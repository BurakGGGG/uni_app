import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_app/features/assistant/data/robot_memory.dart';
import 'package:uni_app/features/assistant/domain/robot_scripts.dart';
import 'package:uni_app/features/assistant/presentation/widgets/robot_avatar.dart';
import 'package:uni_app/features/auth/presentation/screens/onboarding_screen.dart';

/// Onboarding artık Üni'nin ağzından konuşuyor: her sayfada robot,
/// metinler [RobotScripts] üzerinden iki dilli, son sayfada isim sorusu.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RobotScripts.languageCode = 'tr';
  });

  tearDown(() => RobotScripts.languageCode = 'tr');

  // Onboarding bitince `context.go('/login')` çalışır — gerçek router
  // yerine iki rotalık minimal bir GoRouter yeter.
  Future<void> pump(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (_, _) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('login')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('ilk sayfada Üni kendini tanıtır', (tester) async {
    await pump(tester);

    expect(find.byType(RobotAvatar), findsWidgets);
    expect(find.text(RobotScripts.onboardingPages.first.title), findsOneWidget);
  });

  // Performans kuralı: ekran başına en fazla bir animasyonlu avatar.
  // PageView komşu sayfaları canlı tuttuğu için bu kolayca bozulabilir.
  testWidgets('aynı anda yalnız bir animasyonlu avatar var', (tester) async {
    await pump(tester);

    final animated = tester
        .widgetList<RobotAvatar>(find.byType(RobotAvatar))
        .where((a) => a.animated);
    expect(animated, hasLength(1));
  });

  testWidgets('dil İngilizce ise metinler İngilizce', (tester) async {
    RobotScripts.languageCode = 'en';
    await pump(tester);

    expect(find.text(RobotScripts.onboardingPages.first.title), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('son sayfada isim kutusu çıkar, girilen ad hatırlanır',
      (tester) async {
    await pump(tester);

    // İlk sayfada isim kutusu yok.
    expect(find.byType(TextField), findsNothing);

    final controller = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;
    controller.jumpToPage(RobotScripts.onboardingPages.length - 1);
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Ada');

    // "Atla" da onboarding'i tamamlar — ad yine kaydedilmeli.
    await tester.tap(find.text('Atla'));
    await tester.pump();

    final memory = RobotMemory(await SharedPreferences.getInstance());
    expect(memory.displayName, 'Ada');
  });

  // Cihazda RenderFlex taşması olarak patlamıştı: isim kutusu eklenince
  // içerik kısa ekranda sığmıyordu. İçerik artık kaydırılabilir.
  testWidgets('kısa ekranda taşma yok', (tester) async {
    tester.view.physicalSize = const Size(720, 1200); // ~360x600 mantıksal
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pump(tester);
    expect(tester.takeException(), isNull);

    // Son sayfa en yüklü olan — isim kutusu orada.
    final controller =
        tester.widget<PageView>(find.byType(PageView)).controller!;
    controller.jumpToPage(RobotScripts.onboardingPages.length - 1);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);

    // Sayfa atlarken kurulan flutter_animate gecikme zamanlayıcısını boşalt.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('klavye açıkken de taşmaz ve isim kutusu erişilebilir',
      (tester) async {
    tester.view.physicalSize = const Size(720, 1200);
    tester.view.devicePixelRatio = 2.0;
    // Klavyenin kapladığı alanı taklit et.
    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await pump(tester);
    final controller =
        tester.widget<PageView>(find.byType(PageView)).controller!;
    controller.jumpToPage(RobotScripts.onboardingPages.length - 1);
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);

    // Sayfa atlarken kurulan flutter_animate gecikme zamanlayıcısını boşalt.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('isim boş bırakılırsa ad kaydedilmez', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Atla'));
    await tester.pump();

    final memory = RobotMemory(await SharedPreferences.getInstance());
    expect(memory.displayName, isNull);
  });
}
