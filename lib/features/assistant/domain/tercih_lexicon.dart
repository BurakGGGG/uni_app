/// Üni sohbet ayrıştırıcısının sözlüğü (saf Dart).
///
/// Tüm anahtarlar TercihNlu'nun fold biçimindedir: Türkçe küçük harf +
/// aksan katlama (ş→s, ğ→g, ü→u, ö→o, ç→c, ı→i) + noktalama yok.
/// Değerlerdeki `deptQuery` motor-uyumlu KÜÇÜK HARF Türkçe parçadır
/// (motor `name.toLowerCase().contains(query)` yapar); `interestKeys`
/// `interestAreas` anahtarlarıdır — testler ikisini de doğrular.
library;

/// Meslek/ilgi kelimesinin karşılığı: kullanıcıya dönük etiket + isteğe
/// bağlı motor sorgusu + yumuşak ilgi anahtarları.
class LexiconEntry {
  final String label;

  /// Motorun `deptQuery`'sine yazılabilir küçük-harf parça. null →
  /// kelime yalnız yumuşak ilgi sinyali üretir (örn. "yazılımcı" tek
  /// bölüme indirgenemez, ailesini boost'lamak doğrusudur).
  final String? deptQuery;

  /// InterestArea.key değerleri (WizardPrefs.interestKeys'e gider).
  final Set<String> interestKeys;

  const LexiconEntry(this.label, {this.deptQuery, this.interestKeys = const {}});
}

const _tip = LexiconEntry('Tıp', deptQuery: 'tıp', interestKeys: {'saglik'});
const _hukuk =
    LexiconEntry('Hukuk', deptQuery: 'hukuk', interestKeys: {'hukuk'});
const _psikoloji = LexiconEntry('Psikoloji',
    deptQuery: 'psikoloji', interestKeys: {'psikoloji'});
const _yazilim =
    LexiconEntry('Bilgisayar / Yazılım', interestKeys: {'bilgisayar'});
const _ogretmenlik = LexiconEntry('Öğretmenlik',
    deptQuery: 'öğretmenliği', interestKeys: {'egitim'});
const _hemsirelik = LexiconEntry('Hemşirelik',
    deptQuery: 'hemşirelik', interestKeys: {'hemsirelik'});
const _ebelik =
    LexiconEntry('Ebelik', deptQuery: 'ebelik', interestKeys: {'hemsirelik'});
const _mimarlik = LexiconEntry('Mimarlık',
    deptQuery: 'mimarlık', interestKeys: {'mimarlik'});
const _eczacilik = LexiconEntry('Eczacılık',
    deptQuery: 'eczacılık', interestKeys: {'saglik'});
const _veterinerlik = LexiconEntry('Veterinerlik',
    deptQuery: 'veteriner', interestKeys: {'veteriner'});
const _muhendislik = LexiconEntry('Mühendislik', deptQuery: 'mühendis');
const _pilotaj = LexiconEntry('Pilotaj', deptQuery: 'pilotaj');
const _gazetecilik = LexiconEntry('Gazetecilik',
    deptQuery: 'gazetecilik', interestKeys: {'iletisim'});
const _disHekimligi = LexiconEntry('Diş Hekimliği',
    deptQuery: 'diş hekim', interestKeys: {'saglik'});
const _fizyoterapi = LexiconEntry('Fizyoterapi',
    deptQuery: 'fizyoterapi', interestKeys: {'saglik-bilimleri'});
const _diyetetik = LexiconEntry('Beslenme ve Diyetetik',
    deptQuery: 'diyetetik', interestKeys: {'saglik-bilimleri'});
const _saglikAlani = LexiconEntry('Sağlık',
    interestKeys: {'saglik', 'saglik-bilimleri', 'hemsirelik'});
const _teknoloji =
    LexiconEntry('Teknoloji', interestKeys: {'bilgisayar', 'elektrik'});
const _medya = LexiconEntry('Medya / İletişim', interestKeys: {'iletisim'});
const _tasarim = LexiconEntry('Tasarım', interestKeys: {'tasarim', 'mimarlik'});
const _turizm = LexiconEntry('Turizm', interestKeys: {'turizm'});
const _finans = LexiconEntry('Bankacılık / Finans', interestKeys: {'finans'});
const _ekonomi = LexiconEntry('İktisat / Ekonomi', interestKeys: {'isletme'});
const _bilgisayarAlani =
    LexiconEntry('Bilgisayar / Yazılım', interestKeys: {'bilgisayar'});
