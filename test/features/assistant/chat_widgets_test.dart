import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/assistant/domain/chat_models.dart';
import 'package:uni_app/features/assistant/presentation/widgets/chat_chip_row.dart';
import 'package:uni_app/features/assistant/presentation/widgets/chat_input_bar.dart';
import 'package:uni_app/features/assistant/presentation/widgets/chat_preview_card.dart';
import 'package:uni_app/features/assistant/presentation/widgets/chat_user_bubble.dart';
import 'package:uni_app/features/score_calculator/domain/models/match_result.dart';
import 'package:uni_app/features/university/domain/models/department_model.dart';
import 'package:uni_app/features/university/domain/models/university_model.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

UniversityMatch _match() {
  return UniversityMatch(
    department: DepartmentModel(
      id: 'd1',
      universityId: 'u1',
      name: 'Psikoloji',
      faculty: 'Edebiyat Fakültesi',
      type: 'Lisans',
      language: 'Türkçe',
    ),
    university: UniversityModel(
      id: 'u1',
      cityId: '34',
      name: 'Test Üniversitesi',
      type: 'Devlet',
      hasCampus: true,
      logoUrl: '',
      photoUrl: '',
      description: '',
      establishedYear: 1990,
      website: '',
    ),
    category: MatchCategory.target,
    departmentBaseScore: 420,
    departmentRanking: 85000,
    scoreDifference: 5,
    fitScore: 76,
  );
}

void main() {
  testWidgets('ChatUserBubble metni sağa yaslı gösterir', (tester) async {
    await tester.pumpWidget(_wrap(const ChatUserBubble(text: 'sıralamam 80 bin')));
    expect(find.text('sıralamam 80 bin'), findsOneWidget);
    final align = tester.widget<Align>(
      find.ancestor(
        of: find.text('sıralamam 80 bin'),
        matching: find.byType(Align),
      ).first,
    );
    expect(align.alignment, Alignment.centerRight);
  });

  testWidgets('ChatChipRow tıklanan çipi geri verir', (tester) async {
    ChatChip? tapped;
    const chips = [
      ChatChip('İstanbul', sendText: 'istanbul'),
      ChatChip('Farketmez', command: ChatCommand.skip),
    ];
    await tester.pumpWidget(_wrap(
      ChatChipRow(chips: chips, onTap: (c) => tapped = c),
    ));
    await tester.tap(find.text('Farketmez'));
    expect(tapped?.command, ChatCommand.skip);
  });

  testWidgets('ChatPreviewCard bölüm + üniversite + kategori gösterir',
      (tester) async {
    await tester.pumpWidget(_wrap(ChatPreviewCard(match: _match())));
    expect(find.text('Psikoloji'), findsOneWidget);
    expect(find.text('Test Üniversitesi'), findsOneWidget);
    expect(find.text('Ulaşılabilir'), findsOneWidget);
    expect(find.text('%76 uygun'), findsOneWidget);
    expect(find.text('taban 85.000'), findsOneWidget);
  });

  testWidgets('ChatInputBar gönderir ve alanı temizler', (tester) async {
    String? sent;
    await tester.pumpWidget(_wrap(
      ChatInputBar(enabled: true, onSend: (t) => sent = t),
    ));
    await tester.enterText(find.byType(TextField), 'psikoloji istiyorum');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    expect(sent, 'psikoloji istiyorum');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
  });

  testWidgets('ChatInputBar kilitliyken göndermez', (tester) async {
    String? sent;
    await tester.pumpWidget(_wrap(
      ChatInputBar(enabled: false, onSend: (t) => sent = t),
    ));
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    expect(sent, isNull);
  });
}
