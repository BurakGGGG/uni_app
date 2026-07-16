import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rozet etkileşim olaylarını server'a bildiren servis (Singleton).
///
/// Tüm sayaçlar ve streak, recordEngagementEvent Cloud Function'ı
/// tarafından users/{uid}/stats/engagement altında tutulur; istemci
/// yalnızca olay bildirir. Fire-and-forget: hata ana akışı asla bozmaz.
class EngagementService {
  EngagementService._();

  static final EngagementService instance = EngagementService._();

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  /// Günde bir kez app_open bildirir (streak + ortam rozetleri).
  ///
  /// Guard: SharedPreferences'ta kullanıcı başına İstanbul günü tutulur;
  /// aynı gün ikinci kez çağrı sunucuya gitmez (sunucu zaten idempotent,
  /// bu sadece gereksiz çağrıyı önler).
  void maybeRecordAppOpen(SharedPreferences prefs) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final today = _istanbulToday();
    final key = 'lastStreakPing_$uid';
    if (prefs.getString(key) == today) return;

    unawaited(prefs.setString(key, today));
    _send('app_open');
  }

  void recordUniversityViewed(String universityId) {
    _send('university_viewed', targetId: universityId);
  }

  void recordCityViewed(String cityId) {
    _send('city_viewed', targetId: cityId);
  }

  void recordComparisonMade() => _send('comparison_made');

  void recordShare() => _send('content_shared');

  // NOT: Favori rozetleri sunucu tarafı Firestore trigger'ı
  // (syncUserFavoriteBadges) ile verilir; istemci olayı yoktur.

  void recordProfileUpdated() => _send('profile_updated');

  void _send(String event, {String? targetId}) {
    if (FirebaseAuth.instance.currentUser == null) return;
    unawaited(_sendInternal(event, targetId: targetId));
  }

  Future<void> _sendInternal(String event, {String? targetId}) async {
    try {
      final callable = _functions.httpsCallable(
        'recordEngagementEvent',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 10)),
      );
      await callable.call<Object?>({
        'event': event,
        'targetId': ?targetId,
      });
    } catch (e) {
      debugPrint('[EngagementService] $event failed: $e');
    }
  }

  /// Europe/Istanbul günü (Türkiye sabit UTC+3, DST yok).
  String _istanbulToday() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }
}
