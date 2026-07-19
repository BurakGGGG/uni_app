import 'dart:collection';

import 'package:flutter/foundation.dart';

/// Client-taraflı rate limiter.
///
/// Cloud Function'lara yapılan çağrıları istemci tarafında
/// hız sınırına tabi tutar. Bu, gereksiz ağ trafiğini, maliyeti
/// ve abuse'u azaltır.
///
/// Kullanım:
/// ```dart
/// final _limiter = RateLimiter(maxRequests: 3, window: Duration(minutes: 1));
///
/// Future<void> doWork() async {
///   if (!_limiter.tryAcquire()) {
///     throw RateLimitExceededException(_limiter.retryAfter);
///   }
///   // ... API çağrısı
/// }
/// ```
class RateLimiter {
  /// Pencere içinde izin verilen maksimum istek sayısı.
  final int maxRequests;

  /// Hız sınırı penceresi.
  final Duration window;

  /// Zaman damgalarını tutan kuyruk (FIFO).
  final Queue<DateTime> _timestamps = Queue<DateTime>();

  RateLimiter({
    required this.maxRequests,
    required this.window,
  });

  /// Yeni bir isteğe izin verilip verilmediğini kontrol eder.
  ///
  /// İzin verilirse `true` döner ve zaman damgasını kaydeder.
  /// Reddedilirse `false` döner — çağıran tarafa [retryAfter] süresini gösterebilirsiniz.
  bool tryAcquire() {
    _pruneExpired();
    if (_timestamps.length >= maxRequests) {
      return false;
    }
    _timestamps.addLast(DateTime.now());
    return true;
  }

  /// Süresi dolmuş zaman damgalarını temizler.
  void _pruneExpired() {
    final now = DateTime.now();
    while (_timestamps.isNotEmpty &&
        now.difference(_timestamps.first) > window) {
      _timestamps.removeFirst();
    }
  }

  /// Rate limit aşıldığında kaç saniye sonra tekrar denenebileceği.
  Duration get retryAfter {
    if (_timestamps.isEmpty) return Duration.zero;
    final oldest = _timestamps.first;
    final diff = window - DateTime.now().difference(oldest);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Kalan istek hakkı.
  int get remaining {
    _pruneExpired();
    return (maxRequests - _timestamps.length).clamp(0, maxRequests);
  }

  /// Limiter'ı sıfırla (örn. yeni oturum açılınca).
  void reset() {
    _timestamps.clear();
  }
}

/// Rate limit aşıldığında fırlatılır.
class RateLimitExceededException implements Exception {
  /// Ne kadar süre sonra tekrar denenebileceği.
  final Duration retryAfter;

  const RateLimitExceededException(this.retryAfter);

  @override
  String toString() =>
      'Rate limit aşıldı. ${retryAfter.inSeconds} saniye sonra tekrar deneyin.';
}

/// Uygulama genelinde kullanılan rate limiter'lar.
///
/// Her servis için özel pencere ve limit değerleri tanımlanmıştır.
class AppRateLimiters {
  AppRateLimiters._();

  /// AI Karşılaştırma Özeti — dakikada 3 istek.
  static final aiComparison = RateLimiter(
    maxRequests: 3,
    window: const Duration(minutes: 1),
  );

  /// AI öneri zenginleştirme (Üni robotu) — dakikada 3 istek.
  /// Sunucu penceresi daha geniş (12/dk); bu istemci emniyeti.
  static final aiRecommendation = RateLimiter(
    maxRequests: 3,
    window: const Duration(minutes: 1),
  );

  /// Genel karşılaştırma — dakikada 10 istek.
  static final comparison = RateLimiter(
    maxRequests: 10,
    window: const Duration(minutes: 1),
  );

  /// Yorum yazma — dakikada 5 istek.
  static final reviewSubmit = RateLimiter(
    maxRequests: 5,
    window: const Duration(minutes: 1),
  );

  /// Arama — saniyede 5 istek (debounce sonrası bile çok fazla olabilir).
  static final search = RateLimiter(
    maxRequests: 5,
    window: const Duration(seconds: 3),
  );

  /// Tüm limiter'ları sıfırla (kullanıcı değişikliğinde).
  static void resetAll() {
    aiComparison.reset();
    aiRecommendation.reset();
    comparison.reset();
    reviewSubmit.reset();
    search.reset();
    debugPrint('[RateLimiter] All limiters reset');
  }
}
