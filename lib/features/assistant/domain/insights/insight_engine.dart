import '../../../practice_exams/domain/practice_exam_analytics.dart';
import '../../../preference_wizard/domain/match_reason.dart' show formatRankTr;
import '../robot_message.dart';
import '../robot_mood.dart';
import '../robot_scripts.dart';
import '../tercih_calendar.dart';
import 'insight_context.dart';
import 'target_roadmap.dart';
import 'uni_insight.dart';

/// Üni'nin analist tarafı — tercih verisini okuyup önceliklendirilmiş not
/// listesi üretir.
///
/// [RobotBrain] ile aynı sözleşme: saf fonksiyonlar, LLM yok, metinler
/// [RobotScripts]'te. Fark şu — RobotBrain tek bir yüzey için tek bir cümle
/// seçer, burası tüm veriyi tarayıp "şu an senin için önemli olan ne" sorusunu
/// yanıtlar.
///
/// Motor bir dönem hedefe mesafe ve ders gelişimi de yayıyordu; o notlar
/// Üni'yi tercih asistanından çalışma koçuna çevirdiği için kaldırıldı.
/// Çalışmanın yeri Denemelerim: hedef bloğu, gelişim grafiği ve ders analizi
/// zaten orada, tam hâliyle duruyor. Burada kalan tek çalışma bağı
/// [roadmapFor] — onu da panel değil, Denemelerim'in hedef bloğu okuyor.
abstract final class InsightEngine {
  /// Ders analizinin baktığı deneme penceresi — `subjectStats` varsayılanı.
  /// Yalnız [roadmapFor] kullanır.
  static const int _statsWindow = 5;

  /// Taban puanın kayda değer sayılan yıllık oynaması.
  static const double _baseDeltaThreshold = 3;

  /// Bu oranın altında dolan kontenjan "boş kalmış" sayılır.
  static const double _lowFillRate = 0.9;

  /// Bağlamdan tüm notları üretir, önceliğe göre azalan sıralı.
  ///
  /// Eşit öncelikte id'ye göre alfabetik — sıralama deterministik olmalı,
  /// yoksa aynı veri her açılışta farklı kart gösterir.
  static List<UniInsight> analyze(InsightContext ctx) {
    final all = <UniInsight>[
      ..._setup(ctx),
      ..._list(ctx),
      ..._data(ctx),
      ..._calendar(ctx),
    ];
    all.sort((a, b) {
      final byPriority = b.priority.compareTo(a.priority);
      return byPriority != 0 ? byPriority : a.id.compareTo(b.id);
    });
    return all;
  }

  /// Bağlamdan hedef yol haritası; hesaplanamıyorsa null.
  ///
  /// Panel de aynı hesabı kullanır (blok olarak çizmek için) — iki yerde
  /// ayrı hesaplanırsa kart ile not farklı sayı söyler.
  static TargetRoadmap? roadmapFor(InsightContext ctx) {
    final target = ctx.target;
    if (target == null) return null;
    final exams = ctx.liveExams;
    if (exams.isEmpty) return null;

    final year = exams.first.year;
    final points = trendFor(exams, ctx.scoreType, year: year);
    final latest = points.lastOrNull;
    final currentScore = latest?.placementScore;
    if (currentScore == null || currentScore <= 0) return null;

    return RoadmapPlanner.compute(
      targetRank: target.targetRank,
      targetScoreFallback: target.targetScore,
      scoreType: ctx.scoreType,
      year: year,
      currentScore: currentScore,
      currentRank: latest?.rank,
      stats: subjectStats(exams, window: _statsWindow),
    );
  }

  // ── Kurulum ────────────────────────────────────────────────────

  /// Tercih yolunun tek ön koşulu: puan.
  ///
  /// Bir zamanlar burada üç adımlık bir zincir vardı (puan → ilk deneme →
  /// hedef program) ve öğrenci daha tercih listesine bakamadan iki çalışma
  /// ödevi alıyordu. Deneme ve hedef daveti artık Denemelerim'in kendi boş
  /// durumunda ve hedef kartında yaşıyor; tercih asistanı onları sormaz.
  static List<UniInsight> _setup(InsightContext ctx) {
    if (ctx.hasProfile) return const [];
    return [
      _build(
        id: 'setup.noProfile',
        kind: InsightKind.setup,
        priority: 95,
        tone: InsightTone.neutral,
        mood: RobotMood.thinking,
        action: RobotAction.openScoreCalculator,
        dismissible: false,
      ),
    ];
  }

