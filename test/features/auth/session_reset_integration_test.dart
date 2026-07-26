import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_app/core/providers/shared_preferences_provider.dart';
import 'package:uni_app/features/assistant/presentation/providers/assistant_providers.dart';
import 'package:uni_app/features/home/presentation/providers/recent_searches_provider.dart';
import 'package:uni_app/features/practice_exams/data/practice_exam_repository.dart';
import 'package:uni_app/features/practice_exams/domain/models/exam_target.dart';
import 'package:uni_app/features/practice_exams/domain/models/practice_exam.dart';
import 'package:uni_app/features/practice_exams/presentation/providers/practice_exam_providers.dart';
import 'package:uni_app/features/preference_wizard/domain/models/student_score_profile.dart';
import 'package:uni_app/features/preference_wizard/domain/models/wizard_prefs.dart';
import 'package:uni_app/features/preference_wizard/presentation/providers/preference_wizard_providers.dart';
import 'package:uni_app/features/score_calculator/domain/models/score_input.dart';

/// Firestore'a hiç gitmeyen sahte depo — reset yolu uzağa DOKUNMAMALI, bu
/// yüzden buradaki [pushed]/[deleted] listeleri boş kalmalı.
class _FakeRepository implements PracticeExamRepository {
  final List<PracticeExam> pushed = [];
  final List<PracticeExam> deleted = [];

  @override
  bool get isSignedIn => false;

  @override
  String? get currentUid => null;

  @override
  Future<List<PracticeExam>> pullAll() async => const [];

  @override
  Future<void> upsert(PracticeExam exam) async => pushed.add(exam);

  @override
  Future<void> upsertAll(List<PracticeExam> exams) async =>
      pushed.addAll(exams);

  @override
  Future<void> markDeleted(PracticeExam exam) async => deleted.add(exam);

  @override
  Future<ExamTarget?> pullTarget() async => null;

  @override
  Future<void> pushTarget(ExamTarget? target) async {}
}

/// [SessionReset._clearLocalUserData]'nın çağırdığı ile birebir aynı zincir.
/// Test hedefli değil, gerçek kullanım yolu: hesap değişiminde çalışan reset.
Future<void> _runReset(ProviderContainer c) async {
  await c.read(studentScoreProfileProvider.notifier).clear();
  await c.read(wizardPrefsProvider.notifier).reset();
  await c.read(practiceExamsProvider.notifier).resetLocal();
  c.read(examTargetProvider.notifier).resetLocal();
  await c.read(robotMemoryProvider).clear();
  await c.read(recentSearchesProvider.notifier).clear();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeRepository repo;

  Future<ProviderContainer> makeContainer() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = _FakeRepository();
    return ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      practiceExamRepositoryProvider.overrideWithValue(repo),
    ]);
  }

  test('reset — cihaz-yerel kullanıcı verisi tamamen düşer', () async {
    final c = await makeContainer();
    addTearDown(c.dispose);

    // Önceki hesabın izleri yerele yazılır.
    await c.read(studentScoreProfileProvider.notifier).save(
          StudentScoreProfile(
            scoreType: 'SAY',
            placementScore: 430.5,
            year: 2026,
            updatedAt: DateTime(2026, 7, 1),
          ),
        );
    await c
        .read(wizardPrefsProvider.notifier)
        .save(const WizardPrefs(cityIds: {'06'}));
    await c.read(practiceExamsProvider.notifier).add(
          PracticeExam(
            id: 'e1',
            takenAt: DateTime(2026, 5, 10),
            createdAt: DateTime(2026, 5, 10),
            updatedAt: DateTime(2026, 5, 10),
            name: 'Deneme',
            year: 2026,
            input: const ScoreInput(tytMatCorrect: 20),
          ),
        );
    await c.read(examTargetProvider.notifier).setTarget(ExamTarget(
          departmentId: 'd1',
          departmentName: 'Tıp',
          universityName: 'Hacettepe',
          scoreType: 'SAY',
          targetRank: 1836,
          setAt: DateTime(2026, 7, 1),
        ));
    await c.read(robotMemoryProvider).setDisplayName('Ada');
    await c.read(recentSearchesProvider.notifier).add('Boğaziçi Tıp');

    // Hepsi gerçekten yazıldı.
    expect(c.read(studentScoreProfileProvider), isNotNull);
    expect(c.read(practiceExamsProvider), hasLength(1));
    expect(c.read(examTargetProvider), isNotNull);
    expect(c.read(recentSearchesProvider), isNotEmpty);

    await _runReset(c);

    // Bellekteki durum anında sıfır.
    expect(c.read(studentScoreProfileProvider), isNull);
    expect(c.read(wizardPrefsProvider).cityIds, isEmpty);
    expect(c.read(practiceExamsProvider), isEmpty);
    expect(c.read(examTargetProvider), isNull);
    expect(c.read(robotMemoryProvider).displayName, isNull);
    expect(c.read(recentSearchesProvider), isEmpty);

    // Reset Firestore'a DOKUNMADI — silme/push yayılmadı (uzak yedek korunur).
    expect(repo.deleted, isEmpty);
    expect(repo.pushed, hasLength(1)); // yalnız ilk add(); resetLocal push atmaz
  });

  test('reset sonrası taze store da boş okur (kalıcılık)', () async {
    final c = await makeContainer();
    addTearDown(c.dispose);

    await c.read(practiceExamsProvider.notifier).add(
          PracticeExam(
            id: 'e1',
            takenAt: DateTime(2026, 5, 10),
            createdAt: DateTime(2026, 5, 10),
            updatedAt: DateTime(2026, 5, 10),
            name: 'Deneme',
            year: 2026,
            input: const ScoreInput(tytMatCorrect: 20),
          ),
        );

    await _runReset(c);

    // Yeni bir container aynı prefs'ten kurulsa da (uygulama yeniden açılışı)
    // eski kayıt geri gelmemeli — legacy anahtar da temizlendi.
    final reopened = ProviderContainer(overrides: [
      sharedPreferencesProvider
          .overrideWithValue(await SharedPreferences.getInstance()),
      practiceExamRepositoryProvider.overrideWithValue(_FakeRepository()),
    ]);
    addTearDown(reopened.dispose);
    expect(reopened.read(practiceExamsProvider), isEmpty);
    expect(reopened.read(studentScoreProfileProvider), isNull);
  });
}
