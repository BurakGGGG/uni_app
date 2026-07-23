import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/assistant/domain/insights/insight_context.dart';
import 'package:uni_app/features/assistant/domain/insights/weekly_plan.dart';
import 'package:uni_app/features/assistant/domain/robot_message.dart';
import 'package:uni_app/features/assistant/domain/robot_scripts.dart';
import 'package:uni_app/features/practice_exams/domain/models/exam_target.dart';
import 'package:uni_app/features/practice_exams/domain/models/practice_exam.dart';
import 'package:uni_app/features/preference_wizard/domain/models/student_score_profile.dart';
import 'package:uni_app/features/score_calculator/domain/models/score_input.dart';
import 'package:uni_app/features/score_calculator/domain/models/yks_subject.dart';

StudentScoreProfile _profile() => StudentScoreProfile(
      scoreType: 'SAY',
      placementScore: 430,
      year: 2026,
      updatedAt: DateTime(2026, 3, 1),
    );

ExamTarget _target() => ExamTarget(
      departmentId: 'd1',
      departmentName: 'Bilgisayar Müh.',
      universityName: 'Boğaziçi',
      scoreType: 'SAY',
      targetRank: 20000,
      targetScore: 480,
      setAt: DateTime(2026, 1, 1),
    );

PracticeExam _exam({
  required String id,
  required DateTime takenAt,
  Map<YksSubject, double> nets = const {},
}) {
  return PracticeExam(
    id: id,
    takenAt: takenAt,
    createdAt: takenAt,
    updatedAt: takenAt,
    name: 'Deneme $id',
    kind: PracticeExamKind.genel,
    year: 2026,
    input: ScoreInput(
      selectedYear: 2026,
      scoreType: 'SAY',
      obpScore: 80,
      selectedDepartment: '',
      entryMode: NetEntryMode.directNet,
      directNets: nets.isEmpty ? _defaultNets : nets,
    ),
    results: const [],
  );
}

const _defaultNets = <YksSubject, double>{
  YksSubject.tytTurkce: 30,
  YksSubject.tytSosyal: 12,
  YksSubject.tytMat: 25,
  YksSubject.tytFen: 12,
  YksSubject.aytMat: 15,
  YksSubject.aytFizik: 5,
  YksSubject.aytKimya: 5,
  YksSubject.aytBiyo: 5,
};

ListSnapshot _list({
  int items = 10,
  int guaranteed = 3,
  int target = 4,
  int dream = 3,
}) =>
    ListSnapshot(
      listId: 'l1',
      title: 'Listem',
      itemCount: items,
      guaranteed: guaranteed,
      target: target,
      dream: dream,
    );

Set<String> _ids(WeeklyPlan plan) => plan.tasks.map((t) => t.id).toSet();

