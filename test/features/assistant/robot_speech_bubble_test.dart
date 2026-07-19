import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/assistant/domain/robot_message.dart';
import 'package:uni_app/features/assistant/domain/robot_mood.dart';
import 'package:uni_app/features/assistant/presentation/widgets/robot_speech_bubble.dart';

void main() {
  const msgA = RobotMessage(
    'test.a',
    'Merhaba ben Üni seninle çalışmaya hazırım',
    RobotMood.happy,
  );
  const msgB = RobotMessage(
    'test.b',
    'Yeni bir mesaj geldi baştan yazıyorum',
    RobotMood.thinking,
  );

  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: child));

  testWidgets('typewriter metni tamamlar', (tester) async {
    await tester.pumpWidget(wrap(const RobotSpeechBubble(message: msgA)));
    // 6 kelime × 55ms — fazlasıyla bekle.
    await tester.pump(const Duration(seconds: 2));
    expect(find.text(msgA.text), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mesaj değişince typewriter baştan başlar', (tester) async {
    await tester.pumpWidget(wrap(const RobotSpeechBubble(message: msgA)));
    await tester.pump(const Duration(seconds: 2));

    await tester.pumpWidget(wrap(const RobotSpeechBubble(message: msgB)));
    await tester.pump(const Duration(milliseconds: 60));
    // Henüz tamamlanmamış olmalı (baştan yazıyor).
    expect(find.text(msgB.text), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text(msgB.text), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('typewriter kapalıyken metin anında görünür', (tester) async {
    await tester.pumpWidget(
      wrap(const RobotSpeechBubble(message: msgA, typewriter: false)),
    );
    expect(find.text(msgA.text), findsOneWidget);
  });
}
