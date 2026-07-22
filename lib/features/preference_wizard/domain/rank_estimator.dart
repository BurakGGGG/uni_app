import 'dart:math' as math;

import '../../university/domain/models/department_model.dart';

/// Puan → tahmini başarı sıralaması dönüştürücü.
///
/// Aynı veri setindeki (taban puan, taban sıra) çiftlerinden puan türü başına
/// bir eğri kurar: SAY 1.842, TYT 3.209, EA 1.232, SÖZ 758, DİL 255 çift.
/// Kuruluş: 1 puanlık kovalara medyan sıra → "puan arttıkça sıra artamaz"
/// kuralıyla tekdüzeleştirme (running min) → log-sıra uzayında parçalı
/// doğrusal enterpolasyon. Sıralar 1.000–2.000.000 aralığına yayıldığından
/// enterpolasyon log uzayında yapılır.
///
/// Kuruluş O(n log n) ve bir kez; sorgu binary search + lerp, O(log n).
class RankEstimator {
  final Map<String, _RankCurve> _curves;

  const RankEstimator._(this._curves);

  factory RankEstimator.fromDepartments(List<DepartmentModel> departments) {
    final byType = <String, Map<int, List<int>>>{};
    for (final dept in departments) {
      final score = dept.effectiveBaseScore;
      final rank = dept.rankingForMatching;
      final type = dept.effectiveScoreType?.toUpperCase();
      if (score <= 0 || rank == null || rank <= 0) continue;
      if (type == null || type.isEmpty) continue;
      final buckets = byType.putIfAbsent(type, () => {});
      buckets.putIfAbsent(score.floor(), () => []).add(rank);
    }

    final curves = <String, _RankCurve>{};
    byType.forEach((type, buckets) {
      final curve = _RankCurve.fromBuckets(buckets);
      if (curve != null) curves[type] = curve;
    });
    return RankEstimator._(curves);
  }

  /// Verilen puanın tahmini başarı sıralaması; puan türü için eğri
  /// kurulamadıysa null. Eğri uçlarının dışındaki puanlar uca kelepçelenir.
  int? estimateRank(double score, String scoreType) {
    if (score <= 0) return null;
    return _curves[scoreType.toUpperCase()]?.estimate(score);
  }

  /// Bu puan türü için tahmin yapılabiliyor mu (UI dürtmesi için).
  bool supports(String scoreType) =>
      _curves.containsKey(scoreType.toUpperCase());
}

/// Yıl bazlı puan → tahmini başarı sıralaması dönüştürücü.
///
/// [RankEstimator] tek (güncel) eğri kurar; bu sınıf puan hesaplamanın yıl
/// karşılaştırması için yıl × tür eğrileri kurar: 2025 çiftleri scoreData'nın
/// kendisinden, 2022–2024 çiftleri previousYears'tan. Eğri kuruluşu ve
/// sorgusu [_RankCurve] ile ortak.
class MultiYearRankEstimator {
  final Map<String, Map<int, _RankCurve>> _curvesByType;

  const MultiYearRankEstimator._(this._curvesByType);

  factory MultiYearRankEstimator.fromDepartments(
      List<DepartmentModel> departments) {
    // tür → yıl → (puan kovası → sıralar)
    final buckets = <String, Map<int, Map<int, List<int>>>>{};

    void add(String? type, int year, double score, int rank) {
      if (type == null || type.isEmpty || score <= 0 || rank <= 0) return;
      buckets
          .putIfAbsent(type.toUpperCase(), () => {})
          .putIfAbsent(year, () => {})
          .putIfAbsent(score.floor(), () => [])
          .add(rank);
    }

    for (final dept in departments) {
      final sd = dept.scoreData;
      if (sd == null) continue;
      final type = dept.effectiveScoreType;
      add(type, sd.year, sd.baseScore, sd.ranking);
      sd.previousYears.forEach(
          (year, yearly) => add(type, year, yearly.baseScore, yearly.ranking));
    }

    final curves = <String, Map<int, _RankCurve>>{};
    buckets.forEach((type, byYear) {
      byYear.forEach((year, yearBuckets) {
        final curve = _RankCurve.fromBuckets(yearBuckets);
        if (curve != null) (curves[type] ??= {})[year] = curve;
      });
    });
    return MultiYearRankEstimator._(curves);
  }

  /// Verilen puanın istenen yıldaki tahmini sırası ve eğrinin veri yılı.
  ///
  /// İstenen yılın eğrisi yoksa en yakın küçük yıla düşer (2026 → 2025);
  /// altında yıl yoksa en yakın büyük yıl kullanılır. Dönen `curveYear`
  /// istenen yıldan farklıysa UI "X verisine göre" etiketi basar.
  ({int rank, int curveYear})? estimateRank(
      double score, String scoreType, int year) {
    if (score <= 0) return null;
    final byYear = _curvesByType[scoreType.toUpperCase()];
    if (byYear == null) return null;
    final curveYear = _resolveYear(byYear, year);
    if (curveYear == null) return null;
    return (rank: byYear[curveYear]!.estimate(score), curveYear: curveYear);
  }

  /// Bu tür + yıl için (fallback dahil) tahmin yapılabiliyor mu.
  bool supports(String scoreType, int year) {
    final byYear = _curvesByType[scoreType.toUpperCase()];
    return byYear != null && _resolveYear(byYear, year) != null;
  }

  static int? _resolveYear(Map<int, _RankCurve> byYear, int year) {
    if (byYear.containsKey(year)) return year;
    int? below;
    int? above;
    for (final y in byYear.keys) {
      if (y < year && (below == null || y > below)) below = y;
      if (y > year && (above == null || y < above)) above = y;
    }
    return below ?? above;
  }
}

class _RankCurve {
  /// Artan sırada kova puanları ve o puanlardaki ln(medyan sıra).
  /// Tekdüze: puan arttıkça lnRank artmaz.
  final List<double> scores;
  final List<double> lnRanks;

  const _RankCurve._(this.scores, this.lnRanks);

  static _RankCurve? fromBuckets(Map<int, List<int>> buckets) {
    if (buckets.length < 2) return null;
    final keys = buckets.keys.toList()..sort();

    final scores = <double>[];
    final lnRanks = <double>[];
    var runningMinLn = double.infinity;
    for (final key in keys) {
      final ranks = buckets[key]!..sort();
      final median = ranks[ranks.length ~/ 2];
      // Tekdüzeleştirme: daha yüksek puan asla daha kötü sıra veremez.
      runningMinLn = math.min(runningMinLn, math.log(median));
      scores.add(key + 0.5); // kova orta noktası
      lnRanks.add(runningMinLn);
    }
    return _RankCurve._(scores, lnRanks);
  }

  int estimate(double score) {
    if (score <= scores.first) return math.exp(lnRanks.first).round();
    if (score >= scores.last) return math.exp(lnRanks.last).round();

    // Binary search: score'un düştüğü aralığın üst ucu.
    var lo = 0;
    var hi = scores.length - 1;
    while (lo + 1 < hi) {
      final mid = (lo + hi) ~/ 2;
      if (scores[mid] <= score) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final t = (score - scores[lo]) / (scores[hi] - scores[lo]);
    final ln = lnRanks[lo] + (lnRanks[hi] - lnRanks[lo]) * t;
    return math.exp(ln).round();
  }
}
