import * as functions from 'firebase-functions';
import { sendNotificationToUser } from './helpers';

/**
 * Bir review'ın isApproved durumu değiştiğinde yorumun yazarına bildirim gönder.
 * Sadece state geçişinde tetiklenir (false → true veya silindi).
 */
export const onReviewModerated = functions
  .region('europe-west1')
  .firestore
  .document('reviews/{reviewId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const reviewId = context.params.reviewId;
    
    // isApproved değişti mi?
    if (before.isApproved === after.isApproved) return null;
    
    const userId = after.userId as string;
    if (!userId) return null;
    
    let title: string;
    let body: string;
    let routePath = '/';
    
    if (after.isApproved === true && before.isApproved === false) {
      // Onaylandı
      title = 'Yorumun onaylandı ✅';
      body = 'Yorumun yayında, başkaları görebilir.';
    } else if (after.isApproved === false && before.isApproved === true) {
      // Reddedildi (önce onaylıyken redden gelen vakası)
      title = 'Yorumun moderasyonda';
      body = 'Yorumun tekrar inceleniyor. Detay için profilini kontrol et.';
    } else {
      return null;  // Durum belirsiz
    }
    
    // Route hesapla
    const reviewType = after.type as string;
    if (reviewType === 'university') {
      routePath = `/university/${after.targetId}`;
    } else if (reviewType === 'department') {
      routePath = `/university/${after.universityId}/department/${after.targetId}`;
    } else if (reviewType === 'place') {
      routePath = `/place/${after.targetId}`;
    }
    
    await sendNotificationToUser({
      userId,
      type: 'review_moderated',
      title,
      body,
      data: { route: routePath, reviewId },
      prefKey: 'reviewModeratedEnabled',
    });
    
    return null;
  });
