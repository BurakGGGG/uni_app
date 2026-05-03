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

  /// Kısaltma ve alternatif isimler (ODTÜ, İTÜ vb.) — arama için
  final List<String> aliases;

  // YENİ alanlar
  final String? brandPrimaryHex;     // "#C00000"
  final String? brandSecondaryHex;   // "#7A0000"
  final bool brandUseDarkOverlay;    // açık logolar için true

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
    this.aliases = const [],
    this.brandPrimaryHex,
    this.brandSecondaryHex,
    this.brandUseDarkOverlay = false,
  });

  // YENİ getter — brand color'u döner
  Color? get brandColor {
    if (brandPrimaryHex == null) return null;
    return _hexToColor(brandPrimaryHex!);
  }

  // YENİ getter — hero gradient'i hazır olarak döner
  LinearGradient get heroGradient {
    if (brandPrimaryHex == null) {
      // Fallback: Default hero gradient if no brand colors are defined
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF333333), Color(0xFF111111)], // Placeholder until AppColors can be imported if needed, or fallback to dark.
      );
    }
    final primary = _hexToColor(brandPrimaryHex!);
    final secondary = brandSecondaryHex != null
        ? _hexToColor(brandSecondaryHex!)
        : _darken(primary, 0.25);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primary, secondary],
    );
  }

  // YENİ getter — logoyu local asset'ten yükle
  String get logoAssetPath => 'assets/logos/$id.png';

  static Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness * (1 - amount)).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

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
      aliases: List<String>.from(map['aliases'] ?? []),
      brandPrimaryHex: map['brandPrimaryHex'] as String?,
      brandSecondaryHex: map['brandSecondaryHex'] as String?,
      brandUseDarkOverlay: map['brandUseDarkOverlay'] ?? false,
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
      'aliases': aliases,
      if (brandPrimaryHex != null) 'brandPrimaryHex': brandPrimaryHex,
      if (brandSecondaryHex != null) 'brandSecondaryHex': brandSecondaryHex,
      'brandUseDarkOverlay': brandUseDarkOverlay,
    };
  }
}
