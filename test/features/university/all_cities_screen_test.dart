import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:uni_app/features/university/domain/models/city_model.dart';
import 'package:uni_app/features/university/presentation/providers/university_providers.dart';
import 'package:uni_app/features/university/presentation/screens/all_cities_screen.dart';
import 'package:uni_app/features/university/presentation/widgets/city_card.dart';
import 'package:uni_app/l10n/generated/app_localizations.dart';

/// Tüm şehirler ekranı.
///
/// Kilitlenen sözleşme: kapsam başlıkta gerçek sayılarla yazılır, bölge
/// rozetleri gerçekten süzer ve sıralama değişince liste yeniden dizilir.
void main() {
  CityModel city(
    String plate,
    String name, {
    int app = 1,
    int? population,
  }) =>
      CityModel(
        id: plate,
        name: name,
        plateCode: plate,
        photoUrl: '',
        totalUniversityCount: app,
        appUniversityCount: app,
        population: population,
      );

  final cities = [
    city('34', 'İstanbul', app: 20, population: 15900000),
    city('06', 'Ankara', app: 11, population: 5800000),
    city('35', 'İzmir', app: 7),
    city('41', 'Kocaeli', app: 2),
    city('26', 'Eskişehir', app: 3),
  ];

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const AllCitiesScreen()),
        GoRoute(path: '/city/:id', builder: (_, _) => const SizedBox()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          citiesProvider.overrideWith((ref) async => cities),
        ],
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Bölge adı iki yerde geçiyor: rozette ve kartın üstünde. İkisini
  // ayırmadan yapılan her arama iki sonuç buluyor.
  Finder chip(String label) => find.widgetWithText(AnimatedContainer, label);
  Finder card(String name) => find.descendant(
        of: find.byType(CityCard),
        matching: find.text(name),
      );

  testWidgets('başlık kapsamı gerçek sayılarla söyler', (tester) async {
    await pump(tester);

    // Eskiden sabit bir slogan vardı ("Türkiye'nin üniversite şehirleri");
    // sayılar hem daha bilgilendirici hem de veriyle birlikte güncelleniyor.
    expect(find.text('5 şehir · 43 üniversite'), findsWidgets);
  });

  testWidgets('bölge rozeti listeyi süzer', (tester) async {
    await pump(tester);

    expect(card('İzmir'), findsOneWidget);

    await tester.tap(chip('Marmara'));
    await tester.pumpAndSettle();

    expect(card('İstanbul'), findsOneWidget);
    expect(card('Kocaeli'), findsOneWidget);
    expect(card('İzmir'), findsNothing);
    expect(find.text('2 şehir · 22 üniversite'), findsOneWidget);
  });

  testWidgets('rozet yalnız o bölgede şehir varken çıkar', (tester) async {
    await pump(tester);

    // Veri setinde Karadeniz şehri yok — rozet boş sonuç vaat etmemeli.
    expect(chip('Karadeniz'), findsNothing);
    expect(chip('Ege'), findsOneWidget);
  });

  testWidgets('sıralama seçimi listeyi yeniden dizer', (tester) async {
    await pump(tester);

    Offset yOf(String name) => tester.getTopLeft(card(name));

    // Varsayılan: üniversite sayısına göre.
    expect(yOf('İstanbul').dy, lessThan(yOf('Kocaeli').dy));

    await tester.tap(find.byTooltip('Sırala'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("A'dan Z'ye").last);
    await tester.pumpAndSettle();

    expect(yOf('Ankara').dy, lessThan(yOf('İstanbul').dy));
  });

  testWidgets('arama temizlenince liste geri gelir', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'kocaeli');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(card('Kocaeli'), findsOneWidget);
    expect(card('İstanbul'), findsNothing);

    // Aramayı geri almanın tek yolu klavyeyle silmekti.
    await tester.tap(find.byTooltip('Aramayı temizle'));
    await tester.pumpAndSettle();

    expect(card('İstanbul'), findsOneWidget);
  });

  testWidgets('sonuç yokken süzgeci temizleme sunulur', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Şehir bulunamadı'), findsOneWidget);

    await tester.tap(find.text('Süzgeci temizle'));
    await tester.pumpAndSettle();

    expect(card('İstanbul'), findsOneWidget);
  });
}
