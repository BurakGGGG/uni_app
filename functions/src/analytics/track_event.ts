import {
  onCall,
  HttpsError,
  type CallableRequest,
  type FunctionsErrorCode,
} from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';

const db = admin.firestore();

const LOG_COMPONENT = 'analytics.trackAnalyticsEvent';
const MAX_EVENTS_PER_CALL = 10;
const RATE_LIMIT_WINDOW_MS = 60 * 1000;
const RATE_LIMIT_MAX_EVENTS = 120;

const analyticsEvents = {
  newUser: ['totalUsers', 'newUsers'],
  login: ['totalLogins', 'logins'],
  reviewCreated: ['totalReviews', 'reviews'],
  reviewLiked: ['totalLikes', 'likes'],
  storyViewed: ['totalStoryViews', 'storyViews'],
  comparisonMade: ['totalComparisons', 'comparisons'],
  scoreCalculated: ['totalScoreCalculations', 'scoreCalculations'],
  favoriteAdded: ['totalFavorites', 'favorites'],
  reportCreated: ['totalReports', 'reports'],
  universityViewed: ['totalUniversityViews', 'universityViews'],
  departmentViewed: ['totalDepartmentViews', 'departmentViews'],
  searchPerformed: ['totalSearches', 'searches'],
  preferenceListCreated: ['totalPreferenceLists', 'preferenceLists'],
  preferenceListShared: ['totalPreferenceListShares', 'preferenceListShares'],
  comparisonShared: ['totalComparisonShares', 'comparisonShares'],
  preferenceWizardOpened: [
    'totalPreferenceWizardOpened',
    'preferenceWizardOpened',
  ],
  preferenceWizardMatched: [
    'totalPreferenceWizardMatched',
    'preferenceWizardMatched',
  ],
  preferenceAutoListCreated: ['totalPreferenceAutoLists', 'preferenceAutoLists'],
  paywallShown: ['totalPaywallShown', 'paywallShown'],
  adWatched: ['totalAdWatched', 'adWatched'],
  subscriptionPurchased: ['totalSubscriptionPurchased', 'subscriptionPurchased'],
  aiComparisonUsed: ['totalAiComparisons', 'aiComparisons'],
  aiRecommendationUsed: ['totalAiRecommendations', 'aiRecommendations'],
} as const;

type AnalyticsEventName = keyof typeof analyticsEvents;

interface TrackAnalyticsInput {
  event?: unknown;
  events?: unknown;
  universityId?: unknown;
  universityName?: unknown;
}

interface AnalyticsLogContext {
  component: typeof LOG_COMPONENT;
  authenticated: boolean;
  appCheckPresent: boolean;
  uid?: string;
  appId?: string;
  appCheckAlreadyConsumed?: boolean;
}

export const trackAnalyticsEvent = onCall(
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
      rejectAnalytics(
        'unauthenticated',
        'Giriş gerekli.',
        'unauthenticated',
        logContext,
      );
    }

    const uid = req.auth.uid;
    const authenticatedLogContext = buildLogContext(req, uid);
    const input = (req.data ?? {}) as TrackAnalyticsInput;
    const events = parseEvents(input, authenticatedLogContext);
    await enforceRateLimit(uid, events.length, authenticatedLogContext);
    const eventCounts = countEvents(events);

    const today = formatDate(new Date());
    const counterUpdates: Record<string, unknown> = {
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    };
    const dailyUpdates: Record<string, unknown> = {
      date: today,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    };

    for (const eventName of Object.keys(eventCounts) as AnalyticsEventName[]) {
      const count = eventCounts[eventName];
      const [counterField, dailyField] = analyticsEvents[eventName];
      counterUpdates[counterField] = admin.firestore.FieldValue.increment(count);
      dailyUpdates[dailyField] = admin.firestore.FieldValue.increment(count);
    }

    const batch = db.batch();
    batch.set(db.collection('analytics').doc('counters'), counterUpdates, { merge: true });
    batch.set(db.collection('analytics').doc(`daily_${today}`), dailyUpdates, { merge: true });

    let topUniversityUpdated = false;
    if (events.includes('universityViewed')) {
      const university = parseUniversity(input, authenticatedLogContext);
      batch.set(
        db.collection('analytics').doc('topUniversities').collection('items').doc(university.id),
        {
          name: university.name,
          viewCount: admin.firestore.FieldValue.increment(1),
          lastViewed: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      topUniversityUpdated = true;
    }

    try {
      await batch.commit();
      logger.info('Analytics event accepted', {
        ...authenticatedLogContext,
        outcome: 'accepted',
        date: today,
        eventCount: events.length,
        eventCounts: countsForLog(eventCounts),
        topUniversityUpdated,
      });
      return { ok: true };
    } catch (err) {
      logger.error('Analytics event write failed', {
        ...authenticatedLogContext,
        outcome: 'failed',
        reason: 'write_failed',
        date: today,
        eventCount: events.length,
        eventCounts: countsForLog(eventCounts),
        topUniversityUpdated,
        err: errorForLog(err),
      });
      throw new HttpsError('internal', 'Analytics kaydı yapılamadı.');
    }
  },
);

