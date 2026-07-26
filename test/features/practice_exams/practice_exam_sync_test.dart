import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_app/features/practice_exams/data/practice_exam_repository.dart';
import 'package:uni_app/features/practice_exams/data/practice_exam_store.dart';
import 'package:uni_app/features/practice_exams/data/practice_exam_sync_service.dart';
import 'package:uni_app/features/practice_exams/domain/models/exam_target.dart';
import 'package:uni_app/features/practice_exams/domain/models/practice_exam.dart';
import 'package:uni_app/features/score_calculator/domain/models/score_input.dart';

/// Yapılandırılabilir sahte depo. [uid] her an değiştirilebilir — senkron
/// sırasında hesap değişimini taklit etmek için [onPull] `pullAll` await'i
/// içinde çalışır.
class _FakeRepo implements PracticeExamRepository {
  _FakeRepo({this.remote = const [], this.onPull});

  String? uid = 'A';
  List<PracticeExam> remote;
  final Future<void> Function()? onPull;
  final List<PracticeExam> pushed = [];
  bool upsertAllCalled = false;

  @override
  bool get isSignedIn => uid != null;

  @override
  String? get currentUid => uid;

  @override
  Future<List<PracticeExam>> pullAll() async {
    if (onPull != null) await onPull!();
    return remote;
  }

  @override
  Future<void> upsert(PracticeExam exam) async => pushed.add(exam);

  @override
  Future<void> upsertAll(List<PracticeExam> exams) async {
    upsertAllCalled = true;
    pushed.addAll(exams);
  }

  @override
  Future<void> markDeleted(PracticeExam exam) async {}

  @override
  Future<ExamTarget?> pullTarget() async => null;

  @override
  Future<void> pushTarget(ExamTarget? target) async {}
}

PracticeExam _exam(
  String id, {
  required DateTime updatedAt,
  String name = 'Deneme',
  bool deleted = false,
}) {
  return PracticeExam(
    id: id,
    takenAt: DateTime(2026, 5, 10),
    createdAt: DateTime(2026, 5, 10),
    updatedAt: updatedAt,
    name: name,
    year: 2026,
    input: const ScoreInput(tytMatCorrect: 20),
    deleted: deleted,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final t1 = DateTime(2026, 5, 10);
  final t2 = DateTime(2026, 5, 20);

  group('sync — hesap değişimi', () {
    Future<PracticeExamStore> freshStore() async {
      SharedPreferences.setMockInitialValues({});
      return PracticeExamStore(await SharedPreferences.getInstance());
    }

    test('hesap sabitse yerel + uzak birleşir ve yerel push edilir', () async {
      final store = await freshStore();
      await store.save([_exam('yerel', updatedAt: t2)]);
      final repo = _FakeRepo(remote: [_exam('uzak', updatedAt: t1)]);

      final result =
          await PracticeExamSyncService(store: store, repository: repo).sync();

      expect(result.map((e) => e.id), containsAll(['yerel', 'uzak']));
      expect(repo.pushed.map((e) => e.id), contains('yerel'));
    });

    test('pullAll sırasında hesap değişirse yerel diriltilmez, push atılmaz',
        () async {
      final store = await freshStore();
      // Önceki hesabın (A) kaydı yerelde.
      await store.save([_exam('a1', updatedAt: t1)]);

      late _FakeRepo repo;
      repo = _FakeRepo(
        remote: [_exam('a1', updatedAt: t1)],
        onPull: () async {
          // Ağ beklenirken: A çıktı, resetLocal yereli boşalttı, B girdi.
          await store.clearLocalSession();
          repo.uid = 'B';
        },
      );

      final result =
          await PracticeExamSyncService(store: store, repository: repo).sync();

      // B'nin oturumu boş kaldı — A'nın kaydı geri yazılmadı.
      expect(result, isEmpty);
      expect(store.readIncludingDeleted(), isEmpty);
      // A'nın verisi B'nin yedeğine sızmadı.
      expect(repo.upsertAllCalled, isFalse);
      expect(repo.pushed, isEmpty);
    });

    test('senkron sırasında çıkış yapılırsa (uid null) yerel korunur', () async {
      final store = await freshStore();
      await store.save([_exam('a1', updatedAt: t1)]);

      late _FakeRepo repo;
      repo = _FakeRepo(
        remote: const [],
        onPull: () async => repo.uid = null,
      );

      final result =
          await PracticeExamSyncService(store: store, repository: repo).sync();

      // Yerel olduğu gibi kaldı; guard hiçbir yazma yapmadan döndü.
      expect(result.map((e) => e.id), ['a1']);
      expect(repo.upsertAllCalled, isFalse);
    });
  });

  group('merge', () {
    test('yalnız bir tarafta olan kayıtlar korunur', () {
      final merged = PracticeExamSyncService.merge(
        [_exam('yerel', updatedAt: t1)],
        [_exam('uzak', updatedAt: t1)],
      );
      expect(merged.map((e) => e.id), containsAll(['yerel', 'uzak']));
      expect(merged, hasLength(2));
    });

    test('çakışmada updatedAt yenisi kazanır', () {
      final merged = PracticeExamSyncService.merge(
        [_exam('1', updatedAt: t1, name: 'Eski ad')],
        [_exam('1', updatedAt: t2, name: 'Yeni ad')],
      );
      expect(merged.single.name, 'Yeni ad');
    });

    test('yerel daha yeniyse uzaktaki üzerine yazamaz', () {
      final merged = PracticeExamSyncService.merge(
        [_exam('1', updatedAt: t2, name: 'Yerel yeni')],
        [_exam('1', updatedAt: t1, name: 'Uzak eski')],
      );
      expect(merged.single.name, 'Yerel yeni');
    });

    test('uzaktaki mezar taşı yerel kaydı siler', () {
      final merged = PracticeExamSyncService.merge(
        [_exam('1', updatedAt: t1)],
        [_exam('1', updatedAt: t2, deleted: true)],
      );
      expect(merged.single.deleted, isTrue);
    });

    test('id boş kayıtlar atlanır', () {
      final merged = PracticeExamSyncService.merge(
        [_exam('', updatedAt: t1)],
        [_exam('', updatedAt: t2)],
      );
      expect(merged, isEmpty);
    });
  });

  group('toPush', () {
    test('uzakta olmayan yerel kayıtlar gönderilir', () {
      final push = PracticeExamSyncService.toPush(
        [_exam('1', updatedAt: t1), _exam('2', updatedAt: t1)],
        [_exam('1', updatedAt: t1)],
      );
      expect(push.map((e) => e.id), ['2']);
    });

    test('yerel daha yeniyse gönderilir', () {
      final push = PracticeExamSyncService.toPush(
        [_exam('1', updatedAt: t2)],
        [_exam('1', updatedAt: t1)],
      );
      expect(push, hasLength(1));
    });

    test('uzak daha yeniyse gönderilmez', () {
      final push = PracticeExamSyncService.toPush(
        [_exam('1', updatedAt: t1)],
        [_exam('1', updatedAt: t2)],
      );
      expect(push, isEmpty);
    });

    test('misafirken girilen tüm kayıtlar giriş sonrası yüklenir', () {
      // Uzak taraf boş → hepsi push edilmeli (ayrı migrasyon yolu yok).
      final local = [
        _exam('1', updatedAt: t1),
        _exam('2', updatedAt: t1),
        _exam('3', updatedAt: t2),
      ];
      expect(PracticeExamSyncService.toPush(local, const []), hasLength(3));
    });
  });
}