  // ── Liste ──────────────────────────────────────────────────────

  /// Liste uyarıları tercih döneminde öne fırlar; sezon dışında bir öğrencinin
  /// listesinin yarım olması sorun değildir, temmuzda öyledir.
  static List<UniInsight> _list(InsightContext ctx) {
    final inSeason = ctx.phase == TercihPhase.tercihPeriod;
    int p(int seasonal, int offSeason) => inSeason ? seasonal : offSeason;

    final lists = ctx.lists;
    if (lists.isEmpty || lists.every((l) => l.itemCount == 0)) {
      return [
        _build(
          id: 'list.empty',
          kind: InsightKind.list,
          priority: p(70, 40),
          tone: InsightTone.neutral,
          mood: RobotMood.neutral,
          action: RobotAction.openLists,
        ),
      ];
    }

    // En dolu liste "asıl" liste sayılır — kullanıcı 10 liste tutabiliyor,
    // hepsi için ayrı uyarı paneli boğar.
    final main = lists.reduce((a, b) => b.itemCount > a.itemCount ? b : a);
    final out = <UniInsight>[];

    if (main.rated > 0 && main.guaranteed == 0 && main.itemCount >= 5) {
      out.add(_build(
        id: 'list.noSafe',
        kind: InsightKind.list,
        priority: p(85, 50),
        tone: inSeason ? InsightTone.urgent : InsightTone.warning,
        mood: RobotMood.concerned,
        action: RobotAction.openLists,
        vars: {'count': '${main.itemCount}'},
      ));
    } else if (main.rated > 0 && main.dream * 2 > main.rated) {
      out.add(_build(
        id: 'list.tooRisky',
        kind: InsightKind.list,
        priority: p(80, 45),
        tone: InsightTone.warning,
        mood: RobotMood.concerned,
        action: RobotAction.openLists,
        vars: {'rated': '${main.rated}', 'dream': '${main.dream}'},
      ));
    }

    if (main.itemCount > 0 && main.itemCount < 24) {
      out.add(_build(
        id: 'list.incomplete',
        kind: InsightKind.list,
        priority: p(75, 35),
        tone: inSeason ? InsightTone.warning : InsightTone.neutral,
        mood: RobotMood.thinking,
        action: RobotAction.openLists,
        vars: {
          'count': '${main.itemCount}',
          'remaining': '${24 - main.itemCount}',
        },
      ));
    }

    if (main.topCityCount >= 4 && main.topCityName != null) {
      out.add(_build(
        id: 'list.cityConcentration',
        kind: InsightKind.list,
        priority: p(60, 45),
        tone: InsightTone.neutral,
        mood: RobotMood.thinking,
        action: RobotAction.openLists,
        vars: {
          'count': '${main.topCityCount}',
          'city': main.topCityName!,
        },
      ));
    }

    return out;
  }

  // ── ÖSYM verisi ────────────────────────────────────────────────

  /// Takip edilen programlarda dikkat çeken tek bir veri hareketi. Hepsini
  /// yaymak paneli tabloya çevirirdi; en belirgin olanı seçilir.
  static List<UniInsight> _data(InsightContext ctx) {
    if (ctx.tracked.isEmpty) return const [];

    TrackedProgram? down;
    TrackedProgram? up;
    TrackedProgram? empty;
    for (final t in ctx.tracked) {
      final delta = t.baseScoreDelta;
      if (delta != null) {
        if (delta <= -_baseDeltaThreshold &&
            (down == null || delta < down.baseScoreDelta!)) {
          down = t;
        }
        if (delta >= _baseDeltaThreshold &&
            (up == null || delta > up.baseScoreDelta!)) {
          up = t;
        }
      }
      final fill = t.fillRate;
      if (fill != null &&
          fill > 0 &&
          fill < _lowFillRate &&
          (empty == null || fill < empty.fillRate!)) {
        empty = t;
      }
    }

    final out = <UniInsight>[];
    if (down != null) {
      out.add(_build(
        id: 'data.baseTrendDown',
        kind: InsightKind.data,
        priority: 60,
        tone: InsightTone.positive,
        mood: RobotMood.happy,
        action: RobotAction.openBestPrograms,
        actionArg: down.departmentName,
        vars: {
          'dept': down.departmentName,
          'uni': down.universityName,
          'delta': _num(-down.baseScoreDelta!),
        },
      ));
    }
    if (up != null) {
      out.add(_build(
        id: 'data.baseTrendUp',
        kind: InsightKind.data,
        priority: 58,
        tone: InsightTone.warning,
        mood: RobotMood.thinking,
        action: RobotAction.openBestPrograms,
        actionArg: up.departmentName,
        vars: {
          'dept': up.departmentName,
          'uni': up.universityName,
          'delta': _num(up.baseScoreDelta!),
        },
      ));
    }
    if (empty != null) {
      out.add(_build(
        id: 'data.lowFillRate',
        kind: InsightKind.data,
        priority: 45,
        tone: InsightTone.neutral,
        mood: RobotMood.thinking,
        action: RobotAction.openBestPrograms,
        actionArg: empty.departmentName,
        vars: {
          'dept': empty.departmentName,
          'uni': empty.universityName,
          'rate': '${(empty.fillRate! * 100).round()}',
        },
      ));
    }
    return out;
  }

