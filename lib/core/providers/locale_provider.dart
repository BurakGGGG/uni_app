import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared_preferences_provider.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref);
});

Locale resolveInitialLocale({
  required String? savedLanguageCode,
  required Locale deviceLocale,
}) {
  if (savedLanguageCode == 'tr' || savedLanguageCode == 'en') {
    return Locale(savedLanguageCode!);
  }

  return deviceLocale.languageCode.toLowerCase() == 'tr'
      ? const Locale('tr')
      : const Locale('en');
}

class LocaleNotifier extends StateNotifier<Locale> {
  final Ref ref;
  static const _localeKey = 'app_locale';

  LocaleNotifier(this.ref)
    : super(
        resolveInitialLocale(
          savedLanguageCode: ref
              .read(sharedPreferencesProvider)
              .getString(_localeKey),
          deviceLocale: PlatformDispatcher.instance.locale,
        ),
      );

  Future<void> setLocale(Locale locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_localeKey, locale.languageCode);
    state = locale;
  }
}
