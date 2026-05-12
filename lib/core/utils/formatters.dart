import 'package:intl/intl.dart';

/// Türkçe locale (tr_TR) için merkezi sayı/tarih formatlayıcılar.
///
/// Kullanmadan önce `main.dart` içinde
/// `initializeDateFormatting('tr_TR')` çağrıldığından emin ol — bu olmadan
/// `DateFormat` çağrıları "Locale data has not been initialized" hatası verir.
///
/// Örnek:
/// ```dart
/// AppFormatters.rating(4.36789)  // → '4,4'
/// AppFormatters.score(450789.5)  // → '450.789,5'
/// AppFormatters.month(DateTime.now())  // → 'May 2026'
/// AppFormatters.compactNumber(1500)  // → '1,5 B'
/// AppFormatters.percent(0.85)  // → '%85'
/// ```
class AppFormatters {
  AppFormatters._();

  static const String _locale = 'tr_TR';

  // ─── Sayılar ────────────────────────────────────────────────
  static final NumberFormat _ratingFormat = NumberFormat('#0.0', _locale);
  static final NumberFormat _scoreFormat = NumberFormat('#,##0.0', _locale);
  static final NumberFormat _integerFormat = NumberFormat('#,##0', _locale);
  static final NumberFormat _compactFormat = NumberFormat.compact(locale: _locale);
  static final NumberFormat _percentFormat = NumberFormat.percentPattern(_locale);

  // ─── Tarih ──────────────────────────────────────────────────
  static final DateFormat _monthFormat = DateFormat('MMM yyyy', _locale);
  static final DateFormat _dayMonthFormat = DateFormat('d MMM', _locale);
  static final DateFormat _fullDateFormat = DateFormat('d MMMM yyyy', _locale);
  static final DateFormat _shortDateFormat = DateFormat('d.M.yyyy', _locale);

  // ─── Public API ─────────────────────────────────────────────

  /// 4.5 ★ gibi rating değeri. null veya 0 ise '—' döner.
  static String rating(num? value) {
    if (value == null || value == 0) return '—';
    return _ratingFormat.format(value);
  }

  /// 450.789,5 gibi puan değeri (binlik ayraç ile).
  static String score(num? value) {
    if (value == null) return '—';
    return _scoreFormat.format(value);
  }

  /// 12.345 gibi tam sayı (binlik ayraç ile).
  static String integer(num? value) {
    if (value == null) return '—';
    return _integerFormat.format(value);
  }

  /// 1.500 → '1,5 B' · 2.300.000 → '2,3 Mn' gibi kompakt gösterim.
  static String compactNumber(num? value) {
    if (value == null) return '—';
    return _compactFormat.format(value);
  }

  /// 0.85 → '%85' gibi yüzde formatı.
  static String percent(num? fraction) {
    if (fraction == null) return '—';
    return _percentFormat.format(fraction);
  }

  /// Sıralama (1.234 gibi). null veya 0 ise '—' döner.
  static String ranking(int? value) {
    if (value == null || value == 0) return '—';
    return _integerFormat.format(value);
  }

  /// 'May 2026' gibi kısa ay+yıl.
  static String month(DateTime date) => _monthFormat.format(date);

  /// '12 May' gibi gün+ay.
  static String dayMonth(DateTime date) => _dayMonthFormat.format(date);

  /// '12 Mayıs 2026' gibi tam tarih.
  static String fullDate(DateTime date) => _fullDateFormat.format(date);

  /// '12.5.2026' gibi kısa tarih (slash yerine nokta — TR konvansiyonu).
  static String shortDate(DateTime date) => _shortDateFormat.format(date);

  /// İki sayı arasındaki delta'yı '+1,2' veya '-0,5' biçiminde döner.
  /// Karşılaştırma kartlarındaki delta pill'leri için kullanışlı.
  static String delta(num value, {int fractionDigits = 1}) {
    if (value == 0) return '0';
    final formatted = value.abs().toStringAsFixed(fractionDigits).replaceAll('.', ',');
    return value > 0 ? '+$formatted' : '-$formatted';
  }
}
