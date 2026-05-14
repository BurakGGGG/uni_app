import '../../../university/domain/models/university_model.dart';

/// 3 üniversitenin yan yana karşılaştırılmış sonuç modeli.
/// Pro tier'a özel feature.
class TripleComparisonResult {
  final UniversityModel uniA;
  final UniversityModel uniB;
  final UniversityModel uniC;
  final Map<String, TripleCategoryComparison> categoryComparisons;
  final TripleComparisonStats stats;
  final int placeCountA;
  final int placeCountB;
  final int placeCountC;

  const TripleComparisonResult({
    required this.uniA,
    required this.uniB,
    required this.uniC,
    required this.categoryComparisons,
    required this.stats,
    required this.placeCountA,
    required this.placeCountB,
    required this.placeCountC,
  });

  /// Genel kazanan — en yüksek avgRating. Tie tolerance 0.05.
  String? get overallWinnerId {
    final maxRating = [
      uniA.avgRating,
      uniB.avgRating,
      uniC.avgRating,
    ].reduce((a, b) => a > b ? a : b);

    final near = [uniA, uniB, uniC]
        .where((u) => (maxRating - u.avgRating).abs() < 0.05)
        .toList();
    if (near.length > 1) return null; // çoklu tie
    return near.first.id;
  }

  /// Bir üniversite kaç kategoride önde?
  int categoriesWonBy(String uniId) =>
      categoryComparisons.values.where((c) => c.winnerId == uniId).length;

  int get categoriesTied =>
      categoryComparisons.values.where((c) => c.winnerId == null).length;

  /// Skor normalization (0-5 → 0-100 ölçek için, bar chart/grafik görselleri)
  static double normalizeScore(double raw, {double max = 5.0}) {
    if (raw <= 0) return 0;
    return ((raw / max) * 100).clamp(0, 100);
  }

  /// 3 skor için sıralama: en yüksek 1. olur (leaderboard UI için)
  List<MapEntry<String, double>> rankedScores() {
    final entries = [
      MapEntry(uniA.id, uniA.avgRating),
      MapEntry(uniB.id, uniB.avgRating),
      MapEntry(uniC.id, uniC.avgRating),
    ];
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Tek satırlık özet (ekran başlığı için)
  String get summaryText {
    final winner = overallWinnerId;
    if (winner == null) {
      return '3 üniversite genel puanlarda çok yakın';
    }
    final name = winner == uniA.id
        ? uniA.name
        : winner == uniB.id
            ? uniB.name
            : uniC.name;
    return '$name genel olarak öne çıkıyor';
  }
}

/// 3 üniversite için tek bir kategorinin (akademik, sosyal vb.) karşılaştırması.
class TripleCategoryComparison {
  final String categoryName;
  final double valueA;
  final double valueB;
  final double valueC;
  // En yüksek değere sahip uniId. Birden çok max ise null (tie).
  final String? winnerId;

  const TripleCategoryComparison({
    required this.categoryName,
    required this.valueA,
    required this.valueB,
    required this.valueC,
    required this.winnerId,
  });

  /// Bu kategoride en yüksek değer
  double get maxValue {
    return [valueA, valueB, valueC].reduce((a, b) => a > b ? a : b);
  }

  /// 0..1 normalize edilmiş değer (bar görselleri için)
  double normalizedFor(double v) {
    final m = maxValue;
    if (m == 0) return 0;
    return (v / m).clamp(0.0, 1.0);
  }
}

class TripleComparisonStats {
  final int totalDepartmentsA;
  final int totalDepartmentsB;
  final int totalDepartmentsC;
  final double avgBaseScoreA;
  final double avgBaseScoreB;
  final double avgBaseScoreC;
  final Map<String, int> placeBreakdownA;
  final Map<String, int> placeBreakdownB;
  final Map<String, int> placeBreakdownC;

  const TripleComparisonStats({
    required this.totalDepartmentsA,
    required this.totalDepartmentsB,
    required this.totalDepartmentsC,
    required this.avgBaseScoreA,
    required this.avgBaseScoreB,
    required this.avgBaseScoreC,
    required this.placeBreakdownA,
    required this.placeBreakdownB,
    required this.placeBreakdownC,
  });
}
