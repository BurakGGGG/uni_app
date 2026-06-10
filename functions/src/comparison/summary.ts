import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import { logger } from 'firebase-functions';

const GROQ_API_KEY = defineSecret('GROQ_API_KEY');
const db = admin.firestore();

const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const GROQ_MODEL = 'llama-3.1-8b-instant';
const CACHE_TTL_MS = 24 * 60 * 60 * 1000;
const DAILY_AI_COMPARISON_LIMIT = 5;
// Regenerate: her unique (uid, karşılaştırma çifti) için 1 ek özet üretme hakkı.
// Günlük cap yerine per-pair limit — bir kullanıcı aynı çift için sınırsız regenerate
// yaparak token tüketemez. Farklı çiftler için her birinde 1 hak vardır.
const REQUEST_TIMEOUT_MS = 15000;

interface SummaryInput {
  comparisonType: 'university' | 'department' | 'city';
  entityA: { id: string; name: string };
  entityB: { id: string; name: string };
  comparisonData: Record<string, unknown>;
  regenerate?: boolean;
}

interface SummaryOutput {
  summary: string;
  cached: boolean;
  generatedAt: number;
}

export const generateComparisonSummary = onCall(
  {
    region: 'europe-west1',             // ← bölge tutarlı (Türkiye için)
    timeoutSeconds: 20,                 // ← 30 → 20 (timeout pyramid: Client 25s > Function 20s > Groq 15s)
    memory: '256MiB',
    secrets: [GROQ_API_KEY],
    cors: true,
    // enforceAppCheck: true,           // DEV: client'ta App Check başlatılana kadar kapalı.
    //                                  // Production sprint'te tekrar aç + main.dart'ta
    //                                  // FirebaseAppCheck.instance.activate(...) ekle.
  },
  async (req): Promise<SummaryOutput> => {
    if (!req.auth) {
      throw new HttpsError('unauthenticated', 'Giriş gerekli.');
    }
    const uid = req.auth.uid;
    const input = req.data as SummaryInput | undefined;
    if (!input?.entityA || !input?.entityB || !input?.comparisonData) {
      throw new HttpsError('invalid-argument', 'Eksik karşılaştırma verisi.');
    }

    const usageRef = db.collection('users').doc(uid).collection('usageStats').doc('current');
    const today = formatDate(new Date());

    // ─── ATOMIC QUOTA CHECK + INCREMENT ─────────────────────────
    // Transaction ile race condition'ı engelliyoruz.
    let needsToCallGroq = false;
    let cacheKey = '';
    let cachedSummary: { summary: string; generatedAt: number } | null = null;

    const entityIds = [input.entityA.id, input.entityB.id].sort();
    cacheKey = makeHash({
      type: input.comparisonType,
      entityIds,
      payload: input.comparisonData,
    });
    const cacheRef = db.collection('aiSummaryCache').doc(cacheKey);

    try {
      await db.runTransaction(async (tx) => {
        const usageSnap = await tx.get(usageRef);
        const cacheSnap = await tx.get(cacheRef);

        const usageData = usageSnap.exists ? usageSnap.data() ?? {} : {};
        const lastResetDate = String(usageData.lastResetDate ?? today);
        const needsReset = lastResetDate !== today;
        const dailyAiComparisons = needsReset ? 0 : Number(usageData.dailyAiComparisons ?? 0);

        // Cache hit kontrolü — regenerate=true ise cache atla
        if (cacheSnap.exists && !input.regenerate) {
          const cache = cacheSnap.data() ?? {};
          const expiresAt = Number(cache.expiresAt ?? 0);
          const summary = typeof cache.summary === 'string' ? cache.summary : '';
          if (summary.length > 0 && expiresAt > Date.now()) {
            cachedSummary = { summary, generatedAt: Number(cache.generatedAt ?? Date.now()) };
            // ✅ Cache hit'te quota DÜŞMÜYOR (business decision)
            return;
          }
        }

        // Per-pair regenerate kontrolü — kullanıcı bu karşılaştırma çifti için
        // daha önce regenerate yapmış mı? Cache doc'undaki regeneratedBy map'inde tutuyoruz.
        if (input.regenerate && cacheSnap.exists) {
          const cache = cacheSnap.data() ?? {};
          const regeneratedBy = (cache.regeneratedBy ?? {}) as Record<string, boolean>;
          logger.info('Regenerate check', {
            uid,
            cacheKey,
            hasRegeneratedByMap: !!cache.regeneratedBy,
            alreadyUsedByThisUid: regeneratedBy[uid] === true,
            allRegenerators: Object.keys(regeneratedBy),
          });
          if (regeneratedBy[uid] === true) {
            throw new HttpsError(
              'already-exists',
              'Bu karşılaştırma için yeniden üretme hakkını zaten kullandın.',
            );
          }
        }

        // Cache miss — quota kontrolü + atomik artırım
        if (!input.regenerate && dailyAiComparisons >= DAILY_AI_COMPARISON_LIMIT) {
          throw new HttpsError(
            'resource-exhausted',
            `Günlük AI karşılaştırma limiti (${DAILY_AI_COMPARISON_LIMIT}) doldu. Yarın tekrar dene.`,
          );
        }

        // Quota'yı atomik olarak şimdi artır (regenerate günlük quota'yı tüketmez —
        // sadece per-pair limit ile sınırlı, server-side enforcement yapıyoruz).
        const patch = buildUsagePatch(usageData, {
          resetDaily: needsReset,
          increment: !input.regenerate,
          today,
        });

        tx.set(usageRef, patch, { merge: true });

        needsToCallGroq = true;
      });
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      logger.error('Quota check transaction failed', { uid, err });
      throw new HttpsError('internal', 'Geçici bir sorun oluştu. Lütfen tekrar dene.');
    }

    // Cache hit → erken dönüş
    if (cachedSummary) {
      await incrementAnalyticsCounter('totalAiComparisons', 'aiComparisons').catch((e) =>
        logger.warn('Analytics increment failed', { e }),
      );
      await logSummaryRequest(uid, input, true).catch((e) =>
        logger.warn('Cache hit log failed', { e }),
      );
      return {
        summary: (cachedSummary as { summary: string; generatedAt: number }).summary,
        cached: true,
        generatedAt: (cachedSummary as { summary: string; generatedAt: number }).generatedAt,
      };
    }

    // ─── GROQ API ÇAĞRISI ────────────────────────────────────────
    if (!needsToCallGroq) {
      throw new HttpsError('internal', 'Beklenmeyen durum oluştu.');
    }

    const apiKey = GROQ_API_KEY.value();
    if (!apiKey) {
      logger.error('GROQ_API_KEY missing — running in degraded mode', { uid });
      throw new HttpsError('failed-precondition', 'AI servisi şu anda kullanılamıyor.');
    }

    let summary: string;
    try {
      const prompt = buildPrompt(input);
      summary = await callGroq(apiKey, prompt);
    } catch (err) {
      // Quota'yı düşürdük ama Groq başarısız oldu — kullanıcıya bilgi ver
      logger.error('Groq call failed', { uid, err: String(err) });
      throw new HttpsError(
        'unavailable',
        'AI servisi geçici olarak yanıt vermiyor. Birkaç saniye sonra tekrar dene.',
      );
    }

    const generatedAt = Date.now();
    await cacheRef.set(
      {
        comparisonType: input.comparisonType,
        entityIds,
        summary,
        generatedAt,
        expiresAt: generatedAt + CACHE_TTL_MS,
        // TTL policy için Timestamp formatı (Firestore TTL number değil Timestamp ister).
        // expiresAt (number) cache hit logic'i tarafından kullanılır; expireAt (Timestamp)
        // Firestore'un TTL job'u tarafından doc'u otomatik siler.
        expireAt: admin.firestore.Timestamp.fromMillis(generatedAt + CACHE_TTL_MS),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        // Regenerate ise bu uid için 'kullanıldı' işareti koy.
        // Nested map — Firestore merge: true ile mevcut regeneratedBy map'ine
        // sadece bu uid'i ekler, diğer uid'leri korur.
        ...(input.regenerate ? { regeneratedBy: { [uid]: true } } : {}),
      },
      { merge: true },
    );

    if (input.regenerate) {
      logger.info('Regenerate cache write OK', { uid, cacheKey });
    }

    await incrementAnalyticsCounter('totalAiComparisons', 'aiComparisons').catch((e) =>
      logger.warn('Analytics increment failed', { e }),
    );
    await logSummaryRequest(uid, input, false).catch((e) =>
      logger.warn('Cache miss log failed', { e }),
    );

    return {
      summary,
      cached: false,
      generatedAt,
    };
  },
);

