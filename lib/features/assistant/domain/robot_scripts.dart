import 'robot_message.dart';
import 'robot_mood.dart';

/// Robotun adı — tüm birinci-ağız metinler bu sabiti kullanır;
/// değiştirmek tek satırdır.
const String kRobotName = 'Üni';

/// Sonuçlar hesaplanırken gösterilen statik metin (yükleme kısa sürer,
/// typewriter gerekmez).
const String kResultsLoadingText =
    'Binlerce programı senin için tarıyorum…';

/// Filtreli aramada hiç eşleşme kalmadığında (WizardEmptyResults).
const String kEmptyResultsFilterText =
    'Bu filtrelerle eşleşen program bulamadım — birkaçını gevşetsek mi?';

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

/// Üni'nin tüm repliği. Ses tonu: birinci ağız, "sen" dili, sevimli ama
/// dürüst — yerleşme sözü ASLA verilmez; "tahmin/garanti veremem" korunur.
abstract final class RobotScripts {
  // ── Ana ekran: selamlama gövdeleri (faz + profil durumuna göre) ──
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

  // ── Günün ipucu ──
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

  // ── Sihirbaz girişi ──
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

  /// Giriş ekranında doğrulama hatası.
  static const wizardValidation = RobotScript(
    'wizard.validation.v1',
    'Bir saniye — önerilere geçebilmem için sıralamanı ya da puanını '
        'girmen gerekiyor.',
    RobotMood.concerned,
  );

  // ── Sonuç özetleri ({total}/{guaranteed}/{target}/{dream} doldurulur).
  // Hepsi "tahmin" içerir — dürüstlük tonu testle korunuyor. ──
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

  /// Puanla (sırasız) girişte sonuç özetine eklenen dürüstlük cümlesi.
  static const estimatedRankSuffix =
      ' Bu arada sıralamanı puanından tahmin ettim — gerçek sıranı '
      'girersen daha isabetli olurum.';

  // ── Liste sağlığı yorumları ──
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

  // ── Boş liste dürtmesi ──
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

  // ── Üni ile Sohbet — doğal dilli sihirbaz ──
  // `{...}` yer tutucularını ChatFlow doldurur. Onay balonu "tahmin" dili
  // taşır — dürüstlük tonu testle korunur.

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

  /// Kilitli serbest-yazı alanına dokununca: sohbet özelliği yolda.
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

  // ── Rozet kutlaması ──
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
}
