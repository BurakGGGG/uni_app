import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/preference_lists/domain/models/preference_list_model.dart';
import 'package:uni_app/features/preference_wizard/domain/list_health.dart';
import 'package:uni_app/features/preference_wizard/domain/models/student_score_profile.dart';
import 'package:uni_app/features/preference_wizard/domain/models/wizard_filter.dart';
import 'package:uni_app/features/preference_wizard/domain/preference_match_engine.dart';
import 'package:uni_app/features/preference_wizard/domain/similar_programs.dart';
import 'package:uni_app/features/score_calculator/domain/models/match_result.dart';
import 'package:uni_app/features/university/domain/models/department_model.dart';
import 'package:uni_app/features/university/domain/models/university_model.dart';

StudentScoreProfile _profile({double score = 0, int? rank}) {
  return StudentScoreProfile(
    scoreType: 'SAY',
    placementScore: score,
    rank: rank,
    year: 2026,
    updatedAt: DateTime(2026, 7, 17),
  );
}

DepartmentModel _dept(
  String id, {
  String uni = 'u1',
  String name = 'Bilgisayar Mühendisliği',
  String type = 'Lisans',
  String scoreType = 'SAY',
  double base = 0,
  int ranking = 0,
  String? description,
}) {
  return DepartmentModel.fromMap({
    'universityId': uni,
    'name': name,
    'faculty': 'Mühendislik Fakültesi',
    'type': type,
    'language': 'Türkçe',
    'description': ?description,
    'scoreData': {
      'year': 2025,
      'scoreType': scoreType,
      'baseScore': base,
      'ranking': ranking,
      'quota': 10,
      'placedCount': 10,
      'previousYears': <String, dynamic>{},
    },
  }, id);
}

UniversityModel _uni(String id, {String name = 'Üni'}) {
  return UniversityModel.fromMap(
    {'name': '$name $id', 'cityId': 'c1', 'type': 'Devlet'},
    id,
  );
}

PreferenceItem _item(
  int order, {
  String scoreType = 'SAY',
  double? base,
  int? ranking,
}) {
  return PreferenceItem(
    deptId: 'd$order',
    uniId: 'u1',
    order: order,
    deptName: 'Bölüm $order',
    uniName: 'Üni',
    scoreType: scoreType,
    baseScore: base,
    ranking: ranking,
  );
}

