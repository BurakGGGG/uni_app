import 'robot_message.dart';
import 'robot_mood.dart';

/// Robotun adı — tüm birinci-ağız metinler bu sabiti kullanır;
/// değiştirmek tek satırdır. Ad her iki dilde de aynıdır.
const String kRobotName = 'Üni';

/// Sonuçlar hesaplanırken gösterilen statik metin (yükleme kısa sürer,
/// typewriter gerekmez).
String get kResultsLoadingText => RobotScripts.isEn
    ? 'Scanning thousands of programs for you…'
    : 'Binlerce programı senin için tarıyorum…';

/// Filtreli aramada hiç eşleşme kalmadığında (WizardEmptyResults).
String get kEmptyResultsFilterText => RobotScripts.isEn
    ? "I couldn't find any programs matching these filters — shall we "
        'loosen a few?'
    : 'Bu filtrelerle eşleşen program bulamadım — birkaçını gevşetsek mi?';

/// Tek bir mesaj şablonu. Metindeki `{...}` yer tutucularını RobotBrain
/// doldurur; şablonlar burada kalır ki tüm copy tek dosyada yaşasın.
class RobotScript {
  final String id;
  final String text;
  final RobotMood mood;
  final RobotAction action;

  const RobotScript(
    this.id,
    this.text,
    this.mood, {
    this.action = RobotAction.none,
  });

  RobotMessage toMessage() => RobotMessage(id, text, mood, action: action);
}

/// Onboarding sayfası metni. [RobotScript]'ten ayrı bir tip çünkü burada
/// başlık + gövde birlikte gerekiyor; görsel taraf (gradyan, vurgu rengi)
/// ekranda kalır.
class OnboardingCopy {
  final String id;
  final String title;
  final String body;
  final RobotMood mood;

  const OnboardingCopy(this.id, this.title, this.body, this.mood);
}

/// Üni'nin tüm repliği — iki dilde. Ses tonu: birinci ağız, "sen" dili,
/// sevimli ama dürüst — yerleşme sözü ASLA verilmez; "tahmin / garanti
/// veremem" ("estimate / can't guarantee") korunur.
///
/// Dil, uygulama kökünde [languageCode] ile ayarlanır (localeProvider);
/// tüm çağrı yerleri `RobotScripts.x` olarak değişmeden kalır — getter'lar
/// aktif dilin tablosuna yönlendirir. Mesaj id'leri dilden bağımsızdır
/// (analitik ve testler aynı kalır).
abstract final class RobotScripts {
  /// Aktif dil ('tr' | 'en') — uygulama kökü locale değişince günceller.
  static String languageCode = 'tr';

  static bool get isEn => languageCode == 'en';

  // ── Ana ekran: selamlama gövdeleri ──
  static List<RobotScript> get homeTercihWithProfile =>
      isEn ? _En.homeTercihWithProfile : _Tr.homeTercihWithProfile;
  static List<RobotScript> get homeTercihNoProfile =>
      isEn ? _En.homeTercihNoProfile : _Tr.homeTercihNoProfile;
  static List<RobotScript> get homeExamCountdown =>
      isEn ? _En.homeExamCountdown : _Tr.homeExamCountdown;
  static List<RobotScript> get homeExamWeek =>
      isEn ? _En.homeExamWeek : _Tr.homeExamWeek;
  static List<RobotScript> get homeResultsWait =>
      isEn ? _En.homeResultsWait : _Tr.homeResultsWait;
  static List<RobotScript> get homePlacementWait =>
      isEn ? _En.homePlacementWait : _Tr.homePlacementWait;
  static List<RobotScript> get homePlacementDone =>
      isEn ? _En.homePlacementDone : _Tr.homePlacementDone;
  static List<RobotScript> get homeOffSeason =>
      isEn ? _En.homeOffSeason : _Tr.homeOffSeason;

  // ── Günün ipucu ──
  static List<RobotScript> get tips => isEn ? _En.tips : _Tr.tips;

  // ── Sihirbaz girişi ──
  static List<RobotScript> get wizardFirstVisit =>
      isEn ? _En.wizardFirstVisit : _Tr.wizardFirstVisit;
  static List<RobotScript> get wizardWithProfile =>
      isEn ? _En.wizardWithProfile : _Tr.wizardWithProfile;
  static List<RobotScript> get wizardNoProfile =>
      isEn ? _En.wizardNoProfile : _Tr.wizardNoProfile;
  static RobotScript get wizardValidation =>
      isEn ? _En.wizardValidation : _Tr.wizardValidation;

  // ── Sonuç özetleri ──
  static List<RobotScript> get resultsBalanced =>
      isEn ? _En.resultsBalanced : _Tr.resultsBalanced;
  static List<RobotScript> get resultsRisky =>
      isEn ? _En.resultsRisky : _Tr.resultsRisky;
  static List<RobotScript> get resultsSafe =>
      isEn ? _En.resultsSafe : _Tr.resultsSafe;
  static List<RobotScript> get resultsEmpty =>
      isEn ? _En.resultsEmpty : _Tr.resultsEmpty;
  static String get estimatedRankSuffix =>
      isEn ? _En.estimatedRankSuffix : _Tr.estimatedRankSuffix;

  // ── Liste sağlığı ──
  static List<RobotScript> get healthNoGuaranteed =>
      isEn ? _En.healthNoGuaranteed : _Tr.healthNoGuaranteed;
  static List<RobotScript> get healthTooRisky =>
      isEn ? _En.healthTooRisky : _Tr.healthTooRisky;
  static List<RobotScript> get healthTooSafe =>
      isEn ? _En.healthTooSafe : _Tr.healthTooSafe;
  static List<RobotScript> get healthBalanced =>
      isEn ? _En.healthBalanced : _Tr.healthBalanced;
  static List<RobotScript> get healthUnrated =>
      isEn ? _En.healthUnrated : _Tr.healthUnrated;

  // ── Boş liste dürtmesi ──
  static List<RobotScript> get emptyList =>
      isEn ? _En.emptyList : _Tr.emptyList;

