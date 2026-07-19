import '../../preference_wizard/domain/match_reason.dart';
import '../../score_calculator/domain/models/match_result.dart';
import 'robot_brain.dart';
import 'robot_enrichment.dart';
import 'robot_message.dart';

/// Sonuç özeti + kart notları — kaynak ne dönerse balon/kartlar onu gösterir.
class RobotResultsSummary {
  final RobotMessage message;

  /// `universityId_departmentId` → Üni'nin kişisel notu.
  /// Kural kaynağında hep boş; yalnız LLM kaynağı doldurur.
  final Map<String, String> notes;

  const RobotResultsSummary(this.message, {this.notes = const {}});
}

/// Faz 2 dikişi: sonuç özeti mesajının kaynağı. Kural tabanlı varsayılan;
/// Pro kullanıcılar için `enrichRecommendations` callable'ını saran LLM
/// kaynağı aynı arayüze takılır (mood'u yine kurallar belirler — LLM mood
/// seçmez). Balon UI'ı kaynaktan habersizdir.
abstract interface class RobotMessageSource {
  /// [topMatches] kural tabanlı kaynakta kullanılmaz; LLM kaynağı zenginleşme
  /// için en iyi eşleşmeleri sunucuya taşır.
  Future<RobotResultsSummary> resultsSummary(
    ResultsContext ctx, {
    List<UniversityMatch> topMatches,
  });
}

class RuleBasedMessageSource implements RobotMessageSource {
  const RuleBasedMessageSource();

  @override
  Future<RobotResultsSummary> resultsSummary(
    ResultsContext ctx, {
    List<UniversityMatch> topMatches = const [],
  }) async {
    return RobotResultsSummary(RobotBrain.resultsSummary(ctx));
  }
}

/// Faz 2: Pro kullanıcının balon metnini LLM özetiyle zenginleştirir ve ilk
/// önerilere "Üni'nin notu" ekler. Mood ve geri düşüş metni kurallardan
/// gelir; istemcinin her hatası (limit, abonelik, ağ) sessizce kural
/// metnine düşer — kullanıcı hiçbir kırılma görmez.
class LlmEnrichedMessageSource implements RobotMessageSource {
  final RobotEnrichmentClient _client;

  /// Sunucu en fazla bu kadar öneri kabul eder (enrich.ts MAX_INPUT_DEPTS).
  static const int _maxCandidates = 8;

  const LlmEnrichedMessageSource(this._client);

  @override
  Future<RobotResultsSummary> resultsSummary(
    ResultsContext ctx, {
    List<UniversityMatch> topMatches = const [],
  }) async {
    final rule = RobotBrain.resultsSummary(ctx);
    if (ctx.total == 0 || topMatches.isEmpty) {
      return RobotResultsSummary(rule);
    }
    try {
      final enriched = await _client.enrich(
        userTags: _tagsFor(ctx),
        candidates: [
          for (final m in topMatches.take(_maxCandidates)) _candidateFor(m),
        ],
      );
      final summary = enriched?.summary.trim() ?? '';
      if (summary.isEmpty) return RobotResultsSummary(rule);
      return RobotResultsSummary(
        RobotMessage('results.llm', summary, rule.mood, action: rule.action),
        notes: enriched!.notes,
      );
    } catch (_) {
      return RobotResultsSummary(rule);
    }
  }

  /// Sunucu anahtarları [a-zA-Z0-9_] ister — Türkçe karakter yalnız değerde.
  Map<String, String> _tagsFor(ResultsContext ctx) {
    final scoreType = ctx.scoreType;
    return {
      if (scoreType != null && scoreType.isNotEmpty) 'puan_turu': scoreType,
      if (ctx.rank != null) 'siralama': formatRankTr(ctx.rank!),
      if (ctx.usedEstimatedRank) 'siralama_notu': 'puandan tahmin edildi',
      'dagilim': '${ctx.guaranteed} yuksek sans / ${ctx.target} ulasilabilir'
          ' / ${ctx.dream} zorlayici',
    };
  }

  RobotEnrichCandidate _candidateFor(UniversityMatch m) {
    final ranking = m.departmentRanking;
    return RobotEnrichCandidate(
      departmentId: m.department.id,
      departmentName: m.department.name,
      universityId: m.university.id,
      universityName: m.university.name,
      totalScore: (m.fitScore ?? 0).toDouble(),
      reasons: [
        _categoryLabel(m.category),
        if (m.fitScore != null) 'uygunluk skoru %${m.fitScore}',
        if (ranking != null && ranking > 0)
          'taban sırası ${formatRankTr(ranking)}',
      ],
    );
  }

  static String _categoryLabel(MatchCategory c) {
    switch (c) {
      case MatchCategory.guaranteed:
        return 'yüksek şans';
      case MatchCategory.target:
        return 'ulaşılabilir';
      case MatchCategory.dream:
        return 'zorlayıcı';
    }
  }
}
