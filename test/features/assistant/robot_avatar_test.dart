import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/assistant/domain/robot_mood.dart';
import 'package:uni_app/features/assistant/presentation/widgets/robot_avatar.dart';

void main() {
  testWidgets('tüm mood × boyut × tema kombinasyonları hatasız çizilir',
      (tester) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      for (final mood in RobotMood.values) {
        for (final size in [20.0, 48.0, 96.0]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: Scaffold(
                body: Center(
                  child: RobotAvatar(
                    size: size,
                    mood: mood,
                    animated: false,
                  ),
                ),
              ),
            ),
          );
          expect(find.byType(RobotAvatar), findsOneWidget,
              reason: '$brightness $mood $size');
          expect(tester.takeException(), isNull,
              reason: '$brightness $mood $size');
        }
      }
    }
  });

  testWidgets('animated avatar kare atlatmadan çizer ve temiz kapanır',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: RobotAvatar(size: 56, mood: RobotMood.celebrating),
          ),
        ),
      ),
    );
    // Süzülme + kırpma zamanlayıcıları çalışırken birkaç kare ilerlet.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);

    // Widget sökülünce controller/timer'lar temizlenmeli (pending timer
    // hatası bu testi kırar).
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('erişilebilirlik: animasyonlar kapalıyken ticker kurulmaz',
      (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: RobotAvatar(size: 56)),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });
}
