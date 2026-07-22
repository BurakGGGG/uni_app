import '../../preference_wizard/domain/similar_programs.dart';

/// "En iyi X bölümleri" için kaba alan katmanı.
///
/// Sihirbazın [interestAreas] listesi (25 küratörlü aile) zaten var ama dar:
/// "Bilgisayar / Yazılım" var, "Mühendislik" yok. Bu katman onların üstüne
/// kullanıcının sorduğu genişlikte (~11) bir alan tanımı koyar.
///
/// İki sinyal birlikte kullanılır çünkü [interestAreas] küratörlü bir BEYAZ
/// LİSTEDİR ve veri setindeki 119 lisans adının hepsini kapsamaz:
///   1. [interestKeys] — küratörlü ailelerin normalize adları (kesin eşleşme),
///   2. [nameContains] — normalize ad üzerinde alt dize kuralı (kalanı yakalar).
/// Bir ad birden fazla alana düşebilir (ör. "görsel iletişim tasarımı" hem
/// Tasarım hem İletişim); liste ekranı bunu sorun etmez.
///
/// `program_category_test.dart` asset'teki her lisans adının en az bir alana
/// düştüğünü doğrular — yeni bir bölüm adı geldiğinde test kırmızıya döner.
class ProgramCategory {
  /// Kalıcı anahtar (rota parametresi ve depoya yazılır — değiştirilmemeli).
  final String key;

  /// Kullanıcıya görünen ad.
  final String label;

  /// [interestAreas] anahtarları.
  final Set<String> interestKeys;

  /// Normalize ad üzerinde alt dize kuralları.
  final List<String> nameContains;

  const ProgramCategory({
    required this.key,
    required this.label,
    this.interestKeys = const {},
    this.nameContains = const [],
  });

  /// Bu alanın kapsadığı küratörlü normalize adlar (önbelleklenir).
  Set<String> get _curatedNames =>
      _curatedCache[key] ??= namesForInterests(interestKeys);

  static final Map<String, Set<String>> _curatedCache = {};

  /// [normalizedName] bu alana giriyor mu?
  /// (Ad `normalizeProgramName` ile indirgenmiş olmalıdır.)
  bool matches(String normalizedName) {
    if (_curatedNames.contains(normalizedName)) return true;
    for (final needle in nameContains) {
      if (normalizedName.contains(needle)) return true;
    }
    return false;
  }
}

