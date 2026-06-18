import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';

const db = admin.firestore();
const storage = admin.storage();

const LOG_COMPONENT = 'places.placeSuggestions';
const TEN_MINUTES_MS = 10 * 60 * 1000;
const SUGGESTION_LIMIT_PER_WINDOW = 3;
const DUPLICATE_CHECK_LIMIT_PER_WINDOW = 20;
const MAX_PHOTO_COUNT = 5;
const MAX_PHOTO_SIZE_BYTES = 10 * 1024 * 1024;
const ID_RE = /^[A-Za-z0-9_-]{1,256}$/;
const PHOTO_NAME_RE = /^photo_[0-4]\.(jpg|jpeg|png|webp)$/;
const ALLOWED_PHOTO_CONTENT_TYPES = [
  'image/jpeg',
  'image/png',
  'image/webp',
];
const ALLOWED_PRICE_RANGES = ['₺', '₺₺', '₺₺₺'];

type PlaceType = 'cafe' | 'dorm' | 'study_area' | 'library' | 'sports';
type PlaceSuggestionAction = 'approve' | 'reject';

interface SubmitPlaceSuggestionInput {
  suggestionId?: unknown;
  universityId?: unknown;
  name?: unknown;
  type?: unknown;
  description?: unknown;
  address?: unknown;
  photoUrls?: unknown;
  latitude?: unknown;
  longitude?: unknown;
  priceRange?: unknown;
  openHours?: unknown;
  phone?: unknown;
  amenities?: unknown;
}

interface PlaceSuggestionActionInput {
  action?: unknown;
  suggestionId?: unknown;
  adminNote?: unknown;
  approvedPlace?: unknown;
}

interface PlaceDetails {
  name: string;
  type: PlaceType;
  description: string;
  address: string;
  latitude: number | null;
  longitude: number | null;
  priceRange: string | null;
  openHours: string | null;
  phone: string | null;
  amenities: string[];
}

interface RateLimitResult {
  allowed: boolean;
  currentCount: number;
  nextCount: number;
  limit: number;
  windowAgeMs: number | null;
}

interface ParsedStorageUrl {
  bucketName: string;
  filePath: string;
}

interface DuplicateCheckInput {
  universityId?: unknown;
  name?: unknown;
  type?: unknown;
  latitude?: unknown;
  longitude?: unknown;
  excludeSuggestionId?: unknown;
}

interface DuplicateSearchInput {
  universityId: string;
  name: string;
  type: PlaceType;
  latitude: number | null;
  longitude: number | null;
  excludeSuggestionId?: string;
}

interface DuplicateCandidate {
  id: string;
  name: string;
  type: string;
  address: string;
  source: 'place' | 'suggestion';
  status: string;
  similarity: number;
  distanceMeters: number | null;
}

