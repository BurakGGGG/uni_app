import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/core/providers/locale_provider.dart';

void main() {
  group('resolveInitialLocale', () {
    test('starts in Turkish on Turkish devices', () {
      final locale = resolveInitialLocale(
        savedLanguageCode: null,
        deviceLocale: const Locale('tr', 'TR'),
      );

      expect(locale, const Locale('tr'));
    });

    test('starts in English on non-Turkish devices', () {
      for (final deviceLocale in const [
        Locale('en', 'US'),
        Locale('de', 'DE'),
        Locale('fr', 'FR'),
      ]) {
        expect(
          resolveInitialLocale(
            savedLanguageCode: null,
            deviceLocale: deviceLocale,
          ),
          const Locale('en'),
        );
      }
    });

    test('keeps the language previously selected by the user', () {
      expect(
        resolveInitialLocale(
          savedLanguageCode: 'en',
          deviceLocale: const Locale('tr', 'TR'),
        ),
        const Locale('en'),
      );
      expect(
        resolveInitialLocale(
          savedLanguageCode: 'tr',
          deviceLocale: const Locale('en', 'US'),
        ),
        const Locale('tr'),
      );
    });
  });
}
