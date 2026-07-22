import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/best_programs/domain/program_category.dart';
import 'package:uni_app/features/preference_wizard/domain/similar_programs.dart';

/// Alan taksonomisinin asset'teki gerçek bölüm adlarını KAPSADIĞINI doğrular.
/// Bu testin amacı estetik değil: kapsanmayan bir ad "En iyi X bölümleri"
/// ekranında hiçbir alanın altında görünmez, yani kullanıcıdan gizlenir.
void main() {
  late List<Map<String, dynamic>> scores;

  setUpAll(() {
    final raw = File('assets/data/department_scores.json').readAsStringSync();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    scores = [
      for (final s in decoded['scores'] as List<dynamic>)
        s as Map<String, dynamic>,
    ];
  });

  Set<String> normalizedNames(String programType) => {
        for (final s in scores)
          if (s['type'] == programType)
            normalizeProgramName(s['name'] as String),
      };

  test('her lisans bölümü en az bir alana düşer', () {
    final uncovered = <String>[];
    for (final name in normalizedNames('Lisans')) {
      if (categoriesFor(name).isEmpty) uncovered.add(name);
    }
    expect(
      uncovered,
      isEmpty,
      reason: 'Alansız kalan lisans bölümleri (program_category.dart\'a kural '
          'ekle): ${uncovered.join(", ")}',
    );
  });

  test('her önlisans bölümü de en az bir alana düşer', () {
    // Önlisans filtreden açılabildiği için kategorilerin altında görünmeli.
    final uncovered = <String>[];
    for (final name in normalizedNames('Önlisans')) {
      if (categoriesFor(name).isEmpty) uncovered.add(name);
    }
    expect(
      uncovered,
      isEmpty,
      reason: 'Alansız kalan önlisans bölümleri: ${uncovered.join(", ")}',
    );
  });

  test('alan anahtarları benzersiz ve kalıcı', () {
    final keys = programCategories.map((c) => c.key).toList();
    expect(keys.toSet().length, keys.length);
    // Anahtarlar rotaya ve depoya yazılır — sessizce değişmemeli.
    expect(keys, contains('muhendislik'));
    expect(keys, contains('saglik'));
  });

  test('mühendislik alanı tüm mühendislikleri toplar', () {
    final engineering = normalizedNames('Lisans')
        .where((n) => n.contains('muhendis'))
        .toList();
    expect(engineering.length, greaterThan(15));
    for (final name in engineering) {
      expect(
        categoriesFor(name).map((c) => c.key),
        contains('muhendislik'),
        reason: '$name mühendislik alanına düşmedi',
      );
    }
  });

  test('sağlık alanı tıp / diş / eczacılık üçlüsünü kapsar', () {
    for (final name in ['tip', 'dis hekimligi', 'eczacilik', 'hemsirelik']) {
      expect(categoriesFor(name).map((c) => c.key), contains('saglik'),
          reason: '$name sağlık alanına düşmedi');
    }
  });

  test('öğretmenlik alanı ad kuralıyla tüm öğretmenlikleri toplar', () {
    final teaching = normalizedNames('Lisans')
        .where((n) => n.contains('ogretmenligi'))
        .toList();
    expect(teaching.length, greaterThan(10));
    for (final name in teaching) {
      expect(categoriesFor(name).map((c) => c.key), contains('egitim'),
          reason: '$name eğitim alanına düşmedi');
    }
  });

  test('categoryByKey bilinmeyen anahtarda null döner', () {
    expect(categoryByKey('muhendislik'), isNotNull);
    expect(categoryByKey('yok-boyle-bir-alan'), isNull);
  });
}
