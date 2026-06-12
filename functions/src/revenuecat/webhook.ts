import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';

const REVENUECAT_WEBHOOK_SECRET = defineSecret('REVENUECAT_WEBHOOK_TOKEN');
const db = admin.firestore();

type Tier = 'free' | 'plus' | 'pro';

/**
 * RevenueCat webhook handler.
 *
 * İyileştirmeler:
 * - Bölge europe-west1'e taşındı
 * - CORS kapatıldı (Browser'dan çağrılmamalı)
 * - Idempotency: Aynı event 2 kez işlenmez (webhookEvents koleksiyonu)
 * - User validation: Firebase Auth'da uid var mı kontrolü
 * - Transaction: idempotency mark + subscription write atomik
 */
export const revenuecatWebhook = onRequest(
  {
    region: 'europe-west1',
    secrets: [REVENUECAT_WEBHOOK_SECRET],
    cors: false,  // Browser'dan çağrılmamalı
  },
  async (req, res) => {
    // 1. Method kontrolü
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    // 2. Authorization header (RevenueCat custom secret)
    const expectedToken = REVENUECAT_WEBHOOK_SECRET.value();
    const authHeader = req.get('authorization') ?? '';
    const providedToken = authHeader.replace(/^Bearer\s+/i, '').trim();
    if (!expectedToken || providedToken !== expectedToken) {
      logger.warn('Webhook unauthorized', { authHeader: authHeader.slice(0, 20) });
      res.status(401).send('Unauthorized');
      return;
    }

    const event = (req.body?.event ?? req.body) as Record<string, unknown>;
    const appUserId = String(event.app_user_id ?? event.appUserId ?? '');
    if (!appUserId) {
      res.status(400).send('Missing app_user_id');
      return;
    }

    // 3. Idempotency — aynı event'i 2 kez işleme
    const eventId = String(event.id ?? `${appUserId}_${Date.now()}`);
    const eventRef = db.collection('webhookEvents').doc(eventId);
    const eventSnap = await eventRef.get();
    if (eventSnap.exists) {
      logger.info('Duplicate webhook event ignored', { eventId });
      res.status(200).send('OK (duplicate)');
      return;
    }

    // 4. User var mı? (Firebase Auth doğrulama)
    try {
      await admin.auth().getUser(appUserId);
    } catch {
      logger.warn('Webhook for unknown user', { uid: appUserId });
      res.status(404).send('User not found');
      return;
    }

    const entitlementIds = (
      (event.entitlement_ids as unknown[]) ??
      (event.entitlementIds as unknown[]) ??
      []
    ).map((v) => String(v).toLowerCase());

    const tier = determineTier(entitlementIds);
    const status = determineStatus(event.type);
    const expiresAtMs = Number(event.expiration_at_ms ?? 0);
    const expiresAt = expiresAtMs > 0
      ? admin.firestore.Timestamp.fromMillis(expiresAtMs)
      : null;

    const subRef = db.collection('subscriptions').doc(appUserId);
    const usageRef = db
      .collection('users')
      .doc(appUserId)
      .collection('usageStats')
      .doc('current');

    // 5. Subscription güncelleme + idempotency mark — transaction
    await db.runTransaction(async (tx) => {
      const beforeSnap = await tx.get(subRef);
      const previousTier = String(beforeSnap.data()?.tier ?? 'free');

      // Idempotency kaydı
      tx.set(eventRef, {
        type: String(event.type ?? 'unknown'),
        appUserId,
        receivedAt: admin.firestore.FieldValue.serverTimestamp(),
        // TTL — 90 gün sonra sil
        expireAt: admin.firestore.Timestamp.fromMillis(
          Date.now() + 90 * 24 * 60 * 60 * 1000,
        ),
      });

      // Subscription güncelle
      tx.set(
        subRef,
        {
          tier,
          status,
          platform: String(event.store ?? event.environment ?? 'unknown'),
          expiresAt,
          rcCustomerId: String(event.original_app_user_id ?? appUserId),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          source: 'revenuecat_webhook',
          lastEventType: String(event.type ?? 'unknown'),
          createdAt: beforeSnap.exists
            ? (beforeSnap.data()?.createdAt ?? admin.firestore.FieldValue.serverTimestamp())
            : admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      // Tier değiştiyse usage stats sıfırla
      if (previousTier !== tier) {
        const today = formatDate(new Date());
        tx.set(
          usageRef,
          {
            dailyComparisons: 0,
            dailyAiComparisons: 0,
            dailyAiRecommendations: 0,
            lastResetDate: today,
            lastAiRecommendationResetDate: today,
          },
          { merge: true },
        );
      }
    });

    res.status(200).json({ ok: true });
  },
);

function determineTier(entitlementIds: string[]): Tier {
  if (entitlementIds.some((id) => id.includes('pro'))) return 'pro';
  if (entitlementIds.some((id) => id.includes('plus'))) return 'plus';
  return 'free';
}

function determineStatus(type: unknown): 'active' | 'expired' | 'trial' {
  const t = String(type ?? '').toUpperCase();
  if (t.includes('EXPIR') || t.includes('CANCEL')) return 'expired';
  if (t.includes('TRIAL')) return 'trial';
  return 'active';
}

function formatDate(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}
