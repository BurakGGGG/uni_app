import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/router/redirect_utils.dart';

void main() {
  group('localRedirectPathFromParam', () {
    test('uygulama içi path değerlerini kabul eder', () {
      expect(localRedirectPathFromParam('/admin'), '/admin');
      expect(
        localRedirectPathFromParam('/write-review/university/uni1?tab=form'),
        '/write-review/university/uni1?tab=form',
      );
    });

    test('boş, relatif ve dış redirect değerlerini reddeder', () {
      expect(localRedirectPathFromParam(null), isNull);
      expect(localRedirectPathFromParam(''), isNull);
      expect(localRedirectPathFromParam('admin'), isNull);
      expect(localRedirectPathFromParam('https://example.com'), isNull);
      expect(localRedirectPathFromParam('//example.com/admin'), isNull);
    });
  });

  group('routeWithLocalFrom', () {
    test('geçerli from parametresini encode ederek route üretir', () {
      expect(
        routeWithLocalFrom('/register', '/admin/reports'),
        '/register?from=%2Fadmin%2Freports',
      );
    });

    test('geçersiz from parametresini eklemez', () {
      expect(
        routeWithLocalFrom('/register', 'https://example.com'),
        '/register',
      );
    });
  });
}
