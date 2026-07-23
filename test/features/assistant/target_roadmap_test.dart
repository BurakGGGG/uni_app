import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/assistant/domain/insights/target_roadmap.dart';
import 'package:uni_app/features/practice_exams/domain/practice_exam_analytics.dart';
import 'package:uni_app/features/score_calculator/domain/models/score_input.dart';
import 'package:uni_app/features/score_calculator/domain/models/yks_subject.dart';
import 'package:uni_app/features/score_calculator/domain/osym_score_distribution.dart';
import 'package:uni_app/features/score_calculator/domain/score_calculator_engine.dart';

SubjectStat _stat(
  YksSubject subject, {
  required double avg,
  int sampleSize = 5,
}) =>
    SubjectStat(
      subject: subject,
      avgNet: avg,
      lastNet: avg,
      delta: null,
      successRate: (avg / subject.maxQuestions).clamp(0.0, 1.0),
      sampleSize: sampleSize,
    );

/// Tipik bir SAY adayının orta seviye ders tablosu.
List<SubjectStat> _saySpread({
  double aytMat = 15,
  double aytFizik = 5,
  double aytKimya = 5,
  double aytBiyo = 5,
  double tytMat = 25,
  double tytTurkce = 30,
  double tytFen = 12,
  double tytSosyal = 12,
}) =>
    [
      _stat(YksSubject.aytMat, avg: aytMat),
      _stat(YksSubject.aytFizik, avg: aytFizik),
      _stat(YksSubject.aytKimya, avg: aytKimya),
      _stat(YksSubject.aytBiyo, avg: aytBiyo),
      _stat(YksSubject.tytMat, avg: tytMat),
      _stat(YksSubject.tytTurkce, avg: tytTurkce),
      _stat(YksSubject.tytFen, avg: tytFen),
      _stat(YksSubject.tytSosyal, avg: tytSosyal),
    ];

