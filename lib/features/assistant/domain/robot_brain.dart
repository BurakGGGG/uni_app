import '../../preference_wizard/domain/list_health.dart';
import '../../preference_wizard/domain/match_reason.dart';
import 'robot_message.dart';
import 'robot_mood.dart';
import 'robot_scripts.dart';
import 'tercih_calendar.dart';

/// Ana ekran selamlaması için bağlam.
class HomeContext {
  final DateTime now;
  final TercihPhase phase;
  final DayPeriod dayPeriod;

  /// Kullanıcının görünen adının ilk kelimesi; anonim/boşsa null.
  final String? firstName;
  final bool hasProfile;

  HomeContext({
    required this.now,
    required this.hasProfile,
    this.firstName,
    TercihPhase? phase,
    DayPeriod? dayPeriod,
  })  : phase = phase ?? tercihPhaseFor(now),
        dayPeriod = dayPeriod ?? dayPeriodFor(now);
}

/// Sonuç ekranı özeti için bağlam — motorun kategori sayıları.
class ResultsContext {
  final int guaranteed;
  final int target;
  final int dream;

  /// Öğrenci yalnız puan girdi, sırası tahmin edildi.
  final bool usedEstimatedRank;

  /// Faz 2 LLM etiketleri için isteğe bağlı profil özeti; kural motoru
  /// bunları kullanmaz.
  final String? scoreType;
  final int? rank;

  const ResultsContext({
    required this.guaranteed,
    required this.target,
    required this.dream,
    this.usedEstimatedRank = false,
    this.scoreType,
    this.rank,
  });

  int get total => guaranteed + target + dream;
}

/// Üni'nin kural tabanlı beyni — saf fonksiyonlar, yüzey başına bir giriş.
/// Metinler [RobotScripts]'te yaşar; burada yalnız seçim + doldurma vardır.
/// LLM yok: maliyetsiz, anında, deterministik test edilebilir.
abstract final class RobotBrain {
  /// Varyantlar arasından seçim. [seed] verilmezse gün+ay kullanılır
  /// (gün boyu sabit, ertesi gün döner); [excludeId] son gösterileni atlar.
  static RobotScript pick(
    List<RobotScript> variants, {
    int? seed,
    String? excludeId,
  }) {
    assert(variants.isNotEmpty);
    var pool = variants;
    if (excludeId != null && variants.length > 1) {
      pool = variants.where((v) => v.id != excludeId).toList();
      if (pool.isEmpty) pool = variants;
    }
    final now = DateTime.now();
    final s = seed ?? (now.day + now.month * 31);
    return pool[s % pool.length];
  }

  // ── Ana ekran ──

  static RobotMessage homeGreeting(
    HomeContext ctx, {
    int? seed,
    String? excludeId,
  }) {
    final body = pick(
      _homeBodiesFor(ctx),
      seed: seed,
      excludeId: excludeId,
    );
    final hello = _helloFor(ctx.dayPeriod, ctx.firstName);
    return RobotMessage(
      body.id,
      '$hello ${body.text}',
      body.mood,
      action: body.action,
    );
  }

  static List<RobotScript> _homeBodiesFor(HomeContext ctx) {
    switch (ctx.phase) {
      case TercihPhase.examCountdown:
        return RobotScripts.homeExamCountdown;
      case TercihPhase.examWeek:
        return RobotScripts.homeExamWeek;
      case TercihPhase.resultsWait:
        return RobotScripts.homeResultsWait;
      case TercihPhase.tercihPeriod:
        return ctx.hasProfile
            ? RobotScripts.homeTercihWithProfile
            : RobotScripts.homeTercihNoProfile;
      case TercihPhase.placementWait:
        return RobotScripts.homePlacementWait;
      case TercihPhase.placementDone:
        return RobotScripts.homePlacementDone;
      case TercihPhase.offSeason:
        return RobotScripts.homeOffSeason;
    }
  }

  static String _helloFor(DayPeriod period, String? firstName) {
    final n = (firstName == null || firstName.isEmpty) ? '' : ' $firstName';
    if (RobotScripts.isEn) {
      switch (period) {
        case DayPeriod.morning:
          return 'Good morning$n!';
        case DayPeriod.afternoon:
          return 'Hey$n!';
        case DayPeriod.evening:
          return 'Good evening$n!';
        case DayPeriod.night:
          return 'Up at this hour, are we$n!';
      }
    }
    switch (period) {
      case DayPeriod.morning:
        return 'Günaydın$n!';
      case DayPeriod.afternoon:
        return 'Selam$n!';
      case DayPeriod.evening:
        return 'İyi akşamlar$n!';
      case DayPeriod.night:
        return 'Bu saatte ayaktayız demek$n!';
    }
  }

  static RobotMessage tipOfDay(
    TercihPhase phase, {
    int? seed,
    String? excludeId,
  }) {
    // Şimdilik ipuçları faz-bağımsız; faz parametresi ileride filtre için.
    return pick(RobotScripts.tips, seed: seed, excludeId: excludeId)
        .toMessage();
  }

  // ── Sihirbaz girişi ──

  static RobotMessage wizardWelcome({
    required bool hasProfile,
    required bool firstVisit,
    int? seed,
  }) {
    if (firstVisit) return RobotScripts.wizardFirstVisit.first.toMessage();
    return pick(
      hasProfile
          ? RobotScripts.wizardWithProfile
          : RobotScripts.wizardNoProfile,
      seed: seed,
    ).toMessage();
  }

  static RobotMessage get wizardValidationError =>
      RobotScripts.wizardValidation.toMessage();

