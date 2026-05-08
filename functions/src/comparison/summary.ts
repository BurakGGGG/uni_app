import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';

const GROQ_API_KEY = defineSecret('GROQ_API_KEY');
const db = admin.firestore();

const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const GROQ_MODEL = 'llama-3.1-8b-instant';
const CACHE_TTL_MS = 24 * 60 * 60 * 1000;
const DAILY_AI_COMPARISON_LIMIT = 5;
const REQUEST_TIMEOUT_MS = 15000;

interface SummaryInput {
  comparisonType: 'university' | 'department' | 'city';
  entityA: { id: string; name: string };
  entityB: { id: string; name: string };
  comparisonData: Record<string, unknown>;
}

interface SummaryOutput {
  summary: string;
  cached: boolean;
  generatedAt: number;
}

export const generateComparisonSummary = onCall(
  {
    region: 'us-central1',
    timeoutSeconds: 30,
    memory: '256MiB',
    secrets: [GROQ_API_KEY],
    cors: true,
  },
  async (req): Promise<SummaryOutput> => {
    if (!req.auth) {
      throw new HttpsError('unauthenticated', 'Giriş gerekli.');
    }
    const uid = req.auth.uid;
    const input = req.data as SummaryInput | undefined;
    if (!input || !input.entityA || !input.entityB || !input.comparisonData) {
      throw new HttpsError('invalid-argument', 'Eksik karşılaştırma verisi.');
    }

    const usageRef = db.collection('users').doc(uid).collection('usageStats').doc('current');
    const today = formatDate(new Date());

    const usageSnap = await usageRef.get();
    const usageData = usageSnap.exists ? usageSnap.data() ?? {} : {};
    const lastResetDate = String(usageData.lastResetDate ?? today);
    const needsReset = lastResetDate !== today;
    const dailyAiComparisons = needsReset ? 0 : Number(usageData.dailyAiComparisons ?? 0);

    if (dailyAiComparisons >= DAILY_AI_COMPARISON_LIMIT) {
      throw new HttpsError('resource-exhausted', 'Günlük AI karşılaştırma limitine ulaşıldı.');
    }

    const entityIds = [input.entityA.id, input.entityB.id].sort();
    const cacheKey = makeHash({
      type: input.comparisonType,
      entityIds,
      payload: input.comparisonData,
    });

    const cacheRef = db.collection('aiSummaryCache').doc(cacheKey);
    const now = Date.now();
    const cacheSnap = await cacheRef.get();
    if (cacheSnap.exists) {
      const cache = cacheSnap.data() ?? {};
      const expiresAt = Number(cache.expiresAt ?? 0);
      const summary = typeof cache.summary === 'string' ? cache.summary : '';
      if (summary.length > 0 && expiresAt > now) {
        await upsertUsageStats(usageRef, usageData, {
          resetDaily: needsReset,
          incrementAiComparisons: true,
          today,
        });
        return {
          summary,
          cached: true,
          generatedAt: Number(cache.generatedAt ?? now),
        };
      }
    }

    const apiKey = GROQ_API_KEY.value();
    if (!apiKey) {
      throw new HttpsError('failed-precondition', 'GROQ_API_KEY ayarlı değil.');
    }

    const prompt = buildPrompt(input);
    const summary = await callGroq(apiKey, prompt);

    const generatedAt = Date.now();
    await cacheRef.set({
      comparisonType: input.comparisonType,
      entityIds,
      summary,
      generatedAt,
      expiresAt: generatedAt + CACHE_TTL_MS,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    await upsertUsageStats(usageRef, usageData, {
      resetDaily: needsReset,
      incrementAiComparisons: true,
      today,
    });

    return {
      summary,
      cached: false,
      generatedAt,
    };
  }
);

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
  prompt: { system: string; user: string }
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
      const text = await res.text();
      throw new Error(`Groq HTTP ${res.status}: ${text.slice(0, 200)}`);
    }

    const json = await res.json() as {
      choices?: Array<{ message?: { content?: string } }>;
    };
    const content = (json.choices?.[0]?.message?.content ?? '').trim();
    if (!content) {
      throw new Error('Groq empty response');
    }
    return content.slice(0, 600);
  } finally {
    clearTimeout(timer);
  }
}

async function upsertUsageStats(
  usageRef: admin.firestore.DocumentReference<admin.firestore.DocumentData>,
  usageData: admin.firestore.DocumentData,
  options: {
    resetDaily: boolean;
    incrementAiComparisons: boolean;
    today: string;
  }
): Promise<void> {
  const patch: Record<string, unknown> = {};

  if (!usageData.lastResetDate || options.resetDaily) {
    patch.lastResetDate = options.today;
    patch.dailyComparisons = 0;
    patch.dailyAiComparisons = 0;
    patch.dailyAiRecommendations = Number(usageData.dailyAiRecommendations ?? 0);
  }

  if (options.incrementAiComparisons) {
    patch.dailyAiComparisons = admin.firestore.FieldValue.increment(1);
  }

  if (Object.keys(patch).length === 0) return;
  await usageRef.set(patch, { merge: true });
}

function formatDate(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function makeHash(payload: unknown): string {
  return crypto.createHash('sha256').update(JSON.stringify(payload)).digest('hex').slice(0, 24);
}
