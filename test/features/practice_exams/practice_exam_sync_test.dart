import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/practice_exams/data/practice_exam_sync_service.dart';
import 'package:uni_app/features/practice_exams/domain/models/practice_exam.dart';
import 'package:uni_app/features/score_calculator/domain/models/score_input.dart';

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
  final t1 = DateTime(2026, 5, 10);
  final t2 = DateTime(2026, 5, 20);

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
