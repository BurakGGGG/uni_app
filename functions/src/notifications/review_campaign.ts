import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { sendNotificationToUser } from './helpers';

const db = admin.firestore();

// Kullanıcı başına ömür boyu en fazla 2 kampanya bildirimi, aralarında
// en az 21 gün. Bookkeeping users/{uid}.reviewCampaign'de tutulur ve
// yalnızca server yazar (isSafeUserUpdate whitelist'i dışında).
const MAX_SENDS_PER_USER = 2;
const MIN_DAYS_BETWEEN_SENDS = 21;
const BATCH_LIMIT = 300;

/**
 * Haftalık "üniversiteni değerlendir" kampanyası.
 *
 * Hedef: doğrulanmış öğrenci + hiç onaylı yorumu yok. Bildirim, kullanıcının
 * kendi üniversitesinin yorum yazma akışına deep-link verir; login gerektiren
 * rota mevcut redirect (from=) akışıyla korunur.
 */
export const sendReviewCampaign = functions
  .region('europe-west1')
  .pubsub
  .schedule('0 19 * * 1') // Pazartesi 19:00
  .timeZone('Europe/Istanbul')
  .onRun(async () => {
    const snap = await db
      .collection('users')
      .where('isVerifiedStudent', '==', true)
      .where('reviewCount', '==', 0)
      .limit(BATCH_LIMIT)
      .get();

    const now = Date.now();
    const eligible = snap.docs.filter((doc) => {
      const data = doc.data();
      const universityId = data.universityId;
      if (typeof universityId !== 'string' || universityId.length === 0) {
        return false;
      }

      const campaign = (data.reviewCampaign ?? {}) as {
        count?: number;
        lastSentAt?: admin.firestore.Timestamp;
      };
      if (Number(campaign.count ?? 0) >= MAX_SENDS_PER_USER) return false;

      const lastSentMs = campaign.lastSentAt?.toMillis() ?? 0;
      return now - lastSentMs > MIN_DAYS_BETWEEN_SENDS * 24 * 60 * 60 * 1000;
    });

    if (eligible.length === 0) {
      console.log('[reviewCampaign] Uygun kullanıcı yok');
      return null;
    }

    // Bildirim gövdesi için üniversite adlarını tek seferde topla.
    const uniIds = [
      ...new Set(eligible.map((doc) => String(doc.data().universityId))),
    ];
    const uniNames = new Map<string, string>();
    await Promise.all(
      uniIds.map(async (uniId) => {
        const uniSnap = await db.collection('universities').doc(uniId).get();
        const name = uniSnap.data()?.name;
        if (typeof name === 'string' && name.length > 0) {
          uniNames.set(uniId, name);
        }
      }),
    );

    let sent = 0;
    for (const doc of eligible) {
      const universityId = String(doc.data().universityId);
      const uniName = uniNames.get(universityId);
      if (!uniName) continue; // üniversite silinmiş/bozuk — atla

      try {
        await sendNotificationToUser({
          userId: doc.id,
          type: 'review_campaign',
          prefKey: 'reviewCampaignEnabled',
          title: 'Üniversiteni değerlendir',
          body: `${uniName} deneyimini paylaş, senden sonrakilere yol göster.`,
          data: { route: `/write-review/university/${universityId}` },
        });

        await doc.ref.set(
          {
            reviewCampaign: {
              count: FieldValue.increment(1),
              lastSentAt: FieldValue.serverTimestamp(),
            },
          },
          { merge: true },
        );
        sent += 1;
      } catch (err) {
        console.error(`[reviewCampaign] ${doc.id} gönderilemedi:`, err);
      }
    }

    console.log(
      `[reviewCampaign] ${sent}/${eligible.length} kullanıcıya gönderildi`,
    );
    return null;
  });
