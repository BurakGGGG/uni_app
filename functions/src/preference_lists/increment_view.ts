import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';

const db = admin.firestore();
const LIST_ID_RE = /^[A-Za-z0-9_-]{1,128}$/;

interface IncrementPreferenceListViewInput {
  listId?: unknown;
}

export const incrementPreferenceListView = onCall(
  {
    region: 'europe-west1',
    timeoutSeconds: 10,
    memory: '256MiB',
    cors: true,
    enforceAppCheck: true,
  },
  async (req): Promise<{ ok: true }> => {
    const input = (req.data ?? {}) as IncrementPreferenceListViewInput;
    const listId = typeof input.listId === 'string' ? input.listId.trim() : '';

    if (!LIST_ID_RE.test(listId)) {
      throw new HttpsError('invalid-argument', 'Geçersiz liste ID.');
    }

    const ref = db.collection('preferenceLists').doc(listId);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new HttpsError('not-found', 'Liste bulunamadı.');
    }

    if (snap.data()?.isPublic !== true) {
      throw new HttpsError('permission-denied', 'Liste herkese açık değil.');
    }

    try {
      await ref.update({
        viewCount: admin.firestore.FieldValue.increment(1),
        lastViewedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return { ok: true };
    } catch (err) {
      logger.error('Preference list view increment failed', {
        listId,
        err: String(err),
      });
      throw new HttpsError('internal', 'Görüntülenme sayısı artırılamadı.');
    }
  },
);
