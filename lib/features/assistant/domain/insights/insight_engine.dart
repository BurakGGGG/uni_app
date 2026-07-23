import '../../../practice_exams/domain/practice_exam_analytics.dart';
import '../../../preference_wizard/domain/match_reason.dart' show formatRankTr;
import '../robot_message.dart';
import '../robot_mood.dart';
import '../robot_scripts.dart';
import '../tercih_calendar.dart';
import 'insight_context.dart';
import 'target_roadmap.dart';
import 'uni_insight.dart';

/// Üni'nin analist tarafı — tüm veri kaynaklarını okuyup önceliklendirilmiş
/// not listesi üretir.
///
/// [RobotBrain] ile aynı sözleşme: saf fonksiyonlar, LLM yok, metinler
/// [RobotScripts]'te. Fark şu — RobotBrain tek bir yüzey için tek bir cümle
/// seçer, burası tüm veriyi tarayıp "şu an senin için önemli olan ne" sorusunu
/// yanıtlar. Uygulamadaki her ekran kendi verisini biliyor; birbirine bağlayan
/// tek yer burası.
abstract final class InsightEngine {
  /// Ders ortalamasındaki bu kadar netlik değişim "kayda değer" sayılır.
  static const double _subjectDeltaThreshold = 1.5;

  /// Bu kadar gün deneme girilmezse defter "sessiz" kabul edilir.
  static const int _staleDays = 21;

  /// Ders analizinin baktığı deneme penceresi — `subjectStats` varsayılanı.
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
      ..._target(ctx),
      ..._progress(ctx),
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

  /// "Matematik +5 · Fizik +3" — yol haritasının tek satırlık özeti.
  static String describeSteps(TargetRoadmap roadmap) {
    return roadmap.steps
        .map((s) =>
            '${RobotScripts.subjectLabel(s.subject.labelTr)} +${_num(s.netsNeeded)}')
        .join(' · ');
  }

  /// Kurulum yolunun durumu — panelin ilerleme çubuğu bunu çizer.
  static SetupPath setupPathOf(InsightContext ctx) {
    return SetupPath(
      hasProfile: ctx.hasProfile,
      hasTarget: ctx.target != null,
      hasExam: ctx.liveExams.isNotEmpty,
    );
  }

  // ── Kurulum ────────────────────────────────────────────────────

  /// Yalnız SIRADAKİ eksik adımı yayar: üçü birden kart olsaydı panel açılışta
  /// üç kez "eksiksin" derdi. Çubuk zaten hepsini gösteriyor.
  static List<UniInsight> _setup(InsightContext ctx) {
    final path = setupPathOf(ctx);
    if (path.complete) return const [];

    final (id, priority, action) = switch (path) {
      SetupPath(hasProfile: false) => (
          'setup.noProfile',
          95,
          RobotAction.openScoreCalculator,
        ),
      SetupPath(hasTarget: false) => (
          'setup.noTarget',
          90,
          RobotAction.setTarget,
        ),
      _ => ('setup.noExam', 85, RobotAction.openPracticeExams),
    };

    return [
      _build(
        id: id,
        kind: InsightKind.setup,
        priority: priority,
        tone: InsightTone.neutral,
        mood: RobotMood.thinking,
        action: action,
        dismissible: false,
      ),
    ];
  }

  // ── Hedef ──────────────────────────────────────────────────────

  static List<UniInsight> _target(InsightContext ctx) {
    final target = ctx.target;
    final targetRank = target?.targetRank;
    if (target == null || targetRank == null || targetRank <= 0) {
      return const [];
    }

    final points = _rankedTrend(ctx);
    if (points.isEmpty) return const [];

    final current = points.last.rank!;
    final out = <UniInsight>[];

    if (current <= targetRank) {
      out.add(_build(
        id: 'target.reached',
        kind: InsightKind.target,
        priority: 88,
        tone: InsightTone.positive,
        mood: RobotMood.celebrating,
        action: RobotAction.setTarget,
        vars: {
          'dept': target.departmentName,
          'targetRank': _rank(targetRank),
          'currentRank': _rank(current),
        },
      ));
      return out;
    }

    // Yol haritası: hedefe kaç net, hangi dersten. Panelin ve ana sayfanın
    // en değerli cümlesi bu — yön notlarından önce gelir.
    final roadmap = roadmapFor(ctx);
    if (roadmap != null && !roadmap.reached) {
      if (!roadmap.reachable) {
        out.add(_build(
          id: 'target.unreachable',
          kind: InsightKind.target,
          priority: 80,
          tone: InsightTone.warning,
          mood: RobotMood.concerned,
          action: RobotAction.setTarget,
          vars: {
            'dept': target.departmentName,
            'gap': _num(roadmap.scoreGap),
          },
        ));
      } else if (roadmap.steps.isNotEmpty) {
        out.add(_build(
          id: 'target.roadmap',
          kind: InsightKind.target,
          priority: 82,
          tone: InsightTone.neutral,
          mood: RobotMood.thinking,
          action: RobotAction.openPracticeExams,
          vars: {
            'dept': target.departmentName,
            'nets': _num(roadmap.totalNetsNeeded),
            'gap': _num(roadmap.scoreGap),
            'plan': describeSteps(roadmap),
          },
        ));
      }
    }

    // Yön: ilk ve son sıralı nokta arasındaki fark. Tek nokta varsa yön yok.
    if (points.length >= 2) {
      final first = points.first.rank!;
      final moved = first - current; // pozitif = iyileşme
      if (moved > 0) {
        out.add(_build(
          id: 'target.closing',
          kind: InsightKind.target,
          priority: 70,
          tone: InsightTone.positive,
          mood: RobotMood.happy,
          action: RobotAction.openPracticeExams,
          vars: {
            'count': '${points.length}',
            'gain': _rank(moved),
            'dept': target.departmentName,
            'remaining': _rank(current - targetRank),
          },
        ));
      } else if (moved < 0) {
        out.add(_build(
          id: 'target.drifting',
          kind: InsightKind.target,
          priority: 75,
          tone: InsightTone.warning,
          mood: RobotMood.concerned,
          action: RobotAction.openPracticeExams,
          vars: {
            'count': '${points.length}',
            'loss': _rank(-moved),
            'dept': target.departmentName,
          },
        ));
      }
    }
    return out;
  }

