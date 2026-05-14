import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_preferences_provider.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final Ref ref;
  static const _localeKey = 'app_locale';

  LocaleNotifier(this.ref) : super(const Locale('tr')) {
    _loadLocale();
  }

  void _loadLocale() {
    final prefs = ref.read(sharedPreferencesProvider);
    final localeString = prefs.getString(_localeKey);
    if (localeString != null) {
      state = Locale(localeString);
    }
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_localeKey, locale.languageCode);
    state = locale;
  }
}
