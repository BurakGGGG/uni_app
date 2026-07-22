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
}
