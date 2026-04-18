class UniversityModel {
  final String id;
  final String cityId; // Şehrin plaka kodu veya ID'si
  final String name;
  final String type; // "Devlet" veya "Vakıf"
  final bool hasCampus; // Kampüslü mü?
  final String logoUrl;
  final String photoUrl;
  final String description;
  final int establishedYear;
  final String website;

  // ── Sprint 3 — Yorum Sistemi İçin Rating Alanları ──────────────
  final double avgRating;
  final int reviewCount;
  /// Kategori bazlı ortalama puanlar (kampüs, eğitim, sosyal, ulaşım, yemek, yurt)
  final Map<String, double> categoryRatings;

  UniversityModel({
    required this.id,
    required this.cityId,
    required this.name,
    required this.type,
    required this.hasCampus,
    required this.logoUrl,
    required this.photoUrl,
    required this.description,
    required this.establishedYear,
    required this.website,
    this.avgRating = 0.0,
    this.reviewCount = 0,
    this.categoryRatings = const {},
  });

  factory UniversityModel.fromMap(Map<String, dynamic> map, String id) {
    return UniversityModel(
      id: id,
      cityId: map['cityId'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      hasCampus: map['hasCampus'] ?? true,
      logoUrl: map['logoUrl'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      description: map['description'] ?? '',
      establishedYear: map['establishedYear'] ?? 0,
      website: map['website'] ?? '',
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
      'cityId': cityId,
      'name': name,
      'type': type,
      'hasCampus': hasCampus,
      'logoUrl': logoUrl,
      'photoUrl': photoUrl,
      'description': description,
      'establishedYear': establishedYear,
      'website': website,
      'avgRating': avgRating,
      'reviewCount': reviewCount,
      'categoryRatings': categoryRatings,
    };
  }
}