  // ── Takvim ─────────────────────────────────────────────────────

  static List<UniInsight> _calendar(InsightContext ctx) {
    final days = daysLeftInPhase(ctx.now);
    switch (ctx.phase) {
      case TercihPhase.tercihPeriod:
        if (days == null) return const [];
        return [
          _build(
            id: 'calendar.tercihCountdown',
            kind: InsightKind.calendar,
            priority: 90,
            tone: days <= 3 ? InsightTone.urgent : InsightTone.warning,
            mood: days <= 3 ? RobotMood.concerned : RobotMood.happy,
            action: RobotAction.openLists,
            dismissible: false,
            vars: {'days': '$days'},
          ),
        ];
      case TercihPhase.examCountdown:
        if (days == null) return const [];
        return [
          _build(
            id: 'calendar.examCountdown',
            kind: InsightKind.calendar,
            priority: 60,
            tone: InsightTone.neutral,
            mood: RobotMood.thinking,
            action: RobotAction.openPracticeExams,
            vars: {'days': '${days + 1}'},
          ),
        ];
      case TercihPhase.resultsWait:
        return [
          _build(
            id: 'calendar.resultsWait',
            kind: InsightKind.calendar,
            priority: 70,
            tone: InsightTone.neutral,
            mood: RobotMood.thinking,
            action: RobotAction.openScoreCalculator,
          ),
        ];
      case TercihPhase.examWeek:
      case TercihPhase.placementWait:
      case TercihPhase.placementDone:
      case TercihPhase.offSeason:
        return const [];
    }
  }

  // ── Yardımcılar ────────────────────────────────────────────────

  /// Tek ondalıklı sayı. Türkçede virgül, İngilizcede nokta — net ve puan
  /// farkları bu biçimi paylaşır. İşaret metinde taşınır ("{delta} net
  /// geriledi"), burada mutlak değer beklenir.
  static String _num(double value) {
    final text = value.toStringAsFixed(1);
    return RobotScripts.isEn ? text : text.replaceAll('.', ',');
  }

  /// Binlik ayraçlı sıra. [formatRankTr] Türkçe biçimi verir (85.600);
  /// İngilizcede ayraç virgüldür. Panelin "Puanın" adımı da bunu kullanır —
  /// aynı sayı iki yerde iki türlü yazılmasın.
  static String formatRank(int value) {
    final text = formatRankTr(value);
    return RobotScripts.isEn ? text.replaceAll('.', ',') : text;
  }

  /// Metni tablodan alır, `{...}` yer tutucularını doldurur ve kartı kurar.
  static UniInsight _build({
    required String id,
    required InsightKind kind,
    required int priority,
    required InsightTone tone,
    required RobotMood mood,
    RobotAction action = RobotAction.none,
    String? actionArg,
    bool dismissible = true,
    Map<String, String> vars = const {},
  }) {
    final copy = RobotScripts.insight(id);
    return UniInsight(
      id: id,
      kind: kind,
      priority: priority,
      tone: tone,
      mood: mood,
      title: _fill(copy.title, vars),
      body: _fill(copy.body, vars),
      actionLabel: action == RobotAction.none ? null : copy.actionLabel,
      action: action,
      actionArg: actionArg,
      dismissible: dismissible,
    );
  }

  static String _fill(String template, Map<String, String> vars) {
    var out = template;
    vars.forEach((key, value) => out = out.replaceAll('{$key}', value));
    return out;
  }
}
