import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';

const db = admin.firestore();
const storage = admin.storage();
const LOG_COMPONENT = 'storage.cleanupOrphanPlaceSuggestionMedia';
const MIN_AGE_MS = 24 * 60 * 60 * 1000;
const PAGE_SIZE = 250;

export const cleanupOrphanPlaceSuggestionMedia = onSchedule(
  {
    region: 'europe-west1',
    schedule: 'every day 04:00',
    timeZone: 'Europe/Istanbul',
    timeoutSeconds: 540,
    memory: '256MiB',
  },
  async () => {
    const cutoffMs = Date.now() - MIN_AGE_MS;
    const bucket = storage.bucket();
    let pageToken: string | undefined;
    let scannedCount = 0;
    let suggestionCount = 0;
    let deletedCount = 0;
    let activeCount = 0;
    let recentCount = 0;
    let invalidPathCount = 0;
    let failedCount = 0;

    do {
      const [files, nextQuery] = await bucket.getFiles({
        prefix: 'place_suggestions/',
        autoPaginate: false,
        maxResults: PAGE_SIZE,
        pageToken,
      });
      scannedCount += files.length;
      const suggestionIds = uniqueSuggestionIds(
        files.map((file) => file.name),
      );
      suggestionCount += suggestionIds.length;
      const existingSuggestionIds = await existingDocumentIds(
        'place_suggestions',
        suggestionIds,
      );

      for (const file of files) {
        const parsed = parseSuggestionFilePath(file.name);
        if (!parsed) {
          invalidPathCount++;
          continue;
        }
        if (existingSuggestionIds.has(parsed.suggestionId)) {
          activeCount++;
          continue;
        }

        try {
          const [metadata] = await file.getMetadata();
          const createdAtMs = Date.parse(String(metadata.timeCreated ?? ''));
          if (!Number.isFinite(createdAtMs) || createdAtMs > cutoffMs) {
            recentCount++;
            continue;
          }
          await file.delete({ ignoreNotFound: true });
          deletedCount++;
        } catch (err) {
          failedCount++;
          logger.warn('Orphan place suggestion media cleanup failed', {
            component: LOG_COMPONENT,
            filePath: file.name,
            err: String(err),
          });
        }
      }

      pageToken = 'pageToken' in nextQuery
        ? nextQuery.pageToken
        : undefined;
    } while (pageToken);

    logger.info('Orphan place suggestion media cleanup complete', {
      component: LOG_COMPONENT,
      scannedCount,
      suggestionCount,
      deletedCount,
      activeCount,
      recentCount,
      invalidPathCount,
      failedCount,
    });
  },
);

async function existingDocumentIds(
  collection: string,
  ids: string[],
): Promise<Set<string>> {
  const existing = new Set<string>();
  for (let i = 0; i < ids.length; i += 100) {
    const refs = ids
      .slice(i, i + 100)
      .map((id) => db.collection(collection).doc(id));
    if (refs.length === 0) continue;
    const snapshots = await db.getAll(...refs);
    snapshots.forEach((snap) => {
      if (snap.exists) existing.add(snap.id);
    });
  }
  return existing;
}

function uniqueSuggestionIds(paths: string[]): string[] {
  const ids = new Set<string>();
  for (const path of paths) {
    const parsed = parseSuggestionFilePath(path);
    if (parsed) ids.add(parsed.suggestionId);
  }
  return [...ids];
}

function parseSuggestionFilePath(
  path: string,
): { userId: string; suggestionId: string; fileName: string } | null {
  const parts = path.split('/');
  if (
    parts.length !== 4 ||
    parts[0] !== 'place_suggestions' ||
    parts[1].length === 0 ||
    !/^[A-Za-z0-9_-]{1,256}$/.test(parts[2]) ||
    !/^photo_[0-4]\.(jpg|jpeg|png|webp)$/.test(parts[3])
  ) {
    return null;
  }
  return {
    userId: parts[1],
    suggestionId: parts[2],
    fileName: parts[3],
  };
}
