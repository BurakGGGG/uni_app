import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:uni_app/core/utils/formatters.dart';

void main() {
  setUpAll(() async {
    // fullDate/shortDate gibi DateFormat çağrıları için tr_TR locale verisi gerekli.
    await initializeDateFormatting('tr_TR');
  });

  group('AppFormatters.rating', () {
    test('tek ondalık ve virgülle formatlar', () {
      expect(AppFormatters.rating(4.36789), '4,4');
    });

    test('null ve 0 için tire döner', () {
      expect(AppFormatters.rating(null), '—');
      expect(AppFormatters.rating(0), '—');
    });
  });

  group('AppFormatters.score', () {
    test('binlik ayraç nokta, ondalık virgül (TR)', () {
      expect(AppFormatters.score(450789.5), '450.789,5');
    });

    test('null için tire döner', () {
      expect(AppFormatters.score(null), '—');
    });
  });

  group('AppFormatters.integer / ranking', () {
    test('integer binlik ayraçla formatlar', () {
      expect(AppFormatters.integer(12345), '12.345');
      expect(AppFormatters.integer(null), '—');
    });

    test('ranking 0/null için tire, diğerinde binlik ayraç', () {
      expect(AppFormatters.ranking(0), '—');
      expect(AppFormatters.ranking(null), '—');
      expect(AppFormatters.ranking(1234), '1.234');
    });
  });

  group('AppFormatters.compactNumber', () {
    test('küçük sayı olduğu gibi kalır', () {
      expect(AppFormatters.compactNumber(999), '999');
    });

    test('null için tire döner', () {
      expect(AppFormatters.compactNumber(null), '—');
    });
  });

  group('AppFormatters.percent', () {
    test('kesri yüzdeye çevirir', () {
      expect(AppFormatters.percent(0.85), '%85');
    });

    test('null için tire döner', () {
      expect(AppFormatters.percent(null), '—');
    });
  });

  group('AppFormatters.delta', () {
    test('pozitif değere + öneki ekler', () {
      expect(AppFormatters.delta(1.2), '+1,2');
    });

    test('negatif değere - öneki ekler', () {
      expect(AppFormatters.delta(-0.5), '-0,5');
    });

    test('sıfır için işaretsiz 0 döner', () {
      expect(AppFormatters.delta(0), '0');
    });
  });

  group('AppFormatters tarih', () {
    test('shortDate nokta ayraçlı TR formatı', () {
      expect(AppFormatters.shortDate(DateTime(2026, 5, 12)), '12.5.2026');
    });

    test('fullDate Türkçe ay adını içerir', () {
      final formatted = AppFormatters.fullDate(DateTime(2026, 5, 12));
      expect(formatted, contains('Mayıs'));
      expect(formatted, contains('2026'));
    });
  });
}
