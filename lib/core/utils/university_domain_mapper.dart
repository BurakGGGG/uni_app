class UniversityDomainMapper {
  static const Map<String, String> _domainToId = {
    // User provided specifics
    'ogr.iu.edu.tr': 'istanbul_uni',
    'istanbul.edu.tr': 'istanbul_uni',
    'ogr.alanya.edu.tr': 'alanya',
    'alanya.edu.tr': 'alanya',
    'ogr.eskisehir.edu.tr': 'estu',
    'eskisehir.edu.tr': 'estu',
    'ogr.btu.edu.tr': 'btu',
    'btu.edu.tr': 'btu',
    'sivas.edu.tr': 'sivas_btu',
    'trabzon.edu.tr': 'trabzon_uni',
    'std.idu.edu.tr': 'izmir_demokrasi',
    'idu.edu.tr': 'izmir_demokrasi',
    'ogr.ikc.edu.tr': 'izmir_katipcelebi',
    'ikcu.edu.tr': 'izmir_katipcelebi', // From json
    'stu.aydin.edu.tr': 'aydin',
    'aydin.edu.tr': 'aydin',
    'gelisim.edu.tr': 'gelisim',
    'std.medipol.edu.tr': 'medipol',
    'medipol.edu.tr': 'medipol',
    'ogrenci.hitit.edu.tr': 'hitit',
    'hitit.edu.tr': 'hitit',
    'stu.omu.edu.tr': 'omu',
    'omu.edu.tr': 'omu',
    'kou.edu.tr': 'kocaeli',
    'kocaeli.edu.tr': 'kocaeli',
    'beun.edu.tr': 'beun',
    'posta.pau.edu.tr': 'pau',
    'pau.edu.tr': 'pau',
    'karabuk.edu.tr': 'karabuk',

    // Seed data / Common
    'itu.edu.tr': 'itu',
    'yildiz.edu.tr': 'yildiz_teknik',
    'std.yildiz.edu.tr': 'yildiz_teknik',
    'metu.edu.tr': 'odtu',
    'hacettepe.edu.tr': 'hacettepe',
    'ogr.hacettepe.edu.tr': 'hacettepe',
    'ankara.edu.tr': 'ankara_uni',
    'gazi.edu.tr': 'gazi',
    'ogr.gazi.edu.tr': 'gazi',
    'ege.edu.tr': 'ege',
    'ogrenci.ege.edu.tr': 'ege',
    'deu.edu.tr': 'dokuz_eylul',
    'akdeniz.edu.tr': 'akdeniz',
    'anadolu.edu.tr': 'anadolu',
    'ogu.edu.tr': 'ogu',
    'uludag.edu.tr': 'uludag',
    'comu.edu.tr': 'comu',
    'cumhuriyet.edu.tr': 'cumhuriyet',
    'ktu.edu.tr': 'ktu',
    'mersin.edu.tr': 'mersin_uni',
    'tarsus.edu.tr': 'tarsus',
    'marmara.edu.tr': 'marmara',
    'marun.edu.tr': 'marmara',
    'hbv.edu.tr': 'hacibayram',
    'erciyes.edu.tr': 'erciyes',
    'inonu.edu.tr': 'inonu',
    'selcuk.edu.tr': 'selcuk',
    'dpu.edu.tr': 'dpu',
    'sakarya.edu.tr': 'sakarya',
    'ogr.sakarya.edu.tr': 'sakarya',
    'ibu.edu.tr': 'ibu',
    'yyu.edu.tr': 'yyu',
    'atauni.edu.tr': 'atauni',
    'gantep.edu.tr': 'gantep',
    'cu.edu.tr': 'cu',
    'ogrenci.cu.edu.tr': 'cu',
    'ksu.edu.tr': 'ksu',
    'cbu.edu.tr': 'cbu',
    'ogr.cbu.edu.tr': 'cbu',
    'sdu.edu.tr': 'sdu',
    'gop.edu.tr': 'gop',
  };

  /// Returns the corresponding university ID based on the given email address.
  static String? getUniversityId(String email) {
    if (!email.contains('@')) return null;

    final domain = email.toLowerCase().split('@').last.trim();

    // Direct match
    if (_domainToId.containsKey(domain)) {
      return _domainToId[domain];
    }

    // Subdomain matching (e.g., matching abc.ogr.iu.edu.tr to ogr.iu.edu.tr)
    for (final entry in _domainToId.entries) {
      if (domain.endsWith('.${entry.key}')) {
        return entry.value;
      }
    }

    return null;
  }
}
