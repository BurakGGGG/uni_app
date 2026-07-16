import {
  onCall,
  HttpsError,
  type CallableRequest,
  type FunctionsErrorCode,
} from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import {
  VIEWED_CITY_CAP,
  VIEWED_UNIVERSITY_CAP,
  istanbulDateString,
  istanbulYesterdayString,
} from './catalog';
import {
  engagementStatsRef,
  evaluateAmbientBadges,
  evaluateComparisonBadges,
  evaluateExplorationBadges,
  evaluateShareBadges,
  evaluateStreakBadges,
} from './award_badges';

const db = admin.firestore();

const LOG_COMPONENT = 'badges.recordEngagementEvent';
const RATE_LIMIT_WINDOW_MS = 60 * 1000;
const RATE_LIMIT_MAX_EVENTS = 60;
const TARGET_ID_PATTERN = /^[a-zA-Z0-9_-]{1,80}$/;

const ENGAGEMENT_EVENTS = [
  'app_open',
  'university_viewed',
  'city_viewed',
  'comparison_made',
  'content_shared',
  'profile_updated',
] as const;

type EngagementEventName = (typeof ENGAGEMENT_EVENTS)[number];

const EVENTS_REQUIRING_TARGET: ReadonlySet<EngagementEventName> = new Set([
  'university_viewed',
  'city_viewed',
]);

interface EngagementLogContext {
  component: typeof LOG_COMPONENT;
  authenticated: boolean;
  appCheckPresent: boolean;
  uid?: string;
  appId?: string;
}

interface StatsUpdateResult {
  currentStreak: number;
  viewedUniversityCount: number;
  viewedCityCount: number;
  comparisonCount: number;
  shareCount: number;
}

/**
 * İstemci etkileşim olaylarını kaydeder (streak, keşif, karşılaştırma,
 * paylaşım sayaçları) ve ilgili rozetleri değerlendirir.
 *
 * users/{uid}/stats/engagement yalnız bu fonksiyon üzerinden yazılır
 * (rules: allow write: if false) — rozetler güven ürünü olduğundan
 * istemciye yazma yüzeyi açılmaz.
 */
export const recordEngagementEvent = onCall(
  {
    region: 'europe-west1',
    timeoutSeconds: 10,
    memory: '256MiB',
    cors: true,
    enforceAppCheck: true,
  },
  async (req): Promise<{ ok: true }> => {
    const logContext = buildLogContext(req);

    if (!req.auth) {
      reject(
        'unauthenticated',
        'Giriş gerekli.',
        'unauthenticated',
        logContext,
      );
    }

    const uid = req.auth.uid;
    const authedContext = buildLogContext(req, uid);
    const { event, targetId } = parseInput(req.data, authedContext);

    await enforceRateLimit(uid, authedContext);

    const stats = await updateStats(uid, event, targetId);
    await runEvaluators(uid, event, stats);

    logger.info('Engagement event accepted', {
      ...authedContext,
      outcome: 'accepted',
      event,
      currentStreak: stats.currentStreak,
    });
    return { ok: true };
  },
);

function parseInput(
  data: unknown,
  logContext: EngagementLogContext,
): { event: EngagementEventName; targetId?: string } {
  const input = (data ?? {}) as { event?: unknown; targetId?: unknown };

  const rawEvent = typeof input.event === 'string' ? input.event.trim() : '';
  if (!isEngagementEventName(rawEvent)) {
    reject(
      'invalid-argument',
      'Geçersiz engagement olayı.',
      'invalid_event_name',
      logContext,
      { eventName: String(input.event).slice(0, 120) },
    );
  }

  if (!EVENTS_REQUIRING_TARGET.has(rawEvent)) {
    return { event: rawEvent };
  }

  const targetId =
    typeof input.targetId === 'string' ? input.targetId.trim() : '';
  if (!TARGET_ID_PATTERN.test(targetId)) {
    reject(
      'invalid-argument',
      'Geçersiz hedef ID.',
      'invalid_target_id',
      logContext,
      { event: rawEvent },
    );
  }

  return { event: rawEvent, targetId };
}

function isEngagementEventName(value: string): value is EngagementEventName {
  return (ENGAGEMENT_EVENTS as readonly string[]).includes(value);
}

/**
 * Stats dokümanını tek transaction'da günceller. Her olay o günü "aktif"
 * sayar; streak Europe/Istanbul takvimine göre yürür.
 */
