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
