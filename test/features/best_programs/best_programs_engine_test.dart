import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/best_programs/domain/best_programs_engine.dart';
import 'package:uni_app/features/best_programs/domain/models/best_programs_query.dart';
import 'package:uni_app/features/best_programs/domain/program_category.dart';
import 'package:uni_app/features/university/domain/models/department_model.dart';
import 'package:uni_app/features/university/domain/models/university_model.dart';

UniversityModel _uni(
  String id, {
  String type = 'Devlet',
  String cityId = '06',
}) {
  return UniversityModel(
    id: id,
    cityId: cityId,
    name: 'Üni $id',
    type: type,
    hasCampus: true,
    logoUrl: '',
    photoUrl: '',
    description: '',
    establishedYear: 1990,
    website: '',
  );
}

DepartmentModel _dept({
  required String id,
  required String uniId,
  required String name,
  double baseScore = 400,
  int ranking = 50000,
  String type = 'Lisans',
  String language = 'Türkçe',
  String description = '',
  String scoreType = 'SAY',
  Map<int, YearlyScore> previousYears = const {},
}) {
  return DepartmentModel(
    id: id,
    universityId: uniId,
    name: name,
    faculty: 'Fakülte',
    type: type,
    language: language,
    description: description,
    scoreData: DepartmentScoreData(
      year: 2025,
      scoreType: scoreType,
      baseScore: baseScore,
      ranking: ranking,
      quota: 60,
      placedCount: 60,
      previousYears: previousYears,
    ),
  );
}

