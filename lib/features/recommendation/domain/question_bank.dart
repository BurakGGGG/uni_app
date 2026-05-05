import 'package:flutter/material.dart';
import 'models/recommendation_question.dart';

class QuestionBank {
  static const List<RecommendationQuestion> questions = [
    // ─── S1: Alan ──────────────────────────────────────────────
    RecommendationQuestion(
      id: 'alan',
      question: 'Hangi alanda kendini güçlü hissediyorsun?',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(id: 'sayi', label: 'Sayısal / Matematik-Fizik',
            icon: Icons.functions_rounded, tags: {'alan': 'sayi'}),
        QuestionOption(id: 'sozel', label: 'Sözel / Dil-Edebiyat',
            icon: Icons.menu_book_rounded, tags: {'alan': 'sozel'}),
        QuestionOption(id: 'ea', label: 'Eşit Ağırlık',
            icon: Icons.balance_rounded, tags: {'alan': 'ea'}),
        QuestionOption(id: 'bio', label: 'Biyoloji / Kimya ağırlıklı',
            icon: Icons.biotech_rounded, tags: {'alan': 'bio'}),
      ],
    ),

    // ─── S2: Puan ──────────────────────────────────────────────
    RecommendationQuestion(
      id: 'puan',
      question: 'TYT + AYT sıralaman hangi aralıkta?',
      hint: 'Yaklaşık sıralaman yeterli, kesin olmasa da olur',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(id: 'cok_iyi', label: 'İlk 5.000 (200 altı)',
            icon: Icons.emoji_events_rounded, tags: {'puan': 'cok_iyi'}),
        QuestionOption(id: 'iyi', label: '5.000 – 50.000 arası',
            icon: Icons.trending_up_rounded, tags: {'puan': 'iyi'}),
        QuestionOption(id: 'orta', label: '50.000 – 200.000 arası',
            icon: Icons.horizontal_rule_rounded, tags: {'puan': 'orta'}),
        QuestionOption(id: 'dusuk', label: '200.000 üstü / Bilmiyorum',
            icon: Icons.help_outline_rounded, tags: {'puan': 'dusuk'}),
      ],
    ),

    // ─── S3: Şehir ─────────────────────────────────────────────
    RecommendationQuestion(
      id: 'sehir',
      question: 'Hangi şehirde okumak istersin?',
      hint: 'En fazla 3 şehir seçebilirsin',
      type: QuestionType.multiSelect,
      maxSelections: 3,
      options: [
        QuestionOption(id: 'istanbul', label: 'İstanbul', icon: Icons.location_city_rounded, tags: {'sehir': 'istanbul'}),
        QuestionOption(id: 'ankara', label: 'Ankara', icon: Icons.account_balance_rounded, tags: {'sehir': 'ankara'}),
        QuestionOption(id: 'izmir', label: 'İzmir', icon: Icons.wb_sunny_rounded, tags: {'sehir': 'izmir'}),
        QuestionOption(id: 'bursa', label: 'Bursa', icon: Icons.park_rounded, tags: {'sehir': 'bursa'}),
        QuestionOption(id: 'eskisehir', label: 'Eskişehir', icon: Icons.school_rounded, tags: {'sehir': 'eskisehir'}),
        QuestionOption(id: 'antalya', label: 'Antalya / Alanya', icon: Icons.beach_access_rounded, tags: {'sehir': 'antalya'}),
        QuestionOption(id: 'trabzon', label: 'Trabzon / Karadeniz', icon: Icons.terrain_rounded, tags: {'sehir': 'trabzon'}),
        QuestionOption(id: 'mersin', label: 'Mersin / Tarsus', icon: Icons.water_rounded, tags: {'sehir': 'mersin'}),
        QuestionOption(id: 'sivas', label: 'Sivas', icon: Icons.landscape_rounded, tags: {'sehir': 'sivas'}),
        QuestionOption(id: 'canakkale', label: 'Çanakkale', icon: Icons.flag_rounded, tags: {'sehir': 'canakkale'}),
        QuestionOption(id: 'farketmez', label: 'Fark etmez', icon: Icons.public_rounded, tags: {'sehir': 'farketmez'}),
      ],
    ),

    // ─── S4: Üniversite Tipi ───────────────────────────────────
    RecommendationQuestion(
      id: 'tip',
      question: 'Devlet mi, vakıf üniversitesi mi tercih edersin?',
      hint: 'Vakıf üniversiteleri burs imkanları sunabilir',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(id: 'devlet', label: 'Kesinlikle devlet', icon: Icons.flag_rounded, tags: {'tip': 'devlet'}),
        QuestionOption(id: 'devlet_oncelikli', label: 'Önce devlet, burs varsa vakıf da olur', icon: Icons.swap_horiz_rounded, tags: {'tip': 'devlet_oncelikli'}),
        QuestionOption(id: 'burslu_vakif', label: 'Burslu vakıf da olabilir', icon: Icons.card_giftcard_rounded, tags: {'tip': 'burslu_vakif'}),
        QuestionOption(id: 'farketmez', label: 'Fark etmez', icon: Icons.all_inclusive_rounded, tags: {'tip': 'farketmez'}),
      ],
    ),

    // ─── S5: Kariyer Hedefi ────────────────────────────────────
    RecommendationQuestion(
      id: 'hedef',
      question: 'Mezun olduktan sonra ne yapmayı hayal ediyorsun?',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(id: 'klinik', label: 'Klinik / sahada aktif çalışmak', icon: Icons.medical_services_rounded, tags: {'hedef': 'klinik'}),
        QuestionOption(id: 'muhendis', label: 'Mühendislik / teknik proje geliştirmek', icon: Icons.engineering_rounded, tags: {'hedef': 'muhendis'}),
        QuestionOption(id: 'yazilim', label: 'Yazılım / teknoloji şirketinde çalışmak', icon: Icons.code_rounded, tags: {'hedef': 'yazilim'}),
        QuestionOption(id: 'akademi', label: 'Akademik kariyer / araştırma', icon: Icons.science_rounded, tags: {'hedef': 'akademi'}),
        QuestionOption(id: 'hukuk', label: 'Hukuki alanda / avukatlık', icon: Icons.gavel_rounded, tags: {'hedef': 'hukuk'}),
        QuestionOption(id: 'girisim', label: 'Kendi işini kurmak / girişimcilik', icon: Icons.rocket_launch_rounded, tags: {'hedef': 'girisim'}),
        QuestionOption(id: 'yurtdisi', label: 'Yurtdışında çalışmak', icon: Icons.flight_takeoff_rounded, tags: {'hedef': 'yurtdisi'}),
      ],
    ),

    // ─── S6: İlgi Alanı ────────────────────────────────────────
    RecommendationQuestion(
      id: 'ilgi',
      question: 'Seni en çok hangisi heyecanlandırıyor?',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(id: 'saglik', label: 'İnsan vücudu ve sağlık', icon: Icons.favorite_rounded, tags: {'ilgi': 'saglik'}),
        QuestionOption(id: 'kod', label: 'Kod yazmak ve algoritmalar', icon: Icons.terminal_rounded, tags: {'ilgi': 'kod'}),
        QuestionOption(id: 'elektronik', label: 'Elektronik devreler ve sistemler', icon: Icons.memory_rounded, tags: {'ilgi': 'elektronik'}),
        QuestionOption(id: 'hayvan', label: 'Hayvanlar ve doğa', icon: Icons.pets_rounded, tags: {'ilgi': 'hayvan'}),
        QuestionOption(id: 'yemek', label: 'Yemek kültürü ve yaratıcılık', icon: Icons.restaurant_rounded, tags: {'ilgi': 'yemek'}),
        QuestionOption(id: 'hukuk', label: 'Hukuk, adalet ve toplum', icon: Icons.gavel_rounded, tags: {'ilgi': 'hukuk'}),
        QuestionOption(id: 'yazilim', label: 'Teknoloji ve yazılım', icon: Icons.devices_rounded, tags: {'ilgi': 'yazilim'}),
      ],
    ),

    // ─── S7: Ders Başarısı ─────────────────────────────────────
    RecommendationQuestion(
      id: 'ders',
      question: 'Hangi ders türünde daha başarılıydın?',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(id: 'mat_fiz', label: 'Matematik ve fizik', icon: Icons.calculate_rounded, tags: {'ders': 'mat_fiz'}),
        QuestionOption(id: 'kim_bio', label: 'Kimya ve biyoloji', icon: Icons.science_rounded, tags: {'ders': 'kim_bio'}),
        QuestionOption(id: 'sozel', label: 'Türkçe ve sosyal bilimler', icon: Icons.history_edu_rounded, tags: {'ders': 'sozel'}),
        QuestionOption(id: 'dengeli', label: 'Hepsi dengeli', icon: Icons.pie_chart_rounded, tags: {'ders': 'dengeli'}),
      ],
    ),

    // ─── S8: Çalışma Ortamı ────────────────────────────────────
    RecommendationQuestion(
      id: 'ortam',
      question: 'Çalışma ortamın nasıl olsun?',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(id: 'klinik', label: 'Hastane / klinik gibi yoğun, dinamik', icon: Icons.local_hospital_rounded, tags: {'ortam': 'klinik'}),
        QuestionOption(id: 'ofis', label: 'Ofis / stüdyo, düzenli saatler', icon: Icons.business_center_rounded, tags: {'ortam': 'ofis'}),
        QuestionOption(id: 'saha', label: 'Saha / açık alan, hareket', icon: Icons.nature_people_rounded, tags: {'ortam': 'saha'}),
        QuestionOption(id: 'lab', label: 'Laboratuvar / araştırma merkezi', icon: Icons.biotech_rounded, tags: {'ortam': 'lab'}),
        QuestionOption(id: 'atolye', label: 'Mutfak / üretim atölyesi', icon: Icons.soup_kitchen_rounded, tags: {'ortam': 'atolye'}),
        QuestionOption(id: 'kurum', label: 'Mahkeme / kurum', icon: Icons.account_balance_rounded, tags: {'ortam': 'kurum'}),
      ],
    ),

    // ─── S9: Üniversite Önceliği ───────────────────────────────
    RecommendationQuestion(
      id: 'oncelik',
      question: 'Üniversite hayatında en çok neye önem veriyorsun?',
      hint: 'En fazla 2 tane seçebilirsin',
      type: QuestionType.multiSelect,
      maxSelections: 2,
      options: [
        QuestionOption(id: 'akademi', label: 'Akademik itibar ve öğretim kalitesi', icon: Icons.school_rounded, tags: {'oncelik': 'akademi'}),
        QuestionOption(id: 'kampus', label: 'Kampüs yaşamı ve sosyal imkânlar', icon: Icons.park_rounded, tags: {'oncelik': 'kampus'}),
        QuestionOption(id: 'staj', label: 'Staj ve iş bağlantıları', icon: Icons.work_rounded, tags: {'oncelik': 'staj'}),
        QuestionOption(id: 'mezun', label: 'Mezun ağı (alumni)', icon: Icons.people_alt_rounded, tags: {'oncelik': 'mezun'}),
        QuestionOption(id: 'erasmus', label: 'Uluslararası değişim programları', icon: Icons.flight_rounded, tags: {'oncelik': 'erasmus'}),
        QuestionOption(id: 'konum', label: 'Şehir merkezine yakınlık', icon: Icons.location_on_rounded, tags: {'oncelik': 'konum'}),
      ],
    ),

    // ─── S10: Eğitim Dili ──────────────────────────────────────
    RecommendationQuestion(
      id: 'dil',
      question: 'Eğitim dili tercih eder misin?',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(id: 'turkce', label: 'Türkçe eğitim', icon: Icons.flag_circle_rounded, tags: {'dil': 'turkce'}),
        QuestionOption(id: 'mio', label: '%30 İngilizce (MİO)', icon: Icons.swap_horiz_rounded, tags: {'dil': 'mio'}),
        QuestionOption(id: 'tam_ing', label: 'Tam İngilizce eğitim', icon: Icons.translate_rounded, tags: {'dil': 'tam_ing'}),
        QuestionOption(id: 'farketmez', label: 'Fark etmez', icon: Icons.all_inclusive_rounded, tags: {'dil': 'farketmez'}),
      ],
    ),

    // ─── S11: Yurt ─────────────────────────────────────────────
    RecommendationQuestion(
      id: 'yurt',
      question: 'Yurt / barınma konusundaki beklentin nedir?',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(id: 'kyk', label: 'KYK yurdu yeterli', icon: Icons.hotel_rounded, tags: {'yurt': 'kyk'}),
        QuestionOption(id: 'uni_yurt', label: 'Üniversite yurdu olsun', icon: Icons.apartment_rounded, tags: {'yurt': 'uni_yurt'}),
        QuestionOption(id: 'ev', label: 'Ev tutarım, önemli değil', icon: Icons.home_rounded, tags: {'yurt': 'ev'}),
        QuestionOption(id: 'aile', label: 'Aile yanında kalırım', icon: Icons.family_restroom_rounded, tags: {'yurt': 'aile'}),
      ],
    ),

    // ─── S12: Süre ─────────────────────────────────────────────
    RecommendationQuestion(
      id: 'sure',
      question: 'Bölümün uzunluğu seni etkiler mi?',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(id: '4', label: '4 yıl yeterli', icon: Icons.timer_rounded, tags: {'sure': '4'}),
        QuestionOption(id: '5', label: '5 yıl kabul edilebilir', icon: Icons.more_time_rounded, tags: {'sure': '5'}),
        QuestionOption(id: '6', label: '6 yıl da sorun değil (tıp, diş, vet)', icon: Icons.hourglass_bottom_rounded, tags: {'sure': '6'}),
        QuestionOption(id: 'farketmez', label: 'Fark etmez, hedefime ulaşayım', icon: Icons.all_inclusive_rounded, tags: {'sure': 'farketmez'}),
      ],
    ),

    // ─── S13: Çalışma Tarzı ────────────────────────────────────
    RecommendationQuestion(
      id: 'calisma',
      question: 'İnsan ile mi, makine / sistem ile mi çalışmayı tercih edersin?',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(id: 'insan', label: 'İnsanlarla yüz yüze', icon: Icons.people_rounded, tags: {'calisma': 'insan'}),
        QuestionOption(id: 'sistem', label: 'Teknik sistemler / kod', icon: Icons.computer_rounded, tags: {'calisma': 'sistem'}),
        QuestionOption(id: 'hayvan', label: 'Hayvanlarla', icon: Icons.pets_rounded, tags: {'calisma': 'hayvan'}),
        QuestionOption(id: 'belge', label: 'Belgeler / hukuki metinler', icon: Icons.description_rounded, tags: {'calisma': 'belge'}),
        QuestionOption(id: 'urun', label: 'Malzeme / ürün / yemek', icon: Icons.inventory_2_rounded, tags: {'calisma': 'urun'}),
      ],
    ),

    // ─── S14: Stres ────────────────────────────────────────────
    RecommendationQuestion(
      id: 'stres',
      question: 'Stres ve baskıyla başa çıkma konusunda kendini nasıl değerlendiriyorsun?',
      hint: 'Bu cevap tıp, diş, acil yardım gibi bölümlerin uyum skorunu etkiler',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(id: 'yuksek', label: 'Yüksek baskı altında daha iyi çalışırım', icon: Icons.flash_on_rounded, tags: {'stres': 'yuksek'}),
        QuestionOption(id: 'orta', label: 'Orta düzeyde baskı ideal', icon: Icons.tune_rounded, tags: {'stres': 'orta'}),
        QuestionOption(id: 'dusuk', label: 'Sakin ve düzenli ortam isterim', icon: Icons.spa_rounded, tags: {'stres': 'dusuk'}),
      ],
    ),

    // ─── S15: Gelir ────────────────────────────────────────────
    RecommendationQuestion(
      id: 'gelir',
      question: 'Mezuniyet sonrası gelir beklentin?',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(id: 'uzun_vade', label: 'İlk yıllarda düşük olsa da, uzun vadede yüksek olsun', icon: Icons.trending_up_rounded, tags: {'gelir': 'uzun_vade'}),
        QuestionOption(id: 'kisa_vade', label: 'En kısa sürede iyi maaş istiyorum', icon: Icons.attach_money_rounded, tags: {'gelir': 'kisa_vade'}),
        QuestionOption(id: 'onem_vermez', label: 'Para ikincil, işi sevmek önemli', icon: Icons.volunteer_activism_rounded, tags: {'gelir': 'onem_vermez'}),
      ],
    ),

    // ─── S16: Yurt dışı ────────────────────────────────────────
    RecommendationQuestion(
      id: 'yurtdisi',
      question: 'Yurt dışında çalışmak / eğitim almak planın var mı?',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(id: 'evet', label: 'Evet, kesinlikle planım var', icon: Icons.public_rounded, tags: {'yurtdisi': 'evet'}),
        QuestionOption(id: 'belki', label: 'Belki ileride düşünebilirim', icon: Icons.help_outline_rounded, tags: {'yurtdisi': 'belki'}),
        QuestionOption(id: 'hayir', label: 'Hayır, Türkiye\'de kalmayı planlıyorum', icon: Icons.home_rounded, tags: {'yurtdisi': 'hayir'}),
      ],
    ),

    // ─── S17: Pratik/Teorik ────────────────────────────────────
    RecommendationQuestion(
      id: 'stil',
      question: 'Pratik mi, teorik mi?',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(id: 'pratik', label: 'Ellerimi kirletmek, uygulamak istiyorum', icon: Icons.construction_rounded, tags: {'stil': 'pratik'}),
        QuestionOption(id: 'teorik', label: 'Araştırmak, analiz etmek istiyorum', icon: Icons.auto_stories_rounded, tags: {'stil': 'teorik'}),
        QuestionOption(id: 'karma', label: 'İkisi de eşit ölçüde', icon: Icons.balance_rounded, tags: {'stil': 'karma'}),
      ],
    ),

    // ─── S18: Kimlik ───────────────────────────────────────────
    RecommendationQuestion(
      id: 'kimlik',
      question: 'Aşağıdaki ifadelerden hangisi seni en iyi tanımlar?',
      type: QuestionType.singleSelect,
      options: [
        QuestionOption(id: 'kurtarici', label: '"Hayat kurtarmak istiyorum"', icon: Icons.health_and_safety_rounded, tags: {'kimlik': 'kurtarici'}),
        QuestionOption(id: 'insaatci', label: '"Sistemleri inşa etmek istiyorum"', icon: Icons.build_rounded, tags: {'kimlik': 'insaatci'}),
        QuestionOption(id: 'adaletci', label: '"Adaleti sağlamak istiyorum"', icon: Icons.gavel_rounded, tags: {'kimlik': 'adaletci'}),
        QuestionOption(id: 'yaratici', label: '"Lezzetli şeyler yaratmak istiyorum"', icon: Icons.restaurant_rounded, tags: {'kimlik': 'yaratici'}),
        QuestionOption(id: 'kodcu', label: '"Kod ile dünyayı değiştirmek istiyorum"', icon: Icons.terminal_rounded, tags: {'kimlik': 'kodcu'}),
        QuestionOption(id: 'koruyucu', label: '"Hayvanları korumak istiyorum"', icon: Icons.pets_rounded, tags: {'kimlik': 'koruyucu'}),
      ],
    ),
  ];
}
