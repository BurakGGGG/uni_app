/// users/{uid}/stats/engagement dokümanının istemci modeli.
/// Yalnız server yazar (recordEngagementEvent); istemci okur.
class EngagementStats {
  final int currentStreak;
  final int longestStreak;
  final int totalActiveDays;
  final int viewedUniversityCount;
  final int viewedCityCount;
  final int comparisonCount;
  final int shareCount;
  final int totalLikesReceived;

  const EngagementStats({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalActiveDays = 0,
    this.viewedUniversityCount = 0,
    this.viewedCityCount = 0,
    this.comparisonCount = 0,
    this.shareCount = 0,
    this.totalLikesReceived = 0,
  });

  static const empty = EngagementStats();

  factory EngagementStats.fromMap(Map<String, dynamic>? map) {
    if (map == null) return empty;
    int parse(dynamic v) => v is num && v >= 0 ? v.floor() : 0;
    return EngagementStats(
      currentStreak: parse(map['currentStreak']),
      longestStreak: parse(map['longestStreak']),
      totalActiveDays: parse(map['totalActiveDays']),
      viewedUniversityCount: parse(map['viewedUniversityCount']),
      viewedCityCount: parse(map['viewedCityCount']),
      comparisonCount: parse(map['comparisonCount']),
      shareCount: parse(map['shareCount']),
      totalLikesReceived: parse(map['totalLikesReceived']),
    );
  }
}
