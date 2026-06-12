import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import { logger } from 'firebase-functions';

const GROQ_API_KEY = defineSecret('GROQ_API_KEY');

const db = admin.firestore();

const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const GROQ_MODEL = 'llama-3.1-8b-instant';
const CACHE_COLLECTION = 'recommendationEnrichments';
const CACHE_TTL_HOURS = 24;
const CACHE_TTL_MS = CACHE_TTL_HOURS * 3600 * 1000;
const MAX_INPUT_DEPTS = 8;
const TOP_FOR_REASONING = 3; // Sadece ilk 3 öneriye kişisel reasoning
const REQUEST_TIMEOUT_MS = 12000;
const DAILY_AI_RECOMMENDATION_LIMIT = 10;
const AI_RECOMMENDATION_RATE_WINDOW_MS = 60 * 1000;
const AI_RECOMMENDATION_RATE_LIMIT = 12;

// ─── Tipler ────────────────────────────────────────────────────
interface InputDept {
  departmentId: string;
  departmentName: string;
  universityId: string;
  universityName: string;
  totalScore: number;
  reasons: string[];
}

interface EnrichInput {
  userTags: Record<string, string>;
  recommendations: InputDept[];
}

interface EnrichedItem {
  departmentId: string;
  universityId: string;
  reasoning: string;
}

interface EnrichResponse {
  summary: string;
  items: EnrichedItem[];
  cached: boolean;
  generatedAt: number;
}

