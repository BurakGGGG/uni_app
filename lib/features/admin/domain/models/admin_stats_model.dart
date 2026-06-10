/// Admin istatistik ekranında gösterilecek veri modeli.
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
  final int totalUniversityViews;
  final int totalDepartmentViews;
  final int totalSearches;
  final int totalPreferenceLists;
  final int totalPreferenceListShares;
  final int totalComparisonShares;
  final int totalPaywallShown;
  final int totalAdWatched;
  final int totalSubscriptionPurchased;
  final int totalAiComparisons;
  final int totalAiRecommendations;

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
    this.totalUniversityViews = 0,
    this.totalDepartmentViews = 0,
    this.totalSearches = 0,
    this.totalPreferenceLists = 0,
    this.totalPreferenceListShares = 0,
    this.totalComparisonShares = 0,
    this.totalPaywallShown = 0,
    this.totalAdWatched = 0,
    this.totalSubscriptionPurchased = 0,
    this.totalAiComparisons = 0,
    this.totalAiRecommendations = 0,
  });

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
        totalUniversityViews: (map['universityViews'] as num?)?.toInt() ?? 0,
        totalDepartmentViews: (map['departmentViews'] as num?)?.toInt() ?? 0,
        totalSearches: (map['searches'] as num?)?.toInt() ?? 0,
        totalPreferenceLists: (map['preferenceLists'] as num?)?.toInt() ?? 0,
        totalPreferenceListShares:
            (map['preferenceListShares'] as num?)?.toInt() ?? 0,
        totalComparisonShares: (map['comparisonShares'] as num?)?.toInt() ?? 0,
        totalPaywallShown: (map['paywallShown'] as num?)?.toInt() ?? 0,
        totalAdWatched: (map['adWatched'] as num?)?.toInt() ?? 0,
        totalSubscriptionPurchased:
            (map['subscriptionPurchased'] as num?)?.toInt() ?? 0,
        totalAiComparisons: (map['aiComparisons'] as num?)?.toInt() ?? 0,
        totalAiRecommendations: (map['aiRecommendations'] as num?)?.toInt() ?? 0,
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
      totalUniversityViews: (map['totalUniversityViews'] as num?)?.toInt() ?? 0,
      totalDepartmentViews: (map['totalDepartmentViews'] as num?)?.toInt() ?? 0,
      totalSearches: (map['totalSearches'] as num?)?.toInt() ?? 0,
      totalPreferenceLists: (map['totalPreferenceLists'] as num?)?.toInt() ?? 0,
      totalPreferenceListShares:
          (map['totalPreferenceListShares'] as num?)?.toInt() ?? 0,
      totalComparisonShares: (map['totalComparisonShares'] as num?)?.toInt() ?? 0,
      totalPaywallShown: (map['totalPaywallShown'] as num?)?.toInt() ?? 0,
      totalAdWatched: (map['totalAdWatched'] as num?)?.toInt() ?? 0,
      totalSubscriptionPurchased:
          (map['totalSubscriptionPurchased'] as num?)?.toInt() ?? 0,
      totalAiComparisons: (map['totalAiComparisons'] as num?)?.toInt() ?? 0,
      totalAiRecommendations:
          (map['totalAiRecommendations'] as num?)?.toInt() ?? 0,
    );
  }

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
      totalUniversityViews: totalUniversityViews + other.totalUniversityViews,
      totalDepartmentViews: totalDepartmentViews + other.totalDepartmentViews,
      totalSearches: totalSearches + other.totalSearches,
      totalPreferenceLists: totalPreferenceLists + other.totalPreferenceLists,
      totalPreferenceListShares:
          totalPreferenceListShares + other.totalPreferenceListShares,
      totalComparisonShares:
          totalComparisonShares + other.totalComparisonShares,
      totalPaywallShown: totalPaywallShown + other.totalPaywallShown,
      totalAdWatched: totalAdWatched + other.totalAdWatched,
      totalSubscriptionPurchased:
          totalSubscriptionPurchased + other.totalSubscriptionPurchased,
      totalAiComparisons: totalAiComparisons + other.totalAiComparisons,
      totalAiRecommendations:
          totalAiRecommendations + other.totalAiRecommendations,
    );
  }

  static const empty = AdminStatsModel();
}

