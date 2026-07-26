import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:uni_app/router/app_router.dart';

/// "Üni seni tanısın" formu akışın iki adımına taşındı; eski rota artık
/// yönlendirme. Dikkat edilecek yer, `/preference-wizard/results`'ın bu
/// yönlendirmeye TAKILMAMASI — ikisi de aynı önekle başlıyor.
void main() {
  testWidgets('eski form rotası akışa yönlenir, sonuç rotası bozulmaz',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/x',
      routes: [
        GoRoute(path: '/x', builder: (_, _) => const Scaffold(body: Text('x'))),
        GoRoute(
          path: AppRoutes.preferenceWizard,
          redirect: (_, _) => '${AppRoutes.uniFlow}?step=interests',
        ),
        GoRoute(
          path: AppRoutes.preferenceWizardResults,
          builder: (_, _) => const Scaffold(body: Text('sonuçlar')),
        ),
        GoRoute(
          path: AppRoutes.uniFlow,
          builder: (_, state) => Scaffold(
            body: Text('akış:${state.uri.queryParameters['step']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    router.push(AppRoutes.preferenceWizard);
    await tester.pumpAndSettle();
    expect(find.text('akış:interests'), findsOneWidget);

    router.push(AppRoutes.preferenceWizardResults);
    await tester.pumpAndSettle();
    expect(find.text('sonuçlar'), findsOneWidget);
  });
}