  // ── Üni ile Sohbet ──
  static RobotScript get chatHelloNew =>
      isEn ? _En.chatHelloNew : _Tr.chatHelloNew;
  static RobotScript get chatHelloBack =>
      isEn ? _En.chatHelloBack : _Tr.chatHelloBack;
  static RobotScript get chatAskScoreType =>
      isEn ? _En.chatAskScoreType : _Tr.chatAskScoreType;
  static RobotScript get chatAskRank =>
      isEn ? _En.chatAskRank : _Tr.chatAskRank;
  static RobotScript get chatAskInterests =>
      isEn ? _En.chatAskInterests : _Tr.chatAskInterests;
  static RobotScript get chatAskConstraints =>
      isEn ? _En.chatAskConstraints : _Tr.chatAskConstraints;
  static RobotScript get chatConfirm => isEn ? _En.chatConfirm : _Tr.chatConfirm;
  static RobotScript get chatFocus => isEn ? _En.chatFocus : _Tr.chatFocus;
  static RobotScript get chatAck => isEn ? _En.chatAck : _Tr.chatAck;
  static RobotScript get chatPartial => isEn ? _En.chatPartial : _Tr.chatPartial;
  static RobotScript get chatConfused =>
      isEn ? _En.chatConfused : _Tr.chatConfused;
  static RobotScript get chatComingSoon =>
      isEn ? _En.chatComingSoon : _Tr.chatComingSoon;
  static RobotScript get chatScoreInvalid =>
      isEn ? _En.chatScoreInvalid : _Tr.chatScoreInvalid;
  static RobotScript get chatRestart => isEn ? _En.chatRestart : _Tr.chatRestart;
  static RobotScript get chatUpdate => isEn ? _En.chatUpdate : _Tr.chatUpdate;
  static RobotScript get chatSearchError =>
      isEn ? _En.chatSearchError : _Tr.chatSearchError;
  static RobotScript get chatSearchMissing =>
      isEn ? _En.chatSearchMissing : _Tr.chatSearchMissing;

  // ── Rozet kutlaması ──
  static List<RobotScript> get badgeCheer =>
      isEn ? _En.badgeCheer : _Tr.badgeCheer;

  // ── Bölüm / üniversite detayı: kişisel uygunluk yorumu ──
  static RobotScript get deptVerdictHigh =>
      isEn ? _En.deptVerdictHigh : _Tr.deptVerdictHigh;
  static RobotScript get deptVerdictTarget =>
      isEn ? _En.deptVerdictTarget : _Tr.deptVerdictTarget;
  static RobotScript get deptVerdictDream =>
      isEn ? _En.deptVerdictDream : _Tr.deptVerdictDream;
  static RobotScript get deptNeedRank =>
      isEn ? _En.deptNeedRank : _Tr.deptNeedRank;
  static RobotScript get uniFitSummary =>
      isEn ? _En.uniFitSummary : _Tr.uniFitSummary;
  static RobotScript get uniFitNone => isEn ? _En.uniFitNone : _Tr.uniFitNone;

  // ── Boş durumlar (UniEmptyState) ──
  static RobotScript get emptySearch =>
      isEn ? _En.emptySearch : _Tr.emptySearch;
  static RobotScript get emptyFavorites =>
      isEn ? _En.emptyFavorites : _Tr.emptyFavorites;
  static RobotScript get emptyCompare =>
      isEn ? _En.emptyCompare : _Tr.emptyCompare;
  static RobotScript get emptyMyReviews =>
      isEn ? _En.emptyMyReviews : _Tr.emptyMyReviews;
  static RobotScript get emptyUniReviews =>
      isEn ? _En.emptyUniReviews : _Tr.emptyUniReviews;
  static RobotScript get emptyExplore =>
      isEn ? _En.emptyExplore : _Tr.emptyExplore;

  // ── Onboarding — Üni kendini tanıtır ──
  static List<OnboardingCopy> get onboardingPages =>
      isEn ? _En.onboardingPages : _Tr.onboardingPages;

  /// Son sayfadaki isim sorusu.
  static String get onboardingNameHint => isEn ? 'Your name' : 'Adın';
  static String get onboardingNameSkip =>
      isEn ? 'Rather not say' : 'Söylemesem de olur';

  // ── Kısa ifadeler — sohbet akışı ve Üni'ye ait UI etiketleri ──
  static String get phraseRank => isEn ? 'rank' : 'sıra';
  static String get phraseScore => isEn ? 'points' : 'puan';
  static String get phraseScholarship => isEn ? 'Scholarship' : 'Burslu';

  /// Olumsuzlama onayı: '$ad $phraseExcluded' iki dilde de doğru okunur
  /// ("İstanbul hariç" / "İstanbul excluded").
  static String get phraseExcluded => isEn ? 'excluded' : 'hariç';

  static String get chatTitle =>
      isEn ? 'Chat with $kRobotName' : '$kRobotName ile Sohbet';
  static String get inputHint =>
      isEn ? 'Message $kRobotName…' : "$kRobotName'ye yaz…";
  static String get rankBoxHint => isEn
      ? 'Your rank or score (e.g. 80000)'
      : 'Sıralaman ya da puanın (örn. 80000)';
  static String get previewTitle =>
      isEn ? 'Your first matches:' : 'İlk önerilerin:';
  static String get robotNoteLabel =>
      isEn ? "$kRobotName's note: " : "$kRobotName'nin notu: ";
  static String get transferLabel =>
      isEn ? 'Send to $kRobotName' : "$kRobotName'ye aktar";

  // Önizleme kartı etiketleri.
  static String fitLabel(int fit) => isEn ? '$fit% fit' : '%$fit uygun';
  static String cutoffLabel(String rankText) =>
      isEn ? 'cutoff $rankText' : 'taban $rankText';
  static String get categoryHigh => isEn ? 'High chance' : 'Yüksek şans';
  static String get categoryTarget => isEn ? 'Reachable' : 'Ulaşılabilir';
  static String get categoryDream => isEn ? 'Ambitious' : 'Zorlayıcı';

  /// WizardFilter'ın kanonik Türkçe değerleri (motor ve depolama bunları
  /// bekler) — yalnız GÖSTERİM için çevrilir; eşleşmeyen değer aynen döner.
  static String filterLabel(String canonical) {
    if (!isEn) return canonical;
    return const {
          'Devlet': 'Public',
          'Vakıf': 'Foundation',
          'Türkçe': 'Turkish',
          'İngilizce': 'English',
          'Lisans': "Bachelor's",
          'Önlisans': 'Associate',
        }[canonical] ??
        canonical;
  }

