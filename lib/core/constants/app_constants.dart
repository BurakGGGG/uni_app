/// ÜniSeç uygulama sabitleri
class AppConstants {
  AppConstants._();

  // ─── Uygulama Bilgileri ───────────────────────────────────────────
  static const String appName = 'ÜniSeç';
  static const String appTagline = 'Üniversite Yaşam Rehberin';

  /// pubspec.yaml `version` alanıyla birlikte güncellenmeli —
  /// force update kontrolü ve ayarlar ekranı bu değeri kullanır.
  static const String appVersion = '1.0.1';

  /// Firebase Google Sign-In web client ID (google-services.json client_type: 3)
  static const String googleWebClientId =
      '267910282750-5h0rqqnnckgsahuja1amrua5ai0g5d8r.apps.googleusercontent.com';

  /// Son başarılı giriş yapan kullanıcı (Firebase persistence yedek kontrolü)
  static const String persistedAuthUidKey = 'persisted_auth_uid';

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

  // ─── Sprint 4 — Place Yorumu İçin Artılar & Eksiler ─────────────
  // Genel (fallback)
  static const List<String> placePros = [
    'Sessiz', 'Geniş', 'Hızlı Wi-Fi', 'Bol Priz', 'Temiz', 'Güvenli',
    'Açık 7/24', 'Manzaralı', 'Ferah Atmosfer', 'Uygun Fiyat',
    'Kampüse Yakın', 'Çalışmaya Uygun',
  ];

  static const List<String> placeCons = [
    'Kalabalık', 'Pahalı', 'Gürültülü', 'Soğuk',
    'Az Priz', 'Yetersiz Wi-Fi', 'Kötü Konum', 'Az Yer',
  ];

  // ─── Kafe Artılar & Eksiler ───────────────────────────────────────
  static const List<String> cafePros = [
    'Lezzetli Kahve', 'Geniş Menü', 'Çalışmaya Uygun', 'Uygun Fiyat',
    'Hızlı Wi-Fi', 'Bol Priz', 'Sessiz', 'Ferah Atmosfer',
    'Grup Çalışması İçin İdeal', 'Manzaralı', 'Geniş Alan',
    'Güler Yüzlü Personel', 'Temiz', 'Kampüse Yakın',
  ];

  static const List<String> cafeCons = [
    'Pahalı', 'Kalabalık', 'Yavaş Servis', 'Bekleme Süresi Uzun',
    'Sınırlı Menü', 'Gürültülü', 'Az Priz', 'Yetersiz Wi-Fi',
    'Küçük Alan', 'Soğuk', 'Kötü Konum',
  ];

  // ─── Yurt Artılar & Eksiler ───────────────────────────────────────
  static const List<String> dormPros = [
    'Kampüse Yakın', 'Modern Tesis', 'Sıcak Yemek', 'Çamaşırhane',
    'Temiz', 'Güvenli', 'Hızlı Wi-Fi', 'Uygun Fiyat',
    'Sessiz', 'Otopark', 'Spor Salonu', 'Çalışma Odası',
    'Sosyal Alan', '7/24 Sıcak Su',
  ];

  static const List<String> dormCons = [
    'Eski Tesis', 'Sınırlı Kontenjan', 'Yemekler Vasat', 'Kalabalık',
    'Gürültülü', 'Yetersiz Wi-Fi', 'Küçük Odalar', 'Temizlik Sorunu',
    'Kampüse Uzak', 'Ulaşım Sorunu', 'Sıcak Su Sorunu', 'Böcek Problemi',
  ];

  // ─── Kütüphane Artılar & Eksiler ──────────────────────────────────
  static const List<String> libraryPros = [
    'Sessiz Çalışma Salonu', 'Grup Odası', 'Geniş Koleksiyon',
    'Bol Priz', 'Hızlı Wi-Fi', 'Ferah Atmosfer', 'Temiz',
    'Geniş Alan', 'Açık 7/24', 'Klimalı', 'Kampüse Yakın',
    'Çalışmaya Uygun', 'Bilgisayar Salonu',
  ];

  static const List<String> libraryCons = [
    'Yer Bulmak Zor', 'Sessizlik İhlal Ediliyor', 'Kısıtlı Saatler',
    'Kalabalık', 'Yetersiz Wi-Fi', 'Az Priz', 'Soğuk',
    'Eski Kitaplar', 'Küçük Alan', 'Sınırlı Oturma',
  ];
}
