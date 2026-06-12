/**
 * Admin custom claim migration/management script.
 *
 * Legacy migration dry-run:
 *
 *   cd functions
 *   npm run admin:sync-claims
 *
 * Legacy role=admin kullanıcılarına claim yaz:
 *
 *   DRY_RUN=false npm run admin:sync-claims
 *
 * Tek kullanıcıya admin ver:
 *
 *   ADMIN_UID=<uid> ADMIN=true DRY_RUN=false npm run admin:sync-claims
 *
 * Tek kullanıcıdan admin al:
 *
 *   ADMIN_UID=<uid> ADMIN=false DRY_RUN=false npm run admin:sync-claims
 */

import * as admin from 'firebase-admin';

const PROJECT_ID = process.env.GCLOUD_PROJECT ?? 'unisec-e36e1';
const DRY_RUN = process.env.DRY_RUN !== 'false';
const ADMIN_UID = process.env.ADMIN_UID;
const ADMIN_VALUE = process.env.ADMIN !== 'false';
const MAX_RETRIES = 3;
const RETRY_BASE_DELAY_MS = 1000;

async function main(): Promise<void> {
  admin.initializeApp({ projectId: PROJECT_ID });

  console.log(`▶ Admin custom claim sync başlıyor (project: ${PROJECT_ID})`);
  console.log(`   Mode: ${DRY_RUN ? 'DRY_RUN' : 'WRITE'}`);

  if (ADMIN_UID) {
    await setAdminClaim(ADMIN_UID, ADMIN_VALUE);
  } else {
    await syncLegacyRoleAdmins();
  }

  console.log('✅ Admin custom claim sync tamamlandı.');
  await admin.app().delete();
}

async function syncLegacyRoleAdmins(): Promise<void> {
  const db = admin.firestore();
  const snap = await withRetry('Legacy role=admin sorgusu', () =>
    db.collection('users').where('role', '==', 'admin').get(),
  );

  console.log(`   Legacy role=admin kullanıcı sayısı: ${snap.size}`);

  for (const doc of snap.docs) {
    await setAdminClaim(doc.id, true);
  }
}

async function setAdminClaim(uid: string, value: boolean): Promise<void> {
  const user = await withRetry(`Auth kullanıcısı okunuyor (${uid})`, () =>
    admin.auth().getUser(uid),
  );
  const existingClaims = user.customClaims ?? {};
  const nextClaims = { ...existingClaims, admin: value };

  console.log(`   ${uid}: admin ${existingClaims.admin === true} → ${value}`);

  if (!DRY_RUN) {
    await withRetry(`Admin claim yazılıyor (${uid})`, () =>
      admin.auth().setCustomUserClaims(uid, nextClaims),
    );
  }
}

async function withRetry<T>(
  label: string,
  operation: () => Promise<T>,
): Promise<T> {
  let lastError: unknown;

  for (let attempt = 1; attempt <= MAX_RETRIES; attempt += 1) {
    try {
      return await operation();
    } catch (err) {
      lastError = err;
      if (attempt === MAX_RETRIES) break;

      const delayMs = RETRY_BASE_DELAY_MS * attempt;
      console.warn(
        `   ${label} başarısız; tekrar denenecek ` +
          `(${attempt}/${MAX_RETRIES - 1}): ${formatError(err)}`,
      );
      await sleep(delayMs);
    }
  }

  throw lastError;
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

function formatError(err: unknown): string {
  if (err instanceof Error) return err.message;
  return String(err);
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
