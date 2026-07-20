import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { sendNotificationToUser } from './helpers';
import {
  daysUntilTercihClose,
  istanbulNow,
  monthDay,
  PHASE_BOUNDS,
  tercihPhaseFor,
} from '../assistant/tercih_calendar';

const db = admin.firestore();

/** Tek turda taranacak en fazla kullanıcı — maliyet tavanı. */
const MAX_USERS_PER_RUN = 5000;
const PAGE_SIZE = 300;

/** Tercih kapanışına kaç gün kala "son günler" bildirimi gider. */
const LAST_DAYS_THRESHOLD = 3;

type MomentKey =
  | 'tercih_open'
  | 'tercih_last_days'
  | 'placement_day'
  | 'exam_morning';

interface Copy {
  title: string;
  body: string;
}

/**
 * Üni'nin sesi — bildirim metinleri.
 *
 * İstemcideki RobotScripts'ten ayrı tutulur: bildirim metni kısa ve
 * kendine özgüdür, uygulama içi balonlarla aynı değildir. Dürüstlük kuralı
 * burada da geçerli — Üni yerleşme garantisi vermez.
 */
const COPY: Record<MomentKey, { tr: Copy; en: Copy }> = {
  tercih_open: {
    tr: {
      title: 'Tercih dönemi başladı!',
      body: 'Listeni birlikte kuralım mı? Sana uygun bölümleri çıkarayım.',
    },
    en: {
      title: 'The preference period is open!',
      body: "Shall we build your list together? I'll find programs that fit you.",
    },
  },
  // Gövde liste sayısıyla kişiselleştirilir — {n} yer tutucusu.
  tercih_last_days: {
    tr: {
      title: `Tercihlere ${LAST_DAYS_THRESHOLD} gün kaldı`,
      body: 'Listende {n} tercih var. Son bir kez birlikte gözden geçirelim mi?',
    },
    en: {
      title: `${LAST_DAYS_THRESHOLD} days left for preferences`,
      body: 'You have {n} choices in your list. Shall we review it one last time?',
    },
  },
  placement_day: {
    tr: {
      title: 'Yerleştirme sonuçları açıklandı!',
      body: 'Bu anı bekliyordum. Sonucuna birlikte bakalım mı?',
    },
    en: {
      title: 'Placement results are out!',
      body: "I've been waiting for this. Shall we take a look together?",
    },
  },
  exam_morning: {
    tr: {
      title: 'Bugün senin günün',
      body: 'Sakin ol, bu kadar çalıştın. Ben buradayım.',
    },
    en: {
      title: 'Today is your day',
      body: "Stay calm, you've worked so hard for this. I'm right here.",
    },
  },
};

/** Liste boşken "kaç tercih" demek anlamsız — ayrı gövde. */
const EMPTY_LIST_BODY = {
  tr: 'Listen henüz boş. Birlikte hızlıca kuralım mı?',
  en: 'Your list is still empty. Shall we build it quickly together?',
};

const ROUTES: Record<MomentKey, string> = {
  tercih_open: '/preference-wizard',
  tercih_last_days: '/my-lists',
  placement_day: '/my-lists',
  exam_morning: '/',
};

/**
 * Bugün gönderilecek an var mı? Yoksa null — çoğu gün böyle, iş erken çıkar.
 */
export function momentFor(now: Date): MomentKey | null {
  const phase = tercihPhaseFor(now);
  const md = monthDay(now);

  if (phase === 'tercihPeriod') {
    if (md === PHASE_BOUNDS.tercihPeriod.from) return 'tercih_open';
    if (daysUntilTercihClose(now) === LAST_DAYS_THRESHOLD) {
      return 'tercih_last_days';
    }
    return null;
  }
  if (phase === 'placementDone' && md === PHASE_BOUNDS.placementDone.from) {
    return 'placement_day';
  }
  // YKS'nin kesin tarihi yıldan yıla oynar; sınav haftasının ilk günü
  // yaklaşık karşılığı olarak kullanılıyor.
  if (phase === 'examWeek' && md === PHASE_BOUNDS.examWeek.from) {
    return 'exam_morning';
  }
  return null;
}