async function updateStats(
  uid: string,
  event: EngagementEventName,
  targetId?: string,
): Promise<StatsUpdateResult> {
  const ref = engagementStatsRef(uid);
  const now = new Date();
  const today = istanbulDateString(now);
  const yesterday = istanbulYesterdayString(now);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data() ?? {};

    const lastActiveDate =
      typeof data.lastActiveDate === 'string' ? data.lastActiveDate : '';
    let currentStreak = safeCount(data.currentStreak);
    let longestStreak = safeCount(data.longestStreak);
    let totalActiveDays = safeCount(data.totalActiveDays);

    if (lastActiveDate !== today) {
      currentStreak = lastActiveDate === yesterday ? currentStreak + 1 : 1;
      longestStreak = Math.max(longestStreak, currentStreak);
      totalActiveDays += 1;
    }

    const viewedUniversityIds = safeIdMap(data.viewedUniversityIds);
    const viewedCityIds = safeIdMap(data.viewedCityIds);
    let comparisonCount = safeCount(data.comparisonCount);
    let shareCount = safeCount(data.shareCount);

    if (event === 'university_viewed' && targetId) {
      addDistinct(viewedUniversityIds, targetId, VIEWED_UNIVERSITY_CAP);
    } else if (event === 'city_viewed' && targetId) {
      addDistinct(viewedCityIds, targetId, VIEWED_CITY_CAP);
    } else if (event === 'comparison_made') {
      comparisonCount += 1;
    } else if (event === 'content_shared') {
      shareCount += 1;
    }

    const result: StatsUpdateResult = {
      currentStreak,
      viewedUniversityCount: Object.keys(viewedUniversityIds).length,
      viewedCityCount: Object.keys(viewedCityIds).length,
      comparisonCount,
      shareCount,
    };

    tx.set(
      ref,
      {
        lastActiveDate: today,
        currentStreak,
        longestStreak,
        totalActiveDays,
        viewedUniversityIds,
        viewedUniversityCount: result.viewedUniversityCount,
        viewedCityIds,
        viewedCityCount: result.viewedCityCount,
        comparisonCount,
        shareCount,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return result;
  });
}

/** Olayla ilgili rozet değerlendiricilerini çalıştırır. */
async function runEvaluators(
  uid: string,
  event: EngagementEventName,
  stats: StatsUpdateResult,
): Promise<void> {
  // Her olay streak'i ilerletmiş olabilir; ek okuma gerektirmez.
  await evaluateStreakBadges(uid, stats.currentStreak);

  switch (event) {
    case 'app_open':
      // Üyelik yaşı / early adopter / verified / profil rozetleri bir
      // sonraki açılışta kendiliğinden verilsin — scheduler gerekmez.
      await evaluateAmbientBadges(uid);
      break;
    case 'university_viewed':
    case 'city_viewed':
      await evaluateExplorationBadges(
        uid,
        stats.viewedUniversityCount,
        stats.viewedCityCount,
      );
      break;
    case 'comparison_made':
      await evaluateComparisonBadges(uid, stats.comparisonCount);
      break;
    case 'content_shared':
      await evaluateShareBadges(uid, stats.shareCount);
      break;
    case 'profile_updated':
      await evaluateAmbientBadges(uid);
      break;
    // NOT: favori rozetleri Firestore trigger'ı (syncUserFavoriteBadges)
    // ile sunucu-otoriter değerlendirilir; burada işlenmez.
  }
}

async function enforceRateLimit(
  uid: string,
  logContext: EngagementLogContext,
): Promise<void> {
  const ref = db.collection('engagementRateLimits').doc(uid);
  const nowMs = Date.now();

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.exists ? snap.data() ?? {} : {};
    const windowStart = safeCount(data.windowStartAt);
    const count = safeCount(data.count);
    const windowExpired =
      windowStart <= 0 ||
      windowStart > nowMs ||
      nowMs - windowStart >= RATE_LIMIT_WINDOW_MS;
    const nextCount = windowExpired ? 1 : count + 1;

    if (nextCount > RATE_LIMIT_MAX_EVENTS) {
      logger.warn('Engagement event rejected', {
        ...logContext,
        outcome: 'rejected',
        reason: 'rate_limited',
        code: 'resource-exhausted',
        currentCount: count,
        limit: RATE_LIMIT_MAX_EVENTS,
        windowAgeMs: windowStart > 0 ? nowMs - windowStart : null,
      });
      throw new HttpsError(
        'resource-exhausted',
        'Çok kısa sürede fazla olay gönderildi.',
      );
    }

    tx.set(
      ref,
      {
        windowStartAt: windowExpired ? nowMs : windowStart,
        count: nextCount,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
}

function addDistinct(
  ids: Record<string, true>,
  id: string,
  cap: number,
): void {
  if (ids[id] === true) return;
  if (Object.keys(ids).length >= cap) return;
  ids[id] = true;
}

function safeIdMap(value: unknown): Record<string, true> {
  if (value == null || typeof value !== 'object' || Array.isArray(value)) {
    return {};
  }
  const result: Record<string, true> = {};
  for (const key of Object.keys(value as Record<string, unknown>)) {
    result[key] = true;
  }
  return result;
}

function safeCount(value: unknown): number {
  const n = Number(value);
  if (!Number.isFinite(n) || n < 0) return 0;
  return Math.floor(n);
}

function buildLogContext(
  req: CallableRequest<unknown>,
  uid?: string,
): EngagementLogContext {
  return {
    component: LOG_COMPONENT,
    authenticated: Boolean(uid),
    appCheckPresent: Boolean(req.app),
    uid,
    appId: req.app?.appId,
  };
}

function reject(
  code: FunctionsErrorCode,
  message: string,
  reason: string,
  logContext: EngagementLogContext,
  extra: Record<string, unknown> = {},
): never {
  logger.warn('Engagement event rejected', {
    ...logContext,
    outcome: 'rejected',
    reason,
    code,
    ...extra,
  });
  throw new HttpsError(code, message);
}
