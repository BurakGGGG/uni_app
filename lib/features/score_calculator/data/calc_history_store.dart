import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/calc_history_entry.dart';

/// Deneme geçmişini `shared_preferences`'ta JSON listesi olarak saklar.
/// En yeni kayıt başta; [maxEntries] tavanı aşılırsa en eskiler düşer.
class CalcHistoryStore {
  CalcHistoryStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'calc_history_v1';
  static const int maxEntries = 50;

  List<CalcHistoryEntry> read() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          CalcHistoryEntry.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      // Bozuk kayıt — temizle ve boş dön.
      _prefs.remove(_key);
      return const [];
    }
  }

  Future<void> save(List<CalcHistoryEntry> entries) async {
    final capped = entries.take(maxEntries).toList();
    await _prefs.setString(
      _key,
      jsonEncode([for (final e in capped) e.toJson()]),
    );
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
