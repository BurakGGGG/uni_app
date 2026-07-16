/**
 * Tek seferlik rozet backfill script'i — mevcut kullanıcılara yeni katalog
 * kademelerini (yorum/beğeni/favori/üyelik/verified/profil/early adopter)
 * verir. Engagement sayaçları (keşif/karşılaştırma/paylaşım/streak) sıfırdan
 * başlar; onlar backfill edilmez.
 *
 * Varsayılan olarak dry-run çalışır ve Firestore'a yazmaz:
 *
 *   cd functions
 *   npm run build
 *   node lib/scripts/backfill_badges.js
 *
 * Gerçek yazım için:
 *
 *   DRY_RUN=false node lib/scripts/backfill_badges.js
 */

import * as admin from 'firebase-admin';

const PROJECT_ID = process.env.GCLOUD_PROJECT ?? 'unisec-e36e1';
const DRY_RUN = process.env.DRY_RUN !== 'false';
const rawBatchSize = Number(process.env.BATCH_SIZE ?? '200');
const BATCH_SIZE = Math.max(
  1,
  Math.min(500, Number.isFinite(rawBatchSize) ? rawBatchSize : 200),
);

async function main(): Promise<void> {
  admin.initializeApp({ projectId: PROJECT_ID });
  const db = admin.firestore();

  // admin.initializeApp'ten SONRA import edilmeli (modül db handle'ı açıyor).
  const { computeEarnedBadges, awardBadgesIfMissing } = await import(
    '../badges/award_badges'
  );

  console.log(`▶ Rozet backfill başlıyor (project: ${PROJECT_ID})`);
  console.log(`   Mode: ${DRY_RUN ? 'DRY_RUN' : 'WRITE'}`);

  let processed = 0;
  let usersAwarded = 0;
  let badgesAwarded = 0;
  let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | undefined;
  let hasMore = true;

  while (hasMore) {
    let query: FirebaseFirestore.Query = db
      .collection('users')
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(BATCH_SIZE);

    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const usersSnap = await query.get();
    if (usersSnap.empty) break;

    for (const userDoc of usersSnap.docs) {
      const earned = await computeEarnedBadges(userDoc.id);
      const existing = (userDoc.data().badges ?? {}) as Record<
        string,
        unknown
      >;
      const missing = earned.filter((id) => existing[id] == null);

      if (missing.length > 0) {
        console.log(
          `   ${userDoc.id}: +${missing.length} rozet [${missing.join(', ')}]${
            DRY_RUN ? ' (dry-run)' : ''
          }`,
        );
        if (!DRY_RUN) {
          await awardBadgesIfMissing(userDoc.id, missing);
        }
        usersAwarded += 1;
        badgesAwarded += missing.length;
      }
      processed += 1;
    }

    lastDoc = usersSnap.docs[usersSnap.docs.length - 1];
    hasMore = usersSnap.size === BATCH_SIZE;
    console.log(`   İşlenen: ${processed}`);
  }

  console.log('────────────────────────────────────────');
  console.log('✅ Rozet backfill tamamlandı.');
  console.log(`   İşlenen kullanıcı: ${processed}`);
  console.log(
    `   Rozet ${DRY_RUN ? 'verilecek' : 'verilen'} kullanıcı: ${usersAwarded}`,
  );
  console.log(
    `   ${DRY_RUN ? 'Verilecek' : 'Verilen'} toplam rozet: ${badgesAwarded}`,
  );
  console.log('────────────────────────────────────────');

  await admin.app().delete();
}

main().catch(async (err) => {
  console.error('Script çalıştırılamadı:', err);
  try {
    await admin.app().delete();
  } catch {
    // App initialize edilemediyse kapatılacak handle yok.
  }
  process.exit(1);
});
