import 'package:flutter/material.dart';
import 'models/recommendation_question.dart';

class QuestionBank {
  /// 9 soru — yeniden tasarlandı:
  /// • Tekrarlı sorular (hedef/ilgi/kimlik) tek soruda birleşti.
  /// • Alan + puan türü tekrarı kaldırıldı, sadece puan türü kaldı.
  /// • Sıralama 12 buton yerine slider (UX hızlanması).
  /// • Yeni boyutlar eklendi: motivasyon, bütçe, risk toleransı, şehir profili.
  static const List<RecommendationQuestion> questions = [
    // ─── S1: Puan Türü ────────────────────────────────────────
    RecommendationQuestion(
      id: 'puan_turu',
      question: 'Hangi puan türüyle başvurmayı planlıyorsun?',
      hint: 'Henüz emin değilsen "Bilmiyorum" diyebilirsin — sonradan filtreleyebilirsin.',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(
          id: 'say',
          label: 'SAY (Sayısal)',
          subtitle: 'Mühendislik, Tıp, Fen…',
          icon: Icons.calculate_rounded,
          tags: {'puanTuru': 'say', 'alan': 'sayi'},
        ),
        QuestionOption(
          id: 'ea',
          label: 'EA (Eşit Ağırlık)',
          subtitle: 'Hukuk, İşletme, Psikoloji…',
          icon: Icons.balance_rounded,
          tags: {'puanTuru': 'ea', 'alan': 'ea'},
        ),
        QuestionOption(
          id: 'soz',
          label: 'SÖZ (Sözel)',
          subtitle: 'Edebiyat, Tarih, Hukuk…',
          icon: Icons.menu_book_rounded,
          tags: {'puanTuru': 'soz', 'alan': 'sozel'},
        ),
        QuestionOption(
          id: 'dil',
          label: 'DİL',
          subtitle: 'Öğretmenlik, Mütercim-Tercümanlık…',
          icon: Icons.translate_rounded,
          tags: {'puanTuru': 'dil', 'alan': 'sozel'},
        ),
        QuestionOption(
          id: 'tyt',
          label: 'TYT (Önlisans)',
          subtitle: 'İki yıllık programlar',
          icon: Icons.school_rounded,
          tags: {'puanTuru': 'tyt'},
        ),
        QuestionOption(
          id: 'belirsiz',
          label: 'Henüz bilmiyorum',
          icon: Icons.help_outline_rounded,
          tags: {'puanTuru': 'belirsiz'},
        ),
      ],
    ),

    // ─── S2: Sıralama (range slider) ──────────────────────────
    RecommendationQuestion(
      id: 'siralama',
      question: 'Tahmini sıralaman hangi aralıkta?',
      hint: 'İki taraftan da daraltarak bir aralık seç. '
          'Deneme sınavlarındaki en iyi/en kötü sıralamana göre belirleyebilirsin.',
      type: QuestionType.rangeSlider,
      slider: SliderConfig(
        tagKey: 'siralama',
        snaps: [
          SliderSnap(value: 0, label: '1.000', tagValue: '500'),
          SliderSnap(value: 1, label: '5.000', tagValue: '5000'),
          SliderSnap(value: 2, label: '15.000', tagValue: '15000'),
          SliderSnap(value: 3, label: '40.000', tagValue: '40000'),
          SliderSnap(value: 4, label: '100.000', tagValue: '100000'),
          SliderSnap(value: 5, label: '250.000', tagValue: '250000'),
          SliderSnap(value: 6, label: '500.000', tagValue: '500000'),
          SliderSnap(value: 7, label: '1.000.000+', tagValue: '1500000'),
        ],
      ),
    ),

