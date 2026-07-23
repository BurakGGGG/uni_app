import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_app/core/providers/shared_preferences_provider.dart';
import 'package:uni_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:uni_app/features/practice_exams/data/practice_exam_repository.dart';
import 'package:uni_app/features/practice_exams/data/practice_exam_store.dart';
import 'package:uni_app/features/practice_exams/domain/models/exam_target.dart';
import 'package:uni_app/features/practice_exams/domain/models/practice_exam.dart';
import 'package:uni_app/features/practice_exams/presentation/providers/practice_exam_providers.dart';
import 'package:uni_app/features/practice_exams/presentation/screens/practice_exams_screen.dart';
import 'package:uni_app/features/practice_exams/presentation/widgets/practice_exam_summary_card.dart';
import 'package:uni_app/features/score_calculator/domain/models/score_input.dart';

/// Firestore'a hiç gitmeyen sahte depo — testlerde Firebase başlatılmıyor.
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

PracticeExam _exam(
  String id, {
  required DateTime takenAt,
  String name = 'Deneme',
  int? rank,
  PracticeExamKind kind = PracticeExamKind.tyt,
  ScoreInput? input,
}) {
  return PracticeExam(
    id: id,
    takenAt: takenAt,
    createdAt: takenAt,
    updatedAt: takenAt,
    name: name,
    publisher: '3D Yayınları',
    kind: kind,
    year: 2026,
    input: input ?? const ScoreInput(tytTurkceCorrect: 30, tytMatCorrect: 25),
    results: [
      TypeScoreSnapshot(
        scoreType: 'TYT',
        rawScore: 300,
        placementScore: 348,
        estimatedRank: rank,
      ),
    ],
  );
}

void main() {
  late SharedPreferences prefs;
  late _FakeRepository repository;

  Future<void> seed(List<PracticeExam> exams) async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    if (exams.isNotEmpty) await PracticeExamStore(prefs).save(exams);
    repository = _FakeRepository();
  }

  List<Override> overrides() => [
        sharedPreferencesProvider.overrideWithValue(prefs),
        practiceExamRepositoryProvider.overrideWithValue(repository),
        // Auth akışı Firebase'e bağlı; testte misafir kullanıcı taklidi.
        authStateProvider.overrideWith((ref) => Stream.value(null)),
      ];

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: const MaterialApp(home: PracticeExamsScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('kayıt yokken boş durum ve CTA görünür', (tester) async {
    await seed(const []);
    await pumpScreen(tester);

    expect(find.text('Henüz kayıtlı deneme yok'), findsOneWidget);
    expect(find.text('İlk Denemeni Ekle'), findsOneWidget);
  });

  testWidgets('kayıtlar, yayın adı ve tür rozeti listelenir', (tester) async {
    await seed([
      _exam('2',
          takenAt: DateTime(2026, 7, 21), name: 'Deneme 2', rank: 60000),
      _exam('1',
          takenAt: DateTime(2026, 7, 14), name: 'Deneme 1', rank: 90000),
    ]);
    await pumpScreen(tester);

    expect(find.text('Deneme 2'), findsOneWidget);
    expect(find.text('Deneme 1'), findsOneWidget);
    expect(find.textContaining('3D Yayınları'), findsWidgets);
    expect(find.text('Denemelerin (2)'), findsOneWidget);
    // Sıra 90.000 → 60.000: 30.000 basamak ilerleme.
    expect(find.textContaining('sıra ilerledin'), findsOneWidget);
  });

  testWidgets('haftalık seri şeridi hesaplanır', (tester) async {
    final now = DateTime.now();
    await seed([
      _exam('2', takenAt: now, name: 'Bu hafta'),
      _exam('1',
          takenAt: now.subtract(const Duration(days: 7)), name: 'Geçen hafta'),
    ]);
    await pumpScreen(tester);

    expect(find.text('2'), findsWidgets); // 2 deneme ve 2 hafta seri
    expect(find.textContaining('hafta seri'), findsOneWidget);
  });

  testWidgets('hedef yokken hedef belirleme daveti çıkar', (tester) async {
    await seed([_exam('1', takenAt: DateTime(2026, 7, 21))]);
    await pumpScreen(tester);

    expect(find.text('Hedef Belirle'), findsOneWidget);
  });

  testWidgets('netsiz kayıtta ders analizi yönlendirme gösterir',
      (tester) async {
    await seed([
      _exam(
        '1',
        takenAt: DateTime(2026, 7, 21),
        input: const ScoreInput(
          entryMode: NetEntryMode.rank,
          scoreType: 'TYT',
          enteredRank: 120000,
        ),
      ),
    ]);
    await pumpScreen(tester);

    expect(find.textContaining('Ders analizi için netlerini gir'),
        findsOneWidget);
  });

  testWidgets('gelişim grafiği hangi yılın verisiyle çizildiğini yazar',
      (tester) async {
    await seed([
      _exam('2',
          takenAt: DateTime(2026, 7, 21), name: 'Deneme 2', rank: 60000),
      _exam('1',
          takenAt: DateTime(2026, 7, 14), name: 'Deneme 1', rank: 90000),
    ]);
    await pumpScreen(tester);

    // Kayıtlar 2026'ya ait; o yılın tablosu henüz yok, 2025'e düşülür.
    expect(find.textContaining('2026 tablosu henüz yayımlanmadı'),
        findsOneWidget);
    expect(find.textContaining('2025 yerleştirme verisine göre'),
        findsOneWidget);
  });

  testWidgets('grafiğin veri yılı değiştirilebilir', (tester) async {
    await seed([
      _exam('2',
          takenAt: DateTime(2026, 7, 21), name: 'Deneme 2', rank: 60000),
      _exam('1',
          takenAt: DateTime(2026, 7, 14), name: 'Deneme 1', rank: 90000),
    ]);
    await pumpScreen(tester);

    await tester.tap(find.byType(PopupMenuButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2023 verisi').last);
    await tester.pumpAndSettle();

    expect(find.text('Puan ve sıralar 2023 yerleştirme verisine göre.'),
        findsOneWidget);
  });

  testWidgets('misafire yedekleme bilgisi gösterilir', (tester) async {
    await seed([_exam('1', takenAt: DateTime(2026, 7, 21))]);
    await pumpScreen(tester);

    expect(find.textContaining('Giriş yaparsan'), findsOneWidget);
  });

  group('PracticeExamSummaryCard', () {
    Future<void> pumpCard(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: const MaterialApp(
            home: Scaffold(body: PracticeExamSummaryCard()),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('kayıt yokken davet metni', (tester) async {
      await seed(const []);
      await pumpCard(tester);

      expect(find.text('Denemelerim'), findsOneWidget);
      expect(find.textContaining('gelişimini buradan takip et'),
          findsOneWidget);
    });

    testWidgets('son deneme özetini ve tür rozetini gösterir', (tester) async {
      await seed([
        _exam('2',
            takenAt: DateTime(2026, 7, 21), name: 'Son Deneme', rank: 60000),
        _exam('1',
            takenAt: DateTime(2026, 7, 14), name: 'Eski Deneme', rank: 90000),
      ]);
      await pumpCard(tester);

      expect(find.text('Son Deneme'), findsOneWidget);
      expect(find.text('21.07.2026'), findsOneWidget);
      expect(find.textContaining('TYT 348,0'), findsOneWidget);
      // Eski deneme kartta yer almaz — yalnız en son kayıt.
      expect(find.text('Eski Deneme'), findsNothing);
    });
  });
}
