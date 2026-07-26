import '../../../university/domain/models/university_model.dart';

class ComparisonResult {
  final UniversityModel uniA;
  final UniversityModel uniB;
  final Map<String, CategoryComparison> categoryComparisons;
  final ComparisonStats stats;
  final int placeCountA;
  final int placeCountB;
  
  const ComparisonResult({
    required this.uniA,
    required this.uniB,
    required this.categoryComparisons,
    required this.stats,
    required this.placeCountA,
    required this.placeCountB,
  });
  
  /// Genel puan farkı (uniA.avgRating - uniB.avgRating)
  double get overallScoreDelta => uniA.avgRating - uniB.avgRating;
  
  /// Genel "kazanan" — tie ise null
  String? get overallWinnerId {
    if (overallScoreDelta.abs() < 0.05) return null;  // tolerance
    return overallScoreDelta > 0 ? uniA.id : uniB.id;
  }
  
  /// uniA kaç kategoride önde?
  int get categoriesAWins =>
      categoryComparisons.values.where((c) => c.winnerId == uniA.id).length;
  
  /// uniB kaç kategoride önde?
  int get categoriesBWins =>
      categoryComparisons.values.where((c) => c.winnerId == uniB.id).length;
  
  /// Kaç kategoride berabere?
  int get categoriesTied =>
      categoryComparisons.values.where((c) => c.winnerId == null).length;
  
}

class CategoryComparison {
  final String categoryName;
  final double valueA;
  final double valueB;
  final String? winnerId;  // null = tie
  
  const CategoryComparison({
    required this.categoryName,
    required this.valueA,
    required this.valueB,
    required this.winnerId,
  });
  
  double get delta => valueA - valueB;
  double get absDelta => delta.abs();
  
  /// Yüzde farkı (görsel için)
  double get deltaPercent {
    final base = (valueA + valueB) / 2;
    if (base == 0) return 0;
    return (absDelta / base) * 100;
  }
}

class ComparisonStats {
  final int reviewCountDelta;       // A - B
  final int placeCountDelta;
  final int establishedYearDiff;    // |A.year - B.year|
  final bool sameType;              // İkisi de Devlet veya Vakıf
  final bool sameCity;
  final bool sameCampusLayout;
  // ── Yeni metrikler (D6) ──
  final int totalDepartmentsA;
  final int totalDepartmentsB;
  final double avgBaseScoreA;
  final double avgBaseScoreB;
  final Map<String, int> placeBreakdownA;
  final Map<String, int> placeBreakdownB;
  final int undergradCountA;
  final int undergradCountB;
  final int associateCountA;
  final int associateCountB;

  const ComparisonStats({
    required this.reviewCountDelta,
    required this.placeCountDelta,
    required this.establishedYearDiff,
    required this.sameType,
    required this.sameCity,
    required this.sameCampusLayout,
    this.totalDepartmentsA = 0,
    this.totalDepartmentsB = 0,
    this.avgBaseScoreA = 0,
    this.avgBaseScoreB = 0,
    this.placeBreakdownA = const {},
    this.placeBreakdownB = const {},
    this.undergradCountA = 0,
    this.undergradCountB = 0,
    this.associateCountA = 0,
    this.associateCountB = 0,
  });
}
