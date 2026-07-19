/// YKS/tercih yılı takvimi — Üni'nin mesajlarını döneme göre seçmek için.
/// Sınırlar yaklaşık ÖSYM takvimine göre sabit ay/gün aralıklarıdır ve
/// yıldan bağımsız çalışır. İleride Remote Config'e taşınabilir; şimdilik
/// sabit tablo yeterli.
enum TercihPhase {
  /// Mayıs başı – sınava son günler.
  examCountdown,

  /// YKS haftası (~20 Haziran hafta sonu).
  examWeek,

  /// Sınav sonrası sonuç bekleyişi (~temmuz ortasına dek).
  resultsWait,

  /// Tercih dönemi (~15 Temmuz – 5 Ağustos).
  tercihPeriod,

  /// Tercihler kapandı, yerleştirme sonucu bekleniyor.
  placementWait,

  /// Yerleştirme açıklandı, kayıt/ek yerleştirme günleri.
  placementDone,

  /// Ekim – Nisan: sezon dışı keşif dönemi.
  offSeason,
}

TercihPhase tercihPhaseFor(DateTime now) {
  final md = now.month * 100 + now.day;
  if (md >= 501 && md <= 613) return TercihPhase.examCountdown;
  if (md >= 614 && md <= 622) return TercihPhase.examWeek;
  if (md >= 623 && md <= 714) return TercihPhase.resultsWait;
  if (md >= 715 && md <= 805) return TercihPhase.tercihPeriod;
  if (md >= 806 && md <= 827) return TercihPhase.placementWait;
  if (md >= 828 && md <= 930) return TercihPhase.placementDone;
  return TercihPhase.offSeason;
}

/// Günün dilimi — selamlama tonu için.
enum DayPeriod { morning, afternoon, evening, night }

DayPeriod dayPeriodFor(DateTime now) {
  final h = now.hour;
  if (h >= 5 && h < 12) return DayPeriod.morning;
  if (h >= 12 && h < 18) return DayPeriod.afternoon;
  if (h >= 18 && h < 23) return DayPeriod.evening;
  return DayPeriod.night;
}

/// Ana ekran rozet çipi etiketi ("2026 TERCİH DÖNEMİ" gibi) — döneme göre.
String phaseChipLabel(TercihPhase phase, int year) {
  switch (phase) {
    case TercihPhase.examCountdown:
      return '$year YKS YAKLAŞIYOR';
    case TercihPhase.examWeek:
      return '$year YKS HAFTASI';
    case TercihPhase.resultsWait:
      return '$year SONUÇLAR YOLDA';
    case TercihPhase.tercihPeriod:
      return '$year TERCİH DÖNEMİ';
    case TercihPhase.placementWait:
      return '$year YERLEŞTİRME BEKLENİYOR';
    case TercihPhase.placementDone:
      return '$year YERLEŞTİRME AÇIKLANDI';
    case TercihPhase.offSeason:
      return 'KEŞFETMEYE DEVAM';
  }
}
