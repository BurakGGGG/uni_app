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
  
  /// Tek satırlık özet (ekran başlığı için)
  String get summaryText {
    if (overallWinnerId == null) return 'İki üniversite çok yakın';
    final winner = overallWinnerId == uniA.id ? uniA.name : uniB.name;
    return '$winner genel olarak öne çıkıyor';
  }
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
  
  const ComparisonStats({
    required this.reviewCountDelta,
    required this.placeCountDelta,
    required this.establishedYearDiff,
    required this.sameType,
    required this.sameCity,
    required this.sameCampusLayout,
  });
}
