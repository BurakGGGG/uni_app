import { onDocumentDeleted } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions';
import { storageFileFromUrl } from './storage_file_from_url';

const LOG_COMPONENT = 'storage.cleanupDeletedMedia';

export const cleanupDeletedReviewMedia = onDocumentDeleted(
  {
    region: 'europe-west1',
    document: 'reviews/{reviewId}',
  },
  async (event) => {
    const reviewId = event.params.reviewId;
    const urls = parseStringList(event.data?.data()?.imageUrls, 20);
    await deleteStorageUrls(urls, ['review_images/'], {
      source: 'reviews',
      documentId: reviewId,
    });
  },
);

export const cleanupDeletedStoryMedia = onDocumentDeleted(
  {
    region: 'europe-west1',
    document: 'stories/{storyId}',
  },
  async (event) => {
    const storyId = event.params.storyId;
    const data = event.data?.data() ?? {};
    const urls = uniqueStrings([
      data.imageUrl,
      data.thumbnailUrl,
      data.videoUrl,
    ]);
    await deleteStorageUrls(urls, ['stories/'], {
      source: 'stories',
      documentId: storyId,
    });
  },
);

async function deleteStorageUrls(
  urls: string[],
  allowedPrefixes: string[],
  metadata: { source: string; documentId: string },
) {
  if (urls.length === 0) return;

  let deletedCount = 0;
  let skippedCount = 0;
  let failedCount = 0;

  for (const url of urls) {
    const target = storageFileFromUrl(url, allowedPrefixes);
    if (!target) {
      skippedCount++;
      continue;
    }

    try {
      await target.delete({ ignoreNotFound: true });
      deletedCount++;
    } catch (err) {
      failedCount++;
      logger.warn('Storage media cleanup failed', {
        component: LOG_COMPONENT,
        ...metadata,
        err: String(err),
      });
    }
  }

  logger.info('Storage media cleanup complete', {
    component: LOG_COMPONENT,
    ...metadata,
    deletedCount,
    skippedCount,
    failedCount,
  });
}

function parseStringList(value: unknown, maxItems: number): string[] {
  if (!Array.isArray(value)) return [];
  return uniqueStrings(value).slice(0, maxItems);
}

function uniqueStrings(values: unknown[]): string[] {
  const result = new Set<string>();
  for (const value of values) {
    if (typeof value !== 'string') continue;
    const trimmed = value.trim();
    if (trimmed.length > 0) result.add(trimmed);
  }
  return [...result];
}