  /// Puan türü seçilince kısa tepki; bilinmeyen türde null.
  static RobotMessage? wizardScoreTypeReaction(String scoreType) {
    final text = RobotScripts.isEn
        ? switch (scoreType.toUpperCase()) {
            'SAY' =>
              "SAY! We'll browse a wide range, from engineering to health.",
            'EA' => 'EA! Nice options from law to psychology.',
            'SÖZ' =>
              "SÖZ! We'll look at literature, media, history and guidance.",
            'DİL' =>
              "DİL! From translation to language teaching — let's look "
                  'together.',
            'TYT' =>
              "TYT it is — we'll browse two-year (associate) programs.",
            _ => null,
          }
        : switch (scoreType.toUpperCase()) {
            'SAY' =>
              'Sayısal! Mühendislikten sağlığa geniş bir yelpazeye bakacağız.',
            'EA' => 'Eşit ağırlık! Hukuktan psikolojiye güzel seçenekler var.',
            'SÖZ' =>
              'Sözel! Edebiyattan iletişime, tarihten rehberliğe bakarız.',
            'DİL' =>
              'Dil! Mütercimlikten dil öğretmenliklerine birlikte bakarız.',
            'TYT' => 'TYT ile iki yıllık (önlisans) programlara bakacağız.',
            _ => null,
          };
    if (text == null) return null;
    return RobotMessage(
      'wizard.type.${scoreType.toUpperCase()}',
      text,
      RobotMood.happy,
    );
  }

  /// Sıralama girilince banda göre tepki; geçersiz sırada null.
  static RobotMessage? wizardRankReaction(int rank, String scoreType) {
    if (rank <= 0) return null;
    final r = formatRankTr(rank);
    final en = RobotScripts.isEn;
    final (id, text, mood) = switch (rank) {
      < 10000 => (
          'wizard.rank.top',
          en
              ? 'Wow, $r! With this rank the doors look wide open.'
              : 'Vay, $r! Bu sıralamayla kapılar sonuna kadar açık görünüyor.',
          RobotMood.celebrating,
        ),
      < 50000 => (
          'wizard.rank.strong',
          en
              ? '$r — noted! Looks like I can find you plenty of options.'
              : '$r — not ettim! Sana epey seçenek bulabilirim gibi görünüyor.',
          RobotMood.happy,
        ),
      < 150000 => (
          'wizard.rank.mid',
          en
              ? '$r, got it. With a balanced list, nice options will '
                  'come up.'
              : '$r, tamamdır. Dengeli bir liste kurarsak güzel seçenekler '
                  'çıkar.',
          RobotMood.happy,
        ),
      < 500000 => (
          'wizard.rank.wide',
          en
              ? "$r — noted. With realistic targets and a few surprises, "
                  "we'll build a fine list."
              : '$r — not ettim. Gerçekçi hedefler ve birkaç sürprizle güzel '
                  'bir liste kurarız.',
          RobotMood.happy,
        ),
      _ => (
          'wizard.rank.far',
          en
              ? "$r — let's find the safe options that fit you, okay?"
              : '$r — birlikte sana uygun güvenli seçenekleri bulalım, '
                  'tamam mı?',
          RobotMood.neutral,
        ),
    };
    return RobotMessage(id, text, mood);
  }

  // ── Sonuç ekranı ──

  static RobotMessage resultsSummary(ResultsContext ctx, {int? seed}) {
    final List<RobotScript> family;
    if (ctx.total == 0) {
      family = RobotScripts.resultsEmpty;
    } else if (ctx.guaranteed == 0 && ctx.dream > ctx.target) {
      family = RobotScripts.resultsRisky;
    } else if (ctx.dream == 0 && ctx.guaranteed > 0) {
      family = RobotScripts.resultsSafe;
    } else {
      family = RobotScripts.resultsBalanced;
    }
    final script = pick(family, seed: seed);
    var text = script.text
        .replaceAll('{total}', '${ctx.total}')
        .replaceAll('{guaranteed}', '${ctx.guaranteed}')
        .replaceAll('{target}', '${ctx.target}')
        .replaceAll('{dream}', '${ctx.dream}');
    if (ctx.usedEstimatedRank && ctx.total > 0) {
      text += RobotScripts.estimatedRankSuffix;
    }
    return RobotMessage(script.id, text, script.mood, action: script.action);
  }

  // ── Liste sağlığı ──

  /// analyzeListHealth ile aynı eşikler — rapor sayılarından yorum üretir.
  static RobotMessage listHealthComment(
    ListHealthReport report, {
    int? seed,
  }) {
    final rated = report.rated;
    final List<RobotScript> family;
    if (rated == 0) {
      family = RobotScripts.healthUnrated;
    } else if (report.guaranteed == 0 && rated + report.unrated >= 5) {
      family = RobotScripts.healthNoGuaranteed;
    } else if (report.dream * 2 > rated) {
      family = RobotScripts.healthTooRisky;
    } else if (report.guaranteed == rated && rated >= 3) {
      family = RobotScripts.healthTooSafe;
    } else {
      family = RobotScripts.healthBalanced;
    }
    return pick(family, seed: seed).toMessage();
  }

  // ── Bağlamsal anlar ──

  static RobotMessage emptyListNudge({int? seed, String? excludeId}) =>
      pick(RobotScripts.emptyList, seed: seed, excludeId: excludeId)
          .toMessage();

  static RobotMessage badgeCheer(String badgeId, {int? seed}) {
    final script = pick(RobotScripts.badgeCheer, seed: seed);
    // id rozete bağlanır — aynı kutlama analitikte rozetle eşleşsin.
    return RobotMessage(
      '${script.id}.$badgeId',
      script.text,
      script.mood,
    );
  }
}
