/**
 * Sprint 11 (6.4) — Place sayım denormalizasyonu için TEK SEFERLİK backfill.
 *
 * `recomputePlaceCount` trigger'ı bundan sonra otomatik çalışır, ancak
 * mevcut universities dokümanlarında `placeCount` / `placeBreakdown` alanları
 * yok. Bu script tek seferlik olarak hepsini doldurur.
 *
 * Çalıştırma:
 *
 *   # 1) Auth (bir kerelik):
 *   gcloud auth application-default login
 *
 *   # 2) Build + run:
 *   cd functions
 *   npm run build
 *   node lib/scripts/backfill_place_count.js
 *
 * (İsteğe bağlı) Project ID env var ile override edilebilir:
 *
 *   GCLOUD_PROJECT=unisec-e36e1 node lib/scripts/backfill_place_count.js
 *
 * NOT: Bu dosya `functions/src/index.ts`'ten export edilmediği için
 * `firebase deploy --only functions` ile production'a deploy edilmez.
 */

import * as admin from 'firebase-admin';

const PROJECT_ID = process.env.GCLOUD_PROJECT ?? 'unisec-e36e1';

async function main(): Promise<void> {
  // Application Default Credentials (gcloud auth application-default login)
  // veya GOOGLE_APPLICATION_CREDENTIALS env var ile çalışır.
  admin.initializeApp({ projectId: PROJECT_ID });
  const db = admin.firestore();

  console.log(`▶  Backfill başlıyor (project: ${PROJECT_ID})`);
  console.log('   Universities koleksiyonu okunuyor...');

  const unisSnap = await db.collection('universities').get();
  console.log(`   ${unisSnap.size} üniversite bulundu.\n`);

  let processed = 0;
  let totalPlaces = 0;
  const errors: Array<{ uniId: string; err: string }> = [];

  for (const uniDoc of unisSnap.docs) {
    const uniId = uniDoc.id;
    try {
      const placesSnap = await db
        .collection('places')
        .where('universityId', '==', uniId)
        .get();

      const breakdown: Record<string, number> = {};
      for (const placeDoc of placesSnap.docs) {
        const type = String(placeDoc.data().type ?? 'other');
        breakdown[type] = (breakdown[type] ?? 0) + 1;
      }

      await uniDoc.ref.set(
        {
          placeCount: placesSnap.size,
          placeBreakdown: breakdown,
          placeCountUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      processed += 1;
      totalPlaces += placesSnap.size;

      const typesStr =
        Object.keys(breakdown).length > 0
          ? Object.entries(breakdown)
              .map(([k, v]) => `${k}:${v}`)
              .join(', ')
          : '(yok)';
      console.log(
        `   [${processed.toString().padStart(3)}/${unisSnap.size}] ${uniId.padEnd(28)} → ${placesSnap.size} place [${typesStr}]`,
      );
    } catch (err) {
      console.error(`   ❌ Hata: ${uniId}:`, err);
      errors.push({ uniId, err: String(err) });
    }
  }

  console.log('\n────────────────────────────────────────');
  console.log(`✅ Backfill tamamlandı.`);
  console.log(`   İşlenen üniversite: ${processed}/${unisSnap.size}`);
  console.log(`   Toplam place sayımı: ${totalPlaces}`);
  console.log(`   Hata: ${errors.length}`);
  if (errors.length > 0) {
    console.log(`   Hatalı uniId'ler:`);
    for (const e of errors) {
      console.log(`     - ${e.uniId}: ${e.err}`);
    }
  }
  console.log('────────────────────────────────────────\n');

  // Admin SDK'nın açtığı handle'ları kapat ki node process exit etsin
  await admin.app().delete();
}

main().catch((err) => {
  console.error('Script çalıştırılamadı:', err);
  process.exit(1);
});
