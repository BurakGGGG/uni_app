import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/preference_wizard/domain/models/student_score_profile.dart';
import 'package:uni_app/features/preference_wizard/domain/preference_match_engine.dart';
import 'package:uni_app/features/score_calculator/domain/models/match_result.dart';
import 'package:uni_app/features/preference_wizard/domain/rank_estimator.dart';
import 'package:uni_app/features/university/domain/models/department_model.dart';
import 'package:uni_app/features/university/domain/models/university_model.dart';

/// Tahminci + motor v2'nin GERÇEK asset verisiyle sağlığı.
/// Veri statik olduğundan sınırlar deterministiktir (flaky değildir).

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
  late List<DepartmentModel> depts;
  late RankEstimator estimator;

  setUpAll(() {
    final jsonStr =
        File('assets/data/department_scores.json').readAsStringSync();
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    depts = (data['scores'] as List)
        .cast<Map<String, dynamic>>()
        .map(_fromAssetRecord)
        .toList();
    estimator = RankEstimator.fromDepartments(depts);
  });

  test('beş puan türünün tümü için eğri kurulur', () {
    for (final type in ['SAY', 'EA', 'SÖZ', 'DİL', 'TYT']) {
      expect(estimator.supports(type), isTrue, reason: type);
    }
  });

  test('tahmin tekdüze: puan arttıkça sıra iyileşir (artamaz)', () {
    for (final type in ['SAY', 'EA', 'SÖZ', 'DİL', 'TYT']) {
      int? prev;
      for (var score = 200.0; score <= 560; score += 5) {
        final est = estimator.estimateRank(score, type);
        if (est == null) continue;
        if (prev != null) {
          expect(est, lessThanOrEqualTo(prev),
              reason: '$type @$score: $est > $prev');
        }
        prev = est;
      }
    }
  });

  test('gidiş-dönüş: taban puanın tahmini, gerçek taban sıraya yakın', () {
    // Her 25. SAY programında |ln(tahmin/gerçek)| hatasını topla.
    final errors = <double>[];
    final say = depts
        .where((d) =>
            d.effectiveScoreType == 'SAY' &&
            (d.scoreData?.ranking ?? 0) > 0 &&
            d.effectiveBaseScore > 0)
        .toList();
    for (var i = 0; i < say.length; i += 25) {
      final d = say[i];
      final est = estimator.estimateRank(d.effectiveBaseScore, 'SAY');
      if (est == null) continue;
      errors.add(math.log(est / d.scoreData!.ranking).abs());
    }
    errors.sort();
    final p50 = errors[errors.length ~/ 2];
    final p90 = errors[(errors.length * 9) ~/ 10];
    // Eğri kova medyanlarından kurulduğu için medyan hata küçük olmalı;
    // kuyrukta (aynı puana çok farklı sıralar) makul pay bırakılır.
    expect(p50, lessThan(0.25), reason: 'p50=$p50');
    expect(p90, lessThan(0.90), reason: 'p90=$p90');
  });

  test('dağılım regresyonu: üç örnek profil makul kategorilere yayılır', () {
    final uniIds = depts.map((d) => d.universityId).toSet();
    final unis = [
      for (final id in uniIds)
        UniversityModel.fromMap(
            {'name': id, 'cityId': 'c1', 'type': 'Devlet'}, id),
    ];
    final sayCount = depts
        .where((d) => d.effectiveScoreType == 'SAY' && d.effectiveBaseScore > 0)
        .length;

    // İyi / orta / sınır sıralı üç SAY profili.
    for (final rank in [15000, 150000, 600000]) {
      final result = PreferenceMatchEngine.matchAllPrograms(
        profile: StudentScoreProfile(
          scoreType: 'SAY',
          placementScore: 0,
          rank: rank,
          year: 2026,
          updatedAt: DateTime(2026, 7, 17),
        ),
        allDepartments: depts,
        allUniversities: unis,
        estimator: estimator,
      );
      // Sırası >0 olan tüm SAY programları bir kategoriye düşmeli (sırasız
      // 10 küsur program puansız profilde atlanır).
      expect(result.total, greaterThan(sayCount - 30), reason: 'rank $rank');
      expect(result.guaranteed, isNotEmpty, reason: 'rank $rank');
      expect(result.target, isNotEmpty, reason: 'rank $rank');
      expect(result.dream, isNotEmpty, reason: 'rank $rank');
      // Fit skorları kelepçe içinde.
      for (final m in result.target.take(50)) {
        expect(m.fitScore, inInclusiveRange(3, 97));
      }
    }
  });

  test('puanla giren profil de sıra-bazlı eşleşir (tahmini sıra)', () {
    final uniIds = depts.map((d) => d.universityId).toSet();
    final unis = [
      for (final id in uniIds)
        UniversityModel.fromMap(
            {'name': id, 'cityId': 'c1', 'type': 'Devlet'}, id),
    ];
    final result = PreferenceMatchEngine.matchAllPrograms(
      profile: StudentScoreProfile(
        scoreType: 'SAY',
        placementScore: 380,
        year: 2026,
        updatedAt: DateTime(2026, 7, 17),
      ),
      allDepartments: depts,
      allUniversities: unis,
      estimator: estimator,
    );
    expect(result.total, greaterThan(1000));
    final withRank = [...result.guaranteed, ...result.target, ...result.dream]
        .where((m) => (m.departmentRanking ?? 0) > 0);
    for (final m in withRank.take(100)) {
      expect(m.matchBasis, MatchBasis.estimatedRank);
      expect(m.fitScore, isNotNull);
    }
  });
}
