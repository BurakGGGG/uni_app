/// Üni'nin (ÜniSeç robotu) duygu durumları.
/// Avatar çizimi (göz/ağız/anten) ve mesaj tonu bu enum'dan türetilir.
enum RobotMood {
  /// Sakin bekleme — kapsül gözler, düz ağız.
  neutral,

  /// Memnun — gülen hilal gözler, gülümseme, yanaklar.
  happy,

  /// Düşünüyor/hesaplıyor — yukarı bakan gözler, kalkık kaş, "o" ağız.
  thinking,

  /// Kutlama — gülen gözler, parlayan anten, yanaklar.
  celebrating,

  /// Endişeli — küçülmüş gözler, eğik kaşlar, hafif aşağı ağız.
  concerned,

  /// Uyuyor — kapalı çizgi gözler, ağız yok.
  sleeping,
}