void main() {
  group('netWeights', () {
    test('tür kapsamı dışındaki ders haritada yer almaz', () {
      final say = ScoreCalculatorEngine.netWeights('SAY', year: 2026);
      expect(say.containsKey(YksSubject.aytFizik), isTrue);
      expect(say.containsKey(YksSubject.aytEdebiyat), isFalse);

      final soz = ScoreCalculatorEngine.netWeights('SÖZ', year: 2026);
      expect(soz.containsKey(YksSubject.aytFelsefe), isTrue);
      expect(soz.containsKey(YksSubject.aytMat), isFalse);

      expect(ScoreCalculatorEngine.netWeights('YOK'), isEmpty);
    });

    test('katsayılar puan motoruyla birebir tutarlı', () {
      // Her ders için: 1 net eklemenin ham puana etkisi = netWeights değeri.
      // Motor değişirse bu test kırılır — yol haritası sessizce yanlış
      // sayı söylemesin.
      for (final type in const ['TYT', 'SAY', 'EA', 'SÖZ', 'DİL']) {
        final weights = ScoreCalculatorEngine.netWeights(type, year: 2026);
        for (final entry in weights.entries) {
          const base = ScoreInput(
            selectedYear: 2026,
            entryMode: NetEntryMode.directNet,
            directNets: {},
          );
          final plusOne = ScoreInput(
            selectedYear: 2026,
            entryMode: NetEntryMode.directNet,
            directNets: {entry.key: 1},
          );
          final delta =
              ScoreCalculatorEngine.calculateRawScoreFor(plusOne, type) -
                  ScoreCalculatorEngine.calculateRawScoreFor(base, type);
          expect(
            delta,
            closeTo(entry.value, 0.0001),
            reason: '$type / ${entry.key.name}',
          );
        }
      }
    });
  });

  group('maxUsableNet', () {
    test('normalde soru sayısı kadar', () {
      expect(
        ScoreCalculatorEngine.maxUsableNet(YksSubject.aytFizik, year: 2026),
        14,
      );
      expect(
        ScoreCalculatorEngine.maxUsableNet(YksSubject.tytTurkce, year: 2026),
        40,
      );
    });

    test('2026 iptal-soru tavanları uygulanır', () {
      expect(
        ScoreCalculatorEngine.maxUsableNet(YksSubject.aytMat, year: 2026),
        39,
      );
      expect(
        ScoreCalculatorEngine.maxUsableNet(YksSubject.aytEdebiyat, year: 2026),
        23,
      );
      // Tavanı olmayan yılda tam soru sayısı.
      expect(
        ScoreCalculatorEngine.maxUsableNet(YksSubject.aytMat, year: 2025),
        40,
      );
    });
  });

  group('RoadmapPlanner.compute', () {
    test('hedef sırası yoksa null', () {
      expect(
        RoadmapPlanner.compute(
          targetRank: null,
          scoreType: 'SAY',
          year: 2026,
          currentScore: 400,
          stats: _saySpread(),
        ),
        isNull,
      );
    });

    test('hedefi geçmiş öğrencide adım üretmez, reached true', () {
      final roadmap = RoadmapPlanner.compute(
        targetRank: 300000,
        scoreType: 'SAY',
        year: 2026,
        currentScore: 480,
        stats: _saySpread(),
      );
      expect(roadmap, isNotNull);
      expect(roadmap!.reached, isTrue);
      expect(roadmap.steps, isEmpty);
      expect(roadmap.scoreGap, lessThanOrEqualTo(0));
    });

    test('adımlar farkı kapatır ve en çok 3 ders önerilir', () {
      final target =
          OsymScoreDistribution.estimateScore(20000, 'SAY', 2026)!.score;
      final roadmap = RoadmapPlanner.compute(
        targetRank: 20000,
        scoreType: 'SAY',
        year: 2026,
        currentScore: target - 40, // 40 puanlık gerçek bir fark
        stats: _saySpread(),
      )!;

      expect(roadmap.reached, isFalse);
      expect(roadmap.reachable, isTrue);
      expect(roadmap.steps, isNotEmpty);
      expect(roadmap.steps.length, lessThanOrEqualTo(RoadmapPlanner.maxSteps));

      final gained =
          roadmap.steps.fold<double>(0, (sum, s) => sum + s.scoreGain);
      expect(gained, greaterThanOrEqualTo(roadmap.scoreGap));
    });

    test('hiçbir adım dersin tavanını aşmaz', () {
      final target =
          OsymScoreDistribution.estimateScore(1000, 'SAY', 2026)!.score;
      final roadmap = RoadmapPlanner.compute(
        targetRank: 1000,
        scoreType: 'SAY',
        year: 2026,
        currentScore: target - 60,
        // AYT Matematik'i tavana yakın ver: 2026 tavanı 39.
        stats: _saySpread(aytMat: 37),
      )!;

      for (final step in roadmap.steps) {
        expect(
          step.targetNet,
          lessThanOrEqualTo(
            ScoreCalculatorEngine.maxUsableNet(step.subject, year: 2026) +
                0.001,
          ),
          reason: step.subject.name,
        );
        expect(step.netsNeeded, greaterThanOrEqualTo(
          RoadmapPlanner.minStepNet,
        ));
      }
    });

    test('her ders tavandayken yükseltilecek yer kalmaz → null', () {
      final roadmap = RoadmapPlanner.compute(
        targetRank: 1,
        scoreType: 'SAY',
        year: 2026,
        currentScore: 300,
        stats: [
          _stat(YksSubject.aytMat, avg: 39),
          _stat(YksSubject.aytFizik, avg: 14),
          _stat(YksSubject.aytKimya, avg: 13),
          _stat(YksSubject.aytBiyo, avg: 13),
          _stat(YksSubject.tytMat, avg: 40),
          _stat(YksSubject.tytTurkce, avg: 40),
          _stat(YksSubject.tytFen, avg: 20),
          _stat(YksSubject.tytSosyal, avg: 20),
        ],
      );
      expect(roadmap, isNull);
    });

    test('kalan potansiyel yetmiyorsa reachable false', () {
      // Neredeyse tavandaki bir öğrenciye çok uzak bir hedef.
      final roadmap = RoadmapPlanner.compute(
        targetRank: 1,
        scoreType: 'SAY',
        year: 2026,
        currentScore: 200,
        stats: [
          _stat(YksSubject.aytMat, avg: 38),
          _stat(YksSubject.aytFizik, avg: 13),
          _stat(YksSubject.aytKimya, avg: 12),
          _stat(YksSubject.aytBiyo, avg: 12),
          _stat(YksSubject.tytMat, avg: 39),
          _stat(YksSubject.tytTurkce, avg: 39),
          _stat(YksSubject.tytFen, avg: 19),
          _stat(YksSubject.tytSosyal, avg: 19),
        ],
      )!;
      expect(roadmap.reachable, isFalse);
    });

    test('zayıf ve yüksek katsayılı ders önce gelir', () {
      final target =
          OsymScoreDistribution.estimateScore(50000, 'SAY', 2026)!.score;
      final roadmap = RoadmapPlanner.compute(
        targetRank: 50000,
        scoreType: 'SAY',
        year: 2026,
        currentScore: target - 25,
        // AYT Matematik katsayısı en yüksek (3.02) ve başarı oranı en düşük.
        stats: _saySpread(aytMat: 4, aytFizik: 12, aytKimya: 11, aytBiyo: 11),
      )!;
      expect(roadmap.steps.first.subject, YksSubject.aytMat);
    });

    test('bilinmeyen türde yedek puan verilse bile hesap yapılmaz', () {
      // Katsayı tablosu olmayan tür → ders ağırlığı yok → yol haritası yok.
      expect(
        RoadmapPlanner.compute(
          targetRank: 5000,
          scoreType: 'YOK',
          year: 2026,
          currentScore: 400,
          targetScoreFallback: 480,
          stats: _saySpread(),
        ),
        isNull,
      );
    });

    test('hedef puanı yedeğe değil resmî dağılım tablosuna dayanır', () {
      final official =
          OsymScoreDistribution.estimateScore(20000, 'SAY', 2026)!.score;
      final roadmap = RoadmapPlanner.compute(
        targetRank: 20000,
        scoreType: 'SAY',
        year: 2026,
        currentScore: 400,
        targetScoreFallback: 450, // kasten yanlış yedek
        stats: _saySpread(),
      )!;
      expect(roadmap.targetScore, closeTo(official, 0.0001));
    });

    test('ilerleme oranı başlangıç puanına göre hesaplanır', () {
      final roadmap = RoadmapPlanner.compute(
        targetRank: 20000,
        scoreType: 'SAY',
        year: 2026,
        currentScore: 400,
        stats: _saySpread(),
      )!;
      final target = roadmap.targetScore;

      expect(roadmap.progress(startScore: null), isNull);
      // Yolun yarısı: başlangıç, hedefe olan mesafenin ortasında.
      final halfway = target - (target - 400) * 2;
      expect(roadmap.progress(startScore: halfway), closeTo(0.5, 0.001));
      // Baştan hedefin içindeyse tam.
      expect(roadmap.progress(startScore: target + 10), 1);
    });

    test('toplam net adımların toplamıdır', () {
      final target =
          OsymScoreDistribution.estimateScore(20000, 'SAY', 2026)!.score;
      final roadmap = RoadmapPlanner.compute(
        targetRank: 20000,
        scoreType: 'SAY',
        year: 2026,
        currentScore: target - 30,
        stats: _saySpread(),
      )!;
      final sum =
          roadmap.steps.fold<double>(0, (a, s) => a + s.netsNeeded);
      expect(roadmap.totalNetsNeeded, closeTo(sum, 0.0001));
    });
  });
}
