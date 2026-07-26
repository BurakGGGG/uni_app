import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/preference_lists/presentation/widgets/list_actions_sheet.dart';

/// "Çoğalt" başlığı.
///
/// Depo başlığı 80 karakterle sınırlıyor ve sınırı aşan kaydı reddediyor —
/// uzun adlı bir listeyi çoğaltmak sessizce hata vermemeli.
void main() {
  test('kopya eki başlığın sonuna gelir', () {
    expect(copyTitle('Sayısal Planım', 'kopya'), 'Sayısal Planım (kopya)');
  });

  test('80 karakter sınırı aşılmaz, taban kırpılır', () {
    final long = 'A' * 100;
    final result = copyTitle(long, 'kopya');

    expect(result.length, lessThanOrEqualTo(80));
    expect(result.endsWith(' (kopya)'), isTrue);
  });

  test('sınıra tam oturan başlık kırpılmaz', () {
    // 80 - ' (kopya)'.length = 72 karakter tam sığar.
    final fits = 'B' * 72;
    final result = copyTitle(fits, 'kopya');

    expect(result, '$fits (kopya)');
    expect(result.length, 80);
  });

  test('İngilizce ek de aynı sınıra uyar', () {
    expect(copyTitle('A' * 100, 'copy').length, lessThanOrEqualTo(80));
  });
}
