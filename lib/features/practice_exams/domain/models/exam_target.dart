/// Kullanıcının hedeflediği program. Sıra/puan hedefi elle yazılmaz; seçilen
/// programın son yıl tabanından türetilir, böylece hedef veriyle bağlantılı
/// kalır (bkz. `DepartmentScoreFallback.rankingForMatching`).
class ExamTarget {
  final String departmentId;
  final String departmentName;
  final String universityName;
  final String scoreType;

  /// Programın taban başarı sırası — asıl hedef çizgisi.
  final int? targetRank;

  /// Programın taban yerleştirme puanı.
  final double? targetScore;

  final DateTime setAt;

  const ExamTarget({
    required this.departmentId,
    required this.departmentName,
    required this.universityName,
    required this.scoreType,
    this.targetRank,
    this.targetScore,
    required this.setAt,
  });

  /// Hedefe göre kalan sıra. Pozitif → daha var, ≤0 → hedef aşıldı.
  /// Sıra bilgisi olmayan hedeflerde null.
  int? remainingRank(int? currentRank) {
    if (targetRank == null || currentRank == null) return null;
    return currentRank - targetRank!;
  }

  /// 0..1 arası ilerleme. [startRank] ilk denemenin sırası; hedefe doğru kat
  /// edilen yolun oranı. Referans yoksa null.
  double? progress({int? startRank, int? currentRank}) {
    if (targetRank == null || startRank == null || currentRank == null) {
      return null;
    }
    final distance = startRank - targetRank!;
    if (distance <= 0) return 1; // baştan hedefin içindeydi
    final covered = startRank - currentRank;
    return (covered / distance).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'departmentId': departmentId,
        'departmentName': departmentName,
        'universityName': universityName,
        'scoreType': scoreType,
        if (targetRank != null) 'targetRank': targetRank,
        if (targetScore != null) 'targetScore': targetScore,
        'setAt': setAt.toIso8601String(),
      };

  factory ExamTarget.fromJson(Map<String, dynamic> json) {
    return ExamTarget(
      departmentId: json['departmentId'] as String? ?? '',
      departmentName: json['departmentName'] as String? ?? '',
      universityName: json['universityName'] as String? ?? '',
      scoreType: json['scoreType'] as String? ?? '',
      targetRank: (json['targetRank'] as num?)?.toInt(),
      targetScore: (json['targetScore'] as num?)?.toDouble(),
      setAt: DateTime.tryParse(json['setAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
