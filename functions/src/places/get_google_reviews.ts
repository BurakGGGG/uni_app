import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';

const GOOGLE_MAPS_API_KEY = defineSecret('GOOGLE_MAPS_API_KEY');
const db = admin.firestore();

const LOG_COMPONENT = 'get_google_reviews';
const PLACES_URL = 'https://places.googleapis.com/v1/places';
// Yorum alanı "Enterprise + Atmosphere" SKU'suna girer: ayda 1.000 çağrı
// ücretsiz. 950 tavanı ay sınırı/saat dilimi kaymalarına karşı tampon bırakır —
// sıfır maliyet garantisi. Konsoldaki günlük kota sınırı ikinci emniyettir.
const MONTHLY_CALL_LIMIT = 950;
const COUNTER_DOC = 'systemCounters/googlePlacesMonthly';
const REQUEST_TIMEOUT_MS = 10000;

const ID_RE = /^[A-Za-z0-9_-]{1,256}$/;

interface GoogleReviewPayload {
  authorName: string;
  authorPhotoUri: string | null;
  authorUri: string | null;
  rating: number;
  text: string;
  relativeTime: string;
}

interface GoogleReviewsOutput {
  rating: number;
  userRatingCount: number;
  reviews: GoogleReviewPayload[];
  fetchedAt: number;
}

// Places API (New) Place Details yanıtının kullandığımız alt kümesi.
interface PlaceDetailsResponse {
  rating?: number;
  userRatingCount?: number;
  reviews?: Array<{
    rating?: number;
    text?: { text?: string };
    relativePublishTimeDescription?: string;
    authorAttribution?: {
      displayName?: string;
      uri?: string;
      photoUri?: string;
    };
  }>;
}

/**
 * Bir üniversitenin Google puanı + en fazla 5 Google yorumunu CANLI döner.
 *
 * Places politikası: yorum içeriği hiçbir yerde saklanmaz/loglanmaz —
 * yalnızca place_id kalıcıdır (universities/{id}.googlePlaceId).
 * Client atıf gösterimiyle yükümlüdür (yazar adı/foto/profil linki + Google).
 */
export const getGoogleReviews = onCall(
  {
    region: 'europe-west1',
    timeoutSeconds: 15, // timeout pyramid: Client 20s > Function 15s > Places 10s
    memory: '256MiB',
    secrets: [GOOGLE_MAPS_API_KEY],
    cors: true,
    enforceAppCheck: true,
  },
  async (req): Promise<GoogleReviewsOutput> => {
    // Auth şartı yok: detay ekranı misafire açık. App Check kötüye kullanım
    // kapısı, aylık global tavan maliyet kapısıdır.
    const universityId = String((req.data ?? {}).universityId ?? '');
    if (!ID_RE.test(universityId)) {
      throw new HttpsError('invalid-argument', 'Geçersiz üniversite kimliği.');
    }

    const uniSnap = await db.collection('universities').doc(universityId).get();
    const placeId = uniSnap.exists ? uniSnap.data()?.googlePlaceId : null;
    if (typeof placeId !== 'string' || placeId.length === 0) {
      throw new HttpsError('not-found', 'Bu üniversite için Google yorumu yok.');
    }

    const apiKey = GOOGLE_MAPS_API_KEY.value();
    if (!apiKey) {
      logger.error('GOOGLE_MAPS_API_KEY missing', { component: LOG_COMPONENT });
      throw new HttpsError('failed-precondition', 'Servis şu anda kullanılamıyor.');
    }

    await reserveMonthlyQuota();

    let details: PlaceDetailsResponse;
    try {
      details = await fetchPlaceDetails(apiKey, placeId);
    } catch (err) {
      // Kota düşüldü ama upstream başarısız — hakkı iade et (best-effort).
      await releaseMonthlyQuota();
      logger.error('Places fetch failed', {
        component: LOG_COMPONENT,
        universityId,
        err: String(err),
      });
      throw new HttpsError('unavailable', 'Google yorumları şu anda alınamıyor.');
    }

    // Yorum METNİ loglanmaz — sadece sayısal telemetri.
    logger.info('Google reviews served', {
      component: LOG_COMPONENT,
      universityId,
      reviewCount: details.reviews?.length ?? 0,
      appCheckPresent: Boolean(req.app),
    });

    return {
      rating: typeof details.rating === 'number' ? details.rating : 0,
      userRatingCount:
        typeof details.userRatingCount === 'number' ? details.userRatingCount : 0,
      reviews: (details.reviews ?? []).slice(0, 5).map((r) => ({
        authorName: r.authorAttribution?.displayName ?? 'Google kullanıcısı',
        authorPhotoUri: r.authorAttribution?.photoUri ?? null,
        authorUri: r.authorAttribution?.uri ?? null,
        rating: typeof r.rating === 'number' ? r.rating : 0,
        text: r.text?.text ?? '',
        relativeTime: r.relativePublishTimeDescription ?? '',
      })),
      fetchedAt: Date.now(),
    };
  },
);

/** Aylık global sayacı transaction ile artırır; tavan aşıldıysa fırlatır. */
async function reserveMonthlyQuota(): Promise<void> {
  const counterRef = db.doc(COUNTER_DOC);
  const monthKey = currentMonthKey();

  try {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(counterRef);
      const data = snap.exists ? snap.data() ?? {} : {};
      const sameMonth = data.monthKey === monthKey;
      const count = sameMonth ? Number(data.count ?? 0) : 0;

      if (count >= MONTHLY_CALL_LIMIT) {
        throw new HttpsError(
          'resource-exhausted',
          'Google yorumları için aylık kota doldu.',
        );
      }

      tx.set(counterRef, {
        monthKey,
        count: count + 1,
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    logger.error('Quota transaction failed', { component: LOG_COMPONENT, err: String(err) });
    throw new HttpsError('internal', 'Geçici bir sorun oluştu.');
  }
}

/** Upstream hatasında rezerve edilen hakkı iade eder (best-effort). */
async function releaseMonthlyQuota(): Promise<void> {
  try {
    await db.doc(COUNTER_DOC).set(
      { count: FieldValue.increment(-1) },
      { merge: true },
    );
  } catch (err) {
    logger.warn('Quota release failed', { component: LOG_COMPONENT, err: String(err) });
  }
}

async function fetchPlaceDetails(
  apiKey: string,
  placeId: string,
): Promise<PlaceDetailsResponse> {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), REQUEST_TIMEOUT_MS);

  try {
    const url =
      `${PLACES_URL}/${encodeURIComponent(placeId)}` +
      '?languageCode=tr&regionCode=TR';
    const res = await fetch(url, {
      headers: {
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'rating,userRatingCount,reviews',
      },
      signal: ctrl.signal,
    });

    if (!res.ok) {
      const text = await res.text();
      // ❗ Kullanıcıya Places hata detayı sızmaz; log'da da yorum içeriği olmaz.
      logger.error('Places HTTP error', {
        component: LOG_COMPONENT,
        status: res.status,
        body: text.slice(0, 300),
      });
      throw new Error(`Places HTTP ${res.status}`);
    }

    return (await res.json()) as PlaceDetailsResponse;
  } finally {
    clearTimeout(timer);
  }
}

function currentMonthKey(): string {
  const d = new Date();
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}`;
}
