import * as functions from 'firebase-functions/v2';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

export const aggregateUniversityRatings = functions.firestore.onDocumentWritten(
  'reviews/{reviewId}',
  async (event) => {
    // Yorumun üniversite ID'sini bul
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();
    
    // Yorum silindiyse beforeData'dan, eklendi/güncellendiyse afterData'dan alıyoruz
    const universityId = afterData?.universityId || beforeData?.universityId;

    if (!universityId) {
      console.log('No universityId found in review document.');
      return;
    }

    try {
      // İlgili üniversitenin tüm yorumlarını çek
      const reviewsSnapshot = await db
        .collection('reviews')
        .where('universityId', '==', universityId)
        .get();

      let totalRating = 0;
      let reviewCount = 0;
      const categoryTotals: { [key: string]: number } = {};
      const categoryCounts: { [key: string]: number } = {};

      reviewsSnapshot.forEach((doc) => {
        const data = doc.data();
        if (typeof data.overallRating === 'number') {
          totalRating += data.overallRating;
          reviewCount++;

          // Kategori puanlarını topla
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

      // Üniversite dokümanını güncelle
      await db.collection('universities').doc(universityId).update({
        avgRating: avgRating,
        reviewCount: reviewCount,
        categoryRatings: categoryAverages,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Successfully aggregated ratings for university: ${universityId}`);
    } catch (error) {
      console.error('Error aggregating ratings:', error);
    }
  }
);
