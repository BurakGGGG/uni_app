import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/student_score_profile.dart';
import '../domain/models/wizard_prefs.dart';

/// Öğrenci puan profilini ve opsiyonel tercih sinyallerini
/// `shared_preferences`'ta JSON olarak saklayan store.
///
/// Ayrı anahtarlar altında tutulur; cihaza özeldir. İleride cihazlar arası
/// senkron istenirse `users/{uid}.studentProfile`'a mirror eklenebilir.
class StudentProfileStore {
  StudentProfileStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'student_score_profile_v1';
  static const String _prefsKey = 'wizard_prefs_v1';

  StudentScoreProfile? read() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return StudentScoreProfile.fromJson(map);
    } catch (_) {
      // Bozuk kayıt — temizle ve null dön.
      _prefs.remove(_key);
      return null;
    }
  }

  Future<void> save(StudentScoreProfile profile) async {
    await _prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }

  WizardPrefs readWizardPrefs() {
    final raw = _prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return const WizardPrefs();
    try {
      return WizardPrefs.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _prefs.remove(_prefsKey);
      return const WizardPrefs();
    }
  }

  Future<void> saveWizardPrefs(WizardPrefs prefs) async {
    await _prefs.setString(_prefsKey, jsonEncode(prefs.toJson()));
  }

  Future<void> clearWizardPrefs() async {
    await _prefs.remove(_prefsKey);
  }
}
