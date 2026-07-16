import { onRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';

const db = admin.firestore();

// Slug üretimi 8 karakter küçük harf+rakam (rules: [a-z0-9]{8});
// ileriye dönük esneklik için 4-32 aralığını kabul ediyoruz.
const SLUG_RE = /^[a-z0-9]{4,32}$/;

/** Landing sayfasına dönen, herkese açık item alanları (not'lar HARİÇ). */
function publicItem(raw: Record<string, unknown>): Record<string, unknown> {
  return {
    order: raw.order ?? 0,
    deptName: raw.deptName ?? '',
    uniName: raw.uniName ?? '',
    scoreType: raw.scoreType ?? null,
    baseScore: raw.baseScore ?? null,
    ranking: raw.ranking ?? null,
    quota: raw.quota ?? null,
    placedCount: raw.placedCount ?? null,
  };
}

/**
 * Paylaşım landing sayfası (unisec-e36e1.web.app/list/{slug}) için public
 * liste önizlemesi. Firestore'da App Check enforcement aktif olduğundan
 * web sayfası Firestore REST API'ye doğrudan erişemez; bu function Admin
 * SDK ile okur ve YALNIZCA herkese açık alanları döndürür.
 */
export const getPublicPreferenceList = onRequest(
  {
    region: 'europe-west1',
    timeoutSeconds: 10,
    memory: '256MiB',
    cors: true,
  },
  async (req, res): Promise<void> => {
    if (req.method !== 'GET') {
      res.status(405).json({ error: 'method-not-allowed' });
      return;
    }

    const slug =
      typeof req.query.slug === 'string' ? req.query.slug.trim() : '';
    if (!SLUG_RE.test(slug)) {
      res.status(400).json({ error: 'invalid-slug' });
      return;
    }

    try {
      const snap = await db
        .collection('preferenceLists')
        .where('shareSlug', '==', slug)
        .where('isPublic', '==', true)
        .limit(1)
        .get();

      if (snap.empty) {
        res.status(404).json({ error: 'not-found' });
        return;
      }

      const doc = snap.docs[0];
      const data = doc.data();

      // Görüntülenme sayacı — best effort, yanıtı bekletme.
      doc.ref
        .update({
          viewCount: admin.firestore.FieldValue.increment(1),
          lastViewedAt: admin.firestore.FieldValue.serverTimestamp(),
        })
        .catch((err) =>
          logger.warn('Web view increment failed', { slug, err: String(err) }),
        );

      const items = Array.isArray(data.items)
        ? data.items.map((it: Record<string, unknown>) => publicItem(it))
        : [];

      res.set('Cache-Control', 'public, max-age=60, s-maxage=120');
      res.json({
        title: data.title ?? '',
        description: data.description ?? '',
        userName: data.userName ?? 'Öğrenci',
        userPhotoUrl: data.userPhotoUrl ?? null,
        viewCount: data.viewCount ?? 0,
        items,
      });
    } catch (err) {
      logger.error('getPublicPreferenceList failed', {
        slug,
        err: String(err),
      });
      res.status(500).json({ error: 'internal' });
    }
  },
);