  /// [interestAreas] anahtarlarının İngilizce etiketleri; sözlükte yoksa
  /// Türkçe etiket olduğu gibi kullanılır.
  static String interestLabel(String key, String trLabel) {
    if (!isEn) return trLabel;
    return const {
          'bilgisayar': 'Computer / Software',
          'elektrik': 'Electrical / Electronics',
          'makine': 'Mechanical / Automotive',
          'endustri': 'Industrial Eng.',
          'insaat': 'Civil / Environmental',
          'saglik': 'Medicine / Dentistry / Pharmacy',
          'hemsirelik': 'Nursing / Midwifery',
          'isletme': 'Business / Economics',
          'siyaset': 'Politics / International Rel.',
          'psikoloji': 'Psychology / Counseling',
          'mimarlik': 'Architecture / Design',
          'iletisim': 'Communication / Media',
          'matematik': 'Mathematics / Statistics',
          'kimya': 'Chemistry / Bio / Food',
          'havacilik': 'Aviation / Aerospace',
          'saglik-bilimleri': 'Health Sciences',
          'egitim': 'Teaching / Education',
          'dil': 'English / Languages',
          'sosyal': 'Sociology / Philosophy',
          'tarih': 'History / Literature',
          'turizm': 'Tourism / Gastronomy',
          'tasarim': 'Design',
          'finans': 'Banking / Finance',
          'hukuk': 'Law',
          'veteriner': 'Veterinary Medicine',
        }[key] ??
        trLabel;
  }
}

/// Türkçe tablo — özgün metinler.
abstract final class _Tr {
  static const homeTercihWithProfile = <RobotScript>[
    RobotScript(
      'home.tercih.profile.v1',
      'Tercih dönemi tüm hızıyla sürüyor — istersen listeni birlikte '
          'gözden geçirelim.',
      RobotMood.happy,
    ),
    RobotScript(
      'home.tercih.profile.v2',
      'Tercih günleri kıymetli — önerilerine bakıp listeni tazelemek '
          'ister misin?',
      RobotMood.happy,
    ),
  ];

  static const homeTercihNoProfile = <RobotScript>[
    RobotScript(
      'home.tercih.new.v1',
      'Ben $kRobotName! Puanını ya da sıralamanı söylersen sana uygun '
          'programları bulurum.',
      RobotMood.happy,
      action: RobotAction.openWizard,
    ),
    RobotScript(
      'home.tercih.new.v2',
      'Ben $kRobotName, tercih yardımcın! Sıralamanı girersen şansına göre '
          'gruplu öneriler hazırlarım.',
      RobotMood.happy,
      action: RobotAction.openWizard,
    ),
  ];

  static const homeExamCountdown = <RobotScript>[
    RobotScript(
      'home.examCountdown.v1',
      'Sınav yaklaşıyor — sen çalışmana bak, program araştırmayı bana '
          'bırak.',
      RobotMood.neutral,
    ),
  ];

  static const homeExamWeek = <RobotScript>[
    RobotScript(
      'home.examWeek.v1',
      'Sınav haftası! Derin nefes… Sen elinden gelenin en iyisini yap, '
          'gerisine birlikte bakarız.',
      RobotMood.happy,
    ),
  ];

  static const homeResultsWait = <RobotScript>[
    RobotScript(
      'home.resultsWait.v1',
      'Sonuçları beklemek zor, biliyorum. İstersen şimdiden bölümleri '
          'keşfedip fikir toplayabiliriz.',
      RobotMood.neutral,
    ),
    RobotScript(
      'home.resultsWait.v2',
      'Sonuçlar açıklanana dek boş durmayalım — netlerinden puanını '
          'hesaplayıp bir ön bakış yapabiliriz.',
      RobotMood.neutral,
      action: RobotAction.openScoreCalculator,
    ),
  ];

  static const homePlacementWait = <RobotScript>[
    RobotScript(
      'home.placementWait.v1',
      'Tercihler tamam, şimdi yerleştirme sonuçlarını bekliyoruz. '
          'Kablolarım senin için çapraz!',
      RobotMood.happy,
    ),
  ];

  static const homePlacementDone = <RobotScript>[
    RobotScript(
      'home.placementDone.v1',
      'Yerleştirme sonuçları açıklandı! Umarım istediğin yerdesin — ek '
          'yerleştirme gerekirse yine buradayım.',
      RobotMood.happy,
    ),
  ];

  static const homeOffSeason = <RobotScript>[
    RobotScript(
      'home.offSeason.v1',
      'Üniversiteleri keşfetmek için her zaman iyi bir gün. Aklındaki '
          'bölümlere birlikte bakalım mı?',
      RobotMood.neutral,
    ),
  ];

  static const tips = <RobotScript>[
    RobotScript(
      'tip.safety',
      'Küçük ipucu: listenin sonuna 3-4 yüksek şanslı program koymak, '
          'sıralaman beklenenden düşük gelirse seni açıkta kalmaktan korur.',
      RobotMood.neutral,
    ),
    RobotScript(
      'tip.order',
      'Tercih listende sıra önemli: en çok istediğin en üstte olmalı — '
          'yerleştirme yukarıdan aşağı bakar.',
      RobotMood.neutral,
    ),
    RobotScript(
      'tip.fill',
      '24 tercih hakkının hepsini kullanmak zorunda değilsin ama çok boş '
          'bırakmak şansını azaltır.',
      RobotMood.neutral,
    ),
    RobotScript(
      'tip.city',
      'Bir programın sadece puanına değil, şehrine ve kampüs hayatına da '
          'bak — birkaç yılın orada geçecek.',
      RobotMood.neutral,
    ),
    RobotScript(
      'tip.volatility',
      'Taban sıralamalar her yıl oynayabilir — geçen yılın sınırındaki '
          'programlar için tedbirli ol.',
      RobotMood.neutral,
    ),
    RobotScript(
      'tip.scholarship',
      'Burslu vakıf programlarının tabanı devletten zorlu olabilir — '
          'ikisini birlikte değerlendir.',
      RobotMood.neutral,
    ),
    RobotScript(
      'tip.compare',
      'Kararsız kaldığında iki bölümü karşılaştırma ekranında yan yana '
          'koymak işini kolaylaştırır.',
      RobotMood.neutral,
    ),
    RobotScript(
      'tip.language',
      'Öğretim dili İngilizce olan programlarda hazırlık yılını hesaba '
          'katmayı unutma.',
      RobotMood.neutral,
    ),
    RobotScript(
      'tip.recheck',
      'Tercih süresi bitmeden listenin sırasını bir kez daha kontrol et — '
          'sıra değişikliği puan kaybettirmez, şans kazandırır.',
      RobotMood.neutral,
    ),
    RobotScript(
      'tip.curriculum',
      'Bölüm isimleri bazen yanıltır — kararsızsan ders programını '
          'incelemek en sağlamı.',
      RobotMood.neutral,
    ),
  ];

