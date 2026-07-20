/**
 * YKS/tercih takvimi — sunucu tarafı aynası.
 *
 * DİKKAT: Bu tablo istemcideki
 * lib/features/assistant/domain/tercih_calendar.dart ile birebir aynı
 * tutulmalıdır. Sınırları değiştirirken iki dosyayı birlikte güncelle.
 * (Aynı ayna deseni: functions/src/badges/catalog.ts.)
 *
 * Sınırlar yaklaşık ÖSYM takvimine göre sabit ay/gün aralıklarıdır ve
 * yıldan bağımsız çalışır.
 *
 * ZAMAN DİLİMİ: Buradaki tüm fonksiyonlar Date'in UTC alanlarını okur.
 * İstemci yerel saate bakar; sunucu UTC'de çalıştığı için takvim günü
 * kaymasın diye çağıran [istanbulNow] ile İstanbul duvar saatine kaydırılmış
 * bir Date verir. Testler doğrudan `Date.UTC(...)` geçebilir.
 */

export type TercihPhase =
  | 'examCountdown'
  | 'examWeek'
  | 'resultsWait'
  | 'tercihPeriod'
  | 'placementWait'
  | 'placementDone'
  | 'offSeason';

/** Faz sınırları — ay*100 + gün (Dart'taki `md` ile aynı kodlama). */
export const PHASE_BOUNDS = {
  examCountdown: { from: 501, to: 613 },
  examWeek: { from: 614, to: 622 },
  resultsWait: { from: 623, to: 714 },
  tercihPeriod: { from: 715, to: 805 },
  placementWait: { from: 806, to: 827 },
  placementDone: { from: 828, to: 930 },
} as const;

/** Türkiye yıl boyu UTC+3. */
const ISTANBUL_OFFSET_MS = 3 * 60 * 60 * 1000;

/**
 * UTC alanları İstanbul duvar saatini gösteren bir Date döner.
 * Bu dosyadaki diğer fonksiyonlara verilecek "şimdi" budur.
 */
export function istanbulNow(now: Date = new Date()): Date {
  return new Date(now.getTime() + ISTANBUL_OFFSET_MS);
}

/** Tarihin ay*100+gün kodu (UTC alanlarından). */
export function monthDay(d: Date): number {
  return (d.getUTCMonth() + 1) * 100 + d.getUTCDate();
}

export function tercihPhaseFor(now: Date): TercihPhase {
  const md = monthDay(now);
  const b = PHASE_BOUNDS;
  if (md >= b.examCountdown.from && md <= b.examCountdown.to) {
    return 'examCountdown';
  }
  if (md >= b.examWeek.from && md <= b.examWeek.to) return 'examWeek';
  if (md >= b.resultsWait.from && md <= b.resultsWait.to) return 'resultsWait';
  if (md >= b.tercihPeriod.from && md <= b.tercihPeriod.to) {
    return 'tercihPeriod';
  }
  if (md >= b.placementWait.from && md <= b.placementWait.to) {
    return 'placementWait';
  }
  if (md >= b.placementDone.from && md <= b.placementDone.to) {
    return 'placementDone';
  }
  return 'offSeason';
}

/**
 * Tercih döneminin kapanmasına kaç gün kaldığı; dönem dışındaysa null.
 * Son gün 0 döner.
 */
export function daysUntilTercihClose(now: Date): number | null {
  if (tercihPhaseFor(now) !== 'tercihPeriod') return null;
  const to = PHASE_BOUNDS.tercihPeriod.to;
  const close = Date.UTC(
    now.getUTCFullYear(),
    Math.floor(to / 100) - 1,
    to % 100,
  );
  const today = Date.UTC(
    now.getUTCFullYear(),
    now.getUTCMonth(),
    now.getUTCDate(),
  );
  return Math.round((close - today) / 86400000);
}
