import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/exam_target.dart';
import '../domain/models/practice_exam.dart';

/// Deneme defterini `shared_preferences`'ta JSON listesi olarak saklar.
/// En yeni kayıt başta; [maxEntries] tavanı aşılırsa en eskiler düşer.
///
/// Yerel depo tek doğruluk noktasıdır: UI hep buradan okur, Firestore yalnız
/// yedek/senkron katmanıdır ([PracticeExamSyncService]).
class PracticeExamStore {
  PracticeExamStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'practice_exams_v1';
  static const String _targetKey = 'exam_target_v1';

  /// v3'ün "Deneme Geçmişi" anahtarı — tek yön migrasyon kaynağı.
  static const String legacyKey = 'calc_history_v1';

  static const int maxEntries = 200;

  /// Mezar taşları bu süre sonunda temizlenir; senkronun silmeyi tüm
  /// cihazlara yayması için yeterli pencere.
  static const Duration tombstoneTtl = Duration(days: 30);

  /// Silinmemiş kayıtlar, en yeni (deneme tarihine göre) başta.
  List<PracticeExam> read() {
    return [
      for (final e in readIncludingDeleted())
        if (!e.deleted) e,
    ];
  }

  /// Senkronun ihtiyaç duyduğu ham liste — mezar taşları dahil.
  List<PracticeExam> readIncludingDeleted() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final now = DateTime.now();
      final entries = <PracticeExam>[];
      for (final item in list) {
        final exam = PracticeExam.fromJson(item as Map<String, dynamic>);
        // Süresi dolmuş mezar taşı — okuma sırasında düşer.
        if (exam.deleted && now.difference(exam.updatedAt) > tombstoneTtl) {
          continue;
        }
        entries.add(exam);
      }
      return _sorted(entries);
    } catch (_) {
      // Bozuk kayıt — temizle ve boş dön.
      _prefs.remove(_key);
      return const [];
    }
  }

  Future<void> save(List<PracticeExam> entries) async {
    final capped = _sorted(entries).take(maxEntries).toList();
    await _prefs.setString(
      _key,
      jsonEncode([for (final e in capped) e.toJson()]),
    );
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }

  /// Oturum kapanınca yereli tamamen boşaltır: aktif defter, hedef ve eski
  /// migrasyon anahtarı. Firestore'a **dokunmaz** — amaç veriyi silmek değil,
  /// cihazı bir sonraki hesap için temiz bırakmak; uzak yedek olduğu gibi kalır.
  /// [legacyKey] de temizlenir, yoksa defter yeniden kurulunca eski kullanıcının
  /// kayıtları migrasyonla geri dirilir.
  Future<void> clearLocalSession() async {
    await _prefs.remove(_key);
    await _prefs.remove(_targetKey);
    await _prefs.remove(legacyKey);
  }

  /// `calc_history_v1` kayıtlarını yeni deftere taşır.
  ///
  /// Yalnız yeni defter boşken çalışır ve eski anahtarı **silmez** — bir sürüm
  /// boyunca geri dönüş emniyeti. Taşınan kayıt sayısını döner.
  Future<int> migrateFromLegacy() async {
    if ((_prefs.getString(_key) ?? '').isNotEmpty) return 0;
    final legacy = _prefs.getString(legacyKey);
    if (legacy == null || legacy.isEmpty) return 0;
    try {
      final list = jsonDecode(legacy) as List<dynamic>;
      final migrated = [
        for (final item in list)
          PracticeExam.fromLegacyJson(item as Map<String, dynamic>),
      ];
      if (migrated.isEmpty) return 0;
      await save(migrated);
      return migrated.length;
    } catch (_) {
      return 0;
    }
  }

  ExamTarget? readTarget() {
    final raw = _prefs.getString(_targetKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return ExamTarget.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _prefs.remove(_targetKey);
      return null;
    }
  }

  Future<void> saveTarget(ExamTarget target) async {
    await _prefs.setString(_targetKey, jsonEncode(target.toJson()));
  }

  Future<void> clearTarget() async {
    await _prefs.remove(_targetKey);
  }

  /// Deneme tarihine göre yeniden eskiye; eşitlikte kayıt anına göre.
  static List<PracticeExam> _sorted(List<PracticeExam> entries) {
    final sorted = [...entries];
    sorted.sort((a, b) {
      final byTaken = b.takenAt.compareTo(a.takenAt);
      if (byTaken != 0) return byTaken;
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }
}
