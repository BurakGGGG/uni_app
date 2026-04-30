import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Her gün 03:00'te çalışır, expireAt geçmiş notification'ları siler.
 */
export const cleanupExpiredNotifications = functions
  .region('europe-west1')
  .pubsub
  .schedule('0 3 * * *')
  .timeZone('Europe/Istanbul')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const snap = await db.collection('notifications')
      .where('expireAt', '<', now)
      .limit(500)
      .get();
    
    if (snap.empty) {
      console.log('[cleanup] Nothing to delete');
      return null;
    }
    
    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    
    console.log(`[cleanup] Deleted ${snap.size} expired notifications`);
    return null;
  });