function parseEvents(
  input: TrackAnalyticsInput,
  logContext: AnalyticsLogContext,
): AnalyticsEventName[] {
  const rawEvents = Array.isArray(input.events)
    ? input.events
    : input.event === undefined
      ? []
      : [input.event];

  if (rawEvents.length === 0) {
    rejectAnalytics(
      'invalid-argument',
      'Analytics event gerekli.',
      'missing_event',
      logContext,
    );
  }

  if (rawEvents.length > MAX_EVENTS_PER_CALL) {
    rejectAnalytics(
      'invalid-argument',
      'Tek çağrıda en fazla 10 analytics event gönderilebilir.',
      'too_many_events',
      logContext,
      {
        rawEventCount: rawEvents.length,
        maxEventsPerCall: MAX_EVENTS_PER_CALL,
      },
    );
  }

  const events: AnalyticsEventName[] = [];
  for (const rawEvent of rawEvents) {
    if (typeof rawEvent !== 'string') {
      rejectAnalytics(
        'invalid-argument',
        'Analytics event string olmalı.',
        'invalid_event_type',
        logContext,
        { valueType: valueTypeForLog(rawEvent) },
      );
    }

    const eventName = rawEvent.trim();
    if (!isAnalyticsEventName(eventName)) {
      rejectAnalytics(
        'invalid-argument',
        'Geçersiz analytics event.',
        'invalid_event_name',
        logContext,
        { eventName: stringForLog(eventName) },
      );
    }
    events.push(eventName);
  }

  return events;
}

function isAnalyticsEventName(value: string): value is AnalyticsEventName {
  return Object.prototype.hasOwnProperty.call(analyticsEvents, value);
}

function countEvents(events: AnalyticsEventName[]): Record<AnalyticsEventName, number> {
  const counts = {} as Record<AnalyticsEventName, number>;
  for (const eventName of events) {
    counts[eventName] = (counts[eventName] ?? 0) + 1;
  }
  return counts;
}

function parseUniversity(
  input: TrackAnalyticsInput,
  logContext: AnalyticsLogContext,
): { id: string; name: string } {
  const id = typeof input.universityId === 'string' ? input.universityId.trim() : '';
  const name = typeof input.universityName === 'string' ? input.universityName.trim() : '';
  if (!id || !name) {
    rejectAnalytics(
      'invalid-argument',
      'Üniversite bilgisi gerekli.',
      'missing_university_payload',
      logContext,
      {
        hasUniversityId: Boolean(id),
        hasUniversityName: Boolean(name),
      },
    );
  }
  if (id.length > 80 || name.length > 160) {
    rejectAnalytics(
      'invalid-argument',
      'Üniversite bilgisi geçersiz.',
      'invalid_university_length',
      logContext,
      {
        universityIdLength: id.length,
        universityNameLength: name.length,
      },
    );
  }
  if (!/^[a-zA-Z0-9_-]+$/.test(id)) {
    rejectAnalytics(
      'invalid-argument',
      'Üniversite ID formatı geçersiz.',
      'invalid_university_id_format',
      logContext,
      { universityId: stringForLog(id) },
    );
  }
  return { id, name };
}

async function enforceRateLimit(
  uid: string,
  eventCount: number,
  logContext: AnalyticsLogContext,
): Promise<void> {
  const ref = db.collection('analyticsRateLimits').doc(uid);
  const nowMs = Date.now();

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.exists ? snap.data() ?? {} : {};
    const windowStart = safeMillis(data.windowStartAt);
    const count = safeCounter(data.count);
    const windowExpired =
      windowStart <= 0 ||
      windowStart > nowMs ||
      nowMs - windowStart >= RATE_LIMIT_WINDOW_MS;
    const nextCount = windowExpired ? eventCount : count + eventCount;

    if (nextCount > RATE_LIMIT_MAX_EVENTS) {
      logger.warn('Analytics event rejected', {
        ...logContext,
        outcome: 'rejected',
        reason: 'rate_limited',
        code: 'resource-exhausted',
        currentCount: count,
        eventCount,
        nextCount,
        limit: RATE_LIMIT_MAX_EVENTS,
        windowAgeMs: windowStart > 0 ? nowMs - windowStart : null,
      });
      throw new HttpsError(
        'resource-exhausted',
        'Çok kısa sürede fazla analytics olayı gönderildi.',
      );
    }

    tx.set(
      ref,
      {
        windowStartAt: windowExpired ? nowMs : windowStart,
        count: nextCount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
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

function buildLogContext(
  req: CallableRequest<unknown>,
  uid?: string,
): AnalyticsLogContext {
  return {
    component: LOG_COMPONENT,
    authenticated: Boolean(uid),
    appCheckPresent: Boolean(req.app),
    uid,
    appId: req.app?.appId,
    appCheckAlreadyConsumed: req.app?.alreadyConsumed,
  };
}

function rejectAnalytics(
  code: FunctionsErrorCode,
  message: string,
  reason: string,
  logContext: AnalyticsLogContext,
  extra: Record<string, unknown> = {},
): never {
  logger.warn('Analytics event rejected', {
    ...logContext,
    outcome: 'rejected',
    reason,
    code,
    ...extra,
  });
  throw new HttpsError(code, message);
}

function countsForLog(
  counts: Record<AnalyticsEventName, number>,
): Partial<Record<AnalyticsEventName, number>> {
  return counts;
}

function errorForLog(err: unknown): string {
  if (err instanceof Error) {
    return `${err.name}: ${err.message}`;
  }
  return stringForLog(err);
}

function valueTypeForLog(value: unknown): string {
  if (value === null) return 'null';
  if (Array.isArray(value)) return 'array';
  return typeof value;
}

function stringForLog(value: unknown): string {
  return String(value).slice(0, 120);
}

function formatDate(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}
