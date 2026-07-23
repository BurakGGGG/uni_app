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
    if (input.isRankMode) return buildFromRank(input);
    if (input.isScoreMode) return buildFromScore(input);
    final multi = ScoreCalculatorEngine.calculateAllTypes(input);
    return MultiScoreOutcome(
      year: multi.year,
      obpContribution: multi.obpContribution,
      outcomes: [
        for (final score in multi.scores) _outcomeFor(score),
      ],
    );
  }

  /// Sıra modu: netler yerine kullanıcının girdiği başarı sırasından tek
  /// türlük sonuç üretir. Puan resmî dağılımın tersinden gelir, sıra ise
  /// tahmin değil kullanıcının kendi verisidir (`rankIsUserEntered`).
  MultiScoreOutcome buildFromRank(ScoreInput input) {
    final rank = input.enteredRank;
    final type = input.scoreType;
    final derived = (!input.hasValidRank || rank == null)
        ? null
        : OsymScoreDistribution.estimateScore(rank, type, input.selectedYear);
    if (rank == null || derived == null) {
      return MultiScoreOutcome(
        year: input.selectedYear,
        outcomes: const [],
        obpContribution: 0,
      );
    }

    final total =
        OsymScoreDistribution.totalCandidates(type, input.selectedYear);
    double? percentile;
    int? percentileYear;
    if (total != null && total.count > 0) {
      percentile = (rank / total.count * 100).clamp(0.01, 100.0);
      percentileYear = total.year;
    }

    return MultiScoreOutcome(
      year: input.selectedYear,
      obpContribution: 0,
      outcomes: [
        ScoreTypeOutcome(
          score: TypeScore(
            scoreType: type,
            year: input.selectedYear,
            // Sıradan gelen puan zaten OBP'li yerleştirme puanıdır; ham puan
            // ayrıştırılamaz, ikisi de aynı değeri taşır.
            rawScore: derived.score,
            placementScore: derived.score,
          ),
          estimatedRank: rank,
          rankCurveYear: derived.year,
          percentile: percentile,
          percentileYear: percentileYear,
          rankIsUserEntered: true,
        ),
      ],
    );
  }

  /// Puan modu: netler yerine kullanıcının girdiği yerleştirme puanından tek
  /// türlük sonuç üretir. Sıra modunun aynadaki eşi — burada **puan** gerçek,
  /// sıra tahmindir (`rankIsUserEntered: false`).
  MultiScoreOutcome buildFromScore(ScoreInput input) {
    final score = input.enteredScore;
    final type = input.scoreType;
    if (!input.hasValidScore || score == null) {
      return MultiScoreOutcome(
        year: input.selectedYear,
        outcomes: const [],
        obpContribution: 0,
      );
    }

    final rank = _estimateRank(score, type, input.selectedYear);

    double? percentile;
    int? percentileYear;
    if (rank != null) {
      final total =
          OsymScoreDistribution.totalCandidates(type, input.selectedYear);
      if (total != null && total.count > 0) {
        percentile = (rank.rank / total.count * 100).clamp(0.01, 100.0);
        percentileYear = total.year;
      }
    }

    return MultiScoreOutcome(
      year: input.selectedYear,
      obpContribution: 0,
      outcomes: [
        ScoreTypeOutcome(
          score: TypeScore(
            scoreType: type,
            year: input.selectedYear,
            // Girilen puan OBP'li yerleştirme puanıdır; ham puan ayrıştırılamaz.
            rawScore: score,
            placementScore: score,
          ),
          estimatedRank: rank?.rank,
          rankCurveYear: rank?.curveYear,
          percentile: percentile,
          percentileYear: percentileYear,
        ),
      ],
    );
  }

  /// Puan modu yıl karşılaştırması: aynı puan hangi yıl kaçıncı sıra ederdi.
  /// Puan yıldan yıla değişmediği için satırlarda puan sabit, sıra değişkendir.
  List<YearOutcome> scoreYearComparison(
    double score,
    String scoreType, {
    List<int> years = const [2022, 2023, 2024, 2025],
  }) {
    final results = <YearOutcome>[];
    for (final year in years) {
      final official =
          OsymScoreDistribution.estimateRank(score, scoreType, year);
      if (official == null || official.year != year) continue;
      results.add(YearOutcome(
        year: year,
        placementScore: score,
        estimatedRank: official.rank,
        rankCurveYear: year,
      ));
    }
    return results;
  }

  /// Sıra modu yıl karşılaştırması: aynı sıra hangi yıl kaç puana denk gelirdi.
  /// Tablosu olmayan yıllar (2026) atlanır — proxy satır yanıltıcı olurdu.
  List<YearOutcome> rankYearComparison(
    int rank,
    String scoreType, {
    List<int> years = const [2022, 2023, 2024, 2025],
  }) {
    final results = <YearOutcome>[];
    for (final year in years) {
      final derived =
          OsymScoreDistribution.estimateScore(rank, scoreType, year);
      if (derived == null || derived.year != year) continue;
      results.add(YearOutcome(
        year: year,
        placementScore: derived.score,
        estimatedRank: rank,
        rankCurveYear: year,
      ));
    }
    return results;
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
