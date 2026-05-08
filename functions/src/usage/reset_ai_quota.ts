import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Her gün 00:00'da usageStats günlük AI sayaçlarını sıfırlar.
 */
export const resetAiQuotaDaily = functions
  .region('europe-west1')
  .pubsub
  .schedule('0 0 * * *')
  .timeZone('Europe/Istanbul')
  .onRun(async () => {
    const today = formatDate(new Date());
    let totalUpdated = 0;
    let lastUserDoc: FirebaseFirestore.QueryDocumentSnapshot | undefined;

    while (true) {
      let query = db.collection('users').orderBy(admin.firestore.FieldPath.documentId()).limit(400);

      if (lastUserDoc) {
        query = query.startAfter(lastUserDoc);
      }

      const usersSnap = await query.get();
      if (usersSnap.empty) break;

      const batch = db.batch();
      for (const userDoc of usersSnap.docs) {
        const usageRef = userDoc.ref.collection('usageStats').doc('current');
        batch.set(usageRef, {
          dailyAiComparisons: 0,
          dailyAiRecommendations: 0,
          lastResetDate: today,
        }, { merge: true });
      }
      await batch.commit();
      totalUpdated += usersSnap.size;
      lastUserDoc = usersSnap.docs[usersSnap.docs.length - 1];

      if (usersSnap.size < 400) break;
    }

    console.log(`[resetAiQuotaDaily] Reset AI quota docs: ${totalUpdated}`);
    return null;
  });

function formatDate(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}
