import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import {
  BadgeId,
  CITY_VIEW_TIERS,
  COMPARISON_TIERS,
  EARLY_ADOPTER_CUTOFF,
  FAVORITE_TIERS,
  HELPFUL_TIERS,
  MEMBERSHIP_TIERS,
  REVIEW_TIERS,
  SHARE_TIERS,
  STREAK_TIERS,
  UNIVERSITY_VIEW_TIERS,
  earnedFromTiers,
} from './catalog';

const db = admin.firestore();

export type { BadgeId } from './catalog';

/** Rozeti yoksa verir; varsa dokunmaz (idempotent). */
export async function awardBadgeIfMissing(
  uid: string,
  badgeId: BadgeId,
): Promise<void> {
  await awardBadgesIfMissing(uid, [badgeId]);
}

/**
 * Birden çok rozeti tek transaction'da verir; zaten olanlara dokunmaz.
 * Rozet verilememesi ana akışı (sayaç senkronu vb.) bozmamalı.
 */
export async function awardBadgesIfMissing(
  uid: string,
  badgeIds: BadgeId[],
): Promise<void> {
  if (badgeIds.length === 0) return;
  const userRef = db.collection('users').doc(uid);

  try {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(userRef);
      if (!snap.exists) return;

      const badges = (snap.data()?.badges ?? {}) as Record<string, unknown>;
      const missing = badgeIds.filter((id) => badges[id] == null);
      if (missing.length === 0) return;

      const update: Record<string, FieldValue> = {};
      for (const id of missing) {
        update[id] = FieldValue.serverTimestamp();
      }
      tx.set(userRef, { badges: update }, { merge: true });
    });
  } catch (err) {
    logger.warn('Badge award failed', { uid, badgeIds, err: String(err) });
  }
}

/** Onaylı yorum sayısına bağlı rozetleri değerlendirir. */
export async function evaluateReviewCountBadges(
  uid: string,
  approvedReviewCount: number,
): Promise<void> {
  await awardBadgesIfMissing(
    uid,
    earnedFromTiers(REVIEW_TIERS, approvedReviewCount),
  );
}

/**
 * Kullanıcının onaylı yorumlarının toplam beğenisine bağlı rozetler.
 * Toplamı ilerleme UI'ı için stats dokümanına da yazar.
 */
