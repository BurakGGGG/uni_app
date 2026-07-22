import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/preference_wizard/domain/rank_estimator.dart';
import 'package:uni_app/features/university/domain/models/department_model.dart';

DepartmentModel _dept(
  String id,
  double baseScore,
  int ranking, {
  Map<int, YearlyScore> previousYears = const {},
}) {
  return DepartmentModel(
    id: id,
    universityId: 'uni',
    name: 'Bölüm $id',
    faculty: 'Fakülte',
    type: 'Lisans',
    language: 'Türkçe',
    scoreData: DepartmentScoreData(
      year: 2025,
      scoreType: 'SAY',
      baseScore: baseScore,
      ranking: ranking,
      quota: 50,
      placedCount: 50,
      previousYears: previousYears,
    ),
  );
}

void main() {
  group('MultiYearRankEstimator', () {
    // 2025: puan arttıkça sıra düşer; 2024 previousYears'ta farklı bir dünya.
    final departments = [
      _dept('a', 300, 200000, previousYears: {
        2024: const YearlyScore(baseScore: 290, ranking: 250000),
      }),
      _dept('b', 350, 100000, previousYears: {
        2024: const YearlyScore(baseScore: 340, ranking: 120000),
      }),
      _dept('c', 400, 40000, previousYears: {
        2024: const YearlyScore(baseScore: 390, ranking: 50000),
      }),
      _dept('d', 450, 10000, previousYears: {
        2024: const YearlyScore(baseScore: 440, ranking: 12000),
      }),
    ];

    late MultiYearRankEstimator estimator;
    setUpAll(() {
      estimator = MultiYearRankEstimator.fromDepartments(departments);
    });

    test('2025 eğrisi scoreData çiftlerinden kurulur', () {
      final result = estimator.estimateRank(350.5, 'SAY', 2025);
      expect(result, isNotNull);
      expect(result!.curveYear, 2025);
      expect(result.rank, closeTo(100000, 1));
    });

    test('2024 eğrisi previousYears çiftlerinden bağımsız kurulur', () {
      final result = estimator.estimateRank(340.5, 'SAY', 2024);
      expect(result, isNotNull);
      expect(result!.curveYear, 2024);
      expect(result.rank, closeTo(120000, 1));
    });

    test('puan arttıkça tahmini sıra artmaz (monotonluk)', () {
      int? previous;
      for (var score = 300.0; score <= 450.0; score += 5) {
        final rank = estimator.estimateRank(score, 'SAY', 2025)!.rank;
        if (previous != null) {
          expect(rank, lessThanOrEqualTo(previous),
              reason: 'puan $score sırayı bozdu');
        }
        previous = rank;
      }
    });

    test('eğrisi olmayan yıl en yakın küçük yıla düşer (2026 → 2025)', () {
      final result = estimator.estimateRank(400.5, 'SAY', 2026);
      expect(result, isNotNull);
      expect(result!.curveYear, 2025);
    });

    test('altında yıl yoksa en yakın büyük yıl kullanılır (2020 → 2024)', () {
      final result = estimator.estimateRank(400.5, 'SAY', 2020);
      expect(result, isNotNull);
      expect(result!.curveYear, 2024);
    });

    test('bilinmeyen puan türü null döner', () {
      expect(estimator.estimateRank(400, 'EA', 2025), isNull);
      expect(estimator.supports('EA', 2025), isFalse);
      expect(estimator.supports('SAY', 2026), isTrue);
    });

    test('geçersiz puan null döner', () {
      expect(estimator.estimateRank(0, 'SAY', 2025), isNull);
      expect(estimator.estimateRank(-10, 'SAY', 2025), isNull);
    });

    test('sıfır/negatif sıra ve puan çiftleri eğriye girmez', () {
      final sparse = MultiYearRankEstimator.fromDepartments([
        _dept('x', 300, 0), // sıra yok
        _dept('y', 0, 5000), // puan yok
      ]);
      expect(sparse.estimateRank(300, 'SAY', 2025), isNull);
    });
  });
}
