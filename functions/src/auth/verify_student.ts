import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { getUniversityIdFromEmail } from './domain_mapper';

const db = admin.firestore();

export const verifyStudentUniversity = onCall(
  {
    region: 'europe-west1',
    cors: true,
    enforceAppCheck: true,
  },
  async (req) => {
    if (!req.auth) {
      throw new HttpsError('unauthenticated', 'Giriş gerekli.');
    }

    const email = String(req.auth.token.email ?? '').toLowerCase();
    const emailVerified = req.auth.token.email_verified === true;

    if (!emailVerified || !email.endsWith('.edu.tr')) {
      throw new HttpsError(
        'failed-precondition',
        'Doğrulanmış edu.tr e-posta gerekli.',
      );
    }

    const universityId = getUniversityIdFromEmail(email);
    const uid = req.auth.uid;

    await db.collection('users').doc(uid).set(
      {
        isVerifiedStudent: true,
        universityId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return {
      isVerifiedStudent: true,
      universityId,
    };
  },
);
