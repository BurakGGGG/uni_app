import * as functions from 'firebase-functions/v2';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

/**
 * Yorum oluşturulduğunda, güncellendiğinde veya silindiğinde
 * ilgili üniversitenin avgRating, reviewCount ve categoryRatings alanlarını günceller.
 */
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
        .where('isApproved', '==', true)
        .get();

      let totalRating = 0;
      let reviewCount = 0;
      const categoryTotals: { [key: string]: number } = {};
      const categoryCounts: { [key: string]: number } = {};

      reviewsSnapshot.forEach((doc) => {
        const data = doc.data();
        if (typeof data.rating === 'number') {
          totalRating += data.rating;
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

// Moderation Cloud Function — yeni yorum küfür filtresi
export { moderateNewReview } from './moderation';

// Sprint 4 — Place yorumları aggregation
export { aggregatePlaceRatings } from './places/aggregate_place_ratings';
export {
  submitPlaceSuggestion,
  checkPlaceSuggestionDuplicates,
  performPlaceSuggestionAction,
} from './places/place_suggestions';

// Sprint 4 — Department yorumları aggregation
export { aggregateDepartmentRatings } from './aggregations/aggregate_department_ratings';

// Yorum canlandırma — canlı Google yorumları (kota korumalı, içerik saklanmaz)
export { getGoogleReviews } from './places/get_google_reviews';

// Sprint 11 (Karşılaştırma 6.4) — Place sayım denormalizasyonu
export { recomputePlaceCount } from './aggregations/recompute_place_count';

// Sprint 4 — Bildirimler
export { onReviewLiked } from './notifications/on_review_liked';
export { onReviewModerated } from './notifications/on_review_moderated';
export { onNewReviewForFavorite } from './notifications/on_new_review_for_favorite';
export { cleanupExpiredNotifications } from './notifications/cleanup_expired';
export { cleanupStaleTokens } from './notifications/cleanup_stale_tokens';
// TODO(kampanya): Uygulama sürümü (reviewCampaignEnabled toggle'ı) Play'de
// yayınlandıktan sonra bu export'u açıp deploy et — kampanya o zaman başlar.
// export { sendReviewCampaign } from './notifications/review_campaign';
// TODO(üni-hatırlatma): uniRemindersEnabled toggle'ını taşıyan sürüm Play'de
// yayınlandıktan sonra bu export'u açıp deploy et — o zamana kadar mevcut
// kullanıcıların bildirimi kapatma yolu yok.
// export { sendUniReminders } from './notifications/uni_reminders';
export { syncReviewLikeCount } from './reviews/sync_review_like_count';
export { submitReview, getReviewSubmissionStatus } from './reviews/submit_review';

// Auth/profile hardening
export { verifyStudentUniversity } from './auth/verify_student';
export { syncPublicProfile } from './auth/sync_public_profile';
export { syncUserReviewCount } from './auth/sync_user_review_count';
export {
  deleteUserAccount,
  cleanupDeletedUserAccount,
} from './auth/cleanup_user';

// Sprint 5 — AI tercih önerisi zenginleştirme (Groq)
export { enrichRecommendations } from './recommendations/enrich';
export { parseWizardUtterance } from './assistant/parse';

// Sprint 6/8 — Comparison AI summary + günlük AI quota reset
export { generateComparisonSummary } from './comparison/summary';
export { resetAiQuotaDaily } from './usage/reset_ai_quota';

// Sprint 9 — RevenueCat webhook sync
export { revenuecatWebhook } from './revenuecat/webhook';

// Sprint 10 — Cleanup functions
export { cleanupAiSummaryLogs } from './cleanup/ai_logs_cleanup';
export {
  cleanupDeletedReviewMedia,
  cleanupDeletedStoryMedia,
} from './storage/cleanup_deleted_media';
export {
  cleanupOrphanPlaceSuggestionMedia,
} from './storage/cleanup_orphan_place_suggestion_media';

// Server-side analytics counters
export { trackAnalyticsEvent } from './analytics/track_event';

// Rozet sistemi — istemci etkileşim olayları + rozet değerlendirme
export { recordEngagementEvent } from './badges/record_engagement_event';
// Rozet sistemi — favori rozetleri sunucu-otoriter (Firestore trigger)
export { syncUserFavoriteBadges } from './favorites/sync_favorite_badges';

// Preference lists
export { incrementPreferenceListView } from './preference_lists/increment_view';
export { getPublicPreferenceList } from './preference_lists/get_public_list';

// Admin server-side moderation actions
export { performAdminModerationAction } from './admin/moderation_actions';

// Abuse/user submissions
export { submitReviewReport, submitFeedback } from './abuse/user_submissions';
