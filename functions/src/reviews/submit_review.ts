import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';

const db = admin.firestore();

const LOG_COMPONENT = 'reviews.submitReview';
const TEN_MINUTES_MS = 10 * 60 * 1000;
const REVIEW_LIMIT_PER_WINDOW = 3;
const ID_RE = /^[A-Za-z0-9_-]{1,256}$/;
const CATEGORY_KEY_RE = /^[\p{L}\p{N} _.-]{1,80}$/u;

type ReviewType = 'university' | 'department' | 'place';

interface SubmitReviewInput {
  type?: unknown;
  targetId?: unknown;
  universityId?: unknown;
  rating?: unknown;
  categoryRatings?: unknown;
  comment?: unknown;
  pros?: unknown;
  cons?: unknown;
  imageUrls?: unknown;
  isAnonymous?: unknown;
}

interface RateLimitResult {
  allowed: boolean;
  currentCount: number;
  nextCount: number;
  limit: number;
  windowAgeMs: number | null;
}

interface ReviewSubmissionStatus {
  allowed: boolean;
  currentCount: number;
  remaining: number;
  limit: number;
  retryAfterSeconds: number;
  windowAgeMs: number | null;
}

export const getReviewSubmissionStatus = onCall(
  {
    region: 'europe-west1',
    timeoutSeconds: 10,
    memory: '256MiB',
    cors: true,
    enforceAppCheck: true,
  },
  async (req): Promise<ReviewSubmissionStatus> => {
    const uid = requireUid(req.auth?.uid);
    const email = String(req.auth?.token.email ?? '').toLowerCase();
    const emailVerified = req.auth?.token.email_verified === true;
    if (!emailVerified || !email.endsWith('.edu.tr')) {
      throw new HttpsError(
        'failed-precondition',
        'Doğrulanmış edu.tr e-posta gerekli.',
      );
    }

    return getRateLimitStatus(
      `review_create_${uid}`,
      REVIEW_LIMIT_PER_WINDOW,
      TEN_MINUTES_MS,
    );
  },
);

