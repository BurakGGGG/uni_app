import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';

const db = admin.firestore();

const LOG_COMPONENT = 'abuse.userSubmissions';
const TEN_MINUTES_MS = 10 * 60 * 1000;
const REPORT_LIMIT_PER_WINDOW = 5;
const FEEDBACK_LIMIT_PER_WINDOW = 3;
const ID_RE = /^[A-Za-z0-9_-]{1,256}$/;

type ReportReason =
  | 'inappropriate'
  | 'spam'
  | 'offensive'
  | 'misleading'
  | 'other';

type FeedbackType = 'bug' | 'suggestion' | 'other';

interface SubmitReportInput {
  reviewId?: unknown;
  reason?: unknown;
  explanation?: unknown;
}

interface SubmitFeedbackInput {
  type?: unknown;
  message?: unknown;
  appVersion?: unknown;
  platform?: unknown;
}

interface RateLimitResult {
  allowed: boolean;
  currentCount: number;
  nextCount: number;
  limit: number;
  windowAgeMs: number | null;
}

export const submitReviewReport = onCall(
  {
    region: 'europe-west1',
    timeoutSeconds: 10,
    memory: '256MiB',
    cors: true,
    enforceAppCheck: true,
  },
  async (req): Promise<{ ok: true }> => {
    const uid = requireUid(req.auth?.uid);
    const input = (req.data ?? {}) as SubmitReportInput;
    const reviewId = parseId(input.reviewId, 'reviewId');
    const reason = parseReportReason(input.reason);
    const explanation = parseOptionalString(input.explanation, 'explanation', 500);

    const rate = await enforceRateLimit(
      `report_${uid}`,
      REPORT_LIMIT_PER_WINDOW,
      TEN_MINUTES_MS,
    );
    if (!rate.allowed) {
      await logSuspiciousActivity(uid, 'report_rate_limited', {
        reviewId,
        reason,
        ...rate,
        appId: req.app?.appId ?? null,
      });
      throw new HttpsError(
        'resource-exhausted',
        'Çok kısa sürede fazla şikayet gönderdiniz.',
      );
    }

    const reportId = `${reviewId}_${uid}`;
    try {
      await db.runTransaction(async (tx) => {
        const reviewRef = db.collection('reviews').doc(reviewId);
        const reportRef = db.collection('reports').doc(reportId);
        const [reviewSnap, reportSnap] = await Promise.all([
          tx.get(reviewRef),
          tx.get(reportRef),
        ]);

        if (!reviewSnap.exists) {
          throw new HttpsError('not-found', 'Yorum bulunamadı.');
        }
        const reviewData = reviewSnap.data() ?? {};
        if (reviewData.userId === uid) {
          throw new HttpsError(
            'failed-precondition',
            'Kendi yorumunuzu şikayet edemezsiniz.',
          );
        }
        if (reviewData.isApproved !== true) {
          throw new HttpsError(
            'failed-precondition',
            'Bu yorum şu anda şikayet edilemez.',
          );
        }
        if (reportSnap.exists) {
          throw new HttpsError(
            'already-exists',
            'Bu yorumu zaten şikayet ettiniz.',
          );
        }

        tx.create(reportRef, {
          reviewId,
          userId: uid,
          reason,
          explanation: explanation ?? null,
          status: 'pending',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
    } catch (err) {
      if (err instanceof HttpsError && err.code === 'already-exists') {
        await logSuspiciousActivity(uid, 'duplicate_report_attempt', {
          reviewId,
          reason,
          appId: req.app?.appId ?? null,
        });
      }
      throw err;
    }

    logger.info('Review report submitted', {
      component: LOG_COMPONENT,
      uid,
      reviewId,
      reason,
      appCheckPresent: Boolean(req.app),
    });
    return { ok: true };
  },
);

export const submitFeedback = onCall(
  {
    region: 'europe-west1',
    timeoutSeconds: 10,
    memory: '256MiB',
    cors: true,
    enforceAppCheck: true,
  },
  async (req): Promise<{ ok: true }> => {
    const uid = requireUid(req.auth?.uid);
    const input = (req.data ?? {}) as SubmitFeedbackInput;
    const type = parseFeedbackType(input.type);
    const message = parseRequiredString(input.message, 'message', 10, 1000);
    const appVersion = parseOptionalString(input.appVersion, 'appVersion', 40);
    const platform = parseOptionalString(input.platform, 'platform', 40);
    const userEmail = parseOptionalString(req.auth?.token.email, 'userEmail', 320);

    const rate = await enforceRateLimit(
      `feedback_${uid}`,
      FEEDBACK_LIMIT_PER_WINDOW,
      TEN_MINUTES_MS,
    );
    if (!rate.allowed) {
      await logSuspiciousActivity(uid, 'feedback_rate_limited', {
        type,
        ...rate,
        appId: req.app?.appId ?? null,
      });
      throw new HttpsError(
        'resource-exhausted',
        'Çok kısa sürede fazla geri bildirim gönderdiniz.',
      );
    }

    await db.collection('feedback').add({
      userId: uid,
      userEmail: userEmail ?? null,
      type,
      message,
      status: 'new',
      appVersion: appVersion ?? null,
      platform: platform ?? null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info('Feedback submitted', {
      component: LOG_COMPONENT,
      uid,
      type,
      appCheckPresent: Boolean(req.app),
    });
    return { ok: true };
  },
);

async function enforceRateLimit(
  key: string,
  limit: number,
  windowMs: number,
): Promise<RateLimitResult> {
  const ref = db.collection('submissionRateLimits').doc(key);
  const nowMs = Date.now();

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.exists ? snap.data() ?? {} : {};
    const windowStart = safeMillis(data.windowStartAt);
    const count = safeCounter(data.count);
    const windowExpired =
      windowStart <= 0 ||
      windowStart > nowMs ||
      nowMs - windowStart >= windowMs;
    const nextCount = windowExpired ? 1 : count + 1;
    const result: RateLimitResult = {
      allowed: nextCount <= limit,
      currentCount: count,
      nextCount,
      limit,
      windowAgeMs: windowStart > 0 ? nowMs - windowStart : null,
    };

    if (result.allowed) {
      tx.set(
        ref,
        {
          windowStartAt: windowExpired ? nowMs : windowStart,
          count: nextCount,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }

    return result;
  });
}

async function logSuspiciousActivity(
  uid: string,
  type: string,
  metadata: Record<string, unknown>,
) {
  await db.collection('suspiciousActivityLogs').add({
    uid,
    type,
    source: LOG_COMPONENT,
    metadata,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  logger.warn('Suspicious activity logged', {
    component: LOG_COMPONENT,
    uid,
    type,
    ...metadata,
  });
}

function requireUid(uid: string | undefined): string {
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Giriş gerekli.');
  }
  return uid;
}

function parseId(value: unknown, fieldName: string): string {
  const parsed = parseRequiredString(value, fieldName, 1, 256);
  if (!ID_RE.test(parsed)) {
    throw new HttpsError('invalid-argument', `${fieldName} formatı geçersiz.`);
  }
  return parsed;
}

function parseReportReason(value: unknown): ReportReason {
  if (
    value === 'inappropriate' ||
    value === 'spam' ||
    value === 'offensive' ||
    value === 'misleading' ||
    value === 'other'
  ) {
    return value;
  }
  throw new HttpsError('invalid-argument', 'Geçersiz şikayet nedeni.');
}

function parseFeedbackType(value: unknown): FeedbackType {
  if (value === 'bug' || value === 'suggestion' || value === 'other') {
    return value;
  }
  throw new HttpsError('invalid-argument', 'Geçersiz feedback türü.');
}

function parseRequiredString(
  value: unknown,
  fieldName: string,
  minLength: number,
  maxLength: number,
): string {
  if (typeof value !== 'string') {
    throw new HttpsError('invalid-argument', `${fieldName} string olmalı.`);
  }
  const trimmed = value.trim();
  if (trimmed.length < minLength || trimmed.length > maxLength) {
    throw new HttpsError('invalid-argument', `${fieldName} uzunluğu geçersiz.`);
  }
  return trimmed;
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

function safeCounter(value: unknown): number {
  const n = Number(value);
  if (!Number.isFinite(n) || n < 0) return 0;
  return Math.floor(n);
}

function safeMillis(value: unknown): number {
  const n = Number(value);
  if (!Number.isFinite(n) || n < 0) return 0;
  return Math.floor(n);
}