void main() {
  final universities = {
    'a': _uni('a'),
    'b': _uni('b', type: 'Vakıf', cityId: '34'),
    'c': _uni('c', cityId: '35'),
  };

  group('rank — sıralama', () {
    test('başarı sırası artan; sırasızlar sona, eşitlikte taban puanı', () {
      final depts = [
        _dept(id: '1', uniId: 'a', name: 'Tıp', ranking: 5000),
        // ranking 0 ve previousYears yok → referans sıra kurulamaz.
        _dept(id: '2', uniId: 'a', name: 'Tıp', ranking: 0, baseScore: 300),
        _dept(id: '3', uniId: 'b', name: 'Tıp', ranking: 100),
        _dept(id: '4', uniId: 'c', name: 'Tıp', ranking: 5000, baseScore: 460),
      ];

      final result = BestProgramsEngine.rank(
          depts, universities, const BestProgramsQuery());

      expect(result.map((r) => r.department.id), ['3', '4', '1', '2']);
      expect(result.first.position, 1);
      expect(result.last.reference, isNull);
    });

    test('taban puanına göre sıralama seçilebilir', () {
      final depts = [
        _dept(id: '1', uniId: 'a', name: 'Tıp', ranking: 100, baseScore: 400),
        _dept(id: '2', uniId: 'a', name: 'Tıp', ranking: 9000, baseScore: 480),
      ];

      final result = BestProgramsEngine.rank(depts, universities,
          const BestProgramsQuery(sort: BestProgramsSort.scoreDesc));

      expect(result.map((r) => r.department.id), ['2', '1']);
    });

    test('ranking 0 ise önceki yıla düşer (rankingForMatching)', () {
      final depts = [
        _dept(
          id: 'fallback',
          uniId: 'a',
          name: 'Tıp',
          ranking: 0,
          previousYears: {2024: const YearlyScore(baseScore: 390, ranking: 70)},
        ),
        _dept(id: 'normal', uniId: 'a', name: 'Tıp', ranking: 9000),
      ];

      final result = BestProgramsEngine.rank(
          depts, universities, const BestProgramsQuery());

      expect(result.first.department.id, 'fallback');
      expect(result.first.reference!.rank, 70);
      expect(result.first.reference!.year, 2024);
      expect(result.first.referenceIsStale, isTrue);
    });
  });

  group('rank — filtreler', () {
    final depts = [
      _dept(id: 'devlet', uniId: 'a', name: 'Tıp'),
      _dept(
          id: 'vakif-burslu',
          uniId: 'b',
          name: 'Tıp',
          description: '(Burslu)'),
      _dept(
          id: 'ingilizce',
          uniId: 'c',
          name: 'Tıp',
          language: 'İngilizce'),
      _dept(
          id: 'uzaktan',
          uniId: 'a',
          name: 'Tıp',
          description: '(Uzaktan Öğretim)'),
      _dept(id: 'onlisans', uniId: 'a', name: 'Anestezi', type: 'Önlisans'),
      _dept(id: 'hukuk', uniId: 'a', name: 'Hukuk', scoreType: 'EA'),
    ];

    List<String> ids(BestProgramsQuery q) =>
        BestProgramsEngine.rank(depts, universities, q)
            .map((r) => r.department.id)
            .toList();

    test('varsayılan: sadece lisans, uzaktan/açıköğretim gizli', () {
      expect(ids(const BestProgramsQuery()),
          unorderedEquals(['devlet', 'vakif-burslu', 'ingilizce', 'hukuk']));
    });

    test('uzaktan öğretim anahtarla açılır', () {
      expect(ids(const BestProgramsQuery(includeDistance: true)),
          contains('uzaktan'));
    });

    test('önlisans filtreden gelir', () {
      expect(ids(const BestProgramsQuery(programTypes: {'Önlisans'})),
          ['onlisans']);
    });

    test('devlet/vakıf filtresi', () {
      expect(ids(const BestProgramsQuery(uniTypes: {'Vakıf'})),
          ['vakif-burslu']);
      expect(ids(const BestProgramsQuery(uniTypes: {'Devlet'})),
          unorderedEquals(['devlet', 'ingilizce', 'hukuk']));
    });

    test('sadece burslu filtresi', () {
      expect(ids(const BestProgramsQuery(onlyScholarship: true)),
          ['vakif-burslu']);
    });

    test('şehir ve öğretim dili filtreleri', () {
      expect(ids(const BestProgramsQuery(cityIds: {'35'})), ['ingilizce']);
      expect(ids(const BestProgramsQuery(languages: {'İngilizce'})),
          ['ingilizce']);
    });

    test('bölüm adı tam eşleşir, arama alt dize arar', () {
      expect(ids(const BestProgramsQuery(departmentName: 'Hukuk')), ['hukuk']);
      expect(ids(const BestProgramsQuery(search: 'tıp')),
          unorderedEquals(['devlet', 'vakif-burslu', 'ingilizce']));
    });

    test('alan filtresi kategoriyi uygular', () {
      expect(ids(const BestProgramsQuery(categoryKey: 'hukuk-siyaset')),
          ['hukuk']);
      expect(ids(const BestProgramsQuery(categoryKey: 'saglik')),
          unorderedEquals(['devlet', 'vakif-burslu', 'ingilizce']));
    });

    test('üniversitesi bilinmeyen program listeye girmez', () {
      final orphan = [_dept(id: 'yok', uniId: 'yok-boyle-uni', name: 'Tıp')];
      expect(
          BestProgramsEngine.rank(
              orphan, universities, const BestProgramsQuery()),
          isEmpty);
    });
  });

  group('departmentsIn / searchDepartments', () {
    final depts = [
      _dept(id: '1', uniId: 'a', name: 'Tıp', ranking: 5000),
      _dept(id: '2', uniId: 'b', name: 'Tıp', ranking: 100),
      _dept(id: '3', uniId: 'a', name: 'Diş Hekimliği', ranking: 20000),
      _dept(id: '4', uniId: 'a', name: 'Hukuk', scoreType: 'EA'),
    ];

    test('alandaki bölümler en iyi sıralarına göre gelir', () {
      final summaries = BestProgramsEngine.departmentsIn(
          categoryByKey('saglik')!, depts, const BestProgramsQuery());

      expect(summaries.map((s) => s.name), ['Tıp', 'Diş Hekimliği']);
      final tip = summaries.first;
      expect(tip.programCount, 2);
      expect(tip.bestRank, 100);
      expect(tip.scoreType, 'SAY');
    });

    test('arama adla başlayanı öne alır', () {
      final results = BestProgramsEngine.searchDepartments('hukuk', depts);
      expect(results.single.name, 'Hukuk');
      expect(BestProgramsEngine.searchDepartments('', depts), isEmpty);
    });
  });

  group('gerçek veri (assets/data/department_scores.json)', () {
    late List<DepartmentModel> all;
    late Map<String, UniversityModel> unis;

    setUpAll(() {
      final scores = (jsonDecode(File('assets/data/department_scores.json')
          .readAsStringSync()) as Map<String, dynamic>)['scores'] as List;
      all = [
        for (final s in scores)
          DepartmentModel.fromMap(
            {
              'universityId': s['universityId'],
              'name': s['name'],
              'faculty': s['faculty'],
              'type': s['type'],
              'language': s['language'],
              'description': s['description'],
              'duration': s['duration'],
              'scoreData': {
                'year': s['year'],
                'scoreType': s['scoreType'],
                'baseScore': s['baseScore'],
                'ranking': s['ranking'],
                'quota': s['quota'],
                'placedCount': s['placedCount'],
                'previousYears': s['previousYears'],
              },
            },
            s['deptId'] as String,
          ),
      ];
      final uniIds = {for (final d in all) d.universityId};
      unis = {for (final id in uniIds) id: _uni(id)};
    });

    test('"En iyi Tıp" listesi sıralamaya göre doğru başlar', () {
      final result = BestProgramsEngine.rank(
        all,
        unis,
        const BestProgramsQuery(departmentName: 'Tıp'),
      );

      expect(result.length, greaterThan(60));
      // Sıralar artan olmalı (null'lar zaten sonda).
      final ranks = [
        for (final r in result)
          if (r.reference != null) r.reference!.rank,
      ];
      expect(ranks, orderedEquals([...ranks]..sort()));
      // En iyi program 100'den iyi bir sırada (2025'te Medipol 38, Koç 43).
      expect(result.first.reference!.rank, lessThan(100));
    });

    test('"En iyi mühendislik" tüm mühendislikleri kapsar', () {
      final result = BestProgramsEngine.rank(
        all,
        unis,
        const BestProgramsQuery(categoryKey: 'muhendislik'),
      );

      final names = result.map((r) => r.department.name).toSet();
      expect(names, contains('Bilgisayar Mühendisliği'));
      expect(names, contains('Makine Mühendisliği'));
      expect(names, contains('Endüstri Mühendisliği'));
      expect(result.length, greaterThan(500));
      // İlk sıradaki program gerçekten en iyi sıraya sahip olmalı.
      expect(result.first.reference!.rank, lessThan(500));
    });

    test('açıköğretim/uzaktan varsayılan olarak listede yok', () {
      final result = BestProgramsEngine.rank(
        all,
        unis,
        const BestProgramsQuery(programTypes: {'Lisans', 'Önlisans'}),
      );
      expect(
        result.any((r) => BestProgramsEngine.isDistanceLearning(r.department)),
        isFalse,
      );
    });
  });
}
