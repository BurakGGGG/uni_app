import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/core/utils/snackbar_helper.dart';

/// SnackBar sözleşmesi.
///
/// **Flutter tuzağı:** `SnackBar.persist` varsayılanı `action != null` —
/// yani GERİ AL / Giriş yap gibi bir eylem veren SnackBar süresi dolsa da
/// ekranda KALIR. Kullanıcı içeriği onun altından okumaya çalışıyor.
/// `showAppSnackBar` bunu kapatıyor; test kapalı kaldığını doğruluyor.
void main() {
  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    return ctx;
  }

  testWidgets('eylemli SnackBar süresi dolunca kaybolur', (tester) async {
    final ctx = await pumpHost(tester);

    showAppSnackBar(
      ctx,
      message: 'Zorlayıcıdan güvenliye sıralandı',
      duration: const Duration(seconds: 5),
      action: SnackBarAction(label: 'GERİ AL', onPressed: () {}),
    );
    await tester.pumpAndSettle();
    expect(find.text('GERİ AL'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('GERİ AL'), findsNothing);
    expect(find.text('Zorlayıcıdan güvenliye sıralandı'), findsNothing);
  });

  testWidgets('eylemsiz SnackBar da süresinde kaybolur', (tester) async {
    final ctx = await pumpHost(tester);

    showAppSnackBar(ctx, message: 'Kaydedildi');
    await tester.pumpAndSettle();
    expect(find.text('Kaydedildi'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Kaydedildi'), findsNothing);
  });

  testWidgets('eylem hâlâ çalışır — kaybolması işlevi bozmaz', (tester) async {
    final ctx = await pumpHost(tester);
    var tapped = false;

    showAppSnackBar(
      ctx,
      message: 'Silindi',
      action: SnackBarAction(label: 'GERİ AL', onPressed: () => tapped = true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('GERİ AL'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });
}