  static const wizardFirstVisit = <RobotScript>[
    RobotScript(
      'wizard.first.v1',
      'Merhaba, ben $kRobotName! Şöyle çalışıyorum: puanını ya da '
          'sıralamanı gir, ben binlerce programı tarayıp şansına göre '
          'gruplayayım. Beğendiklerini tek dokunuşla listene eklersin.',
      RobotMood.happy,
    ),
  ];

  static const wizardWithProfile = <RobotScript>[
    RobotScript(
      'wizard.profile.v1',
      'Tekrar hoş geldin! Bilgilerin duruyor — ister güncelle, ister '
          'doğrudan önerilerine geç.',
      RobotMood.happy,
    ),
    RobotScript(
      'wizard.profile.v2',
      'Yine buradayım! Sıralamanda değişiklik varsa güncelle, yoksa hemen '
          'önerilere geçelim.',
      RobotMood.happy,
    ),
  ];

  static const wizardNoProfile = <RobotScript>[
    RobotScript(
      'wizard.new.v1',
      'Hoş geldin! Puanını ya da sıralamanı girersen sana uygun '
          'programları bulmaya hemen başlarım.',
      RobotMood.happy,
    ),
    RobotScript(
      'wizard.new.v2',
      'Hazırsan başlayalım! Bir sıralama ya da puan yeter — gerisini bana '
          'bırak.',
      RobotMood.happy,
    ),
  ];

  static const wizardValidation = RobotScript(
    'wizard.validation.v1',
    'Bir saniye — önerilere geçebilmem için sıralamanı ya da puanını '
        'girmen gerekiyor.',
    RobotMood.concerned,
  );

  static const resultsBalanced = <RobotScript>[
    RobotScript(
      'results.balanced.v1',
      'Taramam bitti! {total} program buldum, {guaranteed} tanesi yüksek '
          'şanslı görünüyor. Bunlar geçmiş yıl verilerine dayalı tahminler '
          '— garanti veremem ama güzel bir başlangıç!',
      RobotMood.celebrating,
    ),
    RobotScript(
      'results.balanced.v2',
      'Sonuçlar hazır! {total} programı grupladım: {guaranteed} yüksek '
          'şans, {target} ulaşılabilir, {dream} zorlayıcı. Tahminlerim '
          'geçmiş yıl verilerine dayanıyor — son karar senin.',
      RobotMood.celebrating,
    ),
  ];

  static const resultsRisky = <RobotScript>[
    RobotScript(
      'results.risky.v1',
      'Hmm… tahminlerime göre önerilerin çoğu zorlayıcı bölgede. '
          'Cesaretini seviyorum ama listene birkaç güvenli program da '
          'serpiştirsek içim daha rahat eder.',
      RobotMood.concerned,
    ),
    RobotScript(
      'results.risky.v2',
      'Bu profille sonuçların çoğu zorlayıcı çıktı — tahminim, güvenli '
          'bölgeden birkaç ekleme yapmanın iyi olacağı yönünde. Ulaşılabilir '
          'olanlara da göz at.',
      RobotMood.concerned,
    ),
  ];

  static const resultsSafe = <RobotScript>[
    RobotScript(
      'results.safe.v1',
      'Tahminlerime göre buradaki seçeneklerin çoğu senin için oldukça '
          'güvenli. İstersen üst sıralara birkaç hedef program ekleyip '
          'şansını zorlayabilirsin!',
      RobotMood.neutral,
    ),
  ];

  static const resultsEmpty = <RobotScript>[
    RobotScript(
      'results.empty.v1',
      'Bu kriterlerle eşleşme bulamadım… Üzülme — tahminlerim filtrelere '
          'bağlı; birkaçını gevşetirsek yeni kapılar açılabilir.',
      RobotMood.concerned,
    ),
  ];

  static const estimatedRankSuffix =
      ' Bu arada sıralamanı puanından tahmin ettim — gerçek sıranı '
      'girersen daha isabetli olurum.';

  static const healthNoGuaranteed = <RobotScript>[
    RobotScript(
      'health.noGuaranteed.v1',
      'Listende yüksek şanslı tercih göremiyorum — sona birkaç güvenli '
          'program eklemeni öneririm, ne olur ne olmaz.',
      RobotMood.concerned,
      action: RobotAction.openWizard,
    ),
  ];

  static const healthTooRisky = <RobotScript>[
    RobotScript(
      'health.tooRisky.v1',
      'Listenin yarısından fazlası zorlayıcı görünüyor — cesur liste! '
          'Yine de dengeyi birlikte gözden geçirsek iyi olur.',
      RobotMood.concerned,
    ),
  ];

  static const healthTooSafe = <RobotScript>[
    RobotScript(
      'health.tooSafe.v1',
      'Listen bana epey güvenli göründü — üst sıralara birkaç hedef '
          'program eklersen şansını artırabilirsin.',
      RobotMood.neutral,
    ),
  ];

  static const healthBalanced = <RobotScript>[
    RobotScript(
      'health.balanced.v1',
      'Listene baktım: dağılım dengeli görünüyor. Eline sağlık!',
      RobotMood.happy,
    ),
  ];

  static const healthUnrated = <RobotScript>[
    RobotScript(
      'health.unrated.v1',
      'Listedeki programları puan türünle karşılaştıramadım — profilini '
          'bir kontrol edelim mi?',
      RobotMood.thinking,
      action: RobotAction.openWizard,
    ),
  ];

  static const emptyList = <RobotScript>[
    RobotScript(
      'emptyList.v1',
      'Listen henüz boş görünüyor. İstersen puanına göre birlikte '
          'dolduralım — birkaç dakikanı alır.',
      RobotMood.neutral,
      action: RobotAction.openWizard,
    ),
    RobotScript(
      'emptyList.v2',
      'Boş liste, dolu potansiyel! Sıralamanı söyle, sana uygun '
          'programlarla başlayalım.',
      RobotMood.happy,
      action: RobotAction.openWizard,
    ),
  ];

  static const chatHelloNew = RobotScript(
    'chat.hello.new',
    'Merhaba, ben $kRobotName! Sana uygun programları bulmak için birkaç '
        'kısa sorum var — aşağıdaki balonlardan seçerek bir dakikada '
        'bitiririz.',
    RobotMood.happy,
  );

