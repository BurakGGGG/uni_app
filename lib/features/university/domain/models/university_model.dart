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

  // Google Places place_id — canlı Google yorumları için (getGoogleReviews CF).
  // Places politikası gereği yalnızca place_id saklanır, yorum içeriği saklanmaz.
  final String? googlePlaceId;

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
    this.googlePlaceId,
  });

  // ── Tüm üniversiteler için logo-bazlı gradient fallback renkleri ──
  // Firestore'da brandPrimaryHex/brandSecondaryHex yoksa bu harita kullanılır.
  static const Map<String, List<String>> _brandColorFallback = {
    // ── İstanbul ──
    'itu':               ['#1A237E', '#283593'],  // Lacivert
    'istanbul_uni':      ['#1B5E20', '#2E7D32'],  // Yeşil
    'yildiz_teknik':     ['#FFB300', '#0D47A1'],  // Altın ve lacivert
    'marmara':           ['#0D47A1', '#1565C0'],  // Mavi
    'aydin':             ['#0D47A1', '#1565C0'],  // Lacivert
    'gelisim':           ['#1A237E', '#283593'],  // Koyu lacivert
    'medipol':           ['#1A237E', '#757575'],  // Lacivert ve gri
    // ── Ankara ──
    'odtu':              ['#D32F2F', '#EF5350'],  // Kırmızı beyaz
    'hacettepe':         ['#D32F2F', '#EF5350'],  // Kırmızı beyaz
    'ankara_uni':        ['#0D47A1', '#FFB300'],  // Lacivert altın
    'gazi':              ['#0D47A1', '#4DD0E1'],  // Lacivert açık turkuaz
    'hacibayram':        ['#212121', '#D32F2F'],  // Siyah kırmızı
    // ── İzmir ──
    'ege':               ['#0D47A1', '#1976D2'],  // Mavi
    'dokuz_eylul':       ['#1A237E', '#303F9F'],  // Lacivert
    'izmir_demokrasi':   ['#795548', '#C62828'],  // Açık kahve kırmızı
    'izmir_katipcelebi': ['#B71C1C', '#880E4F'],  // Koyu kırmızı
    // ── Antalya ──
    'akdeniz':           ['#E65100', '#FF6D00'],  // Turuncu
    'alanya':            ['#0277BD', '#039BE5'],  // Mavi
    // ── Eskişehir ──
    'anadolu':           ['#212121', '#424242'],  // Siyah
    'ogu':               ['#00ACC1', '#0D47A1'],  // Turkuaz lacivert
    'estu':              ['#800000', '#500000'],  // Bordomsu
    // ── Bursa ──
    'uludag':            ['#00ACC1', '#0D47A1'],  // Turkuaz lacivert
    'btu':               ['#0D47A1', '#1976D2'],  // Mavi
    // ── Çanakkale ──
    'comu':              ['#D32F2F', '#212121'],  // Kırmızı siyah beyaz
    // ── Sivas ──
    'cumhuriyet':        ['#D32F2F', '#B71C1C'],  // Kırmızı koyu kırmızı
    'sivas_btu':         ['#1A237E', '#283593'],  // Lacivert
    // ── Trabzon ──
    'ktu':               ['#1A237E', '#1565C0'],  // Lacivert-mavi
    'trabzon_uni':       ['#004D40', '#00695C'],  // Teal
    // ── Mersin ──
    'mersin_uni':        ['#E65100', '#FF8F00'],  // Turuncu
    'tarsus':            ['#1A237E', '#1976D2'],  // Mavi
    // ── Çorum ──
    'hitit':             ['#FF8F00', '#1A237E'],  // Turuncu koyu lacivert
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
    'beun':              ['#D32F2F', '#B71C1C'],  // Kırmızı
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

    // ── v2 yeni üniversiteler (logodan otomatik çıkarım) ──
    'adiyaman_uni':   ['#0072B6', '#005283'],  // Adıyaman Üniversitesi
    'aku':            ['#005E9D', '#004371'],  // Afyon Kocatepe Üniversitesi
    'aksaray_uni':    ['#167DBC', '#0F5A87'],  // Aksaray Üniversitesi
    'amasya_uni':     ['#E42317', '#099844'],  // Amasya Üniversitesi
    'asbu':           ['#752645', '#E4C4A8'],  // Ankara Sosyal Bilimler Üniversitesi
    'aybu':           ['#00C0D8', '#002E78'],  // Ankara Yıldırım Beyazıt Üniversitesi
    'acu':            ['#1F793B', '#16572A'],  // Artvin Çoruh Üniversitesi
    'atilim':         ['#233574', '#F20410'],  // Atılım Üniversitesi
    'adu':            ['#2A388E', '#1E2866'],  // Aydın Adnan Menderes Üniversitesi
    'bahcesehir':     ['#03519F', '#023A72'],  // Bahçeşehir Üniversitesi
    'balikesir_uni':  ['#0C8C88', '#086461'],  // Balıkesir Üniversitesi
    'baskent':        ['#DE2027', '#9F171C'],  // Başkent Üniversitesi
    'bingol_uni':     ['#93CAEC', '#F2823E'],  // Bingöl Üniversitesi
    'bitlis_eren':    ['#0BAFC7', '#077E8F'],  // Bitlis Eren Üniversitesi
    'bogazici':       ['#134A8F', '#0D3566'],  // Boğaziçi Üniversitesi
    'maku':           ['#3A2666', '#291B49'],  // Burdur Mehmet Akif Ersoy Üniversitesi
    'dicle':          ['#E2B241', '#A2802E'],  // Dicle Üniversitesi
    'duzce_uni':      ['#003B74', '#002A53'],  // Düzce Üniversitesi
    'ebyu':           ['#273970', '#9A8245'],  // Erzincan Binali Yıldırım Üniversitesi
    'firat':          ['#821342', '#5D0D2F'],  // Fırat Üniversitesi
    'galatasaray':    ['#F6C21D', '#A20807'],  // Galatasaray Üniversitesi
    'giresun_uni':    ['#111A9E', '#1C9605'],  // Giresun Üniversitesi
    'gumushane_uni':  ['#D0092C', '#95061F'],  // Gümüşhane Üniversitesi
    'harran':         ['#E0D000', '#1579AE'],  // Harran Üniversitesi
    'mku':            ['#99161B', '#D89A59'],  // Hatay Mustafa Kemal Üniversitesi
    'isubu':          ['#22499A', '#6AC9C9'],  // Isparta Uygulamalı Bilimler Üniversitesi
    'kadir_has':      ['#065494', '#043C6A'],  // Kadir Has Üniversitesi
    'kafkas':         ['#00B3C1', '#174395'],  // Kafkas Üniversitesi
    'kastamonu_uni':  ['#D44143', '#352838'],  // Kastamonu Üniversitesi
    'koc':            ['#AE162B', '#7D0F1E'],  // Koç Üniversitesi
    'klu':            ['#0E437B', '#0A3058'],  // Kırklareli Üniversitesi
    'kku':            ['#2168B2', '#ED2129'],  // Kırıkkale Üniversitesi
    'kaeu':           ['#004FA1', '#56AF27'],  // Kırşehir Ahi Evran Üniversitesi
    'artuklu':        ['#901860', '#671145'],  // Mardin Artuklu Üniversitesi
    'msgsu':          ['#050390', '#030267'],  // Mimar Sinan Güzel Sanatlar Üniversitesi
    'msku':           ['#2C318D', '#990F26'],  // Muğla Sıtkı Koçman Üniversitesi
    'erbakan':        ['#305A8B', '#224064'],  // Necmettin Erbakan Üniversitesi
    'nevu':           ['#B62C2D', '#E4A73F'],  // Nevşehir Hacı Bektaş Veli Üniversitesi
    'ohu':            ['#0091A7', '#006878'],  // Niğde Ömer Halisdemir Üniversitesi
    'sabanci':        ['#004288', '#002F61'],  // Sabancı Üniversitesi
    'subu':           ['#003BAB', '#009F4E'],  // Sakarya Uygulamalı Bilimler Üniversitesi
    'sbu':            ['#295075', '#862A46'],  // Sağlık Bilimleri Üniversitesi
    'tobb_etu':       ['#1B47A1', '#F38B21'],  // TOBB Ekonomi ve Teknoloji Üniversitesi
    'nku':            ['#000EA0', '#000A73'],  // Tekirdağ Namık Kemal Üniversitesi
    'trakya':         ['#D1A348', '#22388D'],  // Trakya Üniversitesi
    'turk_alman':     ['#86CAD6', '#292C37'],  // Türk-Alman Üniversitesi
    'yasar':          ['#00519B', '#003A6F'],  // Yaşar Üniversitesi
    'yeditepe':       ['#005296', '#009145'],  // Yeditepe Üniversitesi
    'yobu':           ['#E11A1E', '#F6B7B6'],  // Yozgat Bozok Üniversitesi
    'ozyegin':        ['#004B93', '#CE0068'],  // Özyeğin Üniversitesi
    'bilkent':        ['#678FBE', '#E2081D'],  // İhsan Doğramacı Bilkent Üniversitesi
    'bilgi':          ['#DA2D2A', '#C13E40'],  // İstanbul Bilgi Üniversitesi
    'iuc':            ['#10243D', '#AB8D3F'],  // İstanbul Üniversitesi-Cerrahpaşa
    'izmir_ekonomi':  ['#FF7100', '#B75100'],  // İzmir Ekonomi Üniversitesi
    'iyte':           ['#920213', '#69010D'],  // İzmir Yüksek Teknoloji Enstitüsü
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
      googlePlaceId: map['googlePlaceId'] as String?,
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
      if (googlePlaceId != null) 'googlePlaceId': googlePlaceId,
    };
  }
}
