import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/score_calculator/domain/osym_score_distribution.dart';

void main() {
  group('OsymScoreDistribution — resmî çapalar', () {
    test('çapa üstündeki puan tepe değere kelepçelenir', () {
      // 2025 TYT 550+ → 14 aday.
      final result = OsymScoreDistribution.estimateRank(560, 'TYT', 2025);
      expect(result!.rank, 14);
      expect(result.year, 2025);
    });

    test('çapa puanında resmî değer birebir döner', () {
      // 2025 SAY 450 → 46.142; 2025 EA 410 → 20.244.
      expect(OsymScoreDistribution.estimateRank(450, 'SAY', 2025)!.rank, 46142);
      expect(OsymScoreDistribution.estimateRank(410, 'EA', 2025)!.rank, 20244);
    });

    test('çapalar arası log-uzayda enterpole edilir', () {
      // 2025 SAY 460: 470→29.410 ile 450→46.142 arasında, geometrik ortalama
      // ≈ 36.838. Doğrusal ortalama (37.776) DEĞİL.
      final result = OsymScoreDistribution.estimateRank(460, 'SAY', 2025)!;
      expect(result.rank, closeTo(36838, 50));
    });

    test('tablonun altındaki puan toplam aday sayısına düşer', () {
      final result = OsymScoreDistribution.estimateRank(50, 'SAY', 2025)!;
      expect(result.rank, 1291531);
    });

    test('2026 tablosu yok → 2025 proxy (yıl etiketiyle)', () {
      final result = OsymScoreDistribution.estimateRank(450, 'SAY', 2026)!;
      expect(result.rank, 46142);
      expect(result.year, 2025);
    });

    test('eski yıllar kendi tablosunu kullanır', () {
      // 2022 SAY 450 → 56.594; 2023 EA 450 → 6.403; 2024 DİL 450 → 8.698.
      expect(OsymScoreDistribution.estimateRank(450, 'SAY', 2022)!.rank, 56594);
      expect(OsymScoreDistribution.estimateRank(450, 'EA', 2023)!.rank, 6403);
      expect(OsymScoreDistribution.estimateRank(450, 'DİL', 2024)!.rank, 8698);
    });

    test('toplam aday sayıları (dilim paydası)', () {
      expect(OsymScoreDistribution.totalCandidates('TYT', 2025)!.count,
          2310579);
      expect(OsymScoreDistribution.totalCandidates('SÖZ', 2025)!.count,
          1174047);
      expect(OsymScoreDistribution.totalCandidates('DİL', 2022)!.count,
          123163);
      // 2026 → 2025 toplamı proxy olarak döner.
      final proxy = OsymScoreDistribution.totalCandidates('SAY', 2026)!;
      expect(proxy.count, 1291531);
      expect(proxy.year, 2025);
    });

    test('geçersiz girdi null döner', () {
      expect(OsymScoreDistribution.estimateRank(0, 'SAY', 2025), isNull);
      expect(OsymScoreDistribution.estimateRank(400, 'YOK', 2025), isNull);
      expect(OsymScoreDistribution.totalCandidates('YOK', 2025), isNull);
    });
  });

  group('OsymScoreDistribution — sıra → puan (ters dönüşüm)', () {
    test('çapa sırasında resmî puan eşiği birebir döner', () {
      // 2025 SAY 46.142 → 450; 2025 EA 20.244 → 410.
      expect(OsymScoreDistribution.estimateScore(46142, 'SAY', 2025)!.score,
          closeTo(450, 0.01));
      expect(OsymScoreDistribution.estimateScore(20244, 'EA', 2025)!.score,
          closeTo(410, 0.01));
    });

    test('gidiş-dönüş: estimateScore(estimateRank(p)) ≈ p', () {
      // Tolerans 1 puan: ileri yön sırayı TAM SAYIYA yuvarlıyor, tepe
      // çapalarda aday sayısı tek haneli olabildiği için (2025 SÖZ 530 → 7)
      // bu yuvarlama yarım puana kadar geri yansıyor.
      for (final type in ['TYT', 'SAY', 'EA', 'SÖZ', 'DİL']) {
        for (final year in [2022, 2023, 2024, 2025]) {
          for (final score in [520.0, 460.0, 400.0, 330.0, 260.0]) {
            final rank =
                OsymScoreDistribution.estimateRank(score, type, year)!.rank;
            final back =
                OsymScoreDistribution.estimateScore(rank, type, year)!;
            expect(back.score, closeTo(score, 1.0),
                reason: '$type/$year $score → $rank → ${back.score}');
            expect(back.clamped, isFalse);
          }
        }
      }
    });

    test('gidiş-dönüş: estimateRank(estimateScore(s)) ≈ s (asıl yön)', () {
      // Kullanıcının kullandığı yön sıra→puan olduğundan sıra uzayında
      // kapanışı da doğrula: sapma binde birin altında kalmalı.
      for (final type in ['TYT', 'SAY', 'EA', 'SÖZ', 'DİL']) {
        for (final rank in [5000, 45000, 150000, 400000]) {
          final result =
              OsymScoreDistribution.estimateScore(rank, type, 2025)!;
          // Tür başına aday sayısı farklı (2025 DİL toplam 140.657) — tablo
          // dışına düşen sıra kelepçelenir, orada kapanış beklenemez.
          if (result.clamped) continue;
          final back =
              OsymScoreDistribution.estimateRank(result.score, type, 2025)!
                  .rank;
          expect(back, closeTo(rank, rank * 0.001),
              reason: '$type $rank → ${result.score} → $back');
        }
      }
    });

    test('doğrulanmış 2025 SAY değerleri', () {
      double at(int rank) =>
          OsymScoreDistribution.estimateScore(rank, 'SAY', 2025)!.score;
      expect(at(500), closeTo(537.67, 0.05));
      expect(at(45000), closeTo(451.11, 0.05));
      expect(at(300000), closeTo(302.50, 0.05));
    });

    test('tablo dışı sıralar uçlara kelepçelenir', () {
      // 2025 SAY en üst çapa 550 → 57 aday; daha iyi sıra tek puana çözülemez.
      final top = OsymScoreDistribution.estimateScore(20, 'SAY', 2025)!;
      expect(top.score, 550);
      expect(top.clamped, isTrue);

      final bottom = OsymScoreDistribution.estimateScore(2000000, 'SAY', 2025)!;
      expect(bottom.score, 115);
      expect(bottom.clamped, isTrue);
    });

    test('kuyruktaki düz plato üst eşiğe çözülür', () {
      // 2025 TYT: (150, 2310553) → (130, 2310579) → (115, 2310579).
      // 2.310.579 zaten son çapa (kelepçe); platoya düşen 2.310.570 ise
      // 150–130 kirişinde değil, 130 eşiğinde durur.
      final onPlateau =
          OsymScoreDistribution.estimateScore(2310579, 'TYT', 2025)!;
      expect(onPlateau.score, 115);
      expect(onPlateau.clamped, isTrue);
    });

    test('2026 tablosu yok → 2025 proxy (yıl etiketiyle)', () {
      final result = OsymScoreDistribution.estimateScore(46142, 'SAY', 2026)!;
      expect(result.score, closeTo(450, 0.01));
      expect(result.year, 2025);
    });

    test('geçersiz girdi null döner', () {
      expect(OsymScoreDistribution.estimateScore(0, 'SAY', 2025), isNull);
      expect(OsymScoreDistribution.estimateScore(-5, 'SAY', 2025), isNull);
      expect(OsymScoreDistribution.estimateScore(1000, 'YOK', 2025), isNull);
    });
  });
}
