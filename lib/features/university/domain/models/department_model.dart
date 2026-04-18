class DepartmentModel {
  final String id;
  final String universityId;
  final String name;
  final String faculty; // Fakülte / Yüksekokul
  final String type; // "Lisans" veya "Önlisans"
  final String language; // "Türkçe" veya "İngilizce"
  final double? baseScore; // ÖSYM taban puanı
  final int? ranking; // Sıralama
  final String? scoreType; // SAY, EA, SÖZ, DİL, TYT
  final int duration; // Yıl (2 veya 4+)
  final int? quota; // Kontenjan

  // ── Sprint 3 — Yorum Sistemi İçin Rating Alanları ──────────────
  final double avgRating;
  final int reviewCount;
  /// Kategori bazlı ortalama puanlar (eğitim kalitesi, hoca, iş imkanı, staj, ders yükü)
  final Map<String, double> categoryRatings;

  DepartmentModel({
    required this.id,
    required this.universityId,
    required this.name,
    required this.faculty,
    required this.type,
    required this.language,
    this.baseScore,
    this.ranking,
    this.scoreType,
    this.duration = 4,
    this.quota,
    this.avgRating = 0.0,
    this.reviewCount = 0,
    this.categoryRatings = const {},
  });

  factory DepartmentModel.fromMap(Map<String, dynamic> map, String id) {
    return DepartmentModel(
      id: id,
      universityId: map['universityId'] ?? '',
      name: map['name'] ?? '',
      faculty: map['faculty'] ?? '',
      type: map['type'] ?? '',
      language: map['language'] ?? 'Türkçe',
      baseScore: (map['baseScore'] as num?)?.toDouble(),
      ranking: map['ranking'] as int?,
      scoreType: map['scoreType'] as String?,
      duration: map['duration'] ?? (map['type'] == 'Önlisans' ? 2 : 4),
      quota: map['quota'] as int?,
      avgRating: (map['avgRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      categoryRatings: Map<String, double>.from(
        (map['categoryRatings'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ) ?? {},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'universityId': universityId,
      'name': name,
      'faculty': faculty,
      'type': type,
      'language': language,
      'baseScore': baseScore,
      'ranking': ranking,
      'scoreType': scoreType,
      'duration': duration,
      'quota': quota,
      'avgRating': avgRating,
      'reviewCount': reviewCount,
      'categoryRatings': categoryRatings,
    };
  }
}