  static const chatHelloBack = RobotScript(
    'chat.hello.back',
    'Tekrar hoş geldin! Şöyle not almışım: {profile}. Sonuçlara mı '
        'geçelim, bilgilerini mi güncelleyelim?',
    RobotMood.happy,
  );

  static const chatAskScoreType = RobotScript(
    'chat.ask.type',
    'Hangi puan türüyle yerleşeceksin? SAY, EA, SÖZ ya da DİL — önlisans '
        'düşünüyorsan TYT.',
    RobotMood.neutral,
  );

  static const chatAskRank = RobotScript(
    'chat.ask.rank',
    'Peki sıralaman ya da puanın ne? Aşağıdaki kutucuğa yazman yeter — '
        'bilmiyorsan netlerinden birlikte hesaplayabiliriz.',
    RobotMood.neutral,
  );

  static const chatAskInterests = RobotScript(
    'chat.ask.interests',
    'Ne okumak istersin? Aşağıdan bir alan seç — kararsızsan '
        '"Farketmez" de yeter.',
    RobotMood.happy,
  );

  static const chatAskConstraints = RobotScript(
    'chat.ask.constraints',
    'Şehir ya da üniversite türü tercihin var mı? Aşağıdan '
        'seçebilirsin; yoksa "Farketmez" de.',
    RobotMood.neutral,
  );

  static const chatConfirm = RobotScript(
    'chat.confirm',
    'Şöyle not ettim: {summary}. Hazırsan arıyorum! Bulduklarım geçmiş '
        'yıl verilerine dayalı tahmin olacak — garanti değil ama iyi bir '
        'pusula.',
    RobotMood.happy,
  );

  static const chatFocus = RobotScript(
    'chat.focus',
    'Birden fazla bölüm saydın — hangisine odaklanayım? "Hepsi" dersen '
        'hepsine birden bakarım.',
    RobotMood.thinking,
  );

  static const chatAck = RobotScript(
    'chat.ack',
    'Not ettim: {pieces}!',
    RobotMood.happy,
  );

  static const chatPartial = RobotScript(
    'chat.partial',
    'Şu kısmı tam çözemedim: "{rest}". İstersen farklı sözcüklerle bir '
        'daha söyle.',
    RobotMood.thinking,
  );

  static const chatConfused = RobotScript(
    'chat.confused',
    'Bunu tam anlayamadım — aşağıdaki seçeneklerden ilerleyelim mi?',
    RobotMood.thinking,
  );

  static const chatComingSoon = RobotScript(
    'chat.coming.soon',
    'Klavye kısmım daha hazır değil! Geliştiricilerim şu an üzerimde '
        'çalışıyor; yakında burada doya doya sohbet edeceğiz. Şimdilik '
        'balonlardan ve kutucuktan ilerleyelim, olur mu?',
    RobotMood.happy,
  );

  static const chatScoreInvalid = RobotScript(
    'chat.score.invalid',
    'Hmm, yerleştirme puanı 150-560 aralığında olur — bir daha dener '
        'misin?',
    RobotMood.concerned,
  );

  static const chatRestart = RobotScript(
    'chat.restart',
    'Tamamdır, baştan alıyoruz!',
    RobotMood.neutral,
  );

  static const chatUpdate = RobotScript(
    'chat.update',
    'Olur, bilgilerini tazeleyelim! Soruları baştan soruyorum — çoğu '
        'tek dokunuş zaten.',
    RobotMood.neutral,
  );

  static const chatSearchError = RobotScript(
    'chat.search.error',
    'Ay, bir şeyler ters gitti — bağlantını kontrol edip bir daha '
        'dener misin?',
    RobotMood.concerned,
  );

  static const chatSearchMissing = RobotScript(
    'chat.search.missing',
    'Aramaya başlamadan önce puan türünü ve sıralamanı (ya da puanını) '
        'öğrenmem gerekiyor.',
    RobotMood.concerned,
  );

  static const badgeCheer = <RobotScript>[
    RobotScript(
      'badge.v1',
      'Yeni rozet! Seninle gurur duyuyorum — böyle devam!',
      RobotMood.celebrating,
    ),
    RobotScript(
      'badge.v2',
      'Koleksiyona bir rozet daha! Tebrikler!',
      RobotMood.celebrating,
    ),
    RobotScript(
      'badge.v3',
      'Bunu sen kazandın! Rozetin hayırlı olsun.',
      RobotMood.celebrating,
    ),
  ];

  static const onboardingPages = <OnboardingCopy>[
    OnboardingCopy(
      'onboarding.hello',
      "Merhaba, ben $kRobotName!",
      'Üniversite yolculuğunda sana eşlik edeceğim. Birlikte hayalindeki '
          'bölümü bulacağız.',
      RobotMood.happy,
    ),
    OnboardingCopy(
      'onboarding.discover',
      'Keşfet & Karşılaştır',
      'Yüzlerce üniversiteyi puana, şehre ve olanaklara göre süzerim; '
          'ikisini yan yana koyup farkı gösteririm.',
      RobotMood.thinking,
    ),
    OnboardingCopy(
      'onboarding.reviews',
      'Gerçek öğrenci yorumları',
      'edu.tr ile doğrulanmış öğrencilerin deneyimleri. Sahte yorum yok, '
          'süslemesiz anlatılmış hikâyeler var.',
      RobotMood.happy,
    ),
    OnboardingCopy(
      'onboarding.ready',
      'Seni nasıl çağırayım?',
      'Adını bilirsem sohbetimiz daha samimi olur. İstemezsen boş '
          'bırakabilirsin — yine de yanındayım.',
      RobotMood.celebrating,
    ),
  ];

