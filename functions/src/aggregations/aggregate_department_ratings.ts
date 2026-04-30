import * as functions from 'firebase-functions/v2';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Bölüm yorumu oluşturulduğunda, güncellendiğinde veya silindiğinde
 * ilgili bölümün avgRating, reviewCount ve categoryRatings alanlarını günceller.
 *
 * aggregateUniversityRatings ile aynı pattern; sadece type == 'department' filtresi
 * ve hedef koleksiyon departments/{deptId}.
 */
export const aggregateDepartmentRatings = functions.firestore.onDocumentWritten(
  'reviews/{reviewId}',
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();
    const review = afterData ?? beforeData;

    if (!review) return;

    // Sadece bölüm yorumlarını işle
    if (review.type !== 'department') return;

    // Onaylanmamış yorumları da saymasın
    const targetId = review.targetId as string | undefined;
    if (!targetId) {
      console.log('[aggregateDeptRatings] No targetId found');
      return;
    }

    try {
      // İlgili bölümün tüm onaylanmış yorumlarını çek
      const reviewsSnap = await db
        .collection('reviews')
        .where('targetId', '==', targetId)
        .where('type', '==', 'department')
        .where('isApproved', '==', true)
        .get();

      let totalRating = 0;
      let reviewCount = 0;
      const categoryTotals: { [key: string]: number } = {};
      const categoryCounts: { [key: string]: number } = {};

      reviewsSnap.forEach((doc) => {
        const data = doc.data();
        if (typeof data.rating === 'number') {
          totalRating += data.rating;
          reviewCount++;

          if (data.categoryRatings && typeof data.categoryRatings === 'object') {
            for (const [key, value] of Object.entries(data.categoryRatings)) {
              if (typeof value === 'number') {
                categoryTotals[key] = (categoryTotals[key] || 0) + value;
                categoryCounts[key] = (categoryCounts[key] || 0) + 1;
              }
            }
          }
        }
      });

      const avgRating = reviewCount > 0 ? totalRating / reviewCount : 0;

      const categoryAverages: { [key: string]: number } = {};
      for (const key of Object.keys(categoryTotals)) {
        categoryAverages[key] = categoryTotals[key] / categoryCounts[key];
      }

      // Bölüm dokümanını güncelle
      await db.collection('departments').doc(targetId).update({
        avgRating,
        reviewCount,
        categoryRatings: categoryAverages,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(
        `[aggregateDeptRatings] Updated department ${targetId}: avg=${avgRating.toFixed(2)}, count=${reviewCount}`
      );
    } catch (error) {
      console.error('[aggregateDeptRatings] Error:', error);
    }
  }
);
