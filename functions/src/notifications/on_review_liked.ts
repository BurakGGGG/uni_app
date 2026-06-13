import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { sendNotificationToUser } from './helpers';

const db = admin.firestore();

/**
 * Bir review like'landığında, review yazarına bildirim gönder.
 * 
 * NOT: Spam'i önlemek için "batched" yaklaşım — aynı kullanıcının
 * son 10 dakikada gönderdiği "review_liked" bildirimi varsa, yeni gönderme.
 */
export const onReviewLiked = functions
  .region('europe-west1')
  .firestore
  .document('reviews/{reviewId}/likes/{userId}')
  .onCreate(async (snap, context) => {
    const reviewId = context.params.reviewId;
    const likerUserId = context.params.userId;
    
    // 1. Review'ı çek
    const reviewDoc = await db.collection('reviews').doc(reviewId).get();
    if (!reviewDoc.exists) return null;
    const review = reviewDoc.data()!;
    
    const reviewAuthorId = review.userId as string;
    
    // 2. Kendi yorumunu beğenmemize bildirim göndermeyelim
    if (likerUserId === reviewAuthorId) return null;
    
    // 3. Liker bilgisi
    const likerDoc = await db.collection('users').doc(likerUserId).get();
    const likerName = likerDoc.exists 
      ? (likerDoc.data()!.displayName || 'Bir kullanıcı') 
      : 'Bir kullanıcı';
    
    // 4. Spam koruma: son 10 dk'da bu user'a review_liked bildirimi gitti mi?
    const tenMinAgo = admin.firestore.Timestamp.fromMillis(
      Date.now() - 10 * 60 * 1000
    );
    const recentSnap = await db.collection('notifications')
      .where('userId', '==', reviewAuthorId)
      .where('type', '==', 'review_liked')
      .where('data.reviewId', '==', reviewId)
      .where('createdAt', '>=', tenMinAgo)
      .limit(1)
      .get();
    
    if (!recentSnap.empty) {
      // Aynı yoruma yeni like geldi → sayıyı güncelle
      const recentDoc = recentSnap.docs[0];
      const currentCount = (recentDoc.data().data?.likeCount as number) || 1;
      const newCount = currentCount + 1;
      
      await recentDoc.ref.update({
        body: `${likerName} ve ${newCount - 1} kişi daha yorumunuzu beğendi`,
        'data.likeCount': newCount,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`[onReviewLiked] Updated batch notif (${newCount} likes)`);
      return null;
    }
    
    // 5. Yeni bildirim
    const reviewType = review.type as string;
    let routePath = '/';
    if (reviewType === 'university') {
      routePath = `/university/${review.targetId}`;
    } else if (reviewType === 'department') {
      routePath = `/university/${review.universityId}/department/${review.targetId}`;
    } else if (reviewType === 'place') {
      routePath = `/place/${review.targetId}`;
    }
    
    await sendNotificationToUser({
      userId: reviewAuthorId,
      type: 'review_liked',
      title: 'Yorumun beğenildi 🎉',
      body: `${likerName} yorumunuzu beğendi`,
      data: {
        route: routePath,
        reviewId,
        likeCount: '1',
      },
      prefKey: 'reviewLikedEnabled',
    });
    
    return null;
  });
