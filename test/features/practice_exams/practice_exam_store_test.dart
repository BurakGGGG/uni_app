import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_app/features/practice_exams/data/practice_exam_store.dart';
import 'package:uni_app/features/practice_exams/domain/models/exam_target.dart';
import 'package:uni_app/features/practice_exams/domain/models/practice_exam.dart';
import 'package:uni_app/features/score_calculator/domain/models/score_input.dart';

PracticeExam _exam(
  String id, {
  DateTime? takenAt,
  DateTime? updatedAt,
  bool deleted = false,
  String name = 'Deneme',
}) {
  final when = takenAt ?? DateTime(2026, 5, 10);
  return PracticeExam(
    id: id,
    takenAt: when,
    createdAt: when,
    updatedAt: updatedAt ?? when,
    name: name,
    year: 2026,
    input: const ScoreInput(tytMatCorrect: 20),
    deleted: deleted,
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('round-trip: kaydet ve geri oku', () async {
    final store = PracticeExamStore(prefs);
    await store.save([_exam('1', name: 'İlk Deneme')]);

    final read = PracticeExamStore(prefs).read();
    expect(read, hasLength(1));
    expect(read.first.name, 'İlk Deneme');
    expect(read.first.input.tytMatCorrect, 20);
  });

  test('liste deneme tarihine göre yeniden eskiye sıralanır', () async {
    final store = PracticeExamStore(prefs);
    await store.save([
      _exam('eski', takenAt: DateTime(2026, 3, 1)),
      _exam('yeni', takenAt: DateTime(2026, 6, 1)),
      _exam('orta', takenAt: DateTime(2026, 4, 15)),
    ]);

    expect(store.read().map((e) => e.id), ['yeni', 'orta', 'eski']);
  });

  test('bozuk JSON temizlenir ve boş döner', () async {
    SharedPreferences.setMockInitialValues({'practice_exams_v1': '{bozuk'});
    final broken = await SharedPreferences.getInstance();

    expect(PracticeExamStore(broken).read(), isEmpty);
    expect(broken.getString('practice_exams_v1'), isNull);
  });

  test('200 kayıt tavanı — en eskiler düşer', () async {
    final store = PracticeExamStore(prefs);
    await store.save([
      for (var i = 0; i < 260; i++)
        _exam('$i', takenAt: DateTime(2026, 1, 1).add(Duration(days: i))),
    ]);

    final read = store.read();
    expect(read, hasLength(PracticeExamStore.maxEntries));
    expect(read.first.id, '259'); // en yeni korunur
  });

  test('mezar taşları listeden gizlenir ama senkron için okunabilir', () async {
    final store = PracticeExamStore(prefs);
    await store.save([
      _exam('canlı', takenAt: DateTime(2026, 5, 10)),
      _exam('silinmiş',
          takenAt: DateTime(2026, 5, 9),
          updatedAt: DateTime.now(),
          deleted: true),
    ]);

    expect(store.read().map((e) => e.id), ['canlı']);
    expect(store.readIncludingDeleted().map((e) => e.id),
        containsAll(['canlı', 'silinmiş']));
  });

  test('süresi dolmuş mezar taşı okuma sırasında düşer', () async {
    final store = PracticeExamStore(prefs);
    final old = DateTime.now().subtract(const Duration(days: 45));
    await store.save([
      _exam('eskimis', takenAt: old, updatedAt: old, deleted: true),
      _exam('taze',
          takenAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deleted: true),
    ]);

    final all = store.readIncludingDeleted().map((e) => e.id);
    expect(all, ['taze']);
  });

  group('migrateFromLegacy', () {
    test('calc_history_v1 kayıtları yeni deftere taşınır', () async {
      final legacy = [
        {
          'id': '1',
          'createdAt': '2026-04-02T14:20:00.000',
          'label': 'Deneme 3',
          'year': 2026,
          'input': const ScoreInput(tytMatCorrect: 22).toJson(),
          'results': const <Map<String, dynamic>>[],
        },
      ];
      SharedPreferences.setMockInitialValues(
          {'calc_history_v1': jsonEncode(legacy)});
      final p = await SharedPreferences.getInstance();
      final store = PracticeExamStore(p);

      expect(await store.migrateFromLegacy(), 1);
      expect(store.read().single.name, 'Deneme 3');
      // Eski anahtar bir sürüm boyunca durur (geri dönüş emniyeti).
      expect(p.getString(PracticeExamStore.legacyKey), isNotNull);
    });

    test('yeni defter doluysa migrasyon çalışmaz', () async {
      final store = PracticeExamStore(prefs);
      await store.save([_exam('mevcut', name: 'Mevcut')]);
      await prefs.setString('calc_history_v1', jsonEncode([
        {'id': '1', 'label': 'Eski', 'createdAt': '2026-01-01T00:00:00.000'},
      ]));

      expect(await store.migrateFromLegacy(), 0);
      expect(store.read().single.name, 'Mevcut');
    });

    test('eski anahtar yoksa sessizce 0 döner', () async {
      expect(await PracticeExamStore(prefs).migrateFromLegacy(), 0);
    });

    test('bozuk eski kayıt migrasyonu patlatmaz', () async {
      SharedPreferences.setMockInitialValues({'calc_history_v1': 'bozuk'});
      final p = await SharedPreferences.getInstance();
      expect(await PracticeExamStore(p).migrateFromLegacy(), 0);
    });
  });

  test('hedef kaydedilir, okunur, silinir', () async {
    final store = PracticeExamStore(prefs);
    expect(store.readTarget(), isNull);

    await store.saveTarget(ExamTarget(
      departmentId: 'd1',
      departmentName: 'Tıp',
      universityName: 'Hacettepe Üniversitesi',
      scoreType: 'SAY',
      targetRank: 1836,
      targetScore: 520.4,
      setAt: DateTime(2026, 7, 1),
    ));

    final read = PracticeExamStore(prefs).readTarget();
    expect(read!.departmentName, 'Tıp');
    expect(read.targetRank, 1836);

    await store.clearTarget();
    expect(store.readTarget(), isNull);
  });
}
