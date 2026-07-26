import 'package:shared_preferences/shared_preferences.dart';

/// Üni'nin kısa hafızası — son gösterilen mesajlar (tekrar önleme) ve
/// ilk-kullanım bayrakları. FeatureDiscoveryService ile aynı desen:
/// cihaz-yerel, `shared_preferences`.
class RobotMemory {
  final SharedPreferences _prefs;
  const RobotMemory(this._prefs);

  static const _lastShownPrefix = 'assistant_last_';
  static const _wizardIntroSeenKey = 'assistant_wizard_intro_seen_v1';
  static const _displayNameKey = 'assistant_display_name';
  static const _dismissedPrefix = 'assistant_dismissed_';
  static const _planWeekKey = 'assistant_plan_week';
  static const _planDoneKey = 'assistant_plan_done';
  static const _screenTipPrefix = 'assistant_tip_';

  /// Bir ekran ipucu en fazla bu kadar kez söylenir, sonra susar.
  ///
  /// Notlardan farklı olarak ipucunun süresi DOLMAZ: "Keşfet nasıl
  /// kullanılır" bilgisi öğrenildikten sonra her açılışta tekrarlanırsa
  /// Üni dırdırcıya döner. Ekranın durumu değişince (boş liste → dolu
  /// liste) kimlik de değişir ve yeni ipucu kendi hakkıyla konuşur.
  static const int screenTipMaxShows = 3;

  /// Kapatılan bir not bu süre boyunca susar; sonra geri gelir. Kalıcı
  /// susturma yok — "listende güvenli tercih yok" uyarısı sorun çözülmeden
  /// bir daha görünmezse uyarı olmaktan çıkar.
  static const Duration insightSnooze = Duration(days: 7);

  /// Bu slotta en son gösterilen mesaj id'si (RobotBrain.pick'e excludeId).
  String? lastShown(String slot) =>
      _prefs.getString('$_lastShownPrefix$slot');

  Future<void> recordShown(String slot, String messageId) =>
      _prefs.setString('$_lastShownPrefix$slot', messageId);

  bool get wizardIntroSeen => _prefs.getBool(_wizardIntroSeenKey) ?? false;

  Future<void> markWizardIntroSeen() =>
      _prefs.setBool(_wizardIntroSeenKey, true);

  /// Onboarding'de Üni'nin sorduğu ad. Oturum açılmadan önce toplandığı
  /// için cihaz-yerel; auth'ta ad yoksa selamlama buna düşer. Boşsa null.
  String? get displayName {
    final v = _prefs.getString(_displayNameKey)?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  Future<void> setDisplayName(String name) =>
      _prefs.setString(_displayNameKey, name.trim());

  // ── Üni Paneli: not susturma ──

  /// Not hâlâ susturulmuş mu? Süresi dolan kayıt okunurken temizlenir.
  bool isInsightDismissed(String insightId, {DateTime? now}) {
    final key = '$_dismissedPrefix$insightId';
    final raw = _prefs.getInt(key);
    if (raw == null) return false;
    final until = DateTime.fromMillisecondsSinceEpoch(raw);
    if (!(now ?? DateTime.now()).isBefore(until)) {
      _prefs.remove(key);
      return false;
    }
    return true;
  }

  Future<void> dismissInsight(String insightId, {DateTime? now}) {
    final until = (now ?? DateTime.now()).add(insightSnooze);
    return _prefs.setInt(
      '$_dismissedPrefix$insightId',
      until.millisecondsSinceEpoch,
    );
  }

  // ── Sekme ipuçları ──

  /// [tipId] daha söylenebilir mi?
  bool canShowScreenTip(String tipId) =>
      (_prefs.getInt('$_screenTipPrefix$tipId') ?? 0) < screenTipMaxShows;

  Future<void> recordScreenTipShown(String tipId) {
    final key = '$_screenTipPrefix$tipId';
    return _prefs.setInt(key, (_prefs.getInt(key) ?? 0) + 1);
  }

  // ── Üni Paneli: haftalık plan işaretleri ──

  /// [weekKey] haftasında işaretlenmiş görevler. Kayıtlı hafta farklıysa boş
  /// döner — plan pazartesi kendiliğinden sıfırlanır, ayrı temizlik gerekmez.
  Set<String> donePlanTasks(String weekKey) {
    if (_prefs.getString(_planWeekKey) != weekKey) return const {};
    return (_prefs.getStringList(_planDoneKey) ?? const []).toSet();
  }

  Future<void> togglePlanTask(String weekKey, String taskId) async {
    final done = donePlanTasks(weekKey).toSet();
    if (!done.remove(taskId)) done.add(taskId);
    await _prefs.setString(_planWeekKey, weekKey);
    await _prefs.setStringList(_planDoneKey, done.toList());
  }

  /// Oturum kapanınca cihazda kalan tüm Üni hafızasını siler: selamlama adı,
  /// susturulan notlar, plan işaretleri ve ilk-kullanım bayrakları. Bunlar
  /// cihaz-yereldir (uid'e bağlı değil), temizlenmezse bir sonraki hesaba
  /// "Merhaba <önceki ad>" olarak sızar.
  Future<void> clear() async {
    final stale = _prefs
        .getKeys()
        .where((key) =>
            key.startsWith(_lastShownPrefix) ||
            key.startsWith(_dismissedPrefix) ||
            key.startsWith(_screenTipPrefix) ||
            key == _wizardIntroSeenKey ||
            key == _displayNameKey ||
            key == _planWeekKey ||
            key == _planDoneKey)
        .toList(growable: false);
    for (final key in stale) {
      await _prefs.remove(key);
    }
  }
}
