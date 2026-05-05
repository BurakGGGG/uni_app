// Üniversite–Bölüm güç skoru matrisi (1–5 arası).
// null = o bölüm bu üniversitede yok veya çok zayıf.

class UniStrength {
  final String universityId;
  final String universityName;
  final String city; // şehir etiket id'si
  final String type; // 'devlet' veya 'vakif'
  final Map<String, int> strengths; // departmentProfileId → 1-5

  const UniStrength({
    required this.universityId,
    required this.universityName,
    required this.city,
    required this.type,
    required this.strengths,
  });
}

class UniversityStrengthMatrix {
  static const List<UniStrength> all = [
    UniStrength(universityId: 'itu', universityName: 'İstanbul Teknik Üniversitesi', city: 'istanbul', type: 'devlet',
        strengths: {'bilgisayar_muh': 5, 'yazilim_muh': 4, 'ee_muh': 5}),
    UniStrength(universityId: 'odtu', universityName: 'ODTÜ', city: 'ankara', type: 'devlet',
        strengths: {'bilgisayar_muh': 5, 'yazilim_muh': 4, 'ee_muh': 5}),
    UniStrength(universityId: 'ytu', universityName: 'Yıldız Teknik Üniversitesi', city: 'istanbul', type: 'devlet',
        strengths: {'bilgisayar_muh': 4, 'yazilim_muh': 3, 'ee_muh': 4}),
    UniStrength(universityId: 'iu', universityName: 'İstanbul Üniversitesi', city: 'istanbul', type: 'devlet',
        strengths: {'bilgisayar_muh': 3, 'ee_muh': 3, 'tip': 5, 'dis': 5, 'vet': 4, 'hukuk': 5, 'acil_yardim': 4}),
    UniStrength(universityId: 'hacettepe', universityName: 'Hacettepe Üniversitesi', city: 'ankara', type: 'devlet',
        strengths: {'bilgisayar_muh': 4, 'ee_muh': 4, 'tip': 5, 'dis': 5, 'acil_yardim': 4}),
    UniStrength(universityId: 'ankara', universityName: 'Ankara Üniversitesi', city: 'ankara', type: 'devlet',
        strengths: {'bilgisayar_muh': 3, 'ee_muh': 3, 'tip': 4, 'dis': 4, 'vet': 5, 'hukuk': 4, 'acil_yardim': 3}),
    UniStrength(universityId: 'gazi', universityName: 'Gazi Üniversitesi', city: 'ankara', type: 'devlet',
        strengths: {'bilgisayar_muh': 3, 'ee_muh': 3, 'tip': 4, 'dis': 4, 'hukuk': 4, 'gastronomi': 3, 'acil_yardim': 3}),
    UniStrength(universityId: 'ege', universityName: 'Ege Üniversitesi', city: 'izmir', type: 'devlet',
        strengths: {'bilgisayar_muh': 3, 'ee_muh': 3, 'tip': 4, 'dis': 4, 'vet': 4, 'hukuk': 3, 'gastronomi': 3, 'acil_yardim': 3}),
    UniStrength(universityId: 'deu', universityName: 'Dokuz Eylül Üniversitesi', city: 'izmir', type: 'devlet',
        strengths: {'bilgisayar_muh': 3, 'ee_muh': 3, 'tip': 3, 'dis': 3, 'vet': 3, 'hukuk': 3, 'acil_yardim': 3}),
    UniStrength(universityId: 'marmara', universityName: 'Marmara Üniversitesi', city: 'istanbul', type: 'devlet',
        strengths: {'bilgisayar_muh': 3, 'ee_muh': 3, 'tip': 3, 'dis': 4, 'vet': 3, 'hukuk': 4, 'gastronomi': 3, 'bilgisayar_prog': 3, 'acil_yardim': 3}),
    UniStrength(universityId: 'ktu', universityName: 'Karadeniz Teknik Üniversitesi', city: 'trabzon', type: 'devlet',
        strengths: {'bilgisayar_muh': 3, 'ee_muh': 3, 'tip': 3, 'dis': 3, 'bilgisayar_prog': 2}),
    UniStrength(universityId: 'uludag', universityName: 'Bursa Uludağ Üniversitesi', city: 'bursa', type: 'devlet',
        strengths: {'bilgisayar_muh': 3, 'ee_muh': 3, 'tip': 3, 'dis': 3, 'vet': 3, 'hukuk': 3, 'bilgisayar_prog': 2, 'acil_yardim': 3}),
    UniStrength(universityId: 'anadolu', universityName: 'Anadolu Üniversitesi', city: 'eskisehir', type: 'devlet',
        strengths: {'bilgisayar_muh': 2, 'ee_muh': 2, 'hukuk': 3, 'bilgisayar_prog': 3, 'acil_yardim': 2}),
    UniStrength(universityId: 'esogu', universityName: 'Eskişehir Osmangazi Üniversitesi', city: 'eskisehir', type: 'devlet',
        strengths: {'bilgisayar_muh': 2, 'ee_muh': 2, 'tip': 3, 'dis': 3}),
    UniStrength(universityId: 'estu', universityName: 'Eskişehir Teknik Üniversitesi', city: 'eskisehir', type: 'devlet',
        strengths: {'bilgisayar_muh': 3, 'yazilim_muh': 3, 'ee_muh': 3}),
    UniStrength(universityId: 'akdeniz', universityName: 'Akdeniz Üniversitesi', city: 'antalya', type: 'devlet',
        strengths: {'bilgisayar_muh': 2, 'ee_muh': 2, 'tip': 3, 'dis': 3, 'vet': 3, 'hukuk': 3, 'gastronomi': 3, 'bilgisayar_prog': 2, 'acil_yardim': 2}),
    UniStrength(universityId: 'mersin', universityName: 'Mersin Üniversitesi', city: 'mersin', type: 'devlet',
        strengths: {'bilgisayar_muh': 2, 'ee_muh': 2, 'tip': 2, 'dis': 2, 'hukuk': 2, 'bilgisayar_prog': 2}),
    UniStrength(universityId: 'tarsus', universityName: 'Tarsus Üniversitesi', city: 'mersin', type: 'devlet',
        strengths: {'bilgisayar_muh': 2, 'yazilim_muh': 2, 'ee_muh': 2, 'bilgisayar_prog': 3, 'acil_yardim': 3}),
    UniStrength(universityId: 'alku', universityName: 'Alanya ALKÜ', city: 'antalya', type: 'devlet',
        strengths: {'bilgisayar_muh': 2, 'yazilim_muh': 2, 'ee_muh': 2, 'gastronomi': 3, 'bilgisayar_prog': 2, 'acil_yardim': 2}),
    UniStrength(universityId: 'medipol', universityName: 'İstanbul Medipol Üniversitesi', city: 'istanbul', type: 'vakif',
        strengths: {'bilgisayar_muh': 2, 'tip': 3, 'dis': 3, 'acil_yardim': 3}),
    UniStrength(universityId: 'aydin', universityName: 'İstanbul Aydın Üniversitesi', city: 'istanbul', type: 'vakif',
        strengths: {'bilgisayar_muh': 2, 'yazilim_muh': 2, 'hukuk': 2, 'gastronomi': 3, 'bilgisayar_prog': 2, 'acil_yardim': 2}),
    UniStrength(universityId: 'gelisim', universityName: 'İstanbul Gelişim Üniversitesi', city: 'istanbul', type: 'vakif',
        strengths: {'bilgisayar_muh': 1, 'bilgisayar_prog': 3, 'acil_yardim': 3}),
    UniStrength(universityId: 'cumhuriyet', universityName: 'Sivas Cumhuriyet Üniversitesi', city: 'sivas', type: 'devlet',
        strengths: {'bilgisayar_muh': 2, 'ee_muh': 2, 'tip': 3, 'dis': 3, 'vet': 3, 'bilgisayar_prog': 2, 'acil_yardim': 2}),
    UniStrength(universityId: 'sivas_biltek', universityName: 'Sivas Bilim ve Teknoloji Üniversitesi', city: 'sivas', type: 'devlet',
        strengths: {'bilgisayar_muh': 2, 'yazilim_muh': 2, 'ee_muh': 2}),
    UniStrength(universityId: 'hbv', universityName: 'Ankara Hacı Bayram Veli Üniversitesi', city: 'ankara', type: 'devlet',
        strengths: {'bilgisayar_muh': 2, 'ee_muh': 2, 'hukuk': 3}),
    UniStrength(universityId: 'idu', universityName: 'İzmir Demokrasi Üniversitesi', city: 'izmir', type: 'devlet',
        strengths: {'bilgisayar_muh': 2, 'yazilim_muh': 2, 'ee_muh': 2, 'bilgisayar_prog': 2}),
    UniStrength(universityId: 'ikcu', universityName: 'İzmir Kâtip Çelebi Üniversitesi', city: 'izmir', type: 'devlet',
        strengths: {'bilgisayar_muh': 3, 'ee_muh': 3, 'tip': 3, 'dis': 3, 'acil_yardim': 3}),
    UniStrength(universityId: 'comu', universityName: 'Çanakkale ÇOMÜ', city: 'canakkale', type: 'devlet',
        strengths: {'bilgisayar_muh': 2, 'ee_muh': 2, 'tip': 3, 'vet': 3, 'bilgisayar_prog': 2}),
    UniStrength(universityId: 'btu', universityName: 'Bursa Teknik Üniversitesi', city: 'bursa', type: 'devlet',
        strengths: {'bilgisayar_muh': 3, 'yazilim_muh': 2, 'ee_muh': 3}),
    UniStrength(universityId: 'trabzon', universityName: 'Trabzon Üniversitesi', city: 'trabzon', type: 'devlet',
        strengths: {'bilgisayar_muh': 2, 'ee_muh': 2, 'gastronomi': 2, 'bilgisayar_prog': 2}),
    UniStrength(universityId: 'hitit', universityName: 'Hitit Üniversitesi', city: 'sivas', type: 'devlet',
        strengths: {'bilgisayar_muh': 2, 'ee_muh': 2, 'bilgisayar_prog': 2, 'acil_yardim': 2}),
  ];
}
