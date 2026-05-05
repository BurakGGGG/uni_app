// Bölüm profilleri: Her bölüm için W1-W7 kurallarına göre
// hangi tag değerlerinin tam (1.0) veya kısmi (0.5, 0.3, vb.) eşleştiği.
//
// Ağırlık tablosu (toplam 100):
// W1 (alan+ders): 25  |  W2 (ilgi+kimlik): 20  |  W3 (hedef+gelir): 15
// W4 (ortam+calisma): 15  |  W5 (puan): 10  |  W6 (süre): 10  |  W7 (stres): 5

class DepartmentProfile {
  final String id;
  final String name;
  final int duration; // yıl
  final Map<String, double> w1Rules; // alan + ders eşleşmeleri
  final Map<String, double> w2Rules; // ilgi + kimlik eşleşmeleri
  final Map<String, double> w3Rules; // hedef + gelir eşleşmeleri
  final Map<String, double> w4Rules; // ortam + calisma eşleşmeleri
  final Map<String, double> w5Rules; // puan eşleşmeleri
  final Map<String, double> w6Rules; // süre eşleşmeleri
  final Map<String, double> w7Rules; // stres eşleşmeleri

  const DepartmentProfile({
    required this.id,
    required this.name,
    required this.duration,
    required this.w1Rules,
    required this.w2Rules,
    required this.w3Rules,
    required this.w4Rules,
    required this.w5Rules,
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
      duration: 6,
      w1Rules: {'alan:bio': 1.0, 'alan:ea': 0.5, 'ders:kim_bio': 1.0, 'ders:dengeli': 0.5},
      w2Rules: {'ilgi:saglik': 1.0, 'kimlik:kurtarici': 1.0},
      w3Rules: {'hedef:klinik': 1.0, 'gelir:uzun_vade': 1.0, 'gelir:onem_vermez': 0.7},
      w4Rules: {'ortam:klinik': 1.0, 'calisma:insan': 1.0},
      w5Rules: {'puan:cok_iyi': 1.0, 'puan:iyi': 0.3},
      w6Rules: {'sure:6': 1.0, 'sure:farketmez': 1.0, 'sure:5': 0.3},
      w7Rules: {'stres:yuksek': 1.0, 'stres:orta': 0.5},
    ),

    // ─── Diş Hekimliği ────────────────────────────────────────
    DepartmentProfile(
      id: 'dis',
      name: 'Diş Hekimliği',
      duration: 5,
      w1Rules: {'alan:bio': 1.0, 'alan:ea': 0.5, 'ders:kim_bio': 1.0, 'ders:dengeli': 0.5},
      w2Rules: {'ilgi:saglik': 1.0, 'kimlik:kurtarici': 0.8},
      w3Rules: {'hedef:klinik': 1.0, 'gelir:uzun_vade': 1.0},
      w4Rules: {'ortam:klinik': 1.0, 'calisma:insan': 1.0},
      w5Rules: {'puan:cok_iyi': 1.0, 'puan:iyi': 0.7},
      w6Rules: {'sure:5': 1.0, 'sure:6': 1.0, 'sure:farketmez': 1.0, 'sure:4': 0.2},
      w7Rules: {'stres:yuksek': 1.0, 'stres:orta': 1.0},
    ),

    // ─── Veterinerlik ─────────────────────────────────────────
    DepartmentProfile(
      id: 'vet',
      name: 'Veterinerlik',
      duration: 5,
      w1Rules: {'alan:bio': 1.0, 'ders:kim_bio': 1.0},
      w2Rules: {'ilgi:hayvan': 1.0, 'kimlik:koruyucu': 1.0},
      w3Rules: {'hedef:klinik': 1.0, 'gelir:onem_vermez': 0.8},
      w4Rules: {'ortam:saha': 1.0, 'ortam:klinik': 1.0, 'calisma:hayvan': 1.0},
      w5Rules: {'puan:cok_iyi': 1.0, 'puan:iyi': 0.8},
      w6Rules: {'sure:5': 1.0, 'sure:6': 1.0, 'sure:farketmez': 1.0, 'sure:4': 0.3},
      w7Rules: {'stres:yuksek': 1.0, 'stres:orta': 1.0},
    ),

    // ─── Hukuk ────────────────────────────────────────────────
    DepartmentProfile(
      id: 'hukuk',
      name: 'Hukuk',
      duration: 4,
      w1Rules: {'alan:sozel': 1.0, 'alan:ea': 1.0, 'ders:sozel': 1.0, 'ders:dengeli': 0.7},
      w2Rules: {'ilgi:hukuk': 1.0, 'kimlik:adaletci': 1.0},
      w3Rules: {'hedef:hukuk': 1.0, 'hedef:akademi': 0.5, 'gelir:uzun_vade': 0.8},
      w4Rules: {'ortam:kurum': 1.0, 'ortam:ofis': 1.0, 'calisma:belge': 1.0, 'calisma:insan': 0.7},
      w5Rules: {'puan:iyi': 1.0, 'puan:cok_iyi': 1.0, 'puan:orta': 0.5},
      w6Rules: {'sure:4': 1.0, 'sure:farketmez': 1.0},
      w7Rules: {'stres:orta': 1.0, 'stres:yuksek': 1.0, 'stres:dusuk': 0.5},
    ),

    // ─── Bilgisayar Mühendisliği ──────────────────────────────
    DepartmentProfile(
      id: 'bilgisayar_muh',
      name: 'Bilgisayar Mühendisliği',
      duration: 4,
      w1Rules: {'alan:sayi': 1.0, 'alan:ea': 0.5, 'ders:mat_fiz': 1.0, 'ders:dengeli': 0.7},
      w2Rules: {'ilgi:kod': 1.0, 'ilgi:yazilim': 1.0, 'kimlik:kodcu': 1.0, 'kimlik:insaatci': 1.0},
      w3Rules: {'hedef:yazilim': 1.0, 'hedef:muhendis': 1.0, 'hedef:girisim': 1.0, 'hedef:yurtdisi': 0.7, 'gelir:kisa_vade': 0.8},
      w4Rules: {'ortam:ofis': 1.0, 'ortam:lab': 1.0, 'calisma:sistem': 1.0},
      w5Rules: {'puan:iyi': 1.0, 'puan:cok_iyi': 1.0, 'puan:orta': 0.5},
      w6Rules: {'sure:4': 1.0, 'sure:farketmez': 1.0},
      w7Rules: {'stres:yuksek': 1.0, 'stres:orta': 1.0, 'stres:dusuk': 1.0},
    ),

    // ─── Yazılım Mühendisliği ─────────────────────────────────
    DepartmentProfile(
      id: 'yazilim_muh',
      name: 'Yazılım Mühendisliği',
      duration: 4,
      w1Rules: {'alan:sayi': 1.0, 'alan:ea': 0.5, 'ders:mat_fiz': 1.0, 'ders:dengeli': 0.7},
      w2Rules: {'ilgi:kod': 1.0, 'ilgi:yazilim': 1.0, 'kimlik:kodcu': 1.0, 'kimlik:insaatci': 1.0},
      w3Rules: {'hedef:yazilim': 1.0, 'hedef:muhendis': 1.0, 'hedef:girisim': 1.0, 'hedef:yurtdisi': 0.7, 'gelir:kisa_vade': 0.8},
      w4Rules: {'ortam:ofis': 1.0, 'ortam:lab': 1.0, 'calisma:sistem': 1.0},
      w5Rules: {'puan:orta': 1.0, 'puan:iyi': 1.0, 'puan:cok_iyi': 1.0, 'puan:dusuk': 0.5},
      w6Rules: {'sure:4': 1.0, 'sure:farketmez': 1.0},
      w7Rules: {'stres:yuksek': 1.0, 'stres:orta': 1.0, 'stres:dusuk': 1.0},
    ),

    // ─── Elektrik-Elektronik Mühendisliği ─────────────────────
    DepartmentProfile(
      id: 'ee_muh',
      name: 'Elektrik-Elektronik Mühendisliği',
      duration: 4,
      w1Rules: {'alan:sayi': 1.0, 'ders:mat_fiz': 1.0, 'ders:dengeli': 0.5},
      w2Rules: {'ilgi:elektronik': 1.0, 'ilgi:kod': 1.0, 'kimlik:insaatci': 1.0},
      w3Rules: {'hedef:muhendis': 1.0, 'hedef:yazilim': 1.0, 'gelir:kisa_vade': 0.7},
      w4Rules: {'ortam:lab': 1.0, 'ortam:ofis': 1.0, 'calisma:sistem': 1.0},
      w5Rules: {'puan:iyi': 1.0, 'puan:cok_iyi': 1.0, 'puan:orta': 0.6},
      w6Rules: {'sure:4': 1.0, 'sure:farketmez': 1.0},
      w7Rules: {'stres:yuksek': 1.0, 'stres:orta': 1.0, 'stres:dusuk': 1.0},
    ),

    // ─── Bilgisayar Programcılığı (MYO) ──────────────────────
    DepartmentProfile(
      id: 'bilgisayar_prog',
      name: 'Bilgisayar Programcılığı',
      duration: 2,
      w1Rules: {'alan:sayi': 1.0, 'alan:ea': 1.0, 'ders:mat_fiz': 1.0, 'ders:dengeli': 0.8},
      w2Rules: {'ilgi:kod': 1.0, 'ilgi:yazilim': 1.0, 'kimlik:kodcu': 0.8},
      w3Rules: {'hedef:yazilim': 1.0, 'hedef:girisim': 0.7, 'gelir:kisa_vade': 1.0},
      w4Rules: {'ortam:ofis': 1.0, 'calisma:sistem': 1.0},
      w5Rules: {'puan:dusuk': 1.0, 'puan:orta': 1.0, 'puan:iyi': 0.5},
      w6Rules: {'sure:4': 1.0, 'sure:farketmez': 1.0},
      w7Rules: {'stres:yuksek': 1.0, 'stres:orta': 1.0, 'stres:dusuk': 1.0},
    ),

    // ─── İlk ve Acil Yardım / Paramedik ──────────────────────
    DepartmentProfile(
      id: 'acil_yardim',
      name: 'İlk ve Acil Yardım',
      duration: 2,
      w1Rules: {'alan:bio': 1.0, 'alan:sayi': 1.0, 'ders:kim_bio': 1.0, 'ders:dengeli': 0.7},
      w2Rules: {'ilgi:saglik': 1.0, 'kimlik:kurtarici': 1.0},
      w3Rules: {'hedef:klinik': 1.0, 'gelir:kisa_vade': 0.8},
      w4Rules: {'ortam:saha': 1.0, 'ortam:klinik': 1.0, 'calisma:insan': 1.0},
      w5Rules: {'puan:dusuk': 1.0, 'puan:orta': 1.0},
      w6Rules: {'sure:4': 1.0, 'sure:farketmez': 1.0},
      w7Rules: {'stres:yuksek': 1.0, 'stres:orta': 0.7},
    ),

    // ─── Gastronomi ───────────────────────────────────────────
    DepartmentProfile(
      id: 'gastronomi',
      name: 'Gastronomi ve Mutfak Sanatları',
      duration: 4,
      w1Rules: {'alan:ea': 1.0, 'alan:sozel': 1.0, 'ders:sozel': 0.8, 'ders:dengeli': 0.8},
      w2Rules: {'ilgi:yemek': 1.0, 'kimlik:yaratici': 1.0},
      w3Rules: {'hedef:girisim': 1.0, 'hedef:yurtdisi': 1.0, 'hedef:muhendis': 0.3, 'gelir:onem_vermez': 0.8},
      w4Rules: {'ortam:atolye': 1.0, 'calisma:urun': 1.0},
      w5Rules: {'puan:dusuk': 1.0, 'puan:orta': 1.0, 'puan:iyi': 0.7},
      w6Rules: {'sure:4': 1.0, 'sure:farketmez': 1.0},
      w7Rules: {'stres:dusuk': 1.0, 'stres:orta': 1.0},
    ),
  ];
}