  // ── Bölüm / üniversite detayı ──
  // Dürüstlük: kategori bir TAHMİN; garanti dili yok.
  static const deptVerdictHigh = RobotScript(
    'dept.verdict.high',
    'Bu bölüm senin sıralamanla yüksek şanslı görünüyor. Geçen yılın '
        'verisine göre tahminim bu — garanti veremem ama listende yer '
        'etmesi mantıklı.',
    RobotMood.celebrating,
  );
  static const deptVerdictTarget = RobotScript(
    'dept.verdict.target',
    'Bu bölüm sana ulaşılabilir görünüyor — sınırda değil ama rahat da '
        'değil. Tahminim geçen yılın verisine dayanıyor.',
    RobotMood.happy,
  );
  static const deptVerdictDream = RobotScript(
    'dept.verdict.dream',
    'Bu bölüm senin için zorlayıcı görünüyor. İstersen listene koy, ama '
        'yanına ulaşılabilir birkaç seçenek de ekleyelim.',
    RobotMood.thinking,
  );
  static const deptNeedRank = RobotScript(
    'dept.needRank',
    'Sıralamanı bilsem bu bölümün sana uygun olup olmadığını '
        'söyleyebilirdim. Birlikte hızlıca girelim mi?',
    RobotMood.neutral,
    action: RobotAction.openWizard,
  );
  static const uniFitSummary = RobotScript(
    'uni.fit.summary',
    'Burada senin sıralamana uyan {count} bölüm buldum — {high} tanesi '
        'yüksek şanslı. Bunlar tahmin, kesin söz değil.',
    RobotMood.happy,
  );
  static const uniFitNone = RobotScript(
    'uni.fit.none',
    'Bu üniversitede senin puan türünde ulaşılabilir bir bölüm '
        'bulamadım. Başka üniversitelere bakmamı ister misin?',
    RobotMood.concerned,
  );

  // ── Boş durumlar ──
  static const emptySearch = RobotScript(
    'empty.search',
    'Bunu bulamadım. Yazımı değiştirmeyi ya da daha kısa bir kelime '
        'denemeyi öneririm.',
    RobotMood.concerned,
  );
  static const emptyFavorites = RobotScript(
    'empty.favorites',
    'Beğendiğin üniversiteleri buraya ekle; sonra hepsini bir arada '
        'gösteririm.',
    RobotMood.happy,
  );
  static const emptyCompare = RobotScript(
    'empty.compare',
    'İki üniversite seç, farklarını yan yana koyayım.',
    RobotMood.happy,
  );
  static const emptyMyReviews = RobotScript(
    'empty.myReviews',
    'Henüz yorum yazmamışsın. Deneyimin senden sonrakiler için gerçekten '
        'kıymetli.',
    RobotMood.neutral,
  );
  static const emptyUniReviews = RobotScript(
    'empty.uniReviews',
    'Buranın ilk yorumu senden gelebilir. Kısa bir deneyim bile çok şey '
        'anlatır.',
    RobotMood.happy,
  );
  static const emptyExplore = RobotScript(
    'empty.explore',
    'Bu filtrelerle bir şey çıkmadı. Birkaçını gevşetsek mi?',
    RobotMood.concerned,
  );
}

/// İngilizce tablo — id'ler Türkçe tabloyla birebir aynı.
abstract final class _En {
  static const homeTercihWithProfile = <RobotScript>[
    RobotScript(
      'home.tercih.profile.v1',
      "Preference season is in full swing — let's review your list "
          'together if you like.',
      RobotMood.happy,
    ),
    RobotScript(
      'home.tercih.profile.v2',
      'These preference days are precious — want to check your matches '
          'and refresh your list?',
      RobotMood.happy,
    ),
  ];

  static const homeTercihNoProfile = <RobotScript>[
    RobotScript(
      'home.tercih.new.v1',
      "I'm $kRobotName! Tell me your score or rank and I'll find the "
          'programs that suit you.',
      RobotMood.happy,
      action: RobotAction.openWizard,
    ),
    RobotScript(
      'home.tercih.new.v2',
      "I'm $kRobotName, your preference buddy! Enter your rank and I'll "
          'prepare suggestions grouped by your chances.',
      RobotMood.happy,
      action: RobotAction.openWizard,
    ),
  ];

  static const homeExamCountdown = <RobotScript>[
    RobotScript(
      'home.examCountdown.v1',
      'The exam is getting close — you focus on studying, leave the '
          'program research to me.',
      RobotMood.neutral,
    ),
  ];

  static const homeExamWeek = <RobotScript>[
    RobotScript(
      'home.examWeek.v1',
      "Exam week! Deep breath… Do your best and we'll figure out the "
          'rest together.',
      RobotMood.happy,
    ),
  ];

  static const homeResultsWait = <RobotScript>[
    RobotScript(
      'home.resultsWait.v1',
      'Waiting for results is hard, I know. We could start exploring '
          'departments and gathering ideas in the meantime.',
      RobotMood.neutral,
    ),
    RobotScript(
      'home.resultsWait.v2',
      "Let's not sit idle until results day — we can estimate your "
          'score from your net answers and take an early look.',
      RobotMood.neutral,
      action: RobotAction.openScoreCalculator,
    ),
  ];

  static const homePlacementWait = <RobotScript>[
    RobotScript(
      'home.placementWait.v1',
      'Preferences are in — now we wait for placement results. My '
          'cables are crossed for you!',
      RobotMood.happy,
    ),
  ];

  static const homePlacementDone = <RobotScript>[
    RobotScript(
      'home.placementDone.v1',
      "Placement results are out! I hope you're where you wanted to be "
          "— and if you need the extra round, I'm right here.",
      RobotMood.happy,
    ),
  ];

  static const homeOffSeason = <RobotScript>[
    RobotScript(
      'home.offSeason.v1',
      'Any day is a good day to explore universities. Shall we look at '
          'the departments on your mind together?',
      RobotMood.neutral,
    ),
  ];

  static const tips = <RobotScript>[
    RobotScript(
      'tip.safety',
      'Small tip: putting 3-4 high-chance programs at the end of your '
          'list protects you if your rank comes in lower than expected.',
      RobotMood.neutral,
    ),
    RobotScript(
      'tip.order',
      'Order matters in your list: what you want most should be on top — '
          'placement reads from top to bottom.',
      RobotMood.neutral,
    ),
    RobotScript(
      'tip.fill',
      "You don't have to use all 24 preference slots, but leaving too "
          'many empty lowers your chances.',
      RobotMood.neutral,
    ),
    RobotScript(
      'tip.city',
      "Don't judge a program by its score alone — look at the city and "
          "campus life too; you'll spend a few years there.",
      RobotMood.neutral,
    ),
    RobotScript(
      'tip.volatility',
      'Cutoff ranks can shift every year — be cautious with programs '
          "that sat right at last year's edge.",
      RobotMood.neutral,
    ),
    RobotScript(
      'tip.scholarship',
      'Scholarship programs at private universities can have tougher '
          'cutoffs than state ones — weigh both together.',
      RobotMood.neutral,
    ),
    RobotScript(
      'tip.compare',
      "When you're torn, putting two departments side by side on the "
          'compare screen makes it easier.',
      RobotMood.neutral,
    ),
    RobotScript(
      'tip.language',
      "For English-taught programs, don't forget to factor in the "
          'preparatory year.',
      RobotMood.neutral,
    ),
    RobotScript(
      'tip.recheck',
      'Before the deadline, double-check the order of your list — '
          "reordering costs nothing and can win you a spot.",
      RobotMood.neutral,
    ),
    RobotScript(
      'tip.curriculum',
      'Department names can be misleading — when unsure, checking the '
          'curriculum is the safest bet.',
      RobotMood.neutral,
    ),
  ];

