// Üniversite–Bölüm güç skoru matrisi.
// v2: Gerçek taban puan sıralamasına dayalı güç skorları.
// Sıra < 10.000 → 5 | 10.001–30.000 → 4 | 30.001–70.000 → 3
// 70.001–150.000 → 2 | > 150.000 → 1 | Bölüm yok → null
//
// Önlisans bölümlerinde (bil_prog, acil_yardim) görece skorlama kullanılır.
// Kaynak: unisec_tercih_asistani_v2.md (2024-3-allowlist, 875 kayıt)

class UniStrengthEntry {
  final String universityId;
  final String universityName;
  final String city;
  final String type; // 'devlet' veya 'vakif'
  /// departmentProfileId → güç skoru (1-5)
  /// Her bölüm için o üniversitenin gerçek taban puan sıralaması
  final Map<String, int> strengths;
  /// departmentProfileId → gerçek sıralama (algoritmada W5 hesabı için)
  final Map<String, int> rankings;

  const UniStrengthEntry({
    required this.universityId,
    required this.universityName,
    required this.city,
    required this.type,
    required this.strengths,
    this.rankings = const {},
  });
}

class UniversityStrengthMatrix {
  static const List<UniStrengthEntry> all = [
    // ── ODTÜ ──
    UniStrengthEntry(
      universityId: 'odtu', universityName: 'ODTÜ', city: 'ankara', type: 'devlet',
      strengths: {'bilgisayar_muh': 5, 'ee_muh': 5},
      rankings: {'bilgisayar_muh': 953, 'ee_muh': 1601},
    ),
    // ── Hacettepe ──
    UniStrengthEntry(
      universityId: 'hacettepe', universityName: 'Hacettepe Üniversitesi', city: 'ankara', type: 'devlet',
      strengths: {'tip': 5, 'dis': 4, 'bilgisayar_muh': 5, 'ee_muh': 5, 'hukuk': 5, 'bil_prog': 3, 'acil_yardim': 5},
      rankings: {'tip': 1938, 'dis': 15003, 'bilgisayar_muh': 4382, 'ee_muh': 6310, 'hukuk': 4048, 'bil_prog': 290645, 'acil_yardim': 218420},
    ),
    // ── Ankara Üniversitesi ──
    UniStrengthEntry(
      universityId: 'ankara_uni', universityName: 'Ankara Üniversitesi', city: 'ankara', type: 'devlet',
      strengths: {'tip': 5, 'dis': 4, 'veteriner': 3, 'hukuk': 5, 'bilgisayar_muh': 4, 'ee_muh': 3, 'bil_prog': 2, 'acil_yardim': 4},
      rankings: {'tip': 3569, 'dis': 21111, 'veteriner': 69730, 'hukuk': 3227, 'bilgisayar_muh': 27581, 'ee_muh': 30612, 'bil_prog': 457291, 'acil_yardim': 277375},
    ),
    // ── İstanbul Üniversitesi ──
    UniStrengthEntry(
      universityId: 'istanbul_uni', universityName: 'İstanbul Üniversitesi', city: 'istanbul', type: 'devlet',
      strengths: {'tip': 5, 'dis': 4, 'hukuk': 5, 'bilgisayar_muh': 2, 'bil_prog': 1},
      rankings: {'tip': 5135, 'dis': 23877, 'hukuk': 5562, 'bilgisayar_muh': 86549, 'bil_prog': 1203843},
    ),
    // ── Gazi ──
    UniStrengthEntry(
      universityId: 'gazi', universityName: 'Gazi Üniversitesi', city: 'ankara', type: 'devlet',
      strengths: {'tip': 5, 'dis': 4, 'hukuk': 4, 'bilgisayar_muh': 4, 'ee_muh': 3, 'gastronomi': 3, 'bil_prog': 3, 'acil_yardim': 4},
      rankings: {'tip': 5197, 'dis': 25820, 'bilgisayar_muh': 19504, 'ee_muh': 34163, 'bil_prog': 369915, 'acil_yardim': 305036},
    ),
    // ── Ege ──
    UniStrengthEntry(
      universityId: 'ege', universityName: 'Ege Üniversitesi', city: 'izmir', type: 'devlet',
      strengths: {'tip': 5, 'dis': 4, 'bilgisayar_muh': 4, 'ee_muh': 3, 'bil_prog': 3, 'acil_yardim': 4},
      rankings: {'tip': 5294, 'dis': 23387, 'bilgisayar_muh': 17383, 'ee_muh': 34888, 'bil_prog': 262910, 'acil_yardim': 283569},
    ),
    // ── Marmara ──
    UniStrengthEntry(
      universityId: 'marmara', universityName: 'Marmara Üniversitesi', city: 'istanbul', type: 'devlet',
      strengths: {'tip': 5, 'dis': 4, 'hukuk': 5, 'bilgisayar_muh': 4, 'ee_muh': 3, 'bil_prog': 4, 'acil_yardim': 3},
      rankings: {'tip': 6641, 'dis': 29051, 'hukuk': 9010, 'bilgisayar_muh': 27828, 'ee_muh': 46972, 'bil_prog': 195113, 'acil_yardim': 347388},
    ),
    // ── Dokuz Eylül ──
    UniStrengthEntry(
      universityId: 'dokuz_eylul', universityName: 'Dokuz Eylül Üniversitesi', city: 'izmir', type: 'devlet',
      strengths: {'tip': 5, 'dis': 4, 'veteriner': 2, 'hukuk': 4, 'bilgisayar_muh': 4, 'ee_muh': 3, 'gastronomi': 4, 'bil_prog': 3, 'acil_yardim': 4},
      rankings: {'tip': 7326, 'dis': 28239, 'veteriner': 137984, 'hukuk': 16202, 'bilgisayar_muh': 23271, 'ee_muh': 40164, 'gastronomi': 20690, 'bil_prog': 320027, 'acil_yardim': 323699},
    ),
    // ── Akdeniz ──
    UniStrengthEntry(
      universityId: 'akdeniz', universityName: 'Akdeniz Üniversitesi', city: 'antalya', type: 'devlet',
      strengths: {'tip': 5, 'dis': 4, 'veteriner': 3, 'hukuk': 4, 'bilgisayar_muh': 3, 'ee_muh': 2, 'gastronomi': 4, 'bil_prog': 3, 'acil_yardim': 4},
      rankings: {'tip': 8580, 'dis': 29329, 'hukuk': 21532, 'bilgisayar_muh': 34200, 'ee_muh': 70395, 'gastronomi': 10002, 'bil_prog': 346757, 'acil_yardim': 339574},
    ),
    // ── Eskişehir Osmangazi ──
    UniStrengthEntry(
      universityId: 'ogu', universityName: 'Eskişehir Osmangazi Üniversitesi', city: 'eskisehir', type: 'devlet',
      strengths: {'tip': 5, 'dis': 3, 'hukuk': 4, 'bilgisayar_muh': 3, 'ee_muh': 3, 'gastronomi': 4, 'bil_prog': 2, 'acil_yardim': 4},
      rankings: {'tip': 9630, 'dis': 30041, 'hukuk': 21448, 'bilgisayar_muh': 39669, 'ee_muh': 52380, 'gastronomi': 26006, 'bil_prog': 528125, 'acil_yardim': 333274},
    ),
    // ── Bursa Uludağ ──
    UniStrengthEntry(
      universityId: 'uludag', universityName: 'Bursa Uludağ Üniversitesi', city: 'bursa', type: 'devlet',
      strengths: {'tip': 4, 'dis': 3, 'veteriner': 2, 'hukuk': 4, 'bilgisayar_muh': 3, 'ee_muh': 3, 'bil_prog': 3, 'acil_yardim': 3},
      rankings: {'tip': 10163, 'dis': 30716, 'veteriner': 86750, 'hukuk': 24424, 'bilgisayar_muh': 46117, 'ee_muh': 60038, 'bil_prog': 325303, 'acil_yardim': 353382},
    ),
    // ── İzmir Kâtip Çelebi ──
    UniStrengthEntry(
      universityId: 'izmir_katipcelebi', universityName: 'İzmir Kâtip Çelebi Üniversitesi', city: 'izmir', type: 'devlet',
      strengths: {'tip': 4, 'dis': 3, 'hukuk': 4, 'bilgisayar_muh': 3, 'ee_muh': 3, 'gastronomi': 3, 'acil_yardim': 3},
      rankings: {'tip': 12692, 'dis': 31182, 'hukuk': 29819, 'bilgisayar_muh': 47803, 'ee_muh': 68341, 'gastronomi': 48463, 'acil_yardim': 397265},
    ),
    // ── Yıldız Teknik ──
    UniStrengthEntry(
      universityId: 'yildiz_teknik', universityName: 'Yıldız Teknik Üniversitesi', city: 'istanbul', type: 'devlet',
      strengths: {'bilgisayar_muh': 5},
      rankings: {'bilgisayar_muh': 5733},
    ),
    // ── İstanbul Medipol ──
    UniStrengthEntry(
      universityId: 'medipol', universityName: 'İstanbul Medipol Üniversitesi', city: 'istanbul', type: 'vakif',
      strengths: {'tip': 5, 'dis': 4, 'hukuk': 4, 'bilgisayar_muh': 4, 'ee_muh': 3, 'gastronomi': 5, 'bil_prog': 4, 'acil_yardim': 3},
      rankings: {'tip': 50, 'dis': 26168, 'hukuk': 16025, 'bilgisayar_muh': 16185, 'ee_muh': 42370, 'gastronomi': 7641, 'bil_prog': 207420, 'acil_yardim': 356537},
    ),
    // ── İstanbul Aydın ──
    UniStrengthEntry(
      universityId: 'aydin', universityName: 'İstanbul Aydın Üniversitesi', city: 'istanbul', type: 'vakif',
      strengths: {'tip': 4, 'dis': 3, 'hukuk': 4, 'bilgisayar_muh': 3, 'ee_muh': 2, 'gastronomi': 5, 'bil_prog': 4, 'acil_yardim': 2},
      rankings: {'tip': 14205, 'dis': 33874, 'hukuk': 28886, 'bilgisayar_muh': 51920, 'ee_muh': 77795, 'gastronomi': 9255, 'bil_prog': 194846, 'acil_yardim': 442034},
    ),
    // ── İstanbul Gelişim ──
    UniStrengthEntry(
      universityId: 'gelisim', universityName: 'İstanbul Gelişim Üniversitesi', city: 'istanbul', type: 'vakif',
      strengths: {'dis': 3, 'bilgisayar_muh': 3, 'ee_muh': 2, 'gastronomi': 4, 'bil_prog': 3, 'acil_yardim': 2},
      rankings: {'dis': 39647, 'bilgisayar_muh': 61661, 'ee_muh': 103449, 'gastronomi': 21559, 'bil_prog': 303349, 'acil_yardim': 515037},
    ),
    // ── Mersin Üniversitesi ──
    UniStrengthEntry(
      universityId: 'mersin_uni', universityName: 'Mersin Üniversitesi', city: 'mersin', type: 'devlet',
      strengths: {'tip': 4, 'dis': 3, 'hukuk': 2, 'bilgisayar_muh': 2, 'ee_muh': 2, 'gastronomi': 3, 'bil_prog': 2, 'acil_yardim': 3},
      rankings: {'tip': 14608, 'dis': 33567, 'bilgisayar_muh': 85308, 'ee_muh': 146323, 'gastronomi': 54727, 'bil_prog': 557722, 'acil_yardim': 356973},
    ),
    // ── ÇOMÜ ──
    UniStrengthEntry(
      universityId: 'comu', universityName: 'Çanakkale Onsekiz Mart Üniversitesi', city: 'canakkale', type: 'devlet',
      strengths: {'tip': 4, 'dis': 3, 'veteriner': 3, 'bilgisayar_muh': 3, 'ee_muh': 2, 'gastronomi': 3, 'bil_prog': 2, 'acil_yardim': 3},
      rankings: {'tip': 15039, 'dis': 34116, 'bilgisayar_muh': 65816, 'ee_muh': 104816, 'gastronomi': 37459, 'bil_prog': 410762, 'acil_yardim': 381188},
    ),
    // ── KTÜ ──
    UniStrengthEntry(
      universityId: 'ktu', universityName: 'Karadeniz Teknik Üniversitesi', city: 'trabzon', type: 'devlet',
      strengths: {'tip': 4, 'dis': 3, 'bilgisayar_muh': 3, 'ee_muh': 2, 'bil_prog': 2, 'acil_yardim': 3},
      rankings: {'tip': 17526, 'dis': 36271, 'bilgisayar_muh': 62303, 'ee_muh': 97955, 'bil_prog': 569262, 'acil_yardim': 412993},
    ),
    // ── Sivas Cumhuriyet ──
    UniStrengthEntry(
      universityId: 'cumhuriyet', universityName: 'Sivas Cumhuriyet Üniversitesi', city: 'sivas', type: 'devlet',
      strengths: {'tip': 4, 'dis': 3, 'veteriner': 1, 'bilgisayar_muh': 2, 'ee_muh': 1, 'gastronomi': 2, 'bil_prog': 1, 'acil_yardim': 2},
      rankings: {'tip': 21430, 'dis': 39395, 'veteriner': 169294, 'bilgisayar_muh': 142279, 'ee_muh': 239524, 'gastronomi': 147236, 'bil_prog': 747657, 'acil_yardim': 443219},
    ),
    // ── Alanya ALKÜ ──
    UniStrengthEntry(
      universityId: 'alanya', universityName: 'Alanya Alaaddin Keykubat Üniversitesi', city: 'antalya', type: 'devlet',
      strengths: {'tip': 4, 'dis': 3, 'bilgisayar_muh': 2, 'ee_muh': 1, 'gastronomi': 3, 'bil_prog': 2, 'acil_yardim': 2},
      rankings: {'tip': 22086, 'dis': 38609, 'bilgisayar_muh': 86192, 'ee_muh': 161706, 'gastronomi': 50681, 'bil_prog': 590465, 'acil_yardim': 443051},
    ),
    // ── İzmir Demokrasi ──
    UniStrengthEntry(
      universityId: 'izmir_demokrasi', universityName: 'İzmir Demokrasi Üniversitesi', city: 'izmir', type: 'devlet',
      strengths: {'tip': 4, 'dis': 3, 'hukuk': 3, 'ee_muh': 2},
      rankings: {'tip': 23458, 'dis': 37001, 'hukuk': 35622, 'ee_muh': 119114},
    ),
    // ── Hitit ──
    UniStrengthEntry(
      universityId: 'hitit', universityName: 'Hitit Üniversitesi', city: 'sivas', type: 'devlet',
      strengths: {'tip': 4, 'bilgisayar_muh': 1, 'ee_muh': 1, 'bil_prog': 1, 'acil_yardim': 2},
      rankings: {'tip': 27521, 'bilgisayar_muh': 223315, 'ee_muh': 293633, 'bil_prog': 1032922, 'acil_yardim': 577419},
    ),
    // ── Eskişehir Teknik ──
    UniStrengthEntry(
      universityId: 'estu', universityName: 'Eskişehir Teknik Üniversitesi', city: 'eskisehir', type: 'devlet',
      strengths: {'bilgisayar_muh': 4, 'ee_muh': 3, 'bil_prog': 3},
      rankings: {'bilgisayar_muh': 27594, 'ee_muh': 45788, 'bil_prog': 344709},
    ),
    // ── İTÜ ──
    UniStrengthEntry(
      universityId: 'itu', universityName: 'İstanbul Teknik Üniversitesi', city: 'istanbul', type: 'devlet',
      strengths: {'bilgisayar_muh': 3, 'ee_muh': 2},
      rankings: {'bilgisayar_muh': 44932, 'ee_muh': 115193},
    ),
    // ── Bursa Teknik ──
    UniStrengthEntry(
      universityId: 'btu', universityName: 'Bursa Teknik Üniversitesi', city: 'bursa', type: 'devlet',
      strengths: {'bilgisayar_muh': 3, 'ee_muh': 2},
      rankings: {'bilgisayar_muh': 56002, 'ee_muh': 79426},
    ),
    // ── Sivas Bilim ve Teknoloji ──
    UniStrengthEntry(
      universityId: 'sivas_btu', universityName: 'Sivas Bilim ve Teknoloji Üniversitesi', city: 'sivas', type: 'devlet',
      strengths: {'bilgisayar_muh': 2, 'ee_muh': 2},
      rankings: {'bilgisayar_muh': 90958, 'ee_muh': 144836},
    ),
    // ── Tarsus ──
    UniStrengthEntry(
      universityId: 'tarsus', universityName: 'Tarsus Üniversitesi', city: 'mersin', type: 'devlet',
      strengths: {'bilgisayar_muh': 2, 'ee_muh': 1, 'bil_prog': 1, 'acil_yardim': 3},
      rankings: {'bilgisayar_muh': 145342, 'ee_muh': 237880, 'bil_prog': 821778, 'acil_yardim': 427997},
    ),
    // ── Anadolu ──
    UniStrengthEntry(
      universityId: 'anadolu', universityName: 'Anadolu Üniversitesi', city: 'eskisehir', type: 'devlet',
      strengths: {'hukuk': 4, 'gastronomi': 4, 'bil_prog': 1, 'acil_yardim': 2},
      rankings: {'hukuk': 19033, 'gastronomi': 14685, 'bil_prog': 1020716, 'acil_yardim': 0},
    ),
    // ── Hacı Bayram Veli ──
    UniStrengthEntry(
      universityId: 'hacibayram', universityName: 'Ankara Hacı Bayram Veli Üniversitesi', city: 'ankara', type: 'devlet',
      strengths: {'hukuk': 5, 'gastronomi': 3},
      rankings: {'hukuk': 9139, 'gastronomi': 32564},
    ),
    // ── Trabzon Üniversitesi ──
    UniStrengthEntry(
      universityId: 'trabzon_uni', universityName: 'Trabzon Üniversitesi', city: 'trabzon', type: 'devlet',
      strengths: {'hukuk': 3, 'acil_yardim': 2},
      rankings: {'hukuk': 53204, 'acil_yardim': 548772},
    ),
  ];
}
