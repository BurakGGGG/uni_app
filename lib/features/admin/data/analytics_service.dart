import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../domain/models/analytics_event.dart';

/// Analytics event tracking servisi (Singleton).
///
/// Her event'te Firestore'da iki doküman güncellenir:
/// 1. `analytics/counters` → tüm zamanlar toplamı
/// 2. `analytics/daily/{yyyy-MM-dd}` → günlük kırılım
///
/// Tüm işlemler fire-and-forget yapılır, ana akış hiçbir zaman
/// analytics hatası yüzünden bozulmaz.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Bugünün tarih string'i: "2026-06-08"
  String get _todayString => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Bir analytics event'i kaydet.
  ///
  /// Fire-and-forget: Bu metodu `unawaited` ile çağırabilirsiniz.
  /// Hata olursa sadece loglanır, fırlatılmaz.
  void trackEvent(AnalyticsEvent event) {
    unawaited(_trackEventInternal(event));
  }

  Future<void> _trackEventInternal(AnalyticsEvent event) async {
    try {
      final batch = _firestore.batch();

      // 1. All-time counter güncelle
      final counterRef = _firestore.collection('analytics').doc('counters');
      batch.set(
        counterRef,
        {
          event.counterField: FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 2. Günlük kırılım güncelle
      final dailyRef =
          _firestore.collection('analytics').doc('daily_$_todayString');
      batch.set(
        dailyRef,
        {
          event.dailyField: FieldValue.increment(1),
          'date': _todayString,
        },
        SetOptions(merge: true),
      );

      await batch.commit();
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
      final batch = _firestore.batch();
      final counterRef = _firestore.collection('analytics').doc('counters');
      final dailyRef =
          _firestore.collection('analytics').doc('daily_$_todayString');

      final counterUpdates = <String, dynamic>{
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      final dailyUpdates = <String, dynamic>{
        'date': _todayString,
      };

      for (final event in events) {
        counterUpdates[event.counterField] = FieldValue.increment(1);
        dailyUpdates[event.dailyField] = FieldValue.increment(1);
      }

      batch.set(counterRef, counterUpdates, SetOptions(merge: true));
      batch.set(dailyRef, dailyUpdates, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      debugPrint('[AnalyticsService] trackEvents failed: $e');
    }
  }
}
