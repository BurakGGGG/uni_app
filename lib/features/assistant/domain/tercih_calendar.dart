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

/// Bulunulan fazın son günü (dahil) — geri sayımlar bunu kullanır.
///
/// Sezon dışı (Ekim–Nisan) yıl sınırını aştığı için null döner; oraya geri
/// sayım koymanın da anlamı yok.
DateTime? phaseEndFor(DateTime now) {
  final (month, day) = switch (tercihPhaseFor(now)) {
    TercihPhase.examCountdown => (6, 13),
    TercihPhase.examWeek => (6, 22),
    TercihPhase.resultsWait => (7, 14),
    TercihPhase.tercihPeriod => (8, 5),
    TercihPhase.placementWait => (8, 27),
    TercihPhase.placementDone => (9, 30),
    TercihPhase.offSeason => (0, 0),
  };
  if (month == 0) return null;
  return DateTime(now.year, month, day);
}

/// Fazın bitişine kalan tam gün sayısı; sezon dışında null.
/// Son gün 0 döner ("bugün son gün").
int? daysLeftInPhase(DateTime now) {
  final end = phaseEndFor(now);
  if (end == null) return null;
  final today = DateTime(now.year, now.month, now.day);
  return end.difference(today).inDays;
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