const _elektrikAlani =
    LexiconEntry('Elektrik-Elektronik', interestKeys: {'elektrik'});
const _makineAlani =
    LexiconEntry('Makine / Otomotiv', interestKeys: {'makine'});
const _endustriAlani = LexiconEntry('Endüstri', interestKeys: {'endustri'});
const _insaatAlani = LexiconEntry('İnşaat / Çevre', interestKeys: {'insaat'});
const _siyasetAlani =
    LexiconEntry('Siyaset / Uluslararası', interestKeys: {'siyaset'});
const _matematikAlani =
    LexiconEntry('Matematik / İstatistik', interestKeys: {'matematik'});
const _kimyaAlani = LexiconEntry('Kimya / Biyo / Gıda', interestKeys: {'kimya'});
const _havacilikAlani =
    LexiconEntry('Havacılık / Uzay', interestKeys: {'havacilik'});
const _egitimAlani =
    LexiconEntry('Öğretmenlik / Eğitim', interestKeys: {'egitim'});
const _edebiyatAlani = LexiconEntry('Tarih / Edebiyat', interestKeys: {'tarih'});
const _sosyalAlani =
    LexiconEntry('Sosyoloji / Felsefe', interestKeys: {'sosyal'});
const _iletisimAlani =
    LexiconEntry('İletişim / Medya', interestKeys: {'iletisim'});

/// Tek kelimelik meslek/ilgi sözlüğü. Bölüm adıyla birebir yazılanlar
/// ("psikoloji", "hemşirelik") buraya gelmeden asset bölüm sözlüğünde
/// yakalanır; burası kalan halk dilini karşılar.
const Map<String, LexiconEntry> professionLexicon = {
  'doktor': _tip, 'doktorluk': _tip, 'hekim': _tip, 'hekimlik': _tip,
  'psikiyatrist': _tip, 'psikiyatr': _tip,
  'psikolog': _psikoloji, 'psikologluk': _psikoloji,
  'avukat': _hukuk, 'avukatlik': _hukuk, 'hukukcu': _hukuk,
  'savci': _hukuk, 'hakim': _hukuk,
  'yazilim': _yazilim, 'yazilimci': _yazilim, 'yazilimcilik': _yazilim,
  'programci': _yazilim, 'programcilik': _yazilim, 'kodlama': _yazilim,
  'bilisim': _yazilim,
  'ogretmen': _ogretmenlik, 'ogretmenlik': _ogretmenlik,
  'muhendis': _muhendislik, 'muhendislik': _muhendislik,
  'hemsire': _hemsirelik,
  'ebe': _ebelik,
  'mimar': _mimarlik,
  'eczaci': _eczacilik,
  'veteriner': _veterinerlik, 'veterinerlik': _veterinerlik,
  'pilot': _pilotaj, 'pilotluk': _pilotaj,
  'gazeteci': _gazetecilik,
  'fizyoterapist': _fizyoterapi,
  'diyetisyen': _diyetetik,
  'saglik': _saglikAlani, 'saglikci': _saglikAlani,
  'teknoloji': _teknoloji,
  'medya': _medya,
  'tasarim': _tasarim, 'tasarimci': _tasarim,
  'turizm': _turizm, 'turizmci': _turizm,
  'bankaci': _finans, 'bankacilik': _finans,
  'ekonomist': _ekonomi, 'iktisatci': _ekonomi,
  // İlgi alanı çekirdek kelimeleri — sohbet çipleri de bu yoldan geçer.
  // Gerçek bölüm adıyla çakışanlar ("matematik", "sosyoloji") önce bölüm
  // sözlüğünde yakalanır; burası yalnız yedek/genel kullanım.
  'bilgisayar': _bilgisayarAlani,
  'elektrik': _elektrikAlani, 'elektronik': _elektrikAlani,
  'makine': _makineAlani, 'otomotiv': _makineAlani,
  'endustri': _endustriAlani,
  'insaat': _insaatAlani, 'cevre': _insaatAlani,
  'siyaset': _siyasetAlani, 'uluslararasi': _siyasetAlani,
  'matematik': _matematikAlani, 'istatistik': _matematikAlani,
  'kimya': _kimyaAlani, 'biyoloji': _kimyaAlani, 'gida': _kimyaAlani,
  'havacilik': _havacilikAlani, 'uzay': _havacilikAlani,
  'egitim': _egitimAlani,
  'edebiyat': _edebiyatAlani,
  'sosyal': _sosyalAlani, 'sosyoloji': _sosyalAlani, 'felsefe': _sosyalAlani,
  'iletisim': _iletisimAlani,
  'gastronomi': _turizm,
  'grafik': _tasarim,
  'finans': _finans,
};

