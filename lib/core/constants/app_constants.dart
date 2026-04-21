/// ÜniSeç uygulama sabitleri
class AppConstants {
  AppConstants._();

  // ─── Uygulama Bilgileri ───────────────────────────────────────────
  static const String appName = 'ÜniSeç';
  static const String appTagline = 'Hayalindeki üniversiteyi keşfet';
  static const String appVersion = '1.0.0';

  // ─── Spacing ──────────────────────────────────────────────────────
  static const double spacingXxs = 2;
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 20;
  static const double spacingXxl = 24;
  static const double spacingXxxl = 32;
  static const double spacingHuge = 40;
  static const double spacingMassive = 48;

  // ─── Border Radius ────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 24;
  static const double radiusFull = 100;

  // ─── Icon Sizes ───────────────────────────────────────────────────
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 28;
  static const double iconXxl = 32;
  static const double iconHuge = 48;

  // ─── Animation Durations ──────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animVerySlow = Duration(milliseconds: 800);

  // ─── Pagination ───────────────────────────────────────────────────
  static const int pageSize = 20;
  static const int reviewsPageSize = 10;

  // ─── Image Sizes ──────────────────────────────────────────────────
  static const double avatarSm = 32;
  static const double avatarMd = 40;
  static const double avatarLg = 56;
  static const double avatarXl = 80;

  // ─── Rating Categories ────────────────────────────────────────────
  static const List<String> uniRatingCategories = [
    'Kampüs Yaşamı',
    'Eğitim Kalitesi',
    'Sosyal Hayat',
    'Ulaşım',
    'Yemek',
    'Yurt',
  ];

  static const List<String> deptRatingCategories = [
    'Eğitim Kalitesi',
    'Hoca Kalitesi',
    'İş İmkanı',
    'Staj Olanağı',
    'Ders Yükü',
  ];

  static const List<String> placeRatingCategories = [
    'Ortam',
    'Fiyat',
    'Temizlik',
    'Hizmet',
  ];

  // ─── Score Types ──────────────────────────────────────────────────
  static const List<String> scoreTypes = ['SAY', 'EA', 'SÖZ', 'DİL', 'TYT'];

  // ─── University Types ─────────────────────────────────────────────
  static const List<String> universityTypes = ['Devlet', 'Vakıf'];

  // ─── Place Types ──────────────────────────────────────────────────
  static const Map<String, String> placeTypeLabels = {
    'cafe': 'Kafe',
    'dorm': 'Yurt',
    'study_area': 'Çalışma Alanı',
    'library': 'Kütüphane',
    'sports': 'Spor Tesisi',
  };

  // ─── Price Range ──────────────────────────────────────────────────
  static const Map<String, String> priceRangeLabels = {
    '₺': 'Uygun',
    '₺₺': 'Orta',
    '₺₺₺': 'Pahalı',
  };

  // ─── Review Preset: Artılar & Eksiler ──────────────────────────
  static const List<String> commonUniPros = [
    'Geniş kampüs',
    'Kaliteli hocalar',
    'Aktif sosyal hayat',
    'İyi kütüphane',
    'Güvenli ortam',
    'Güçlü mezun ağı',
    'Modern tesisler',
    'Bol öğrenci indirimi',
  ];

  static const List<String> commonUniCons = [
    'Ulaşım zor',
    'Yemekhane pahalı',
    'Az sosyal aktivite',
    'Kalabalık sınıflar',
    'Yetersiz yurt',
    'Bürokratik işlemler',
    'Eski binalar',
  ];

  static const List<String> commonDeptPros = [
    'Deneyimli akademisyenler',
    'Güncel müfredat',
    'İyi staj imkanları',
    'Güçlü mezun kariyeri',
    'Araştırma fırsatları',
  ];

  static const List<String> commonDeptCons = [
    'Ağır ders yükü',
    'Uygulamalı ders az',
    'Zor sınavlar',
    'Az seçmeli ders',
  ];
}
