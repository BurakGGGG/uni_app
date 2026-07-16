import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/student_score_profile.dart';

/// Öğrenci puan profilini `shared_preferences`'ta JSON olarak saklayan store.
///
/// Tek anahtar altında tutulur; cihaza özeldir. İleride cihazlar arası senkron
/// istenirse `users/{uid}.studentProfile`'a mirror eklenebilir (v1 local).
class StudentProfileStore {
  StudentProfileStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'student_score_profile_v1';

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
}