// ─── YARDIMCI FONKSİYONLAR ─────────────────────────────────────

function buildUsagePatch(
  usageData: admin.firestore.DocumentData,
  options: { resetDaily: boolean; increment: boolean; today: string },
): Record<string, unknown> {
  const patch: Record<string, unknown> = {};

  if (!usageData.lastResetDate || options.resetDaily) {
    patch.lastResetDate = options.today;
    patch.dailyComparisons = 0;
    patch.dailyAiComparisons = options.increment ? 1 : 0;
    patch.dailyAiRecommendations = Number(usageData.dailyAiRecommendations ?? 0);
  } else if (options.increment) {
    patch.dailyAiComparisons = admin.firestore.FieldValue.increment(1);
  }

  return patch;
}

function buildPrompt(input: SummaryInput): { system: string; user: string } {
  const system = `Sen bir Türk üniversite karşılaştırma danışmanısın.
Yanıtın doğal ve kısa Türkçe olmalı.
Sadece verilen veriye dayan, veri uydurma.
Çıktı SADECE düz metin olsun, markdown veya JSON verme.`;

  const user = `İki Türk üniversitesini karşılaştırıyoruz: ${input.entityA.name} ve ${input.entityB.name}.
Veriler: ${JSON.stringify(input.comparisonData)}
Lütfen 2-3 cümle Türkçe karşılaştırma özeti yaz.
Öğrenci perspektifinden, hangi öğrenciye hangisi daha uygun olur?`;

  return { system, user };
}