/// Alanlar — sıra ekranda göründükleri sıradır, anahtarlar kalıcıdır.
///
/// `nameContains` kuralları hem lisans hem önlisans adlarını kapsar; önlisans
/// tarafı ağırlıkla "... teknolojisi / hizmetleri" kalıbında olduğundan ayrı
/// bloklarda gruplanmıştır. Türkçe ünsüz yumuşaması nedeniyle bazı kökler iki
/// biçimde yazılır ("saglik" ve "saglig" gibi).
const List<ProgramCategory> programCategories = [
  ProgramCategory(
    key: 'muhendislik',
    label: 'Mühendislik & Teknoloji',
    interestKeys: {
      'bilgisayar', 'elektrik', 'makine', 'endustri', 'insaat', 'havacilik',
    },
    nameContains: [
      // "muhendis" hem "... Mühendisliği" hem "Mühendislik ve Doğa Bilimleri
      // Programları" adlarını yakalar.
      'muhendis',
      // Önlisans tekniği: "teknoloji" öneki teknolojisi/teknolojileri'yi de alır.
      'teknoloji', 'programciligi', 'elektrik', 'elektronik', 'makine',
      'mekatronik', 'insaat', 'otomotiv', 'kaynak', 'madencilik', 'harita',
      'iklimlendirme', 'dogalgaz', 'kalipcilik', 'konstruksiyonu', 'bilisim',
      'yapi', 'enerji',
    ],
  ),
  ProgramCategory(
    key: 'saglik',
    label: 'Sağlık',
    interestKeys: {'saglik', 'hemsirelik', 'saglik-bilimleri', 'veteriner'},
    nameContains: [
      'konusma terapisi', 'saglik', 'saglig', 'tibbi', 'anestezi', 'diyaliz',
      'radyoterapi', 'optisyenlik', 'protez', 'ortez', 'odyometri', 'eczane',
      'ameliyathane', 'acil yardim', 'patoloji', 'elektronorofizyoloji',
      'engelli bakimi', 'yasli bakimi', 'fizyoterapi', 'laboratuvar',
      'goruntuleme', 'dokumantasyon',
    ],
  ),
  ProgramCategory(
    key: 'hukuk-siyaset',
    label: 'Hukuk & Siyaset',
    interestKeys: {'hukuk', 'siyaset'},
  ),
  ProgramCategory(
    key: 'iktisadi',
    label: 'İktisadi & İdari',
    interestKeys: {'isletme', 'finans'},
    nameContains: [
      'isletme', 'ticaret', 'pazarlama', 'insan kaynaklari', 'denizcilik',
      'havacilik yonetimi', 'yonetim bilimleri', 'yonetim bilisim',
      'bankacilik', 'finans', 'ekonomi', 'iktisat', 'maliye',
      // Önlisans idari programları.
      'muhasebe', 'lojistik', 'emlak', 'buro yonetimi', 'cagri merkezi',
      'posta hizmetleri', 'sosyal guvenlik', 'yerel yonetimler', 'ulastirma',
      'spor yonetimi', 'tapu', 'kadastro', 'afet yonetimi',
    ],
  ),
  ProgramCategory(
    key: 'egitim',
    label: 'Öğretmenlik & Eğitim',
    interestKeys: {'egitim'},
    nameContains: ['ogretmenligi'],
  ),
  ProgramCategory(
    key: 'fen',
    label: 'Fen & Matematik',
    interestKeys: {'matematik', 'kimya'},
    nameContains: ['biyoloji', 'cografi bilgi'],
  ),
  ProgramCategory(
    key: 'sosyal',
    label: 'Sosyal & Beşerî',
    interestKeys: {'sosyal', 'tarih', 'psikoloji'},
    nameContains: [
      'ilahiyat', 'cografya', 'belge yonetimi', 'sosyal bilimler', 'arkeoloji',
      'sosyal hizmet', 'guvenli', 'savunma', 'itfaiye',
    ],
  ),
  ProgramCategory(
    key: 'dil-edebiyat',
    label: 'Dil & Edebiyat',
    interestKeys: {'dil'},
    nameContains: [
      'dili ve edebiyati', 'mutercim', 'lehceleri', 'kulturu ve edebiyati',
      'ingilizce', 'cevirmen',
    ],
  ),
  ProgramCategory(
    key: 'mimarlik-tasarim',
    label: 'Mimarlık & Tasarım',
    interestKeys: {'mimarlik', 'tasarim'},
    nameContains: [
      'mimar', 'tasarim', 'planlama', 'el sanatlari', 'dekoratif',
      'restorasyon', 'mobilya', 'dekorasyon', 'giyim', 'sac bakimi',
      'basim ve yayim', 'tekstil',
    ],
  ),
  ProgramCategory(
    key: 'iletisim',
    label: 'İletişim & Medya',
    interestKeys: {'iletisim'},
    nameContains: ['medya', 'reklam', 'iletisim', 'gazetecilik', 'televizyon'],
  ),
  ProgramCategory(
    key: 'turizm',
    label: 'Turizm & Gastronomi',
    interestKeys: {'turizm'},
    nameContains: [
      'turizm', 'gastronomi', 'rekreasyon', 'ascilik', 'turist rehberligi',
      'kabin hizmetleri',
    ],
  ),
  ProgramCategory(
    key: 'ziraat',
    label: 'Ziraat & Orman',
    nameContains: [
      'tarim', 'tarla', 'bahce', 'bitki', 'toprak', 'zootekni', 'orman',
      'su urunleri', 'biyosistem', 'gida',
    ],
  ),
];

/// Anahtarla alan bul.
ProgramCategory? categoryByKey(String key) {
  for (final c in programCategories) {
    if (c.key == key) return c;
  }
  return null;
}

/// [normalizedName]'in düştüğü tüm alanlar (boş olabilir).
List<ProgramCategory> categoriesFor(String normalizedName) =>
    [for (final c in programCategories) if (c.matches(normalizedName)) c];
