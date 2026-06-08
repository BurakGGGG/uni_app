/// Takip edilen analytics event türleri.
///
/// Her event Firestore'da iki yere yazılır:
/// 1. `analytics/counters` → all-time toplamlar
/// 2. `analytics/daily/{yyyy-MM-dd}` → günlük kırılım
enum AnalyticsEvent {
  /// Yeni kullanıcı kaydı
  newUser('totalUsers', 'newUsers'),

  /// Başarılı giriş (her login)
  login('totalLogins', 'logins'),

  /// Yeni yorum oluşturuldu
  reviewCreated('totalReviews', 'reviews'),

  /// Yorum beğenildi
  reviewLiked('totalLikes', 'likes'),

  /// Story görüntülendi
  storyViewed('totalStoryViews', 'storyViews'),

  /// Karşılaştırma yapıldı
  comparisonMade('totalComparisons', 'comparisons'),

  /// Puan hesaplandı
  scoreCalculated('totalScoreCalculations', 'scoreCalculations'),

  /// Favorilere eklendi
  favoriteAdded('totalFavorites', 'favorites'),

  /// Rapor/şikayet gönderildi
  reportCreated('totalReports', 'reports');

  /// All-time counter dokümanındaki alan adı
  final String counterField;

  /// Günlük dokümanındaki alan adı
  final String dailyField;

  const AnalyticsEvent(this.counterField, this.dailyField);
}