  static const wizardFirstVisit = <RobotScript>[
    RobotScript(
      'wizard.first.v1',
      "Hi, I'm $kRobotName! Here's how I work: enter your score or "
          "rank, and I'll scan thousands of programs and group them by "
          'your chances. Add the ones you like to your list with one tap.',
      RobotMood.happy,
    ),
  ];

  static const wizardWithProfile = <RobotScript>[
    RobotScript(
      'wizard.profile.v1',
      'Welcome back! Your info is saved — update it, or jump straight '
          'to your matches.',
      RobotMood.happy,
    ),
    RobotScript(
      'wizard.profile.v2',
      "Here I am again! If your rank changed, update it — otherwise "
          "let's go straight to your matches.",
      RobotMood.happy,
    ),
  ];

  static const wizardNoProfile = <RobotScript>[
    RobotScript(
      'wizard.new.v1',
      "Welcome! Enter your score or rank and I'll get right to finding "
          'programs that fit you.',
      RobotMood.happy,
    ),
    RobotScript(
      'wizard.new.v2',
      "Ready when you are! One rank or score is enough — leave the "
          'rest to me.',
      RobotMood.happy,
    ),
  ];

  static const wizardValidation = RobotScript(
    'wizard.validation.v1',
    'One second — I need your rank or score before I can show you '
        'matches.',
    RobotMood.concerned,
  );

  static const resultsBalanced = <RobotScript>[
    RobotScript(
      'results.balanced.v1',
      'Scan complete! I found {total} programs, {guaranteed} of them '
          'look high-chance. These are estimates based on past years — '
          "I can't guarantee anything, but it's a great start!",
      RobotMood.celebrating,
    ),
    RobotScript(
      'results.balanced.v2',
      'Results are ready! I grouped {total} programs: {guaranteed} '
          'high-chance, {target} reachable, {dream} ambitious. My '
          "estimates rely on past-year data — the final call is yours.",
      RobotMood.celebrating,
    ),
  ];

  static const resultsRisky = <RobotScript>[
    RobotScript(
      'results.risky.v1',
      'Hmm… by my estimates most of your matches sit in the ambitious '
          "zone. I admire the courage, but I'd feel better if we "
          'sprinkled in a few safe programs.',
      RobotMood.concerned,
    ),
    RobotScript(
      'results.risky.v2',
      'With this profile most results came out ambitious — my estimate '
          'is that adding a few safe picks would help. Check the '
          'reachable ones too.',
      RobotMood.concerned,
    ),
  ];

  static const resultsSafe = <RobotScript>[
    RobotScript(
      'results.safe.v1',
      'By my estimates most options here are quite safe for you. If '
          'you like, add a few target programs up top and push your '
          'luck!',
      RobotMood.neutral,
    ),
  ];

  static const resultsEmpty = <RobotScript>[
    RobotScript(
      'results.empty.v1',
      "I couldn't find a match with these criteria… Don't worry — my "
          'estimates depend on the filters; loosening a few could open '
          'new doors.',
      RobotMood.concerned,
    ),
  ];

  static const estimatedRankSuffix =
      ' By the way, I estimated your rank from your score — enter your '
      "real rank and I'll be more accurate.";

  static const healthNoGuaranteed = <RobotScript>[
    RobotScript(
      'health.noGuaranteed.v1',
      "I don't see any high-chance picks in your list — I'd add a few "
          'safe programs at the end, just in case.',
      RobotMood.concerned,
      action: RobotAction.openWizard,
    ),
  ];

  static const healthTooRisky = <RobotScript>[
    RobotScript(
      'health.tooRisky.v1',
      'More than half of your list looks ambitious — bold list! Still, '
          "we'd better review the balance together.",
      RobotMood.concerned,
    ),
  ];

  static const healthTooSafe = <RobotScript>[
    RobotScript(
      'health.tooSafe.v1',
      'Your list looks quite safe to me — adding a few target programs '
          'up top could raise your chances.',
      RobotMood.neutral,
    ),
  ];

  static const healthBalanced = <RobotScript>[
    RobotScript(
      'health.balanced.v1',
      'I checked your list: the balance looks good. Nice work!',
      RobotMood.happy,
    ),
  ];

  static const healthUnrated = <RobotScript>[
    RobotScript(
      'health.unrated.v1',
      "I couldn't compare the programs in your list with your score "
          'type — shall we check your profile?',
      RobotMood.thinking,
      action: RobotAction.openWizard,
    ),
  ];

  static const emptyList = <RobotScript>[
    RobotScript(
      'emptyList.v1',
      'Your list looks empty. We could fill it together based on your '
          'score — it only takes a few minutes.',
      RobotMood.neutral,
      action: RobotAction.openWizard,
    ),
    RobotScript(
      'emptyList.v2',
      "Empty list, full potential! Tell me your rank and we'll start "
          'with programs that fit you.',
      RobotMood.happy,
      action: RobotAction.openWizard,
    ),
  ];

  static const chatHelloNew = RobotScript(
    'chat.hello.new',
    "Hi, I'm $kRobotName! I have a few quick questions to find the "
        "programs that fit you — pick from the bubbles below and we'll "
        'be done in a minute.',
    RobotMood.happy,
  );

  static const chatHelloBack = RobotScript(
    'chat.hello.back',
    "Welcome back! Here's what I noted: {profile}. Shall we go to your "
        'results, or update your info?',
    RobotMood.happy,
  );

  static const chatAskScoreType = RobotScript(
    'chat.ask.type',
    'Which score type will you apply with? SAY, EA, SÖZ or DİL — TYT '
        "if you're considering associate degrees.",
    RobotMood.neutral,
  );

  static const chatAskRank = RobotScript(
    'chat.ask.rank',
    "So, what's your rank or score? Just type it in the little box "
        "below — if you don't know it, we can calculate it from your "
        'net answers.',
    RobotMood.neutral,
  );

