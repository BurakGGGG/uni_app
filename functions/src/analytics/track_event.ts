import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';

const db = admin.firestore();

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

export const trackAnalyticsEvent = onCall(
  {
    region: 'europe-west1',
    timeoutSeconds: 10,
    memory: '256MiB',
    cors: true,
    enforceAppCheck: true,
  },
  async (req): Promise<{ ok: true }> => {
    if (!req.auth) {
      throw new HttpsError('unauthenticated', 'Giriş gerekli.');
    }

    const uid = req.auth.uid;
    const input = (req.data ?? {}) as TrackAnalyticsInput;
    const events = parseEvents(input);
    await enforceRateLimit(uid, events.length);

    const today = formatDate(new Date());
    const counterUpdates: Record<string, unknown> = {
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    };
    const dailyUpdates: Record<string, unknown> = {
      date: today,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    };

    const eventCounts = countEvents(events);
    for (const eventName of Object.keys(eventCounts) as AnalyticsEventName[]) {
      const count = eventCounts[eventName];
      const [counterField, dailyField] = analyticsEvents[eventName];
      counterUpdates[counterField] = admin.firestore.FieldValue.increment(count);
      dailyUpdates[dailyField] = admin.firestore.FieldValue.increment(count);
    }

    const batch = db.batch();
    batch.set(db.collection('analytics').doc('counters'), counterUpdates, { merge: true });
    batch.set(db.collection('analytics').doc(`daily_${today}`), dailyUpdates, { merge: true });

    if (events.includes('universityViewed')) {
      const university = parseUniversity(input);
      if (university) {
        batch.set(
          db.collection('analytics').doc('topUniversities').collection('items').doc(university.id),
          {
            name: university.name,
            viewCount: admin.firestore.FieldValue.increment(1),
            lastViewed: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }
    }

    try {
      await batch.commit();
      return { ok: true };
    } catch (err) {
      logger.error('Analytics event write failed', { uid, err: String(err) });
      throw new HttpsError('internal', 'Analytics kaydı yapılamadı.');
    }
  },
);

function parseEvents(input: TrackAnalyticsInput): AnalyticsEventName[] {
  const rawEvents = Array.isArray(input.events) ? input.events : [input.event];
  const rawNames = rawEvents
    .filter((value): value is string => typeof value === 'string')
    .slice(0, MAX_EVENTS_PER_CALL);

  if (rawNames.length === 0) {
    throw new HttpsError('invalid-argument', 'Analytics event gerekli.');
  }

  const events: AnalyticsEventName[] = [];
  for (const eventName of rawNames) {
    if (!isAnalyticsEventName(eventName)) {
      throw new HttpsError('invalid-argument', 'Geçersiz analytics event.');
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

function parseUniversity(input: TrackAnalyticsInput): { id: string; name: string } | null {
  const id = typeof input.universityId === 'string' ? input.universityId.trim() : '';
  const name = typeof input.universityName === 'string' ? input.universityName.trim() : '';
  if (!id || !name) return null;
  if (id.length > 80 || name.length > 160) {
    throw new HttpsError('invalid-argument', 'Üniversite bilgisi geçersiz.');
  }
  if (!/^[a-zA-Z0-9_-]+$/.test(id)) {
    throw new HttpsError('invalid-argument', 'Üniversite ID formatı geçersiz.');
  }
  return { id, name };
}

async function enforceRateLimit(uid: string, eventCount: number): Promise<void> {
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

function formatDate(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}