  // ── Gelişim ────────────────────────────────────────────────────

  static List<UniInsight> _progress(InsightContext ctx) {
    final exams = ctx.liveExams;
    if (exams.isEmpty) return const [];

    final out = <UniInsight>[];

    // Sessizlik — en yeni deneme üstte (liveExams yeniden eskiye sıralı).
    final sinceLast = _wholeDaysBetween(exams.first.takenAt, ctx.now);
    if (sinceLast >= _staleDays) {
      out.add(_build(
        id: 'progress.stale',
        kind: InsightKind.progress,
        priority: 78,
        tone: InsightTone.warning,
        mood: RobotMood.sleeping,
        action: RobotAction.openPracticeExams,
        vars: {'days': '$sinceLast'},
      ));
    }

    final stats = subjectStats(exams, window: _statsWindow);
    if (stats.isNotEmpty) {
      // En sert düşüş ve en sert yükseliş — her ailenin en fazla bir kartı.
      SubjectStat? worst;
      SubjectStat? best;
      for (final s in stats) {
        final delta = s.delta;
        if (delta == null) continue;
        if (delta <= -_subjectDeltaThreshold &&
            (worst == null || delta < worst.delta!)) {
          worst = s;
        }
        if (delta >= _subjectDeltaThreshold &&
            (best == null || delta > best.delta!)) {
          best = s;
        }
      }
      if (worst != null) {
        out.add(_build(
          id: 'progress.drop',
          kind: InsightKind.progress,
          priority: 74,
          tone: InsightTone.warning,
          mood: RobotMood.concerned,
          action: RobotAction.openPracticeExams,
          vars: {
            'subject': RobotScripts.subjectLabel(worst.subject.labelTr),
            'delta': _num(-worst.delta!),
            'avg': _num(worst.avgNet),
          },
        ));
      }
      if (best != null) {
        out.add(_build(
          id: 'progress.jump',
          kind: InsightKind.progress,
          priority: 72,
          tone: InsightTone.positive,
          mood: RobotMood.celebrating,
          action: RobotAction.openPracticeExams,
          vars: {
            'subject': RobotScripts.subjectLabel(best.subject.labelTr),
            'delta': _num(best.delta!),
            'avg': _num(best.avgNet),
          },
        ));
      }

      // En zayıf ders — stats successRate'e göre azalan sıralı geliyor.
      final weakest = stats.last;
      if (weakest.sampleSize >= 2 && weakest.successRate < 0.5) {
        out.add(_build(
          id: 'progress.weakest',
          kind: InsightKind.progress,
          priority: 65,
          tone: InsightTone.neutral,
          mood: RobotMood.thinking,
          action: RobotAction.openPracticeExams,
          vars: {
            'subject': RobotScripts.subjectLabel(weakest.subject.labelTr),
            'rate': '${(weakest.successRate * 100).round()}',
          },
        ));
      }
    }

    final streak = weeklyStreak(exams, now: ctx.now);
    if (streak >= 2) {
      out.add(_build(
        id: 'progress.streak',
        kind: InsightKind.progress,
        priority: 55,
        tone: InsightTone.positive,
        mood: RobotMood.celebrating,
        vars: {'weeks': '$streak'},
      ));
    }

    final points = _rankedTrend(ctx);
    if (points.length >= 2) {
      final gain = points.first.rank! - points.last.rank!;
      if (gain > 0) {
        out.add(_build(
          id: 'progress.rankGain',
          kind: InsightKind.progress,
          priority: 68,
          tone: InsightTone.positive,
          mood: RobotMood.celebrating,
          action: RobotAction.openPracticeExams,
          vars: {
            'gain': _rank(gain),
            'first': _rank(points.first.rank!),
            'last': _rank(points.last.rank!),
          },
        ));
      }
    }

    return out;
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

  /// Analiz türüne göre deneme serisi, yalnız sırası bilinen noktalar,
  /// eskiden yeniye. Seri tek yıla oturtulur — 2022 sırasıyla 2025 sırası
  /// aynı eksene çizilirse gelişim yanlış okunur ([trendFor] notu).
  static List<ExamTrendPoint> _rankedTrend(InsightContext ctx) {
    final exams = ctx.liveExams;
    final type = ctx.scoreType;
    if (exams.isEmpty || type.isEmpty) return const [];
    final points = trendFor(exams, type, year: exams.first.year);
    return [
      for (final p in points)
        if (p.rank != null && p.rank! > 0) p,
    ];
  }

  static int _wholeDaysBetween(DateTime from, DateTime to) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  /// Tek ondalıklı sayı. Türkçede virgül, İngilizcede nokta — net ve puan
  /// farkları bu biçimi paylaşır. İşaret metinde taşınır ("{delta} net
  /// geriledi"), burada mutlak değer beklenir.
  static String _num(double value) {
    final text = value.toStringAsFixed(1);
    return RobotScripts.isEn ? text : text.replaceAll('.', ',');
  }

  /// Binlik ayraçlı sıra. [formatRankTr] Türkçe biçimi verir (85.600);
  /// İngilizcede ayraç virgüldür.
  static String _rank(int value) {
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
