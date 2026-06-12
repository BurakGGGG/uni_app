import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/analytics_event.dart';

/// Analytics event tracking servisi (Singleton).
///
/// Her event'te Cloud Function üzerinden iki Firestore dokümanı güncellenir:
/// 1. `analytics/counters` → tüm zamanlar toplamı
/// 2. `analytics/daily_{yyyy-MM-dd}` → günlük kırılım
///
/// Tüm işlemler fire-and-forget yapılır, ana akış hiçbir zaman
/// analytics hatası yüzünden bozulmaz.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  /// Bir analytics event'i kaydet.
  ///
  /// Fire-and-forget: Bu metodu `unawaited` ile çağırabilirsiniz.
  /// Hata olursa sadece loglanır, fırlatılmaz.
  void trackEvent(AnalyticsEvent event) {
    unawaited(_trackEventInternal(event));
  }

  /// Üniversite görüntüleme — counter + top universities sıralaması.
  void trackUniversityView({
    required String universityId,
    required String universityName,
  }) {
    unawaited(
      _trackUniversityViewInternal(
        universityId: universityId,
        universityName: universityName,
      ),
    );
  }

  Future<void> _trackUniversityViewInternal({
    required String universityId,
    required String universityName,
  }) async {
    try {
      await _callTrackAnalytics({
        'event': AnalyticsEvent.universityViewed.name,
        'universityId': universityId,
        'universityName': universityName,
      });
    } catch (e) {
      debugPrint('[AnalyticsService] trackUniversityView failed: $e');
    }
  }

  Future<void> _trackEventInternal(AnalyticsEvent event) async {
    try {
      await _callTrackAnalytics({'event': event.name});
    } catch (e) {
      debugPrint('[AnalyticsService] trackEvent(${event.name}) failed: $e');
    }
  }

  /// Birden fazla event'i tek batch'te kaydet (performans optimizasyonu).
  void trackEvents(List<AnalyticsEvent> events) {
    unawaited(_trackEventsInternal(events));
  }

  Future<void> _trackEventsInternal(List<AnalyticsEvent> events) async {
    try {
      await _callTrackAnalytics({
        'events': events.map((event) => event.name).toList(growable: false),
      });
    } catch (e) {
      debugPrint('[AnalyticsService] trackEvents failed: $e');
    }
  }

  Future<void> _callTrackAnalytics(Map<String, Object?> payload) async {
    final callable = _functions.httpsCallable(
      'trackAnalyticsEvent',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 10)),
    );
    await callable.call<Object?>(payload);
  }
}
