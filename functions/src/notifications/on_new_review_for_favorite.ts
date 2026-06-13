import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Yeni bir university review'ı onaylandığında, o üniversiteyi favoriye eklemiş
 * tüm kullanıcılara topic-based bildirim gönder.
 * 
 * Topic name: `uni_{uniId}`
 */
export const onNewReviewForFavorite = functions
  .region('europe-west1')
  .firestore
  .document('reviews/{reviewId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Sadece "approved hale geçen" review'lar
    if (before.isApproved === true || after.isApproved !== true) return null;
    
    // Sadece university review'ları (place ve department için ayrı pattern)
    if (after.type !== 'university') return null;
    
    const uniId = after.targetId as string;
    
    // Üni adını çek
    const uniDoc = await db.collection('universities').doc(uniId).get();
    const uniName = uniDoc.exists ? uniDoc.data()!.name : 'Üniversite';
    
    // Yazarın adı
    const authorDoc = await db.collection('users').doc(after.userId).get();
    const authorName = authorDoc.exists 
      ? (authorDoc.data()!.displayName || 'Biri') 
      : 'Biri';
    
    const topic = `uni_${uniId}`;
    
    await messaging.send({
      topic,
      notification: {
        title: `${uniName} için yeni yorum`,
        body: `${authorName} ${uniName} hakkında yorum yazdı`,
      },
      data: {
        route: `/university/${uniId}`,
        type: 'favorite_new_review',
        reviewId: context.params.reviewId,
      },
      android: {
        notification: {
          channelId: 'default_channel_id',
          priority: 'high',
        },
      },
      apns: {
        payload: { aps: { badge: 1, sound: 'default' } },
      },
    });
    
    console.log(`[onNewReviewForFavorite] ✅ Sent to topic ${topic}`);
    return null;
  });
