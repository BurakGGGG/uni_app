import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/score_calculator/domain/models/match_result.dart';
import 'package:uni_app/features/score_calculator/domain/models/score_input.dart';
import 'package:uni_app/features/score_calculator/presentation/providers/score_calculator_providers.dart';
import 'package:uni_app/features/university/domain/models/department_model.dart';
import 'package:uni_app/features/university/domain/models/university_model.dart';
import 'package:uni_app/features/university/presentation/providers/university_providers.dart';

DepartmentModel _dept(String id, double baseScore, int ranking,
    {String name = 'Bilgisayar Mühendisliği', String scoreType = 'SAY'}) {
  return DepartmentModel(
    id: id,
    universityId: 'uni1',
    name: name,
    faculty: 'Mühendislik',
    type: 'Lisans',
    language: 'Türkçe',
    scoreData: DepartmentScoreData(
      year: 2025,
      scoreType: scoreType,
      baseScore: baseScore,
      ranking: ranking,
      quota: 60,
      placedCount: 60,
    ),
  );
}

void main() {
  // Site vakası: Y-SAY ≈ 418.6 → resmî 2025 dağılımında ~85 bin sıra.
  const input = ScoreInput(
    selectedYear: 2026,
    obpScore: 80,
    selectedDepartment: 'Bilgisayar Mühendisliği',
    tytTurkceCorrect: 22,
    tytSosyalCorrect: 12,
    tytMatCorrect: 22,
    tytFenCorrect: 12,
    aytMatCorrect: 22,
    aytFizikCorrect: 12,
    aytKimyaCorrect: 12,
    aytBiyoCorrect: 12,
  );

  final departments = [
    _dept('rahat', 340, 200000), // öğrenci sırası çok daha iyi → garanti
    _dept('sinirda', 415, 88000), // öğrenciyle başa baş → hedef civarı
    _dept('hayal', 470, 20000), // öğrenciden çok iyi → hayal
    _dept('hukuk', 380, 60000, name: 'Hukuk', scoreType: 'EA'),
  ];

  final universities = [
    UniversityModel(
      id: 'uni1',
      cityId: '06',
      name: 'Test Üniversitesi',
      type: 'Devlet',
      hasCampus: true,
      logoUrl: '',
      photoUrl: '',
      description: '',
      establishedYear: 1990,
      website: '',
    ),
  ];

  ProviderContainer buildContainer() {
    final container = ProviderContainer(overrides: [
      allScoredDepartmentsProvider.overrideWith((ref) async => departments),
      allUniversitiesProvider.overrideWith((ref) async => universities),
    ]);
    addTearDown(container.dispose);
    container.read(scoreInputProvider.notifier).state = input;
    return container;
  }

  test('multiScoreOutcomeProvider türleri, sırayı ve dilimi doldurur',
      () async {
    final container = buildContainer();
    final outcome =
        await container.read(multiScoreOutcomeProvider.future);

    expect(outcome, isNotNull);
    expect(outcome!.outcomes.map((o) => o.score.scoreType),
        ['TYT', 'SAY', 'EA']);
    final say = outcome.byType('SAY')!;
    expect(say.estimatedRank, greaterThan(65449)); // resmî 430 çapası
    expect(say.estimatedRank, lessThan(87117)); // resmî 410 çapası
    expect(say.percentile, isNotNull);
  });

  test('eligibleProgramsProvider sihirbaz motoruyla kategorize eder',
      () async {
    final container = buildContainer();
    final result =
        await container.read(eligibleProgramsProvider('SAY').future);

    expect(result, isNotNull);
    // EA Hukuk programı SAY listesine giremez.
    expect(result!.total, 3);
    expect(result.guaranteed.map((m) => m.department.id), contains('rahat'));
    expect(result.dream.map((m) => m.department.id), contains('hayal'));
  });

  test('targetDepartmentVerdictProvider hedef bölümü özetler', () async {
    final container = buildContainer();
    final verdict =
        await container.read(targetDepartmentVerdictProvider.future);

    expect(verdict, isNotNull);
    expect(verdict!.departmentName, 'Bilgisayar Mühendisliği');
    expect(verdict.total, 3); // Hukuk (EA) dahil değil — adı farklı
    // En uygun program en yüksek fit'li olan (rahat kaçan garanti program).
    expect(verdict.best.department.id, 'rahat');
    expect(verdict.guaranteed, greaterThanOrEqualTo(1));
  });

  test('hedef bölüm seçilmemişse verdict null', () async {
    final container = buildContainer();
    container.read(scoreInputProvider.notifier).state =
        input.copyWith(selectedDepartment: '');

    expect(
        await container.read(targetDepartmentVerdictProvider.future), isNull);
  });

  test('net yoksa multiScoreOutcome null döner', () async {
    final container = buildContainer();
    container.read(scoreInputProvider.notifier).state = const ScoreInput();

    expect(await container.read(multiScoreOutcomeProvider.future), isNull);
  });

  group('sıralama modu', () {
    const rankInput = ScoreInput(
      selectedYear: 2026,
      entryMode: NetEntryMode.rank,
      scoreType: 'SAY',
      enteredRank: 85000,
      selectedDepartment: 'Bilgisayar Mühendisliği',
    );

    test('tür ve sıra tamamsa tek türlük sonuç üretir', () async {
      final container = buildContainer();
      container.read(scoreInputProvider.notifier).state = rankInput;

      final outcome = await container.read(multiScoreOutcomeProvider.future);
      expect(outcome, isNotNull);
      expect(outcome!.outcomes.map((o) => o.score.scoreType), ['SAY']);
      expect(outcome.byType('SAY')!.rankIsUserEntered, isTrue);
    });

    test('tür seçilmemişse null döner (Hesapla kapalı kalır)', () async {
      final container = buildContainer();
      container.read(scoreInputProvider.notifier).state =
          rankInput.copyWith(scoreType: '');

      expect(await container.read(multiScoreOutcomeProvider.future), isNull);
    });

    test('girilen sıra motora GERÇEK sıra olarak gider', () async {
      final container = buildContainer();
      container.read(scoreInputProvider.notifier).state = rankInput;

      final result =
          await container.read(eligibleProgramsProvider('SAY').future);
      expect(result, isNotNull);
      // Gerçek sıra → MatchBasis.rank (tahmin belirsizliği uygulanmaz).
      for (final match in [
        ...result!.guaranteed,
        ...result.target,
        ...result.dream,
      ]) {
        expect(match.matchBasis, MatchBasis.rank,
            reason: '${match.department.id} tahmini sıra yoluna düştü');
      }
      // 85.000 sırayla 200.000 taban sıralı program garanti olmalı.
      expect(result.guaranteed.map((m) => m.department.id), contains('rahat'));
      expect(result.dream.map((m) => m.department.id), contains('hayal'));
    });

    test('puan modunda sıra TAHMİN yoluna düşer (gerileme koruması)',
        () async {
      final container = buildContainer();
      final result =
          await container.read(eligibleProgramsProvider('SAY').future);

      expect(result, isNotNull);
      expect(
        [...result!.guaranteed, ...result.target, ...result.dream]
            .map((m) => m.matchBasis),
        everyElement(MatchBasis.estimatedRank),
      );
    });

    test('hedef bölüm listesi seçilen türe göre süzülür', () async {
      final container = buildContainer();

      // Tür verilmezse tüm bölümler (eski davranış).
      expect(await container.read(uniqueDepartmentNamesProvider('').future),
          containsAll(['Bilgisayar Mühendisliği', 'Hukuk']));
      // TYT seçen kullanıcıya SAY bölümü önerilmemeli.
      expect(await container.read(uniqueDepartmentNamesProvider('SAY').future),
          ['Bilgisayar Mühendisliği']);
      expect(await container.read(uniqueDepartmentNamesProvider('EA').future),
          ['Hukuk']);
      expect(await container.read(uniqueDepartmentNamesProvider('TYT').future),
          isEmpty);
    });

    test('tür değişince seçili hedef bölüm bayat kalmaz', () {
      // Ekran türü değiştirirken selectedDepartment'ı temizliyor; model
      // tarafında bu kombinasyonun geçerli olduğunu sabitle.
      const withDept = ScoreInput(
        entryMode: NetEntryMode.rank,
        scoreType: 'SAY',
        enteredRank: 85000,
        selectedDepartment: 'Bilgisayar Mühendisliği',
      );
      final switched =
          withDept.copyWith(scoreType: 'TYT', selectedDepartment: '');
      expect(switched.selectedDepartment, '');
      expect(switched.enteredRank, 85000);
    });

    test('yıl karşılaştırması sıra modunda ters tabloyu kullanır', () async {
      final container = buildContainer();
      container.read(scoreInputProvider.notifier).state = rankInput;

      final rows = await container.read(yearComparisonProvider('SAY').future);
      expect(rows.map((r) => r.year), [2022, 2023, 2024, 2025]);
      expect(rows.every((r) => r.estimatedRank == 85000), isTrue);
    });
  });
}
