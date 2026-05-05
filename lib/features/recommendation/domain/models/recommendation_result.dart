enum MedalType { gold, silver, bronze, honorable, none }

class RecommendationResult {
  final List<CombinedRecommendation> recommendations;
  final String summary;
  final DateTime generatedAt;

  RecommendationResult({
    required this.recommendations,
    required this.summary,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();
}

/// Birleşik öneri: Bölüm + Üniversite + Skor
class CombinedRecommendation {
  final String departmentId;
  final String departmentName;
  final String universityId;
  final String universityName;
  final double totalScore;
  final double normalizedScore; // 0-100 arası
  final MedalType medal;
  final List<String> reasons;

  CombinedRecommendation({
    required this.departmentId,
    required this.departmentName,
    required this.universityId,
    required this.universityName,
    required this.totalScore,
    required this.normalizedScore,
    required this.medal,
    required this.reasons,
  });
}