async function callGroq(
  apiKey: string,
  prompt: { system: string; user: string },
): Promise<string> {
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
        temperature: 0.4,
        max_tokens: 220,
        messages: [
          { role: 'system', content: prompt.system },
          { role: 'user', content: prompt.user },
        ],
      }),
      signal: ctrl.signal,
    });

    if (!res.ok) {
      // ❗ Kullanıcıya gönderilen mesajda Groq detayı SIZMIYOR
      const text = await res.text();
      logger.error('Groq HTTP error', { status: res.status, body: text.slice(0, 500) });
      throw new Error(`Groq HTTP ${res.status}`);
    }

    const json = (await res.json()) as {
      choices?: Array<{ message?: { content?: string } }>;
    };
    const content = (json.choices?.[0]?.message?.content ?? '').trim();
    if (!content) {
      logger.warn('Groq empty response');
      throw new Error('Groq empty response');
    }
    return content.slice(0, 600);
  } finally {
    clearTimeout(timer);
  }
}

function formatDate(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
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

function makeHash(payload: unknown): string {
  return crypto.createHash('sha256').update(JSON.stringify(payload)).digest('hex').slice(0, 24);
}

async function logSummaryRequest(
  uid: string,
  input: SummaryInput,
  cached: boolean,
): Promise<void> {
  await db.collection('aiSummaryLogs').add({
    userId: uid,
    comparisonType: input.comparisonType,
    entityAId: input.entityA.id,
    entityBId: input.entityB.id,
    cacheHit: cached,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    // ❗ TTL için — 30 gün sonra otomatik silinir (Firestore TTL policy gerekli)
    expireAt: admin.firestore.Timestamp.fromMillis(Date.now() + 30 * 24 * 60 * 60 * 1000),
  });
}