export const submitReview = onCall(
  {
    region: 'europe-west1',
    timeoutSeconds: 10,
    memory: '256MiB',
    cors: true,
    enforceAppCheck: true,
  },
  async (req): Promise<{ ok: true; reviewId: string }> => {
    const uid = requireUid(req.auth?.uid);
    const email = String(req.auth?.token.email ?? '').toLowerCase();
    const emailVerified = req.auth?.token.email_verified === true;
    if (!emailVerified || !email.endsWith('.edu.tr')) {
      throw new HttpsError(
        'failed-precondition',
        'Doğrulanmış edu.tr e-posta gerekli.',
      );
    }

    const input = (req.data ?? {}) as SubmitReviewInput;
    const type = parseReviewType(input.type);
    const targetId = parseId(input.targetId, 'targetId');
    const universityId = parseId(input.universityId, 'universityId');
    const rating = parseRating(input.rating);
    const categoryRatings = parseCategoryRatings(input.categoryRatings);
    const comment = parseRequiredString(input.comment, 'comment', 20, 500);
    const pros = parseStringList(input.pros, 'pros', 10, 80);
    const cons = parseStringList(input.cons, 'cons', 10, 80);
    const imageUrls = parseImageUrls(input.imageUrls, uid);
    const isAnonymous = parseBool(input.isAnonymous, 'isAnonymous');

    if (type === 'university' && targetId !== universityId) {
      throw new HttpsError(
        'invalid-argument',
        'Üniversite yorumu hedefi universityId ile aynı olmalı.',
      );
    }

    const profileSnap = await db.collection('users').doc(uid).get();
    if (!profileSnap.exists) {
      throw new HttpsError('failed-precondition', 'Kullanıcı profili bulunamadı.');
    }
    const profile = profileSnap.data() ?? {};
    if (profile.universityId !== universityId) {
      throw new HttpsError(
        'failed-precondition',
        'Yalnızca kendi üniversiteniz için yorum gönderebilirsiniz.',
      );
    }

    const rate = await enforceRateLimit(
      `review_create_${uid}`,
      REVIEW_LIMIT_PER_WINDOW,
      TEN_MINUTES_MS,
    );
    if (!rate.allowed) {
      await logSuspiciousActivity(uid, 'review_create_rate_limited', {
        type,
        targetId,
        universityId,
        ...rate,
        appId: req.app?.appId ?? null,
      });
      throw new HttpsError(
        'resource-exhausted',
        'Çok kısa sürede fazla yorum gönderdiniz.',
      );
    }

    const displayName = parseProfileString(profile.displayName, 'displayName', 120);
    const photoUrl = parseOptionalProfileString(profile.photoUrl, 'photoUrl', 2048);
    const userUniversity = parseOptionalProfileString(
      profile.university,
      'university',
      160,
    );
    const reviewRef = db.collection('reviews').doc();

    await reviewRef.create({
      type,
      targetId,
      universityId,
      userId: uid,
      userName: isAnonymous ? 'Anonim Öğrenci' : displayName,
      userPhotoUrl: isAnonymous ? null : photoUrl,
      userUniversity: userUniversity ?? null,
      rating,
      categoryRatings,
      comment,
      pros,
      cons,
      imageUrls,
      likes: 0,
      isAnonymous,
      isApproved: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info('Review submitted', {
      component: LOG_COMPONENT,
      uid,
      reviewId: reviewRef.id,
      type,
      targetId,
      universityId,
      appCheckPresent: Boolean(req.app),
    });

    return { ok: true, reviewId: reviewRef.id };
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

async function getRateLimitStatus(
  key: string,
  limit: number,
  windowMs: number,
): Promise<ReviewSubmissionStatus> {
  const ref = db.collection('submissionRateLimits').doc(key);
  const nowMs = Date.now();
  const snap = await ref.get();
  const data = snap.exists ? snap.data() ?? {} : {};
  const windowStart = safeMillis(data.windowStartAt);
  const count = safeCounter(data.count);
  const windowExpired =
    windowStart <= 0 || windowStart > nowMs || nowMs - windowStart >= windowMs;
  const currentCount = windowExpired ? 0 : count;
  const remaining = Math.max(0, limit - currentCount);
  const windowAgeMs = windowStart > 0 ? nowMs - windowStart : null;
  const retryAfterMs =
    remaining > 0 || windowExpired ? 0 : Math.max(0, windowMs - (windowAgeMs ?? 0));

  return {
    allowed: remaining > 0,
    currentCount,
    remaining,
    limit,
    retryAfterSeconds: Math.ceil(retryAfterMs / 1000),
    windowAgeMs,
  };
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

function parseReviewType(value: unknown): ReviewType {
  if (value === 'university' || value === 'department' || value === 'place') {
    return value;
  }
  throw new HttpsError('invalid-argument', 'Geçersiz yorum türü.');
}

function parseId(value: unknown, fieldName: string): string {
  const parsed = parseRequiredString(value, fieldName, 1, 256);
  if (!ID_RE.test(parsed)) {
    throw new HttpsError('invalid-argument', `${fieldName} formatı geçersiz.`);
  }
  return parsed;
}

function parseRating(value: unknown): number {
  const rating = Number(value);
  if (!Number.isFinite(rating) || rating < 1 || rating > 5) {
    throw new HttpsError('invalid-argument', 'Puan 1 ile 5 arasında olmalı.');
  }
  return rating;
}

function parseCategoryRatings(value: unknown): Record<string, number> {
  if (!isRecord(value)) {
    throw new HttpsError('invalid-argument', 'Kategori puanları map olmalı.');
  }
  const entries = Object.entries(value);
  if (entries.length > 12) {
    throw new HttpsError('invalid-argument', 'Çok fazla kategori puanı.');
  }
  const parsed: Record<string, number> = {};
  for (const [key, raw] of entries) {
    const categoryKey = key.trim();
    if (!CATEGORY_KEY_RE.test(categoryKey)) {
      throw new HttpsError('invalid-argument', 'Kategori anahtarı geçersiz.');
    }
    const rating = parseRating(raw);
    parsed[categoryKey] = rating;
  }
  return parsed;
}

function parseImageUrls(value: unknown, uid: string): string[] {
  const urls = parseStringList(value, 'imageUrls', 3, 2048);
  for (const url of urls) {
    if (!isValidReviewImageUrl(url, uid)) {
      throw new HttpsError('invalid-argument', 'Görsel URL formatı geçersiz.');
    }
  }
  return urls;
}

function isValidReviewImageUrl(url: string, uid: string): boolean {
  if (!url.startsWith('https://')) return false;

  try {
    const parsed = new URL(url);
    if (parsed.hostname === 'firebasestorage.googleapis.com') {
      const parts = parsed.pathname.split('/');
      const objectIndex = parts.indexOf('o');
      if (objectIndex < 0 || objectIndex + 1 >= parts.length) return false;
      const objectPath = decodeURIComponent(parts.slice(objectIndex + 1).join('/'));
      return isValidReviewImagePath(objectPath, uid);
    }

    if (parsed.hostname === 'storage.googleapis.com') {
      const parts = parsed.pathname.split('/').filter(Boolean);
      if (parts.length < 2) return false;
      const objectPath = decodeURIComponent(parts.slice(1).join('/'));
      return isValidReviewImagePath(objectPath, uid);
    }
  } catch (_err) {
    return false;
  }

  return false;
}

function isValidReviewImagePath(objectPath: string, uid: string): boolean {
  const prefix = `review_images/${uid}/`;
  if (!objectPath.startsWith(prefix)) return false;

  const fileName = objectPath.slice(prefix.length);
  return /^[A-Za-z0-9_-]+\.jpg$/.test(fileName);
}

function parseStringList(
  value: unknown,
  fieldName: string,
  maxItems: number,
  maxItemLength: number,
): string[] {
  if (!Array.isArray(value)) {
    throw new HttpsError('invalid-argument', `${fieldName} liste olmalı.`);
  }
  if (value.length > maxItems) {
    throw new HttpsError('invalid-argument', `${fieldName} çok uzun.`);
  }
  return value.map((item) => {
    if (typeof item !== 'string') {
      throw new HttpsError('invalid-argument', `${fieldName} string içermeli.`);
    }
    const trimmed = item.trim();
    if (trimmed.length === 0 || trimmed.length > maxItemLength) {
      throw new HttpsError('invalid-argument', `${fieldName} elemanı çok uzun.`);
    }
    return trimmed;
  });
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

function parseBool(value: unknown, fieldName: string): boolean {
  if (typeof value !== 'boolean') {
    throw new HttpsError('invalid-argument', `${fieldName} bool olmalı.`);
  }
  return value;
}

function parseProfileString(
  value: unknown,
  fieldName: string,
  maxLength: number,
): string {
  if (typeof value !== 'string') {
    throw new HttpsError('failed-precondition', `${fieldName} eksik.`);
  }
  const trimmed = value.trim();
  if (trimmed.length === 0 || trimmed.length > maxLength) {
    throw new HttpsError('failed-precondition', `${fieldName} geçersiz.`);
  }
  return trimmed;
}

function parseOptionalProfileString(
  value: unknown,
  fieldName: string,
  maxLength: number,
): string | null {
  if (value === undefined || value === null) return null;
  if (typeof value !== 'string') {
    throw new HttpsError('failed-precondition', `${fieldName} geçersiz.`);
  }
  const trimmed = value.trim();
  if (trimmed.length > maxLength) {
    throw new HttpsError('failed-precondition', `${fieldName} çok uzun.`);
  }
  return trimmed.length === 0 ? null : trimmed;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
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
