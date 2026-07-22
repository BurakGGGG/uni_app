/// Takip edilen analytics event türleri.
///
/// Her event Firestore'da iki yere yazılır:
/// 1. `analytics/counters` → all-time toplamlar
/// 2. `analytics/daily/{yyyy-MM-dd}` → günlük kırılım
enum AnalyticsEvent {
  newUser('totalUsers', 'newUsers'),
  login('totalLogins', 'logins'),
  reviewCreated('totalReviews', 'reviews'),
  reviewLiked('totalLikes', 'likes'),
  storyViewed('totalStoryViews', 'storyViews'),
  comparisonMade('totalComparisons', 'comparisons'),
  scoreCalculated('totalScoreCalculations', 'scoreCalculations'),
  scoreShared('totalScoreShares', 'scoreShares'),
  favoriteAdded('totalFavorites', 'favorites'),
  reportCreated('totalReports', 'reports'),

  // Keşif & etkileşim
  universityViewed('totalUniversityViews', 'universityViews'),
  departmentViewed('totalDepartmentViews', 'departmentViews'),
  searchPerformed('totalSearches', 'searches'),
  preferenceListCreated('totalPreferenceLists', 'preferenceLists'),
  preferenceListShared('totalPreferenceListShares', 'preferenceListShares'),
  comparisonShared('totalComparisonShares', 'comparisonShares'),

  // Tercih Robotu
  preferenceWizardOpened('totalPreferenceWizardOpened', 'preferenceWizardOpened'),
  preferenceWizardMatched('totalPreferenceWizardMatched', 'preferenceWizardMatched'),
  preferenceAutoListCreated('totalPreferenceAutoLists', 'preferenceAutoLists'),

  // Monetizasyon
  paywallShown('totalPaywallShown', 'paywallShown'),
  adWatched('totalAdWatched', 'adWatched'),
  subscriptionPurchased('totalSubscriptionPurchased', 'subscriptionPurchased'),
  aiComparisonUsed('totalAiComparisons', 'aiComparisons'),
  aiRecommendationUsed('totalAiRecommendations', 'aiRecommendations');

  final String counterField;
  final String dailyField;

  const AnalyticsEvent(this.counterField, this.dailyField);
}