/// İki kelimelik sözlük — anahtarlar kök halleriyle ("dis hekimi" →
/// "dis hekim"); TercihNlu iki kelimenin kök adaylarını birleştirip arar.
const Map<String, LexiconEntry> professionBigrams = {
  'dis hekim': _disHekimligi,
};

/// Halk dilindeki şehir adları → plaka kodu (resmî 81 il CityHelper'dan
/// gelir, burası yalnız takma adlar).
const Map<String, String> cityAliases = {
  'afyon': '03',
  'urfa': '63',
  'antep': '27',
  'maras': '46',
};

/// Puan türü — yalnız TAM token eşleşmesi (kısa oldukları için kök
/// indirgeme yanlış yakalar: "dili" ≠ "dil").
const Map<String, String> scoreTypeExact = {
  'say': 'SAY',
  'ea': 'EA',
  'soz': 'SÖZ',
  'dil': 'DİL',
  'ydt': 'DİL',
  'tyt': 'TYT',
};

/// Puan türü — kök indirgemeyle de eşleşebilen uzun adlar
/// ("sayısaldan" → "sayisal").
const Map<String, String> scoreTypeStemmed = {
  'sayisal': 'SAY',
  'sozel': 'SÖZ',
};

/// Kök indirgemede denenen Türkçe ekler (fold edilmiş, uzundan kısaya).
/// İndirgeme en fazla iki kademe uygulanır ("istanbuldakiler" → "ler" →
/// "daki" → "istanbul"); kök en az 3 harf kalmalıdır.
const List<String> kSuffixes = [
  'larinda', 'lerinde', 'sindaki', 'sindeki',
  'daki', 'deki', 'taki', 'teki', 'inda', 'inde', 'unda', 'unde',
  'dan', 'den', 'tan', 'ten', 'lar', 'ler', 'nin', 'nun', 'nda', 'nde',
  'yla', 'yle',
  'da', 'de', 'ta', 'te', 'ya', 'ye', 'yi', 'yu', 'la', 'le', 'li', 'lu',
  'si', 'su', 'in', 'un', 'im', 'um',
  'a', 'e', 'i', 'u',
];

/// Ayrıştırmada anlam taşımayan dolgu kelimeleri — `unresolved`'a girmez.
const Set<String> chatStopwords = {
  've', 'veya', 'ya', 'yada', 'ile', 'icin', 'ama', 'fakat', 'ancak',
  'hem', 'da', 'de', 'ki', 'mi', 'mu', 'daki', 'deki', 'dan', 'den',
  'ta', 'te', 'o', 'bu', 'su', 'ne', 'nasil', 'hangi', 'kadar',
  'bir', 'bi', 'sey', 'seyler', 'cok', 'en', 'az', 'daha', 'biraz',
  'tam', 'sadece', 'yaklasik', 'civari', 'civarinda', 'falan', 'filan',
  'acaba', 'galiba', 'sanirim', 'belki', 'var', 'yok', 'olur', 'olsun',
  'olabilir', 'olmak', 'olmaz', 'istiyorum', 'isterim', 'istiyom',
  'istedim', 'isterdim', 'istemiyorum', 'okumak', 'okurum', 'okuyacagim',
  'kazanmak', 'gitmek', 'girmek', 'yapmak', 'yapabilirim',
  'dusunuyorum', 'bakiyorum', 'bakiniyorum', 'ariyorum', 'seciyorum',
  'oldu', 'yap', 'olarak', 'artik', 'simdi', 'degistir', 'peki',
  'once', 'sonra',
  'universite', 'universitesi', 'universitede', 'universitesinde',
  'universiteler', 'universiteleri', 'uni', 'okul', 'okulda', 'okullar',
  'fakulte', 'fakultesi', 'bolum', 'bolumu', 'bolumler', 'bolumleri',
  'bolumune', 'program', 'programlar', 'tercih', 'tercihler',
  'tercihlerim', 'liste', 'listem', 'bana', 'benim', 'ben', 'beni',
  'gibi', 'merhabalar', 'selam', 'lutfen', 'tesekkurler', 'tamam',
  'evet', 'hayir', 'yerlesmek', 'yerlesme', 'sinav', 'sinavda', 'yks',
};
