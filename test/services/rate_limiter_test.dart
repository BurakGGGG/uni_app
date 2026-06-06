import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/services/rate_limiter.dart';

void main() {
  group('RateLimiter', () {
    late RateLimiter limiter;

    setUp(() {
      limiter = RateLimiter(
        maxRequests: 3,
        window: const Duration(seconds: 2),
      );
    });

    test('izin verir — limit aşılmadığında', () {
      expect(limiter.tryAcquire(), isTrue);
      expect(limiter.tryAcquire(), isTrue);
      expect(limiter.tryAcquire(), isTrue);
    });

    test('reddeder — limit aşıldığında', () {
      limiter.tryAcquire();
      limiter.tryAcquire();
      limiter.tryAcquire();

      expect(limiter.tryAcquire(), isFalse);
    });

    test('remaining doğru hesaplanır', () {
      expect(limiter.remaining, equals(3));

      limiter.tryAcquire();
      expect(limiter.remaining, equals(2));

      limiter.tryAcquire();
      limiter.tryAcquire();
      expect(limiter.remaining, equals(0));
    });

    test('retryAfter — limit aşılınca pozitif değer döner', () {
      limiter.tryAcquire();
      limiter.tryAcquire();
      limiter.tryAcquire();

      final retry = limiter.retryAfter;
      expect(retry.inMilliseconds, greaterThan(0));
      expect(retry.inSeconds, lessThanOrEqualTo(2));
    });

    test('retryAfter — boş kuyrukta sıfır döner', () {
      expect(limiter.retryAfter, equals(Duration.zero));
    });

    test('reset — limiter sıfırlanır', () {
      limiter.tryAcquire();
      limiter.tryAcquire();
      limiter.tryAcquire();
      expect(limiter.tryAcquire(), isFalse);

      limiter.reset();
      expect(limiter.remaining, equals(3));
      expect(limiter.tryAcquire(), isTrue);
    });

    test('pencere süresi dolunca tekrar izin verir', () async {
      // Kısa pencere ile test
      final shortLimiter = RateLimiter(
        maxRequests: 1,
        window: const Duration(milliseconds: 100),
      );

      expect(shortLimiter.tryAcquire(), isTrue);
      expect(shortLimiter.tryAcquire(), isFalse);

      // Pencere süresini bekle
      await Future.delayed(const Duration(milliseconds: 150));

      expect(shortLimiter.tryAcquire(), isTrue);
    });

    test('maxRequests: 1 — tekli limit doğru çalışır', () {
      final singleLimiter = RateLimiter(
        maxRequests: 1,
        window: const Duration(minutes: 1),
      );

      expect(singleLimiter.tryAcquire(), isTrue);
      expect(singleLimiter.tryAcquire(), isFalse);
      expect(singleLimiter.remaining, equals(0));
    });
  });

  group('RateLimitExceededException', () {
    test('toString doğru mesaj üretir', () {
      const exception = RateLimitExceededException(Duration(seconds: 30));
      expect(
        exception.toString(),
        contains('30 saniye'),
      );
    });

    test('retryAfter doğru saklanır', () {
      const exception = RateLimitExceededException(Duration(seconds: 45));
      expect(exception.retryAfter, equals(const Duration(seconds: 45)));
    });
  });

  group('AppRateLimiters', () {
    test('tüm limiter instansları oluşturulabilir', () {
      expect(AppRateLimiters.aiComparison, isNotNull);
      expect(AppRateLimiters.comparison, isNotNull);
      expect(AppRateLimiters.reviewSubmit, isNotNull);
      expect(AppRateLimiters.search, isNotNull);
    });

    test('resetAll tüm limiter\'ları sıfırlar', () {
      // Tüm limiter'ları doldur
      for (int i = 0; i < 3; i++) {
        AppRateLimiters.aiComparison.tryAcquire();
      }
      for (int i = 0; i < 10; i++) {
        AppRateLimiters.comparison.tryAcquire();
      }

      expect(AppRateLimiters.aiComparison.tryAcquire(), isFalse);
      expect(AppRateLimiters.comparison.tryAcquire(), isFalse);

      // Reset
      AppRateLimiters.resetAll();

      expect(AppRateLimiters.aiComparison.tryAcquire(), isTrue);
      expect(AppRateLimiters.comparison.tryAcquire(), isTrue);
    });
  });
}
