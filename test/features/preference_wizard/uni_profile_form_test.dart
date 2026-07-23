import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_app/core/providers/shared_preferences_provider.dart';
import 'package:uni_app/features/preference_wizard/presentation/providers/preference_wizard_providers.dart';
import 'package:uni_app/features/preference_wizard/presentation/screens/uni_profile_form_screen.dart';
import 'package:uni_app/features/university/domain/models/city_model.dart';
import 'package:uni_app/features/university/presentation/providers/university_providers.dart';

/// Sohbetin yerine gelen form: seçimler DOĞRU KATMANA yazılmalı.
/// Yumuşak sinyaller (ilgi/şehir/tür/dil) sıralamayı etkiler, elemez;
/// sert filtreler (program türü, burslu) gerçekten eler.
void main() {
  late ProviderContainer container;

  /// Form "Önerilerimi göster"de `context.push` çağırıyor — gerçek bir
  /// router olmadan assert atar. Sonuç ekranı yerine işaret koyan bir
  /// yer tutucu yeter.
  ///
  /// `disableAnimations`: başlıktaki Üni avatarı animasyonlu, bu bayrak
  /// olmadan test sonunda bekleyen timer kalır (RobotAvatar bayrağı görünce
  /// hiç controller kurmaz).
  Widget app(ProviderContainer container) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const UniProfileFormScreen(),
          routes: [
            GoRoute(
              path: 'preference-wizard/results',
              builder: (_, _) =>
                  const Scaffold(body: Text('sonuçlar')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    return UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final overrides = [
      sharedPreferencesProvider.overrideWithValue(prefs),
      citiesProvider.overrideWith((ref) async => const [
            CityModel(
              id: '34',
              name: 'İstanbul',
              plateCode: '34',
              photoUrl: '',
              totalUniversityCount: 0,
              appUniversityCount: 0,
            ),
            CityModel(
              id: '06',
              name: 'Ankara',
              plateCode: '06',
              photoUrl: '',
              totalUniversityCount: 0,
              appUniversityCount: 0,
            ),
          ]),
    ];
    container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);

    await tester.pumpWidget(app(container));
    await tester.pump();
  }

  testWidgets('sohbet yok — form başlığı ve bölümleri görünür',
      (tester) async {
    await pump(tester);

    expect(find.text('Üni seni tanısın'), findsOneWidget);
    expect(find.text('Neye ilgin var?'), findsOneWidget);
    expect(find.text('Hangi şehirler?'), findsOneWidget);
    expect(find.text('Öğretim dili'), findsOneWidget);
    expect(find.text('Önerilerimi göster'), findsOneWidget);
    // Serbest metin girişi yok.
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('ilgi ve dil seçimi yumuşak katmana yazılır', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Hukuk'));
    await tester.tap(find.text('İngilizce'));
    await tester.pump();

    // Uygulanana kadar depoya yazılmaz.
    expect(container.read(wizardPrefsProvider).interestKeys, isEmpty);

    await tester.tap(find.text('Önerilerimi göster'));
    await tester.pump();

    final prefs = container.read(wizardPrefsProvider);
    expect(prefs.interestKeys, contains('hukuk'));
    expect(prefs.languages, contains('İngilizce'));
    // Yumuşak seçimler sert filtreye SIZMAZ — yoksa listeyi eleyerek daraltır.
    expect(container.read(wizardFilterProvider).languages, isEmpty);
  });

  testWidgets('şehir seçimi yumuşak katmana yazılır', (tester) async {
    await pump(tester);
    await tester.pump(); // citiesProvider çözülsün

    await tester.tap(find.text('Ankara'));
    await tester.pump();
    await tester.tap(find.text('Önerilerimi göster'));
    await tester.pump();

    expect(container.read(wizardPrefsProvider).cityIds, contains('06'));
    expect(container.read(wizardFilterProvider).cityIds, isEmpty);
  });

  testWidgets('program türü ve burs seçimi sert filtreye yazılır',
      (tester) async {
    await pump(tester);

    await tester.tap(find.text('Önlisans'));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await tester.tap(find.text('Önerilerimi göster'));
    await tester.pump();

    final filter = container.read(wizardFilterProvider);
    expect(filter.programTypes, contains('Önlisans'));
    expect(filter.onlyScholarship, isTrue);
    expect(filter.hasAnyFilter, isTrue);
  });

  testWidgets('kayıtlı seçimler formda önseçili gelir', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Hukuk'));
    await tester.pump();
    await tester.tap(find.text('Önerilerimi göster'));
    await tester.pump();

    // Aynı container ile ekranı yeniden kur.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(container));
    await tester.pump();

    final chip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Hukuk'),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('seçim geri alınabilir', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Hukuk'));
    await tester.pump();
    await tester.tap(find.text('Hukuk'));
    await tester.pump();
    await tester.tap(find.text('Önerilerimi göster'));
    await tester.pump();

    expect(container.read(wizardPrefsProvider).interestKeys, isEmpty);
  });
}
