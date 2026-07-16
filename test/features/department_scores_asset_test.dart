import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/university/domain/models/department_model.dart';

/// `UniversityRepository._parseScoresAssetIfNeeded` ile aynı map şekli —
/// asset'ten model kurma yolunun tüm kayıtlarda çalıştığını doğrular.
DepartmentModel _fromAssetRecord(Map<String, dynamic> s) {
  return DepartmentModel.fromMap({
    'universityId': s['universityId'],
    'name': s['name'],
    'faculty': s['faculty'],
    'type': s['type'],
    'language': s['language'],
    'duration': s['duration'],
    'description': s['description'],
    'baseScore': s['baseScore'],
    'ranking': s['ranking'],
    'quota': s['quota'],
    'scoreType': s['scoreType'],
    'scoreData': {
      'year': s['year'],
      'scoreType': s['scoreType'],
      'baseScore': s['baseScore'],
      'ranking': s['ranking'],
      'quota': s['quota'],
      'placedCount': s['placedCount'],
      'previousYears': s['previousYears'] ?? {},
    },
  }, s['deptId'] as String);
}

void main() {
  late Map<String, dynamic> data;
  late List<Map<String, dynamic>> scores;

  setUpAll(() {
    final jsonStr =
        File('assets/data/department_scores.json').readAsStringSync();
    data = json.decode(jsonStr) as Map<String, dynamic>;
    scores = (data['scores'] as List).cast<Map<String, dynamic>>();
  });

  test('asset sürüm bilgisi taşıyor', () {
    expect(data['version'], isA<String>());
    expect((data['version'] as String).isNotEmpty, isTrue);
  });

  test('tüm kayıtlar DepartmentModel\'e dönüşüyor', () {
    expect(scores.length, greaterThan(7000));

    var withBase = 0;
    var withRanking = 0;
    const validTypes = {'SAY', 'EA', 'SÖZ', 'DİL', 'TYT'};

    for (final s in scores) {
      final dept = _fromAssetRecord(s); // tip hatası varsa burada fırlar
      expect(dept.id.isNotEmpty, isTrue);
      expect(dept.universityId.isNotEmpty, isTrue);
      expect(dept.name.isNotEmpty, isTrue);

      final base = dept.effectiveBaseScore;
      if (base > 0) {
        withBase++;
        expect(validTypes.contains(dept.effectiveScoreType?.toUpperCase()),
            isTrue,
            reason: '${dept.id}: geçersiz puan türü '
                '${dept.effectiveScoreType}');
      }
      if (dept.rankingForMatching != null) withRanking++;
    }

    // Eşleştirme motorunun çalışması için verinin büyük kısmı dolu olmalı.
    expect(withBase, greaterThan(7000));
    expect(withRanking, greaterThan(7000));
  });

  test('Burslu varyantları description üzerinden ayırt edilebiliyor', () {
    final burslu = scores
        .where((s) => (s['description'] as String?)?.contains('Burslu') ??
            false)
        .toList();
    expect(burslu.length, greaterThan(500));
    final dept = _fromAssetRecord(burslu.first);
    expect(dept.description, contains('Burslu'));
  });

  test('previousYears geçmiş sıralamaları parse ediliyor', () {
    final sample = scores.firstWhere(
      (s) => (s['previousYears'] as Map?)?.isNotEmpty ?? false,
    );
    final dept = _fromAssetRecord(sample);
    expect(dept.scoreData!.previousYears.isNotEmpty, isTrue);
    for (final entry in dept.scoreData!.previousYears.entries) {
      expect(entry.key, inInclusiveRange(2015, 2026));
    }
  });
}
