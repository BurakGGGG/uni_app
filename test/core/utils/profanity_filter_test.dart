import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/core/utils/profanity_filter.dart';

void main() {
  group('ProfanityFilter', () {
    group('containsProfanity', () {
      // ─── Clean text → OK ─────────────────────────────────────────
      test('returns false for clean text', () {
        expect(ProfanityFilter.containsProfanity('merhaba'), isFalse);
      });

      test('returns false for empty string', () {
        expect(ProfanityFilter.containsProfanity(''), isFalse);
        expect(ProfanityFilter.containsProfanity('   '), isFalse);
      });

      test('returns false for normal sentences', () {
        expect(
          ProfanityFilter.containsProfanity(
            'Bilgisayar Mühendisliği öğrencisiyim',
          ),
          isFalse,
        );
      });

      // ─── False positive koruması ─────────────────────────────────
      test('does NOT flag "sıkıştır" as profanity (false positive)', () {
        expect(ProfanityFilter.containsProfanity('sıkıştır'), isFalse);
      });

      test('does NOT flag "sıkıntı" as profanity', () {
        expect(ProfanityFilter.containsProfanity('sıkıntı'), isFalse);
      });

      test('does NOT flag "Amasya" as profanity', () {
        expect(ProfanityFilter.containsProfanity('Amasya'), isFalse);
      });

      test('does NOT flag "toprak" as profanity', () {
        expect(ProfanityFilter.containsProfanity('toprak'), isFalse);
      });

      test('does NOT flag "malzeme" as profanity', () {
        expect(ProfanityFilter.containsProfanity('malzeme'), isFalse);
      });

      // ─── Direct profanity → BLOCK ────────────────────────────────
      test('detects direct profanity "siktir"', () {
        expect(ProfanityFilter.containsProfanity('siktir'), isTrue);
      });

      test('detects profanity "orospu"', () {
        expect(ProfanityFilter.containsProfanity('orospu'), isTrue);
      });

      test('detects profanity in a sentence', () {
        expect(
          ProfanityFilter.containsProfanity('bu ne siktir lan'),
          isTrue,
        );
      });

      // ─── Leet-speak varyantları → BLOCK ──────────────────────────
      test('detects leet-speak "s1kt1r"', () {
        expect(ProfanityFilter.containsProfanity('s1kt1r'), isTrue);
      });

      test('detects leet-speak "s!kt!r"', () {
        expect(ProfanityFilter.containsProfanity('s!kt!r'), isTrue);
      });

      test('detects spaced-out evasion "s i k t i r"', () {
        expect(ProfanityFilter.containsProfanity('s i k t i r'), isTrue);
      });

      test('detects dotted evasion "s.i.k.t.i.r"', () {
        expect(ProfanityFilter.containsProfanity('s.i.k.t.i.r'), isTrue);
      });

      // ─── Case insensitive ────────────────────────────────────────
      test('detects uppercase "SIKTIR"', () {
        expect(ProfanityFilter.containsProfanity('SIKTIR'), isTrue);
      });

      test('detects mixed case "SiKtIr"', () {
        expect(ProfanityFilter.containsProfanity('SiKtIr'), isTrue);
      });
    });

    group('sanitize', () {
      test('returns null for clean text', () {
        expect(ProfanityFilter.sanitize('merhaba'), isNull);
      });

      test('returns null for empty text', () {
        expect(ProfanityFilter.sanitize(''), isNull);
      });

      test('masks profanity with ***', () {
        final result = ProfanityFilter.sanitize('siktir');
        expect(result, isNotNull);
        expect(result, contains('***'));
      });
    });
  });
}
