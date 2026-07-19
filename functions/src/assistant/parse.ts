import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';

// Üni sohbeti — Faz B: cihazdaki kural ayrıştırıcının çözemediği cümle
// Pro kullanıcı için buraya gelir. LLM yalnız SEMANTİK çıkarım yapar
// (puan türü / sayılar / şehir-bölüm ADLARI); istemci bu adları kendi
// kapalı kümelerine oturtur (grounding) — uydurulan hiçbir değer filtreye
// giremez. enrich.ts iskeletinin kopyasıdır; girdiler benzersiz olduğu
// için cache YOKTUR.

const GROQ_API_KEY = defineSecret('GROQ_API_KEY');

const db = admin.firestore();

const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const GROQ_MODEL = 'llama-3.1-8b-instant';
const REQUEST_TIMEOUT_MS = 8000;
const MAX_UTTERANCE_LEN = 280;
const DAILY_PARSE_LIMIT = 20;
const PARSE_RATE_WINDOW_MS = 60 * 1000;
const PARSE_RATE_LIMIT = 10;
const MAX_LIST_ITEMS = 5;
const MAX_ITEM_LEN = 40;

// ─── Tipler ────────────────────────────────────────────────────
interface ParseResponse {
  scoreType: string | null;
  rank: number | null;
  score: number | null;
  cities: string[];
  uniTypes: string[];
  languages: string[];
  programTypes: string[];
  onlyScholarship: boolean | null;
  depts: string[];
  generatedAt: number;
}

const SCORE_TYPES = new Set(['TYT', 'SAY', 'EA', 'SÖZ', 'DİL']);
const UNI_TYPES = new Set(['Devlet', 'Vakıf']);
const LANGUAGES = new Set(['Türkçe', 'İngilizce']);
const PROGRAM_TYPES = new Set(['Lisans', 'Önlisans']);

