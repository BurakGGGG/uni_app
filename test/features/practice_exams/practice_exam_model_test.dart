import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/practice_exams/domain/models/practice_exam.dart';
import 'package:uni_app/features/score_calculator/domain/models/score_input.dart';
import 'package:uni_app/features/score_calculator/domain/models/yks_subject.dart';

void main() {
  final exam = PracticeExam(
    id: '1700000000000',
    takenAt: DateTime(2026, 5, 10),
    createdAt: DateTime(2026, 5, 11, 9, 30),
    updatedAt: DateTime(2026, 5, 12, 8),
    name: 'TYT Deneme 5',
    publisher: '3D Yayınları',
    kind: PracticeExamKind.tyt,
    year: 2026,
    input: const ScoreInput(tytTurkceCorrect: 30, tytTurkceWrong: 4),
    results: const [
      TypeScoreSnapshot(
        scoreType: 'TYT',
        rawScore: 300,
        placementScore: 348,
        estimatedRank: 120000,
        percentile: 9.3,
      ),
    ],
    note: 'Paragrafta zorlandım',
  );

  test('toJson/fromJson round-trip tüm alanları korur', () {
    final decoded =
        PracticeExam.fromJson(jsonDecode(jsonEncode(exam.toJson())));

    expect(decoded.id, exam.id);
    expect(decoded.takenAt, exam.takenAt);
    expect(decoded.createdAt, exam.createdAt);
    expect(decoded.updatedAt, exam.updatedAt);
    expect(decoded.name, 'TYT Deneme 5');
    expect(decoded.publisher, '3D Yayınları');
    expect(decoded.kind, PracticeExamKind.tyt);
    expect(decoded.note, 'Paragrafta zorlandım');
    expect(decoded.deleted, isFalse);
    expect(decoded.input.tytTurkceCorrect, 30);
    expect(decoded.results.single.estimatedRank, 120000);
    expect(decoded.results.single.percentile, 9.3);
  });

  test('fromLegacyJson eski calc_history_v1 kaydını kayıpsız taşır', () {
    // v3'ün gerçek kayıt biçimi: label + createdAt, tarih/yayın/tür yok.
    final legacy = {
      'id': '1690000000000',
      'createdAt': '2026-04-02T14:20:00.000',
      'label': 'Deneme 3',
      'year': 2026,
      'input': const ScoreInput(tytMatCorrect: 22, tytMatWrong: 4).toJson(),
      'results': [
        const TypeScoreSnapshot(
          scoreType: 'SAY',
          rawScore: 370,
          placementScore: 418.6,
          estimatedRank: 85000,
        ).toJson(),
      ],
    };

    final migrated = PracticeExam.fromLegacyJson(legacy);

    expect(migrated.id, '1690000000000');
    expect(migrated.name, 'Deneme 3');
    // Eski kayıtta deneme tarihi yoktu; kaydedildiği an deneme tarihi sayılır.
    expect(migrated.takenAt, DateTime(2026, 4, 2, 14, 20));
    expect(migrated.createdAt, migrated.takenAt);
    expect(migrated.updatedAt, migrated.takenAt);
    expect(migrated.publisher, isEmpty);
    expect(migrated.kind, PracticeExamKind.genel);
    expect(migrated.input.tytMatCorrect, 22);
    expect(migrated.results.single.placementScore, 418.6);
  });

  test('fromLegacyJson id boşsa createdAt üzerinden id üretir', () {
    final migrated = PracticeExam.fromLegacyJson({
      'id': '',
      'createdAt': '2026-04-02T14:20:00.000',
      'label': 'Deneme',
    });
    expect(migrated.id,
        DateTime(2026, 4, 2, 14, 20).millisecondsSinceEpoch.toString());
  });

  test('hasNets giriş moduna göre belirlenir', () {
    expect(exam.hasNets, isTrue);
    final rankExam = exam.copyWith(
      input: const ScoreInput(
        entryMode: NetEntryMode.rank,
        scoreType: 'SAY',
        enteredRank: 45000,
      ),
    );
    expect(rankExam.hasNets, isFalse);
    expect(rankExam.isRankMode, isTrue);

    final scoreExam = exam.copyWith(
      input: const ScoreInput(
        entryMode: NetEntryMode.score,
        scoreType: 'SAY',
        enteredScore: 451.1,
      ),
    );
    expect(scoreExam.hasNets, isFalse);
    expect(scoreExam.isRankMode, isFalse);
  });

  test('rankProgressOver pozitifse sıra ilerlemiş demektir', () {
    final older = exam.copyWith(results: [
      const TypeScoreSnapshot(
        scoreType: 'TYT',
        rawScore: 280,
        placementScore: 328,
        estimatedRank: 150000,
      ),
    ]);
    expect(exam.rankProgressOver(older), 30000);
    expect(older.rankProgressOver(exam), -30000);
  });

  test('kind.subjects deneme kapsamını verir', () {
    expect(PracticeExamKind.tyt.subjects,
        YksSubject.bySection(YksSection.tyt));
    expect(PracticeExamKind.tyt.subjects, isNot(contains(YksSubject.aytMat)));
    expect(PracticeExamKind.ayt.subjects, contains(YksSubject.aytMat));
    expect(PracticeExamKind.ayt.subjects,
        isNot(contains(YksSubject.tytTurkce)));
    expect(PracticeExamKind.ydt.subjects, [YksSubject.ydt]);
    expect(PracticeExamKind.genel.subjects, YksSubject.values);
  });

  test('copyWith updatedAt vermezse "şimdi"ye çeker (senkron için)', () {
    final before = DateTime.now();
    final renamed = exam.copyWith(name: 'Yeni ad');
    expect(renamed.name, 'Yeni ad');
    expect(renamed.updatedAt.isBefore(before), isFalse);
    expect(renamed.createdAt, exam.createdAt); // createdAt değişmez
  });
}
