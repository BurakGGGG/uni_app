/// Cloud Function'dan dönen Groq destekli zenginleştirme.
class RecommendationEnrichment {
  /// 2-3 cümle kişisel özet.
  final String summary;

  /// `{universityId}_{departmentId}` → kişisel reasoning.
  final Map<String, String> reasoningByKey;

  /// Cache'ten mi geldi (debug/log için).
  final bool cached;

  const RecommendationEnrichment({
    required this.summary,
    required this.reasoningByKey,
    required this.cached,
  });

  static String keyFor(String uniId, String deptId) => '${uniId}_$deptId';

  String? reasoningFor(String uniId, String deptId) =>
      reasoningByKey[keyFor(uniId, deptId)];

  factory RecommendationEnrichment.fromMap(Map<String, dynamic> map) {
    final items = (map['items'] as List?) ?? [];
    final reasoningMap = <String, String>{};
    for (final raw in items) {
      if (raw is! Map) continue;
      final m = raw.cast<String, dynamic>();
      final uni = m['universityId']?.toString();
      final dept = m['departmentId']?.toString();
      final reason = m['reasoning']?.toString();
      if (uni == null || dept == null || reason == null) continue;
      reasoningMap[keyFor(uni, dept)] = reason;
    }
    return RecommendationEnrichment(
      summary: map['summary']?.toString() ?? '',
      reasoningByKey: reasoningMap,
      cached: map['cached'] == true,
    );
  }
}
