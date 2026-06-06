import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Firebase Remote Config tabanlı A/B Testing servisi.
///
/// Paywall varyantları, onboarding akışı, UI denemeleri gibi
/// testleri uzaktan yönetmenizi sağlar.
///
/// Kullanım:
/// ```dart
/// final variant = ABTestService().getPaywallVariant();
/// if (variant == 'B') { ... alternatif paywall ... }
/// ```
class ABTestService {
  static final ABTestService _instance = ABTestService._();
  factory ABTestService() => _instance;
  ABTestService._();

  final _remoteConfig = FirebaseRemoteConfig.instance;
  bool _initialized = false;

  // ═══════════════════════════════════════════════════════════════
  //  Remote Config Anahtarları
  // ═══════════════════════════════════════════════════════════════

  /// Paywall varyantı: 'A' (varsayılan), 'B', 'C'
  static const _keyPaywallVariant = 'ab_paywall_variant';

  /// Onboarding akışı: 'classic' veya 'short'
  static const _keyOnboardingFlow = 'ab_onboarding_flow';

  /// Ana sayfa sıralaması: 'default', 'reviews_first', 'cities_first'
  static const _keyHomeSectionOrder = 'ab_home_section_order';

  /// Review yazma teşviki gösterilsin mi?
  static const _keyShowReviewPrompt = 'ab_show_review_prompt';

  /// Review teşviki minimum gün sayısı (uygulama kurulumundan itibaren)
  static const _keyReviewPromptMinDays = 'ab_review_prompt_min_days';

  // ═══════════════════════════════════════════════════════════════
  //  Başlatma
  // ═══════════════════════════════════════════════════════════════

  /// A/B test yapılandırmasını yükler.
  ///
  /// [ForceUpdateService.init()] zaten Remote Config'i başlatıyor;
  /// bu metod sadece A/B test varsayılanlarını ekler.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _remoteConfig.setDefaults({
        _keyPaywallVariant: 'A',
        _keyOnboardingFlow: 'classic',
        _keyHomeSectionOrder: 'default',
        _keyShowReviewPrompt: true,
        _keyReviewPromptMinDays: 3,
      });

      // ForceUpdateService tarafından zaten fetch edilmiş olabilir,
      // bu durumda tekrar fetch etmeye gerek yok.
      debugPrint('[ABTest] Defaults set');
    } catch (e) {
      debugPrint('[ABTest] Init error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  Getter'lar
  // ═══════════════════════════════════════════════════════════════

  /// Paywall varyantı: 'A', 'B', 'C'
  ///
  /// Firebase konsolunda kullanıcıları yüzde bazında segmentlere ayırarak
  /// farklı paywall deneyimleri sunabilirsiniz.
  String getPaywallVariant() {
    return _remoteConfig.getString(_keyPaywallVariant);
  }

  /// Onboarding akışı: 'classic' (4 sayfa) veya 'short' (2 sayfa)
  String getOnboardingFlow() {
    return _remoteConfig.getString(_keyOnboardingFlow);
  }

  /// Ana sayfa bölüm sıralaması
  String getHomeSectionOrder() {
    return _remoteConfig.getString(_keyHomeSectionOrder);
  }

  /// Review teşviki gösterilsin mi?
  bool shouldShowReviewPrompt() {
    return _remoteConfig.getBool(_keyShowReviewPrompt);
  }

  /// Review teşviki minimum gün sayısı
  int getReviewPromptMinDays() {
    return _remoteConfig.getInt(_keyReviewPromptMinDays);
  }

  /// Tüm aktif A/B test değerlerini debug için döndürür.
  Map<String, dynamic> getAllValues() {
    return {
      'paywall_variant': getPaywallVariant(),
      'onboarding_flow': getOnboardingFlow(),
      'home_section_order': getHomeSectionOrder(),
      'show_review_prompt': shouldShowReviewPrompt(),
      'review_prompt_min_days': getReviewPromptMinDays(),
    };
  }
}
