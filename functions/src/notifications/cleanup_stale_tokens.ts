import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Haftalık çalışır, 90 günden eski "lastTokenRefresh"li kullanıcıların 
 * fcmTokens listesini temizler.
 */
export const cleanupStaleTokens = functions
  .region('europe-west1')
  .pubsub
  .schedule('0 4 * * 0')  // Pazar 04:00
  .timeZone('Europe/Istanbul')
  .onRun(async () => {
    const ninetyDaysAgo = admin.firestore.Timestamp.fromMillis(
      Date.now() - 90 * 24 * 60 * 60 * 1000
    );
    
    const snap = await db.collection('users')
      .where('lastTokenRefresh', '<', ninetyDaysAgo)
      .limit(100)
      .get();
    
    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.update(doc.ref, { fcmTokens: [] });
    }
    
    await batch.commit();
    console.log(`[cleanupStaleTokens] Cleared tokens for ${snap.size} users`);
    return null;
  });
