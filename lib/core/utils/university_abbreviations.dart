/// Üniversite kısaltmaları — ÖSYM resmi tam adından kısa koda çevirir.
///
/// Kullanım:
/// ```dart
/// final short = UniversityAbbreviations.shorten('İSTANBUL TEKNİK ÜNİVERSİTESİ');
/// // => 'İTÜ'
/// ```
class UniversityAbbreviations {
  UniversityAbbreviations._();

  /// Tam ad → kısaltma haritası (büyük harf normalize edilmiş).
  static const Map<String, String> _map = {
    'ABDULLAH GÜL ÜNİVERSİTESİ': 'AGÜ',
    'ADANA ALPARSLAN TÜRKEŞ BİLİM VE TEKNOLOJİ ÜNİVERSİTESİ': 'ATÜ',
    'ADIYAMAN ÜNİVERSİTESİ': 'ADYÜ',
    'AFYON KOCATEPE ÜNİVERSİTESİ': 'AKÜ',
    'AFYONKARAHİSAR SAĞLIK BİLİMLERİ ÜNİVERSİTESİ': 'AFSÜ',
    'AĞRI İBRAHİM ÇEÇEN ÜNİVERSİTESİ': 'AİÇÜ',
    'AKDENİZ ÜNİVERSİTESİ': 'AKDÜ',
    'AKSARAY ÜNİVERSİTESİ': 'ASÜ',
    'ALANYA ALAADDİN KEYKUBAT ÜNİVERSİTESİ': 'ALKÜ',
    'ANADOLU ÜNİVERSİTESİ': 'ANAÜ',
    'ANKARA HACI BAYRAM VELİ ÜNİVERSİTESİ': 'AHBVÜ',
    'ANKARA MÜZİK VE GÜZEL SANATLAR ÜNİVERSİTESİ': 'MGÜ',
    'ANKARA SOSYAL BİLİMLER ÜNİVERSİTESİ': 'ASBÜ',
    'ANKARA ÜNİVERSİTESİ': 'AÜ',
    'ANKARA YILDIRIM BEYAZIT ÜNİVERSİTESİ': 'AYBÜ',
    'ARDAHAN ÜNİVERSİTESİ': 'ARÜ',
    'ARTVİN ÇORUH ÜNİVERSİTESİ': 'AÇÜ',
    'ATATÜRK ÜNİVERSİTESİ': 'ATAÜNİ',
    'AYDIN ADNAN MENDERES ÜNİVERSİTESİ': 'ADÜ',
    'BALIKESİR ÜNİVERSİTESİ': 'BAÜN',
    'BANDIRMA ONYEDİ EYLÜL ÜNİVERSİTESİ': 'BANÜ',
    'BATMAN ÜNİVERSİTESİ': 'BATÜ',
    'BAYBURT ÜNİVERSİTESİ': 'BAYÜ',
    'BİLECİK ŞEYH EDEBALİ ÜNİVERSİTESİ': 'BŞEÜ',
    'BİNGÖL ÜNİVERSİTESİ': 'BÜ',
    'BİTLİS EREN ÜNİVERSİTESİ': 'BEÜ',
    'BOĞAZİÇİ ÜNİVERSİTESİ': 'BOÜN',
    'BOLU ABANT İZZET BAYSAL ÜNİVERSİTESİ': 'AİBÜ',
    'BURDUR MEHMET AKİF ERSOY ÜNİVERSİTESİ': 'MAKÜ',
    'BURSA TEKNİK ÜNİVERSİTESİ': 'BTÜ',
    'BURSA ULUDAĞ ÜNİVERSİTESİ': 'BUÜ',
    'ÇANAKKALE ONSEKİZ MART ÜNİVERSİTESİ': 'ÇOMÜ',
    'ÇANKIRI KARATEKİN ÜNİVERSİTESİ': 'ÇAKÜ',
    'ÇUKUROVA ÜNİVERSİTESİ': 'ÇÜ',
    'DİCLE ÜNİVERSİTESİ': 'DÜ',
    'DOKUZ EYLÜL ÜNİVERSİTESİ': 'DEÜ',
    'DÜZCE ÜNİVERSİTESİ': 'DÜZÜ',
    'EGE ÜNİVERSİTESİ': 'EÜ',
    'ERCİYES ÜNİVERSİTESİ': 'ERÜ',
    'ERZİNCAN BİNALİ YILDIRIM ÜNİVERSİTESİ': 'EBYÜ',
    'ERZURUM TEKNİK ÜNİVERSİTESİ': 'ETÜ',
    'ESKİŞEHİR OSMANGAZİ ÜNİVERSİTESİ': 'ESOGÜ',
    'ESKİŞEHİR TEKNİK ÜNİVERSİTESİ': 'ESTÜ',
    'FIRAT ÜNİVERSİTESİ': 'FÜ',
    'GALATASARAY ÜNİVERSİTESİ': 'GSÜ',
    'GAZİ ÜNİVERSİTESİ': 'GÜ',
    'GAZİANTEP BİLİM VE TEKNOLOJİ ÜNİVERSİTESİ': 'GİBTÜ',
    'GAZİANTEP ÜNİVERSİTESİ': 'GAÜN',
    'GEBZE TEKNİK ÜNİVERSİTESİ': 'GTÜ',
    'GİRESUN ÜNİVERSİTESİ': 'GRÜ',
    'GÜMÜŞHANE ÜNİVERSİTESİ': 'GŞÜ',
    'HACETTEPE ÜNİVERSİTESİ': 'HÜ',
    'HARRAN ÜNİVERSİTESİ': 'HRÜ',
    'HATAY MUSTAFA KEMAL ÜNİVERSİTESİ': 'MKÜ',
    'HİTİT ÜNİVERSİTESİ': 'HİTÜ',
    'IĞDIR ÜNİVERSİTESİ': 'IĞDÜ',
    'ISPARTA UYGULAMALI BİLİMLER ÜNİVERSİTESİ': 'ISUBÜ',
    'İNÖNÜ ÜNİVERSİTESİ': 'İNÜ',
    'İSKENDERUN TEKNİK ÜNİVERSİTESİ': 'İSTE',
    'İSTANBUL MEDENİYET ÜNİVERSİTESİ': 'İMÜ',
    'İSTANBUL TEKNİK ÜNİVERSİTESİ': 'İTÜ',
    'İSTANBUL ÜNİVERSİTESİ': 'İÜ',
    'İSTANBUL ÜNİVERSİTESİ-CERRAHPAŞA': 'İÜC',
    'İZMİR KATİP ÇELEBİ ÜNİVERSİTESİ': 'İKÇÜ',
    'İZMİR DEMOKRASİ ÜNİVERSİTESİ': 'İDÜ',
    'İZMİR YÜKSEK TEKNOLOJİ ENSTİTÜSÜ': 'İYTE',
    'KAFKAS ÜNİVERSİTESİ': 'KAÜ',
    'KAHRAMANMARAŞ İSTİKLAL ÜNİVERSİTESİ': 'KİÜ',
    'KAHRAMANMARAŞ SÜTÇÜ İMAM ÜNİVERSİTESİ': 'KSÜ',
    'KARABÜK ÜNİVERSİTESİ': 'KBÜ',
    'KARADENİZ TEKNİK ÜNİVERSİTESİ': 'KTÜ',
    'KARAMANOĞLU MEHMETBEY ÜNİVERSİTESİ': 'KMÜ',
    'KASTAMONU ÜNİVERSİTESİ': 'KÜ',
    'KAYSERİ ÜNİVERSİTESİ': 'KAYÜ',
    'KIRIKKALE ÜNİVERSİTESİ': 'KKÜ',
    'KIRKLARELİ ÜNİVERSİTESİ': 'KLÜ',
    'KIRŞEHİR AHİ EVRAN ÜNİVERSİTESİ': 'KAEÜ',
    'KİLİS 7 ARALIK ÜNİVERSİTESİ': 'KİYÜ',
    'KOCAELİ ÜNİVERSİTESİ': 'KOÜ',
    'KONYA TEKNİK ÜNİVERSİTESİ': 'KTÜN',
    'KÜTAHYA DUMLUPINAR ÜNİVERSİTESİ': 'DPÜ',
    'KÜTAHYA SAĞLIK BİLİMLERİ ÜNİVERSİTESİ': 'KSBÜ',
    'MALATYA TURGUT ÖZAL ÜNİVERSİTESİ': 'MTÜ',
    'MANİSA CELAL BAYAR ÜNİVERSİTESİ': 'MCBÜ',
    'MARDİN ARTUKLU ÜNİVERSİTESİ': 'MAÜ',
    'MARMARA ÜNİVERSİTESİ': 'MÜ',
    'MERSİN ÜNİVERSİTESİ': 'MEÜ',
    'MİLLİ SAVUNMA ÜNİVERSİTESİ': 'MSÜ',
    'MİMAR SİNAN GÜZEL SANATLAR ÜNİVERSİTESİ': 'MSGSÜ',
    'MUĞLA SITKI KOÇMAN ÜNİVERSİTESİ': 'MSKÜ',
    'MUNZUR ÜNİVERSİTESİ': 'MUNÜ',
    'MUŞ ALPARSLAN ÜNİVERSİTESİ': 'MŞÜ',
    'NECMETTİN ERBAKAN ÜNİVERSİTESİ': 'NEÜ',
    'NEVŞEHİR HACI BEKTAŞ VELİ ÜNİVERSİTESİ': 'NEVÜ',
    'NİĞDE ÖMER HALİSDEMİR ÜNİVERSİTESİ': 'ÖHÜ',
    'ONDOKUZ MAYIS ÜNİVERSİTESİ': 'OMÜ',
    'ORDU ÜNİVERSİTESİ': 'ODÜ',
    'ORTADOĞU TEKNİK ÜNİVERSİTESİ': 'ODTÜ',
    'OSMANİYE KORKUT ATA ÜNİVERSİTESİ': 'OKÜ',
    'PAMUKKALE ÜNİVERSİTESİ': 'PAÜ',
    'RECEP TAYYİP ERDOĞAN ÜNİVERSİTESİ': 'RTEÜ',
    'SAĞLIK BİLİMLERİ ÜNİVERSİTESİ': 'SBÜ',
    'SAKARYA ÜNİVERSİTESİ': 'SAÜ',
    'SAMSUN ÜNİVERSİTESİ': 'SAMÜ',
    'SELÇUK ÜNİVERSİTESİ': 'SÜ',
    'SİİRT ÜNİVERSİTESİ': 'SİÜ',
    'SİNOP ÜNİVERSİTESİ': 'SNÜ',
    'SİVAS BİLİM VE TEKNOLOJİ ÜNİVERSİTESİ': 'SBTÜ',
    'SİVAS CUMHURİYET ÜNİVERSİTESİ': 'SCÜ',
    'SÜLEYMAN DEMİREL ÜNİVERSİTESİ': 'SDÜ',
    'ŞIRNAK ÜNİVERSİTESİ': 'ŞÜ',
    'TEKİRDAĞ NAMIK KEMAL ÜNİVERSİTESİ': 'NKÜ',
    'TOKAT GAZİOSMANPAŞA ÜNİVERSİTESİ': 'TOGÜ',
    'TRABZON ÜNİVERSİTESİ': 'TRÜ',
    'TRAKYA ÜNİVERSİTESİ': 'TÜ',
    'TÜRK-ALMAN ÜNİVERSİTESİ': 'TAÜ',
    'TÜRK-JAPON BİLİM VE TEKNOLOJİ ÜNİVERSİTESİ': 'TJÜ',
    'UŞAK ÜNİVERSİTESİ': 'UÜ',
    'VAN YÜZÜNCÜ YIL ÜNİVERSİTESİ': 'YYÜ',
    'YALOVA ÜNİVERSİTESİ': 'YÜ',
    'YILDIZ TEKNİK ÜNİVERSİTESİ': 'YTÜ',
    'YOZGAT BOZOK ÜNİVERSİTESİ': 'YOBÜ',
    'ZONGULDAK BÜLENT ECEVİT ÜNİVERSİTESİ': 'BEÜN',
  };

  /// Verilen üniversite adını kısaltmaya çevirir.
  ///
  /// Eşleşme bulamazsa ilk 2 kelimeyi döndürür (uzunsa),
  /// kısa adlarda olduğu gibi bırakır.
  static String shorten(String fullName) {
    // Türkçe karakterleri bozmadan uppercase yapmak için:
    String toTurkishUpper(String s) {
      return s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
    }

    // 1) Tam eşleşme (case-insensitive)
    final upper = toTurkishUpper(fullName).trim();
    final match = _map[upper];
    if (match != null) return match;

    // 2) Kısmi eşleşme — map'te "ÜNİVERSİTESİ" suffix'siz arama
    for (final entry in _map.entries) {
      if (upper.contains(entry.key) || entry.key.contains(upper)) {
        return entry.value;
      }
    }

    // 3) Fallback: kısa isimler olduğu gibi, uzunlar ilk 2 kelime
    final words = fullName.split(' ');
    if (words.length <= 2 || fullName.length <= 14) return fullName;
    return words.take(2).join(' ');
  }

  /// Map'e doğrudan erişim (örn. listelemek için).
  static Map<String, String> get all => _map;
}
