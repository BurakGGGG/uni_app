import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/preference_lists/domain/models/preference_list_model.dart';
import 'package:uni_app/features/preference_wizard/domain/list_health.dart';
import 'package:uni_app/features/preference_wizard/domain/match_reason.dart';
import 'package:uni_app/features/preference_wizard/domain/models/student_score_profile.dart';
import 'package:uni_app/features/preference_wizard/domain/models/wizard_filter.dart';
import 'package:uni_app/features/preference_wizard/domain/models/wizard_prefs.dart';
import 'package:uni_app/features/preference_wizard/domain/preference_match_engine.dart';
import 'package:uni_app/features/preference_wizard/domain/rank_estimator.dart';
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
  int quota = 10,
  int placed = 10,
  Map<String, dynamic>? previousYears,
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
      'quota': quota,
      'placedCount': placed,
      'previousYears': previousYears ?? <String, dynamic>{},
    },
  }, id);
}

UniversityModel _uni(
  String id, {
  String name = 'Üni',
  String cityId = 'c1',
  String type = 'Devlet',
}) {
  return UniversityModel.fromMap(
    {'name': '$name $id', 'cityId': cityId, 'type': type},
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

  group('baseFitForRatio', () {
    test('çapa noktaları ve uçlar', () {
      expect(baseFitForRatio(0.45), 95); // ilk çapanın altı
      expect(baseFitForRatio(0.60), 95);
      expect(baseFitForRatio(0.675), closeTo(90, 0.01)); // 0.60-0.75 ortası
      expect(baseFitForRatio(0.90), closeTo(70, 0.01));
      expect(baseFitForRatio(1.00), closeTo(55, 0.01));
      expect(baseFitForRatio(1.05), closeTo(47.5, 0.01));
      expect(baseFitForRatio(1.10), closeTo(40, 0.01));
      expect(baseFitForRatio(1.60), closeTo(10, 0.01));
      expect(baseFitForRatio(2.00), 5); // taban
    });

    test('tekdüze: oran arttıkça fit artmaz', () {
      var prev = double.infinity;
      for (var r = 0.30; r <= 2.50; r += 0.01) {
        final fit = baseFitForRatio(r);
        expect(fit, lessThanOrEqualTo(prev + 1e-9),
            reason: 'ratio $r: $fit > $prev');
        prev = fit;
      }
    });
  });

  group('categoryForFit', () {
    test('eşikler: 70 yüksek şans, 40 ulaşılabilir', () {
      expect(categoryForFit(70), MatchCategory.guaranteed);
      expect(categoryForFit(69), MatchCategory.target);
      expect(categoryForFit(40), MatchCategory.target);
      expect(categoryForFit(39), MatchCategory.dream);
    });
  });

  group('computeFit düzelticileri', () {
    test('yalnız temel eğri', () {
      expect(computeFit(studentRank: 45000, programRank: 100000), 95);
      expect(computeFit(studentRank: 100000, programRank: 100000), 55);
    });

    test('trend: sıkılaşan program ceza, gevşeyen ödül alır', () {
      expect(
        computeFit(
            studentRank: 80000, programRank: 80000, previousProgramRank: 100000),
        49, // 55 - 6 (trend 0.80 < 0.85; |ln| 0.223 < 0.25 → oynaklık yok)
      );
      expect(
        computeFit(
            studentRank: 120000,
            programRank: 120000,
            previousProgramRank: 100000),
        59, // 55 + 4 (trend 1.20 > 1.15)
      );
    });

    test('oynaklık: |ln(değişim)| > 0.25 fit\'i ortaya çeker', () {
      // ratio 0.60 → 95; trend 0.70 → -6 → 89; |ln 0.7|=0.357 → %20 ortaya.
      expect(
        computeFit(
            studentRank: 42000, programRank: 70000, previousProgramRank: 100000),
        81, // 89 + (50-89)*0.2 = 81.2
      );
    });

    test('boş kontenjan güven artırır', () {
      expect(
        computeFit(
            studentRank: 100000, programRank: 100000, quota: 10, placedCount: 7),
        63, // 55 + 8
      );
    });

    test('tahmini sıra ve bayat yıl belirsizlik payı ekler', () {
      expect(
        computeFit(
            studentRank: 45000, programRank: 100000, estimatedBasis: true),
        84, // 95 + (50-95)*0.25
      );
      expect(
        computeFit(
            studentRank: 45000, programRank: 100000, staleReference: true),
        88, // 95 + (50-95)*0.15
      );
    });

    test('kelepçe: fit asla 97 üstü / 3 altı olmaz', () {
      expect(
        computeFit(
            studentRank: 30000, programRank: 100000, quota: 10, placedCount: 5),
        97, // 95 + 8 = 103 → kelepçe
      );
      expect(computeFit(studentRank: 300000, programRank: 100000), 5);
    });
  });

  group('RankEstimator + tahmini sırayla eşleştirme', () {
    final curveDepts = [
      _dept('e1', base: 400, ranking: 100000),
      _dept('e2', base: 450, ranking: 50000),
      _dept('e3', base: 500, ranking: 10000),
    ];
    final estimator = RankEstimator.fromDepartments(curveDepts);

    test('puandan sıra tahmini log uzayında enterpolasyonla çalışır', () {
      expect(estimator.estimateRank(450, 'SAY'),
          inInclusiveRange(45000, 56000));
      // Uçların dışı uca kelepçelenir.
      expect(estimator.estimateRank(300, 'SAY'), 100000);
      expect(estimator.estimateRank(560, 'SAY'), 10000);
      // Bilinmeyen tür → null.
      expect(estimator.estimateRank(450, 'EA'), isNull);
      expect(estimator.supports('SAY'), isTrue);
    });

    test('puanla giren öğrenci tahmini sırayla sıra-bazlı eşleşir', () {
      final eval = evaluateDepartment(
        _profile(score: 450),
        _dept('d1', base: 400, ranking: 100000),
        estimator: estimator,
      );
      expect(eval!.basis, MatchBasis.estimatedRank);
      expect(eval.category, MatchCategory.guaranteed);
      expect(eval.fit, 84); // ratio ~0.50 → 95, tahmin payı → 84
      expect(eval.refRankYear, 2025);
    });

    test('tahminci yoksa puan-farkı son çare yolu (fit üretilmez)', () {
      final eval = evaluateDepartment(
        _profile(score: 450),
        _dept('d1', base: 400, ranking: 100000),
      );
      expect(eval!.basis, MatchBasis.score);
      expect(eval.fit, isNull);
    });

    test('motor: puanlı profil + tahminci üç kategoriye dağıtır', () {
      final result = PreferenceMatchEngine.matchAllPrograms(
        profile: _profile(score: 450),
        allDepartments: curveDepts,
        allUniversities: [_uni('u1')],
        estimator: estimator,
      );
      expect(result.total, 3);
      expect(result.guaranteed.single.department.id, 'e1');
      expect(result.target.single.department.id, 'e2');
      expect(result.dream.single.department.id, 'e3');
      for (final m in [
        ...result.guaranteed,
        ...result.target,
        ...result.dream,
      ]) {
        expect(m.matchBasis, MatchBasis.estimatedRank);
        expect(m.fitScore, isNotNull);
      }
    });
  });

  group('bayat referans yılı', () {
    test('2024 sırasına düşen program etiketlenir ve temkinli kategorilenir',
        () {
      final dept = _dept(
        'stale',
        base: 440,
        ranking: 0, // 2025 sırası yok
        previousYears: {
          '2024': {'baseScore': 445.0, 'ranking': 52000},
        },
      );
      final eval = evaluateDepartment(_profile(rank: 46800), dept);
      // ratio 0.90 → temel 70 (v1'de tam sınırda yüksek şans olurdu);
      // bayat yıl payı → 67 → ulaşılabilir.
      expect(eval!.fit, 67);
      expect(eval.category, MatchCategory.target);
      expect(eval.refRankYear, 2024);
    });
  });

  group('yumuşak tercih sinyalleri (WizardPrefs)', () {
    test('tercih edilen şehir kategori içinde öne gelir, kategori değişmez',
        () {
      final result = PreferenceMatchEngine.matchAllPrograms(
        profile: _profile(rank: 45000),
        allDepartments: [
          _dept('d-c1', uni: 'u1', base: 300, ranking: 100000),
          _dept('d-c2', uni: 'u2', base: 300, ranking: 100000),
        ],
        allUniversities: [_uni('u1'), _uni('u2', cityId: 'c2')],
        prefs: const WizardPrefs(cityIds: {'c2'}),
      );
      // Boost eleme/kategori değiştirme yapmaz — yalnız sıralar.
      expect(result.guaranteed.length, 2);
      expect(result.guaranteed.first.department.id, 'd-c2');
      expect(result.guaranteed.first.fitScore,
          result.guaranteed.last.fitScore); // görünen fit değişmedi
    });

    test('ilgi alanı bonusu bölüm ailesi üzerinden çalışır', () {
      final result = PreferenceMatchEngine.matchAllPrograms(
        profile: _profile(rank: 45000),
        allDepartments: [
          _dept('tarih', name: 'Tarih', base: 320, ranking: 46000),
          _dept('yazilim',
              name: 'Yazılım Mühendisliği', base: 320, ranking: 46000),
        ],
        allUniversities: [_uni('u1')],
        prefs: const WizardPrefs(interestKeys: {'bilgisayar'}),
      );
      expect(result.target.length, 2);
      expect(result.target.first.department.id, 'yazilim');
    });

    test('JSON gidiş-dönüş ve isEmpty', () {
      const prefs = WizardPrefs(
        cityIds: {'ist', 'ank'},
        uniTypes: {'Devlet'},
        interestKeys: {'bilgisayar', 'psikoloji'},
      );
      final restored = WizardPrefs.fromJson(prefs.toJson());
      expect(restored.cityIds, prefs.cityIds);
      expect(restored.uniTypes, prefs.uniTypes);
      expect(restored.interestKeys, prefs.interestKeys);
      expect(restored.isEmpty, isFalse);
      expect(const WizardPrefs().isEmpty, isTrue);
    });

    test('interestAreas anahtarları benzersiz ve aileleri kapsıyor', () {
      final keys = interestAreas.map((a) => a.key).toSet();
      expect(keys.length, interestAreas.length);
      expect(
        namesForInterests({'bilgisayar'}),
        contains('yazilim muhendisligi'),
      );
      expect(namesForInterests(const {}), isEmpty);
    });
  });

  group('buildMatchReasons', () {
    test('sıra-bazlı ana cümle marjı yüzdeyle anlatır', () {
      final result = PreferenceMatchEngine.matchAllPrograms(
        profile: _profile(rank: 45000),
        allDepartments: [_dept('d1', base: 300, ranking: 100000)],
        allUniversities: [_uni('u1')],
      );
      final reasons =
          buildMatchReasons(result.guaranteed.single, _profile(rank: 45000));
      expect(reasons.first.kind, MatchReasonKind.primary);
      expect(reasons.first.text, contains('sıran %55 önde'));
      expect(reasons.first.text, contains('100.000'));
    });

    test('boş kontenjan ve tahmini sıra etiketleri düşer', () {
      final estimator = RankEstimator.fromDepartments([
        _dept('e1', base: 400, ranking: 100000),
        _dept('e2', base: 450, ranking: 50000),
      ]);
      final result = PreferenceMatchEngine.matchAllPrograms(
        profile: _profile(score: 450),
        allDepartments: [
          _dept('d1', base: 400, ranking: 100000, quota: 10, placed: 7),
        ],
        allUniversities: [_uni('u1')],
        estimator: estimator,
      );
      final reasons =
          buildMatchReasons(result.guaranteed.single, _profile(score: 450));
      expect(
        reasons.any((r) =>
            r.kind == MatchReasonKind.emptySeats &&
            r.text.contains('3 kontenjan')),
        isTrue,
      );
      expect(
        reasons.any((r) => r.kind == MatchReasonKind.estimatedNudge),
        isTrue,
      );
    });

    test('formatRankTr binlik ayraç', () {
      expect(formatRankTr(999), '999');
      expect(formatRankTr(1000), '1.000');
      expect(formatRankTr(462104), '462.104');
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
