// Bölüm profilleri: Her bölüm için W1-W7 kurallarına göre
// hangi tag değerlerinin tam (1.0) veya kısmi eşleştiği.
//
// v2 güncellemesi: Yazılım Mühendisliği kaldırıldı (veritabanında yok).
// Puan türleri eklendi: SAY, EA, SÖZ, TYT
// Kurallar unisec_tercih_asistani_v2.md Bölüm 5'e göre güncellendi.

class DepartmentProfile {
  final String id;
  final String name;
  final String type; // 'Lisans' veya 'Önlisans'
  final String scoreType; // 'say', 'ea', 'soz', 'tyt'
  final int duration; // yıl
  final int maxRanking; // en kötü üniversitenin sıralaması
  final Map<String, double> w1Rules; // alan + ders
  final Map<String, double> w2Rules; // ilgi + kimlik
  final Map<String, double> w3Rules; // hedef + gelir
  final Map<String, double> w4Rules; // ortam + calisma
  // W5 artık puanUyumu() fonksiyonuyla hesaplanıyor (engine'de)
  final Map<String, double> w6Rules; // süre
  final Map<String, double> w7Rules; // stres

  const DepartmentProfile({
    required this.id,
    required this.name,
    required this.type,
    required this.scoreType,
    required this.duration,
    required this.maxRanking,
    required this.w1Rules,
    required this.w2Rules,
    required this.w3Rules,
    required this.w4Rules,
    required this.w6Rules,
    required this.w7Rules,
  });
}

