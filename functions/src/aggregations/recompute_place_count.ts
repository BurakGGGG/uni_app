import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Sprint 11 (Karşılaştırma 6.4) — Place sayım denormalizasyonu
 *
 * `places/{placeId}` koleksiyonunda herhangi bir create/update/delete olduğunda,
 * etkilenen üniversitenin `universities/{uniId}` dokümanındaki
 * `placeCount` ve `placeBreakdown` alanlarını yeniden hesaplar.
 *
 * Bu, karşılaştırma feature'ının her seferinde tüm `places` koleksiyonunu
 * okumasını engeller (avg. 50-300 read → 0 read).
 */
export const recomputePlaceCount = onDocumentWritten(
  {
    region: 'europe-west1',
    document: 'places/{placeId}',
  },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    // Etkilenen üniversite(ler)
    // Place'in universityId'si değişmişse hem eski hem yeni uni'yi recompute et
    const affectedUniversityIds = new Set<string>();
    const beforeUid = before?.universityId as string | undefined;
    const afterUid = after?.universityId as string | undefined;
    if (beforeUid) affectedUniversityIds.add(beforeUid);
    if (afterUid) affectedUniversityIds.add(afterUid);

    if (affectedUniversityIds.size === 0) {
      logger.warn('recomputePlaceCount: no universityId in event', {
        placeId: event.params.placeId,
      });
      return;
    }

    for (const universityId of affectedUniversityIds) {
      try {
        await recomputeForUniversity(universityId);
      } catch (err) {
        logger.error('recomputePlaceCount failed', { universityId, err });
        // Re-throw etmiyoruz — diğer üniversiteler için de denesin
      }
    }
  },
);

async function recomputeForUniversity(universityId: string): Promise<void> {
  const snap = await db
    .collection('places')
    .where('universityId', '==', universityId)
    .get();

  const breakdown: Record<string, number> = {};
  for (const doc of snap.docs) {
    const type = String(doc.data().type ?? 'other');
    breakdown[type] = (breakdown[type] ?? 0) + 1;
  }

  await db.collection('universities').doc(universityId).set(
    {
      placeCount: snap.size,
      placeBreakdown: breakdown,
      placeCountUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  logger.info('placeCount recomputed', {
    universityId,
    placeCount: snap.size,
    typeCount: Object.keys(breakdown).length,
  });
}
