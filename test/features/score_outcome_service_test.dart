import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/preference_wizard/domain/rank_estimator.dart';
import 'package:uni_app/features/score_calculator/domain/models/score_input.dart';
import 'package:uni_app/features/score_calculator/domain/score_outcome_service.dart';

void main() {
  // Resmî ÖSYM tabloları tüm türleri kapsadığından boş estimator yeterli;
  // estimator yalnız tablo bulunamazsa devreye girer.
  final service = ScoreOutcomeService(
    estimator: MultiYearRankEstimator.fromDepartments(const []),
  );

  // Site regresyon vakası: Y-SAY 418.61955, TYT 398.38..., EA 324.32...
  const input = ScoreInput(
    selectedYear: 2026,
    obpScore: 80,
    tytTurkceCorrect: 22,
    tytSosyalCorrect: 12,
    tytMatCorrect: 22,
    tytFenCorrect: 12,
    aytMatCorrect: 22,
    aytFizikCorrect: 12,
    aytKimyaCorrect: 12,
    aytBiyoCorrect: 12,
  );

  group('ScoreOutcomeService.buildAll', () {
    test('her uygulanabilir türe sıra + dilim ekler', () {
      final outcome = service.buildAll(input);
      expect(outcome.outcomes.map((o) => o.score.scoreType),
          ['TYT', 'SAY', 'EA']);
      for (final o in outcome.outcomes) {
        expect(o.estimatedRank, isNotNull,
            reason: '${o.score.scoreType} sırasız kaldı');
        expect(o.percentile, isNotNull);
        expect(o.percentile, greaterThan(0));
        expect(o.percentile, lessThanOrEqualTo(100));
      }
    });

    test('2026 puanı 2025 tablosuna proxy — etiket bilgisi dolu', () {
      final outcome = service.buildAll(input);
      final say = outcome.byType('SAY')!;
      expect(say.rankCurveYear, 2025);
      expect(say.rankIsProxy, isTrue);
      expect(say.percentileYear, 2025);
    });

    test('sıra resmî tabloyla tutarlı (Y-SAY ≈ 418.6 → ~85 bin)', () {
      // 2025 SAY tablosunda 430 → 65.449 ve 410 → 87.117; 418.6 arada olmalı.
      final say = service.buildAll(input).byType('SAY')!;
      expect(say.estimatedRank, greaterThan(65449));
      expect(say.estimatedRank, lessThan(87117));
    });

    test('dilim = sıra / toplam aday (SAY 2025 toplamı 1.291.531)', () {
      final say = service.buildAll(input).byType('SAY')!;
      final expected = say.estimatedRank! / 1291531 * 100;
      expect(say.percentile, closeTo(expected, 0.001));
    });

    test('best en düşük sıralı türü seçer', () {
      final outcome = service.buildAll(input);
      final ranks = {
        for (final o in outcome.outcomes) o.score.scoreType: o.estimatedRank!,
      };
      final minType = ranks.entries
          .reduce((a, b) => a.value <= b.value ? a : b)
          .key;
      expect(outcome.best!.score.scoreType, minType);
    });
  });

  group('ScoreOutcomeService.yearComparison', () {
    test('beş yılın puan ve sırası; 2026 satırı proxy etiketli', () {
      final rows = service.yearComparison(input, 'SAY');
      expect(rows.map((r) => r.year), [2022, 2023, 2024, 2025, 2026]);
      for (final row in rows) {
        expect(row.placementScore, greaterThan(0));
        expect(row.estimatedRank, isNotNull, reason: '${row.year} sırasız');
      }
      final r2025 = rows.firstWhere((r) => r.year == 2025);
      final r2026 = rows.firstWhere((r) => r.year == 2026);
      expect(r2025.rankIsProxy, isFalse);
      expect(r2026.rankIsProxy, isTrue);
      expect(r2026.rankCurveYear, 2025);
    });

    test('her yıl kendi resmî tablosunu kullanır', () {
      final rows = service.yearComparison(input, 'SAY');
      for (final row in rows.where((r) => r.year <= 2025)) {
        expect(row.rankCurveYear, row.year);
      }
    });
  });
}
