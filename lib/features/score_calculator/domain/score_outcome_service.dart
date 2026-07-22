import '../../preference_wizard/domain/rank_estimator.dart';
import 'models/multi_score_result.dart';
import 'models/score_input.dart';
import 'osym_score_distribution.dart';
import 'score_calculator_engine.dart';

/// Motor puanlarına tahmini başarı sırası ve yüzdelik dilim ekler.
///
/// Sıra tahmini iki kademeli: önce ÖSYM'nin resmî yığınsal dağılım tabloları
/// ([OsymScoreDistribution], 2022–2025), tablo yoksa veri setindeki taban
/// puan/sıra çiftlerinden kurulan [MultiYearRankEstimator] eğrisi.
class ScoreOutcomeService {
  final MultiYearRankEstimator estimator;

  const ScoreOutcomeService({required this.estimator});

  MultiScoreOutcome buildAll(ScoreInput input) {
    final multi = ScoreCalculatorEngine.calculateAllTypes(input);
    return MultiScoreOutcome(
      year: multi.year,
      obpContribution: multi.obpContribution,
      outcomes: [
        for (final score in multi.scores) _outcomeFor(score),
      ],
    );
  }

  /// Aynı netlerin farklı yılların katsayı ve dağılımlarıyla sonucu.
  List<YearOutcome> yearComparison(
    ScoreInput input,
    String scoreType, {
    List<int> years = const [2022, 2023, 2024, 2025, 2026],
  }) {
    final results = <YearOutcome>[];
    for (final year in years) {
      final raw = ScoreCalculatorEngine.calculateRawScoreFor(
        input,
        scoreType,
        yearOverride: year,
      );
      final placement = raw + input.obpContribution;
      final rank = _estimateRank(placement, scoreType, year);
      results.add(YearOutcome(
        year: year,
        placementScore: placement,
        estimatedRank: rank?.rank,
        rankCurveYear: rank?.curveYear,
      ));
    }
    return results;
  }

  ScoreTypeOutcome _outcomeFor(TypeScore score) {
    final rank =
        _estimateRank(score.placementScore, score.scoreType, score.year);

    double? percentile;
    int? percentileYear;
    if (rank != null) {
      final total =
          OsymScoreDistribution.totalCandidates(score.scoreType, score.year);
      if (total != null && total.count > 0) {
        percentile = (rank.rank / total.count * 100).clamp(0.01, 100.0);
        percentileYear = total.year;
      }
    }

    return ScoreTypeOutcome(
      score: score,
      estimatedRank: rank?.rank,
      rankCurveYear: rank?.curveYear,
      percentile: percentile,
      percentileYear: percentileYear,
    );
  }

  ({int rank, int curveYear})? _estimateRank(
      double score, String scoreType, int year) {
    final official = OsymScoreDistribution.estimateRank(score, scoreType, year);
    if (official != null) {
      return (rank: official.rank, curveYear: official.year);
    }
    return estimator.estimateRank(score, scoreType, year);
  }
}
