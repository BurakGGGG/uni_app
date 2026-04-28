import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';

const db = admin.firestore();

const PLACE_CATEGORIES = ['Ortam', 'Fiyat', 'Temizlik', 'Hizmet'];

/**
 * Place yorumları yazıldığında/güncellendiğinde/silindiğinde
 * place doc'unun avgRating, reviewCount ve categoryRatings alanlarını günceller.
 *
 * Not: Aynı `reviews/{reviewId}` doc değişikliği `aggregateUniversityRatings` ve
 * `moderateNewReview` fonksiyonlarını da tetikler. Ama her function `type` filtrelediği
 * için sadece kendi alanını güncelliyor. Early return ile maliyet düşük.
 */
export const aggregatePlaceRatings = onDocumentWritten(
  'reviews/{reviewId}',
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    // Place yorumu mu kontrol et (type === 'place')
    const reviewType = afterData?.type ?? beforeData?.type;
    if (reviewType !== 'place') return;

    const placeId = afterData?.targetId ?? beforeData?.targetId;
    if (!placeId) return;

    // Approval state değişti mi? İkisi de pending ise aggregate gereksiz.
    const wasApproved = beforeData?.isApproved === true;
    const isApproved = afterData?.isApproved === true;
    const isDelete = !event.data?.after.exists;
    if (!wasApproved && !isApproved && !isDelete) return;

    console.log(`[aggregatePlaceRatings] place=${placeId}`);

    // Tüm onaylı yorumları çek
    const reviewsSnap = await db.collection('reviews')
      .where('targetId', '==', placeId)
      .where('type', '==', 'place')
      .where('isApproved', '==', true)
      .get();

    if (reviewsSnap.empty) {
      // Hiç onaylı yorum yok — sıfırla
      await db.collection('places').doc(placeId).set({
        avgRating: 0,
        reviewCount: 0,
        categoryRatings: {},
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      return;
    }

    // Hesapla
    let totalOverall = 0;
    const categoryTotals: Record<string, { sum: number; count: number }> = {};
    for (const cat of PLACE_CATEGORIES) {
      categoryTotals[cat] = { sum: 0, count: 0 };
    }

    for (const doc of reviewsSnap.docs) {
      const data = doc.data();
      totalOverall += data.rating ?? 0;

      const catRatings = (data.categoryRatings as Record<string, number>) || {};
      for (const [cat, rating] of Object.entries(catRatings)) {
        if (categoryTotals[cat]) {
          categoryTotals[cat].sum += rating;
          categoryTotals[cat].count += 1;
        }
      }
    }

    const reviewCount = reviewsSnap.size;
    const avgRating = totalOverall / reviewCount;

    const categoryRatings: Record<string, number> = {};
    for (const [cat, { sum, count }] of Object.entries(categoryTotals)) {
      if (count > 0) {
        categoryRatings[cat] = parseFloat((sum / count).toFixed(2));
      }
    }

    await db.collection('places').doc(placeId).set({
      avgRating: parseFloat(avgRating.toFixed(2)),
      reviewCount,
      categoryRatings,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    console.log(`[aggregatePlaceRatings] ✅ place=${placeId} avg=${avgRating.toFixed(2)} count=${reviewCount}`);
  }
);
