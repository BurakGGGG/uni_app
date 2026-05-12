import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';

const db = admin.firestore();
const BATCH_SIZE = 400;
const RETENTION_DAYS = 30;

/**
 * Her gün 03:00'te 30 günden eski aiSummaryLogs dokümanlarını temizler.
 *
 * Not: Firestore TTL policy de aynı işi yapabilir (gcloud CLI ile ayarlanır).
 * Bu function, TTL policy yoksa ya da yedek olarak kullanılır.
 */
export const cleanupAiSummaryLogs = onSchedule(
  {
    region: 'europe-west1',
    schedule: 'every day 03:00',
    timeZone: 'Europe/Istanbul',
  },
  async () => {
    const cutoff = admin.firestore.Timestamp.fromMillis(
      Date.now() - RETENTION_DAYS * 24 * 60 * 60 * 1000,
    );

    let totalDeleted = 0;
    let hasMore = true;

    while (hasMore) {
      const snap = await db
        .collection('aiSummaryLogs')
        .where('createdAt', '<', cutoff)
        .limit(BATCH_SIZE)
        .get();

      if (snap.empty) {
        hasMore = false;
        break;
      }

      const batch = db.batch();
      snap.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      totalDeleted += snap.size;

      if (snap.size < BATCH_SIZE) hasMore = false;
    }

    logger.info(`Cleanup complete: ${totalDeleted} aiSummaryLogs deleted`);
  },
);
