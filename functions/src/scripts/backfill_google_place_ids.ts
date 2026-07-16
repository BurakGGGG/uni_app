/**
 * Tek seferlik googlePlaceId backfill script'i.
 *
 * Girdi: lib/scripts/osym/v3_resolve_place_ids.py çıktısı olan
 * lib/scripts/osym/v3_place_ids.json ({ appId: placeId }).
 * Elle kontrol raporu (v3_place_id_report.md) onaylanmadan çalıştırma.
 *
 * Varsayılan olarak dry-run çalışır ve Firestore'a yazmaz:
 *
 *   cd functions
 *   npm run backfill:google-place-ids
 *
 * Gerçek yazım için:
 *
 *   DRY_RUN=false npm run backfill:google-place-ids
 */

import * as fs from 'fs';
import * as path from 'path';
import * as admin from 'firebase-admin';

const PROJECT_ID = process.env.GCLOUD_PROJECT ?? 'unisec-e36e1';
const DRY_RUN = process.env.DRY_RUN !== 'false';
const IDS_FILE =
  process.env.IDS_FILE ??
  path.resolve(__dirname, '../../../lib/scripts/osym/v3_place_ids.json');

async function main(): Promise<void> {
  const raw = fs.readFileSync(IDS_FILE, 'utf8');
  const placeIds = JSON.parse(raw) as Record<string, string>;
  const entries = Object.entries(placeIds).filter(
    ([uniId, placeId]) =>
      typeof uniId === 'string' &&
      uniId.length > 0 &&
      typeof placeId === 'string' &&
      placeId.length > 0,
  );

  admin.initializeApp({ projectId: PROJECT_ID });
  const db = admin.firestore();

  console.log(`▶ googlePlaceId backfill başlıyor (project: ${PROJECT_ID})`);
  console.log(`   Mode: ${DRY_RUN ? 'DRY_RUN' : 'WRITE'}`);
  console.log(`   Girdi: ${IDS_FILE} (${entries.length} üniversite)`);

  let written = 0;
  let missing = 0;
  const batch = db.batch();
  for (const [uniId, placeId] of entries) {
    const ref = db.collection('universities').doc(uniId);
    const snap = await ref.get();
    if (!snap.exists) {
      console.warn(`   !! universities/${uniId} bulunamadı, atlanıyor.`);
      missing += 1;
      continue;
    }
    if (!DRY_RUN) {
      batch.set(ref, { googlePlaceId: placeId }, { merge: true });
    }
    written += 1;
  }

  if (!DRY_RUN && written > 0) {
    await batch.commit();
  }

  console.log('────────────────────────────────────────');
  console.log('✅ googlePlaceId backfill tamamlandı.');
  console.log(`   Yazılan: ${written}${DRY_RUN ? ' (dry-run)' : ''}`);
  console.log(`   Firestore'da bulunamayan: ${missing}`);
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
