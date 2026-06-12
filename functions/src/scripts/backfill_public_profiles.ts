/**
 * Tek seferlik publicProfiles backfill script'i.
 *
 * Varsayılan olarak dry-run çalışır ve Firestore'a yazmaz:
 *
 *   cd functions
 *   npm run build
 *   node lib/scripts/backfill_public_profiles.js
 *
 * Gerçek yazım için:
 *
 *   DRY_RUN=false node lib/scripts/backfill_public_profiles.js
 *
 * Opsiyonel:
 *
 *   GCLOUD_PROJECT=unisec-e36e1 BATCH_SIZE=400 DRY_RUN=false node lib/scripts/backfill_public_profiles.js
 */

import * as admin from 'firebase-admin';
import { buildPublicProfileData } from '../auth/public_profile_payload';

const PROJECT_ID = process.env.GCLOUD_PROJECT ?? 'unisec-e36e1';
const DRY_RUN = process.env.DRY_RUN !== 'false';
const rawBatchSize = Number(process.env.BATCH_SIZE ?? '400');
const BATCH_SIZE = Math.max(
  1,
  Math.min(500, Number.isFinite(rawBatchSize) ? rawBatchSize : 400),
);

async function main(): Promise<void> {
  admin.initializeApp({ projectId: PROJECT_ID });
  const db = admin.firestore();

  console.log(`▶ publicProfiles backfill başlıyor (project: ${PROJECT_ID})`);
  console.log(`   Mode: ${DRY_RUN ? 'DRY_RUN' : 'WRITE'}`);
  console.log(`   Batch size: ${BATCH_SIZE}`);

  let processed = 0;
  let written = 0;
  let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | undefined;

  while (true) {
    let query: FirebaseFirestore.Query = db
      .collection('users')
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(BATCH_SIZE);

    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const usersSnap = await query.get();
    if (usersSnap.empty) break;

    const batch = db.batch();
    for (const userDoc of usersSnap.docs) {
      const publicProfileRef = db.collection('publicProfiles').doc(userDoc.id);
      const publicProfileData = buildPublicProfileData(userDoc.data());

      if (!DRY_RUN) {
        batch.set(publicProfileRef, publicProfileData);
      }
    }

    if (!DRY_RUN) {
      await batch.commit();
      written += usersSnap.size;
    }

    processed += usersSnap.size;
    lastDoc = usersSnap.docs[usersSnap.docs.length - 1];
    console.log(
      `   İşlenen: ${processed} | Yazılan: ${written}${DRY_RUN ? ' (dry-run)' : ''}`,
    );

    if (usersSnap.size < BATCH_SIZE) break;
  }

  console.log('────────────────────────────────────────');
  console.log('✅ publicProfiles backfill tamamlandı.');
  console.log(`   İşlenen user dokümanı: ${processed}`);
  console.log(`   Yazılan publicProfiles: ${written}`);
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
