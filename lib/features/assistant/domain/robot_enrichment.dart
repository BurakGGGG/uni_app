/// Faz 2 — LLM zenginleştirme sözleşmesi (saf Dart, ağ yok).
///
/// Sunucudaki `enrichRecommendations` callable'ının istemci tarafı tipleri:
/// giriş adayları ([RobotEnrichCandidate]) ve dönen özet + kart notları
/// ([RobotEnrichment]). Ağ işini data katmanındaki servis yapar; testler
/// [RobotEnrichmentClient]'ı sahteleyerek kaynağı headless doğrular.
library;

/// Sunucuya taşınan tek öneri — `enrich.ts` InputDept alanlarıyla birebir.
class RobotEnrichCandidate {
  final String departmentId;
  final String departmentName;
  final String universityId;
  final String universityName;
  final double totalScore;

  /// LLM'e verilen kısa sinyaller (kategori, uygunluk, taban sırası…).
  final List<String> reasons;

  const RobotEnrichCandidate({
    required this.departmentId,
    required this.departmentName,
    required this.universityId,
    required this.universityName,
    required this.totalScore,
    this.reasons = const [],
  });
}

/// LLM'den dönen zenginleştirme.
class RobotEnrichment {
  /// Balon metni olacak 1-2 cümlelik özet.
  final String summary;

  /// `universityId_departmentId` → ilk 3 öneri kartına kişisel not.
  final Map<String, String> notes;

  const RobotEnrichment({required this.summary, this.notes = const {}});
}

/// Ağ istemcisi dikişi. Data katmanı Cloud Function ile uygular;
/// her başarısızlıkta (limit, abonelik, ağ) null döner — kaynak sessizce
/// kural metnine düşer, kullanıcı hiçbir şey fark etmez.
abstract interface class RobotEnrichmentClient {
  Future<RobotEnrichment?> enrich({
    required Map<String, String> userTags,
    required List<RobotEnrichCandidate> candidates,
  });
}
