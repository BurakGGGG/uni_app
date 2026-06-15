import * as admin from 'firebase-admin';

const storage = admin.storage();

export type StorageFile = ReturnType<ReturnType<typeof storage.bucket>['file']>;

export function storageFileFromUrl(
  url: string,
  allowedPrefixes: string[],
): StorageFile | null {
  const parsed = parseStorageUrl(url);
  if (!parsed) return null;

  const defaultBucketName = storage.bucket().name;
  if (parsed.bucketName !== defaultBucketName) return null;
  if (!allowedPrefixes.some((prefix) => parsed.filePath.startsWith(prefix))) {
    return null;
  }

  return storage.bucket(parsed.bucketName).file(parsed.filePath);
}

function parseStorageUrl(
  url: string,
): { bucketName: string; filePath: string } | null {
  try {
    if (url.startsWith('gs://')) {
      const withoutScheme = url.slice('gs://'.length);
      const slashIndex = withoutScheme.indexOf('/');
      if (slashIndex <= 0) return null;
      return {
        bucketName: withoutScheme.slice(0, slashIndex),
        filePath: withoutScheme.slice(slashIndex + 1),
      };
    }

    const parsed = new URL(url);
    if (parsed.hostname === 'firebasestorage.googleapis.com') {
      const parts = parsed.pathname.split('/');
      const bucketIndex = parts.indexOf('b');
      const objectIndex = parts.indexOf('o');
      if (bucketIndex < 0 || objectIndex < 0 || objectIndex + 1 >= parts.length) {
        return null;
      }
      return {
        bucketName: parts[bucketIndex + 1],
        filePath: decodeURIComponent(parts.slice(objectIndex + 1).join('/')),
      };
    }

    if (parsed.hostname === 'storage.googleapis.com') {
      const parts = parsed.pathname.split('/').filter(Boolean);
      if (parts.length < 2) return null;
      return {
        bucketName: parts[0],
        filePath: decodeURIComponent(parts.slice(1).join('/')),
      };
    }
  } catch (_err) {
    return null;
  }
  return null;
}
