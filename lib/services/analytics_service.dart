import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// ÜniSeç Analytics & Crashlytics servisi.
///
/// Tüm analytics eventleri ve Crashlytics custom key'leri bu servis
/// üzerinden yönetilir. Singleton pattern — `AnalyticsService()` ile erişilir.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;
  FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  /// GoRouter ile entegre analytics observer.
  /// MaterialApp.router'ın observers listesine eklenebilir (GoRouter içinden değil).
  FirebaseAnalyticsObserver get routeObserver =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ═══════════════════════════════════════════════════════════════
  //  Crashlytics — Kullanıcı Bağlamı
  // ═══════════════════════════════════════════════════════════════

  /// Kullanıcı giriş yaptığında Crashlytics'te kullanıcı kimliğini ve
  /// bağlamsal key'leri ayarla. Crash raporlarında görünür.
  Future<void> setUserContext({
    required String userId,
    required String tier,
    bool isVerifiedStudent = false,
  }) async {
    try {
      await _crashlytics.setUserIdentifier(userId);
      await _crashlytics.setCustomKey('user_tier', tier);
      await _crashlytics.setCustomKey('is_verified_student', isVerifiedStudent);
      await _analytics.setUserId(id: userId);
      await _analytics.setUserProperty(name: 'subscription_tier', value: tier);
      await _analytics.setUserProperty(
        name: 'verified_student',
        value: isVerifiedStudent.toString(),
      );
    } catch (e) {
      debugPrint('[Analytics] setUserContext failed: $e');
    }
  }

  /// Kullanıcı çıkış yaptığında kimlikleri temizle.
  Future<void> clearUserContext() async {
    try {
      await _crashlytics.setUserIdentifier('');
      await _analytics.setUserId(id: null);
    } catch (e) {
      debugPrint('[Analytics] clearUserContext failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  Ekran Görüntüleme (Screen View Tracking)
  // ═══════════════════════════════════════════════════════════════

  /// Manuel ekran görüntüleme kaydı (GoRouter observer otomatik yapar,
  /// bu yöntem özel ekranlar için).
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    await _safeLog(
      'screen_view',
      {
        'firebase_screen': screenName,
        'firebase_screen_class': screenClass ?? screenName,
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Onboarding & Auth Funnel
  // ═══════════════════════════════════════════════════════════════

  /// Onboarding başladı.
  Future<void> logOnboardingStarted() async {
    await _safeLog('onboarding_started', {});
  }

  /// Onboarding tamamlandı.
  Future<void> logOnboardingCompleted() async {
    await _safeLog('onboarding_completed', {});
  }

  /// Kayıt ekranı açıldı.
  Future<void> logSignUpStarted({required String method}) async {
    await _safeLog('sign_up_started', {'method': method});
  }

  /// Kayıt başarılı.
  Future<void> logSignUpCompleted({required String method}) async {
    await _safeLog('sign_up', {'method': method});
  }

  /// Giriş başarılı.
  Future<void> logLogin({required String method}) async {
    await _safeLog('login', {'method': method});
  }

  /// Giriş başarısız.
  Future<void> logLoginFailed({
    required String method,
    required String error,
  }) async {
    await _safeLog('login_failed', {'method': method, 'error': error});
  }

  // ═══════════════════════════════════════════════════════════════
  //  Üniversite & Bölüm Keşif
  // ═══════════════════════════════════════════════════════════════

  /// Üniversite detay sayfası açıldı.
  Future<void> logUniversityViewed({
    required String universityId,
    required String universityName,
  }) async {
    await _safeLog('university_viewed', {
      'university_id': universityId,
      'university_name': universityName,
    });
  }

  /// Bölüm detay sayfası açıldı.
  Future<void> logDepartmentViewed({
    required String departmentId,
    required String departmentName,
  }) async {
    await _safeLog('department_viewed', {
      'department_id': departmentId,
      'department_name': departmentName,
    });
  }

  /// Arama yapıldı.
  Future<void> logSearch({required String query, int? resultCount}) async {
    await _safeLog('search', {
      'search_term': query,
      // ignore: use_null_aware_elements
      if (resultCount != null) 'result_count': resultCount,
    });
  }

  // ═══════════════════════════════════════════════════════════════
  //  Favoriler & Tercih Listeleri
  // ═══════════════════════════════════════════════════════════════

  /// Favorilere eklendi.
  Future<void> logFavoriteAdded({
    required String type,
    required String targetId,
  }) async {
    await _safeLog('favorite_added', {'type': type, 'target_id': targetId});
  }

  /// Favorilerden çıkarıldı.
  Future<void> logFavoriteRemoved({
    required String type,
    required String targetId,
  }) async {
    await _safeLog('favorite_removed', {'type': type, 'target_id': targetId});
  }

  /// Tercih listesi oluşturuldu.
  Future<void> logPreferenceListCreated({required int itemCount}) async {
    await _safeLog(
        'preference_list_created', {'item_count': itemCount});
  }

  /// Tercih listesi paylaşıldı.
  Future<void> logPreferenceListShared() async {
    await _safeLog('preference_list_shared', {});
  }

  // ═══════════════════════════════════════════════════════════════
  //  Yorumlar (Reviews)
  // ═══════════════════════════════════════════════════════════════

  /// İlk yorum yazıldı (milestone event).
  Future<void> logFirstReviewWritten({
    required String type,
    required double rating,
  }) async {
    await _safeLog(
        'first_review_written', {'type': type, 'rating': rating});
  }

  /// Yorum yazıldı.
  Future<void> logReviewWritten({
    required String type,
    required String targetId,
    required double rating,
  }) async {
    await _safeLog('review_written', {
      'type': type,
      'target_id': targetId,
      'rating': rating,
    });
  }

  /// Yorum beğenildi.
  Future<void> logReviewLiked({required String reviewId}) async {
    await _safeLog('review_liked', {'review_id': reviewId});
  }

  // ═══════════════════════════════════════════════════════════════
  //  Karşılaştırma
  // ═══════════════════════════════════════════════════════════════

  /// Karşılaştırma başlatıldı.
  Future<void> logComparisonStarted({
    required String type,
    required String userTier,
  }) async {
    await _safeLog(
      'comparison_started',
      {'type': type, 'user_tier': userTier},
    );
  }

  /// Karşılaştırma paylaşıldı (screenshot).
  Future<void> logComparisonShared({required String type}) async {
    await _safeLog('comparison_shared', {'type': type});
  }

  // ═══════════════════════════════════════════════════════════════
  //  Puan Hesaplayıcı
  // ═══════════════════════════════════════════════════════════════

  /// Puan hesaplama yapıldı.
  Future<void> logScoreCalculated({
    required String scoreType,
    required double calculatedScore,
  }) async {
    await _safeLog('score_calculated', {
      'score_type': scoreType,
      'calculated_score': calculatedScore,
    });
  }

  // ═══════════════════════════════════════════════════════════════
  //  Monetizasyon
  // ═══════════════════════════════════════════════════════════════

  /// Paywall gösterildi.
  Future<void> logPaywallShown({
    required String trigger,
    required String userTier,
  }) async {
    await _safeLog(
      'paywall_shown',
      {'trigger': trigger, 'user_tier': userTier},
    );
  }

  /// Abonelik satın alındı.
  Future<void> logSubscriptionPurchased({
    required String tier,
    String billing = 'monthly',
  }) async {
    await _safeLog(
      'subscription_purchased',
      {'tier': tier, 'billing': billing},
    );
  }

  /// Reklam izlendi.
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

  // ═══════════════════════════════════════════════════════════════
  //  Push Bildirimler
  // ═══════════════════════════════════════════════════════════════

  /// Push bildirimine tıklandı.
  Future<void> logNotificationTapped({
    String? route,
    String? type,
  }) async {
    await _safeLog('notification_tapped', {
      // ignore: use_null_aware_elements
      if (route != null) 'route': route,
      // ignore: use_null_aware_elements
      if (type != null) 'type': type,
    });
  }

  // ═══════════════════════════════════════════════════════════════
  //  Engagement Metrikleri
  // ═══════════════════════════════════════════════════════════════

  /// Uygulama paylaşıldı (Share butonundan).
  Future<void> logAppShared() async {
    await _safeLog('app_shared', {});
  }

  /// Uygulama değerlendirildi (in-app review).
  Future<void> logAppRated() async {
    await _safeLog('app_rated', {});
  }

  /// Profil fotoğrafı değiştirildi.
  Future<void> logProfilePhotoChanged() async {
    await _safeLog('profile_photo_changed', {});
  }

  /// Dil değiştirildi.
  Future<void> logLanguageChanged({required String newLanguage}) async {
    await _safeLog('language_changed', {'new_language': newLanguage});
  }

  /// Tema değiştirildi.
  Future<void> logThemeChanged({required String newTheme}) async {
    await _safeLog('theme_changed', {'new_theme': newTheme});
  }

  // ═══════════════════════════════════════════════════════════════
  //  Dahili Yardımcı
  // ═══════════════════════════════════════════════════════════════

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
