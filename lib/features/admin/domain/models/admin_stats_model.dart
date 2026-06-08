/// Admin istatistik ekranında gösterilecek veri modeli.
///
/// Hem all-time toplamları hem de seçilen zaman dilimine göre
/// hesaplanmış değerleri tutar.
class AdminStatsModel {
  final int totalUsers;
  final int totalLogins;
  final int totalReviews;
  final int totalLikes;
  final int totalStoryViews;
  final int totalComparisons;
  final int totalScoreCalculations;
  final int totalFavorites;
  final int totalReports;

  const AdminStatsModel({
    this.totalUsers = 0,
    this.totalLogins = 0,
    this.totalReviews = 0,
    this.totalLikes = 0,
    this.totalStoryViews = 0,
    this.totalComparisons = 0,
    this.totalScoreCalculations = 0,
    this.totalFavorites = 0,
    this.totalReports = 0,
  });

  /// Firestore dokümanından model oluştur.
  /// [fieldMapper] all-time için counterField, daily için dailyField kullanılır.
  factory AdminStatsModel.fromMap(
    Map<String, dynamic> map, {
    bool isDaily = false,
  }) {
    if (isDaily) {
      return AdminStatsModel(
        totalUsers: (map['newUsers'] as num?)?.toInt() ?? 0,
        totalLogins: (map['logins'] as num?)?.toInt() ?? 0,
        totalReviews: (map['reviews'] as num?)?.toInt() ?? 0,
        totalLikes: (map['likes'] as num?)?.toInt() ?? 0,
        totalStoryViews: (map['storyViews'] as num?)?.toInt() ?? 0,
        totalComparisons: (map['comparisons'] as num?)?.toInt() ?? 0,
        totalScoreCalculations:
            (map['scoreCalculations'] as num?)?.toInt() ?? 0,
        totalFavorites: (map['favorites'] as num?)?.toInt() ?? 0,
        totalReports: (map['reports'] as num?)?.toInt() ?? 0,
      );
    }
    return AdminStatsModel(
      totalUsers: (map['totalUsers'] as num?)?.toInt() ?? 0,
      totalLogins: (map['totalLogins'] as num?)?.toInt() ?? 0,
      totalReviews: (map['totalReviews'] as num?)?.toInt() ?? 0,
      totalLikes: (map['totalLikes'] as num?)?.toInt() ?? 0,
      totalStoryViews: (map['totalStoryViews'] as num?)?.toInt() ?? 0,
      totalComparisons: (map['totalComparisons'] as num?)?.toInt() ?? 0,
      totalScoreCalculations:
          (map['totalScoreCalculations'] as num?)?.toInt() ?? 0,
      totalFavorites: (map['totalFavorites'] as num?)?.toInt() ?? 0,
      totalReports: (map['totalReports'] as num?)?.toInt() ?? 0,
    );
  }

  /// İki modeli topla (günlük kırılımları birleştirmek için).
  AdminStatsModel operator +(AdminStatsModel other) {
    return AdminStatsModel(
      totalUsers: totalUsers + other.totalUsers,
      totalLogins: totalLogins + other.totalLogins,
      totalReviews: totalReviews + other.totalReviews,
      totalLikes: totalLikes + other.totalLikes,
      totalStoryViews: totalStoryViews + other.totalStoryViews,
      totalComparisons: totalComparisons + other.totalComparisons,
      totalScoreCalculations:
          totalScoreCalculations + other.totalScoreCalculations,
      totalFavorites: totalFavorites + other.totalFavorites,
      totalReports: totalReports + other.totalReports,
    );
  }

  /// Boş kontrol
  static const empty = AdminStatsModel();
}
