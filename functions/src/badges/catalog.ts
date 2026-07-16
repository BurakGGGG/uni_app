/**
 * Rozet kataloğu — sunucu tarafı tek gerçek kaynak.
 *
 * DİKKAT: Bu liste istemcideki
 * lib/features/profile/domain/badge_catalog.dart ile birebir aynı
 * tutulmalıdır. Yeni rozet eklerken iki dosyayı birlikte güncelle.
 */

export const BADGE_IDS = [
  // Yorumcu
  'first_review',
  'detailed_reviewer',
  'prolific_reviewer',
  'review_legend',
  // Kahraman (beğeni)
  'helpful',
  'community_hero',
  'like_magnet',
  // Koleksiyon (favori)
  'collector',
  'master_collector',
  // Keşif
  'explorer',
  'wanderer',
  'cartographer',
  'city_traveler',
  // Analiz (karşılaştırma)
  'analyst',
  'strategist',
  // Paylaşım
  'ambassador',
  'super_ambassador',
  // Seri (üst üste gün)
  'streak_starter',
  'streak_keeper',
  'streak_master',
  // Üyelik
  'loyal_member',
  'veteran',
  // Özel
  'profile_complete',
  'verified_scholar',
  'early_adopter',
] as const;

export type BadgeId = (typeof BADGE_IDS)[number];

/** Eşik → rozet eşlemeleri; artan sırada tutulur. */
export const REVIEW_TIERS: ReadonlyArray<[number, BadgeId]> = [
  [1, 'first_review'],
  [3, 'detailed_reviewer'],
  [10, 'prolific_reviewer'],
  [25, 'review_legend'],
];

export const HELPFUL_TIERS: ReadonlyArray<[number, BadgeId]> = [
  [10, 'helpful'],
  [50, 'community_hero'],
  [150, 'like_magnet'],
];

export const FAVORITE_TIERS: ReadonlyArray<[number, BadgeId]> = [
  [5, 'collector'],
  [15, 'master_collector'],
];

export const UNIVERSITY_VIEW_TIERS: ReadonlyArray<[number, BadgeId]> = [
  [10, 'explorer'],
  [30, 'wanderer'],
  [60, 'cartographer'],
];

export const CITY_VIEW_TIERS: ReadonlyArray<[number, BadgeId]> = [
  [5, 'city_traveler'],
];

export const COMPARISON_TIERS: ReadonlyArray<[number, BadgeId]> = [
  [5, 'analyst'],
  [20, 'strategist'],
];

export const SHARE_TIERS: ReadonlyArray<[number, BadgeId]> = [
  [3, 'ambassador'],
  [10, 'super_ambassador'],
];

export const STREAK_TIERS: ReadonlyArray<[number, BadgeId]> = [
  [3, 'streak_starter'],
  [7, 'streak_keeper'],
  [30, 'streak_master'],
];

export const MEMBERSHIP_TIERS: ReadonlyArray<[number, BadgeId]> = [
  [30, 'loyal_member'],
  [365, 'veteran'],
];

/**
 * Bu tarihten önce açılan hesaplar "İlk Nesil" (early_adopter) rozetini alır.
 * Yayın tarihi + ~60 gün; release netleşince gerekirse güncelle.
 */
export const EARLY_ADOPTER_CUTOFF = new Date('2026-09-15T00:00:00Z');

/** Keşif map'lerinin doküman boyutunu sınırlamak için üst sınırlar. */
export const VIEWED_UNIVERSITY_CAP = 80;
export const VIEWED_CITY_CAP = 30;

/** Eşik tablosundan, verilen sayaçla hak edilen rozetleri döndürür. */
export function earnedFromTiers(
  tiers: ReadonlyArray<[number, BadgeId]>,
  count: number,
): BadgeId[] {
  return tiers.filter(([threshold]) => count >= threshold).map(([, id]) => id);
}

const istanbulDateFormat = new Intl.DateTimeFormat('en-CA', {
  timeZone: 'Europe/Istanbul',
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
});

/**
 * Europe/Istanbul gününü 'YYYY-MM-DD' verir. Streak hesapları bu takvime
 * göre yapılır (analytics'teki UTC formatDate'i KULLANMA). Türkiye'de DST
 * olmadığından "dün" = şimdi - 24 saat güvenlidir.
 */
export function istanbulDateString(date: Date = new Date()): string {
  return istanbulDateFormat.format(date);
}

export function istanbulYesterdayString(now: Date = new Date()): string {
  return istanbulDateString(new Date(now.getTime() - 24 * 60 * 60 * 1000));
}
