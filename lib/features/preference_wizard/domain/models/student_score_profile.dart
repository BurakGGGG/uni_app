/// Öğrencinin kalıcı puan/sıralama profili.
///
/// Puan Hesaplayıcı sonucundan ya da Tercih Robotu "Hızlı giriş" ekranından
/// oluşturulur ve `shared_preferences`'ta saklanır. App genelinde uygunluk
/// rozeti (Garanti/Hedef/Riskli) ve tercih robotu eşleştirmesi bu profili
/// referans alır.
class StudentScoreProfile {
  /// Puan türü: 'TYT', 'SAY', 'EA', 'SÖZ', 'DİL'
  final String scoreType;

  /// Yerleştirme puanı (ham + OBP katkısı).
  final double placementScore;

  /// Başarı sıralaması. Öğrenci girmemişse null — bu durumda eşleştirme
  /// yalnızca puan-bazlı çalışır.
  final int? rank;

  /// Diploma notu ortalaması (OBP), 0-100.
  final double obp;

  /// Profilin ait olduğu YKS yılı (ör. 2025).
  final int year;

  final DateTime updatedAt;

  const StudentScoreProfile({
    required this.scoreType,
    required this.placementScore,
    this.rank,
    this.obp = 0,
    required this.year,
    required this.updatedAt,
  });

  bool get hasRank => rank != null && rank! > 0;

  StudentScoreProfile copyWith({
    String? scoreType,
    double? placementScore,
    int? rank,
    bool clearRank = false,
    double? obp,
    int? year,
    DateTime? updatedAt,
  }) {
    return StudentScoreProfile(
      scoreType: scoreType ?? this.scoreType,
      placementScore: placementScore ?? this.placementScore,
      rank: clearRank ? null : (rank ?? this.rank),
      obp: obp ?? this.obp,
      year: year ?? this.year,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'scoreType': scoreType,
        'placementScore': placementScore,
        if (rank != null) 'rank': rank,
        'obp': obp,
        'year': year,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory StudentScoreProfile.fromJson(Map<String, dynamic> json) {
    return StudentScoreProfile(
      scoreType: json['scoreType'] as String? ?? '',
      placementScore: (json['placementScore'] as num?)?.toDouble() ?? 0,
      rank: (json['rank'] as num?)?.toInt(),
      obp: (json['obp'] as num?)?.toDouble() ?? 0,
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
