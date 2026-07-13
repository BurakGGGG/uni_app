import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';

const db = admin.firestore();

/**
 * Rozet kimlikleri — users/{uid}.badges map'inde anahtar olarak tutulur
 * (değer: verildiği an, Timestamp). Rozetler yalnızca server tarafından
 * yazılır (isSafeUserUpdate whitelist'i dışında) ve geri alınmaz.
 */
export type BadgeId = 'first_review' | 'detailed_reviewer' | 'helpful';

export const BADGE_THRESHOLDS = {
  detailedReviewerReviewCount: 3,
  helpfulTotalLikes: 10,
} as const;

/** Rozeti yoksa verir; varsa dokunmaz (idempotent). */
export async function awardBadgeIfMissing(
  uid: string,
  badgeId: BadgeId,
): Promise<void> {
  const userRef = db.collection('users').doc(uid);

  try {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(userRef);
      if (!snap.exists) return;

      const badges = (snap.data()?.badges ?? {}) as Record<string, unknown>;
      if (badges[badgeId] != null) return;

      tx.set(
        userRef,
        {
          badges: { [badgeId]: FieldValue.serverTimestamp() },
        },
        { merge: true },
      );
    });
  } catch (err) {
    // Rozet verilememesi ana akışı (sayaç senkronu) bozmamalı.
    logger.warn('Badge award failed', { uid, badgeId, err: String(err) });
  }
}

/** Onaylı yorum sayısına bağlı rozetleri değerlendirir. */
export async function evaluateReviewCountBadges(
  uid: string,
  approvedReviewCount: number,
): Promise<void> {
  if (approvedReviewCount >= 1) {
    await awardBadgeIfMissing(uid, 'first_review');
  }
  if (approvedReviewCount >= BADGE_THRESHOLDS.detailedReviewerReviewCount) {
    await awardBadgeIfMissing(uid, 'detailed_reviewer');
  }
}

/** Kullanıcının onaylı yorumlarının toplam beğenisine bağlı rozet. */
export async function evaluateHelpfulBadge(uid: string): Promise<void> {
  const reviews = await db
    .collection('reviews')
    .where('userId', '==', uid)
    .where('isApproved', '==', true)
    .select('likes')
    .get();

  const totalLikes = reviews.docs.reduce(
    (sum, doc) => sum + Number(doc.data().likes ?? 0),
    0,
  );

  if (totalLikes >= BADGE_THRESHOLDS.helpfulTotalLikes) {
    await awardBadgeIfMissing(uid, 'helpful');
  }
}
