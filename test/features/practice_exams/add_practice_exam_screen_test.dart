import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_app/core/providers/shared_preferences_provider.dart';
import 'package:uni_app/features/practice_exams/data/practice_exam_repository.dart';
import 'package:uni_app/features/practice_exams/data/practice_exam_store.dart';
import 'package:uni_app/features/practice_exams/domain/models/exam_target.dart';
import 'package:uni_app/features/practice_exams/domain/models/practice_exam.dart';
import 'package:uni_app/features/practice_exams/presentation/providers/practice_exam_providers.dart';
import 'package:uni_app/features/practice_exams/presentation/screens/add_practice_exam_screen.dart';
import 'package:uni_app/features/preference_wizard/domain/rank_estimator.dart';
import 'package:uni_app/features/preference_wizard/presentation/providers/preference_wizard_providers.dart';
import 'package:uni_app/features/score_calculator/domain/models/score_input.dart';
import 'package:uni_app/features/score_calculator/presentation/widgets/subject_score_input.dart';

class _FakeRepository implements PracticeExamRepository {
  final List<PracticeExam> pushed = [];

  @override
  bool get isSignedIn => false;

  @override
  Future<List<PracticeExam>> pullAll() async => const [];

  @override
  Future<void> upsert(PracticeExam exam) async => pushed.add(exam);

  @override
  Future<void> upsertAll(List<PracticeExam> exams) async =>
      pushed.addAll(exams);

  @override
  Future<void> markDeleted(PracticeExam exam) async =>
      pushed.add(exam.copyWith(deleted: true));

  @override
  Future<ExamTarget?> pullTarget() async => null;

  @override
  Future<void> pushTarget(ExamTarget? target) async {}
}

void main() {
  late ProviderContainer container;

  /// Ekran bir alt rotanın üstüne itilir — kaydettikten sonra `Navigator.pop`
  /// çalışabilsin diye altında bir rota olmalı.
  Future<void> pump(WidgetTester tester, {PracticeExam? existing}) async {
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // Düzenlenen kayıt defterde zaten duruyor olmalı.
    if (existing != null) await PracticeExamStore(prefs).save([existing]);

    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      practiceExamRepositoryProvider.overrideWithValue(_FakeRepository()),
      // Resmî ÖSYM tabloları beş türü de kapsıyor; tahmin motoru yalnız
      // yedek olduğundan boş estimator yeterli (Firestore'a gitmez).
      multiYearRankEstimatorProvider.overrideWith(
          (ref) async => MultiYearRankEstimator.fromDepartments(const [])),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => AddPracticeExamScreen(existing: existing),
                  ),
                ),
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
  }

  Finder subjectField(String title) => find
      .descendant(
        of: find.widgetWithText(SubjectScoreInput, title),
        matching: find.byType(TextFormField),
      )
      .first;

  testWidgets('ad, tarih ve tür ekranın kendisinde sorulur', (tester) async {
    await pump(tester);

    expect(find.text('Deneme Ekle'), findsOneWidget);
    expect(find.text('Deneme Bilgileri'), findsOneWidget);
    expect(find.text('Deneme 1'), findsOneWidget); // varsayılan ad
    expect(find.textContaining('Deneme tarihi:'), findsOneWidget);
    for (final kind in PracticeExamKind.values) {
      expect(find.widgetWithText(ChoiceChip, kind.labelTr), findsOneWidget);
    }
  });

  testWidgets('deneme türü ders kapsamını belirler', (tester) async {
    await pump(tester);

    // Varsayılan TYT: yalnız TYT dersleri.
    expect(find.widgetWithText(SubjectScoreInput, 'Türkçe'), findsOneWidget);
    expect(find.widgetWithText(SubjectScoreInput, 'Fizik'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Genel'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(SubjectScoreInput, 'Fizik'), findsOneWidget);
    expect(find.widgetWithText(SubjectScoreInput, 'Türkçe'), findsOneWidget);
  });

  testWidgets('TYT neti olmayan türlerde puan hesaplanamaz uyarısı çıkar',
      (tester) async {
    await pump(tester);
    expect(find.textContaining('TYT neti olmadan'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'AYT'));
    await tester.pumpAndSettle();

    expect(find.textContaining('TYT neti olmadan'), findsOneWidget);
  });

  testWidgets('net girilmeden kaydetme kapalı', (tester) async {
    await pump(tester);

    expect(find.text('En az bir dersin netini gir'), findsOneWidget);
    expect(container.read(practiceExamsProvider), isEmpty);
  });

  testWidgets('kaydedince defterde ad, tür ve netlerle görünür',
      (tester) async {
    await pump(tester);

    await tester.enterText(subjectField('Türkçe'), '30');
    await tester.pump();
    expect(find.text('Hesaplanacak: TYT'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Deneme 1'),
        'Limit Deneme 3');
    await tester.pump();

    await tester.tap(find.text('Denemeyi Kaydet'));
    await tester.pumpAndSettle();

    final exams = container.read(practiceExamsProvider);
    expect(exams, hasLength(1));
    expect(exams.single.name, 'Limit Deneme 3');
    expect(exams.single.kind, PracticeExamKind.tyt);
    expect(exams.single.input.tytTurkceCorrect, 30);
    expect(exams.single.byType('TYT'), isNotNull);
    // Kaydettikten sonra ekran kapanır.
    expect(find.text('Deneme Ekle'), findsNothing);
  });

  testWidgets('kapsam dışı dersler kayda girmez', (tester) async {
    await pump(tester);

    // Önce Genel'de AYT neti gir, sonra türü TYT'ye çevir.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Genel'));
    await tester.pumpAndSettle();
    await tester.enterText(subjectField('Türkçe'), '30');
    await tester.enterText(subjectField('Fizik'), '10');
    await tester.pump();

    await tester.tap(find.widgetWithText(ChoiceChip, 'TYT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Denemeyi Kaydet'));
    await tester.pumpAndSettle();

    final exam = container.read(practiceExamsProvider).single;
    expect(exam.input.tytTurkceCorrect, 30);
    expect(exam.input.aytFizikCorrect, 0);
  });

  testWidgets('sıralama modunda yıl ve tür seçilir, netler gizlenir',
      (tester) async {
    await pump(tester);

    await tester.tap(find.text('Sıralama'));
    await tester.pumpAndSettle();

    expect(find.text('Başarı Sıralaman'), findsOneWidget);
    expect(find.widgetWithText(SubjectScoreInput, 'Türkçe'), findsNothing);
    expect(find.text('Hangi yılın sıralaması?'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '2022'), findsOneWidget);
    expect(find.text('Puan türünü seç ve sıranı gir'), findsOneWidget);
  });

  testWidgets('düzenleme modu var olan kaydı değiştirir', (tester) async {
    final existing = PracticeExam(
      id: '1',
      takenAt: DateTime(2026, 7, 1),
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
      name: 'Eski Ad',
      kind: PracticeExamKind.tyt,
      year: 2026,
      input: const ScoreInput(obpScore: 80, tytTurkceCorrect: 20),
    );
    await pump(tester, existing: existing);

    expect(find.text('Denemeyi Düzenle'), findsOneWidget);
    expect(find.text('Eski Ad'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextField, 'Eski Ad'), 'Yeni Ad');
    await tester.pump();
    await tester.tap(find.text('Değişiklikleri Kaydet'));
    await tester.pumpAndSettle();

    final exams = container.read(practiceExamsProvider);
    // Yeni kayıt açılmaz; var olan güncellenir.
    expect(exams, hasLength(1));
    expect(exams.single.id, '1');
    expect(exams.single.name, 'Yeni Ad');
  });
}
