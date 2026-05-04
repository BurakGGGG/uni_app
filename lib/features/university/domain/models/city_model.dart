import 'package:flutter/material.dart';

class CityModel {
  final String id;
  final String name;
  final String plateCode;
  final String photoUrl;
  final int totalUniversityCount;
  final int appUniversityCount;
  final String? brandPrimaryHex;
  final String? brandSecondaryHex;
  final bool brandUseDarkOverlay;

  const CityModel({
    required this.id,
    required this.name,
    required this.plateCode,
    required this.photoUrl,
    required this.totalUniversityCount,
    required this.appUniversityCount,
    this.brandPrimaryHex,
    this.brandSecondaryHex,
    this.brandUseDarkOverlay = false,
  });

  // ─── Brand Color API (UniversityModel ile simetrik) ─────────────

  Color get brandPrimary {
    if (brandPrimaryHex == null) return const Color(0xFF6C63FF); // AppColors.primary fallback
    return _hexToColor(brandPrimaryHex!);
  }

  Color get brandSecondary {
    if (brandSecondaryHex == null) return _darken(brandPrimary, 0.25);
    return _hexToColor(brandSecondaryHex!);
  }

  LinearGradient get brandGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [brandPrimary, brandSecondary],
      );

  /// Kart yüzeyi için hafif saydam versiyon
  LinearGradient get surfaceGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          brandPrimary.withValues(alpha: 0.12),
          brandSecondary.withValues(alpha: 0.06),
        ],
      );

  /// Logo + isim sertifikalı bir küçük chip (üni sayısı vs.)
  LinearGradient get accentBadgeGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          brandPrimary.withValues(alpha: 0.92),
          brandSecondary.withValues(alpha: 0.92),
        ],
      );

  /// Hero detail sayfası için dark/koyu overlay'li gradient
  LinearGradient get heroOverlayGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          brandPrimary.withValues(alpha: 0.6),
          _darken(brandPrimary, 0.4).withValues(alpha: 0.95),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

  String get logoAssetPath => 'assets/city_logos/$id.png';

  // ─── Firestore Serialization ─────────────────────────────────────

  factory CityModel.fromMap(Map<String, dynamic> map, String id) {
    return CityModel(
      id: id,
      name: map['name'] ?? '',
      plateCode: map['plateCode'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      totalUniversityCount: map['totalUniversityCount'] ?? 0,
      appUniversityCount: map['appUniversityCount'] ?? 0,
      brandPrimaryHex: map['brandPrimaryHex'] as String?,
      brandSecondaryHex: map['brandSecondaryHex'] as String?,
      brandUseDarkOverlay: map['brandUseDarkOverlay'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'plateCode': plateCode,
        'photoUrl': photoUrl,
        'totalUniversityCount': totalUniversityCount,
        'appUniversityCount': appUniversityCount,
        if (brandPrimaryHex != null) 'brandPrimaryHex': brandPrimaryHex,
        if (brandSecondaryHex != null) 'brandSecondaryHex': brandSecondaryHex,
        'brandUseDarkOverlay': brandUseDarkOverlay,
      };

  // ─── Private Helpers ─────────────────────────────────────────────

  static Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness * (1 - amount)).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}
