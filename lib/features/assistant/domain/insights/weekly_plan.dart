import '../../../practice_exams/domain/practice_exam_analytics.dart';
import '../robot_message.dart';
import '../robot_scripts.dart';
import 'insight_context.dart';
import 'target_roadmap.dart';

/// Haftalık plandaki tek görev.
class PlanTask {
  /// Şablon kimliği (`plan.addExam`) — işaretleme durumu bununla saklanır,
  /// dolayısıyla hafta içinde kararlı olmalıdır.
  final String id;
  final String title;
  final String hint;
  final RobotAction action;
  final String? actionArg;

  const PlanTask({
    required this.id,
    required this.title,
    required this.hint,
    this.action = RobotAction.none,
    this.actionArg,
  });
}

/// Bir haftanın planı.
class WeeklyPlan {
  /// Haftanın pazartesisi, `2026-07-20` biçiminde. Depolama anahtarı budur;
  /// hafta dönünce işaretler kendiliğinden sıfırlanır.
  final String weekKey;
  final List<PlanTask> tasks;

  const WeeklyPlan({required this.weekKey, required this.tasks});

  bool get isEmpty => tasks.isEmpty;
}

/// Haftalık ÇALIŞMA planını üretir — saf, kural tabanlı.
///
/// Görevleri kullanıcı yazmaz, Üni türetir: zayıf dersler + hedef mesafesi.
/// Plan bir dönem tercih görevleri de yayıyordu ("listene 12 tercih daha
/// ekle"); onlar Üni Paneli'nin 3. ve 4. adımına taşındı — aynı işi iki yerde
/// istemek kullanıcıya iki ayrı ödev listesi gibi okunuyordu. Burası artık
/// Denemelerim'in bloğu: yalnız çalışma.
abstract final class WeeklyPlanner {
  /// En fazla kaç görev. Üçten fazlası haftalık plan değil, yapılacaklar
  /// listesi olur ve hiçbiri yapılmaz.
  static const int maxTasks = 3;

  static WeeklyPlan build(InsightContext ctx, {TargetRoadmap? roadmap}) {
    final tasks = <PlanTask>[];

    void add(
      String id, {
      Map<String, String> vars = const {},
      RobotAction action = RobotAction.none,
      String? actionArg,
    }) {
      if (tasks.length >= maxTasks) return;
      if (tasks.any((t) => t.id == id)) return;
      final copy = RobotScripts.planTask(id);
      tasks.add(PlanTask(
        id: id,
        title: _fill(copy.title, vars),
        hint: _fill(copy.body, vars),
        action: action,
        actionArg: actionArg,
      ));
    }

    // Kurulum eksikse plan onu kapatmaya çalışır; ölçemediğim şey için
    // görev veremem.
    if (!ctx.hasProfile) {
      add('plan.calcScore', action: RobotAction.openScoreCalculator);
    }
    if (ctx.target == null) {
      add('plan.setTarget', action: RobotAction.setTarget);
    }

    _studyTasks(ctx, roadmap, add);

    return WeeklyPlan(weekKey: weekKeyFor(ctx.now), tasks: tasks);
  }

  /// Çalışma tarafı: bu haftanın denemesi + yol haritasının ilk adımı +
  /// en zayıf ders.
  static void _studyTasks(
    InsightContext ctx,
    TargetRoadmap? roadmap,
    void Function(String,
            {Map<String, String> vars,
            RobotAction action,
            String? actionArg})
        add,
  ) {
    final exams = ctx.liveExams;
    final thisWeek = weekKeyFor(ctx.now);
    final loggedThisWeek =
        exams.any((e) => weekKeyFor(e.takenAt) == thisWeek);
    if (!loggedThisWeek) {
      add('plan.addExam', action: RobotAction.openPracticeExams);
    }

    final step = roadmap?.steps.firstOrNull;
    if (step != null) {
      add(
        'plan.raiseNet',
        vars: {
          'subject': RobotScripts.subjectLabel(step.subject.labelTr),
          'nets': _num(step.netsNeeded),
          'gain': _num(step.scoreGain),
        },
        action: RobotAction.openPracticeExams,
      );
      return; // yol haritası zaten "hangi derse yüklen"i söylüyor
    }

    final stats = subjectStats(exams);
    if (stats.isNotEmpty) {
      final weakest = stats.last;
      if (weakest.sampleSize >= 2 && weakest.successRate < 0.6) {
        add(
          'plan.focusSubject',
          vars: {
            'subject': RobotScripts.subjectLabel(weakest.subject.labelTr),
            'rate': '${(weakest.successRate * 100).round()}',
          },
          action: RobotAction.openPracticeExams,
        );
      }
    }
  }

  static String _fill(String template, Map<String, String> vars) {
    var out = template;
    vars.forEach((key, value) => out = out.replaceAll('{$key}', value));
    return out;
  }

  static String _num(double value) {
    // Tam sayıysa ondalık gösterme: "+5 net" "+5,0 net"den iyi okunur.
    final text = value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
    return RobotScripts.isEn ? text : text.replaceAll('.', ',');
  }
}

/// Tarihin ait olduğu haftanın pazartesisi, `YYYY-MM-DD` biçiminde.
/// [weeklyStreak] ile aynı hafta tanımı (pazartesi başlangıç).
String weekKeyFor(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  final monday = day.subtract(Duration(days: day.weekday - DateTime.monday));
  final m = monday.month.toString().padLeft(2, '0');
  final d = monday.day.toString().padLeft(2, '0');
  return '${monday.year}-$m-$d';
}
