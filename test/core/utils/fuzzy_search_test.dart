import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/core/utils/fuzzy_search.dart';

void main() {
  group('levenshteinDistance', () {
    test('identical strings have distance 0', () {
      expect(levenshteinDistance('odtu', 'odtu'), 0);
    });

    test('empty string distance equals other length', () {
      expect(levenshteinDistance('', 'abc'), 3);
      expect(levenshteinDistance('abc', ''), 3);
    });

    test('single edit has distance 1', () {
      expect(levenshteinDistance('bogazici', 'bogzici'), 1); // silme
      expect(levenshteinDistance('hacettep', 'hacettepe'), 1); // ekleme
      expect(levenshteinDistance('marmara', 'marmaba'), 1); // değiştirme
    });
  });

  group('fuzzyDistance', () {
    test('Türkçe normalize ile aksanı yok sayar', () {
      // "boğaziçi" → "bogazici"; sorgu zaten ASCII.
      expect(fuzzyDistance('bogazici', ['Boğaziçi Üniversitesi']), 0);
    });

    test('yazım hatasını küçük mesafeyle yakalar', () {
      expect(
        fuzzyDistance('bogzici', ['Boğaziçi Üniversitesi']),
        lessThanOrEqualTo(1),
      );
    });

    test('önek eşleşmesini yakalar', () {
      // "boğaz" → "boğaziçi" öneki ile 0 mesafe.
      expect(fuzzyDistance('bogaz', ['Boğaziçi Üniversitesi']), 0);
    });

    test('kısaltma/alias adayını da değerlendirir', () {
      expect(fuzzyDistance('odtu', ['Orta Doğu Teknik', 'ODTÜ']), 0);
    });

    test('alakasız sorgu büyük mesafe verir', () {
      expect(
        fuzzyDistance('xyzqwerty', ['Boğaziçi Üniversitesi']),
        greaterThan(3),
      );
    });
  });

  group('isFuzzyMatch', () {
    test('kısa sorguda sadece 1 hataya izin verir', () {
      expect(isFuzzyMatch(1, 4), isTrue);
      expect(isFuzzyMatch(2, 4), isFalse);
    });

    test('uzun sorguda 3 hataya kadar izin verir', () {
      expect(isFuzzyMatch(3, 10), isTrue);
      expect(isFuzzyMatch(4, 10), isFalse);
    });
  });
}
