import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/shared_preferences_provider.dart';

/// Feature Discovery (Coach Mark) servisinin durumunu yönetir.
///
/// SharedPreferences tabanlı, versiyon destekli flag yönetimi sunar.
/// `_v1` suffix'i sayesinde gelecekteki UI güncellemelerinde
/// yeni showcase versiyonu çıkarılabilir.
class FeatureDiscoveryService {
  FeatureDiscoveryService(this._prefs);

  final SharedPreferences _prefs;

  // ─── Flag Anahtarları ──────────────────────────────────────────
  static const homeCompleted = 'feature_discovery_home_v1';
  static const comparisonChartsCompleted =
      'feature_discovery_comparison_charts_v1';

  /// Belirtilen showcase tamamlanmış mı?
  bool isCompleted(String key) => _prefs.getBool(key) ?? false;

  /// Belirtilen showcase'i tamamlandı olarak işaretle.
  Future<void> markCompleted(String key) => _prefs.setBool(key, true);

  /// Tüm showcase flag'lerini sıfırla (Profil → Rehberi tekrar gör).
  Future<void> resetAll() async {
    await _prefs.remove(homeCompleted);
    await _prefs.remove(comparisonChartsCompleted);
  }
}

/// Riverpod provider
final featureDiscoveryProvider = Provider<FeatureDiscoveryService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FeatureDiscoveryService(prefs);
});

/// Uygulama turu için paylaşılan GlobalKey'ler.
///
/// AppShell ve HomeScreen gibi farklı widget ağaçlarının
/// aynı showcase scope'unu kullanabilmesi için static key'ler.
class AppTourKeys {
  AppTourKeys._();

  static final search = GlobalKey(debugLabel: 'tour_search');
  static final story = GlobalKey(debugLabel: 'tour_story');
  static final hero = GlobalKey(debugLabel: 'tour_hero');
  static final notification = GlobalKey(debugLabel: 'tour_notification');
  static final exploreTab = GlobalKey(debugLabel: 'tour_explore');
  static final compareTab = GlobalKey(debugLabel: 'tour_compare');
  static final listsTab = GlobalKey(debugLabel: 'tour_lists');
}
