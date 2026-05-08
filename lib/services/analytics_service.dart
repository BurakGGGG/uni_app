import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  Future<void> logComparisonStarted({
    required String type,
    required String userTier,
  }) async {
    await _safeLog(
      'comparison_started',
      {'type': type, 'user_tier': userTier},
    );
  }

  Future<void> logPaywallShown({
    required String trigger,
    required String userTier,
  }) async {
    await _safeLog(
      'paywall_shown',
      {'trigger': trigger, 'user_tier': userTier},
    );
  }

  Future<void> logSubscriptionPurchased({
    required String tier,
    String billing = 'monthly',
  }) async {
    await _safeLog(
      'subscription_purchased',
      {'tier': tier, 'billing': billing},
    );
  }

  Future<void> logAdWatched({
    required bool completed,
    required int dailyComparisonCount,
  }) async {
    await _safeLog(
      'ad_watched',
      {
        'result': completed ? 'completed' : 'cancelled',
        'daily_comparison_count': dailyComparisonCount,
      },
    );
  }

  Future<void> _safeLog(
    String name,
    Map<String, Object?> parameters,
  ) async {
    try {
      final sanitized = <String, Object>{};
      parameters.forEach((key, value) {
        if (value != null) sanitized[key] = value;
      });
      await _analytics.logEvent(name: name, parameters: sanitized);
    } catch (e) {
      debugPrint('[Analytics] $name failed: $e');
    }
  }
}