void main() {
  tearDown(() => RobotScripts.languageCode = 'tr');

  group('hafta anahtarı', () {
    test('haftanın pazartesisini verir', () {
      // 2026-07-23 perşembe → pazartesi 2026-07-20.
      expect(weekKeyFor(DateTime(2026, 7, 23)), '2026-07-20');
      expect(weekKeyFor(DateTime(2026, 7, 20)), '2026-07-20');
      // Pazar hâlâ aynı haftaya ait.
      expect(weekKeyFor(DateTime(2026, 7, 26, 23, 59)), '2026-07-20');
      // Pazartesi yeni hafta.
      expect(weekKeyFor(DateTime(2026, 7, 27)), '2026-07-27');
    });

    test('ay ve yıl sınırını doğru geçer', () {
      expect(weekKeyFor(DateTime(2026, 1, 1)), '2025-12-29');
      expect(weekKeyFor(DateTime(2026, 3, 1)), '2026-02-23');
    });
  });

  group('kurulum eksikleri', () {
    test('profil yoksa ilk görev puan hesaplamak', () {
      final plan = WeeklyPlanner.build(InsightContext(now: DateTime(2026, 3, 5)));
      expect(plan.tasks.first.id, 'plan.calcScore');
      expect(plan.tasks.first.action, RobotAction.openScoreCalculator);
    });

    test('hedef yoksa hedef belirleme görevi girer', () {
      final plan = WeeklyPlanner.build(InsightContext(
        now: DateTime(2026, 3, 5),
        profile: _profile(),
      ));
      expect(_ids(plan), contains('plan.setTarget'));
    });
  });

  group('çalışma görevleri', () {
    test('bu hafta deneme yoksa deneme görevi çıkar', () {
      final plan = WeeklyPlanner.build(InsightContext(
        now: DateTime(2026, 3, 5),
        profile: _profile(),
        target: _target(),
        exams: [_exam(id: 'a', takenAt: DateTime(2026, 2, 20))],
      ));
      expect(_ids(plan), contains('plan.addExam'));
    });

    test('bu hafta deneme girilmişse görev tekrar edilmez', () {
      final plan = WeeklyPlanner.build(InsightContext(
        now: DateTime(2026, 3, 5), // perşembe
        profile: _profile(),
        target: _target(),
        exams: [_exam(id: 'a', takenAt: DateTime(2026, 3, 3))], // salı
      ));
      expect(_ids(plan), isNot(contains('plan.addExam')));
    });

    test('en zayıf ders görevi yeterli örneklem ister', () {
      // Tek deneme → sampleSize 1 → odak görevi çıkmaz.
      final tek = WeeklyPlanner.build(InsightContext(
        now: DateTime(2026, 3, 5),
        profile: _profile(),
        target: _target(),
        exams: [_exam(id: 'a', takenAt: DateTime(2026, 3, 3))],
      ));
      expect(_ids(tek), isNot(contains('plan.focusSubject')));

      final cok = WeeklyPlanner.build(InsightContext(
        now: DateTime(2026, 3, 5),
        profile: _profile(),
        target: _target(),
        exams: [
          for (var i = 0; i < 3; i++)
            _exam(id: 'e$i', takenAt: DateTime(2026, 3, i + 1)),
        ],
      ));
      expect(_ids(cok), contains('plan.focusSubject'));
    });
  });

  group('liste görevleri', () {
    test('güvenli tercih yoksa ekleme görevi çıkar', () {
      final plan = WeeklyPlanner.build(InsightContext(
        now: DateTime(2026, 7, 23), // tercih dönemi
        profile: _profile(),
        target: _target(),
        exams: [_exam(id: 'a', takenAt: DateTime(2026, 7, 21))],
        lists: [_list(guaranteed: 0, target: 5, dream: 5, items: 10)],
      ));
      expect(_ids(plan), contains('plan.addSafe'));
    });

    test('tercih döneminde liste görevleri çalışmanın önüne geçer', () {
      final ctx = InsightContext(
        now: DateTime(2026, 7, 23),
        profile: _profile(),
        target: _target(),
        exams: [_exam(id: 'a', takenAt: DateTime(2026, 7, 1))],
        lists: [_list(guaranteed: 0, target: 5, dream: 5, items: 10)],
      );
      final plan = WeeklyPlanner.build(ctx);
      expect(plan.tasks.first.id, startsWith('plan.'));
      expect(
        plan.tasks.first.id,
        anyOf('plan.addSafe', 'plan.completeList'),
        reason: 'temmuzda liste önce gelir',
      );
    });

    test('sezon dışında çalışma görevleri önce gelir', () {
      final plan = WeeklyPlanner.build(InsightContext(
        now: DateTime(2026, 3, 5),
        profile: _profile(),
        target: _target(),
        exams: [_exam(id: 'a', takenAt: DateTime(2026, 2, 20))],
        lists: [_list(guaranteed: 0, target: 5, dream: 5, items: 10)],
      ));
      expect(plan.tasks.first.id, 'plan.addExam');
    });

    test('boş listede liste görevi üretilmez', () {
      final plan = WeeklyPlanner.build(InsightContext(
        now: DateTime(2026, 7, 23),
        profile: _profile(),
        target: _target(),
        exams: [_exam(id: 'a', takenAt: DateTime(2026, 7, 21))],
        lists: [_list(items: 0, guaranteed: 0, target: 0, dream: 0)],
      ));
      expect(_ids(plan), isNot(contains('plan.completeList')));
      expect(_ids(plan), isNot(contains('plan.addSafe')));
    });
  });

  group('genel kurallar', () {
    test('en fazla 3 görev', () {
      final plan = WeeklyPlanner.build(InsightContext(
        now: DateTime(2026, 7, 23),
        lists: [_list(guaranteed: 0, target: 5, dream: 5, items: 6)],
      ));
      expect(plan.tasks.length, lessThanOrEqualTo(WeeklyPlanner.maxTasks));
    });

    test('aynı görev iki kez girmez', () {
      final plan = WeeklyPlanner.build(InsightContext(
        now: DateTime(2026, 7, 23),
        profile: _profile(),
        target: _target(),
        exams: [_exam(id: 'a', takenAt: DateTime(2026, 7, 1))],
        lists: [
          _list(guaranteed: 0, target: 3, dream: 3, items: 6),
          _list(guaranteed: 0, target: 2, dream: 2, items: 4),
        ],
      ));
      expect(_ids(plan).length, plan.tasks.length);
    });

    test('hiçbir görevde doldurulmamış yer tutucu kalmaz', () {
      for (final lang in ['tr', 'en']) {
        RobotScripts.languageCode = lang;
        for (final now in [DateTime(2026, 3, 5), DateTime(2026, 7, 23)]) {
          final plan = WeeklyPlanner.build(InsightContext(
            now: now,
            profile: _profile(),
            target: _target(),
            exams: [
              for (var i = 0; i < 4; i++)
                _exam(id: 'e$i', takenAt: now.subtract(Duration(days: 20 + i))),
            ],
            lists: [_list(guaranteed: 0, target: 5, dream: 5, items: 9)],
          ));
          for (final task in plan.tasks) {
            expect(task.title, isNot(contains('{')), reason: '${task.id} $lang');
            expect(task.hint, isNot(contains('{')), reason: '${task.id} $lang');
          }
        }
      }
    });

    test('görev id\'leri iki dilde birebir aynı', () {
      RobotScripts.languageCode = 'tr';
      final tr = RobotScripts.planTaskIds.toSet();
      RobotScripts.languageCode = 'en';
      expect(RobotScripts.planTaskIds.toSet(), tr);
    });

    test('plan hafta anahtarını taşır', () {
      final plan = WeeklyPlanner.build(InsightContext(
        now: DateTime(2026, 7, 23),
      ));
      expect(plan.weekKey, '2026-07-20');
    });
  });
}
