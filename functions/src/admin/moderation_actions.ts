import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';

const db = admin.firestore();
const storage = admin.storage();

const LOG_COMPONENT = 'admin.performModerationAction';
type StorageFile = ReturnType<ReturnType<typeof storage.bucket>['file']>;

type AdminAction =
  | 'updateReportStatus'
  | 'hideReview'
  | 'unhideReview'
  | 'deleteReview'
  | 'updateFeedbackStatus'
  | 'deleteFeedback';

type ReportStatus = 'pending' | 'reviewed' | 'dismissed' | 'actioned';
type FeedbackStatus = 'new' | 'in_progress' | 'resolved';

interface AdminActionInput {
  action?: unknown;
  reportId?: unknown;
  reviewId?: unknown;
  feedbackId?: unknown;
  status?: unknown;
  adminNote?: unknown;
}

interface AuditLogInput {
  actorUid: string;
  action: string;
  targetCollection: 'reports' | 'reviews' | 'feedback';
  targetId: string;
  reportId?: string;
  reviewId?: string;
  feedbackId?: string;
  reviewOwnerId?: string;
  status?: string;
  adminNotePresent?: boolean;
  photoCount?: number;
}

export const performAdminModerationAction = onCall(
  {
    region: 'europe-west1',
    timeoutSeconds: 30,
    memory: '256MiB',
    cors: true,
    enforceAppCheck: true,
  },
  async (req): Promise<{ ok: true }> => {
    if (!req.auth) {
      throw new HttpsError('unauthenticated', 'Giriş gerekli.');
    }
    if (req.auth.token.admin !== true) {
      throw new HttpsError('permission-denied', 'Admin yetkisi gerekli.');
    }

    const uid = req.auth.uid;
    const input = (req.data ?? {}) as AdminActionInput;
    const action = parseAction(input.action);

    logger.info('Admin moderation action requested', {
      component: LOG_COMPONENT,
      uid,
      action,
      appCheckPresent: Boolean(req.app),
    });

    switch (action) {
      case 'updateReportStatus':
        await updateReportStatus(uid, input);
        break;
      case 'hideReview':
        await hideReview(uid, input);
        break;
      case 'unhideReview':
        await unhideReview(uid, input);
        break;
      case 'deleteReview':
        await deleteReview(uid, input);
        break;
      case 'updateFeedbackStatus':
        await updateFeedbackStatus(uid, input);
        break;
      case 'deleteFeedback':
        await deleteFeedback(uid, input);
        break;
    }

    logger.info('Admin moderation action accepted', {
      component: LOG_COMPONENT,
      uid,
      action,
      appCheckPresent: Boolean(req.app),
    });
    return { ok: true };
  },
);

