import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { buildPublicProfileData } from './public_profile_payload';

const db = admin.firestore();

export const syncPublicProfile = onDocumentWritten(
  {
    region: 'europe-west1',
    document: 'users/{userId}',
  },
  async (event) => {
    const userId = event.params.userId;
    const profileRef = db.collection('publicProfiles').doc(userId);
    const after = event.data?.after;

    if (!after?.exists) {
      await profileRef.delete();
      return;
    }

    const data = after.data() ?? {};
    await profileRef.set(buildPublicProfileData(data));
  },
);
