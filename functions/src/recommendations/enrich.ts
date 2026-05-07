import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';

const GROQ_API_KEY = defineSecret('GROQ_API_KEY');

const db = admin.firestore();

const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const GROQ_MODEL = 'llama-3.1-8b-instant';
const CACHE_COLLECTION = 'recommendationEnrichments';
const CACHE_TTL_HOURS = 24;
const MAX_INPUT_DEPTS = 8;
const TOP_FOR_REASONING = 3; // Sadece ilk 3 öneriye kişisel reasoning
const REQUEST_TIMEOUT_MS = 12000;

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

    try {
      const cached = await cacheRef.get();
      if (cached.exists) {
        const cd = cached.data();
        if (cd && cd.summary && Array.isArray(cd.items)) {
          const ageMs = Date.now() - (cd.generatedAt ?? 0);
          if (ageMs < CACHE_TTL_HOURS * 3600 * 1000) {
            return {
              summary: cd.summary,
              items: cd.items,
              cached: true,
              generatedAt: cd.generatedAt,
            };
          }
        }
      }
    } catch (e) {
      console.warn('Cache read failed, continuing:', e);
    }

    // ── Groq çağrısı ──
    const apiKey = GROQ_API_KEY.value();
    if (!apiKey) {
      throw new HttpsError('failed-precondition', 'GROQ_API_KEY ayarlı değil.');
    }

    const prompt = buildPrompt(userTags, depts);

    let llmJson: { summary?: string; items?: EnrichedItem[] } | null = null;
    try {
      llmJson = await callGroq(apiKey, prompt);
    } catch (e) {
      console.error('Groq call failed:', e);
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

    // ── Cache yaz ──
    try {
      await cacheRef.set({
        summary: result.summary,
        items: result.items,
        generatedAt: result.generatedAt,
        userId: uid,
      });
    } catch (e) {
      console.warn('Cache write failed:', e);
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
