import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/core/utils/turkish_compare.dart';

void main() {
  group('turkishCompare', () {
    test('Türkçe alfabetik sıra: a < ç < ı < i', () {
      expect(turkishCompare('ankara', 'çorum'), isNegative);
      expect(turkishCompare('çorum', 'ışık'), isNegative);
      expect(turkishCompare('ışık', 'izmir'), isNegative);
    });

    test('eşit kelimeler için 0 döner', () {
      expect(turkishCompare('ankara', 'ankara'), 0);
    });

    test('önek olan kelime daha kısa olduğu için önce gelir', () {
      expect(turkishCompare('an', 'ankara'), isNegative);
      expect(turkishCompare('ankara', 'an'), isPositive);
    });

    test('liste Türkçe alfabetik olarak sıralanır', () {
      final cities = ['izmir', 'ışık', 'ankara', 'çorum'];
      cities.sort(turkishCompare);
      expect(cities, ['ankara', 'çorum', 'ışık', 'izmir']);
    });
  });

  group('turkishNormalize', () {
    test('Türkçe karakterleri ASCII karşılığına indirger', () {
      expect(turkishNormalize('odtü'), 'odtu');
      expect(turkishNormalize('ışık'), 'isik');
      expect(turkishNormalize('güneş'), 'gunes');
      expect(turkishNormalize('çağ'), 'cag');
    });

    test('zaten ASCII olan metin değişmez', () {
      expect(turkishNormalize('ankara'), 'ankara');
    });
  });
}
