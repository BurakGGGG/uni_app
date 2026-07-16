import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/reviews/domain/models/review_model.dart';
import 'package:uni_app/features/reviews/presentation/widgets/review_actions_menu.dart';

void main() {
  testWidgets('delete confirmation renders and invokes the delete callback', (
    tester,
  ) async {
    var deleteCalled = false;
    final now = DateTime(2026, 7, 1);
    final review = ReviewModel(
      id: 'review-1',
      type: ReviewType.university,
      targetId: 'university-1',
      universityId: 'university-1',
      userId: 'user-1',
      userName: 'Test User',
      rating: 4,
      comment: 'Bu test için yeterince uzun bir yorum metnidir.',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ReviewActionsMenu(
              review: review,
              showOwnerActions: true,
              showReportAction: false,
              onEdit: () {},
              onDelete: () async {
                deleteCalled = true;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yorumu Sil'));
    await tester.pumpAndSettle();

    expect(find.text('Evet, Sil'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Evet, Sil'));
    await tester.pumpAndSettle();

    expect(deleteCalled, isTrue);
    expect(tester.takeException(), isNull);
  });
}
