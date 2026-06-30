import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/shared_preferences_provider.dart';

const _kRecentSearchesKey = 'recent_searches_v1';
const _kMaxRecentSearches = 8;

/// Kullanıcının son arama sorgularını SharedPreferences'te tutar.
/// En yeni en başta, tekrarlar elenir, en fazla [_kMaxRecentSearches] kayıt.
class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier(this._prefs)
      : super(_prefs.getStringList(_kRecentSearchesKey) ?? const []);

  final SharedPreferences _prefs;

  Future<void> add(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.length < 2) return;
    final updated = <String>[
      query,
      ...state.where((q) => q.toLowerCase() != query.toLowerCase()),
    ].take(_kMaxRecentSearches).toList();
    state = updated;
    await _prefs.setStringList(_kRecentSearchesKey, updated);
  }

  Future<void> remove(String query) async {
    final updated = state.where((q) => q != query).toList();
    state = updated;
    await _prefs.setStringList(_kRecentSearchesKey, updated);
  }

  Future<void> clear() async {
    state = const [];
    await _prefs.remove(_kRecentSearchesKey);
  }
}

final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return RecentSearchesNotifier(prefs);
});
