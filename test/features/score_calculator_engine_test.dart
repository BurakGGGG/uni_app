import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/score_calculator/domain/score_calculator_engine.dart';
import 'package:uni_app/features/score_calculator/domain/models/score_input.dart';
import 'package:uni_app/features/score_calculator/domain/models/yks_subject.dart';

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

  group('ScoreCalculatorEngine — applicableScoreTypes', () {
    test('sadece TYT netleri → yalnız TYT', () {
      const input = ScoreInput(tytTurkceCorrect: 20, tytFenCorrect: 10);
      expect(ScoreCalculatorEngine.applicableScoreTypes(input), ['TYT']);
    });

    test('TYT şartı yoksa hiçbir tür hesaplanmaz', () {
      // Türkçe ve Temel Mat 0 net — Sosyal/AYT dolu olsa bile liste boş.
      const input = ScoreInput(
        tytSosyalCorrect: 20,
        aytMatCorrect: 30,
        ydtCorrect: 60,
      );
      expect(ScoreCalculatorEngine.applicableScoreTypes(input), isEmpty);
    });

    test('Türkçe 0.5 net eşiği sınırda sağlanır', () {
      // 1 doğru 2 yanlış = 0.5 net → şart tamam.
      const input = ScoreInput(tytTurkceCorrect: 1, tytTurkceWrong: 2);
      expect(ScoreCalculatorEngine.applicableScoreTypes(input), ['TYT']);
    });

    test('AYT Matematik hem SAY hem EA açar', () {
      const input = ScoreInput(tytMatCorrect: 10, aytMatCorrect: 5);
      expect(ScoreCalculatorEngine.applicableScoreTypes(input),
          ['TYT', 'SAY', 'EA']);
    });

    test('AYT Edebiyat hem EA hem SÖZ açar', () {
      const input = ScoreInput(tytTurkceCorrect: 10, aytEdebiyatCorrect: 5);
      expect(ScoreCalculatorEngine.applicableScoreTypes(input),
          ['TYT', 'EA', 'SÖZ']);
    });

    test('YDT neti DİL açar', () {
      const input = ScoreInput(tytTurkceCorrect: 10, ydtCorrect: 40);
      expect(
          ScoreCalculatorEngine.applicableScoreTypes(input), ['TYT', 'DİL']);
    });

    test('tüm testler dolu → beş tür sabit sırada', () {
      const input = ScoreInput(
        tytTurkceCorrect: 20,
        tytMatCorrect: 20,
        aytMatCorrect: 10,
        aytFizikCorrect: 5,
        aytEdebiyatCorrect: 10,
        aytTarih2Correct: 5,
        ydtCorrect: 30,
      );
      expect(ScoreCalculatorEngine.applicableScoreTypes(input),
          ['TYT', 'SAY', 'EA', 'SÖZ', 'DİL']);
    });
  });

  group('ScoreCalculatorEngine — calculateAllTypes (site regresyonu)', () {
    // Aynı doğrulama vakası: TYT 22/12/22/12, AYT SAY 22/12/12/12, OBP 80.
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

    test('uygulanabilir türler: TYT, SAY, EA (AYT Mat EA da açar)', () {
      final result = ScoreCalculatorEngine.calculateAllTypes(input);
      expect(result.scores.map((s) => s.scoreType), ['TYT', 'SAY', 'EA']);
      expect(result.year, 2026);
      expect(result.obpContribution, closeTo(48.0, 0.001));
    });

    test('tür puanları tekli hesapla birebir aynı (siteyle uyumlu)', () {
      final result = ScoreCalculatorEngine.calculateAllTypes(input);
      expect(result.byType('SAY')!.rawScore, closeTo(370.61955, 0.01));
      expect(result.byType('SAY')!.placementScore, closeTo(418.61955, 0.01));
      expect(result.byType('TYT')!.rawScore, closeTo(350.38244, 0.01));
      expect(result.byType('EA')!.rawScore, closeTo(276.32537, 0.01));
    });

    test('ek puan kapalıyken extraPlacementScore null', () {
      final result = ScoreCalculatorEngine.calculateAllTypes(input);
      expect(result.byType('SAY')!.extraPlacementScore, isNull);
    });

    test('yearOverride girdinin yılını ezer', () {
      // Sadece Temel Mat 10 net: 2025 → 145.47 + 10×3.28,
      // 2026 → 150.6785 + 10×3.2484.
      const simple = ScoreInput(selectedYear: 2026, tytMatCorrect: 10);
      final r2025 =
          ScoreCalculatorEngine.calculateAllTypes(simple, yearOverride: 2025);
      final r2026 = ScoreCalculatorEngine.calculateAllTypes(simple);
      expect(r2025.byType('TYT')!.rawScore, closeTo(178.27, 0.01));
      expect(r2026.byType('TYT')!.rawScore, closeTo(183.1625, 0.01));
      expect(r2025.year, 2025);
      expect(r2025.byType('TYT')!.year, 2025);
    });
  });

  group('ScoreInput — OBP tam destek', () {
    const base = ScoreInput(obpScore: 80);

    test('OBP = diploma × 5, katkı = OBP × 0.12', () {
      expect(base.obp, equals(400.0));
      expect(base.obpContribution, closeTo(48.0, 0.001));
    });

    test('katsayı indirimi: geçen yıl yerleşen için OBP × 0.06', () {
      final placed = base.copyWith(placedLastYear: true);
      expect(placed.obpContribution, closeTo(24.0, 0.001));
    });

    test('meslek lisesi kendi alanı ek katkısı OBP × 0.06', () {
      final meslek = base.copyWith(meslekOwnField: true);
      expect(meslek.ekPuanContribution, closeTo(24.0, 0.001));
    });

    test('indirimli meslek ek katkısı OBP × 0.03', () {
      final both =
          base.copyWith(meslekOwnField: true, placedLastYear: true);
      expect(both.ekPuanContribution, closeTo(12.0, 0.001));
    });

    test('checkbox kapalıyken ek katkı 0', () {
      expect(base.ekPuanContribution, equals(0.0));
    });

    test('ek puan açıkken extraPlacementScore = yerleştirme + ek', () {
      final meslek = ScoreInput(
        selectedYear: 2026,
        obpScore: 80,
        tytMatCorrect: 20,
        meslekOwnField: true,
      );
      final result = ScoreCalculatorEngine.calculateAllTypes(meslek);
      final tyt = result.byType('TYT')!;
      expect(tyt.extraPlacementScore!,
          closeTo(tyt.placementScore + 24.0, 0.001));
    });
  });

  group('ScoreInput — direkt net modu', () {
    test('directNet modunda netler directNets\'ten okunur, D/Y yok sayılır', () {
      const input = ScoreInput(
        entryMode: NetEntryMode.directNet,
        directNets: {YksSubject.tytTurkce: 35.25},
        tytTurkceCorrect: 10, // yok sayılmalı
        tytTurkceWrong: 8,
      );
      expect(input.tytTurkceNet, equals(35.25));
      expect(input.tytMatNet, equals(0.0));
    });

    test('net soru sayısına ve teorik minimuma kelepçelenir', () {
      const input = ScoreInput(
        entryMode: NetEntryMode.directNet,
        directNets: {
          YksSubject.tytFen: 99.0, // max 20
          YksSubject.aytTarih1: -99.0, // min -10/4
        },
      );
      expect(input.netOf(YksSubject.tytFen), equals(20.0));
      expect(input.netOf(YksSubject.aytTarih1), equals(-2.5));
    });

    test('aynı netler iki modda aynı puanı verir (site vakası)', () {
      const direct = ScoreInput(
        selectedYear: 2026,
        obpScore: 80,
        entryMode: NetEntryMode.directNet,
        directNets: {
          YksSubject.tytTurkce: 22,
          YksSubject.tytSosyal: 12,
          YksSubject.tytMat: 22,
          YksSubject.tytFen: 12,
          YksSubject.aytMat: 22,
          YksSubject.aytFizik: 12,
          YksSubject.aytKimya: 12,
          YksSubject.aytBiyo: 12,
        },
      );
      final result = ScoreCalculatorEngine.calculateAllTypes(direct);
      expect(result.byType('SAY')!.rawScore, closeTo(370.61955, 0.01));
      expect(result.byType('TYT')!.rawScore, closeTo(350.38244, 0.01));
    });
  });

  group('ScoreInput — serileştirme', () {
    test('toJson/fromJson round-trip tüm alanları korur', () {
      const original = ScoreInput(
        selectedYear: 2025,
        scoreType: 'SAY',
        obpScore: 92.5,
        selectedDepartment: 'Tıp',
        entryMode: NetEntryMode.directNet,
        directNets: {YksSubject.aytMat: 31.75, YksSubject.tytTurkce: 28},
        placedLastYear: true,
        meslekOwnField: true,
        tytTurkceCorrect: 30,
        tytTurkceWrong: 4,
        ydtCorrect: 55,
      );

      final restored = ScoreInput.fromJson(original.toJson());

      expect(restored.selectedYear, original.selectedYear);
      expect(restored.scoreType, original.scoreType);
      expect(restored.obpScore, original.obpScore);
      expect(restored.selectedDepartment, original.selectedDepartment);
      expect(restored.entryMode, original.entryMode);
      expect(restored.directNets, original.directNets);
      expect(restored.placedLastYear, original.placedLastYear);
      expect(restored.meslekOwnField, original.meslekOwnField);
      expect(restored.tytTurkceCorrect, original.tytTurkceCorrect);
      expect(restored.tytTurkceWrong, original.tytTurkceWrong);
      expect(restored.ydtCorrect, original.ydtCorrect);
      // Türetilmiş netler de aynı olmalı.
      expect(restored.aytMatNet, original.aytMatNet);
      expect(restored.totalNet, original.totalNet);
    });

    test('boş/bilinmeyen alanlar güvenli varsayılanlara düşer', () {
      final restored = ScoreInput.fromJson(const {
        'directNets': {'olmayanDers': 5.0},
      });
      expect(restored.selectedYear, 2026);
      expect(restored.entryMode, NetEntryMode.correctWrong);
      expect(restored.directNets, isEmpty);
      expect(restored.placedLastYear, isFalse);
    });
  });

  group('ScoreInput — totalNet', () {
    test('tüm derslerin net toplamı', () {
      const input = ScoreInput(
        tytTurkceCorrect: 20,
        tytTurkceWrong: 4, // 19
        aytMatCorrect: 10, // 10
        ydtCorrect: 5, // 5
      );
      expect(input.totalNet, closeTo(34.0, 0.001));
    });
  });
}
