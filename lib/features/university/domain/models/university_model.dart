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

  // ── Sprint 11 (6.4) — Place sayım denormalizasyonu ──
  // Cloud Function `recomputePlaceCount` trigger'ı tarafından güncellenir.
  // null ise client tarafı eski yöntemle (PlaceRepository) fallback yapar.
  final int? placeCount;
  final Map<String, int>? placeBreakdown;

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
    this.placeCount,
    this.placeBreakdown,
  });

  // ── Tüm üniversiteler için logo-bazlı gradient fallback renkleri ──
  // Firestore'da brandPrimaryHex/brandSecondaryHex yoksa bu harita kullanılır.
  static const Map<String, List<String>> _brandColorFallback = {
    // ── İstanbul ──
    'itu':               ['#1A237E', '#283593'],  // Lacivert
    'istanbul_uni':      ['#8B0000', '#B22222'],  // Bordo
    'yildiz_teknik':     ['#1B5E20', '#2E7D32'],  // Koyu yeşil
    'marmara':           ['#0D47A1', '#1565C0'],  // Mavi
    'aydin':             ['#4A148C', '#6A1B9A'],  // Mor
    'gelisim':           ['#E65100', '#F57C00'],  // Turuncu
    'medipol':           ['#B71C1C', '#D32F2F'],  // Kırmızı
    // ── Ankara ──
    'odtu':              ['#1A237E', '#0D47A1'],  // Lacivert
    'hacettepe':         ['#F57F17', '#FBC02D'],  // Sarı-turuncu
    'ankara_uni':        ['#1B5E20', '#388E3C'],  // Yeşil
    'gazi':              ['#B71C1C', '#D32F2F'],  // Kırmızı
    'hacibayram':        ['#4A148C', '#7B1FA2'],  // Mor
    // ── İzmir ──
    'ege':               ['#0D47A1', '#1976D2'],  // Mavi
    'dokuz_eylul':       ['#1A237E', '#303F9F'],  // Lacivert
    'izmir_demokrasi':   ['#00695C', '#00897B'],  // Teal
    'izmir_katipcelebi': ['#1565C0', '#42A5F5'],  // Açık mavi
    // ── Antalya ──
    'akdeniz':           ['#E65100', '#FF6D00'],  // Turuncu
    'alanya':            ['#0277BD', '#039BE5'],  // Mavi
    // ── Eskişehir ──
    'anadolu':           ['#1A237E', '#3949AB'],  // Lacivert
    'ogu':               ['#B71C1C', '#E53935'],  // Kırmızı
    'estu':              ['#004D40', '#00796B'],  // Koyu teal
    // ── Bursa ──
    'uludag':            ['#1B5E20', '#43A047'],  // Yeşil
    'btu':               ['#0D47A1', '#1976D2'],  // Mavi
    // ── Çanakkale ──
    'comu':              ['#BF360C', '#E64A19'],  // Koyu turuncu
    // ── Sivas ──
    'cumhuriyet':        ['#880E4F', '#AD1457'],  // Bordo-pembe
    'sivas_btu':         ['#1A237E', '#283593'],  // Lacivert
    // ── Trabzon ──
    'ktu':               ['#1A237E', '#1565C0'],  // Lacivert-mavi
    'trabzon_uni':       ['#004D40', '#00695C'],  // Teal
    // ── Mersin ──
    'mersin_uni':        ['#E65100', '#FF8F00'],  // Turuncu
    'tarsus':            ['#1A237E', '#1976D2'],  // Mavi
    // ── Çorum ──
    'hitit':             ['#4E342E', '#6D4C41'],  // Kahve
    // ── Kayseri ──
    'erciyes':           ['#1A3C8F', '#C41E3A'],  // Mavi → Kırmızı
    // ── Malatya ──
    'inonu':             ['#F5A623', '#C88B18'],  // Altın sarısı
    // ── Samsun ──
    'omu':               ['#3B5998', '#C0392B'],  // Mavi → Kırmızı
    // ── Konya ──
    'selcuk':            ['#D4A817', '#8B7312'],  // Altın kartal
    // ── Kütahya ──
    'dpu':               ['#3D348B', '#6A5ACD'],  // Mor/Lacivert
    // ── Kocaeli ──
    'kocaeli':           ['#1B9E5F', '#2C3E50'],  // Yeşil → Lacivert
    // ── Sakarya ──
    'sakarya':           ['#1A3478', '#2C5AA0'],  // Lacivert
    // ── Bolu ──
    'ibu':               ['#1B7A3D', '#2E4C8A'],  // Yeşil → Lacivert
    // ── Zonguldak ──
    'beun':              ['#D42B2B', '#2E7D32'],  // Kırmızı → Yeşil
    // ── Van ──
    'yyu':               ['#1A5276', '#5DADE2'],  // Koyu mavi → Açık mavi
    // ── Erzurum ──
    'atauni':            ['#2E3A6E', '#C9A94E'],  // Lacivert → Altın
    // ── Gaziantep ──
    'gantep':            ['#1A2D5A', '#C0392B'],  // Lacivert → Kırmızı
    // ── Adana ──
    'cu':                ['#1E7B2C', '#0E5C1E'],  // Yeşil tonları
    // ── Denizli ──
    'pau':               ['#1A4C7A', '#4A90D9'],  // İki ton mavi
    // ── Kahramanmaraş ──
    'ksu':               ['#343278', '#C0392B'],  // Mor → Kırmızı
    // ── Manisa ──
    'cbu':               ['#1A3478', '#4DC4E0'],  // Lacivert → Açık mavi
    // ── Isparta ──
    'sdu':               ['#D42B2B', '#8B1A1A'],  // Kırmızı tonları
    // ── Karabük ──
    'karabuk':           ['#3B6FA0', '#C0392B'],  // Mavi → Kırmızı
    // ── Tokat ──
    'gop':               ['#008B8B', '#4A1558'],  // Teal → Mor
  };

  /// Firestore veya fallback'ten primary hex rengi döner.
  String? get _effectivePrimaryHex =>
      brandPrimaryHex ?? _brandColorFallback[id]?[0];

  /// Firestore veya fallback'ten secondary hex rengi döner.
  String? get _effectiveSecondaryHex =>
      brandSecondaryHex ?? _brandColorFallback[id]?[1];

  // Brand color getter — Firestore veya fallback'i kullanır
  Color? get brandColor {
    final hex = _effectivePrimaryHex;
    if (hex == null) return null;
    return _hexToColor(hex);
  }

  // Hero gradient getter — Firestore veya fallback'i kullanır
  LinearGradient get heroGradient {
    final primaryHex = _effectivePrimaryHex;
    if (primaryHex == null) {
      // Son çare: koyu fallback
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF333333), Color(0xFF111111)],
      );
    }
    final primary = _hexToColor(primaryHex);
    final secondaryHex = _effectiveSecondaryHex;
    final secondary = secondaryHex != null
        ? _hexToColor(secondaryHex)
        : _darken(primary, 0.25);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primary, secondary],
    );
  }

  // Logoyu local asset'ten yükle
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
      placeCount: (map['placeCount'] as num?)?.toInt(),
      placeBreakdown: (map['placeBreakdown'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
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
      'aliases': aliases,
      if (brandPrimaryHex != null) 'brandPrimaryHex': brandPrimaryHex,
      if (brandSecondaryHex != null) 'brandSecondaryHex': brandSecondaryHex,
      'brandUseDarkOverlay': brandUseDarkOverlay,
      if (placeCount != null) 'placeCount': placeCount,
      if (placeBreakdown != null) 'placeBreakdown': placeBreakdown,
    };
  }
}
