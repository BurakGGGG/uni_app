import * as admin from 'firebase-admin';

const db = admin.firestore();
const messaging = admin.messaging();

interface SendNotificationOptions {
  userId: string;
  type: 'review_liked' | 'review_moderated' | 'favorite_new_review';
  title: string;
  body: string;
  data?: Record<string, string>;
  prefKey: 'reviewLikedEnabled' | 'reviewModeratedEnabled' | 'favoriteNewReviewEnabled';
}

/**
 * Tek user'a bildirim gönder + Firestore'a notification doc yaz.
 * Tercihler kapalıysa hiçbir şey yapma.
 */
export async function sendNotificationToUser(opts: SendNotificationOptions) {
  const userDoc = await db.collection('users').doc(opts.userId).get();
  if (!userDoc.exists) return;
  
  const user = userDoc.data()!;
  
  // Preference kontrolü
  const prefs = user.notificationPrefs || {};
  if (prefs[opts.prefKey] === false) {
    console.log(`[notif] ${opts.userId} has ${opts.prefKey}=false, skipping`);
    return;
  }
  
  const tokens = (user.fcmTokens || []) as string[];
  if (tokens.length === 0) {
    console.log(`[notif] ${opts.userId} has no FCM tokens`);
  }
  
  // 1. Firestore'a notification doc yaz (in-app merkezi için)
  const notifId = db.collection('notifications').doc().id;
  const expireAt = admin.firestore.Timestamp.fromMillis(
    Date.now() + 90 * 24 * 60 * 60 * 1000  // 90 gün
  );
  await db.collection('notifications').doc(notifId).set({
    userId: opts.userId,
    type: opts.type,
    title: opts.title,
    body: opts.body,
    data: opts.data || {},
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expireAt,
  });
  
  // 2. FCM push gönder
  if (tokens.length > 0) {
    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: opts.title,
        body: opts.body,
      },
      data: {
        ...opts.data || {},
        notificationId: notifId,
        type: opts.type,
      },
      android: {
        notification: {
          channelId: 'default_channel_id',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: { badge: 1, sound: 'default' },
        },
      },
    });
    
    // Geçersiz token'ları temizle
    const invalidTokens: string[] = [];
    response.responses.forEach((r, i) => {
      if (!r.success) {
        const error = r.error?.code;
        if (error === 'messaging/invalid-registration-token' ||
            error === 'messaging/registration-token-not-registered') {
          invalidTokens.push(tokens[i]);
        }
      }
    });
    
    if (invalidTokens.length > 0) {
      await db.collection('users').doc(opts.userId).update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
      });
      console.log(`[notif] Removed ${invalidTokens.length} invalid tokens`);
    }
  }
  
  console.log(`[notif] ✅ Sent ${opts.type} to ${opts.userId}`);
}
