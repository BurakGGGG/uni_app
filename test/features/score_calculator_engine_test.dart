import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/score_calculator/domain/score_calculator_engine.dart';
import 'package:uni_app/features/score_calculator/domain/models/score_input.dart';

void main() {
  group('ScoreInput — Net Hesaplama', () {
    test('doğru net formülü: D - (Y / 4)', () {
      const input = ScoreInput(
        scoreType: 'TYT',
        obpScore: 80,
        selectedDepartment: 'Test',
        tytTurkceCorrect: 32,
        tytTurkceWrong: 8,
      );

      // 32 - (8 / 4) = 32 - 2 = 30
      expect(input.tytTurkceNet, equals(30.0));
    });

    test('yanlış = 0 iken net = doğru sayısı', () {
      const input = ScoreInput(
        scoreType: 'TYT',
        obpScore: 80,
        selectedDepartment: 'Test',
        tytMatCorrect: 25,
        tytMatWrong: 0,
      );

      expect(input.tytMatNet, equals(25.0));
    });

    test('doğru = 0, yanlış > 0 → negatif net', () {
      const input = ScoreInput(
        scoreType: 'TYT',
        obpScore: 80,
        selectedDepartment: 'Test',
        tytFenCorrect: 0,
        tytFenWrong: 4,
      );

      // 0 - (4/4) = -1.0
      expect(input.tytFenNet, equals(-1.0));
    });

    test('OBP contribution = obpScore × 0.6', () {
      const input = ScoreInput(
        scoreType: 'TYT',
        obpScore: 85,
        selectedDepartment: 'Test',
      );

      expect(input.obpContribution, closeTo(51.0, 0.01));
    });

    test('OBP contribution — minimum (0)', () {
      const input = ScoreInput(
        scoreType: 'TYT',
        obpScore: 0,
        selectedDepartment: 'Test',
      );

      expect(input.obpContribution, equals(0.0));
    });

    test('OBP contribution — maximum (100)', () {
      const input = ScoreInput(
        scoreType: 'TYT',
        obpScore: 100,
        selectedDepartment: 'Test',
      );

      expect(input.obpContribution, equals(60.0));
    });

    test('copyWith değerleri doğru günceller', () {
      const original = ScoreInput(
        scoreType: 'TYT',
        obpScore: 80,
        selectedDepartment: 'Test',
        tytTurkceCorrect: 20,
      );

      final updated = original.copyWith(
        tytTurkceCorrect: 35,
        scoreType: 'SAY',
      );

      expect(updated.tytTurkceCorrect, equals(35));
      expect(updated.scoreType, equals('SAY'));
      // Değiştirilmeyenler aynı kalmalı
      expect(updated.obpScore, equals(80));
      expect(updated.selectedDepartment, equals('Test'));
    });
  });

  group('ScoreCalculatorEngine — TYT Hesaplama', () {
    test('tüm netler 0 iken sadece base score döner', () {
      const input = ScoreInput(
        scoreType: 'TYT',
        selectedYear: 2025,
        obpScore: 0,
        selectedDepartment: 'Test',
      );

      final rawScore = ScoreCalculatorEngine.calculateRawScore(input);
      // 2025 TYT base score: 145.47
      expect(rawScore, closeTo(145.47, 0.1));
    });

    test('pozitif netlerle puan artar', () {
      const input = ScoreInput(
        scoreType: 'TYT',
        selectedYear: 2025,
        obpScore: 80,
        selectedDepartment: 'Test',
        tytTurkceCorrect: 30,
        tytTurkceWrong: 2,
        tytSosyalCorrect: 15,
        tytSosyalWrong: 1,
        tytMatCorrect: 25,
        tytMatWrong: 3,
        tytFenCorrect: 10,
        tytFenWrong: 2,
      );

      final rawScore = ScoreCalculatorEngine.calculateRawScore(input);
      // Sıfır netlere göre kesinlikle daha yüksek olmalı
      expect(rawScore, greaterThan(145.47));
    });

    test('placement score = raw + OBP contribution', () {
      const input = ScoreInput(
        scoreType: 'TYT',
        selectedYear: 2025,
        obpScore: 80,
        selectedDepartment: 'Test',
        tytTurkceCorrect: 20,
        tytTurkceWrong: 0,
      );

      final rawScore = ScoreCalculatorEngine.calculateRawScore(input);
      final placementScore =
          ScoreCalculatorEngine.calculatePlacementScore(input);
      
      expect(placementScore, closeTo(rawScore + 48.0, 0.01));
    });
  });

  group('ScoreCalculatorEngine — SAY Hesaplama', () {
    test('SAY puanı hesaplanır', () {
      const input = ScoreInput(
        scoreType: 'SAY',
        selectedYear: 2025,
        obpScore: 85,
        selectedDepartment: 'Bilgisayar Mühendisliği',
        tytTurkceCorrect: 30,
        tytTurkceWrong: 2,
        tytSosyalCorrect: 15,
        tytSosyalWrong: 1,
        tytMatCorrect: 30,
        tytMatWrong: 2,
        tytFenCorrect: 12,
        tytFenWrong: 2,
        aytMatCorrect: 30,
        aytMatWrong: 4,
        aytFizikCorrect: 10,
        aytFizikWrong: 2,
        aytKimyaCorrect: 8,
        aytKimyaWrong: 3,
        aytBiyoCorrect: 5,
        aytBiyoWrong: 1,
      );

      final rawScore = ScoreCalculatorEngine.calculateRawScore(input);
      // SAY base score 2025: 132.87 + hesaplanmış puan
      expect(rawScore, greaterThan(132.87));
      // Mantıklı aralıkta olmalı (100-500)
      expect(rawScore, lessThan(500));
    });
  });

  group('ScoreCalculatorEngine — Bilinmeyen skor tipi', () {
    test('bilinmeyen scoreType 0 döner', () {
      const input = ScoreInput(
        scoreType: 'UNKNOWN',
        obpScore: 80,
        selectedDepartment: 'Test',
      );

      final score = ScoreCalculatorEngine.calculateRawScore(input);
      expect(score, equals(0));
    });
  });

  group('ScoreCalculatorEngine — 2026 Hesaplama', () {
    test('tüm netler 0 iken 2026 base score döner', () {
      const input = ScoreInput(
        scoreType: 'TYT',
        selectedYear: 2026,
        obpScore: 0,
        selectedDepartment: 'Test',
      );

      final rawScore = ScoreCalculatorEngine.calculateRawScore(input);
      // 2026 TYT base score: 150.6785
      expect(rawScore, closeTo(150.6785, 0.001));
    });

    test('2026 SAY puanı katsayılarla tutarlı hesaplanır', () {
      const input = ScoreInput(
        scoreType: 'SAY',
        selectedYear: 2026,
        obpScore: 0,
        selectedDepartment: 'Test',
        tytTurkceCorrect: 40,
        aytMatCorrect: 40,
      );

      final rawScore = ScoreCalculatorEngine.calculateRawScore(input);
      // 121.6515 + 40×1.2300 + 39×3.0215 (40. net iptal) = 288.69
      expect(rawScore, closeTo(288.69, 0.01));
    });

    test('varsayılan yıl 2026', () {
      const input = ScoreInput(
        scoreType: 'TYT',
        obpScore: 0,
        selectedDepartment: 'Test',
      );

      expect(input.selectedYear, equals(2026));
    });
  });

  group('ScoreCalculatorEngine — 2026 site regresyonu (yks-puan.hesaplama.net)', () {
    // Gerçek doğrulama vakası: TYT 22/12/22/12, AYT SAY 22/12/12/12, OBP 80.
    // Beklenen değerler sitenin 2026 sonuçları (22 Temmuz 2026).
    const input = ScoreInput(
      scoreType: 'SAY',
      selectedYear: 2026,
      obpScore: 80,
      selectedDepartment: 'Test',
      tytTurkceCorrect: 22,
      tytSosyalCorrect: 12,
      tytMatCorrect: 22,
      tytFenCorrect: 12,
      aytMatCorrect: 22,
      aytFizikCorrect: 12,
      aytKimyaCorrect: 12,
      aytBiyoCorrect: 12,
    );

    test('SAY ham puan siteyle uyumlu (370.61955)', () {
      expect(ScoreCalculatorEngine.calculateRawScore(input),
          closeTo(370.61955, 0.01));
    });

    test('Y-SAY yerleştirme puanı siteyle uyumlu (418.61955)', () {
      expect(ScoreCalculatorEngine.calculatePlacementScore(input),
          closeTo(418.61955, 0.01));
    });

    test('TYT ham puan siteyle uyumlu (350.38244)', () {
      final tyt = input.copyWith(scoreType: 'TYT');
      expect(ScoreCalculatorEngine.calculateRawScore(tyt),
          closeTo(350.38244, 0.01));
    });

    test('EA ham puan siteyle uyumlu (276.32537)', () {
      final ea = input.copyWith(scoreType: 'EA');
      expect(ScoreCalculatorEngine.calculateRawScore(ea),
          closeTo(276.32537, 0.01));
    });
  });

  group('ScoreCalculatorEngine — 2026 iptal soru tavanları', () {
    test('2026 AYT Matematik 40. net puan getirmez', () {
      const base = ScoreInput(
        scoreType: 'SAY',
        selectedYear: 2026,
        obpScore: 0,
        selectedDepartment: 'Test',
        tytTurkceCorrect: 10,
      );
      final at39 = ScoreCalculatorEngine.calculateRawScore(
          base.copyWith(aytMatCorrect: 39));
      final at40 = ScoreCalculatorEngine.calculateRawScore(
          base.copyWith(aytMatCorrect: 40));
      expect(at40, closeTo(at39, 0.0001));
    });

    test('2026 AYT Edebiyat 24. net puan getirmez (SÖZ)', () {
      const base = ScoreInput(
        scoreType: 'SÖZ',
        selectedYear: 2026,
        obpScore: 0,
        selectedDepartment: 'Test',
        tytTurkceCorrect: 10,
      );
      final at23 = ScoreCalculatorEngine.calculateRawScore(
          base.copyWith(aytEdebiyatCorrect: 23));
      final at24 = ScoreCalculatorEngine.calculateRawScore(
          base.copyWith(aytEdebiyatCorrect: 24));
      expect(at24, closeTo(at23, 0.0001));
    });

    test('2025\'te tavan yok — 40. matematik neti puan getirir', () {
      const base = ScoreInput(
        scoreType: 'SAY',
        selectedYear: 2025,
        obpScore: 0,
        selectedDepartment: 'Test',
        tytTurkceCorrect: 10,
      );
      final at39 = ScoreCalculatorEngine.calculateRawScore(
          base.copyWith(aytMatCorrect: 39));
      final at40 = ScoreCalculatorEngine.calculateRawScore(
          base.copyWith(aytMatCorrect: 40));
      expect(at40 - at39, closeTo(2.89, 0.01));
    });
  });

  group('ScoreCalculatorEngine — Yıl fallback', () {
    test('desteklenmeyen yıl default (2026) katsayılarını kullanır', () {
      const input2026 = ScoreInput(
        scoreType: 'TYT',
        selectedYear: 2026,
        obpScore: 0,
        selectedDepartment: 'Test',
        tytTurkceCorrect: 20,
        tytTurkceWrong: 0,
      );

      const inputUnknown = ScoreInput(
        scoreType: 'TYT',
        selectedYear: 9999,
        obpScore: 0,
        selectedDepartment: 'Test',
        tytTurkceCorrect: 20,
        tytTurkceWrong: 0,
      );

      final score2026 = ScoreCalculatorEngine.calculateRawScore(input2026);
      final scoreUnknown = ScoreCalculatorEngine.calculateRawScore(inputUnknown);

      // 2026 katsayılarına fallback etmeli
      expect(scoreUnknown, closeTo(score2026, 0.01));
    });
  });
}
