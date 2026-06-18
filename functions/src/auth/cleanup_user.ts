import * as admin from 'firebase-admin';
import * as functionsV1 from 'firebase-functions/v1';
import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

const db = admin.firestore();
const MAX_AUTH_AGE_SECONDS = 10 * 60;
const QUERY_BATCH_SIZE = 100;
const LOG_COMPONENT = 'auth.deleteUserAccount';

interface CleanupStats {
  deletedDocuments: number;
  deletedStoragePrefixes: number;
  anonymizedDocuments: number;
}

export const deleteUserAccount = onCall(
  {
    region: 'europe-west1',
    timeoutSeconds: 540,
    memory: '512MiB',
    cors: true,
    enforceAppCheck: true,
  },
  async (req): Promise<{ ok: true }> => {
    const auth = req.auth;
    if (!auth) {
      throw new HttpsError('unauthenticated', 'Giriş gerekli.');
    }
    const uid = auth.uid;
    if (req.data?.confirmation !== 'DELETE') {
      throw new HttpsError(
        'invalid-argument',
        'Hesap silme onayı geçersiz.',
      );
    }

    requireRecentAuthentication(auth.token.auth_time);

    logger.info('Account deletion started', {
      component: LOG_COMPONENT,
      uid,
      appId: req.app?.appId ?? null,
    });

    try {
      const stats = await cleanupUserData(uid);

      // Authentication is deleted last. If any cleanup step fails, the user
      // remains authenticated and can safely retry without leaving orphan data.
      await admin.auth().deleteUser(uid);

      logger.info('Account deletion completed', {
        component: LOG_COMPONENT,
        uid,
        ...stats,
      });
      return { ok: true };
    } catch (error) {
      logger.error('Account deletion failed', {
        component: LOG_COMPONENT,
        uid,
        error: String(error),
      });
      throw new HttpsError(
        'internal',
        'Hesap şu anda silinemedi. Lütfen daha sonra tekrar deneyin.',
      );
    }
  },
);

/**
 * Firebase Console or another trusted backend can also delete an Auth user.
 * This trigger provides an idempotent cleanup fallback for those cases.
 */
export const cleanupDeletedUserAccount = functionsV1
  .region('europe-west1')
  .auth.user()
  .onDelete(async (user) => {
    try {
      const stats = await cleanupUserData(user.uid);
      logger.info('Deleted Auth user cleanup completed', {
        component: LOG_COMPONENT,
        uid: user.uid,
        ...stats,
      });
    } catch (error) {
      logger.error('Deleted Auth user cleanup failed', {
        component: LOG_COMPONENT,
        uid: user.uid,
        error: String(error),
      });
      throw error;
    }
  });

async function cleanupUserData(uid: string): Promise<CleanupStats> {
  const stats: CleanupStats = {
    deletedDocuments: 0,
    deletedStoragePrefixes: 0,
    anonymizedDocuments: 0,
  };

  // Top-level documents owned by the user. recursiveDelete also removes
  // subcollections such as likes under reviews.
  const ownedQueries = [
    db.collection('reviews').where('userId', '==', uid),
    db.collection('reports').where('userId', '==', uid),
    db.collection('feedback').where('userId', '==', uid),
    db.collection('preferenceLists').where('userId', '==', uid),
    db.collection('notifications').where('userId', '==', uid),
    db.collection('place_suggestions').where('userId', '==', uid),
    db.collection('aiSummaryLogs').where('userId', '==', uid),
    db.collection('recommendationEnrichments').where('userId', '==', uid),
    db.collection('suspiciousActivityLogs').where('uid', '==', uid),
    db.collection('webhookEvents').where('appUserId', '==', uid),
  ];

  for (const query of ownedQueries) {
    stats.deletedDocuments += await deleteQueryRecursively(query);
  }

  stats.deletedDocuments += await deleteLikesCreatedByUser(uid);
  stats.anonymizedDocuments += await anonymizeApprovedPlaces(uid);
  stats.anonymizedDocuments += await anonymizeAdminAuditLogs(uid);
  stats.anonymizedDocuments += await removeUidFromSummaryCache(uid);

  const directRefs = [
    db.collection('publicProfiles').doc(uid),
    db.collection('subscriptions').doc(uid),
    db.collection('analyticsRateLimits').doc(uid),
    db.collection('submissionRateLimits').doc(`review_create_${uid}`),
    db.collection('submissionRateLimits').doc(`report_${uid}`),
    db.collection('submissionRateLimits').doc(`feedback_${uid}`),
    db.collection('submissionRateLimits').doc(`place_suggestion_${uid}`),
    db.collection('submissionRateLimits').doc(`place_duplicate_check_${uid}`),
  ];
  for (const ref of directRefs) {
    const snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
      stats.deletedDocuments++;
    }
  }

  const userRef = db.collection('users').doc(uid);
  const userSnap = await userRef.get();
  if (userSnap.exists) {
    await db.recursiveDelete(userRef);
    stats.deletedDocuments++;
  }

  const bucket = admin.storage().bucket();
  const storagePrefixes = [
    `profile_photos/${uid}.jpg`,
    `review_images/${uid}/`,
    `place_suggestions/${uid}/`,
  ];
  for (const prefix of storagePrefixes) {
    await bucket.deleteFiles({ prefix, force: true });
    stats.deletedStoragePrefixes++;
  }

  return stats;
}

