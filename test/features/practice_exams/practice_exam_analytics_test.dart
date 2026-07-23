import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/practice_exams/domain/models/practice_exam.dart';
import 'package:uni_app/features/practice_exams/domain/practice_exam_analytics.dart';
import 'package:uni_app/features/score_calculator/domain/models/score_input.dart';
import 'package:uni_app/features/score_calculator/domain/models/yks_subject.dart';

PracticeExam _exam({
  required String id,
  required DateTime takenAt,
  PracticeExamKind kind = PracticeExamKind.genel,
  ScoreInput input = const ScoreInput(),
  List<TypeScoreSnapshot> results = const [],
  bool deleted = false,
}) {
  return PracticeExam(
    id: id,
    takenAt: takenAt,
    createdAt: takenAt,
    updatedAt: takenAt,
    name: 'Deneme $id',
    kind: kind,
    year: 2026,
    input: input,
    results: results,
    deleted: deleted,
  );
}

TypeScoreSnapshot _say(double score, int rank) => TypeScoreSnapshot(
      scoreType: 'SAY',
      rawScore: score - 48,
      placementScore: score,
      estimatedRank: rank,
    );

void main() {
  group('trendFor', () {
    test('eskiden yeniye sıralar ve türü olmayan kayıtları atlar', () {
      final exams = [
        _exam(
          id: 'b',
          takenAt: DateTime(2026, 6, 1),
          results: [_say(430, 65000)],
        ),
        _exam(
          id: 'tyt',
          takenAt: DateTime(2026, 5, 20),
          results: const [
            TypeScoreSnapshot(
                scoreType: 'TYT', rawScore: 300, placementScore: 348),
          ],
        ),
        _exam(
          id: 'a',
          takenAt: DateTime(2026, 4, 1),
          results: [_say(400, 110000)],
        ),
      ];

      final points = trendFor(exams, 'SAY');
      expect(points.map((p) => p.examId), ['a', 'b']);
      expect(points.first.rank, 110000);
      expect(points.last.placementScore, 430);
    });

    test('silinmiş kayıt grafiğe girmez', () {
      final points = trendFor([
        _exam(
            id: '1',
            takenAt: DateTime(2026, 4, 1),
            results: [_say(400, 110000)],
            deleted: true),
      ], 'SAY');
      expect(points, isEmpty);
    });

    test('tür verilmezse kaydın en iyi türü kullanılır', () {
      final points = trendFor([
        _exam(
          id: '1',
          takenAt: DateTime(2026, 4, 1),
          results: [
            _say(400, 110000),
            const TypeScoreSnapshot(
                scoreType: 'EA',
                rawScore: 330,
                placementScore: 378,
                estimatedRank: 200000),
          ],
        ),
      ], '');
      expect(points.single.rank, 110000); // SAY daha iyi sıra
    });
  });

  group('subjectStats', () {
    ScoreInput tytNets({int turkce = 30, int mat = 20}) =>
        ScoreInput(tytTurkceCorrect: turkce, tytMatCorrect: mat);

    test('başarı oranına göre sıralar — soru sayısı normalize edilir', () {
      // Türkçe 30/40 = %75, Temel Mat 36/40 = %90 → Mat önde olmalı.
      final stats = subjectStats([
        _exam(
          id: '1',
          takenAt: DateTime(2026, 5, 1),
          kind: PracticeExamKind.tyt,
          input: tytNets(turkce: 30, mat: 36),
        ),
      ]);

      expect(stats.first.subject, YksSubject.tytMat);
      expect(stats.first.successRate, closeTo(0.9, 0.001));
      expect(stats.map((s) => s.subject), contains(YksSubject.tytTurkce));
    });

    test('TYT denemesi AYT derslerini kirletmez', () {
      final stats = subjectStats([
        _exam(
          id: 'tyt',
          takenAt: DateTime(2026, 5, 10),
          kind: PracticeExamKind.tyt,
          input: tytNets(),
        ),
        _exam(
          id: 'genel',
          takenAt: DateTime(2026, 5, 1),
          kind: PracticeExamKind.genel,
          input: const ScoreInput(tytTurkceCorrect: 30, aytMatCorrect: 20),
        ),
      ]);

      final aytMat =
          stats.firstWhere((s) => s.subject == YksSubject.aytMat);
      // Yalnız "genel" denemesi sayılmalı; TYT denemesi 0 net katmamalı.
      expect(aytMat.sampleSize, 1);
      expect(aytMat.avgNet, 20);
    });

    test('yalnız puan/sıra girilen kayıtlar analize girmez', () {
      final stats = subjectStats([
        _exam(
          id: 'rank',
          takenAt: DateTime(2026, 5, 1),
          input: const ScoreInput(
            entryMode: NetEntryMode.rank,
            scoreType: 'SAY',
            enteredRank: 45000,
          ),
        ),
      ]);
      expect(stats, isEmpty);
    });

    test('delta bir önceki pencereyle karşılaştırır', () {
      // window: 2 → son iki deneme ortalaması vs önceki iki.
      final stats = subjectStats(
        [
          _exam(
              id: '4',
              takenAt: DateTime(2026, 5, 4),
              kind: PracticeExamKind.tyt,
              input: tytNets(turkce: 34)),
          _exam(
              id: '3',
              takenAt: DateTime(2026, 5, 3),
              kind: PracticeExamKind.tyt,
              input: tytNets(turkce: 32)),
          _exam(
              id: '2',
              takenAt: DateTime(2026, 5, 2),
              kind: PracticeExamKind.tyt,
              input: tytNets(turkce: 28)),
          _exam(
              id: '1',
              takenAt: DateTime(2026, 5, 1),
              kind: PracticeExamKind.tyt,
              input: tytNets(turkce: 26)),
        ],
        window: 2,
      );

      final turkce =
          stats.firstWhere((s) => s.subject == YksSubject.tytTurkce);
      expect(turkce.avgNet, 33); // (34 + 32) / 2
      expect(turkce.lastNet, 34);
      expect(turkce.delta, 6); // 33 - 27
    });

    test('referans pencere yoksa delta null', () {
      final stats = subjectStats([
        _exam(
            id: '1',
            takenAt: DateTime(2026, 5, 1),
            kind: PracticeExamKind.tyt,
            input: tytNets()),
      ]);
      expect(stats.first.delta, isNull);
    });
  });

  group('weeklyStreak', () {
    // 2026-07-23 Perşembe; haftanın pazartesi'si 2026-07-20.
    final now = DateTime(2026, 7, 23);

    test('kayıt yoksa 0', () {
      expect(weeklyStreak(const [], now: now), 0);
    });

    test('kesintisiz üç hafta', () {
      final exams = [
        _exam(id: '1', takenAt: DateTime(2026, 7, 21)), // bu hafta
        _exam(id: '2', takenAt: DateTime(2026, 7, 15)), // geçen hafta
        _exam(id: '3', takenAt: DateTime(2026, 7, 8)), // ondan önceki
      ];
      expect(weeklyStreak(exams, now: now), 3);
    });

    test('bu hafta boşsa seri geçen haftadan sayılır', () {
      final exams = [
        _exam(id: '2', takenAt: DateTime(2026, 7, 15)),
        _exam(id: '3', takenAt: DateTime(2026, 7, 8)),
      ];
      // Hafta ortasında seri kırık görünmemeli.
      expect(weeklyStreak(exams, now: now), 2);
    });

    test('atlanan hafta seriyi bitirir', () {
      final exams = [
        _exam(id: '1', takenAt: DateTime(2026, 7, 21)), // bu hafta
        // 13-19 Temmuz haftası boş
        _exam(id: '3', takenAt: DateTime(2026, 7, 8)),
      ];
      expect(weeklyStreak(exams, now: now), 1);
    });

    test('aynı haftadaki iki deneme seriyi iki saymaz', () {
      final exams = [
        _exam(id: '1', takenAt: DateTime(2026, 7, 21)),
        _exam(id: '2', takenAt: DateTime(2026, 7, 22)),
      ];
      expect(weeklyStreak(exams, now: now), 1);
    });

    test('çok eski kayıt seri saymaz', () {
      expect(
        weeklyStreak([_exam(id: '1', takenAt: DateTime(2026, 1, 5))],
            now: now),
        0,
      );
    });
  });

  group('dominantScoreType / scoreTypesIn', () {
    test('en sık tür seçilir', () {
      final exams = [
        _exam(
            id: '1',
            takenAt: DateTime(2026, 5, 3),
            results: [_say(430, 65000)]),
        _exam(
            id: '2',
            takenAt: DateTime(2026, 5, 2),
            results: [_say(420, 75000)]),
        _exam(
          id: '3',
          takenAt: DateTime(2026, 5, 1),
          results: const [
            TypeScoreSnapshot(
                scoreType: 'EA', rawScore: 330, placementScore: 378),
          ],
        ),
      ];
      expect(dominantScoreType(exams), 'SAY');
      expect(scoreTypesIn(exams), ['SAY', 'EA']);
    });

    test('kayıt yoksa null', () {
      expect(dominantScoreType(const []), isNull);
      expect(scoreTypesIn(const []), isEmpty);
    });

    test('eşitlikte en son denemenin türü kazanır', () {
      final exams = [
        _exam(
          id: 'yeni',
          takenAt: DateTime(2026, 5, 10),
          results: const [
            TypeScoreSnapshot(
                scoreType: 'EA',
                rawScore: 330,
                placementScore: 378,
                estimatedRank: 90000),
          ],
        ),
        _exam(
            id: 'eski',
            takenAt: DateTime(2026, 5, 1),
            results: [_say(430, 65000)]),
      ];
      expect(dominantScoreType(exams), 'EA');
    });
  });
}
