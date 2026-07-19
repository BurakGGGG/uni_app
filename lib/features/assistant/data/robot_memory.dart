import 'package:shared_preferences/shared_preferences.dart';

/// Üni'nin kısa hafızası — son gösterilen mesajlar (tekrar önleme) ve
/// ilk-kullanım bayrakları. FeatureDiscoveryService ile aynı desen:
/// cihaz-yerel, `shared_preferences`.
class RobotMemory {
  final SharedPreferences _prefs;
  const RobotMemory(this._prefs);

  static const _lastShownPrefix = 'assistant_last_';
  static const _wizardIntroSeenKey = 'assistant_wizard_intro_seen_v1';

  /// Bu slotta en son gösterilen mesaj id'si (RobotBrain.pick'e excludeId).
  String? lastShown(String slot) =>
      _prefs.getString('$_lastShownPrefix$slot');

  Future<void> recordShown(String slot, String messageId) =>
      _prefs.setString('$_lastShownPrefix$slot', messageId);

  bool get wizardIntroSeen => _prefs.getBool(_wizardIntroSeenKey) ?? false;

  Future<void> markWizardIntroSeen() =>
      _prefs.setBool(_wizardIntroSeenKey, true);
}
