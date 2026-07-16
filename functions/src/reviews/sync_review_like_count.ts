import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { evaluateHelpfulBadge } from '../badges/award_badges';

const db = admin.firestore();

export const syncReviewLikeCount = onDocumentWritten(
  {
    region: 'europe-west1',
    document: 'reviews/{reviewId}/likes/{userId}',
  },
  async (event) => {
    const reviewId = event.params.reviewId;
    const reviewRef = db.collection('reviews').doc(reviewId);
    const reviewSnap = await reviewRef.get();

    if (!reviewSnap.exists) return;

    const countSnap = await reviewRef.collection('likes').count().get();
    await reviewRef.set(
      {
        likes: countSnap.data().count,
      },
      { merge: true },
    );

    const authorId = reviewSnap.data()?.userId;
    if (typeof authorId === 'string' && authorId.length > 0) {
      await evaluateHelpfulBadge(authorId);
    }
  },
);