// ─── Cloud Function ────────────────────────────────────────────
export const enrichRecommendations = onCall(
  {
    region: 'us-central1',
    secrets: [GROQ_API_KEY],
    timeoutSeconds: 30,
    memory: '256MiB',
    cors: true,
    enforceAppCheck: true,
  },
  async (req): Promise<EnrichResponse> => {
    if (!req.auth) {
      throw new HttpsError('unauthenticated', 'Giriş gerekli.');
    }
    const uid = req.auth.uid;

    const data = req.data as EnrichInput | undefined;
    if (!data || !Array.isArray(data.recommendations) || data.recommendations.length === 0) {
      throw new HttpsError('invalid-argument', 'Öneri listesi boş.');
    }

    // İnput sanitizasyon: en fazla MAX_INPUT_DEPTS öneri
    const depts = data.recommendations.slice(0, MAX_INPUT_DEPTS).map((d) => ({
      departmentId: String(d.departmentId ?? ''),
      departmentName: String(d.departmentName ?? '').slice(0, 80),
      universityId: String(d.universityId ?? ''),
      universityName: String(d.universityName ?? '').slice(0, 80),
      totalScore: Number(d.totalScore ?? 0),
      reasons: Array.isArray(d.reasons)
        ? d.reasons.slice(0, 4).map((r) => String(r).slice(0, 120))
        : [],
    }));

    const userTags = sanitizeTags(data.userTags ?? {});
    const cacheHash = makeHash({ userTags, depts });

    // ── Cache kontrolü ──
    const cacheRef = db
      .collection(CACHE_COLLECTION)
      .doc(`${uid}_${cacheHash}`);
    const usageRef = db.collection('users').doc(uid).collection('usageStats').doc('current');
    const subscriptionRef = db.collection('subscriptions').doc(uid);
    const today = formatDate(new Date());
    const nowMs = Date.now();

    // ── Atomik entitlement + rate limit + quota kontrolü ──
    let cachedResponse: EnrichResponse | null = null;
    let needsToCallGroq = false;

    try {
      await db.runTransaction(async (tx) => {
        const subscriptionSnap = await tx.get(subscriptionRef);
        const usageSnap = await tx.get(usageRef);
        const cacheSnap = await tx.get(cacheRef);

        const isAdmin = req.auth?.token.admin === true;
        if (!isAdmin && !hasActiveProSubscription(subscriptionSnap.data())) {
          throw new HttpsError(
            'permission-denied',
            'AI öneri asistanı için Pro abonelik gerekli.',
          );
        }

        const usageData = usageSnap.exists ? usageSnap.data() ?? {} : {};
        const usagePatch: Record<string, unknown> = {
          ...buildUsageStatsBasePatch(usageData, { today }),
          ...buildRecommendationRateLimitPatch(usageData, nowMs),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        if (cacheSnap.exists) {
          const cached = parseCachedResponse(cacheSnap.data(), nowMs);
          if (cached) {
            cachedResponse = cached;
            tx.set(usageRef, usagePatch, { merge: true });
            return;
          }
        }

        Object.assign(
          usagePatch,
          buildRecommendationQuotaPatch(usageData, { today }),
        );
        tx.set(usageRef, usagePatch, { merge: true });
        needsToCallGroq = true;
      });
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      logger.error('Recommendation quota transaction failed', { uid, err: String(e) });
      throw new HttpsError('internal', 'Geçici bir sorun oluştu. Lütfen tekrar dene.');
    }

    // Cache hit → günlük AI öneri hakkı düşmez.
    const cached = cachedResponse;
    if (cached) {
      await incrementAnalyticsCounter('totalAiRecommendations', 'aiRecommendations').catch((e) =>
        logger.warn('Analytics increment failed', { e }),
      );
      return cached;
    }

    // ── Groq çağrısı ──
    if (!needsToCallGroq) {
      throw new HttpsError('internal', 'Beklenmeyen durum oluştu.');
    }

    const apiKey = GROQ_API_KEY.value();
    if (!apiKey) {
      throw new HttpsError('failed-precondition', 'GROQ_API_KEY ayarlı değil.');
    }

    const prompt = buildPrompt(userTags, depts);

    let llmJson: { summary?: string; items?: EnrichedItem[] } | null = null;
    try {
      llmJson = await callGroq(apiKey, prompt);
    } catch (e) {
      logger.error('Groq call failed', { uid, err: String(e) });
      throw new HttpsError('unavailable', 'AI önerisi şu an alınamıyor.');
    }

    if (!llmJson || !llmJson.summary || !Array.isArray(llmJson.items)) {
      throw new HttpsError('internal', 'AI yanıtı geçersiz format.');
    }

    // Sonuçları doğrula: sadece ilk 3 dept ID'sine reasoning kabul et
    const top3 = depts.slice(0, TOP_FOR_REASONING);
    const allowedKeys = new Set(
      top3.map((d) => `${d.universityId}_${d.departmentId}`)
    );
    const cleanItems: EnrichedItem[] = (llmJson.items ?? [])
      .filter((it) => {
        if (!it || typeof it.reasoning !== 'string') return false;
        const key = `${it.universityId}_${it.departmentId}`;
        return allowedKeys.has(key);
      })
      .slice(0, TOP_FOR_REASONING)
      .map((it) => ({
        departmentId: String(it.departmentId),
        universityId: String(it.universityId),
        reasoning: String(it.reasoning).slice(0, 200),
      }));

    const result: EnrichResponse = {
      summary: String(llmJson.summary).slice(0, 280),
      items: cleanItems,
      cached: false,
      generatedAt: Date.now(),
    };

    await incrementAnalyticsCounter('totalAiRecommendations', 'aiRecommendations').catch((e) =>
      logger.warn('Analytics increment failed', { e }),
    );

    // ── Cache yaz ──
    try {
      await cacheRef.set({
        summary: result.summary,
        items: result.items,
        generatedAt: result.generatedAt,
        userId: uid,
      });
    } catch (e) {
      logger.warn('Cache write failed', { uid, e });
    }

    return result;
  }
);

// ─── Prompt builder ────────────────────────────────────────────
function buildPrompt(
  tags: Record<string, string>,
  depts: InputDept[]
): { system: string; user: string } {
  const tagsLines = Object.entries(tags)
    .map(([k, v]) => `- ${k}: ${v}`)
    .join('\n');

  const reasoningCount = Math.min(depts.length, TOP_FOR_REASONING);
  const reasoningDepts = depts.slice(0, reasoningCount);

  const deptsBlock = reasoningDepts
    .map((d, i) => {
      const reasons = d.reasons.length ? d.reasons.join(', ') : 'genel uyum';
      return `${i + 1}. ${d.departmentName} — ${d.universityName}
   ids: dept=${d.departmentId} uni=${d.universityId} | sinyaller: ${reasons}`;
    })
    .join('\n');

  const system = `Sen bir Türk üniversite tercih danışmanısın.
Çıktıların doğal, hatasız Türkçe olmalı. Cümleler kısa olmalı.
Asla "sevgili öğrenci", "kariyerine uygun", "harika seçim" gibi basmakalıp ifadeler kullanma.
Asla yeni bölüm/üniversite uydurma — sadece sana verilenler hakkında konuş.
Cevabın SADECE geçerli JSON olmalı; başka metin yazma.

ÇIKTI SINIRLARI (kesin):
- summary: 1-2 cümle, en fazla 30 kelime.
- her reasoning: 1 kısa cümle, en fazla 18 kelime.
- "sen" diliyle yaz, samimi ama yalın.`;

  const user = `ÖĞRENCİ YANITLARI:
${tagsLines}

KURAL MOTORUNDAN İLK 3 ÖNERİ (yalnızca bunlar için reasoning yaz):
${deptsBlock}

JSON şeması:
{
  "summary": "1-2 cümle, max 30 kelime, doğal Türkçe.",
  "items": [
    { "departmentId": "<id>", "universityId": "<id>", "reasoning": "1 kısa cümle, max 18 kelime." }
  ]
}

Kurallar:
- items DİZİSİ tam ${reasoningCount} öğe; sıralama yukarıdaki ile aynı.
- departmentId ve universityId AYNEN kopyala.
- Reasoning'de öğrencinin verdiği cevapla bağlantı kur (motivasyon/risk/şehir/alan vb.).
- Türkçe karakterleri (ç,ğ,ı,ş,ö,ü) doğru kullan.`;

  return { system, user };
}

// ─── Groq HTTP çağrısı ─────────────────────────────────────────
async function callGroq(
  apiKey: string,
  prompt: { system: string; user: string }
): Promise<{ summary?: string; items?: EnrichedItem[] }> {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), REQUEST_TIMEOUT_MS);

  try {
    const res = await fetch(GROQ_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        temperature: 0.4,       // Daha az yaratıcılık, daha tutarlı dil
        max_tokens: 400,        // Top 3 + summary için yeterli
        response_format: { type: 'json_object' },
        messages: [
          { role: 'system', content: prompt.system },
          { role: 'user', content: prompt.user },
        ],
      }),
      signal: ctrl.signal,
    });

    if (!res.ok) {
      const text = await res.text();
      throw new Error(`Groq HTTP ${res.status}: ${text.slice(0, 200)}`);
    }

    const json = (await res.json()) as {
      choices?: Array<{ message?: { content?: string } }>;
    };
    const content = json.choices?.[0]?.message?.content;
    if (!content) throw new Error('Groq empty response');

    return JSON.parse(content);
  } finally {
    clearTimeout(timer);
  }
}