// ─── Cloud Function ────────────────────────────────────────────
export const parseWizardUtterance = onCall(
  {
    region: 'us-central1',
    secrets: [GROQ_API_KEY],
    timeoutSeconds: 15,
    memory: '256MiB',
    cors: true,
    enforceAppCheck: true,
  },
  async (req): Promise<ParseResponse> => {
    if (!req.auth) {
      throw new HttpsError('unauthenticated', 'Giriş gerekli.');
    }
    const uid = req.auth.uid;

    const utterance = String(
      (req.data as { utterance?: unknown } | undefined)?.utterance ?? '',
    ).trim();
    if (!utterance || utterance.length > MAX_UTTERANCE_LEN) {
      throw new HttpsError('invalid-argument', 'Geçersiz cümle.');
    }

    const usageRef = db
      .collection('users')
      .doc(uid)
      .collection('usageStats')
      .doc('current');
    const subscriptionRef = db.collection('subscriptions').doc(uid);
    const today = formatDate(new Date());
    const nowMs = Date.now();

    // ── Atomik entitlement + rate limit + günlük kota ──
    try {
      await db.runTransaction(async (tx) => {
        const subscriptionSnap = await tx.get(subscriptionRef);
        const usageSnap = await tx.get(usageRef);

        const isAdmin = req.auth?.token.admin === true;
        if (!isAdmin && !hasActiveProSubscription(subscriptionSnap.data())) {
          throw new HttpsError(
            'permission-denied',
            'Doğal dil asistanı için Pro abonelik gerekli.',
          );
        }

        const usageData = usageSnap.exists ? usageSnap.data() ?? {} : {};

        // Dakikalık pencere
        const windowStart = finiteMillis(usageData.aiParseWindowStartAt);
        const windowCount = safeCounter(usageData.aiParseWindowCount);
        const windowExpired =
          windowStart <= 0 ||
          windowStart > nowMs ||
          nowMs - windowStart >= PARSE_RATE_WINDOW_MS;
        if (!windowExpired && windowCount >= PARSE_RATE_LIMIT) {
          throw new HttpsError(
            'resource-exhausted',
            'Çok hızlı yazıyorsun — birkaç saniye sonra tekrar dene.',
          );
        }

        // Günlük kota
        const lastReset =
          typeof usageData.lastAiParseResetDate === 'string'
            ? usageData.lastAiParseResetDate
            : '';
        const daily =
          lastReset === today ? safeCounter(usageData.dailyAiParses) : 0;
        if (daily >= DAILY_PARSE_LIMIT) {
          throw new HttpsError(
            'resource-exhausted',
            `Günlük doğal dil hakkı (${DAILY_PARSE_LIMIT}) doldu. Yarın tekrar dene.`,
          );
        }

        const nextWindowStart = windowExpired ? nowMs : windowStart;
        tx.set(
          usageRef,
          {
            aiParseWindowStartAt: nextWindowStart,
            aiParseWindowCount: windowExpired ? 1 : windowCount + 1,
            dailyAiParses: daily + 1,
            lastAiParseResetDate: today,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      });
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      logger.error('Parse quota transaction failed', { uid, err: String(e) });
      throw new HttpsError('internal', 'Geçici bir sorun oluştu. Lütfen tekrar dene.');
    }

    // ── Groq çağrısı ──
    const apiKey = GROQ_API_KEY.value();
    if (!apiKey) {
      throw new HttpsError('failed-precondition', 'GROQ_API_KEY ayarlı değil.');
    }

    let llmJson: Record<string, unknown> | null = null;
    try {
      llmJson = await callGroq(apiKey, utterance);
    } catch (e) {
      logger.error('Groq parse call failed', { uid, err: String(e) });
      throw new HttpsError('unavailable', 'Asistan şu an yanıt veremiyor.');
    }
    if (!llmJson) {
      throw new HttpsError('internal', 'AI yanıtı geçersiz format.');
    }

    return sanitizeResponse(llmJson);
  },
);

// ─── Prompt + Groq ─────────────────────────────────────────────
function buildPrompt(utterance: string): { system: string; user: string } {
  const system = `Sen bir Türk YKS tercih asistanının bilgi çıkarım motorusun.
Görevin: öğrencinin cümlesinden yapılandırılmış alanları çıkarmak.
Cevabın SADECE geçerli JSON olmalı; başka metin yazma.
Cümlede geçmeyen alan için null / boş dizi döndür — ASLA tahmin uydurma.

Alanlar:
- scoreType: "SAY" | "EA" | "SÖZ" | "DİL" | "TYT" | null (sayısal→SAY, eşit ağırlık→EA, sözel→SÖZ, yabancı dil→DİL, önlisans/2 yıllık→TYT)
- rank: başarı sıralaması (tam sayı, "80 bin"→80000) | null
- score: yerleştirme puanı (100-560 arası) | null
- cities: Türkiye il adları, resmî yazımla (örn. "İstanbul", "Şanlıurfa")
- uniTypes: "Devlet" ve/veya "Vakıf" (özel üniversite→Vakıf)
- languages: "Türkçe" ve/veya "İngilizce" (öğretim dili)
- programTypes: "Lisans" ve/veya "Önlisans"
- onlyScholarship: yalnız burslu isteniyorsa true, aksi null
- depts: bölüm/alan adları resmî Türkçe yazımla (meslekleri bölüme çevir: doktor→Tıp, avukat→Hukuk, yazılımcı→Bilgisayar Mühendisliği)`;

  const user = `Öğrencinin cümlesi:
"""${utterance}"""

JSON şeması:
{
  "scoreType": "SAY" | "EA" | "SÖZ" | "DİL" | "TYT" | null,
  "rank": number | null,
  "score": number | null,
  "cities": ["..."],
  "uniTypes": ["..."],
  "languages": ["..."],
  "programTypes": ["..."],
  "onlyScholarship": true | null,
  "depts": ["..."]
}`;

  return { system, user };
}

async function callGroq(
  apiKey: string,
  utterance: string,
): Promise<Record<string, unknown> | null> {
  const prompt = buildPrompt(utterance);
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
        temperature: 0, // Çıkarım görevi — yaratıcılık istenmez
        max_tokens: 300,
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

    return JSON.parse(content) as Record<string, unknown>;
  } finally {
    clearTimeout(timer);
  }
}

// ─── Sanitizasyon ──────────────────────────────────────────────
function sanitizeResponse(raw: Record<string, unknown>): ParseResponse {
  const scoreType =
    typeof raw.scoreType === 'string' && SCORE_TYPES.has(raw.scoreType)
      ? raw.scoreType
      : null;

  const rank = intInRange(raw.rank, 1, 4_000_000);
  const score = numInRange(raw.score, 100, 560);

  return {
    scoreType,
    rank,
    score,
    cities: stringList(raw.cities),
    uniTypes: stringList(raw.uniTypes).filter((v) => UNI_TYPES.has(v)),
    languages: stringList(raw.languages).filter((v) => LANGUAGES.has(v)),
    programTypes: stringList(raw.programTypes).filter((v) =>
      PROGRAM_TYPES.has(v),
    ),
    onlyScholarship: raw.onlyScholarship === true ? true : null,
    depts: stringList(raw.depts),
    generatedAt: Date.now(),
  };
}

function stringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .filter((v): v is string => typeof v === 'string')
    .map((v) => v.trim().slice(0, MAX_ITEM_LEN))
    .filter((v) => v.length > 0)
    .slice(0, MAX_LIST_ITEMS);
}

function intInRange(value: unknown, min: number, max: number): number | null {
  const n = Number(value);
  if (!Number.isFinite(n)) return null;
  const i = Math.round(n);
  return i >= min && i <= max ? i : null;
}

function numInRange(value: unknown, min: number, max: number): number | null {
  const n = Number(value);
  if (!Number.isFinite(n)) return null;
  return n >= min && n <= max ? n : null;
}

// ─── Yardımcılar (enrich.ts ile aynı desen) ────────────────────
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

function formatDate(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function safeCounter(value: unknown): number {
  const n = Number(value);
  if (!Number.isFinite(n) || n < 0) return 0;
  return Math.floor(n);
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