/// Firestore'dan canlı okunan kullanıcı/abonelik metrikleri.
class AdminLiveStatsModel {
  final int totalUsers;
  final int verifiedStudents;
  final int activeUsers7d;
  final int activeUsers30d;
  final int proSubscribers;
  final int plusSubscribers;

  const AdminLiveStatsModel({
    this.totalUsers = 0,
    this.verifiedStudents = 0,
    this.activeUsers7d = 0,
    this.activeUsers30d = 0,
    this.proSubscribers = 0,
    this.plusSubscribers = 0,
  });

  static const empty = AdminLiveStatsModel();
}

/// Günlük trend veri noktası.
class DailyTrendPoint {
  final String date;
  final String label;
  final int newUsers;
  final int logins;

  const DailyTrendPoint({
    required this.date,
    required this.label,
    required this.newUsers,
    required this.logins,
  });
}

/// Dönem karşılaştırması (bu hafta vs geçen hafta).
class PeriodComparisonModel {
  final int thisPeriodNewUsers;
  final int lastPeriodNewUsers;
  final int thisPeriodLogins;
  final int lastPeriodLogins;

  const PeriodComparisonModel({
    this.thisPeriodNewUsers = 0,
    this.lastPeriodNewUsers = 0,
    this.thisPeriodLogins = 0,
    this.lastPeriodLogins = 0,
  });

  double get newUsersChangePercent {
    if (lastPeriodNewUsers == 0) {
      return thisPeriodNewUsers > 0 ? 100 : 0;
    }
    return ((thisPeriodNewUsers - lastPeriodNewUsers) / lastPeriodNewUsers) * 100;
  }

  double get loginsChangePercent {
    if (lastPeriodLogins == 0) {
      return thisPeriodLogins > 0 ? 100 : 0;
    }
    return ((thisPeriodLogins - lastPeriodLogins) / lastPeriodLogins) * 100;
  }
}

/// Popüler üniversite sıralama kaydı.
class TopUniversityStat {
  final String universityId;
  final String name;
  final int viewCount;

  const TopUniversityStat({
    required this.universityId,
    required this.name,
    required this.viewCount,
  });
}

/// Türev oranlar ve hesaplanmış metrikler.
class AdminDerivedStats {
  final double avgLikesPerReview;
  final double comparisonsPerUser;
  final double storyViewsPerStory;
  final double proRatePercent;
  final double verifiedRatePercent;
  final double loginEngagementPercent;
  final double paywallConversionPercent;
  final double adCompletionPercent;

  const AdminDerivedStats({
    this.avgLikesPerReview = 0,
    this.comparisonsPerUser = 0,
    this.storyViewsPerStory = 0,
    this.proRatePercent = 0,
    this.verifiedRatePercent = 0,
    this.loginEngagementPercent = 0,
    this.paywallConversionPercent = 0,
    this.adCompletionPercent = 0,
  });

  factory AdminDerivedStats.compute({
    required AdminStatsModel stats,
    required AdminLiveStatsModel live,
    required int activeStoryCount,
    required int userBase,
  }) {
    double safeDiv(int a, int b) => b == 0 ? 0 : a / b;

    final avgLikes = safeDiv(stats.totalLikes, stats.totalReviews);
    final comparisonsPerUser = safeDiv(stats.totalComparisons, userBase);
    final storyViewsPerStory = safeDiv(stats.totalStoryViews, activeStoryCount);
    final proRate = safeDiv(live.proSubscribers, live.totalUsers) * 100;
    final verifiedRate = safeDiv(live.verifiedStudents, live.totalUsers) * 100;
    final loginEngagement = safeDiv(stats.totalLogins, userBase) * 100;

    // Paywall conversion: purchases / paywall shown
    final paywallConversion =
        safeDiv(stats.totalSubscriptionPurchased, stats.totalPaywallShown) * 100;

    // Ad completion uses adWatched counter (only completed ads tracked)
    final adCompletion = stats.totalAdWatched > 0 ? 100.0 : 0.0;

    return AdminDerivedStats(
      avgLikesPerReview: avgLikes,
      comparisonsPerUser: comparisonsPerUser,
      storyViewsPerStory: storyViewsPerStory,
      proRatePercent: proRate,
      verifiedRatePercent: verifiedRate,
      loginEngagementPercent: loginEngagement,
      paywallConversionPercent: paywallConversion,
      adCompletionPercent: adCompletion,
    );
  }
}
