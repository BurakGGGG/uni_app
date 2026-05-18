import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_preferences_provider.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier(ref);
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final Ref ref;
  static const _themeKey = 'app_theme_mode';

  ThemeNotifier(this.ref) : super(ThemeMode.light) {
    _loadTheme();
  }

  void _loadTheme() {
    final prefs = ref.read(sharedPreferencesProvider);
    final themeString = prefs.getString(_themeKey);
    if (themeString != null) {
      state = ThemeMode.values.firstWhere(
        (e) => e.name == themeString,
        orElse: () => ThemeMode.light,
      );
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_themeKey, mode.name);
    state = mode;
  }
}
