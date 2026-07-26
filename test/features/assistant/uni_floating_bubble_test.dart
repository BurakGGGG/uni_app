import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_app/core/providers/shared_preferences_provider.dart';
import 'package:uni_app/core/services/feature_discovery_service.dart';
import 'package:uni_app/features/assistant/data/robot_memory.dart';
import 'package:uni_app/features/assistant/domain/insights/uni_insight.dart';
import 'package:uni_app/features/assistant/domain/robot_message.dart';
import 'package:uni_app/features/assistant/domain/robot_mood.dart';
import 'package:uni_app/features/assistant/presentation/providers/assistant_providers.dart';
import 'package:uni_app/features/assistant/presentation/providers/uni_panel_providers.dart';
import 'package:uni_app/features/assistant/presentation/widgets/robot_avatar.dart';
import 'package:uni_app/features/assistant/presentation/widgets/uni_floating_bubble.dart';

/// Yüzen Üni: her sekmede duran avatar + açılışta bir selam, ardından yalnız
/// gerçek bir notu varsa açılan minik konuşma balonu.
///
/// Kilitlenen sözleşme — hepsi "Clippy olmasın" kuralları: selam da not da
/// oturumda bir kez, elle kapatılanın arkasından yenisi gelmez, tur bitmeden
/// hiç konuşmaz, kapatılan not susturulur.
void main() {
  const note = UniInsight(
    id: 'list.noSafe',
    kind: InsightKind.list,
    priority: 80,
    title: 'Listende güvenli tercih yok',
    body: 'İlk beş sıraya ulaşılabilir bir program eklemelisin.',
    tone: InsightTone.warning,
    actionLabel: 'Listeyi aç',
    action: RobotAction.openLists,
  );

  const greeting = RobotMessage(
    'home.tercih',
    'Selam Burak! Ben Üni.',
    RobotMood.happy,
    action: RobotAction.openScoreCalculator,
  );

  late SharedPreferences prefs;

  Future<ProviderContainer> containerWith({
    UniInsight? insight,
    bool tourDone = true,
  }) async {
    SharedPreferences.setMockInitialValues(
      tourDone ? {FeatureDiscoveryService.homeCompleted: true} : {},
    );
    prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      topInsightProvider.overrideWithValue(insight),
      // Gerçek selamlama Firebase'e (currentUserProvider) bakıyor; testin
      // konusu metin değil sıra.
      homeGreetingProvider.overrideWithValue(greeting),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  /// `disableAnimations`: RobotAvatar bayrağı görünce hiç controller kurmaz —
  /// yoksa test sonunda bekleyen timer kalır.
  Widget app(ProviderContainer container, {Widget? page, String path = '/'}) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: UniFloatingLayer(
              currentPath: path,
              child: page ?? const SizedBox.expand(),
            ),
          ),
        ),
        GoRoute(
          path: '/uni',
          builder: (_, _) => const Scaffold(body: Text('üni paneli')),
        ),
        GoRoute(
          path: '/my-lists',
          builder: (_, _) => const Scaffold(body: Text('listelerim')),
        ),
        GoRoute(
          path: '/score-calculator',
          builder: (_, _) => const Scaffold(body: Text('puan hesaplayıcı')),
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

  setUp(UniFloatingLayer.resetSpokenSession);

  /// Katman dispose edilmeden testi bitirirsek bekleyen timer'lar kalır.
  Future<void> teardownTree(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  group('selamlama', () {
    testWidgets('açılışta bir kez selamlar, sonra susar', (tester) async {
      final container = await containerWith(insight: null);
      await tester.pumpWidget(app(container));

      // Hemen değil: ekran yerine otursun.
      expect(find.text(greeting.text), findsNothing);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text(greeting.text), findsOneWidget);

      await tester.pump(const Duration(seconds: 8)); // kendi kapanır
      expect(find.text(greeting.text), findsNothing);

      // Sekme değişimi gibi: katman yeniden kurulur, selam tekrar etmez.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(container));
      await tester.pump(const Duration(seconds: 3));
      expect(find.text(greeting.text), findsNothing);

      await teardownTree(tester);
    });

    testWidgets('selama dokunmak mesajın eylemine gider', (tester) async {
      final container = await containerWith(insight: null);
      await tester.pumpWidget(app(container));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text(greeting.text));
      await tester.pumpAndSettle();

      expect(find.text('puan hesaplayıcı'), findsOneWidget);

      await teardownTree(tester);
    });

    testWidgets('selamın süresi dolunca sıradaki not gelir', (tester) async {
      final container = await containerWith(insight: note);
      await tester.pumpWidget(app(container));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text(greeting.text), findsOneWidget);
      expect(find.text(note.title), findsNothing);

      // Selam kapanır → not sıraya girer.
      await tester.pump(const Duration(seconds: 8));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text(greeting.text), findsNothing);
      expect(find.text(note.title), findsOneWidget);

      await teardownTree(tester);
    });

    testWidgets('selam ELLE kapatılırsa arkasından not gelmez',
        (tester) async {
      final container = await containerWith(insight: note);
      await tester.pumpWidget(app(container));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byTooltip('Kapat'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      // Susturduğu şeyin yerine yenisini koymak dırdır olurdu.
      expect(find.text(note.title), findsNothing);

      await teardownTree(tester);
    });
  });

  group('notlar', () {
    setUp(() => UniFloatingLayer.resetSpokenSession(greeted: true));

    testWidgets('not yokken avatar var, balon yok', (tester) async {
      final container = await containerWith(insight: null);
      await tester.pumpWidget(app(container));
      await tester.pump(const Duration(seconds: 3));

      expect(find.byType(RobotAvatar), findsOneWidget);
      expect(find.textContaining('güvenli tercih'), findsNothing);
      expect(find.text(greeting.text), findsNothing);

      await teardownTree(tester);
    });

    testWidgets('avatara dokunmak Üni panelini açar', (tester) async {
      final container = await containerWith(insight: null);
      await tester.pumpWidget(app(container));
      await tester.pump();

      await tester.tap(find.byType(RobotAvatar));
      await tester.pumpAndSettle();

      expect(find.text('üni paneli'), findsOneWidget);

      await teardownTree(tester);
    });

    testWidgets('notu varsa kısa bir gecikmeyle konuşur', (tester) async {
      final container = await containerWith(insight: note);
      await tester.pumpWidget(app(container));
      await tester.pump();

      expect(find.text(note.title), findsNothing);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text(note.title), findsOneWidget);

      // Kendi kendine kapanır — kullanıcı uğraşmak zorunda kalmaz.
      await tester.pump(const Duration(seconds: 8));
      expect(find.text(note.title), findsNothing);

      await teardownTree(tester);
    });

    testWidgets('aynı not oturumda ikinci kez konuşmaz', (tester) async {
      final container = await containerWith(insight: note);
      await tester.pumpWidget(app(container));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text(note.title), findsOneWidget);
      await tester.pump(const Duration(seconds: 8)); // kapansın

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(container));
      await tester.pump(const Duration(seconds: 3));

      expect(find.text(note.title), findsNothing);

      await teardownTree(tester);
    });

    testWidgets('balona dokunmak notun eylemine gider', (tester) async {
      final container = await containerWith(insight: note);
      await tester.pumpWidget(app(container));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text(note.title));
      await tester.pumpAndSettle();

      // Avatar panele götürür, balon notun kendi hedefine.
      expect(find.text('listelerim'), findsOneWidget);

      await teardownTree(tester);
    });

    testWidgets('kapatılan not susturulur', (tester) async {
      final container = await containerWith(insight: note);
      await tester.pumpWidget(app(container));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byTooltip('Kapat'));
      await tester.pump();

      expect(find.text(note.title), findsNothing);
      expect(
        container.read(robotMemoryProvider).isInsightDismissed(note.id),
        isTrue,
      );

      await teardownTree(tester);
    });

    testWidgets('aşağı kaydırırken çekilir', (tester) async {
      final container = await containerWith(insight: null);
      await tester.pumpWidget(app(
        container,
        page: ListView.builder(
          itemCount: 40,
          itemBuilder: (_, i) => SizedBox(height: 80, child: Text('satır $i')),
        ),
      ));
      await tester.pump();

      double opacity() => tester
          .widget<AnimatedOpacity>(find.byType(AnimatedOpacity))
          .opacity;

      expect(opacity(), 1);

      final gesture =
          await tester.startGesture(tester.getCenter(find.text('satır 1')));
      await gesture.moveBy(const Offset(0, -220));
      await tester.pump();
      expect(opacity(), 0, reason: 'kaydırırken içeriği kapatmasın');

      // Parmak kalkınca (kaydırma yönü idle) geri gelir.
      await gesture.up();
      await tester.pump();
      expect(opacity(), 1);

      await teardownTree(tester);
    });
  });

  /// Sekme ipuçları: ana sayfa dışındaki her sekmede Üni önce "burası ne işe
  /// yarar" der. Hangi metnin çıkacağı `screen_tips_test.dart`'ta; burada
  /// balonun DAVRANIŞI kilitleniyor.
  group('ekran ipuçları', () {
    setUp(() => UniFloatingLayer.resetSpokenSession(greeted: true));

    testWidgets('ana sayfada ipucu vermez', (tester) async {
      final container = await containerWith(insight: null);
      await tester.pumpWidget(app(container));
      await tester.pump(const Duration(seconds: 3));

      expect(find.byType(RobotAvatar), findsOneWidget);
      expect(find.textContaining('keşif alanın'), findsNothing);

      await teardownTree(tester);
    });

    testWidgets('keşfet sekmesinde ekranı anlatır', (tester) async {
      final container = await containerWith(insight: null);
      await tester.pumpWidget(app(container, path: '/explore'));
      await tester.pump(const Duration(seconds: 2));

      expect(find.textContaining('keşif alanın'), findsOneWidget);

      await teardownTree(tester);
    });

    testWidgets('ipucu nottan ÖNCE gelir, sonra not sıraya girer',
        (tester) async {
      final container = await containerWith(insight: note);
      await tester.pumpWidget(app(container, path: '/explore'));
      await tester.pump(const Duration(seconds: 2));

      // Yeni sekmeye gelenin ilk sorusu "burası ne işe yarıyor".
      expect(find.textContaining('keşif alanın'), findsOneWidget);
      expect(find.text(note.title), findsNothing);

      await tester.pump(const Duration(seconds: 8));
      await tester.pump(const Duration(seconds: 2));

      expect(find.textContaining('keşif alanın'), findsNothing);
      expect(find.text(note.title), findsOneWidget);

      await teardownTree(tester);
    });

    testWidgets('ipucuna dokunmak ekrandan koparmaz, yalnız kapatır',
        (tester) async {
      final container = await containerWith(insight: null);
      await tester.pumpWidget(app(container, path: '/explore'));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.textContaining('keşif alanın'));
      await tester.pumpAndSettle();

      expect(find.textContaining('keşif alanın'), findsNothing);
      // Not balonunun aksine hiçbir yere gitmez.
      expect(find.text('üni paneli'), findsNothing);

      await teardownTree(tester);
    });

    testWidgets('aynı sekmeye dönmek ipucunu tekrarlatmaz', (tester) async {
      final container = await containerWith(insight: null);
      await tester.pumpWidget(app(container, path: '/explore'));
      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('keşif alanın'), findsOneWidget);
      await tester.pump(const Duration(seconds: 8)); // kapansın

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(container, path: '/explore'));
      await tester.pump(const Duration(seconds: 3));

      expect(find.textContaining('keşif alanın'), findsNothing);

      await teardownTree(tester);
    });

    testWidgets('cihaz kotası dolduysa bir daha söylenmez', (tester) async {
      final container = await containerWith(insight: null);
      final memory = container.read(robotMemoryProvider);
      for (var i = 0; i < RobotMemory.screenTipMaxShows; i++) {
        await memory.recordScreenTipShown('screen.explore');
      }

      await tester.pumpWidget(app(container, path: '/explore'));
      await tester.pump(const Duration(seconds: 3));

      expect(find.textContaining('keşif alanın'), findsNothing);

      await teardownTree(tester);
    });

    testWidgets('gösterilen ipucu cihazda sayılır', (tester) async {
      final container = await containerWith(insight: null);
      await tester.pumpWidget(app(container, path: '/explore'));
      await tester.pump(const Duration(seconds: 2));

      // İki oturum sonra susması bu sayaca bağlı.
      expect(
        container.read(robotMemoryProvider).canShowScreenTip('screen.explore'),
        isTrue,
      );
      expect(prefs.getInt('assistant_tip_screen.explore'), 1);

      await teardownTree(tester);
    });
  });

  testWidgets('uygulama turu bitmediyse hiç konuşmaz', (tester) async {
    final container = await containerWith(insight: note, tourDone: false);
    await tester.pumpWidget(app(container));
    await tester.pump(const Duration(seconds: 3));

    expect(find.text(greeting.text), findsNothing);
    expect(find.text(note.title), findsNothing);
    expect(find.byType(RobotAvatar), findsOneWidget);

    await teardownTree(tester);
  });
}