void main() {
  group('categorizeByRank', () {
    test('sınır değerleri: %90 garanti, %110 hedef, ötesi zorlayıcı', () {
      expect(categorizeByRank(90000, 100000), MatchCategory.guaranteed);
      expect(categorizeByRank(110000, 100000), MatchCategory.target);
      expect(categorizeByRank(111000, 100000), MatchCategory.dream);
    });

    test('referans sıralama yoksa güvenli taraf: hedef', () {
      expect(categorizeByRank(50000, 0), MatchCategory.target);
    });
  });

  group('sadece sıralamayla eşleştirme (puansız profil)', () {
    final unis = [_uni('u1')];

    test('sıralaması olmayan programlar atlanır, kategoriler ranktan gelir',
        () {
      final result = PreferenceMatchEngine.matchAllPrograms(
        profile: _profile(rank: 45000),
        allDepartments: [
          _dept('d1', base: 450, ranking: 40000), // 45000 > 44000 → zorlayıcı
          _dept('d2', base: 380), // sıralama yok → atlanır
          _dept('d3', base: 300, ranking: 100000), // 45000 ≤ 90000 → yüksek
        ],
        allUniversities: unis,
      );

      expect(result.total, 2);
      expect(result.dream.single.department.id, 'd1');
      expect(result.guaranteed.single.department.id, 'd3');
      // Puansız profilde puan farkı hesaplanmaz.
      expect(result.dream.single.scoreDifference, 0);
    });

    test('fit sıralaması sıra-yakınlığına göre çalışır', () {
      final result = PreferenceMatchEngine.matchAllPrograms(
        profile: _profile(rank: 45000),
        allDepartments: [
          _dept('uzak', base: 300, ranking: 100000),
          _dept('yakin', base: 320, ranking: 50000), // 45000 ≤ 45000 → yüksek
        ],
        allUniversities: unis,
      );

      expect(result.guaranteed.length, 2);
      expect(result.guaranteed.first.department.id, 'yakin');
    });

    test('puan + sıralama birlikteyse sıralama birincildir', () {
      final result = PreferenceMatchEngine.matchAllPrograms(
        profile: _profile(score: 400, rank: 45000),
        // Puan farkı +100 (garanti derdi) ama sıralama hedef bandında.
        allDepartments: [_dept('d1', base: 300, ranking: 46000)],
        allUniversities: unis,
      );

      final match = result.target.single;
      expect(match.matchBasis, MatchBasis.rank);
      expect(match.scoreDifference, 100);
    });
  });

  group('onlyScholarship filtresi', () {
    test('yalnız description\'ında Burslu geçenler kalır', () {
      final result = PreferenceMatchEngine.matchAllPrograms(
        profile: _profile(score: 400),
        allDepartments: [
          _dept('burslu', base: 390, description: '(İngilizce) (Burslu)'),
          _dept('ucretli', base: 390),
        ],
        allUniversities: [_uni('u1')],
        filter: const WizardFilter(onlyScholarship: true),
      );

      expect(result.total, 1);
      expect(result.guaranteed.single.department.id, 'burslu');
    });

    test('aktif filtre sayısına dahil edilir', () {
      const filter = WizardFilter(onlyScholarship: true);
      expect(filter.hasAnyFilter, isTrue);
      expect(filter.activeFilterCount, 1);
    });
  });

  group('normalizeProgramName', () {
    test('parantezli ekleri atar, Türkçe karakterleri katlar', () {
      expect(
        normalizeProgramName('Bilgisayar Mühendisliği (İngilizce) (Burslu)'),
        'bilgisayar muhendisligi',
      );
      expect(
        normalizeProgramName('Elektrik-Elektronik Mühendisliği'),
        'elektrik elektronik muhendisligi',
      );
      expect(normalizeProgramName('İşletme'), 'isletme');
      expect(
        normalizeProgramName('Radyo, Televizyon ve Sinema'),
        'radyo televizyon ve sinema',
      );
    });
  });

  group('similarReachable', () {
    test('aynı isim + aile eşleşir; alakasız ve farklı tip elenir', () {
      final profile = _profile(score: 400);
      final result = PreferenceMatchEngine.matchAllPrograms(
        profile: profile,
        allDepartments: [
          // Kaynak: zorlayıcı (400 - 450 = -50).
          _dept('kaynak', uni: 'u1', base: 450),
          // Aile: Yazılım Müh. hedef bandında (-1).
          _dept('aile', uni: 'u2', name: 'Yazılım Mühendisliği', base: 401),
          // Aynı isim başka üni, yüksek şans (+10).
          _dept('ayni-isim', uni: 'u3', base: 390),
          // Alakasız bölüm — önerilmemeli.
          _dept('alakasiz', uni: 'u2', name: 'Tarih', base: 395),
          // Aynı isim ama Önlisans — tip farkı, önerilmemeli.
          _dept('onlisans', uni: 'u2', type: 'Önlisans', base: 380),
        ],
        allUniversities: [_uni('u1'), _uni('u2'), _uni('u3')],
      );

      final source = result.dream.single;
      final picks = similarReachable(source, result);

      expect(picks.map((m) => m.department.id), ['aile', 'ayni-isim']);
    });

    test('kaynağın kendisi önerilmez', () {
      final result = PreferenceMatchEngine.matchAllPrograms(
        profile: _profile(score: 400),
        allDepartments: [_dept('tek', base: 401)],
        allUniversities: [_uni('u1')],
      );
      final source = result.target.single;
      expect(similarReachable(source, result), isEmpty);
    });
  });

  group('analyzeListHealth', () {
    test('güvenli tercih yoksa uyarır', () {
      final report = analyzeListHealth(
        [for (var i = 1; i <= 5; i++) _item(i, base: 450)],
        _profile(score: 400),
      );

      expect(report.guaranteed, 0);
      expect(report.dream, 5);
      expect(
        report.notes.any((n) =>
            n.severity == ListHealthSeverity.warning &&
            n.text.contains('yüksek şanslı tercih yok')),
        isTrue,
      );
      expect(report.likelyPlacement, isNull);
    });

    test('dengeli liste: sayımlar, unrated ve en olası yerleşme', () {
      final report = analyzeListHealth(
        [
          _item(1, base: 450), // zorlayıcı
          _item(2, base: 401), // ulaşılabilir
          _item(3, base: 390), // yüksek şans
          _item(4, scoreType: 'EA', base: 390), // puan türü farklı → unrated
        ],
        _profile(score: 400),
      );

      expect(report.guaranteed, 1);
      expect(report.target, 1);
      expect(report.dream, 1);
      expect(report.unrated, 1);
      expect(report.likelyPlacement!.deptId, 'd3');
      expect(report.likelyCategory, MatchCategory.guaranteed);
      expect(
        report.notes.any((n) => n.severity == ListHealthSeverity.ok),
        isTrue,
      );
    });

    test('tamamı yüksek şanssa hedef yükseltme notu düşer', () {
      final report = analyzeListHealth(
        [for (var i = 1; i <= 3; i++) _item(i, base: 380)],
        _profile(score: 400),
      );
      expect(report.guaranteed, 3);
      expect(
        report.notes.any((n) => n.text.contains('çok güvenli')),
        isTrue,
      );
    });

    test('profil sıralamalıysa item sıralaması öncelikli kullanılır', () {
      final report = analyzeListHealth(
        // Taban puana göre zorlayıcı olurdu; sıralamaya göre yüksek şans.
        [_item(1, base: 450, ranking: 100000)],
        _profile(score: 400, rank: 45000),
      );
      expect(report.guaranteed, 1);
    });
  });
}
