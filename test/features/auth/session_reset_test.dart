import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/auth/presentation/providers/session_reset_provider.dart';

void main() {
  group('SessionReset.shouldClear — hangi geçiş yereli boşaltır', () {
    test('ilk gözlem asla temizlemez (dönen kullanıcı korunur)', () {
      // Cihazı açan giriş yapmış kullanıcının cihaz-yerel verisi silinmemeli.
      expect(
        SessionReset.shouldClear(seen: false, lastUid: null, nextUid: 'a'),
        isFalse,
      );
      expect(
        SessionReset.shouldClear(seen: false, lastUid: null, nextUid: null),
        isFalse,
      );
    });

    test('çıkış (kullanıcı → null) temizler', () {
      expect(
        SessionReset.shouldClear(seen: true, lastUid: 'a', nextUid: null),
        isTrue,
      );
    });

    test('hesap değişimi (a → b) temizler', () {
      expect(
        SessionReset.shouldClear(seen: true, lastUid: 'a', nextUid: 'b'),
        isTrue,
      );
    });

    test('misafir → giriş (null → a) TEMİZLEMEZ — veriler hesaba taşınır', () {
      expect(
        SessionReset.shouldClear(seen: true, lastUid: null, nextUid: 'a'),
        isFalse,
      );
    });

    test('aynı kimlik yeniden yayınlanırsa (token yenileme) temizlemez', () {
      expect(
        SessionReset.shouldClear(seen: true, lastUid: 'a', nextUid: 'a'),
        isFalse,
      );
      expect(
        SessionReset.shouldClear(seen: true, lastUid: null, nextUid: null),
        isFalse,
      );
    });
  });
}
