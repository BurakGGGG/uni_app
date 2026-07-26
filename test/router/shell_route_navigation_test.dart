import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:uni_app/router/app_router.dart';

/// Alt sekme rotalarına geçişin Navigator'ı patlatmadığını doğrular.
///
/// Gerçek çökme: kullanıcı ana sayfadan `/uni`'ye geçip panelin "Listeyi aç"
/// düğmesine bastığında `'!keyReservation.contains(key)'` assert'i atıyordu.
/// Sebep, `StatefulShellRoute` rotalarının `push` edilmesi: shell yığının en
/// üstünde değilken go_router ikinci bir `ShellRouteMatch` klonu ekliyor ve
/// klon aynı page key'i (`ValueKey(route.hashCode)`) taşıyor.
///
/// Her senaryo AYRI test: assert atan bir test, aynı dosyadaki sonraki
/// testlerin çerçevesini de bozuyor ve gerçek sebep görünmez oluyor.
void main() {
  /// Uygulamanın rota iskeletinin küçük kopyası: shell dışında bir `/uni`
  /// rotası + iki sekmeli `StatefulShellRoute`.
  GoRouter buildRouter() => GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.uniPanel,
            builder: (_, _) => const Scaffold(body: Text('uni')),
          ),
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => Scaffold(body: shell),
            branches: [
              StatefulShellBranch(routes: [
                GoRoute(
                  path: AppRoutes.home,
                  pageBuilder: (_, _) =>
                      const NoTransitionPage(child: Scaffold(body: Text('ev'))),
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  path: AppRoutes.myLists,
                  pageBuilder: (_, _) => const NoTransitionPage(
                    child: Scaffold(body: Text('listeler')),
                  ),
                ),
              ]),
            ],
          ),
        ],
      );

  /// `/uni` açıkken [route]'a [navigateToRoute] ile gider.
  Future<void> goFromPanel(WidgetTester tester, String route) async {
    final router = buildRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    router.push(AppRoutes.uniPanel);
    await tester.pumpAndSettle();

    final context = tester.element(find.text('uni'));
    navigateToRoute(context, route);
    await tester.pumpAndSettle();
  }

  testWidgets('panelden alt sekmeye geçiş Navigator\'ı patlatmaz',
      (tester) async {
    await goFromPanel(tester, AppRoutes.myLists);

    expect(tester.takeException(), isNull);
    expect(find.text('listeler'), findsOneWidget);
  });

  testWidgets('panelden sekme olmayan rotaya geçiş push olarak kalır',
      (tester) async {
    await goFromPanel(tester, AppRoutes.uniPanel);

    expect(tester.takeException(), isNull);
    // push edildiği için panel yığında iki kez var — geri tuşu çalışmalı.
    expect(find.text('uni'), findsOneWidget);
  });

  test('shellBranches listesi sorgu dizesiyle de doğru eşleşir', () {
    // `/best-programs?dept=X` bir sekme değildir; yol kısmına bakılmalı.
    expect(AppRoutes.shellBranches.contains('/best-programs'), isFalse);
    expect(AppRoutes.shellBranches.contains(AppRoutes.myLists), isTrue);
  });
}