class DepartmentProfiles {
  static const List<DepartmentProfile> all = [
    // ─── Tıp ──────────────────────────────────────────────────
    DepartmentProfile(
      id: 'tip',
      name: 'Tıp',
      type: 'Lisans',
      scoreType: 'say',
      duration: 6,
      maxRanking: 27521,
      w1Rules: {'alan:bio': 1.0, 'alan:ea': 0.3, 'ders:kim_bio': 1.0, 'ders:dengeli': 0.5},
      w2Rules: {'ilgi:saglik': 1.0, 'kimlik:kurtarici': 1.0},
      w3Rules: {'hedef:klinik': 1.0, 'hedef:akademi': 0.5, 'gelir:uzun_vade': 1.0, 'gelir:onem_vermez': 0.7},
      w4Rules: {'ortam:klinik': 1.0, 'calisma:insan': 1.0},
      w6Rules: {'sure:6': 1.0, 'sure:farketmez': 1.0, 'sure:5': 0.5, 'sure:4': 0.0},
      w7Rules: {'stres:yuksek': 1.0, 'stres:orta': 0.5, 'stres:dusuk': 0.0},
    ),

    // ─── Diş Hekimliği ────────────────────────────────────────
    DepartmentProfile(
      id: 'dis',
      name: 'Diş Hekimliği',
      type: 'Lisans',
      scoreType: 'say',
      duration: 5,
      maxRanking: 39647,
      w1Rules: {'alan:bio': 1.0, 'alan:ea': 0.5, 'ders:kim_bio': 1.0, 'ders:dengeli': 0.5},
      w2Rules: {'ilgi:saglik': 1.0, 'kimlik:kurtarici': 0.8},
      w3Rules: {'hedef:klinik': 1.0, 'gelir:uzun_vade': 1.0},
      w4Rules: {'ortam:klinik': 1.0, 'calisma:insan': 1.0},
      w6Rules: {'sure:5': 1.0, 'sure:6': 1.0, 'sure:farketmez': 1.0, 'sure:4': 0.2},
      w7Rules: {'stres:yuksek': 1.0, 'stres:orta': 0.7},
    ),

    // ─── Veteriner ────────────────────────────────────────────
    DepartmentProfile(
      id: 'veteriner',
      name: 'Veteriner',
      type: 'Lisans',
      scoreType: 'say',
      duration: 5,
      maxRanking: 169294,
      w1Rules: {'alan:bio': 1.0, 'ders:kim_bio': 1.0},
      w2Rules: {'ilgi:hayvan': 1.0, 'kimlik:koruyucu': 1.0},
      w3Rules: {'hedef:klinik': 1.0, 'gelir:onem_vermez': 0.8},
      w4Rules: {'ortam:saha': 1.0, 'ortam:klinik': 1.0, 'calisma:hayvan': 1.0},
      w6Rules: {'sure:5': 1.0, 'sure:6': 1.0, 'sure:farketmez': 1.0, 'sure:4': 0.3},
      w7Rules: {'stres:yuksek': 1.0, 'stres:orta': 1.0},
    ),

    // ─── Hukuk ────────────────────────────────────────────────
    DepartmentProfile(
      id: 'hukuk',
      name: 'Hukuk',
      type: 'Lisans',
      scoreType: 'ea',
      duration: 4,
      maxRanking: 53204,
      w1Rules: {'alan:sozel': 1.0, 'alan:ea': 1.0, 'alan:bio': 0.0, 'ders:sozel': 1.0, 'ders:dengeli': 0.7},
      w2Rules: {'ilgi:hukuk': 1.0, 'kimlik:adaletci': 1.0},
      w3Rules: {'hedef:hukuk': 1.0, 'hedef:akademi': 0.5, 'gelir:uzun_vade': 0.8},
      w4Rules: {'ortam:kurum': 1.0, 'ortam:ofis': 1.0, 'calisma:belge': 1.0, 'calisma:insan': 0.7},
      w6Rules: {'sure:4': 1.0, 'sure:farketmez': 1.0},
      w7Rules: {'stres:orta': 1.0, 'stres:yuksek': 1.0, 'stres:dusuk': 0.5},
    ),

    // ─── Bilgisayar Mühendisliği ──────────────────────────────
    DepartmentProfile(
      id: 'bilgisayar_muh',
      name: 'Bilgisayar Mühendisliği',
      type: 'Lisans',
      scoreType: 'say',
      duration: 4,
      maxRanking: 223315,
      w1Rules: {'alan:sayi': 1.0, 'alan:ea': 0.4, 'ders:mat_fiz': 1.0, 'ders:dengeli': 0.7},
      w2Rules: {'ilgi:kod': 1.0, 'ilgi:yazilim': 1.0, 'kimlik:kodcu': 1.0, 'kimlik:insaatci': 1.0},
      w3Rules: {'hedef:yazilim': 1.0, 'hedef:muhendis': 1.0, 'hedef:girisim': 1.0, 'hedef:yurtdisi': 0.7, 'gelir:kisa_vade': 0.8},
      w4Rules: {'ortam:ofis': 1.0, 'ortam:lab': 1.0, 'calisma:sistem': 1.0},
      w6Rules: {'sure:4': 1.0, 'sure:farketmez': 1.0},
      w7Rules: {'stres:yuksek': 1.0, 'stres:orta': 1.0, 'stres:dusuk': 1.0},
    ),

    // ─── Elektrik-Elektronik Mühendisliği ─────────────────────
    DepartmentProfile(
      id: 'ee_muh',
      name: 'Elektrik-Elektronik Mühendisliği',
      type: 'Lisans',
      scoreType: 'say',
      duration: 4,
      maxRanking: 293633,
      w1Rules: {'alan:sayi': 1.0, 'ders:mat_fiz': 1.0, 'ders:dengeli': 0.5},
      w2Rules: {'ilgi:elektronik': 1.0, 'ilgi:kod': 0.6, 'kimlik:insaatci': 0.8},
      w3Rules: {'hedef:muhendis': 1.0, 'hedef:yazilim': 0.5, 'gelir:kisa_vade': 0.7},
      w4Rules: {'ortam:lab': 1.0, 'ortam:ofis': 1.0, 'calisma:sistem': 1.0},
      w6Rules: {'sure:4': 1.0, 'sure:farketmez': 1.0},
      w7Rules: {'stres:yuksek': 1.0, 'stres:orta': 1.0, 'stres:dusuk': 1.0},
    ),

    // ─── Gastronomi ve Mutfak Sanatları ───────────────────────
    DepartmentProfile(
      id: 'gastronomi',
      name: 'Gastronomi ve Mutfak Sanatları',
      type: 'Lisans',
      scoreType: 'soz',
      duration: 4,
      maxRanking: 147236,
      w1Rules: {'alan:sozel': 1.0, 'alan:ea': 1.0, 'alan:sayi': 0.2, 'ders:sozel': 0.8, 'ders:dengeli': 0.8},
      w2Rules: {'ilgi:yemek': 1.0, 'kimlik:yaratici': 1.0},
      w3Rules: {'hedef:girisim': 1.0, 'hedef:yurtdisi': 0.8, 'gelir:onem_vermez': 0.8},
      w4Rules: {'ortam:atolye': 1.0, 'calisma:urun': 1.0},
      w6Rules: {'sure:4': 1.0, 'sure:farketmez': 1.0},
      w7Rules: {'stres:dusuk': 1.0, 'stres:orta': 1.0},
    ),

    // ─── Bilgisayar Programcılığı (Önlisans) ─────────────────
    DepartmentProfile(
      id: 'bil_prog',
      name: 'Bilgisayar Programcılığı',
      type: 'Önlisans',
      scoreType: 'tyt',
      duration: 2,
      maxRanking: 1203843,
      w1Rules: {'alan:sayi': 1.0, 'alan:ea': 1.0, 'ders:mat_fiz': 1.0, 'ders:dengeli': 0.8},
      w2Rules: {'ilgi:kod': 1.0, 'ilgi:yazilim': 1.0, 'kimlik:kodcu': 0.8},
      w3Rules: {'hedef:yazilim': 1.0, 'hedef:girisim': 0.7, 'gelir:kisa_vade': 1.0},
      w4Rules: {'ortam:ofis': 1.0, 'calisma:sistem': 1.0},
      w6Rules: {'sure:4': 1.0, 'sure:farketmez': 1.0},
      w7Rules: {'stres:yuksek': 1.0, 'stres:orta': 1.0, 'stres:dusuk': 1.0},
    ),

    // ─── İlk ve Acil Yardım (Önlisans) ───────────────────────
    DepartmentProfile(
      id: 'acil_yardim',
      name: 'İlk ve Acil Yardım',
      type: 'Önlisans',
      scoreType: 'tyt',
      duration: 2,
      maxRanking: 577419,
      w1Rules: {'alan:bio': 1.0, 'alan:sayi': 1.0, 'ders:kim_bio': 1.0, 'ders:dengeli': 0.7},
      w2Rules: {'ilgi:saglik': 1.0, 'kimlik:kurtarici': 1.0},
      w3Rules: {'hedef:klinik': 1.0, 'gelir:kisa_vade': 0.8},
      w4Rules: {'ortam:saha': 1.0, 'ortam:klinik': 1.0, 'calisma:insan': 1.0},
      w6Rules: {'sure:4': 1.0, 'sure:farketmez': 1.0},
      w7Rules: {'stres:yuksek': 1.0, 'stres:orta': 0.7},
    ),
  ];
}