async function updateReportStatus(uid: string, input: AdminActionInput) {
  const reportId = parseId(input.reportId, 'reportId');
  const status = parseReportStatus(input.status);
  const adminNote = parseOptionalString(input.adminNote, 'adminNote', 1000);

  const batch = db.batch();
  batch.update(db.collection('reports').doc(reportId), {
    status,
    adminNote: adminNote ?? null,
    reviewedBy: uid,
    reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  setAuditLog(batch, {
    actorUid: uid,
    action: 'report_status_updated',
    targetCollection: 'reports',
    targetId: reportId,
    reportId,
    status,
    adminNotePresent: adminNote !== undefined,
  });
  await batch.commit();
}

async function hideReview(uid: string, input: AdminActionInput) {
  const reviewId = parseId(input.reviewId, 'reviewId');
  const reportId = parseOptionalString(input.reportId, 'reportId', 256);
  const adminNote = parseOptionalString(input.adminNote, 'adminNote', 1000);
  const reviewRef = db.collection('reviews').doc(reviewId);
  const reviewSnap = await reviewRef.get();
  if (!reviewSnap.exists) {
    throw new HttpsError('not-found', 'Yorum bulunamadı.');
  }
  if (reportId) {
    await assertReportMatchesReview(reportId, reviewId);
  }
  const reviewOwnerId = parseExistingString(reviewSnap.data()?.userId);

  const batch = db.batch();
  batch.update(reviewRef, {
    isApproved: false,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  if (reportId) {
    batch.update(db.collection('reports').doc(reportId), {
      status: 'actioned',
      adminNote: adminNote ?? null,
      reviewedBy: uid,
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    setAuditLog(batch, {
      actorUid: uid,
      action: 'report_status_updated',
      targetCollection: 'reports',
      targetId: reportId,
      reportId,
      status: 'actioned',
      adminNotePresent: adminNote !== undefined,
    });
  }
  if (reviewOwnerId) {
    setReviewModerationNotification(batch, reviewOwnerId, 'hidden', adminNote);
  }
  setAuditLog(batch, {
    actorUid: uid,
    action: 'review_hidden',
    targetCollection: 'reviews',
    targetId: reviewId,
    reportId,
    reviewId,
    reviewOwnerId,
  });
  await batch.commit();
}

async function unhideReview(uid: string, input: AdminActionInput) {
  const reviewId = parseId(input.reviewId, 'reviewId');
  const batch = db.batch();
  batch.update(db.collection('reviews').doc(reviewId), {
    isApproved: true,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  setAuditLog(batch, {
    actorUid: uid,
    action: 'review_unhidden',
    targetCollection: 'reviews',
    targetId: reviewId,
    reviewId,
  });
  await batch.commit();
}

async function deleteReview(uid: string, input: AdminActionInput) {
  const reviewId = parseId(input.reviewId, 'reviewId');
  const reportId = parseOptionalString(input.reportId, 'reportId', 256);
  const adminNote = parseOptionalString(input.adminNote, 'adminNote', 1000);
  const reviewRef = db.collection('reviews').doc(reviewId);
  const reviewSnap = await reviewRef.get();
  if (!reviewSnap.exists) {
    throw new HttpsError('not-found', 'Yorum bulunamadı.');
  }
  if (reportId) {
    await assertReportMatchesReview(reportId, reviewId);
  }

  const reviewData = reviewSnap.data() ?? {};
  const reviewOwnerId = parseExistingString(reviewData.userId);
  const photoUrls = parseStringList(reviewData.imageUrls, 20);

  const batch = db.batch();
  batch.delete(reviewRef);
  if (reportId) {
    batch.update(db.collection('reports').doc(reportId), {
      status: 'actioned',
      adminNote: adminNote ?? null,
      reviewedBy: uid,
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    setAuditLog(batch, {
      actorUid: uid,
      action: 'report_status_updated',
      targetCollection: 'reports',
      targetId: reportId,
      reportId,
      status: 'actioned',
      adminNotePresent: adminNote !== undefined,
    });
  }
  if (reviewOwnerId) {
    setReviewModerationNotification(batch, reviewOwnerId, 'deleted', adminNote);
  }
  setAuditLog(batch, {
    actorUid: uid,
    action: 'review_deleted',
    targetCollection: 'reviews',
    targetId: reviewId,
    reportId,
    reviewId,
    reviewOwnerId,
    photoCount: photoUrls.length,
  });
  await batch.commit();

  await deleteStorageFiles(photoUrls, uid, reviewId);
}

async function updateFeedbackStatus(uid: string, input: AdminActionInput) {
  const feedbackId = parseId(input.feedbackId, 'feedbackId');
  const status = parseFeedbackStatus(input.status);
  const adminNote = parseOptionalString(input.adminNote, 'adminNote', 1000);

  const batch = db.batch();
  batch.update(db.collection('feedback').doc(feedbackId), {
    status,
    adminNote: adminNote ?? null,
    reviewedBy: uid,
    reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  setAuditLog(batch, {
    actorUid: uid,
    action: 'feedback_status_updated',
    targetCollection: 'feedback',
    targetId: feedbackId,
    feedbackId,
    status,
    adminNotePresent: adminNote !== undefined,
  });
  await batch.commit();
}

async function deleteFeedback(uid: string, input: AdminActionInput) {
  const feedbackId = parseId(input.feedbackId, 'feedbackId');
  const feedbackSnap = await db.collection('feedback').doc(feedbackId).get();
  if (!feedbackSnap.exists) {
    throw new HttpsError('not-found', 'Feedback bulunamadı.');
  }
  const batch = db.batch();
  batch.delete(db.collection('feedback').doc(feedbackId));
  setAuditLog(batch, {
    actorUid: uid,
    action: 'feedback_deleted',
    targetCollection: 'feedback',
    targetId: feedbackId,
    feedbackId,
  });
  await batch.commit();
}

async function assertReportMatchesReview(reportId: string, reviewId: string) {
  const reportSnap = await db.collection('reports').doc(reportId).get();
  if (!reportSnap.exists) {
    throw new HttpsError('not-found', 'Şikayet bulunamadı.');
  }
  if (reportSnap.data()?.reviewId !== reviewId) {
    throw new HttpsError(
      'failed-precondition',
      'Şikayet ve yorum eşleşmiyor.',
    );
  }
}

function setAuditLog(batch: admin.firestore.WriteBatch, log: AuditLogInput) {
  const data: Record<string, unknown> = {
    actorUid: log.actorUid,
    action: log.action,
    targetCollection: log.targetCollection,
    targetId: log.targetId,
    targetPath: `${log.targetCollection}/${log.targetId}`,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  setIfDefined(data, 'reportId', log.reportId);
  setIfDefined(data, 'reviewId', log.reviewId);
  setIfDefined(data, 'feedbackId', log.feedbackId);
  setIfDefined(data, 'reviewOwnerId', log.reviewOwnerId);
  setIfDefined(data, 'status', log.status);
  setIfDefined(data, 'adminNotePresent', log.adminNotePresent);
  setIfDefined(data, 'photoCount', log.photoCount);

  batch.set(db.collection('adminAuditLogs').doc(), data);
}

function setReviewModerationNotification(
  batch: admin.firestore.WriteBatch,
  userId: string,
  action: 'hidden' | 'deleted',
  adminNote?: string,
) {
  batch.set(db.collection('notifications').doc(), {
    userId,
    type: 'review_moderated',
    title: action === 'deleted' ? 'Yorumunuz silindi' : 'Yorumunuz gizlendi',
    body: action === 'deleted'
      ? 'Topluluk kurallarına aykırı bulunan yorumunuz kaldırıldı.'
      : 'Topluluk kurallarına aykırı bulunan yorumunuz gizlendi.',
    data: { adminNote: adminNote ?? null },
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

function parseAction(value: unknown): AdminAction {
  if (
    value === 'updateReportStatus' ||
    value === 'hideReview' ||
    value === 'unhideReview' ||
    value === 'deleteReview' ||
    value === 'updateFeedbackStatus' ||
    value === 'deleteFeedback'
  ) {
    return value;
  }
  throw new HttpsError('invalid-argument', 'Geçersiz admin aksiyonu.');
}

function parseReportStatus(value: unknown): ReportStatus {
  if (
    value === 'pending' ||
    value === 'reviewed' ||
    value === 'dismissed' ||
    value === 'actioned'
  ) {
    return value;
  }
  throw new HttpsError('invalid-argument', 'Geçersiz rapor statüsü.');
}

function parseFeedbackStatus(value: unknown): FeedbackStatus {
  if (value === 'new' || value === 'in_progress' || value === 'resolved') {
    return value;
  }
  throw new HttpsError('invalid-argument', 'Geçersiz feedback statüsü.');
}

function parseId(value: unknown, fieldName: string): string {
  const parsed = parseOptionalString(value, fieldName, 256);
  if (!parsed) {
    throw new HttpsError('invalid-argument', `${fieldName} gerekli.`);
  }
  return parsed;
}

function parseOptionalString(
  value: unknown,
  fieldName: string,
  maxLength: number,
): string | undefined {
  if (value === undefined || value === null) {
    return undefined;
  }
  if (typeof value !== 'string') {
    throw new HttpsError('invalid-argument', `${fieldName} string olmalı.`);
  }
  const trimmed = value.trim();
  if (trimmed.length > maxLength) {
    throw new HttpsError('invalid-argument', `${fieldName} çok uzun.`);
  }
  return trimmed.length === 0 ? undefined : trimmed;
}

function parseExistingString(value: unknown): string | undefined {
  return typeof value === 'string' && value.trim().length > 0
    ? value.trim()
    : undefined;
}

function parseStringList(value: unknown, maxItems: number): string[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return value
    .filter((item): item is string => typeof item === 'string')
    .slice(0, maxItems);
}

function setIfDefined(
  data: Record<string, unknown>,
  key: string,
  value: unknown,
) {
  if (value !== undefined) {
    data[key] = value;
  }
}

async function deleteStorageFiles(
  urls: string[],
  uid: string,
  reviewId: string,
) {
  for (const url of urls) {
    const target = storageFileFromUrl(url);
    if (!target) {
      logger.warn('Review photo URL could not be parsed', {
        component: LOG_COMPONENT,
        uid,
        reviewId,
      });
      continue;
    }
    try {
      await target.delete({ ignoreNotFound: true });
    } catch (err) {
      logger.warn('Review photo delete failed', {
        component: LOG_COMPONENT,
        uid,
        reviewId,
        err: String(err),
      });
    }
  }
}

function storageFileFromUrl(url: string): StorageFile | null {
  try {
    if (url.startsWith('gs://')) {
      const withoutScheme = url.slice('gs://'.length);
      const slashIndex = withoutScheme.indexOf('/');
      if (slashIndex <= 0) return null;
      const bucketName = withoutScheme.slice(0, slashIndex);
      const filePath = withoutScheme.slice(slashIndex + 1);
      return storage.bucket(bucketName).file(filePath);
    }

    const parsed = new URL(url);
    if (parsed.hostname === 'firebasestorage.googleapis.com') {
      const parts = parsed.pathname.split('/');
      const bucketIndex = parts.indexOf('b');
      const objectIndex = parts.indexOf('o');
      if (bucketIndex < 0 || objectIndex < 0 || objectIndex + 1 >= parts.length) {
        return null;
      }
      const bucketName = parts[bucketIndex + 1];
      const objectPath = decodeURIComponent(parts.slice(objectIndex + 1).join('/'));
      return storage.bucket(bucketName).file(objectPath);
    }

    if (parsed.hostname === 'storage.googleapis.com') {
      const parts = parsed.pathname.split('/').filter(Boolean);
      if (parts.length < 2) return null;
      const bucketName = parts[0];
      const objectPath = decodeURIComponent(parts.slice(1).join('/'));
      return storage.bucket(bucketName).file(objectPath);
    }
  } catch (_err) {
    return null;
  }
  return null;
}