export async function evaluateHelpfulBadge(uid: string): Promise<void> {
  const totalLikes = await computeTotalLikesReceived(uid);

  try {
    await engagementStatsRef(uid).set(
      {
        totalLikesReceived: totalLikes,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  } catch (err) {
    logger.warn('totalLikesReceived write failed', { uid, err: String(err) });
  }

  await awardBadgesIfMissing(uid, earnedFromTiers(HELPFUL_TIERS, totalLikes));
}

/** Favori sayısına bağlı rozetler (users/{uid}/favorites count). */
export async function evaluateFavoriteBadges(uid: string): Promise<void> {
  const countSnap = await db
    .collection('users')
    .doc(uid)
    .collection('favorites')
    .count()
    .get();
  await awardBadgesIfMissing(
    uid,
    earnedFromTiers(FAVORITE_TIERS, countSnap.data().count),
  );
}

/** Farklı üniversite/şehir görüntüleme rozetleri. */
export async function evaluateExplorationBadges(
  uid: string,
  viewedUniversityCount: number,
  viewedCityCount: number,
): Promise<void> {
  await awardBadgesIfMissing(uid, [
    ...earnedFromTiers(UNIVERSITY_VIEW_TIERS, viewedUniversityCount),
    ...earnedFromTiers(CITY_VIEW_TIERS, viewedCityCount),
  ]);
}

export async function evaluateComparisonBadges(
  uid: string,
  comparisonCount: number,
): Promise<void> {
  await awardBadgesIfMissing(
    uid,
    earnedFromTiers(COMPARISON_TIERS, comparisonCount),
  );
}

export async function evaluateShareBadges(
  uid: string,
  shareCount: number,
): Promise<void> {
  await awardBadgesIfMissing(uid, earnedFromTiers(SHARE_TIERS, shareCount));
}

export async function evaluateStreakBadges(
  uid: string,
  currentStreak: number,
): Promise<void> {
  await awardBadgesIfMissing(uid, earnedFromTiers(STREAK_TIERS, currentStreak));
}

/**
 * Kullanıcı dokümanından türeyen "ortam" rozetleri: üyelik yaşı, profil
 * tamamlama, onaylı öğrenci, early adopter. app_open ve profil
 * güncellemelerinde çağrılır — scheduler gerekmez.
 */
export async function evaluateAmbientBadges(
  uid: string,
  userData?: FirebaseFirestore.DocumentData,
): Promise<void> {
  const data = userData ?? (await db.collection('users').doc(uid).get()).data();
  if (!data) return;

  await awardBadgesIfMissing(uid, ambientBadgesFor(data));
}

/** Ortam rozetlerini (yazmadan) hesaplar; backfill de kullanır. */
export function ambientBadgesFor(
  data: FirebaseFirestore.DocumentData,
): BadgeId[] {
  const earned: BadgeId[] = [];

  const createdAt = (data.createdAt as admin.firestore.Timestamp | undefined)
    ?.toDate();
  if (createdAt) {
    const ageDays = (Date.now() - createdAt.getTime()) / (24 * 60 * 60 * 1000);
    earned.push(...earnedFromTiers(MEMBERSHIP_TIERS, Math.floor(ageDays)));
    if (createdAt.getTime() < EARLY_ADOPTER_CUTOFF.getTime()) {
      earned.push('early_adopter');
    }
  }

  if (data.isVerifiedStudent === true) {
    earned.push('verified_scholar');
  }

  // `university` alanı server-set (verify akışı) olduğundan hariç.
  const filled = (v: unknown): boolean =>
    typeof v === 'string' ? v.trim().length > 0 : v != null;
  if (
    filled(data.photoUrl) &&
    filled(data.bio) &&
    filled(data.department) &&
    filled(data.grade)
  ) {
    earned.push('profile_complete');
  }

  return earned;
}

/**
 * Tüm rozet kriterlerini baştan değerlendirir (backfill / app_open).
 * Engagement sayaçları stats dokümanından okunur; yoksa sıfır kabul edilir.
 */
export async function evaluateAllBadges(uid: string): Promise<void> {
  const earned = await computeEarnedBadges(uid);
  await awardBadgesIfMissing(uid, earned);
}

/**
 * Kullanıcının şu an hak ettiği TÜM rozetleri (zaten sahip olduklarından
 * bağımsız) hesaplar. Yazmaz — backfill dry-run bunun üstüne kurulu.
 */
export async function computeEarnedBadges(uid: string): Promise<BadgeId[]> {
  const userRef = db.collection('users').doc(uid);
  const [userSnap, statsSnap, favoritesCount] = await Promise.all([
    userRef.get(),
    engagementStatsRef(uid).get(),
    userRef.collection('favorites').count().get(),
  ]);

  const userData = userSnap.data();
  if (!userData) return [];

  const stats = statsSnap.data() ?? {};
  const totalLikes = await computeTotalLikesReceived(uid);

  return [
    ...earnedFromTiers(REVIEW_TIERS, safeCount(userData.reviewCount)),
    ...earnedFromTiers(HELPFUL_TIERS, totalLikes),
    ...earnedFromTiers(FAVORITE_TIERS, favoritesCount.data().count),
    ...earnedFromTiers(
      UNIVERSITY_VIEW_TIERS,
      safeCount(stats.viewedUniversityCount),
    ),
    ...earnedFromTiers(CITY_VIEW_TIERS, safeCount(stats.viewedCityCount)),
    ...earnedFromTiers(COMPARISON_TIERS, safeCount(stats.comparisonCount)),
    ...earnedFromTiers(SHARE_TIERS, safeCount(stats.shareCount)),
    ...earnedFromTiers(STREAK_TIERS, safeCount(stats.currentStreak)),
    ...ambientBadgesFor(userData),
  ];
}

export function engagementStatsRef(
  uid: string,
): FirebaseFirestore.DocumentReference {
  return db
    .collection('users')
    .doc(uid)
    .collection('stats')
    .doc('engagement');
}

async function computeTotalLikesReceived(uid: string): Promise<number> {
  const reviews = await db
    .collection('reviews')
    .where('userId', '==', uid)
    .where('isApproved', '==', true)
    .select('likes')
    .get();

  return reviews.docs.reduce(
    (sum, doc) => sum + Number(doc.data().likes ?? 0),
    0,
  );
}

function safeCount(value: unknown): number {
  const n = Number(value);
  if (!Number.isFinite(n) || n < 0) return 0;
  return Math.floor(n);
}
