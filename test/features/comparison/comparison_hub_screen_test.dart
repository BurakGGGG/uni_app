import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_app/core/providers/shared_preferences_provider.dart';
import 'package:uni_app/features/comparison/domain/models/comparison_history_entry.dart';
import 'package:uni_app/features/comparison/presentation/providers/comparison_providers.dart';
import 'package:uni_app/features/comparison/presentation/screens/comparison_hub_screen.dart';
import 'package:uni_app/features/monetization/presentation/providers/subscription_providers.dart';
import 'package:uni_app/l10n/generated/app_localizations.dart';

/// Karşılaştırma hub'ı.
///
/// Kilitlenen sözleşme: **abonelik footer'ı yok** (kilitli kartın kendi
/// rozeti aynı şeyi zaten söylüyordu), üç tür satırı duruyor ve geçmiş
/// ikonun içinden çıkıp ekrana geldi.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    List<ComparisonHistoryEntry> history = const [],
    bool plus = false,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Üst köşedeki `TemporaryProBadge` prefs okuyor; override yoksa
    // "must be overridden in main.dart" ile patlıyor.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const ComparisonHubScreen()),
    ]);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          canCompareDepartmentsProvider.overrideWithValue(plus),
          canCompareCitiesProvider.overrideWithValue(plus),
          comparisonHistoryProvider.overrideWith(
            (ref) => Stream.value(history),
          ),
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

  testWidgets('abonelik footer\'ı ve yükselt butonu yoktur', (tester) async {
    await pump(tester);

    // Aynı mesaj ekranda iki kez söyleniyordu: kilitli kartın rozeti +
    // alttaki "Aboneliğin: Ücretsiz / Plus'a Geç" bloğu.
    expect(find.text('Aboneliğin'), findsNothing);
    expect(find.text("Plus'a Geç"), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('üç karşılaştırma türü de listelenir', (tester) async {
    await pump(tester);

    expect(find.text('Üniversite'), findsOneWidget);
    expect(find.text('Bölüm'), findsOneWidget);
    expect(find.text('Şehir'), findsOneWidget);
  });

  testWidgets('ücretsiz kullanıcıda kilitli türler Plus rozeti taşır',
      (tester) async {
    await pump(tester);
    expect(find.text('Plus'), findsNWidgets(2));
  });

  testWidgets('Plus kullanıcısında rozet düşer', (tester) async {
    await pump(tester, plus: true);
    expect(find.text('Plus'), findsNothing);
  });

  testWidgets('geçmiş yoksa bölüm hiç çizilmez', (tester) async {
    // Kilitli/boş bir bloğu boş boş göstermek satış gürültüsü olurdu.
    await pump(tester);
    expect(find.text('SON KARŞILAŞTIRMALARIN'), findsNothing);
  });

  testWidgets('geçmiş varsa ekranda görünür', (tester) async {
    await pump(tester, history: [
      _entry('itu', 'İTÜ', 'odtu', 'ODTÜ'),
      _entry('bogazici', 'Boğaziçi', 'koc', 'Koç'),
    ]);

    expect(find.text('SON KARŞILAŞTIRMALARIN'), findsOneWidget);
    expect(find.textContaining('İTÜ'), findsOneWidget);
    expect(find.textContaining('Boğaziçi'), findsOneWidget);

    // `flutter_animate` kademeli girişi zamanlayıcı bırakıyor; dolmadan
    // test biterse "Timer is still pending" ile kırılıyor.
    await tester.pump(const Duration(milliseconds: 400));
  });
}

ComparisonHistoryEntry _entry(
  String idA,
  String nameA,
  String idB,
  String nameB,
) {
  return ComparisonHistoryEntry(
    id: '$idA-$idB',
    type: ComparisonHistoryType.university,
    entityAId: idA,
    entityBId: idB,
    entityAName: nameA,
    entityBName: nameB,
    createdAt: DateTime(2026, 7, 26),
  );
}