/** Bir kullanıcının tercih listelerindeki toplam öğe sayısı. */
async function countChoices(uid: string): Promise<number> {
  const snap = await db
    .collection('preferenceLists')
    .where('userId', '==', uid)
    .get();
  let total = 0;
  for (const doc of snap.docs) {
    const items = doc.data().items;
    if (Array.isArray(items)) total += items.length;
  }
  return total;
}

/**
 * Üni'nin tercih takvimi hatırlatmaları.
 *
 * Günde bir kez çalışır, o günün takvimdeki karşılığına bakar; karşılığı
 * yoksa hiçbir şey yapmaz. Kullanıcı başına yıl önekli anahtar
 * (`2026_tercih_open`) `users/{uid}.uniReminders.sentKeys` içinde tutulur —
 * aynı an bir yıl içinde ikinci kez gönderilmez. Bookkeeping'i yalnız
 * sunucu yazar (isSafeUserUpdate whitelist'i dışında).
 */
export const sendUniReminders = functions
  .region('europe-west1')
  .pubsub.schedule('0 8 * * *') // Her gün 08:00
  .timeZone('Europe/Istanbul')
  .onRun(async () => {
    const now = istanbulNow();
    const moment = momentFor(now);
    if (!moment) {
      console.log('[uniReminders] Bugün gönderilecek an yok');
      return null;
    }

    const sentKey = `${now.getUTCFullYear()}_${moment}`;
    console.log(`[uniReminders] An: ${moment}, anahtar: ${sentKey}`);

    let cursor: admin.firestore.QueryDocumentSnapshot | null = null;
    let scanned = 0;
    let sent = 0;

    while (scanned < MAX_USERS_PER_RUN) {
      let q = db.collection('users').orderBy('__name__').limit(PAGE_SIZE);
      if (cursor) q = q.startAfter(cursor);
      const page = await q.get();
      if (page.empty) break;

      cursor = page.docs[page.docs.length - 1];
      scanned += page.docs.length;

      for (const doc of page.docs) {
        const data = doc.data();

        // Tercih kapalıysa hiç uğraşma (helpers da ayrıca doğrular).
        if (data.notificationPrefs?.uniRemindersEnabled === false) continue;

        const sentKeys = Array.isArray(data.uniReminders?.sentKeys)
          ? (data.uniReminders.sentKeys as unknown[])
          : [];
        if (sentKeys.includes(sentKey)) continue;

        const lang: 'tr' | 'en' = data.locale === 'en' ? 'en' : 'tr';
        const copy = COPY[moment][lang];
        let body = copy.body;

        if (moment === 'tercih_last_days') {
          const n = await countChoices(doc.id);
          body =
            n === 0
              ? EMPTY_LIST_BODY[lang]
              : copy.body.replace('{n}', String(n));
        }

        try {
          await sendNotificationToUser({
            userId: doc.id,
            type: 'uni_reminder',
            prefKey: 'uniRemindersEnabled',
            title: copy.title,
            body,
            data: { route: ROUTES[moment], moment },
          });

          await doc.ref.set(
            { uniReminders: { sentKeys: FieldValue.arrayUnion(sentKey) } },
            { merge: true },
          );
          sent++;
        } catch (e) {
          console.error(`[uniReminders] ${doc.id} gönderilemedi:`, e);
        }
      }

      if (page.docs.length < PAGE_SIZE) break;
    }

    if (scanned >= MAX_USERS_PER_RUN) {
      console.warn(
        `[uniReminders] Tavana takıldı (${MAX_USERS_PER_RUN}); kalan kullanıcılar bu turda atlandı`,
      );
    }
    console.log(`[uniReminders] ${scanned} tarandı, ${sent} gönderildi`);
    return null;
  });