    // ─── S3: Kariyer Alanı (S6+S7+S8 birleşti) ────────────────
    RecommendationQuestion(
      id: 'kariyer_alani',
      question: 'Hangi alanda kariyer hayalin var?',
      hint: 'Hayalin birden fazla alana taşıyorsa en yakın olanı seç.',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(
          id: 'saglik',
          label: 'Sağlık & Tıp',
          subtitle: 'Tıp, Diş Hekimliği, Eczacılık, Hemşirelik',
          icon: Icons.medical_services_rounded,
          tags: {'kariyer': 'saglik', 'ilgi': 'saglik', 'kimlik': 'kurtarici', 'hedef': 'klinik'},
        ),
        QuestionOption(
          id: 'muhendislik',
          label: 'Mühendislik & Teknoloji',
          subtitle: 'Bilgisayar, Elektrik, İnşaat, Makine…',
          icon: Icons.engineering_rounded,
          tags: {'kariyer': 'muhendislik', 'ilgi': 'kod', 'kimlik': 'insaatci', 'hedef': 'muhendis'},
        ),
        QuestionOption(
          id: 'hukuk_kamu',
          label: 'Hukuk & Kamu',
          subtitle: 'Hukuk, Siyaset, Kamu Yönetimi',
          icon: Icons.gavel_rounded,
          tags: {'kariyer': 'hukuk', 'ilgi': 'hukuk', 'kimlik': 'adaletci', 'hedef': 'hukuk'},
        ),
        QuestionOption(
          id: 'isletme_ekonomi',
          label: 'İşletme & Ekonomi',
          subtitle: 'İşletme, İktisat, Maliye, Finans',
          icon: Icons.trending_up_rounded,
          tags: {'kariyer': 'isletme', 'ilgi': 'isletme', 'hedef': 'girisim'},
        ),
        QuestionOption(
          id: 'egitim_sosyal',
          label: 'Eğitim & Sosyal',
          subtitle: 'Öğretmenlik, Psikoloji, Sosyal Hizmet',
          icon: Icons.school_rounded,
          tags: {'kariyer': 'egitim', 'ilgi': 'egitim', 'kimlik': 'rehber', 'hedef': 'egitim'},
        ),
        QuestionOption(
          id: 'yaratici',
          label: 'Yaratıcı & Tasarım',
          subtitle: 'Mimarlık, İç Mimarlık, Gastronomi, Sanat',
          icon: Icons.brush_rounded,
          tags: {'kariyer': 'yaratici', 'ilgi': 'yemek', 'kimlik': 'yaratici'},
        ),
        QuestionOption(
          id: 'bilim_arastirma',
          label: 'Bilim & Araştırma',
          subtitle: 'Fen, Matematik, Biyoloji, Akademik kariyer',
          icon: Icons.science_rounded,
          tags: {'kariyer': 'bilim', 'ilgi': 'bilim', 'hedef': 'akademi'},
        ),
        QuestionOption(
          id: 'belirsiz',
          label: 'Henüz emin değilim',
          subtitle: 'Bana yelpazeden öneriler göster',
          icon: Icons.explore_rounded,
          tags: {'kariyer': 'belirsiz'},
        ),
      ],
    ),

    // ─── S4: Motivasyon ───────────────────────────────────────
    RecommendationQuestion(
      id: 'motivasyon',
      question: 'Bu alana yönelmenin ana nedeni hangisi?',
      hint: 'Sana uygun bölümleri seçerken bu önemli — birden fazla geçerliyse en güçlü olanı seç.',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(
          id: 'tutku',
          label: 'İlgim ve tutkum',
          subtitle: 'O alanda zaman geçirmeyi seviyorum',
          icon: Icons.favorite_rounded,
          tags: {'motivasyon': 'tutku'},
        ),
        QuestionOption(
          id: 'gelir',
          label: 'Maddi getiri / iş garantisi',
          subtitle: 'İyi maaş ve iş güvencesi önemli',
          icon: Icons.attach_money_rounded,
          tags: {'motivasyon': 'gelir'},
        ),
        QuestionOption(
          id: 'toplum',
          label: 'Topluma fayda sağlamak',
          subtitle: 'İnsanlara dokunan bir iş yapmak istiyorum',
          icon: Icons.volunteer_activism_rounded,
          tags: {'motivasyon': 'toplum'},
        ),
        QuestionOption(
          id: 'aile',
          label: 'Ailem yönlendirdi / mantıklı buldum',
          subtitle: 'Çevremin önerisiyle ilerliyorum',
          icon: Icons.groups_rounded,
          tags: {'motivasyon': 'aile'},
        ),
      ],
    ),

    // ─── S5: Şehir Profili ────────────────────────────────────
    RecommendationQuestion(
      id: 'sehir',
      question: 'Nasıl bir şehirde okumak istersin?',
      hint: 'Birden fazla profil seçebilirsin — en fazla 2.',
      type: QuestionType.multiSelect,
      maxSelections: 2,
      options: [
        QuestionOption(
          id: 'buyuk_metropol',
          label: 'Büyük metropol',
          subtitle: 'İstanbul, Ankara, İzmir — hareketli, kalabalık',
          icon: Icons.location_city_rounded,
          tags: {'sehirTipi': 'buyuk'},
        ),
        QuestionOption(
          id: 'orta_dengeli',
          label: 'Orta ölçekli şehir',
          subtitle: 'Bursa, Eskişehir, Antalya — dengeli',
          icon: Icons.location_on_rounded,
          tags: {'sehirTipi': 'orta'},
        ),
        QuestionOption(
          id: 'sakin_kucuk',
          label: 'Sakin / küçük şehir',
          subtitle: 'Çanakkale, Trabzon, Sivas, Hitit — odaklı',
          icon: Icons.terrain_rounded,
          tags: {'sehirTipi': 'sakin'},
        ),
        QuestionOption(
          id: 'farketmez',
          label: 'Şehir farketmez',
          subtitle: 'Önemli olan doğru bölüm / üniversite',
          icon: Icons.public_rounded,
          tags: {'sehir': 'farketmez', 'sehirTipi': 'farketmez'},
        ),
      ],
    ),

    // ─── S6: Bütçe Profili ────────────────────────────────────
    RecommendationQuestion(
      id: 'butce',
      question: 'Vakıf üniversitesi için bütçen ne durumda?',
      hint: 'Bu, devlet/vakıf önerisini doğrudan etkiler.',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(
          id: 'sadece_devlet',
          label: 'Sadece devlet',
          subtitle: 'Vakıf bütçeme uymaz',
          icon: Icons.account_balance_rounded,
          tags: {'tip': 'devlet', 'butce': 'devlet'},
        ),
        QuestionOption(
          id: 'tam_burs_vakif',
          label: 'Tam burs şartıyla vakıf',
          subtitle: 'Burslu olursa vakıf da düşünürüm',
          icon: Icons.card_giftcard_rounded,
          tags: {'tip': 'burslu_vakif', 'butce': 'tam_burs'},
        ),
        QuestionOption(
          id: 'ucretli_olabilir',
          label: 'Yıllık ücret ödeyebilirim',
          subtitle: 'Vakıf da serbestçe değerlendirebilirim',
          icon: Icons.payments_rounded,
          tags: {'tip': 'farketmez', 'butce': 'ucretli_ok'},
        ),
      ],
    ),

    // ─── S7: Üniversite Önceliği ──────────────────────────────
    RecommendationQuestion(
      id: 'oncelik',
      question: 'Üniversite hayatında en çok neye değer veriyorsun?',
      hint: 'En fazla 2 tane seçebilirsin.',
      type: QuestionType.multiSelect,
      maxSelections: 2,
      options: [
        QuestionOption(
          id: 'akademi',
          label: 'Akademik kalite',
          subtitle: 'İyi hocalar, ders kalitesi',
          icon: Icons.school_rounded,
          tags: {'oncelik': 'akademi'},
        ),
        QuestionOption(
          id: 'kampus',
          label: 'Kampüs & sosyal hayat',
          subtitle: 'Öğrenci kulüpleri, etkinlikler',
          icon: Icons.park_rounded,
          tags: {'oncelik': 'kampus'},
        ),
        QuestionOption(
          id: 'staj',
          label: 'Staj & iş bağlantıları',
          subtitle: 'Sektöre yakın, kariyer odaklı',
          icon: Icons.work_rounded,
          tags: {'oncelik': 'staj'},
        ),
        QuestionOption(
          id: 'erasmus',
          label: 'Uluslararası değişim',
          subtitle: 'Erasmus, yurt dışı imkânları',
          icon: Icons.flight_rounded,
          tags: {'oncelik': 'erasmus'},
        ),
        QuestionOption(
          id: 'mezun',
          label: 'Mezun ağı',
          subtitle: 'Güçlü alumni topluluğu',
          icon: Icons.people_alt_rounded,
          tags: {'oncelik': 'mezun'},
        ),
        QuestionOption(
          id: 'konum',
          label: 'Şehir merkezine yakınlık',
          subtitle: 'Ulaşım, sosyal alan',
          icon: Icons.location_on_rounded,
          tags: {'oncelik': 'konum'},
        ),
      ],
    ),

    // ─── S8: Risk Toleransı ───────────────────────────────────
    RecommendationQuestion(
      id: 'risk',
      question: 'Önerilerimiz nasıl olsun?',
      hint: 'Sıralamana göre risk profilini ayarlıyoruz.',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(
          id: 'garanti',
          label: 'Garanti — rahat girebileceğim yerler',
          subtitle: 'Sıralamamın altında olanlar',
          icon: Icons.verified_rounded,
          tags: {'risk': 'garanti'},
        ),
        QuestionOption(
          id: 'denge',
          label: 'Dengeli — hem garanti hem hedef',
          subtitle: 'Karışık öneriler',
          icon: Icons.balance_rounded,
          tags: {'risk': 'denge'},
        ),
        QuestionOption(
          id: 'yuksek',
          label: 'Yüksek hedef — sıralamamı zorlasın',
          subtitle: 'Sınırda ve riskli olanlar dahil',
          icon: Icons.rocket_launch_rounded,
          tags: {'risk': 'yuksek'},
        ),
      ],
    ),

    // ─── S9: Eğitim Dili ──────────────────────────────────────
    RecommendationQuestion(
      id: 'dil',
      question: 'Eğitim dili tercih eder misin?',
      hint: 'Belirsizsen "Fark etmez" seç — geniş yelpaze gelir.',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(
          id: 'turkce',
          label: 'Türkçe eğitim',
          icon: Icons.flag_circle_rounded,
          tags: {'dil': 'turkce'},
        ),
        QuestionOption(
          id: 'mio',
          label: '%30 İngilizce (MİO)',
          subtitle: 'Karma',
          icon: Icons.swap_horiz_rounded,
          tags: {'dil': 'mio'},
        ),
        QuestionOption(
          id: 'tam_ing',
          label: 'Tam İngilizce',
          icon: Icons.translate_rounded,
          tags: {'dil': 'tam_ing'},
        ),
        QuestionOption(
          id: 'farketmez',
          label: 'Fark etmez',
          icon: Icons.all_inclusive_rounded,
          tags: {'dil': 'farketmez'},
        ),
      ],
    ),
  ];
}
