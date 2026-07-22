import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_app/core/providers/shared_preferences_provider.dart';
import 'package:uni_app/features/best_programs/presentation/providers/best_programs_providers.dart';
import 'package:uni_app/features/best_programs/presentation/screens/best_programs_screen.dart';
import 'package:uni_app/features/best_programs/presentation/widgets/best_program_card.dart';
import 'package:uni_app/features/score_calculator/presentation/providers/score_calculator_providers.dart';
import 'package:uni_app/features/university/domain/models/department_model.dart';
import 'package:uni_app/features/university/domain/models/university_model.dart';
import 'package:uni_app/features/university/presentation/providers/university_providers.dart';

UniversityModel _uni(String id, {String type = 'Devlet', String city = '06'}) {
  return UniversityModel(
    id: id,
    cityId: city,
    name: 'Üniversite $id',
    type: type,
    hasCampus: true,
    logoUrl: '',
    photoUrl: '',
    description: '',
    establishedYear: 1990,
    website: '',
  );
}

DepartmentModel _dept(String id, String uniId, int ranking,
    {String name = 'Tıp'}) {
  return DepartmentModel(
    id: id,
    universityId: uniId,
    name: name,
    faculty: 'Tıp Fakültesi',
    type: 'Lisans',
    language: 'Türkçe',
    scoreData: DepartmentScoreData(
      year: 2025,
      scoreType: 'SAY',
      baseScore: 520,
      ranking: ranking,
      quota: 100,
      placedCount: 100,
    ),
  );
}

void main() {
  // FeasibilityChip profili SharedPreferences'tan okur — override edilmezse
  // kart çizilirken patlar.
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  final departments = [
    _dept('d1', 'a', 5000),
    _dept('d2', 'b', 100),
    _dept('d3', 'c', 20000),
    _dept('hukuk', 'a', 3000, name: 'Hukuk'),
  ];
  final universities = [
    _uni('a'),
    _uni('b', type: 'Vakıf', city: '34'),
    _uni('c'),
  ];

  Future<void> pump(WidgetTester tester, {String? dept}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          allScoredDepartmentsProvider.overrideWith((ref) async => departments),
          allUniversitiesProvider.overrideWith((ref) async => universities),
        ],
        child: MaterialApp(home: BestProgramsScreen(departmentName: dept)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('bölüm listesi başarı sırasına göre sıralı gelir',
      (tester) async {
    await pump(tester, dept: 'Tıp');

    expect(find.text('Tıp'), findsOneWidget); // başlık
    expect(find.byType(BestProgramCard), findsNWidgets(3));
    expect(find.text('3 program'), findsOneWidget);

    // En iyi sıralı program (100) birinci kartta olmalı.
    final cards =
        tester.widgetList<BestProgramCard>(find.byType(BestProgramCard));
    expect(cards.map((c) => c.program.department.id), ['d2', 'd1', 'd3']);
    expect(cards.first.program.position, 1);
    // Tek bölümün listesinde ad tekrar edilmez.
    expect(cards.first.showDepartmentName, isFalse);
  });

  testWidgets('veri kapsamı dipnotu her zaman görünür', (tester) async {
    await pump(tester, dept: 'Tıp');
    expect(find.textContaining('105 üniversite'), findsOneWidget);
    expect(find.textContaining('burslu kontenjana aittir'), findsOneWidget);
  });

  testWidgets('filtre uygulanınca liste süzülür', (tester) async {
    await pump(tester, dept: 'Tıp');
    final container = ProviderScope.containerOf(
      tester.element(find.byType(BestProgramsScreen)),
    );

    container.read(bestProgramsQueryProvider.notifier).state = container
        .read(bestProgramsQueryProvider)
        .copyWith(uniTypes: {'Vakıf'});
    await tester.pumpAndSettle();

    expect(find.byType(BestProgramCard), findsOneWidget);
    expect(find.text('1 program'), findsOneWidget);
  });

  testWidgets('sonuç kalmayınca boş durum gösterilir', (tester) async {
    await pump(tester, dept: 'Tıp');
    final container = ProviderScope.containerOf(
      tester.element(find.byType(BestProgramsScreen)),
    );

    container.read(bestProgramsQueryProvider.notifier).state = container
        .read(bestProgramsQueryProvider)
        .copyWith(cityIds: {'99'});
    await tester.pumpAndSettle();

    expect(find.byType(BestProgramCard), findsNothing);
    expect(find.text('Bu filtrelerle program kalmadı'), findsOneWidget);
  });

  testWidgets('alan rotası kategoriyi uygular', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          allScoredDepartmentsProvider.overrideWith((ref) async => departments),
          allUniversitiesProvider.overrideWith((ref) async => universities),
        ],
        child: const MaterialApp(
          home: BestProgramsScreen(categoryKey: 'hukuk-siyaset'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hukuk & Siyaset'), findsOneWidget);
    expect(find.byType(BestProgramCard), findsOneWidget);
    // Alan listesinde bölüm adı kartta görünür.
    final card =
        tester.widget<BestProgramCard>(find.byType(BestProgramCard));
    expect(card.showDepartmentName, isTrue);
  });
}
