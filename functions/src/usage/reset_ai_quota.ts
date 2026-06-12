import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();
const BATCH_SIZE = 400;
const MAX_BATCHES_PER_RUN = 100;  // 100 * 400 = 40k kullanıcı / run

/**
 * Her gün 00:00'da usageStats günlük AI sayaçlarını sıfırlar.
 *
 * İyileştirmeler:
 * - Mevcut production fonksiyon 1st gen olduğu için v1 scheduler API korunur
 * - retryCount: 3 — Hata olursa otomatik retry
 * - MAX_BATCHES_PER_RUN — Tek run'da maksimum 40k kullanıcı (timeout korunur)
 * - collectionGroup query ile direkt usageStats'a erişim (users üzerinden dolaşmak yerine)
 * - Per-batch error logging
 */
export const resetAiQuotaDaily = functions
  .runWith({
    timeoutSeconds: 540,
    memory: '512MB',
  })
  .region('europe-west1')
  .pubsub
  .schedule('every day 00:00')
  .timeZone('Europe/Istanbul')
  .retryConfig({ retryCount: 3 })
  .onRun(async () => {
    const today = formatDate(new Date());
    let totalReset = 0;
    let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;
    let batchIndex = 0;

    while (batchIndex < MAX_BATCHES_PER_RUN) {
      let query = db
        .collectionGroup('usageStats')
        .where('lastResetDate', '!=', today)
        .limit(BATCH_SIZE)
        .orderBy('lastResetDate');

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snap = await query.get();
      if (snap.empty) break;

      const batch = db.batch();
      snap.docs.forEach((doc) => {
        batch.set(
          doc.ref,
          {
            lastResetDate: today,
            dailyAiComparisons: 0,
            dailyAiRecommendations: 0,
            dailyComparisons: 0,
          },
          { merge: true },
        );
      });

      try {
        await batch.commit();
        totalReset += snap.size;
        lastDoc = snap.docs[snap.docs.length - 1];
        batchIndex += 1;
      } catch (err) {
        functions.logger.error('Reset batch failed', { batchIndex, err });
        throw err;  // Retry mekanizmasını tetikle
      }

      if (snap.size < BATCH_SIZE) break;
    }

    functions.logger.info(`AI quota reset complete: ${totalReset} users in ${batchIndex} batches`);
  });

function formatDate(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}
