import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export const syncUserReviewCount = onDocumentWritten(
  {
    region: 'europe-west1',
    document: 'reviews/{reviewId}',
  },
  async (event) => {
    const beforeUserId = event.data?.before.data()?.userId;
    const afterUserId = event.data?.after.data()?.userId;
    const userIds = new Set<string>();

    if (typeof beforeUserId === 'string' && beforeUserId.length > 0) {
      userIds.add(beforeUserId);
    }
    if (typeof afterUserId === 'string' && afterUserId.length > 0) {
      userIds.add(afterUserId);
    }

    await Promise.all([...userIds].map(recomputeUserReviewCount));
  },
);

async function recomputeUserReviewCount(userId: string): Promise<void> {
  const reviews = await db
    .collection('reviews')
    .where('userId', '==', userId)
    .where('isApproved', '==', true)
    .get();

  await db.collection('users').doc(userId).set(
    {
      reviewCount: reviews.size,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}
