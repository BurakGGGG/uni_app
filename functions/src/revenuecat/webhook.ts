import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';

const WEBHOOK_TOKEN = defineSecret('REVENUECAT_WEBHOOK_TOKEN');
const db = admin.firestore();

type Tier = 'free' | 'plus' | 'pro';

export const revenuecatWebhook = onRequest(
  {
    region: 'us-central1',
    secrets: [WEBHOOK_TOKEN],
  },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const expectedToken = WEBHOOK_TOKEN.value();
    const authHeader = req.get('authorization') ?? '';
    const providedToken = authHeader.replace(/^Bearer\s+/i, '').trim();
    if (!expectedToken || providedToken !== expectedToken) {
      res.status(401).send('Unauthorized');
      return;
    }

    const event = (req.body?.event ?? req.body) as Record<string, unknown>;
    const appUserId = String(event.app_user_id ?? event.appUserId ?? '');
    if (!appUserId) {
      res.status(400).send('Missing app_user_id');
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

    const beforeSnap = await subRef.get();
    const previousTier = String(beforeSnap.data()?.tier ?? 'free');

    await subRef.set({
      tier,
      status,
      platform: String(event.store ?? event.environment ?? 'unknown'),
      expiresAt,
      rcCustomerId: String(event.original_app_user_id ?? appUserId),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: beforeSnap.exists
        ? (beforeSnap.data()?.createdAt ?? admin.firestore.FieldValue.serverTimestamp())
        : admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    if (previousTier !== tier) {
      const today = formatDate(new Date());
      await usageRef.set({
        dailyComparisons: 0,
        dailyAiComparisons: 0,
        dailyAiRecommendations: 0,
        lastResetDate: today,
      }, { merge: true });
    }

    res.status(200).json({ ok: true });
  }
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