function requireRecentAuthentication(authTimeValue: unknown): void {
  const authTime = Number(authTimeValue);
  const nowSeconds = Math.floor(Date.now() / 1000);
  if (
    !Number.isFinite(authTime) ||
    authTime <= 0 ||
    nowSeconds - authTime > MAX_AUTH_AGE_SECONDS
  ) {
    throw new HttpsError(
      'failed-precondition',
      'Hesabı silmek için yeniden giriş yapmanız gerekiyor.',
    );
  }
}

async function deleteQueryRecursively(
  query: admin.firestore.Query,
): Promise<number> {
  let deleted = 0;

  let snapshot = await query.limit(QUERY_BATCH_SIZE).get();
  while (!snapshot.empty) {
    for (const doc of snapshot.docs) {
      await db.recursiveDelete(doc.ref);
      deleted++;
    }
    snapshot = await query.limit(QUERY_BATCH_SIZE).get();
  }

  return deleted;
}

async function deleteLikesCreatedByUser(uid: string): Promise<number> {
  let deleted = 0;
  let cursor: admin.firestore.QueryDocumentSnapshot | undefined;
  let hasMore = true;

  while (hasMore) {
    let query = db
      .collectionGroup('likes')
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(QUERY_BATCH_SIZE);
    if (cursor) query = query.startAfter(cursor);

    const snapshot = await query.get();
    if (snapshot.empty) return deleted;

    const batch = db.batch();
    let batchDeletes = 0;
    for (const doc of snapshot.docs) {
      if (doc.id === uid) {
        batch.delete(doc.ref);
        batchDeletes++;
      }
    }
    if (batchDeletes > 0) {
      await batch.commit();
      deleted += batchDeletes;
    }

    cursor = snapshot.docs[snapshot.docs.length - 1];
    hasMore = snapshot.size === QUERY_BATCH_SIZE;
  }

  return deleted;
}

async function anonymizeApprovedPlaces(uid: string): Promise<number> {
  const query = db.collection('places').where('suggestedByUserId', '==', uid);
  return updateQuery(query, () => ({
    suggestedByUserId: admin.firestore.FieldValue.delete(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }));
}

async function anonymizeAdminAuditLogs(uid: string): Promise<number> {
  const query = db.collection('adminAuditLogs').where('actorUid', '==', uid);
  return updateQuery(query, () => ({
    actorUid: 'deleted-user',
  }));
}

async function removeUidFromSummaryCache(uid: string): Promise<number> {
  return updateQuery(db.collection('aiSummaryCache'), (data) => {
    const regeneratedBy = data.regeneratedBy;
    if (
      regeneratedBy === null ||
      typeof regeneratedBy !== 'object' ||
      Array.isArray(regeneratedBy) ||
      !(uid in regeneratedBy)
    ) {
      return null;
    }
    return {
      [`regeneratedBy.${uid}`]: admin.firestore.FieldValue.delete(),
    };
  });
}

async function updateQuery(
  query: admin.firestore.Query,
  patchFor: (
    data: admin.firestore.DocumentData,
  ) => admin.firestore.UpdateData<admin.firestore.DocumentData> | null,
): Promise<number> {
  let updated = 0;
  let cursor: admin.firestore.QueryDocumentSnapshot | undefined;
  let hasMore = true;

  while (hasMore) {
    let page = query
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(QUERY_BATCH_SIZE);
    if (cursor) page = page.startAfter(cursor);

    const snapshot = await page.get();
    if (snapshot.empty) return updated;

    const batch = db.batch();
    let batchUpdates = 0;
    for (const doc of snapshot.docs) {
      const patch = patchFor(doc.data());
      if (patch) {
        batch.update(doc.ref, patch);
        batchUpdates++;
      }
    }
    if (batchUpdates > 0) {
      await batch.commit();
      updated += batchUpdates;
    }

    cursor = snapshot.docs[snapshot.docs.length - 1];
    hasMore = snapshot.size === QUERY_BATCH_SIZE;
  }

  return updated;
}