// ─── Yardımcılar ───────────────────────────────────────────────
function sanitizeTags(raw: Record<string, unknown>): Record<string, string> {
  const out: Record<string, string> = {};
  for (const [k, v] of Object.entries(raw)) {
    if (typeof v !== 'string') continue;
    if (k.length > 32 || v.length > 64) continue;
    if (!/^[a-zA-Z0-9_]+$/.test(k)) continue;
    out[k] = v;
  }
  return out;
}

function makeHash(payload: unknown): string {
  const str = JSON.stringify(payload);
  return crypto.createHash('sha256').update(str).digest('hex').slice(0, 16);
}

function formatDate(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function parseCachedResponse(
  data: admin.firestore.DocumentData | undefined,
  nowMs: number,
): EnrichResponse | null {
  if (!data) return null;

  const summary = typeof data.summary === 'string' ? data.summary.trim() : '';
  const generatedAt = finiteMillis(data.generatedAt);
  if (!summary || generatedAt <= 0 || nowMs - generatedAt >= CACHE_TTL_MS) {
    return null;
  }

  if (!Array.isArray(data.items)) {
    return null;
  }

  const items = data.items
    .map((item: unknown) => parseCachedItem(item))
    .filter((item: EnrichedItem | null): item is EnrichedItem => item !== null)
    .slice(0, TOP_FOR_REASONING);

  return {
    summary: summary.slice(0, 280),
    items,
    cached: true,
    generatedAt,
  };
}

function parseCachedItem(item: unknown): EnrichedItem | null {
  if (!item || typeof item !== 'object') return null;
  const raw = item as Record<string, unknown>;
  const departmentId = typeof raw.departmentId === 'string' ? raw.departmentId : '';
  const universityId = typeof raw.universityId === 'string' ? raw.universityId : '';
  const reasoning = typeof raw.reasoning === 'string' ? raw.reasoning : '';
  if (!departmentId || !universityId || !reasoning) return null;

  return {
    departmentId,
    universityId,
    reasoning: reasoning.slice(0, 200),
  };
}

function hasActiveProSubscription(
  data: admin.firestore.DocumentData | undefined,
): boolean {
  if (!data) return false;

  const tier = String(data.tier ?? 'free');
  const status = String(data.status ?? 'expired');
  if (tier !== 'pro' || (status !== 'active' && status !== 'trial')) {
    return false;
  }

  const expiresAtMs = timestampMillis(data.expiresAt);
  return expiresAtMs <= 0 || expiresAtMs > Date.now();
}

function buildUsageStatsBasePatch(
  usageData: admin.firestore.DocumentData,
  options: { today: string },
): Record<string, unknown> {
  const patch: Record<string, unknown> = {};

  const lastResetDate = typeof usageData.lastResetDate === 'string'
    ? usageData.lastResetDate
    : '';
  if (lastResetDate !== options.today) {
    patch.lastResetDate = options.today;
    patch.dailyComparisons = 0;
    patch.dailyAiComparisons = 0;
  }

  const lastAiResetDate = typeof usageData.lastAiRecommendationResetDate === 'string'
    ? usageData.lastAiRecommendationResetDate
    : '';
  if (lastAiResetDate !== options.today) {
    patch.lastAiRecommendationResetDate = options.today;
    patch.dailyAiRecommendations = 0;
  }

  if (!isValidCounterValue(usageData.totalComparisons)) {
    patch.totalComparisons = 0;
  }

  return patch;
}

function buildRecommendationRateLimitPatch(
  usageData: admin.firestore.DocumentData,
  nowMs: number,
): Record<string, unknown> {
  const windowStart = finiteMillis(usageData.aiRecommendationWindowStartAt);
  const windowCount = safeCounter(usageData.aiRecommendationWindowCount);
  const windowExpired =
    windowStart <= 0 ||
    windowStart > nowMs ||
    nowMs - windowStart >= AI_RECOMMENDATION_RATE_WINDOW_MS;

  if (!windowExpired && windowCount >= AI_RECOMMENDATION_RATE_LIMIT) {
    throw new HttpsError(
      'resource-exhausted',
      'Çok kısa sürede fazla AI önerisi istedin. Biraz sonra tekrar dene.',
    );
  }

  const nextWindowStart = windowExpired ? nowMs : windowStart;
  return {
    aiRecommendationWindowStartAt: nextWindowStart,
    aiRecommendationWindowCount: windowExpired ? 1 : windowCount + 1,
    aiRecommendationWindowResetAt: admin.firestore.Timestamp.fromMillis(
      nextWindowStart + AI_RECOMMENDATION_RATE_WINDOW_MS,
    ),
  };
}

function buildRecommendationQuotaPatch(
  usageData: admin.firestore.DocumentData,
  options: { today: string },
): Record<string, unknown> {
  const lastAiResetDate = typeof usageData.lastAiRecommendationResetDate === 'string'
    ? usageData.lastAiRecommendationResetDate
    : '';
  const needsAiReset = lastAiResetDate !== options.today;
  const dailyAiRecommendations = needsAiReset
    ? 0
    : safeCounter(usageData.dailyAiRecommendations);

  if (dailyAiRecommendations >= DAILY_AI_RECOMMENDATION_LIMIT) {
    throw new HttpsError(
      'resource-exhausted',
      `Günlük AI öneri limiti (${DAILY_AI_RECOMMENDATION_LIMIT}) doldu. Yarın tekrar dene.`,
    );
  }

  const patch: Record<string, unknown> = {
    dailyAiRecommendations: dailyAiRecommendations + 1,
    lastAiRecommendationResetDate: options.today,
  };

  const lastResetDate = typeof usageData.lastResetDate === 'string'
    ? usageData.lastResetDate
    : '';
  if (lastResetDate !== options.today) {
    patch.lastResetDate = options.today;
    patch.dailyComparisons = 0;
    patch.dailyAiComparisons = 0;
  }

  return patch;
}

function safeCounter(value: unknown): number {
  const n = Number(value);
  if (!Number.isFinite(n) || n < 0) return 0;
  return Math.floor(n);
}

function isValidCounterValue(value: unknown): boolean {
  return typeof value === 'number' && Number.isFinite(value) && value >= 0;
}

function finiteMillis(value: unknown): number {
  const n = Number(value);
  if (!Number.isFinite(n) || n < 0) return 0;
  return Math.floor(n);
}

function timestampMillis(value: unknown): number {
  if (value instanceof admin.firestore.Timestamp) {
    return value.toMillis();
  }
  return finiteMillis(value);
}

async function incrementAnalyticsCounter(
  counterField: string,
  dailyField: string,
): Promise<void> {
  const today = formatDate(new Date());
  const batch = db.batch();
  batch.set(
    db.collection('analytics').doc('counters'),
    {
      [counterField]: admin.firestore.FieldValue.increment(1),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  batch.set(
    db.collection('analytics').doc(`daily_${today}`),
    {
      [dailyField]: admin.firestore.FieldValue.increment(1),
      date: today,
    },
    { merge: true },
  );
  await batch.commit();
}
