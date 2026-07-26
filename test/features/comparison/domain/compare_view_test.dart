import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/comparison/domain/compare_view.dart';

/// Karşılaştırmanın ortak görünüm modeli.
///
/// Kilitlenen sözleşme: **kazanan ilan edilmez** — yalnız satır bazında
/// "kim önde" bilinir. Sıfır ile "veri yok" ayrılır, küçüğün iyi olduğu
/// ölçütler (ÖSYM sırası) ters çalışır ve künye satırları yarışmaz.
void main() {
  CompareRow row(
    List<double?> values, {
    bool higherIsBetter = true,
    double tie = 0,
    bool comparable = true,
  }) =>
      CompareRow(
        label: 'ölçüt',
        values: values,
        display: values.map((v) => v?.toString() ?? '—').toList(),
        higherIsBetter: higherIsBetter,
        tieThreshold: tie,
        comparable: comparable,
      );

  group('CompareRow.leader', () {
    test('büyük değer öndedir', () {
      expect(row([4.4, 4.0]).leader, 0);
      expect(row([4.0, 4.4]).leader, 1);
    });

    test('küçük değerin iyi olduğu ölçütte ters çalışır', () {
      // 12.400. sıra, 18.900'den daha zor/başarılı.
      expect(row([12400, 18900], higherIsBetter: false).leader, 0);
    });

    test('eşik altındaki fark berabere sayılır', () {
      // 4,38 ile 4,36 arasında "önde" demek gürültü.
      expect(row([4.38, 4.36], tie: 0.05).leader, isNull);
      expect(row([4.38, 4.20], tie: 0.05).leader, 0);
    });

    test('tek taraflı veri karşılaştırma değildir', () {
      expect(row([4.4, null]).hasData, isFalse);
      expect(row([4.4, null]).leader, isNull);
    });

    test('künye satırı yarışmaz', () {
      expect(row([1990, 2001], comparable: false).leader, isNull);
    });

    test('üç taraflı satırda en iyisi seçilir', () {
      expect(row([3.0, 4.5, 4.0]).leader, 1);
    });
  });

  group('CompareRow.fraction', () {
    test('büyük iyiyken en büyük değer dolu çubuk alır', () {
      final r = row([100, 50]);
      expect(r.fraction(0), 1.0);
      expect(r.fraction(1), 0.5);
    });

    test('küçük iyiyken en küçük değer dolu çubuk alır', () {
      // Uzun çubuk her zaman "daha iyi" anlamına gelmeli.
      final r = row([10000, 20000], higherIsBetter: false);
      expect(r.fraction(0), 1.0);
      expect(r.fraction(1), 0.5);
    });

    test('veri yoksa çubuk çizilmez', () {
      expect(row([null, 20]).fraction(0), 0);
    });
  });

  group('CompareVerdict', () {
    ComparisonView view(List<CompareRow> rows) => ComparisonView(
          sides: const [
            CompareSide(id: 'a', title: 'İstanbul Teknik Üniversitesi'),
            CompareSide(id: 'b', title: 'Orta Doğu Teknik Üniversitesi'),
          ],
          groups: [CompareGroup(title: 'g', rows: rows)],
        );

    test('kim kaç ölçütte önde sayılır', () {
      final v = view([
        row([5, 3]),
        row([5, 3]),
        row([1, 9]),
        row([2, 2]),
      ]).verdict;

      expect(v.leads, [2, 1]);
      expect(v.tied, 1);
      expect(v.compared, 4);
    });

    test('künye satırları sayıma girmez', () {
      final v = view([
        row([5, 3]),
        row([1990, 2001], comparable: false),
      ]).verdict;

      expect(v.compared, 1);
    });

    test('belirgin üstünlük iki ölçüt farkı ister', () {
      // Bu bir KAZANAN ilanı değil; yalnız Üni'nin hangi cümleyi
      // kuracağını belirler.
      expect(view([row([5, 3]), row([5, 3])]).verdict.clearLead, 0);
      expect(view([row([5, 3]), row([3, 5])]).verdict.clearLead, isNull);
    });
  });

  group('strongestFor', () {
    test('oransal olarak en belirgin üstünlüğü seçer', () {
      final view = ComparisonView(
        sides: const [
          CompareSide(id: 'a', title: 'A'),
          CompareSide(id: 'b', title: 'B'),
        ],
        groups: [
          CompareGroup(
            title: 'g',
            rows: [
              // Mutlak fark büyük ama oran küçük.
              CompareRow(
                label: 'Kontenjan',
                values: const [1100, 1000],
                display: const ['1100', '1000'],
              ),
              // Mutlak fark küçük ama oran büyük — asıl ayırt edici bu.
              CompareRow(
                label: 'Kampüs',
                values: const [4.5, 2.0],
                display: const ['4,5', '2,0'],
              ),
            ],
          ),
        ],
      );

      expect(view.strongestFor(0)?.label, 'Kampüs');
      expect(view.strongestFor(1), isNull);
    });
  });
}