  static const chatAskInterests = RobotScript(
    'chat.ask.interests',
    'What would you like to study? Pick a field below — if undecided, '
        '"No preference" works too.',
    RobotMood.happy,
  );

  static const chatAskConstraints = RobotScript(
    'chat.ask.constraints',
    'Any city or university type preference? Pick below, or just say '
        '"No preference".',
    RobotMood.neutral,
  );

  static const chatConfirm = RobotScript(
    'chat.confirm',
    "Here's what I noted: {summary}. Ready when you are! What I find "
        "will be an estimate based on past-year data — not a guarantee, "
        'but a good compass.',
    RobotMood.happy,
  );

  static const chatFocus = RobotScript(
    'chat.focus',
    'You mentioned more than one department — which should I focus on? '
        'Say "All" and I\'ll look at every one of them.',
    RobotMood.thinking,
  );

  static const chatAck = RobotScript(
    'chat.ack',
    'Noted: {pieces}!',
    RobotMood.happy,
  );

  static const chatPartial = RobotScript(
    'chat.partial',
    'I couldn\'t quite work out this part: "{rest}". Try saying it '
        'with different words if you like.',
    RobotMood.thinking,
  );

  static const chatConfused = RobotScript(
    'chat.confused',
    "I didn't quite get that — shall we continue with the options "
        'below?',
    RobotMood.thinking,
  );

  static const chatComingSoon = RobotScript(
    'chat.coming.soon',
    "My keyboard side isn't ready yet! My developers are working on me "
        "right now; soon we'll chat here properly. For now, let's use "
        'the bubbles and the little box, okay?',
    RobotMood.happy,
  );

  static const chatScoreInvalid = RobotScript(
    'chat.score.invalid',
    'Hmm, placement scores fall between 150 and 560 — want to try '
        'again?',
    RobotMood.concerned,
  );

  static const chatRestart = RobotScript(
    'chat.restart',
    "Alright, let's start over!",
    RobotMood.neutral,
  );

  static const chatUpdate = RobotScript(
    'chat.update',
    "Sure, let's refresh your info! I'll ask the questions again — "
        'most are a single tap anyway.',
    RobotMood.neutral,
  );

  static const chatSearchError = RobotScript(
    'chat.search.error',
    'Oops, something went wrong — check your connection and try '
        'again?',
    RobotMood.concerned,
  );

  static const chatSearchMissing = RobotScript(
    'chat.search.missing',
    'Before I can search, I need your score type and your rank (or '
        'score).',
    RobotMood.concerned,
  );

  static const badgeCheer = <RobotScript>[
    RobotScript(
      'badge.v1',
      "A new badge! I'm proud of you — keep it up!",
      RobotMood.celebrating,
    ),
    RobotScript(
      'badge.v2',
      'One more badge for the collection! Congrats!',
      RobotMood.celebrating,
    ),
    RobotScript(
      'badge.v3',
      'You earned this one! Enjoy your badge.',
      RobotMood.celebrating,
    ),
  ];

  static const onboardingPages = <OnboardingCopy>[
    OnboardingCopy(
      'onboarding.hello',
      "Hi, I'm $kRobotName!",
      "I'll be with you through the whole university journey. Together "
          "we'll find the program you're dreaming of.",
      RobotMood.happy,
    ),
    OnboardingCopy(
      'onboarding.discover',
      'Explore & Compare',
      'I filter hundreds of universities by score, city and facilities — '
          'then put two side by side and show you the difference.',
      RobotMood.thinking,
    ),
    OnboardingCopy(
      'onboarding.reviews',
      'Real student reviews',
      'Experiences from students verified through edu.tr. No fake '
          'reviews, just stories told plainly.',
      RobotMood.happy,
    ),
    OnboardingCopy(
      'onboarding.ready',
      'What should I call you?',
      "Knowing your name makes our chats warmer. Leave it blank if you'd "
          "rather not — I'm here either way.",
      RobotMood.celebrating,
    ),
  ];

  // ── Bölüm / üniversite detayı ──
  static const deptVerdictHigh = RobotScript(
    'dept.verdict.high',
    "With your rank this program looks like a high chance. That's my "
        "estimate from last year's data — I can't guarantee it, but it "
        'earns a place on your list.',
    RobotMood.celebrating,
  );
  static const deptVerdictTarget = RobotScript(
    'dept.verdict.target',
    "This one looks reachable for you — not borderline, but not "
        "comfortable either. My estimate rests on last year's data.",
    RobotMood.happy,
  );
  static const deptVerdictDream = RobotScript(
    'dept.verdict.dream',
    'This program looks ambitious for you. Put it on your list if you '
        "like, but let's add a few reachable ones next to it.",
    RobotMood.thinking,
  );
  static const deptNeedRank = RobotScript(
    'dept.needRank',
    'If I knew your rank I could tell you whether this program fits '
        'you. Shall we enter it quickly together?',
    RobotMood.neutral,
    action: RobotAction.openWizard,
  );
  static const uniFitSummary = RobotScript(
    'uni.fit.summary',
    'I found {count} programs here that match your rank — {high} of them '
        'look like a high chance. These are estimates, not promises.',
    RobotMood.happy,
  );
  static const uniFitNone = RobotScript(
    'uni.fit.none',
    "I couldn't find a reachable program in your score type at this "
        'university. Want me to look at other universities?',
    RobotMood.concerned,
  );

  // ── Boş durumlar ──
  static const emptySearch = RobotScript(
    'empty.search',
    "I couldn't find that. Try a different spelling, or a shorter word.",
    RobotMood.concerned,
  );
  static const emptyFavorites = RobotScript(
    'empty.favorites',
    'Add the universities you like here and I\'ll keep them all in one '
        'place for you.',
    RobotMood.happy,
  );
  static const emptyCompare = RobotScript(
    'empty.compare',
    'Pick two universities and I\'ll lay their differences side by side.',
    RobotMood.happy,
  );
  static const emptyMyReviews = RobotScript(
    'empty.myReviews',
    "You haven't written a review yet. Your experience is genuinely "
        'valuable to those coming after you.',
    RobotMood.neutral,
  );
  static const emptyUniReviews = RobotScript(
    'empty.uniReviews',
    'The first review here could be yours. Even a short note says a lot.',
    RobotMood.happy,
  );
  static const emptyExplore = RobotScript(
    'empty.explore',
    'Nothing came up with these filters. Shall we loosen a few?',
    RobotMood.concerned,
  );
}
