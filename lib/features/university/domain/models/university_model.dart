import 'package:flutter/material.dart';

enum CampusLayout {
  campus, block, distributed;

  String get label {
    switch (this) {
      case CampusLayout.campus: return 'Kampüslü';
      case CampusLayout.block: return 'Blok Yerleşke';
      case CampusLayout.distributed: return 'Dağınık Kampüs';
    }
  }

  IconData get icon {
    switch (this) {
      case CampusLayout.campus: return Icons.location_city_rounded;
      case CampusLayout.block: return Icons.apartment_rounded;
      case CampusLayout.distributed: return Icons.scatter_plot_rounded;
    }
  }

  static CampusLayout fromString(String? value) {
    switch (value) {
      case 'campus': return CampusLayout.campus;
      case 'block': return CampusLayout.block;
      case 'distributed': return CampusLayout.distributed;
      default: return CampusLayout.campus;
    }
  }
}

class UniversityModel {
  final String id;
  final String cityId; // Şehrin plaka kodu veya ID'si
  final String name;
  final String type; // "Devlet" veya "Vakıf"
  final bool hasCampus; // Kampüslü mü?
  final CampusLayout campusLayout; // Sprint 4: kampüs yerleşim tipi
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
    this.campusLayout = CampusLayout.campus,
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
      campusLayout: CampusLayout.fromString(map['campusLayout']),
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
      'campusLayout': campusLayout.name,
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
