import '../../score_calculator/domain/models/score_input.dart';

/// "Tercih Yolun" akışının adımları.
///
/// Akış onboarding gibi ekran ekran ilerler: her ekranda tek soru. Eskiden
/// aynı bilgiler tek uzun formda alt alta soruluyordu (TYT netleri, AYT
/// netleri, hedef bölüm, ilgi alanları...) ve öğrenci hiçbir çıktı görmeden
/// onlarca alan dolduruyordu.
enum UniFlowStep {
  /// Nasıl başlayalım: netlerimi gireyim / sıralamam var / puanım var.
  start,

  tytNets,
  aytNets,
  obp,

  /// Sıra yolu — netlerin ve OBP'nin yerine geçer.
  rank,

  /// Puan yolu — netlerin ve OBP'nin yerine geçer.
  score,

  /// "İşte puanın" — profil BURADA kaydedilir.
  reveal,

  /// Aklındaki bölüm (opsiyonel) + o bölümün şans dağılımı.
  targetDept,

  interests,
  cities,

  /// Kart kart programı listeye ekleme.
  buildList,

  /// Kapanış özeti.
  done,
}

extension UniFlowStepX on UniFlowStep {
  /// Atlanabilir adımlar: cevapsız da yola devam edilebilenler. Puan
  /// adımları atlanamaz — onlarsız akışın çıktısı yok.
  bool get skippable => switch (this) {
        UniFlowStep.targetDept ||
        UniFlowStep.interests ||
        UniFlowStep.cities ||
        UniFlowStep.buildList =>
          true,
        _ => false,
      };

  /// Puanın kurulduğu bölüm mü? (İlerleme çubuğunda bölüm etiketi için.)
  bool get isScorePart => switch (this) {
        UniFlowStep.start ||
        UniFlowStep.tytNets ||
        UniFlowStep.aytNets ||
        UniFlowStep.obp ||
        UniFlowStep.rank ||
        UniFlowStep.score ||
        UniFlowStep.reveal =>
          true,
        _ => false,
      };
}

/// Akışın niçin açıldığı.
enum UniFlowMode {
  /// Baştan sona yürüyüş.
  setup,

  /// Özet ekranından tek bir adımı düzenlemek için gelindi: o adım biter
  /// bitmez özete dönülür.
  editOne,
}

/// Rotadaki `?step=` değerini adıma çevirir; tanınmayan değerde null döner
/// (akış baştan başlar). Kısa adlar bilinçli: derin bağlantılar okunabilir
/// kalsın.
UniFlowStep? uniFlowStepFromQuery(String? value) => switch (value) {
      'score' => UniFlowStep.start,
      'target' => UniFlowStep.targetDept,
      'interests' => UniFlowStep.interests,
      'cities' => UniFlowStep.cities,
      'list' => UniFlowStep.buildList,
      _ => null,
    };

/// [mode] ve giriş yoluna göre yürünecek adımlar.
///
/// Sıra/puan yolu netleri ve OBP'yi atlar: girilen sıra zaten yerleştirme
/// puanını içerir, net sormak boşuna üç ekran olurdu.
List<UniFlowStep> uniFlowSteps({
  required NetEntryMode entryMode,
  UniFlowMode mode = UniFlowMode.setup,
  UniFlowStep? only,
}) {
  if (mode == UniFlowMode.editOne) {
    return [only ?? UniFlowStep.interests];
  }
  return [
    UniFlowStep.start,
    ...switch (entryMode) {
      NetEntryMode.rank => const [UniFlowStep.rank],
      NetEntryMode.score => const [UniFlowStep.score],
      _ => const [UniFlowStep.tytNets, UniFlowStep.aytNets, UniFlowStep.obp],
    },
    UniFlowStep.reveal,
    UniFlowStep.targetDept,
    UniFlowStep.interests,
    UniFlowStep.cities,
    UniFlowStep.buildList,
    UniFlowStep.done,
  ];
}