export const submitPlaceSuggestion = onCall(
  {
    region: 'europe-west1',
    timeoutSeconds: 30,
    memory: '256MiB',
    cors: true,
    enforceAppCheck: true,
  },
  async (req): Promise<{ ok: true; suggestionId: string }> => {
    const uid = requireUid(req.auth?.uid);
    const input = (req.data ?? {}) as SubmitPlaceSuggestionInput;
    const suggestionId = parseId(input.suggestionId, 'suggestionId');
    const universityId = parseId(input.universityId, 'universityId');
    const name = parseRequiredString(input.name, 'name', 2, 100);
    const type = parsePlaceType(input.type);
    const description = parseOptionalString(
      input.description,
      'description',
      500,
    );
    const address = parseOptionalString(input.address, 'address', 300);
    const location = parseOptionalLocation(input.latitude, input.longitude);
    const priceRange = parseOptionalPriceRange(input.priceRange);
    const openHours = parseOptionalString(input.openHours, 'openHours', 120);
    const phone = parseOptionalPhone(input.phone);
    const amenities = parseStringList(
      input.amenities,
      'amenities',
      12,
      60,
    );

    const rate = await enforceRateLimit(
      `place_suggestion_${uid}`,
      SUGGESTION_LIMIT_PER_WINDOW,
      TEN_MINUTES_MS,
    );
    if (!rate.allowed) {
      await logSuspiciousActivity(uid, 'place_suggestion_rate_limited', {
        suggestionId,
        universityId,
        type,
        ...rate,
        appId: req.app?.appId ?? null,
      });
      throw new HttpsError(
        'resource-exhausted',
        'Çok kısa sürede fazla mekan önerisi gönderdiniz.',
      );
    }

    const photoUrls = await parseAndValidatePhotoUrls(
      input.photoUrls,
      uid,
      suggestionId,
    );
    const [universitySnap, profileSnap] = await Promise.all([
      db.collection('universities').doc(universityId).get(),
      db.collection('users').doc(uid).get(),
    ]);

    if (!universitySnap.exists) {
      throw new HttpsError('not-found', 'Üniversite bulunamadı.');
    }
    if (!profileSnap.exists) {
      throw new HttpsError(
        'failed-precondition',
        'Kullanıcı profili bulunamadı.',
      );
    }

    const universityName = parseStoredRequiredString(
      universitySnap.data()?.name,
      'universityName',
      160,
    );
    const profile = profileSnap.data() ?? {};
    const userName = resolveUserName(
      profile.displayName,
      req.auth?.token.name,
      req.auth?.token.email,
    );
    const duplicates = await findDuplicateCandidates({
      universityId,
      name,
      type,
      latitude: location.latitude,
      longitude: location.longitude,
      excludeSuggestionId: suggestionId,
    });
    const suggestionRef = db
      .collection('place_suggestions')
      .doc(suggestionId);

    await db.runTransaction(async (tx) => {
      const existing = await tx.get(suggestionRef);
      if (existing.exists) {
        throw new HttpsError(
          'already-exists',
          'Bu mekan önerisi zaten gönderilmiş.',
        );
      }

      tx.create(suggestionRef, {
        universityId,
        universityName,
        userId: uid,
        userName,
        name,
        type,
        description: description ?? '',
        address: address ?? '',
        photoUrls,
        latitude: location.latitude,
        longitude: location.longitude,
        priceRange: priceRange ?? null,
        openHours: openHours ?? null,
        phone: phone ?? null,
        amenities,
        duplicateRiskCount: duplicates.length,
        duplicateCandidateIds: duplicates.map((item) => item.id),
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    logger.info('Place suggestion submitted', {
      component: LOG_COMPONENT,
      uid,
      suggestionId,
      universityId,
      type,
      photoCount: photoUrls.length,
      duplicateRiskCount: duplicates.length,
      appCheckPresent: Boolean(req.app),
    });

    return { ok: true, suggestionId };
  },
);

export const checkPlaceSuggestionDuplicates = onCall(
  {
    region: 'europe-west1',
    timeoutSeconds: 15,
    memory: '256MiB',
    cors: true,
    enforceAppCheck: true,
  },
  async (req): Promise<{ candidates: DuplicateCandidate[] }> => {
    const uid = requireUid(req.auth?.uid);
    const input = (req.data ?? {}) as DuplicateCheckInput;
    const universityId = parseId(input.universityId, 'universityId');
    const name = parseRequiredString(input.name, 'name', 2, 100);
    const type = parsePlaceType(input.type);
    const location = parseOptionalLocation(input.latitude, input.longitude);
    const excludeSuggestionId = input.excludeSuggestionId == null
      ? undefined
      : parseId(input.excludeSuggestionId, 'excludeSuggestionId');

    const rate = await enforceRateLimit(
      `place_duplicate_check_${uid}`,
      DUPLICATE_CHECK_LIMIT_PER_WINDOW,
      TEN_MINUTES_MS,
    );
    if (!rate.allowed) {
      await logSuspiciousActivity(uid, 'place_duplicate_check_rate_limited', {
        universityId,
        ...rate,
        appId: req.app?.appId ?? null,
      });
      throw new HttpsError(
        'resource-exhausted',
        'Çok kısa sürede fazla benzer mekan kontrolü yaptınız.',
      );
    }

    const candidates = await findDuplicateCandidates({
      universityId,
      name,
      type,
      latitude: location.latitude,
      longitude: location.longitude,
      excludeSuggestionId,
    });

    logger.info('Place duplicate check completed', {
      component: LOG_COMPONENT,
      uid,
      universityId,
      candidateCount: candidates.length,
      appCheckPresent: Boolean(req.app),
    });
    return { candidates };
  },
);

export const performPlaceSuggestionAction = onCall(
  {
    region: 'europe-west1',
    timeoutSeconds: 30,
    memory: '256MiB',
    cors: true,
    enforceAppCheck: true,
  },
  async (req): Promise<{ ok: true; placeId?: string }> => {
    const input = (req.data ?? {}) as PlaceSuggestionActionInput;

    if (!req.auth) {
      await logSuspiciousActivity('anonymous', 'failed_admin_callable_access', {
        reason: 'unauthenticated',
        requestedAction: safeMetadataString(input.action),
        appCheckPresent: Boolean(req.app),
        appId: req.app?.appId ?? null,
      });
      throw new HttpsError('unauthenticated', 'Giriş gerekli.');
    }

    const uid = req.auth.uid;
    if (req.auth.token.admin !== true) {
      await logSuspiciousActivity(uid, 'failed_admin_callable_access', {
        reason: 'missing_admin_claim',
        requestedAction: safeMetadataString(input.action),
        appCheckPresent: Boolean(req.app),
        appId: req.app?.appId ?? null,
        email: safeMetadataString(req.auth.token.email),
      });
      throw new HttpsError('permission-denied', 'Admin yetkisi gerekli.');
    }

    const action = parseAction(input.action);
    const suggestionId = parseId(input.suggestionId, 'suggestionId');
    const adminNote = parseOptionalString(
      input.adminNote,
      'adminNote',
      1000,
    );
    const suggestionRef = db
      .collection('place_suggestions')
      .doc(suggestionId);

    const result = await db.runTransaction(async (tx) => {
      const suggestionSnap = await tx.get(suggestionRef);
      if (!suggestionSnap.exists) {
        throw new HttpsError('not-found', 'Mekan önerisi bulunamadı.');
      }

      const suggestion = suggestionSnap.data() ?? {};
      if (suggestion.status !== 'pending') {
        throw new HttpsError(
          'failed-precondition',
          'Bu mekan önerisi daha önce işlenmiş.',
        );
      }

      const commonUpdate = {
        status: action === 'approve' ? 'approved' : 'rejected',
        adminNote: adminNote ?? null,
        reviewedBy: uid,
        reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      const auditRef = db.collection('adminAuditLogs').doc();

      if (action === 'reject') {
        tx.update(suggestionRef, commonUpdate);
        tx.create(auditRef, {
          actorUid: uid,
          action: 'place_suggestion_rejected',
          targetCollection: 'place_suggestions',
          targetId: suggestionId,
          targetPath: `place_suggestions/${suggestionId}`,
          status: 'rejected',
          adminNotePresent: adminNote !== undefined,
          photoCount: safeStoredPhotoCount(suggestion.photoUrls),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return {};
      }

      const universityId = parseStoredId(
        suggestion.universityId,
        'universityId',
      );
      const originalDetails = parseStoredPlaceDetails(suggestion);
      const approvedDetails = parseApprovedPlaceDetails(
        input.approvedPlace,
        originalDetails,
      );
      const photoUrls = parseStoredPhotoUrls(suggestion.photoUrls);
      const ownerId = parseStoredId(suggestion.userId, 'userId');
      const placeRef = db.collection('places').doc();
      const changedFields = changedPlaceFields(
        originalDetails,
        approvedDetails,
      );

      tx.create(placeRef, {
        universityId,
        name: approvedDetails.name,
        type: approvedDetails.type,
        description: approvedDetails.description,
        imageUrls: photoUrls,
        address: approvedDetails.address,
        mapUrl: approvedDetails.latitude != null
          ? googleMapsUrl(
            approvedDetails.latitude,
            approvedDetails.longitude!,
          )
          : null,
        location: approvedDetails.latitude != null
          ? new admin.firestore.GeoPoint(
            approvedDetails.latitude,
            approvedDetails.longitude!,
          )
          : null,
        priceRange: approvedDetails.priceRange,
        openHours: approvedDetails.openHours,
        phone: approvedDetails.phone,
        amenities: approvedDetails.amenities,
        avgRating: 0,
        reviewCount: 0,
        categoryRatings: {},
        isPromoted: false,
        promotionPriority: 0,
        sourceSuggestionId: suggestionId,
        suggestedByUserId: ownerId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      tx.update(suggestionRef, {
        ...commonUpdate,
        placeId: placeRef.id,
        approvedPlace: approvedDetails,
        changedFields,
      });
      tx.create(auditRef, {
        actorUid: uid,
        action: 'place_suggestion_approved',
        targetCollection: 'place_suggestions',
        targetId: suggestionId,
        targetPath: `place_suggestions/${suggestionId}`,
        status: 'approved',
        placeId: placeRef.id,
        adminNotePresent: adminNote !== undefined,
        photoCount: photoUrls.length,
        changedFields,
        approvedSnapshot: approvedDetails,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { placeId: placeRef.id };
    });

    logger.info('Place suggestion action accepted', {
      component: LOG_COMPONENT,
      uid,
      action,
      suggestionId,
      placeId: result.placeId ?? null,
      appCheckPresent: Boolean(req.app),
    });

    return {
      ok: true,
      ...result,
    };
  },
);

async function parseAndValidatePhotoUrls(
  value: unknown,
  uid: string,
  suggestionId: string,
): Promise<string[]> {
  const urls = parsePhotoUrls(value);
  const expectedBucketName = storage.bucket().name;

  for (const url of urls) {
    const parsed = parseStorageUrl(url);
    if (
      !parsed ||
      parsed.bucketName !== expectedBucketName ||
      !isValidPhotoPath(parsed.filePath, uid, suggestionId)
    ) {
      throw new HttpsError(
        'invalid-argument',
        'Mekan fotoğrafı URL formatı geçersiz.',
      );
    }

    try {
      const [metadata] = await storage
        .bucket(parsed.bucketName)
        .file(parsed.filePath)
        .getMetadata();
      const size = Number(metadata.size ?? 0);
      const contentType = String(metadata.contentType ?? '');
      if (
        !Number.isFinite(size) ||
        size <= 0 ||
        size > MAX_PHOTO_SIZE_BYTES ||
        !ALLOWED_PHOTO_CONTENT_TYPES.includes(contentType)
      ) {
        throw new HttpsError(
          'invalid-argument',
          'Mekan fotoğrafı türü veya boyutu geçersiz.',
        );
      }
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      throw new HttpsError(
        'failed-precondition',
        'Yüklenen mekan fotoğrafı doğrulanamadı.',
      );
    }
  }

  return urls;
}

function parsePhotoUrls(value: unknown): string[] {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value)) {
    throw new HttpsError('invalid-argument', 'photoUrls liste olmalı.');
  }
  if (value.length > MAX_PHOTO_COUNT) {
    throw new HttpsError(
      'invalid-argument',
      `En fazla ${MAX_PHOTO_COUNT} fotoğraf gönderilebilir.`,
    );
  }

  const urls = value.map((item) =>
    parseRequiredString(item, 'photoUrl', 1, 2048),
  );
  if (new Set(urls).size !== urls.length) {
    throw new HttpsError('invalid-argument', 'Tekrarlı fotoğraf URLsi var.');
  }
  return urls;
}

function parseStorageUrl(url: string): ParsedStorageUrl | null {
  try {
    if (url.startsWith('gs://')) {
      const withoutScheme = url.slice('gs://'.length);
      const slashIndex = withoutScheme.indexOf('/');
      if (slashIndex <= 0) return null;
      return {
        bucketName: withoutScheme.slice(0, slashIndex),
        filePath: withoutScheme.slice(slashIndex + 1),
      };
    }

    const parsed = new URL(url);
    if (parsed.hostname === 'firebasestorage.googleapis.com') {
      const parts = parsed.pathname.split('/');
      const bucketIndex = parts.indexOf('b');
      const objectIndex = parts.indexOf('o');
      if (
        bucketIndex < 0 ||
        objectIndex < 0 ||
        objectIndex + 1 >= parts.length
      ) {
        return null;
      }
      return {
        bucketName: parts[bucketIndex + 1],
        filePath: decodeURIComponent(parts.slice(objectIndex + 1).join('/')),
      };
    }

    if (parsed.hostname === 'storage.googleapis.com') {
      const parts = parsed.pathname.split('/').filter(Boolean);
      if (parts.length < 2) return null;
      return {
        bucketName: parts[0],
        filePath: decodeURIComponent(parts.slice(1).join('/')),
      };
    }
  } catch (_err) {
    return null;
  }
  return null;
}

function isValidPhotoPath(
  filePath: string,
  uid: string,
  suggestionId: string,
): boolean {
  const prefix = `place_suggestions/${uid}/${suggestionId}/`;
  if (!filePath.startsWith(prefix)) return false;
  return PHOTO_NAME_RE.test(filePath.slice(prefix.length));
}

async function findDuplicateCandidates(
  input: DuplicateSearchInput,
): Promise<DuplicateCandidate[]> {
  const [placesSnap, suggestionsSnap] = await Promise.all([
    db.collection('places')
      .where('universityId', '==', input.universityId)
      .limit(100)
      .get(),
    db.collection('place_suggestions')
      .where('universityId', '==', input.universityId)
      .limit(100)
      .get(),
  ]);

  const candidates: DuplicateCandidate[] = [];
  for (const doc of placesSnap.docs) {
    const candidate = duplicateCandidateFromData(
      doc.id,
      doc.data(),
      'place',
      'approved',
      input,
    );
    if (candidate) candidates.push(candidate);
  }
  for (const doc of suggestionsSnap.docs) {
    if (doc.id === input.excludeSuggestionId) continue;
    const data = doc.data();
    const status = typeof data.status === 'string' ? data.status : 'pending';
    if (status === 'rejected') continue;
    const candidate = duplicateCandidateFromData(
      doc.id,
      data,
      'suggestion',
      status,
      input,
    );
    if (candidate) candidates.push(candidate);
  }

  return candidates
    .sort((a, b) => duplicateRank(b) - duplicateRank(a))
    .slice(0, 5);
}

function duplicateCandidateFromData(
  id: string,
  data: Record<string, unknown>,
  source: 'place' | 'suggestion',
  status: string,
  input: DuplicateSearchInput,
): DuplicateCandidate | null {
  const name = safeMetadataString(data.name, 100);
  if (!name) return null;
  const type = safeMetadataString(data.type, 40) ?? '';
  const similarity = nameSimilarity(input.name, name);
  const latitude = coordinateFromData(data, 'latitude');
  const longitude = coordinateFromData(data, 'longitude');
  const distanceMeters =
    input.latitude != null &&
    input.longitude != null &&
    latitude != null &&
    longitude != null
      ? haversineMeters(
        input.latitude,
        input.longitude,
        latitude,
        longitude,
      )
      : null;
  const sameType = type === input.type;
  const looksSimilar =
    similarity >= 0.58 ||
    (sameType && distanceMeters != null && distanceMeters <= 250);
  if (!looksSimilar) return null;

  return {
    id,
    name,
    type,
    address: safeMetadataString(data.address, 300) ?? '',
    source,
    status,
    similarity: Number(similarity.toFixed(3)),
    distanceMeters: distanceMeters == null
      ? null
      : Math.round(distanceMeters),
  };
}

function duplicateRank(candidate: DuplicateCandidate): number {
  const distanceBonus = candidate.distanceMeters == null
    ? 0
    : Math.max(0, 1 - candidate.distanceMeters / 1000);
  return candidate.similarity * 2 + distanceBonus;
}

function nameSimilarity(left: string, right: string): number {
  const a = normalizeName(left);
  const b = normalizeName(right);
  if (a === b) return 1;
  if (a.length < 2 || b.length < 2) return a === b ? 1 : 0;
  const aBigrams = bigrams(a);
  const bBigrams = bigrams(b);
  let intersection = 0;
  const remaining = new Map<string, number>();
  for (const item of bBigrams) {
    remaining.set(item, (remaining.get(item) ?? 0) + 1);
  }
  for (const item of aBigrams) {
    const count = remaining.get(item) ?? 0;
    if (count <= 0) continue;
    intersection++;
    remaining.set(item, count - 1);
  }
  return (2 * intersection) / (aBigrams.length + bBigrams.length);
}

function normalizeName(value: string): string {
  return value
    .toLocaleLowerCase('tr-TR')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9çğıöşü]+/g, ' ')
    .trim();
}

function bigrams(value: string): string[] {
  const compact = value.replace(/\s+/g, '');
  const result: string[] = [];
  for (let i = 0; i < compact.length - 1; i++) {
    result.push(compact.slice(i, i + 2));
  }
  return result;
}

function coordinateFromData(
  data: Record<string, unknown>,
  key: 'latitude' | 'longitude',
): number | null {
  const raw = data[key];
  if (raw !== undefined && raw !== null) {
    const direct = Number(raw);
    if (Number.isFinite(direct)) return direct;
  }
  const location = data.location;
  if (location instanceof admin.firestore.GeoPoint) {
    return key === 'latitude' ? location.latitude : location.longitude;
  }
  return null;
}

function haversineMeters(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const radius = 6371000;
  const toRadians = (degree: number) => degree * Math.PI / 180;
  const dLat = toRadians(lat2 - lat1);
  const dLng = toRadians(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(lat1)) *
    Math.cos(toRadians(lat2)) *
    Math.sin(dLng / 2) ** 2;
  return radius * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

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

function parseAction(value: unknown): PlaceSuggestionAction {
  if (value === 'approve' || value === 'reject') return value;
  throw new HttpsError('invalid-argument', 'Geçersiz admin aksiyonu.');
}

function parsePlaceType(value: unknown): PlaceType {
  if (
    value === 'cafe' ||
    value === 'dorm' ||
    value === 'study_area' ||
    value === 'library' ||
    value === 'sports'
  ) {
    return value;
  }
  throw new HttpsError('invalid-argument', 'Geçersiz mekan türü.');
}

function parseOptionalLocation(
  latitudeValue: unknown,
  longitudeValue: unknown,
): { latitude: number | null; longitude: number | null } {
  const latitudeMissing = latitudeValue === undefined || latitudeValue === null;
  const longitudeMissing =
    longitudeValue === undefined || longitudeValue === null;
  if (latitudeMissing && longitudeMissing) {
    return { latitude: null, longitude: null };
  }
  if (latitudeMissing || longitudeMissing) {
    throw new HttpsError(
      'invalid-argument',
      'Enlem ve boylam birlikte gönderilmeli.',
    );
  }

  const latitude = Number(latitudeValue);
  const longitude = Number(longitudeValue);
  if (
    !Number.isFinite(latitude) ||
    !Number.isFinite(longitude) ||
    latitude < -90 ||
    latitude > 90 ||
    longitude < -180 ||
    longitude > 180
  ) {
    throw new HttpsError('invalid-argument', 'Konum koordinatları geçersiz.');
  }
  return { latitude, longitude };
}

function parseOptionalPriceRange(value: unknown): string | undefined {
  const parsed = parseOptionalString(value, 'priceRange', 10);
  if (parsed === undefined) return undefined;
  if (!ALLOWED_PRICE_RANGES.includes(parsed)) {
    throw new HttpsError('invalid-argument', 'Fiyat aralığı geçersiz.');
  }
  return parsed;
}

function parseOptionalPhone(value: unknown): string | undefined {
  const parsed = parseOptionalString(value, 'phone', 11);
  if (parsed === undefined) return undefined;
  if (!/^[0-9]{10,11}$/.test(parsed)) {
    throw new HttpsError(
      'invalid-argument',
      'Telefon yalnızca 10 veya 11 rakamdan oluşmalı.',
    );
  }
  return parsed;
}

function parseStringList(
  value: unknown,
  fieldName: string,
  maxItems: number,
  maxItemLength: number,
): string[] {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value) || value.length > maxItems) {
    throw new HttpsError('invalid-argument', `${fieldName} liste sınırı aşıldı.`);
  }
  const result = value.map((item) =>
    parseRequiredString(item, fieldName, 1, maxItemLength),
  );
  return [...new Set(result)];
}

function parseId(value: unknown, fieldName: string): string {
  const parsed = parseRequiredString(value, fieldName, 1, 256);
  if (!ID_RE.test(parsed)) {
    throw new HttpsError('invalid-argument', `${fieldName} formatı geçersiz.`);
  }
  return parsed;
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
  if (value === undefined || value === null) return undefined;
  if (typeof value !== 'string') {
    throw new HttpsError('invalid-argument', `${fieldName} string olmalı.`);
  }
  const trimmed = value.trim();
  if (trimmed.length > maxLength) {
    throw new HttpsError('invalid-argument', `${fieldName} çok uzun.`);
  }
  return trimmed.length === 0 ? undefined : trimmed;
}

function parseStoredId(value: unknown, fieldName: string): string {
  if (typeof value !== 'string') {
    throw new HttpsError('failed-precondition', `${fieldName} eksik.`);
  }
  const trimmed = value.trim();
  if (!ID_RE.test(trimmed)) {
    throw new HttpsError('failed-precondition', `${fieldName} geçersiz.`);
  }
  return trimmed;
}

function parseStoredPlaceType(value: unknown): PlaceType {
  try {
    return parsePlaceType(value);
  } catch (_err) {
    throw new HttpsError(
      'failed-precondition',
      'Kayıtlı mekan türü geçersiz.',
    );
  }
}

function parseStoredRequiredString(
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

function parseStoredOptionalString(
  value: unknown,
  fieldName: string,
  maxLength: number,
): string {
  if (value === undefined || value === null) return '';
  if (typeof value !== 'string') {
    throw new HttpsError('failed-precondition', `${fieldName} geçersiz.`);
  }
  const trimmed = value.trim();
  if (trimmed.length > maxLength) {
    throw new HttpsError('failed-precondition', `${fieldName} çok uzun.`);
  }
  return trimmed;
}

function parseStoredPlaceDetails(
  data: Record<string, unknown>,
): PlaceDetails {
  const location = parseStoredLocation(data.latitude, data.longitude);
  return {
    name: parseStoredRequiredString(data.name, 'name', 100),
    type: parseStoredPlaceType(data.type),
    description: parseStoredOptionalString(
      data.description,
      'description',
      500,
    ),
    address: parseStoredOptionalString(data.address, 'address', 300),
    latitude: location.latitude,
    longitude: location.longitude,
    priceRange: parseStoredPriceRange(data.priceRange),
    openHours: nullableStoredString(data.openHours, 'openHours', 120),
    phone: nullableStoredString(data.phone, 'phone', 40),
    amenities: parseStoredStringList(data.amenities, 12, 60),
  };
}

function parseApprovedPlaceDetails(
  value: unknown,
  fallback: PlaceDetails,
): PlaceDetails {
  if (value === undefined || value === null) return fallback;
  if (!isRecord(value)) {
    throw new HttpsError('invalid-argument', 'approvedPlace map olmalı.');
  }
  const location = parseOptionalLocation(
    value.latitude ?? fallback.latitude,
    value.longitude ?? fallback.longitude,
  );
  return {
    name: value.name === undefined
      ? fallback.name
      : parseRequiredString(value.name, 'name', 2, 100),
    type: value.type === undefined
      ? fallback.type
      : parsePlaceType(value.type),
    description: value.description === undefined
      ? fallback.description
      : parseOptionalString(value.description, 'description', 500) ?? '',
    address: value.address === undefined
      ? fallback.address
      : parseOptionalString(value.address, 'address', 300) ?? '',
    latitude: location.latitude,
    longitude: location.longitude,
    priceRange: value.priceRange === undefined
      ? fallback.priceRange
      : parseOptionalPriceRange(value.priceRange) ?? null,
    openHours: value.openHours === undefined
      ? fallback.openHours
      : parseOptionalString(value.openHours, 'openHours', 120) ?? null,
    phone: value.phone === undefined
      ? fallback.phone
      : parseOptionalPhone(value.phone) ?? null,
    amenities: value.amenities === undefined
      ? fallback.amenities
      : parseStringList(value.amenities, 'amenities', 12, 60),
  };
}

function parseStoredLocation(
  latitudeValue: unknown,
  longitudeValue: unknown,
): { latitude: number | null; longitude: number | null } {
  if (
    (latitudeValue === undefined || latitudeValue === null) &&
    (longitudeValue === undefined || longitudeValue === null)
  ) {
    return { latitude: null, longitude: null };
  }
  const latitude = Number(latitudeValue);
  const longitude = Number(longitudeValue);
  if (
    !Number.isFinite(latitude) ||
    !Number.isFinite(longitude) ||
    latitude < -90 ||
    latitude > 90 ||
    longitude < -180 ||
    longitude > 180
  ) {
    throw new HttpsError(
      'failed-precondition',
      'Kayıtlı konum koordinatları geçersiz.',
    );
  }
  return { latitude, longitude };
}

function parseStoredPriceRange(value: unknown): string | null {
  if (value === undefined || value === null || value === '') return null;
  if (typeof value !== 'string' || !ALLOWED_PRICE_RANGES.includes(value)) {
    throw new HttpsError(
      'failed-precondition',
      'Kayıtlı fiyat aralığı geçersiz.',
    );
  }
  return value;
}

function nullableStoredString(
  value: unknown,
  fieldName: string,
  maxLength: number,
): string | null {
  const parsed = parseStoredOptionalString(value, fieldName, maxLength);
  return parsed.length === 0 ? null : parsed;
}

function parseStoredStringList(
  value: unknown,
  maxItems: number,
  maxItemLength: number,
): string[] {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value) || value.length > maxItems) {
    throw new HttpsError(
      'failed-precondition',
      'Kayıtlı liste alanı geçersiz.',
    );
  }
  return [...new Set(value.map((item) => {
    if (typeof item !== 'string') {
      throw new HttpsError(
        'failed-precondition',
        'Kayıtlı liste elemanı geçersiz.',
      );
    }
    const trimmed = item.trim();
    if (trimmed.length === 0 || trimmed.length > maxItemLength) {
      throw new HttpsError(
        'failed-precondition',
        'Kayıtlı liste elemanı geçersiz.',
      );
    }
    return trimmed;
  }))];
}

function changedPlaceFields(
  before: PlaceDetails,
  after: PlaceDetails,
): string[] {
  const fields: (keyof PlaceDetails)[] = [
    'name',
    'type',
    'description',
    'address',
    'latitude',
    'longitude',
    'priceRange',
    'openHours',
    'phone',
    'amenities',
  ];
  return fields
    .filter((field) =>
      JSON.stringify(before[field]) !== JSON.stringify(after[field]),
    )
    .map(String);
}

function googleMapsUrl(latitude: number, longitude: number): string {
  return `https://www.google.com/maps/search/?api=1&query=${latitude},${longitude}`;
}

function parseStoredPhotoUrls(value: unknown): string[] {
  if (!Array.isArray(value) || value.length > MAX_PHOTO_COUNT) {
    throw new HttpsError(
      'failed-precondition',
      'Kayıtlı fotoğraf listesi geçersiz.',
    );
  }
  return value.map((item) => {
    if (typeof item !== 'string') {
      throw new HttpsError(
        'failed-precondition',
        'Kayıtlı fotoğraf URLsi geçersiz.',
      );
    }
    const trimmed = item.trim();
    if (trimmed.length === 0 || trimmed.length > 2048) {
      throw new HttpsError(
        'failed-precondition',
        'Kayıtlı fotoğraf URLsi geçersiz.',
      );
    }
    return trimmed;
  });
}

function safeStoredPhotoCount(value: unknown): number {
  if (!Array.isArray(value)) return 0;
  return Math.min(value.length, MAX_PHOTO_COUNT);
}

function resolveUserName(
  profileName: unknown,
  tokenName: unknown,
  tokenEmail: unknown,
): string {
  const fromProfile = safeMetadataString(profileName, 120);
  if (fromProfile) return fromProfile;

  const fromToken = safeMetadataString(tokenName, 120);
  if (fromToken) return fromToken;

  const email = safeMetadataString(tokenEmail, 320);
  if (email) {
    const localPart = email.split('@')[0].trim();
    if (localPart.length > 0) return localPart.slice(0, 120);
  }
  return 'Kullanıcı';
}

function safeMetadataString(
  value: unknown,
  maxLength = 256,
): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  if (trimmed.length === 0) return null;
  return trimmed.length > maxLength ? trimmed.slice(0, maxLength) : trimmed;
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

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}
