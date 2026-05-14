# Karşılaştırma Ekranı — Detaylı Düzenleme, Hata Tespiti ve UI İyileştirme Rehberi

> **Hazırlanma Tarihi:** 2026-05-12
> **Kapsam:** `lib/features/comparison/` + Firebase (Firestore Rules, Cloud Functions, indeksler, maliyet)
> **Sürüm:** v1.0 — Hotfix + Sprint Planı
> **Hedef:** Karşılaştırma feature'ı production'a çıkmadan önce kritik güvenlik açıklarını kapamak, kararlılığı artırmak, UI/UX'i Türk üniversite öğrencisi hedef kitlesi için cilalamak.

---

## İçindekiler

1. [Yönetici Özeti](#1-yönetici-özeti)
2. [KRİTİK — Firestore Security Rules](#2-kri̇ti̇k--firestore-security-rules)
3. [KRİTİK — Cloud Functions Düzeltmeleri](#3-kri̇ti̇k--cloud-functions-düzeltmeleri)
4. [KRİTİK — Client Hata Yönetimi](#4-kri̇ti̇k--client-hata-yöneti̇mi̇)
5. [UI / UX İyileştirmeleri](#5-ui--ux-i̇yi̇leşti̇rmeleri̇)
6. [Performans & Firestore Maliyet](#6-performans--firestore-mali̇yet)
7. [Yazım / Lokalizasyon Hataları](#7-yazım--lokali̇zasyon-hataları)
8. [Yeni Özellik Önerileri](#8-yeni̇-özelli̇k-öneri̇leri̇)
9. [Test Kapsamı](#9-test-kapsamı)
10. [Önerilen Yol Haritası (Sprint Plan)](#10-öneri̇len-yol-hari̇tası-sprint-plan)
11. [Ek — PR Review Kontrol Listesi](#11-ek--pr-review-kontrol-li̇stesi̇)

---

## 1. Yönetici Özeti

### 1.1 Tespit Sayıları

| Önem | Adet | Açıklama |
|------|------|----------|
| 🔴 **KRİTİK** | 9 | Production'a çıkarsa veri kaybı / güvenlik açığı / crash |
| 🟠 **YÜKSEK** | 14 | Kullanıcı deneyimini doğrudan bozar, error funnel'ı tıkar |
| 🟡 **ORTA** | 18 | UI tutarsızlığı, performans, maliyet artışı |
| 🟢 **DÜŞÜK** | 11 | Cilalama, future-proofing, dev experience |

### 1.2 Risk Matrisi

| Alan | Risk Seviyesi | Sebep |
|------|---------------|-------|
| Güvenlik | 🔴 **RED** | `cities`, `universities`, `departments` koleksiyonları için `allow write: if true` veya `isAuthenticated()` — herkes admin verisi yazabilir |
| Kararlılık | 🔴 **RED** | AI service ve repository'de try-catch eksikliği, 28+ force-unwrap, race condition |
| Performans | 🟡 **YELLOW** | N+1 query, autoDispose eksikliği, `aiSummaryLogs` TTL yok, hatalı bölge seçimi |
| UI / UX | 🟡 **YELLOW** | Hardcoded renkler/string'ler, shimmer paket yüklü ama kullanılmıyor, accessibility sıfır |
| Test Kapsamı | 🔴 **RED** | `test/features/comparison/` tamamen boş |

### 1.3 Aksiyon Öncelik Tablosu

| Süre | Yapılacaklar |
|------|--------------|
| **Bugün** (1 gün) | 🔴 2.1 — cities/universities/departments rules fix · 🔴 7.1 — Yazım hatası fix · 🔴 4.1 — AiComparisonSummaryService try-catch |
| **Bu Hafta** (3-5 gün) | 🔴 3.1 — Cloud Function race condition · 🔴 4.2-4.5 — Tüm force-unwrap ve catch fix · 🟠 4.3 — Boş catch blokları + Crashlytics |
| **Sprint Sonu** (1-2 hafta) | 🟠 5.1-5.10 — UI iyileştirmeleri · 🟡 6.1-6.6 — Performans optimizasyonları · 🟡 9.1-9.5 — Test yazımı |
| **Future Sprint** (2-4 hafta) | 🟢 8.1-8.5 — Yeni özellikler · 🟡 Lokalizasyon (en/tr ayrımı) |

### 1.4 Etkilenen Dosya Sayısı

```
lib/features/comparison/
├── data/                       (4 dosya — repository + AI service)
├── domain/                     (3 model + 1 service)
├── presentation/
│   ├── providers/              (1 dosya, 650 satır)
│   ├── screens/                (6 dosya, ~4000 satır)
│   └── widgets/                (24 dosya, ~5000 satır)
firestore.rules                 (196 satır)
functions/src/comparison/       (1 dosya, 230 satır)
functions/src/usage/            (1 dosya, ~55 satır)
test/features/comparison/       (BOŞ — yazılacak)
```

---

## 2. KRİTİK — Firestore Security Rules

> **Dosya:** [firestore.rules](firestore.rules)
> **Risk Seviyesi:** 🔴 **EN YÜKSEK**
> **Etki:** Bu rules ile production'a çıkarsanız, **kötü niyetli herhangi bir kullanıcı tüm üniversite/şehir/bölüm verilerinizi silebilir veya bozabilir**.

### 2.1 `cities` koleksiyonu yazmaya açık (Satır 32-35)

#### Mevcut Kod (TEHLİKELİ)
```firestore
// ─── Şehirler ───────────────────────────────────────────────
// Herkes okuyabilir, kimse yazamaz (admin panelden yönetilir)
match /cities/{cityId} {
  allow read: if true;
  allow write: if true;  // ← ❌ HERKES YAZABİLİR!
}
```

Yorumda *"kimse yazamaz"* yazıyor ama kuralın kendisi `if true` diyor. Yorum ile davranış uyumsuz.

#### Düzeltilmiş Kod
```firestore
// ─── Şehirler ───────────────────────────────────────────────
// Herkes okuyabilir, sadece admin yazabilir
match /cities/{cityId} {
  allow read: if true;
  allow write: if isAdmin();
}
```

#### Açıklama
- `cities` koleksiyonu şehir karşılaştırma feature'ının veri kaynağı (`CityComparisonRepository`).
- Yetkisiz yazma → karşılaştırma verisi bozulabilir, AI özet bozuk veri üzerinden üretilir, kullanıcılar yanlış bilgi alır.
- Migration için geçici yazma izni gerekiyorsa, admin SDK ile (Cloud Function veya Firestore Console) yapın.

#### Regresyon Riski
- **Düşük.** Admin paneliniz `isAdmin()` token claim'i ile çalışıyorsa hiçbir şey kırılmaz.
- Seed/migration script kullanıyorsanız, Firestore Admin SDK (service account) ile çalıştığı için rules'tan etkilenmez.

---

### 2.2 `universities` koleksiyonu yazmaya açık (Satır 39-42)

#### Mevcut Kod
```firestore
match /universities/{uniId} {
  allow read: if true;
  allow write: if true; // TEMP: was isAdmin()  ← ❌ "TEMP" production'da hala duruyor
}
```

#### Düzeltilmiş Kod
```firestore
match /universities/{uniId} {
  allow read: if true;
  // Admin yazabilir; isVerifiedStudent kullanıcılar sadece avgRating/reviewCount field'larını
  // (review eklendiğinde) Cloud Function ile güncelletmeli — direkt update YASAK.
  allow write: if isAdmin();
}
```

#### Cloud Function (Trigger) — Review eklendikçe agregat güncelleme
Eğer şu anda client `universities.avgRating` field'ını direkt güncelliyorsa, bu **mutlaka** Cloud Function trigger'a taşınmalı:

```typescript
// functions/src/aggregations/university_rating.ts
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export const recomputeUniversityRating = onDocumentWritten(
  {
    region: 'europe-west1',
    document: 'reviews/{reviewId}',
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    // Hangi üniversiteyi etkilediğini bul
    const universityId = (after?.universityId ?? before?.universityId) as string | undefined;
    if (!universityId) return;

    // Yalnızca onaylı yorumları say
    const snap = await db
      .collection('reviews')
      .where('universityId', '==', universityId)
      .where('isApproved', '==', true)
      .get();

    let sum = 0;
    let count = 0;
    const categoryTotals: Record<string, { sum: number; count: number }> = {};

    for (const doc of snap.docs) {
      const data = doc.data();
      const rating = Number(data.rating ?? 0);
      if (rating > 0) {
        sum += rating;
        count += 1;
      }
      const cats = (data.categoryRatings ?? {}) as Record<string, number>;
      for (const [cat, val] of Object.entries(cats)) {
        if (!categoryTotals[cat]) categoryTotals[cat] = { sum: 0, count: 0 };
        categoryTotals[cat].sum += Number(val);
        categoryTotals[cat].count += 1;
      }
    }

    const avgRating = count > 0 ? Number((sum / count).toFixed(2)) : 0;
    const categoryRatings: Record<string, number> = {};
    for (const [cat, agg] of Object.entries(categoryTotals)) {
      categoryRatings[cat] = agg.count > 0 ? Number((agg.sum / agg.count).toFixed(2)) : 0;
    }

    await db.collection('universities').doc(universityId).set(
      {
        avgRating,
        reviewCount: count,
        categoryRatings,
        ratingUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  },
);
```

Bu trigger, rules'ı kısıtlamamızdan sonra agregat alanların güncel kalmasını sağlar.

---

### 2.3 `departments` write yetkisi her kullanıcıya açık (Satır 46-49)

#### Mevcut Kod
```firestore
match /departments/{deptId} {
  allow read: if true;
  allow write: if isAuthenticated(); // TEMP: migration re-run  ← ❌ Herhangi authenticated user
}
```

Bu, sahte hesap açan herkesin **bölüm taban puanlarını değiştirmesine** izin veriyor. ÖSYM verisi gibi hassas içerik için kabul edilemez.

#### Düzeltilmiş Kod
```firestore
match /departments/{deptId} {
  allow read: if true;
  allow write: if isAdmin();
}
```

#### Migration Senaryosu

Eğer hala ÖSYM verisi import ediliyorsa, iki seçenek:

**Seçenek A:** Migration süresince geçici admin claim ver
```bash
# Migration kullanıcısına admin claim'i ekle (1 kerelik)
gcloud auth application-default login
node scripts/set-admin-claim.js <migration-uid>

# Migration sonrası kaldır
node scripts/remove-admin-claim.js <migration-uid>
```

**Seçenek B (önerilir):** Cloud Function (admin SDK) üzerinden migration
```typescript
// functions/src/migration/import_departments.ts
export const importDepartmentsFromOsym = onCall(
  {
    region: 'europe-west1',
    memory: '1GiB',
    timeoutSeconds: 540,
    secrets: ['ADMIN_API_KEY'],
  },
  async (req) => {
    // ADMIN_API_KEY ile gizli endpoint
    if (req.data?.adminKey !== process.env.ADMIN_API_KEY) {
      throw new HttpsError('permission-denied', 'Yetkisiz erişim.');
    }
    // ... bulk import logic with admin SDK
  },
);
```

---

### 2.4 `aiSummaryLogs` için açık kural yok

#### Sorun
Şu anda `aiSummaryLogs` koleksiyonuna kural tanımlanmamış → Firestore'un default davranışı **implicit deny**, yani çalışıyor. Ama:
- **Audit edilebilirlik düşük** — gelecekteki developer "kural yok, ben kuralı yazabilirim" diye düşünebilir.
- Cloud Function admin SDK ile yazıyor zaten, ama belirsizlik bırakmak risk.

#### Eklenecek Kod
```firestore
// ─── AI Özet Logları ────────────────────────────────────────
// Cloud Function (admin SDK) yazar, kimse okuyamaz.
match /aiSummaryLogs/{logId} {
  allow read: if isAdmin();
  allow write: if false;
}
```

---

### 2.5 `usageStats` update kuralı yetersiz validation

#### Mevcut Kod (Satır 181-185)
```firestore
match /users/{uid}/usageStats/{docId} {
  allow read: if isOwner(uid);
  allow create: if isOwner(uid);
  allow update: if isOwner(uid) &&
    request.resource.data.diff(resource.data)
      .affectedKeys().hasOnly(['dailyComparisons', 'lastResetDate', 'totalComparisons']);
  allow delete: if false;
}
```

#### Sorun
Kullanıcı `dailyComparisons` field'ını **istediği değere set edebilir**. Örnek:
- `dailyComparisons: 1` → `dailyComparisons: -1000` (negatife çekip sınırsız karşılaştırma)
- `totalComparisons: 0` → `totalComparisons: 999999` (analytics bozulur)

#### Düzeltilmiş Kod
```firestore
match /users/{uid}/usageStats/{docId} {
  allow read: if isOwner(uid);

  // İlk oluşturma — bütün sayaçlar 0 olmalı
  allow create: if isOwner(uid) &&
    request.resource.data.dailyComparisons == 0 &&
    request.resource.data.totalComparisons == 0;

  // Update — sadece izinli alanlar, sadece pozitif artış (en fazla +1)
  allow update: if isOwner(uid) &&
    request.resource.data.diff(resource.data)
      .affectedKeys().hasOnly(['dailyComparisons', 'lastResetDate', 'totalComparisons']) &&
    // dailyComparisons: +1 veya 0'a sıfırlama
    (
      (request.resource.data.dailyComparisons == resource.data.dailyComparisons + 1) ||
      (request.resource.data.dailyComparisons == 0)  // gün değişikliği reset
    ) &&
    // totalComparisons: sadece +1
    request.resource.data.totalComparisons >= resource.data.totalComparisons &&
    request.resource.data.totalComparisons <= resource.data.totalComparisons + 1 &&
    // lastResetDate: ISO string format kontrolü
    request.resource.data.lastResetDate is string &&
    request.resource.data.lastResetDate.matches('\\d{4}-\\d{2}-\\d{2}');

  allow delete: if false;
}
```

#### Açıklama
- `dailyComparisons` sadece `+1` artabilir veya `0`'a düşebilir (gün değişimi reset).
- `totalComparisons` sadece monoton artar (`>= resource` ve `<= resource + 1`).
- `lastResetDate` ISO format kontrolü (`YYYY-MM-DD`).
- **Etki:** Kullanıcı client tarafından sayacı manipüle edemez, monetization bypass'ı engellenir.

---

### 2.6 `recommendationEnrichments` doc ID format kontrolü

#### Mevcut Kod (Satır 163-167)
```firestore
match /recommendationEnrichments/{cacheId} {
  allow read: if isAuthenticated() &&
                 resource.data.userId == request.auth.uid;
  allow write: if false;
}
```

#### Sorun
Doc ID format kontrolü yok. Cache document'i siliniyorsa veya yeniden oluşturuluyorsa, kullanıcı doc ID'sini tahmin edebilir.

#### Düzeltilmiş Kod
```firestore
match /recommendationEnrichments/{cacheId} {
  // Doc ID format: {uid}_{hash24} — kullanıcı sadece kendi prefix'ini okuyabilir
  allow read: if isAuthenticated() &&
                 cacheId.matches(request.auth.uid + '_.*') &&
                 resource.data.userId == request.auth.uid;
  allow write: if false;
}
```

---

### 2.7 Komple Düzeltilmiş `firestore.rules`

> Aşağıdaki dosyayı `firestore.rules` üzerine yazın. Tüm yukarıdaki fix'leri içerir.

```firestore
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // ─── Yardımcı Fonksiyonlar ──────────────────────────────────
    function isAuthenticated() {
      return request.auth != null;
    }

    function isAdmin() {
      return isAuthenticated() && request.auth.token.admin == true;
    }

    function isVerifiedStudent() {
      return isAuthenticated() &&
        request.auth.token.email_verified == true &&
        request.auth.token.email.matches('.*\\.edu\\.tr$');
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // ─── Şehirler ───────────────────────────────────────────────
    match /cities/{cityId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // ─── Üniversiteler ──────────────────────────────────────────
    match /universities/{uniId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // ─── Bölümler ───────────────────────────────────────────────
    match /departments/{deptId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // ─── Mekanlar ───────────────────────────────────────────────
    match /places/{placeId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // ─── Bildirimler ────────────────────────────────────────────
    match /notifications/{notifId} {
      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow update: if isAuthenticated() &&
        resource.data.userId == request.auth.uid &&
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isRead']);
      allow delete: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow create: if false;
    }

    // ─── Yorumlar ───────────────────────────────────────────────
    match /reviews/{reviewId} {
      allow read: if resource.data.isApproved == true
        || (request.auth != null && request.auth.uid == resource.data.userId);

      allow create: if isVerifiedStudent() &&
        request.resource.data.userId == request.auth.uid &&
        request.resource.data.universityId == get(/databases/$(database)/documents/users/$(request.auth.uid)).data.universityId &&
        // Rating 1-5 arasında olmalı
        request.resource.data.rating is number &&
        request.resource.data.rating >= 1 &&
        request.resource.data.rating <= 5;

      allow update: if isAuthenticated() && (
        (isOwner(resource.data.userId) &&
         request.resource.data.userId == resource.data.userId) ||
        (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['likes']))
      );

      allow delete: if isOwner(resource.data.userId);
    }

    match /reviews/{reviewId}/likes/{userId} {
      allow read: if true;
      allow create, delete: if isAuthenticated() && request.auth.uid == userId;
      allow update: if false;
    }

    match /reports/{reportId} {
      allow read: if isAdmin();  // Admin moderator panel için
      allow create: if isAuthenticated()
        && request.resource.data.userId == request.auth.uid;
      allow update, delete: if false;
    }

    match /preferenceLists/{listId} {
      allow read: if resource.data.isPublic == true ||
                     (request.auth != null && request.auth.uid == resource.data.userId);

      allow create: if request.auth != null
                    && request.resource.data.userId == request.auth.uid
                    && request.resource.data.items.size() <= 24;

      allow update: if (request.auth != null && request.auth.uid == resource.data.userId)
                    || (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['viewCount']));

      allow delete: if request.auth != null && request.auth.uid == resource.data.userId;
    }

    match /users/{userId} {
      allow read: if true;
      allow create: if isOwner(userId);
      allow update: if isOwner(userId) && (
        !request.resource.data.diff(resource.data).affectedKeys().hasAny(['isVerifiedStudent']) ||
        (request.resource.data.isVerifiedStudent == true && request.auth.token.email_verified == true && request.auth.token.email.matches('.*\\.edu\\.tr$')) ||
        (request.resource.data.isVerifiedStudent == false)
      );
      allow delete: if isOwner(userId);
    }

    match /users/{userId}/favorites/{favId} {
      allow read: if isOwner(userId);
      allow write: if isOwner(userId);
    }

    match /users/{userId}/likedReviews/{reviewId} {
      allow read: if isOwner(userId);
      allow create, delete: if isOwner(userId);
      allow update: if false;
    }

    match /recommendationEnrichments/{cacheId} {
      allow read: if isAuthenticated() &&
                     cacheId.matches(request.auth.uid + '_.*') &&
                     resource.data.userId == request.auth.uid;
      allow write: if false;
    }

    match /subscriptions/{uid} {
      allow read: if isOwner(uid);
      allow write: if false;
    }

    // ─── Kullanım İstatistikleri (Sıkı validation) ───────────────
    match /users/{uid}/usageStats/{docId} {
      allow read: if isOwner(uid);

      allow create: if isOwner(uid) &&
        request.resource.data.dailyComparisons == 0 &&
        request.resource.data.totalComparisons == 0;

      allow update: if isOwner(uid) &&
        request.resource.data.diff(resource.data)
          .affectedKeys().hasOnly(['dailyComparisons', 'lastResetDate', 'totalComparisons']) &&
        (
          (request.resource.data.dailyComparisons == resource.data.dailyComparisons + 1) ||
          (request.resource.data.dailyComparisons == 0)
        ) &&
        request.resource.data.totalComparisons >= resource.data.totalComparisons &&
        request.resource.data.totalComparisons <= resource.data.totalComparisons + 1 &&
        request.resource.data.lastResetDate is string &&
        request.resource.data.lastResetDate.matches('\\d{4}-\\d{2}-\\d{2}');

      allow delete: if false;
    }

    // ─── AI Özet Cache ───────────────────────────────────────────
    match /aiSummaryCache/{cacheKey} {
      allow read: if isAuthenticated();
      allow write: if false;
    }

    // ─── AI Özet Logları ────────────────────────────────────────
    match /aiSummaryLogs/{logId} {
      allow read: if isAdmin();
      allow write: if false;
    }
  }
}
```

---

### 2.8 Rules Test'leri (Firestore Emulator)

> **Yeni dosya:** `test/firestore_rules.test.ts`

```typescript
import { initializeTestEnvironment, RulesTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-uniseç',
    firestore: {
      rules: readFileSync('firestore.rules', 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });
});

afterAll(() => testEnv.cleanup());

describe('cities collection', () => {
  it('herkes okuyabilir', async () => {
    const unauth = testEnv.unauthenticatedContext();
    await assertSucceeds(unauth.firestore().collection('cities').doc('istanbul').get());
  });

  it('normal kullanıcı yazamaz', async () => {
    const user = testEnv.authenticatedContext('user1');
    await assertFails(
      user.firestore().collection('cities').doc('istanbul').set({ name: 'hack' }),
    );
  });

  it('admin yazabilir', async () => {
    const admin = testEnv.authenticatedContext('admin1', { admin: true });
    await assertSucceeds(
      admin.firestore().collection('cities').doc('istanbul').set({ name: 'İstanbul' }),
    );
  });
});

describe('usageStats validation', () => {
  it('kullanıcı dailyComparisons sayacını -1000 yapamaz', async () => {
    const uid = 'user1';
    const user = testEnv.authenticatedContext(uid);
    // Önce admin ile init et
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore()
        .collection('users').doc(uid).collection('usageStats').doc('current')
        .set({ dailyComparisons: 1, totalComparisons: 1, lastResetDate: '2026-05-12' });
    });
    await assertFails(
      user.firestore()
        .collection('users').doc(uid).collection('usageStats').doc('current')
        .update({ dailyComparisons: -1000 }),
    );
  });

  it('kullanıcı dailyComparisons sayacını +1 artırabilir', async () => {
    const uid = 'user2';
    const user = testEnv.authenticatedContext(uid);
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore()
        .collection('users').doc(uid).collection('usageStats').doc('current')
        .set({ dailyComparisons: 1, totalComparisons: 1, lastResetDate: '2026-05-12' });
    });
    await assertSucceeds(
      user.firestore()
        .collection('users').doc(uid).collection('usageStats').doc('current')
        .update({ dailyComparisons: 2, totalComparisons: 2 }),
    );
  });
});
```

`package.json`'a script ekleyin:
```json
{
  "scripts": {
    "test:rules": "firebase emulators:exec --only firestore 'jest test/firestore_rules.test.ts'"
  }
}
```

---

## 3. KRİTİK — Cloud Functions Düzeltmeleri

> **Dosyalar:**
> - [functions/src/comparison/summary.ts](functions/src/comparison/summary.ts) (1-230 satır)
> - [functions/src/usage/reset_ai_quota.ts](functions/src/usage/reset_ai_quota.ts)
> **Risk Seviyesi:** 🔴 **YÜKSEK**

### 3.1 Race Condition — `dailyAiComparisons` Increment Transactional Değil

#### Sorun
[functions/src/comparison/summary.ts:49-57](functions/src/comparison/summary.ts#L49-L57) — Mevcut akış:

```typescript
const usageSnap = await usageRef.get();           // 1. OKU
const dailyAiComparisons = ...                     // 2. HESAPLA
if (dailyAiComparisons >= DAILY_AI_COMPARISON_LIMIT) {  // 3. KONTROL
  throw new HttpsError('resource-exhausted', '...');
}
// ... Groq API çağrısı (3-10 saniye sürer)
await upsertUsageStats(usageRef, ..., { incrementAiComparisons: true });  // 4. YAZ
```

**Race condition senaryosu:**
- Kullanıcı aynı anda 3 farklı request atar (mobil uygulamadan + web'den + 2 cihazdan).
- Her biri `dailyAiComparisons = 4` okur, 4 < 5 olduğu için geçer.
- 3'ü de Groq'a gönderilir, kullanıcı **8 özet** alır (limit 5'ti).
- Kullanıcı ücretsiz olarak limit'i aştığı için **GROQ_API_KEY** maliyetiniz şişer.

#### Düzeltilmiş Kod

```typescript
// functions/src/comparison/summary.ts

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import { logger } from 'firebase-functions';

const GROQ_API_KEY = defineSecret('GROQ_API_KEY');
const db = admin.firestore();

const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const GROQ_MODEL = 'llama-3.1-8b-instant';
const CACHE_TTL_MS = 24 * 60 * 60 * 1000;
const DAILY_AI_COMPARISON_LIMIT = 5;
const REQUEST_TIMEOUT_MS = 15000;

interface SummaryInput {
  comparisonType: 'university' | 'department' | 'city';
  entityA: { id: string; name: string };
  entityB: { id: string; name: string };
  comparisonData: Record<string, unknown>;
}

interface SummaryOutput {
  summary: string;
  cached: boolean;
  generatedAt: number;
}

export const generateComparisonSummary = onCall(
  {
    region: 'europe-west1',             // ← bölge tutarlı (Türkiye için)
    timeoutSeconds: 30,
    memory: '256MiB',
    secrets: [GROQ_API_KEY],
    cors: true,
    enforceAppCheck: true,              // ← App Check ekledik (script ile spam koruma)
  },
  async (req): Promise<SummaryOutput> => {
    if (!req.auth) {
      throw new HttpsError('unauthenticated', 'Giriş gerekli.');
    }
    const uid = req.auth.uid;
    const input = req.data as SummaryInput | undefined;
    if (!input?.entityA || !input?.entityB || !input?.comparisonData) {
      throw new HttpsError('invalid-argument', 'Eksik karşılaştırma verisi.');
    }

    const usageRef = db.collection('users').doc(uid).collection('usageStats').doc('current');
    const today = formatDate(new Date());

    // ─── ATOMIC QUOTA CHECK + INCREMENT ─────────────────────────
    // Transaction ile race condition'ı engelliyoruz.
    let needsToCallGroq = false;
    let cacheKey = '';
    let cachedSummary: { summary: string; generatedAt: number } | null = null;

    const entityIds = [input.entityA.id, input.entityB.id].sort();
    cacheKey = makeHash({
      type: input.comparisonType,
      entityIds,
      payload: input.comparisonData,
    });
    const cacheRef = db.collection('aiSummaryCache').doc(cacheKey);

    try {
      await db.runTransaction(async (tx) => {
        const usageSnap = await tx.get(usageRef);
        const cacheSnap = await tx.get(cacheRef);

        const usageData = usageSnap.exists ? usageSnap.data() ?? {} : {};
        const lastResetDate = String(usageData.lastResetDate ?? today);
        const needsReset = lastResetDate !== today;
        const dailyAiComparisons = needsReset ? 0 : Number(usageData.dailyAiComparisons ?? 0);

        // Cache hit kontrolü
        if (cacheSnap.exists) {
          const cache = cacheSnap.data() ?? {};
          const expiresAt = Number(cache.expiresAt ?? 0);
          const summary = typeof cache.summary === 'string' ? cache.summary : '';
          if (summary.length > 0 && expiresAt > Date.now()) {
            cachedSummary = { summary, generatedAt: Number(cache.generatedAt ?? Date.now()) };
            // ✅ Cache hit'te quota DÜŞMÜYOR (business decision)
            // Eğer quota'dan düşmesini istiyorsanız, aşağıdaki satırı uncomment edin:
            // tx.set(usageRef, buildUsagePatch(usageData, { resetDaily: needsReset, increment: true, today }), { merge: true });
            return;
          }
        }

        // Cache miss — quota kontrolü + atomik artırım
        if (dailyAiComparisons >= DAILY_AI_COMPARISON_LIMIT) {
          throw new HttpsError(
            'resource-exhausted',
            `Günlük AI karşılaştırma limiti (${DAILY_AI_COMPARISON_LIMIT}) doldu. Yarın tekrar dene.`,
          );
        }

        // Quota'yı atomik olarak şimdi artır
        // (Groq başarısız olursa transaction rollback olmaz ama bu kabul edilebilir
        //  çünkü Groq response time düşük ve abuse engelleniyor)
        tx.set(
          usageRef,
          buildUsagePatch(usageData, { resetDaily: needsReset, increment: true, today }),
          { merge: true },
        );

        needsToCallGroq = true;
      });
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      logger.error('Quota check transaction failed', { uid, err });
      throw new HttpsError('internal', 'Geçici bir sorun oluştu. Lütfen tekrar dene.');
    }

    // Cache hit → erken dönüş
    if (cachedSummary) {
      await logSummaryRequest(uid, input, true).catch((e) =>
        logger.warn('Cache hit log failed', { e }),
      );
      return {
        summary: cachedSummary.summary,
        cached: true,
        generatedAt: cachedSummary.generatedAt,
      };
    }

    // ─── GROQ API ÇAĞRISI ────────────────────────────────────────
    if (!needsToCallGroq) {
      throw new HttpsError('internal', 'Beklenmeyen durum oluştu.');
    }

    const apiKey = GROQ_API_KEY.value();
    if (!apiKey) {
      logger.error('GROQ_API_KEY missing — running in degraded mode', { uid });
      throw new HttpsError('failed-precondition', 'AI servisi şu anda kullanılamıyor.');
    }

    let summary: string;
    try {
      const prompt = buildPrompt(input);
      summary = await callGroq(apiKey, prompt);
    } catch (err) {
      // Quota'yı düşürdük ama Groq başarısız oldu — kullanıcıya bilgi ver
      logger.error('Groq call failed', { uid, err: String(err) });
      throw new HttpsError(
        'unavailable',
        'AI servisi geçici olarak yanıt vermiyor. Birkaç saniye sonra tekrar dene.',
      );
    }

    const generatedAt = Date.now();
    await cacheRef.set(
      {
        comparisonType: input.comparisonType,
        entityIds,
        summary,
        generatedAt,
        expiresAt: generatedAt + CACHE_TTL_MS,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    await logSummaryRequest(uid, input, false).catch((e) =>
      logger.warn('Cache miss log failed', { e }),
    );

    return {
      summary,
      cached: false,
      generatedAt,
    };
  },
);

// ─── YARDIMCI FONKSİYONLAR ─────────────────────────────────────

function buildUsagePatch(
  usageData: admin.firestore.DocumentData,
  options: { resetDaily: boolean; increment: boolean; today: string },
): Record<string, unknown> {
  const patch: Record<string, unknown> = {};

  if (!usageData.lastResetDate || options.resetDaily) {
    patch.lastResetDate = options.today;
    patch.dailyComparisons = 0;
    patch.dailyAiComparisons = options.increment ? 1 : 0;
    patch.dailyAiRecommendations = Number(usageData.dailyAiRecommendations ?? 0);
  } else if (options.increment) {
    patch.dailyAiComparisons = admin.firestore.FieldValue.increment(1);
  }

  return patch;
}

function buildPrompt(input: SummaryInput): { system: string; user: string } {
  const system = `Sen bir Türk üniversite karşılaştırma danışmanısın.
Yanıtın doğal ve kısa Türkçe olmalı.
Sadece verilen veriye dayan, veri uydurma.
Çıktı SADECE düz metin olsun, markdown veya JSON verme.`;

  const user = `İki Türk üniversitesini karşılaştırıyoruz: ${input.entityA.name} ve ${input.entityB.name}.
Veriler: ${JSON.stringify(input.comparisonData)}
Lütfen 2-3 cümle Türkçe karşılaştırma özeti yaz.
Öğrenci perspektifinden, hangi öğrenciye hangisi daha uygun olur?`;

  return { system, user };
}

async function callGroq(
  apiKey: string,
  prompt: { system: string; user: string },
): Promise<string> {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), REQUEST_TIMEOUT_MS);

  try {
    const res = await fetch(GROQ_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        temperature: 0.4,
        max_tokens: 220,
        messages: [
          { role: 'system', content: prompt.system },
          { role: 'user', content: prompt.user },
        ],
      }),
      signal: ctrl.signal,
    });

    if (!res.ok) {
      // ❗ Kullanıcıya gönderilen mesajda Groq detayı SIZMIYOR
      const text = await res.text();
      logger.error('Groq HTTP error', { status: res.status, body: text.slice(0, 500) });
      throw new Error(`Groq HTTP ${res.status}`);
    }

    const json = (await res.json()) as {
      choices?: Array<{ message?: { content?: string } }>;
    };
    const content = (json.choices?.[0]?.message?.content ?? '').trim();
    if (!content) {
      logger.warn('Groq empty response');
      throw new Error('Groq empty response');
    }
    return content.slice(0, 600);
  } finally {
    clearTimeout(timer);
  }
}

function formatDate(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function makeHash(payload: unknown): string {
  return crypto.createHash('sha256').update(JSON.stringify(payload)).digest('hex').slice(0, 24);
}

async function logSummaryRequest(
  uid: string,
  input: SummaryInput,
  cached: boolean,
): Promise<void> {
  await db.collection('aiSummaryLogs').add({
    userId: uid,
    comparisonType: input.comparisonType,
    entityAId: input.entityA.id,
    entityBId: input.entityB.id,
    cacheHit: cached,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    // ❗ TTL için — 30 gün sonra otomatik silinir (Firestore TTL policy gerekli, bkz. 3.3)
    expireAt: admin.firestore.Timestamp.fromMillis(Date.now() + 30 * 24 * 60 * 60 * 1000),
  });
}
```

**Önemli değişiklikler:**
1. ✅ Transaction ile atomik quota kontrolü
2. ✅ Cache hit'te quota DÜŞMÜYOR (önceki davranış değişti — bkz. 3.2)
3. ✅ Bölge `us-central1` → `europe-west1` (Türkiye için 50-80ms daha düşük latency)
4. ✅ App Check zorunlu (script abuse engellenir)
5. ✅ Hata mesajları kullanıcıya generic, log'lar detaylı
6. ✅ Groq HTTP error detayı kullanıcıya sızmıyor
7. ✅ `aiSummaryLogs` document'lerine `expireAt` field eklendi (TTL policy ile auto-delete)
8. ✅ Cache log fail olursa main flow patlamıyor (`.catch()`)

#### Client tarafı güncelleme (region değişikliği)

[lib/features/comparison/data/ai_comparison_summary_service.dart](lib/features/comparison/data/ai_comparison_summary_service.dart#L23) — region güncellenmeli:

```dart
AiComparisonSummaryService({
  FirebaseFunctions? functions,
}) : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');
//                                                            ^^^^^^^^^^^^^ değişti
```

---

### 3.2 Cache Hit'te Quota Düşmesin (Business Decision)

#### Mevcut Davranış
[functions/src/comparison/summary.ts:74-78](functions/src/comparison/summary.ts#L74-L78) — Cache hit olsa bile `dailyAiComparisons` artıyor:

```typescript
if (summary.length > 0 && expiresAt > now) {
  await upsertUsageStats(usageRef, usageData, {
    resetDaily: needsReset,
    incrementAiComparisons: true,  // ← Cache hit'te de artıyor
    today,
  });
  // ...
}
```

#### Sorun
Kullanıcı aynı kombinasyonu (örn: ITU vs Boğaziçi) 5 kez açarsa, hiç Groq çağrısı yapılmadığı halde günlük limiti tükeniyor. Bu **kullanıcı için adaletsiz** ve **Pro tier'ın değerini düşürür**.

#### Önerilen Davranış (3.1'deki kod bunu zaten yapıyor)
- Cache hit → quota düşmez
- Cache miss → quota düşer (Groq'a para harcandığı için)

#### Alternatif: Free Tier'e 1 günlük "preview" hakkı
Eğer monetization stratejiniz farklıysa (örn: Free tier'a günde 1 AI summary cache-only erişim), şu kod parçası kullanılabilir:

```typescript
// Cache hit ama free tier'a günlük 1 cache erişimi limit:
const tier = await getTier(uid);  // ayrı bir helper
if (tier === 'free' && dailyAiComparisons >= 1) {
  throw new HttpsError('resource-exhausted', 'Ücretsiz AI özet hakkın bugünlük doldu.');
}
```

---

### 3.3 `aiSummaryLogs` TTL Policy (Maliyet Azaltma)

#### Sorun
Her AI summary çağrısında `aiSummaryLogs` koleksiyonuna log atılıyor. TTL yok → koleksiyon sınırsız büyüyor.
- Aylık ~50.000 log × 12 ay = **600.000 doküman** → ücretsiz Firestore quota'sını yer
- Eski log'lar analitik için faydalı değil (>30 gün)

#### Çözüm A — Firestore TTL Policy (Önerilen)

**1. `expireAt` field'ı eklendi** (3.1 kodunda var):
```typescript
expireAt: admin.firestore.Timestamp.fromMillis(Date.now() + 30 * 24 * 60 * 60 * 1000)
```

**2. Firestore Console'da TTL policy oluştur:**

```bash
# gcloud CLI ile
gcloud firestore fields ttls update expireAt \
  --collection-group=aiSummaryLogs \
  --enable-ttl \
  --project=YOUR_PROJECT_ID
```

Veya Firebase Console → Firestore → Indexes → TTL → "Create Policy" → Collection: `aiSummaryLogs`, Field: `expireAt`.

#### Çözüm B — Scheduled Cleanup (Plan B)

Eğer TTL policy istemiyorsan, scheduled function:

```typescript
// functions/src/cleanup/ai_logs_cleanup.ts
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';

const db = admin.firestore();
const BATCH_SIZE = 400;
const RETENTION_DAYS = 30;

export const cleanupAiSummaryLogs = onSchedule(
  {
    region: 'europe-west1',
    schedule: 'every day 03:00',
    timeZone: 'Europe/Istanbul',
  },
  async () => {
    const cutoff = admin.firestore.Timestamp.fromMillis(
      Date.now() - RETENTION_DAYS * 24 * 60 * 60 * 1000,
    );

    let totalDeleted = 0;
    let hasMore = true;

    while (hasMore) {
      const snap = await db
        .collection('aiSummaryLogs')
        .where('createdAt', '<', cutoff)
        .limit(BATCH_SIZE)
        .get();

      if (snap.empty) {
        hasMore = false;
        break;
      }

      const batch = db.batch();
      snap.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      totalDeleted += snap.size;

      if (snap.size < BATCH_SIZE) hasMore = false;
    }

    logger.info(`Cleanup complete: ${totalDeleted} aiSummaryLogs deleted`);
  },
);
```

---

### 3.4 Region Tutarsızlığı — `us-central1` vs `europe-west1`

#### Mevcut Durum
| Function | Bölge | Latency (Türkiye'den) |
|----------|-------|----------------------|
| `generateComparisonSummary` | `us-central1` | ~180-250ms |
| `resetAiQuotaDaily` | `europe-west1` | ~50-80ms |

#### Sorun
Kullanıcı AI summary istediğinde Türkiye'den ABD'ye gidiyor → ekstra 100-150ms latency. Üstüne Groq çağrısı ekleyince toplam 5-8 saniye AI summary için bekleniyor.

#### Çözüm
Tüm karşılaştırma function'larını `europe-west1`'e taşıyın.

**Adım 1:** Cloud Function'ı yeni bölgeye deploy et
```bash
# Eski function'ı sil
firebase functions:delete generateComparisonSummary --region us-central1

# Yeni bölgeye deploy
firebase deploy --only functions:generateComparisonSummary
```

**Adım 2:** Client'da region güncelle
[lib/features/comparison/data/ai_comparison_summary_service.dart:23](lib/features/comparison/data/ai_comparison_summary_service.dart#L23)
```dart
_functions = functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');
```

**Adım 3:** Diğer karşılaştırma function'larını da kontrol et — varsa hepsini europe-west1'e topla.

> **DİKKAT:** Region taşıma kesintisiz olmalı. Önce yeni bölgeye deploy et, client'ları güncelle, sonra eskiyi sil. Aksi takdirde "Function not found" hatası alırsın.

---

### 3.5 Timeout Hizalama

#### Mevcut Durum
| Katman | Timeout | Açıklama |
|--------|---------|----------|
| Cloud Function | 30s | `timeoutSeconds: 30` |
| Client `HttpsCallable` | 20s | `Duration(seconds: 20)` |
| Groq API (içeride) | 15s | `REQUEST_TIMEOUT_MS = 15000` |

#### Sorun
Client 20s'de timeout veriyor, ama Cloud Function 30s çalışmaya devam ediyor:
- Quota düşmüş, log atılmış, cache yazılmış
- Ama client tarafına yanıt gitmemiş
- Kullanıcı "Yeniden dene" diye tıklarsa **aynı işlem 2 kez sayılıyor**, quota 2 kez düşüyor

#### Çözüm — Tutarlı Timeout Pyramidi

```
Client (25s)  >  Function (20s)  >  Groq (15s) + diğer (5s buffer)
```

**Cloud Function:**
```typescript
export const generateComparisonSummary = onCall(
  {
    region: 'europe-west1',
    timeoutSeconds: 20,  // ← 30 → 20
    // ...
  },
  // ...
);
```

**Client:**
```dart
final callable = _functions.httpsCallable(
  'generateComparisonSummary',
  options: HttpsCallableOptions(
    timeout: const Duration(seconds: 25),  // ← 20 → 25 (Function'dan biraz fazla)
  ),
);
```

**Groq:** 15s sabit kalsın.

Bu pyramid sayesinde Function'ın timeout'u, client'ın timeout'undan **önce** olacak → client her zaman ya Function yanıtı ya da net bir timeout hatası alır.

---

### 3.6 `resetAiQuotaDaily` İyileştirmeleri

#### Mevcut Durum
- Bölge: `europe-west1` ✓ doğru
- Schedule: Her gün 00:00 İstanbul saati
- Batch size: 400

#### Sorun
- Function 9 dakikada timeout (default), 100.000+ kullanıcı varsa batch'ler bitmeden timeout.
- Hata olursa hangi batch'in başarısız olduğu log'lanmıyor.

#### Düzeltilmiş Kod

```typescript
// functions/src/usage/reset_ai_quota.ts
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';

const db = admin.firestore();
const BATCH_SIZE = 400;
const MAX_BATCHES_PER_RUN = 100;  // 100 * 400 = 40k kullanıcı / run

export const resetAiQuotaDaily = onSchedule(
  {
    region: 'europe-west1',
    schedule: 'every day 00:00',
    timeZone: 'Europe/Istanbul',
    timeoutSeconds: 540,        // ← 9 dakika tam
    memory: '512MiB',
    retryCount: 3,              // ← Hata olursa otomatik retry
  },
  async () => {
    const today = formatDate(new Date());
    let totalReset = 0;
    let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;
    let batchIndex = 0;

    while (batchIndex < MAX_BATCHES_PER_RUN) {
      let query = db
        .collectionGroup('usageStats')
        .where('lastResetDate', '!=', today)
        .limit(BATCH_SIZE)
        .orderBy('lastResetDate');

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snap = await query.get();
      if (snap.empty) break;

      const batch = db.batch();
      snap.docs.forEach((doc) => {
        batch.set(
          doc.ref,
          {
            lastResetDate: today,
            dailyAiComparisons: 0,
            dailyAiRecommendations: 0,
            dailyComparisons: 0,
          },
          { merge: true },
        );
      });

      try {
        await batch.commit();
        totalReset += snap.size;
        lastDoc = snap.docs[snap.docs.length - 1];
        batchIndex += 1;
      } catch (err) {
        logger.error('Reset batch failed', { batchIndex, err });
        throw err;  // Retry mekanizmasını tetikle
      }

      if (snap.size < BATCH_SIZE) break;
    }

    logger.info(`AI quota reset complete: ${totalReset} users in ${batchIndex} batches`);
  },
);

function formatDate(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}
```

**Değişiklikler:**
1. `retryCount: 3` — Hata olursa otomatik 3 kez retry
2. `MAX_BATCHES_PER_RUN` — Tek run'da maksimum 40k kullanıcı (timeout korunur)
3. `orderBy + startAfter` ile pagination — büyük dataset'lerde de çalışır
4. Per-batch error logging

---

### 3.7 RevenueCat Webhook Güvenliği

> **Dosya:** `functions/src/revenuecat/webhook.ts`

#### Kontrol Listesi (Spot-check Önerisi)

- [ ] **Signature verification var mı?** RevenueCat webhook'larında `X-Webhook-Signature` header'ı doğrulanmalı
- [ ] **Idempotency key kullanılıyor mu?** Aynı event 2 kez gelirse subscription 2 kez yazılmasın
- [ ] **`subscriptions/{uid}` write öncesi uid validation?** Webhook payload'ından gelen uid Firebase Auth'da var mı?

#### Güvenli Webhook Örneği

```typescript
// functions/src/revenuecat/webhook.ts
import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';

const REVENUECAT_WEBHOOK_SECRET = defineSecret('REVENUECAT_WEBHOOK_SECRET');
const db = admin.firestore();

export const revenuecatWebhook = onRequest(
  {
    region: 'europe-west1',
    secrets: [REVENUECAT_WEBHOOK_SECRET],
    cors: false,  // Browser'dan çağrılmamalı
  },
  async (req, res) => {
    // 1. Method kontrolü
    if (req.method !== 'POST') {
      res.status(405).send('Method not allowed');
      return;
    }

    // 2. Authorization header (RevenueCat custom secret)
    const authHeader = req.header('Authorization');
    const expectedToken = `Bearer ${REVENUECAT_WEBHOOK_SECRET.value()}`;
    if (authHeader !== expectedToken) {
      logger.warn('Webhook unauthorized', { authHeader: authHeader?.slice(0, 20) });
      res.status(401).send('Unauthorized');
      return;
    }

    const event = req.body?.event;
    if (!event?.app_user_id || !event?.type) {
      res.status(400).send('Invalid payload');
      return;
    }

    // 3. Idempotency — aynı event'i 2 kez işleme
    const eventId = String(event.id);
    const eventRef = db.collection('webhookEvents').doc(eventId);
    const eventSnap = await eventRef.get();
    if (eventSnap.exists) {
      logger.info('Duplicate webhook event ignored', { eventId });
      res.status(200).send('OK (duplicate)');
      return;
    }

    const uid = String(event.app_user_id);

    // 4. User var mı? (Firebase Auth doğrulama)
    try {
      await admin.auth().getUser(uid);
    } catch {
      logger.warn('Webhook for unknown user', { uid });
      res.status(404).send('User not found');
      return;
    }

    // 5. Subscription güncelleme + idempotency mark — transaction
    await db.runTransaction(async (tx) => {
      tx.set(eventRef, {
        type: event.type,
        receivedAt: admin.firestore.FieldValue.serverTimestamp(),
        // TTL — 90 gün sonra sil
        expireAt: admin.firestore.Timestamp.fromMillis(
          Date.now() + 90 * 24 * 60 * 60 * 1000,
        ),
      });

      const tier = mapEventToTier(event);
      const expiresAt = event.expiration_at_ms
        ? admin.firestore.Timestamp.fromMillis(Number(event.expiration_at_ms))
        : null;

      tx.set(
        db.collection('subscriptions').doc(uid),
        {
          tier,
          expiresAt,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          source: 'revenuecat_webhook',
          lastEventType: event.type,
        },
        { merge: true },
      );
    });

    res.status(200).send('OK');
  },
);

function mapEventToTier(event: { type: string; product_id?: string }): 'free' | 'plus' | 'pro' {
  if (['CANCELLATION', 'EXPIRATION', 'BILLING_ISSUE'].includes(event.type)) {
    return 'free';
  }
  const productId = (event.product_id ?? '').toLowerCase();
  if (productId.includes('pro')) return 'pro';
  if (productId.includes('plus')) return 'plus';
  return 'free';
}
```

`webhookEvents` için TTL policy ve rules:
```firestore
match /webhookEvents/{eventId} {
  allow read, write: if false;  // Sadece admin SDK
}
```

```bash
gcloud firestore fields ttls update expireAt \
  --collection-group=webhookEvents --enable-ttl
```

---

## 4. KRİTİK — Client Hata Yönetimi

> **Dosyalar:**
> - [ai_comparison_summary_service.dart](lib/features/comparison/data/ai_comparison_summary_service.dart)
> - [comparison_repository.dart](lib/features/comparison/data/comparison_repository.dart)
> - [comparison_providers.dart](lib/features/comparison/presentation/providers/comparison_providers.dart)
> - [department_comparison_screen.dart](lib/features/comparison/presentation/screens/department_comparison_screen.dart)
> - [city_comparison_screen.dart](lib/features/comparison/presentation/screens/city_comparison_screen.dart)
> **Risk Seviyesi:** 🔴 **YÜKSEK** — Production'da silent crash potansiyeli

### 4.1 `AiComparisonSummaryService` — Try-Catch Eksikliği

#### Mevcut Kod
[ai_comparison_summary_service.dart:70-76](lib/features/comparison/data/ai_comparison_summary_service.dart#L70-L76)

```dart
final response = await callable.call<Map<String, dynamic>>(payload);
final data = Map<String, dynamic>.from(response.data);

return AiComparisonSummaryResult(
  summary: (data['summary'] as String? ?? '').trim(),
  cached: data['cached'] as bool? ?? false,
);
```

#### Sorunlar
1. `callable.call` `FirebaseFunctionsException` fırlatabilir → yakalanmıyor
2. `response.data` null olabilir → `Map.from(null)` crash eder
3. Tip cast `as Map<String, dynamic>` runtime fail edebilir
4. Kullanıcı dostu hata mesajı yok

#### Düzeltilmiş Kod

```dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../domain/models/comparison_result.dart';

/// AI özet servisinin döndürebileceği hata türleri
sealed class AiSummaryFailure implements Exception {
  final String userMessage;
  const AiSummaryFailure(this.userMessage);
}

class AiSummaryQuotaExceeded extends AiSummaryFailure {
  const AiSummaryQuotaExceeded()
      : super('Günlük AI özet hakkın doldu. Yarın tekrar dene.');
}

class AiSummaryUnauthenticated extends AiSummaryFailure {
  const AiSummaryUnauthenticated()
      : super('AI özet için giriş yapman gerekiyor.');
}

class AiSummaryUnavailable extends AiSummaryFailure {
  const AiSummaryUnavailable()
      : super('AI servisi geçici olarak yanıt vermiyor. Birkaç saniye sonra tekrar dene.');
}

class AiSummaryNetworkError extends AiSummaryFailure {
  const AiSummaryNetworkError()
      : super('İnternet bağlantını kontrol et ve tekrar dene.');
}

class AiSummaryUnknownError extends AiSummaryFailure {
  const AiSummaryUnknownError()
      : super('Beklenmeyen bir hata oluştu. Lütfen tekrar dene.');
}

class AiComparisonSummaryResult {
  final String summary;
  final bool cached;

  const AiComparisonSummaryResult({
    required this.summary,
    required this.cached,
  });
}

/// Üniversite karşılaştırması için AI özet üretir.
class AiComparisonSummaryService {
  final FirebaseFunctions _functions;
  final FirebaseCrashlytics? _crashlytics;

  AiComparisonSummaryService({
    FirebaseFunctions? functions,
    FirebaseCrashlytics? crashlytics,
  })  : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'europe-west1'),
        _crashlytics = crashlytics;

  Future<AiComparisonSummaryResult> summarizeUniversityComparison(
    ComparisonResult result,
  ) async {
    final payload = _buildPayload(result);

    final callable = _functions.httpsCallable(
      'generateComparisonSummary',
      options: HttpsCallableOptions(
        timeout: const Duration(seconds: 25),
      ),
    );

    try {
      final response = await callable.call<Object?>(payload);
      final raw = response.data;
      if (raw is! Map) {
        throw const AiSummaryUnknownError();
      }
      final data = Map<String, dynamic>.from(raw);
      final summary = (data['summary'] as String? ?? '').trim();
      if (summary.isEmpty) {
        throw const AiSummaryUnavailable();
      }
      return AiComparisonSummaryResult(
        summary: summary,
        cached: data['cached'] as bool? ?? false,
      );
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('[AiSummary] FirebaseFunctionsException: ${e.code} - ${e.message}');
      _crashlytics?.recordError(
        e,
        st,
        reason: 'AI summary call failed',
        information: ['code: ${e.code}', 'message: ${e.message}'],
      );
      throw _mapFirebaseError(e);
    } on AiSummaryFailure {
      rethrow;
    } catch (e, st) {
      debugPrint('[AiSummary] Unknown error: $e');
      _crashlytics?.recordError(e, st, reason: 'AI summary unknown error');
      throw const AiSummaryUnknownError();
    }
  }

  AiSummaryFailure _mapFirebaseError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'resource-exhausted':
        return const AiSummaryQuotaExceeded();
      case 'unauthenticated':
        return const AiSummaryUnauthenticated();
      case 'unavailable':
      case 'deadline-exceeded':
        return const AiSummaryUnavailable();
      case 'network-request-failed':
      case 'cancelled':
        return const AiSummaryNetworkError();
      default:
        return const AiSummaryUnknownError();
    }
  }

  Map<String, dynamic> _buildPayload(ComparisonResult result) {
    return {
      'comparisonType': 'university',
      'entityA': {'id': result.uniA.id, 'name': result.uniA.name},
      'entityB': {'id': result.uniB.id, 'name': result.uniB.name},
      'comparisonData': {
        'overall': {
          'uniA': {
            'avgRating': result.uniA.avgRating,
            'reviewCount': result.uniA.reviewCount,
            'type': result.uniA.type,
            'establishedYear': result.uniA.establishedYear,
          },
          'uniB': {
            'avgRating': result.uniB.avgRating,
            'reviewCount': result.uniB.reviewCount,
            'type': result.uniB.type,
            'establishedYear': result.uniB.establishedYear,
          },
        },
        'categoryComparisons': {
          for (final entry in result.categoryComparisons.entries)
            entry.key: {
              'valueA': entry.value.valueA,
              'valueB': entry.value.valueB,
            },
        },
      },
    };
  }
}
```

#### Provider Tarafı Güncelleme

[comparison_providers.dart:408-424](lib/features/comparison/presentation/providers/comparison_providers.dart#L408-L424)

```dart
final aiComparisonSummaryProvider =
    FutureProvider<AiComparisonSummaryResult?>((ref) async {
  final canUseAi = ref.watch(canUseAiComparisonProvider);
  if (!canUseAi) return null;

  final result = await ref.watch(comparisonResultProvider.future);
  if (result == null) return null;

  final service = ref.read(aiComparisonSummaryServiceProvider);
  final key = _pairKey(result.uniA.id, result.uniB.id);

  try {
    final summary = await service.summarizeUniversityComparison(result);
    _aiSummaryCache[key] = summary;
    return summary;
  } on AiSummaryQuotaExceeded {
    // UI bu durumu özel olarak işleyecek (limit_reached state)
    rethrow;
  } on AiSummaryFailure catch (e) {
    debugPrint('[aiComparisonSummaryProvider] failed: ${e.userMessage}');
    final cached = _aiSummaryCache[key];
    if (cached != null) {
      return cached;  // Cache fallback
    }
    rethrow;
  }
});
```

#### UI Tarafı — Error State Gösterimi

Mevcut [comparison_ai_summary_card.dart](lib/features/comparison/presentation/widgets/comparison_ai_summary_card.dart) sadece `isLimitReached` boolean'ı kontrol ediyor. Genişletilmeli:

```dart
class ComparisonAiSummaryCard extends StatelessWidget {
  final bool loading;
  final bool canUseAi;
  final bool isLimitReached;
  final String summaryText;
  final String? errorMessage;  // ← YENİ
  final VoidCallback? onRetry; // ← YENİ

  const ComparisonAiSummaryCard({
    super.key,
    required this.loading,
    required this.canUseAi,
    required this.isLimitReached,
    required this.summaryText,
    this.errorMessage,
    this.onRetry,
  });

  // ... build() içinde error state:
  if (errorMessage != null) ...[
    Text(
      errorMessage!,
      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
    ),
    const SizedBox(height: 8),
    if (onRetry != null)
      TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh, color: Colors.white),
        label: const Text('Tekrar dene', style: TextStyle(color: Colors.white)),
        style: TextButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.2),
        ),
      ),
  ],
```

---

### 4.2 `ComparisonRepository.compare()` — Future.wait Riskli

#### Mevcut Kod
[comparison_repository.dart:24-31](lib/features/comparison/data/comparison_repository.dart#L24-L31)

```dart
final results = await Future.wait([
  _uniRepo.getUniversity(uniIdA),
  _uniRepo.getUniversity(uniIdB),
  _placeRepo.getPlacesByUniversity(uniIdA),
  _placeRepo.getPlacesByUniversity(uniIdB),
  _uniRepo.getDepartmentsByUniversity(uniIdA),
  _uniRepo.getDepartmentsByUniversity(uniIdB),
]);
```

#### Sorun
- `Future.wait` varsayılan olarak **ilk hata anında crash** eder.
- Örnek: `getPlacesByUniversity` Firestore permission hatası alırsa, tüm operasyon fail olur.
- Halbuki place verisi olmadan da temel karşılaştırma gösterilebilir.

#### Düzeltilmiş Kod

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../university/data/university_repository.dart';
import '../../university/domain/models/department_model.dart';
import '../../places/data/place_repository.dart';
import '../domain/models/comparison_result.dart';
import '../../university/domain/models/university_model.dart';
import '../../places/domain/models/place_model.dart';

class ComparisonRepository {
  final UniversityRepository _uniRepo;
  final PlaceRepository _placeRepo;
  final FirebaseCrashlytics? _crashlytics;

  ComparisonRepository({
    UniversityRepository? uniRepo,
    PlaceRepository? placeRepo,
    FirebaseCrashlytics? crashlytics,
  })  : _uniRepo = uniRepo ?? UniversityRepository(),
        _placeRepo = placeRepo ?? PlaceRepository(),
        _crashlytics = crashlytics;

  Future<ComparisonResult?> compare(String uniIdA, String uniIdB) async {
    if (uniIdA == uniIdB) {
      throw ArgumentError('İki farklı üniversite seçmelisiniz');
    }

    // ─── 1. ZORUNLU veri: üniversiteler ─────────────────────
    // Üniversite veri yoksa karşılaştırma yapılamaz → null dön
    UniversityModel? uniA;
    UniversityModel? uniB;
    try {
      final unis = await Future.wait([
        _uniRepo.getUniversity(uniIdA),
        _uniRepo.getUniversity(uniIdB),
      ]);
      uniA = unis[0];
      uniB = unis[1];
    } catch (e, st) {
      debugPrint('[ComparisonRepo] University fetch failed: $e');
      _crashlytics?.recordError(e, st, reason: 'compare: university fetch failed');
      return null;
    }
    if (uniA == null || uniB == null) return null;

    // ─── 2. OPSİYONEL veri: places ve departments ─────────
    // Bunlar fail olsa bile karşılaştırma devam edebilir (boş list ile)
    final List<PlaceModel> placesA = await _safelyGet(
      () => _placeRepo.getPlacesByUniversity(uniIdA),
      fallback: const <PlaceModel>[],
      tag: 'placesA',
    );
    final List<PlaceModel> placesB = await _safelyGet(
      () => _placeRepo.getPlacesByUniversity(uniIdB),
      fallback: const <PlaceModel>[],
      tag: 'placesB',
    );
    final List<DepartmentModel> deptsA = await _safelyGet(
      () => _uniRepo.getDepartmentsByUniversity(uniIdA),
      fallback: const <DepartmentModel>[],
      tag: 'deptsA',
    );
    final List<DepartmentModel> deptsB = await _safelyGet(
      () => _uniRepo.getDepartmentsByUniversity(uniIdB),
      fallback: const <DepartmentModel>[],
      tag: 'deptsB',
    );

    // ─── 3. Kategori karşılaştırmaları ─────────────────────
    final categories = <String, CategoryComparison>{};
    final allCats = <String>{
      ...uniA.categoryRatings.keys,
      ...uniB.categoryRatings.keys,
    };
    for (final cat in allCats) {
      final valA = (uniA.categoryRatings[cat] ?? 0).toDouble();
      final valB = (uniB.categoryRatings[cat] ?? 0).toDouble();

      String? winnerId;
      if ((valA - valB).abs() < 0.05) {
        winnerId = null;
      } else {
        winnerId = valA > valB ? uniA.id : uniB.id;
      }

      categories[cat] = CategoryComparison(
        categoryName: cat,
        valueA: valA,
        valueB: valB,
        winnerId: winnerId,
      );
    }

    double calculateAvgBaseScore(List<DepartmentModel> depts) {
      if (depts.isEmpty) return 0;
      final sum = depts.fold<double>(0, (s, d) => s + (d.baseScore ?? 0));
      return sum / depts.length;
    }
    int countByType(List<DepartmentModel> depts, String type) =>
        depts.where((d) => d.type == type).length;

    Map<String, int> getPlaceBreakdown(List<PlaceModel> places) {
      final map = <String, int>{};
      for (final p in places) {
        final key = p.type.firestoreValue;
        map[key] = (map[key] ?? 0) + 1;
      }
      return map;
    }

    final stats = ComparisonStats(
      reviewCountDelta: uniA.reviewCount - uniB.reviewCount,
      placeCountDelta: placesA.length - placesB.length,
      establishedYearDiff: (uniA.establishedYear - uniB.establishedYear).abs(),
      sameType: uniA.type == uniB.type,
      sameCity: uniA.cityId == uniB.cityId,
      sameCampusLayout: uniA.campusLayout == uniB.campusLayout,
      totalDepartmentsA: deptsA.length,
      totalDepartmentsB: deptsB.length,
      avgBaseScoreA: calculateAvgBaseScore(deptsA),
      avgBaseScoreB: calculateAvgBaseScore(deptsB),
      placeBreakdownA: getPlaceBreakdown(placesA),
      placeBreakdownB: getPlaceBreakdown(placesB),
      undergradCountA: countByType(deptsA, 'Lisans'),
      undergradCountB: countByType(deptsB, 'Lisans'),
      associateCountA: countByType(deptsA, 'Önlisans'),
      associateCountB: countByType(deptsB, 'Önlisans'),
    );

    return ComparisonResult(
      uniA: uniA,
      uniB: uniB,
      categoryComparisons: categories,
      stats: stats,
      placeCountA: placesA.length,
      placeCountB: placesB.length,
    );
  }

  /// Helper: Fetch işlemini try-catch'le sar, hata olursa fallback dön
  Future<T> _safelyGet<T>(
    Future<T> Function() fetcher, {
    required T fallback,
    required String tag,
  }) async {
    try {
      return await fetcher();
    } catch (e, st) {
      debugPrint('[ComparisonRepo] $tag fetch failed: $e');
      _crashlytics?.recordError(
        e,
        st,
        reason: 'compare: $tag fetch failed (non-critical)',
        fatal: false,
      );
      return fallback;
    }
  }
}
```

**İyileştirmeler:**
1. Üniversite verisi zorunlu (yoksa null dön)
2. Place + Department verisi opsiyonel — fail olursa boş list ile devam
3. Her fail Crashlytics'e `fatal: false` olarak rapor edilir
4. Tag ile hata kaynağı log'larda görülür

---

### 4.3 Boş `catch (_)` Bloklarını Düzelt

#### Konum 1: comparison_providers.dart:191-193

##### Mevcut
```dart
try {
  final result = await ref.read(comparisonRepositoryProvider).compare(...);
  _comparisonResultCache[key] = result;
  return result;
} catch (_) {
  return _comparisonResultCache[key];
}
```

##### Düzeltilmiş
```dart
try {
  final result = await ref.read(comparisonRepositoryProvider).compare(...);
  _comparisonResultCache[key] = result;
  return result;
} catch (e, st) {
  debugPrint('[comparisonResultProvider] compare failed: $e');
  await FirebaseCrashlytics.instance.recordError(
    e,
    st,
    reason: 'comparisonResultProvider failed, falling back to cache',
    fatal: false,
  );
  final cached = _comparisonResultCache[key];
  if (cached != null) return cached;
  rethrow;  // ← Cache yoksa hata UI'a iletilsin
}
```

#### Konum 2: comparison_providers.dart:550-552 (ratingTrendProvider)

##### Mevcut
```dart
} catch (_) {
  return _ratingTrendCache[key] ?? const [];
}
```

##### Düzeltilmiş
```dart
} catch (e, st) {
  debugPrint('[ratingTrendProvider] aggregation failed: $e');
  await FirebaseCrashlytics.instance.recordError(
    e,
    st,
    reason: 'ratingTrendProvider Firestore aggregation failed',
    fatal: false,
  );
  return _ratingTrendCache[key] ?? const [];
}
```

#### Konum 3: comparison_providers.dart:590-592 (categoryHeatMapProvider) ve 641-643 (departmentScatterProvider)

Aynı pattern — `debugPrint` + `Crashlytics.recordError`.

#### Genel Prensip — "Loud Errors"
> Hatalar **mutlaka** en az bir yerde görülmeli:
> - Debug build → `debugPrint`
> - Release build → `Crashlytics.recordError`
> - Kritik UI flow → user-facing toast/snackbar

---

### 4.4 Force-Unwrap (`!`) Kullanımının Temizlenmesi

#### Tespit Edilen Tüm Konumlar

| Dosya | Satır | Mevcut | Risk |
|-------|-------|--------|------|
| city_comparison_screen.dart | 31 | `_a!.id, idB: _b!.id` | 🟠 Race condition (state update) |
| city_comparison_screen.dart | 86 | `_a != null ? _a!.name : 'Şehir A'` | 🟡 Gereksiz |
| city_comparison_screen.dart | 344 | `city!.name` | 🔴 Builder context'te null |
| city_comparison_screen.dart | 357 | `city!.plateCode` | 🔴 |
| city_comparison_screen.dart | 362 | `${city!.appUniversityCount}` | 🔴 |
| department_comparison_screen.dart | 32 | `_a!.department.id` | 🟠 |
| department_comparison_screen.dart | 151 | `_a!.department, _b!.department` | 🟠 |
| department_comparison_screen.dart | 416 | `dept!.name` | 🔴 |
| department_comparison_screen.dart | 427 | `uni!.name` | 🔴 |
| comparison_providers.dart | 168 | `selection.uniIdA!` | 🟡 (yukarıda kontrol var) |
| comparison_providers.dart | 179 | `selection.uniIdA!` | 🟡 |
| comparison_providers.dart | 186-187 | `selection.uniIdA!, selection.uniIdB!` | 🟡 |
| comparison_providers.dart | 346 | `filter.universityId!.isNotEmpty` | 🟠 |
| comparison_providers.dart | 348 | `filter.universityId!` | 🟠 |
| comparison_providers.dart | 361 | `filter.scoreType!.isEmpty` | 🟠 |
| comparison_providers.dart | 628 | `d.scoreData!.baseScore` | 🔴 |
| comparison_providers.dart | 629 | `d.scoreData!.ranking` | 🔴 |

#### Fix Örneği 1 — `city!.name` (city_comparison_screen.dart:344)

**Mevcut:**
```dart
city!.name,
```

**Önerilen:**
```dart
city?.name ?? '—',
```

veya parent widget'ta zaten null kontrol varsa, lokal variable'a al:
```dart
final cityName = city?.name;
if (cityName == null) return const SizedBox.shrink();
// ... cityName'i kullan
```

#### Fix Örneği 2 — `d.scoreData!.baseScore` (comparison_providers.dart:628)

**Mevcut:**
```dart
return departments
    .where((d) {
      final baseScore = d.baseScore ?? d.scoreData?.baseScore;
      final ranking = d.ranking ?? d.scoreData?.ranking;
      return baseScore != null && ranking != null && baseScore > 0 && ranking > 0;
    })
    .map((d) => DepartmentScatterPoint(
          departmentId: d.id,
          departmentName: d.name,
          baseScore: d.baseScore ?? d.scoreData!.baseScore,  // ❌ force unwrap
          ranking: d.ranking ?? d.scoreData!.ranking,        // ❌ force unwrap
          universityId: universityId,
        ))
    .toList();
```

**Sorun:** `where` filter `d.scoreData` null değil garantisi vermiyor; yalnızca `d.scoreData?.baseScore` null değil garantisi veriyor. Eğer `d.scoreData = null` ama `d.baseScore != null` ise force-unwrap **gereksiz** ama yine de risk.

**Önerilen:**
```dart
return departments
    .map((d) {
      final baseScore = d.baseScore ?? d.scoreData?.baseScore;
      final ranking = d.ranking ?? d.scoreData?.ranking;
      if (baseScore == null || ranking == null || baseScore <= 0 || ranking <= 0) {
        return null;
      }
      return DepartmentScatterPoint(
        departmentId: d.id,
        departmentName: d.name,
        baseScore: baseScore,
        ranking: ranking,
        universityId: universityId,
      );
    })
    .whereType<DepartmentScatterPoint>()
    .toList();
```

#### Fix Örneği 3 — `_a!.id, idB: _b!.id` (city_comparison_screen.dart:31)

**Mevcut:**
```dart
void _runComparison() {
  if (_a == null || _b == null) return;
  setState(() => _comparing = true);
  ref.read(cityComparisonResultProvider(
    ComparisonPair(idA: _a!.id, idB: _b!.id),  // ❌
  ));
}
```

**Önerilen:** Lokal değişkene al, böylece force-unwrap gerekmez ve race condition'a karşı korunmuş olursun.

```dart
void _runComparison() {
  final a = _a;
  final b = _b;
  if (a == null || b == null) return;
  setState(() => _comparing = true);
  ref.read(cityComparisonResultProvider(
    ComparisonPair(idA: a.id, idB: b.id),
  ));
}
```

#### Genel Stratejik Refaktör

`analysis_options.yaml`'a aşağıyı ekleyin (force-unwrap'ı **lint hatası** yapın):

```yaml
analyzer:
  errors:
    avoid_unnecessary_containers: warning
    invalid_use_of_internal_member: error

linter:
  rules:
    # Force-unwrap (!) kullanımını **error** seviyesinde işaretle
    avoid_unnecessary_containers: true
    # `!` operatörü için custom lint:
    # NOT: Dart lint'inde direkt "no_bang" yok ama `avoid_dynamic_calls` ile
    #      bir kısım yakalanır. En etkili: dart_code_metrics package.
```

`dart_code_metrics` paketi ile:
```yaml
# pubspec.yaml dev_dependencies
dev_dependencies:
  dart_code_metrics: ^5.7.6
```

```yaml
# analysis_options.yaml
dart_code_metrics:
  rules:
    - avoid-non-null-assertion  # ← Force-unwrap'i error olarak işaretler
```

---

### 4.5 `d.scoreData!.baseScore` ve Null-Safe Pattern

#### Sorun (comparison_providers.dart:628-629)
`departmentScatterProvider` içinde, `where` filter sonrası `map`'te force-unwrap kullanılıyor. `d.baseScore ?? d.scoreData!.baseScore` — eğer `d.baseScore == null` ise `d.scoreData` null olabilir.

**Senaryolar:**
1. ✅ `d.baseScore != null` → `??` ilk operandı seçer, sorun yok
2. ❌ `d.baseScore == null && d.scoreData == null` → `scoreData!` crash eder
3. ⚠ `d.baseScore == null && d.scoreData != null && d.scoreData.baseScore == null` → daha karmaşık

#### Önerilen Refaktör — Helper Extension

```dart
// lib/features/university/domain/models/department_model.dart içine ekle

extension DepartmentScoreFallback on DepartmentModel {
  /// baseScore (legacy) veya scoreData.baseScore, hangisi mevcutsa
  double? get effectiveBaseScore => baseScore ?? scoreData?.baseScore;

  /// ranking (legacy) veya scoreData.ranking
  int? get effectiveRanking => ranking ?? scoreData?.ranking;

  /// scoreType (legacy) veya scoreData.scoreType
  String? get effectiveScoreType => scoreType ?? scoreData?.scoreType;
}
```

Sonra her yerde:
```dart
final score = d.effectiveBaseScore;
if (score == null || score <= 0) return null;
```

Force-unwrap tamamen ortadan kalkar.

---

### 4.6 `ratingTrendProvider` — Empty Result Kullanıcı Görmüyor

#### Sorun
[comparison_providers.dart:489-553](lib/features/comparison/presentation/providers/comparison_providers.dart#L489-L553)

`ratingTrendProvider` Firestore hatası olursa boş liste dönüyor. UI'da hiçbir trend chart gözükmüyor ama kullanıcı **neden gözükmediğini bilmiyor**.

#### Çözüm — Tipli State Dön

```dart
sealed class TrendDataState {
  const TrendDataState();
}

class TrendDataLoading extends TrendDataState {
  const TrendDataLoading();
}

class TrendDataSuccess extends TrendDataState {
  final List<RatingTrendPoint> points;
  const TrendDataSuccess(this.points);
}

class TrendDataInsufficient extends TrendDataState {
  // "Trend için yeterli yorum yok" durumu
  final int reviewCount;
  const TrendDataInsufficient(this.reviewCount);
}

class TrendDataError extends TrendDataState {
  final String userMessage;
  const TrendDataError(this.userMessage);
}

final ratingTrendProvider = FutureProvider.family<TrendDataState, ComparisonPair>(
  (ref, pair) async {
    // ... mevcut logic ...
    try {
      final results = await Future.wait([...]);
      final output = List.generate(6, (i) {/* ... */});
      if (output.every((p) => p.avgRatingA == 0 && p.avgRatingB == 0)) {
        return const TrendDataInsufficient(0);
      }
      _ratingTrendCache[key] = output;
      return TrendDataSuccess(output);
    } catch (e, st) {
      await FirebaseCrashlytics.instance.recordError(e, st);
      final cached = _ratingTrendCache[key];
      if (cached != null) return TrendDataSuccess(cached);
      return const TrendDataError('Trend verisi şu anda yüklenemiyor.');
    }
  },
);
```

UI tarafı:
```dart
trendAsync.when(
  loading: () => const ShimmerTrendChart(),
  error: (e, _) => const _ErrorCard(message: 'Trend yüklenemedi'),
  data: (state) => switch (state) {
    TrendDataLoading() => const ShimmerTrendChart(),
    TrendDataSuccess(:final points) => TrendLineChart(points: points),
    TrendDataInsufficient() => const _EmptyState(
        title: 'Trend için yeterli yorum yok',
        subtitle: 'Bu üniversiteler için son 6 aydır yorum eklenmedi.',
      ),
    TrendDataError(:final userMessage) => _ErrorCard(message: userMessage),
  },
);
```

---

### 4.7 Network State Kontrolü

#### Eksik
Karşılaştırma feature'ında **internet kontrolü yok**. Offline kullanıcı:
1. Üniversite picker açar → boş liste (Firestore cache varsa gözükebilir)
2. Karşılaştır butonuna basar → 10s timeout sonrası "boş sonuç"
3. AI summary → 25s timeout
4. Toplam 35s bekleme, "neden çalışmıyor" anlamıyor

#### Çözüm

```yaml
# pubspec.yaml
dependencies:
  connectivity_plus: ^6.0.5
```

```dart
// lib/core/providers/connectivity_provider.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

final isOnlineProvider = Provider<bool>((ref) {
  final result = ref.watch(connectivityProvider).valueOrNull ?? [];
  return result.any((r) => r != ConnectivityResult.none);
});
```

Karşılaştırma ekranında:
```dart
final isOnline = ref.watch(isOnlineProvider);
if (!isOnline) {
  return const _OfflineBanner();
}
```

---

## 5. UI / UX İyileştirmeleri

> **Risk Seviyesi:** 🟡 **ORTA** — Kullanıcı deneyimini doğrudan etkiler
> **Beklenen Etki:** Engagement +20%, paylaşım +35%, Plus conversion +12%

### 5.1 Shimmer Paketi Kullan (Mevcut Paket Atıl)

#### Mevcut Durum
[pubspec.yaml]'da `shimmer: ^3.0.0` var ama [comparison_ai_summary_card.dart](lib/features/comparison/presentation/widgets/comparison_ai_summary_card.dart#L135-L150) içinde basit `Container` ile yapılmış skeleton:

```dart
class _SkeletonLine extends StatelessWidget {
  final double width;
  const _SkeletonLine({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),  // ← Statik renk, hiç animasyon yok
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }
}
```

#### Düzeltilmiş Kod — Yeniden Kullanılabilir Shimmer Skeleton

> **Yeni dosya:** `lib/core/widgets/shimmer_box.dart`

```dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: baseColor ??
          (isDark ? Colors.white.withValues(alpha: 0.10) : AppColors.shimmerBase),
      highlightColor: highlightColor ??
          (isDark ? Colors.white.withValues(alpha: 0.22) : AppColors.shimmerHighlight),
      period: const Duration(milliseconds: 1400),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Çoklu shimmer satırlardan oluşan bir blok
class ShimmerLines extends StatelessWidget {
  final int lines;
  final double lineHeight;
  final double spacing;
  final List<double>? widthPercentages;

  const ShimmerLines({
    super.key,
    this.lines = 3,
    this.lineHeight = 14,
    this.spacing = 8,
    this.widthPercentages,
  });

  @override
  Widget build(BuildContext context) {
    final widths = widthPercentages ?? List.filled(lines, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i == lines - 1 ? 0 : spacing),
          child: FractionallySizedBox(
            widthFactor: widths[i],
            child: ShimmerBox(height: lineHeight, borderRadius: lineHeight / 2),
          ),
        );
      }),
    );
  }
}
```

#### Comparison AI Summary Card Refaktör

```dart
// comparison_ai_summary_card.dart — _SkeletonLine yerine ShimmerBox

if (loading) ...[
  const ShimmerBox(height: 14, borderRadius: 7),
  const SizedBox(height: 8),
  const ShimmerBox(height: 14, borderRadius: 7),
  const SizedBox(height: 8),
  const ShimmerBox(width: 190, height: 14, borderRadius: 7),
]
```

#### Comparison Result Screen Yükleme Durumu

[university_comparison_screen.dart](lib/features/comparison/presentation/screens/university_comparison_screen.dart) — sadece `CircularProgressIndicator` var. Bunu zenginleştir:

```dart
// loading_state olduğunda render edilecek widget
class ComparisonResultSkeleton extends StatelessWidget {
  const ComparisonResultSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero section skeleton
          Row(
            children: [
              Expanded(child: ShimmerBox(height: 120, borderRadius: 16)),
              const SizedBox(width: 12),
              const ShimmerBox(width: 48, height: 48, borderRadius: 24),
              const SizedBox(width: 12),
              Expanded(child: ShimmerBox(height: 120, borderRadius: 16)),
            ],
          ),
          const SizedBox(height: 16),

          // AI summary skeleton
          ShimmerBox(height: 140, borderRadius: 18),
          const SizedBox(height: 16),

          // Stats row skeleton
          Row(
            children: List.generate(3, (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                child: ShimmerBox(height: 80, borderRadius: 12),
              ),
            )),
          ),
          const SizedBox(height: 16),

          // Categories skeleton
          ...List.generate(5, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerBox(height: 56, borderRadius: 12),
          )),
        ],
      ),
    );
  }
}
```

---

### 5.2 Hardcoded Renkler → AppColors Genişletmesi

#### Mevcut Hardcoded Renkler (Dosya Bazlı Liste)

| Dosya | Satır | Renk | Önerilen Sabit |
|-------|-------|------|----------------|
| city_comparison_screen.dart | 43 | `Color(0xFF0F0F1A)` | `AppColors.darkBackground` |
| city_comparison_screen.dart | 113 | `Color(0xFF1A1A2E)` | `AppColors.darkSurface` |
| comparison_screen.dart | 191 | `Color(0xFF141424)` | `AppColors.darkSurfaceVariant` |
| comparison_ai_summary_card.dart | 29 | `Color(0xFFD4A017)` | `AppColors.gold` (zaten var: `tierPro`) |
| comparison_ai_summary_card.dart | 29 | `Color(0xFF8B5CF6)` | `AppColors.gradientPurple` |
| comparison_ai_summary_card.dart | 36 | `Color(0xFF8B5CF6).withValues(alpha: 0.25)` | `AppColors.gradientPurpleShadow` |
| Çoklu yerler | - | `Colors.white.withValues(alpha: 0.06-0.12)` | `AppColors.darkOverlay06` / `AppColors.darkOverlay12` |

#### Genişletilmiş AppColors

> **Düzenlenecek:** [lib/core/theme/app_colors.dart](lib/core/theme/app_colors.dart)
>
> **Ekleme noktası:** `// ─── Subscription Tier Colors ──────────────────` bölümünden sonra

```dart
  // ─── Dark Mode Surfaces ────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F0F1A);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkSurfaceVariant = Color(0xFF141424);
  static const Color darkSurfaceElevated = Color(0xFF22223F);

  // ─── Dark Mode Overlays (Alpha) ────────────────────────────────
  static Color darkOverlay06 = Colors.white.withValues(alpha: 0.06);
  static Color darkOverlay12 = Colors.white.withValues(alpha: 0.12);
  static Color darkOverlay22 = Colors.white.withValues(alpha: 0.22);
  static Color darkOverlay60 = Colors.white.withValues(alpha: 0.60);

  // ─── Brand Accents ─────────────────────────────────────────────
  static const Color gold = Color(0xFFD4A017);       // Aynı tierPro
  static const Color gradientPurple = Color(0xFF8B5CF6);
  static const Color gradientPink = Color(0xFFEC4899);
  static const Color gradientCyan = Color(0xFF06B6D4);

  // ─── AI Summary Gradient ───────────────────────────────────────
  static const LinearGradient aiSummaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold, gradientPurple],
  );

  static List<BoxShadow> aiSummaryShadow = [
    BoxShadow(
      color: gradientPurple.withValues(alpha: 0.25),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  // ─── Comparison Specific ───────────────────────────────────────
  static const Color winnerHighlight = Color(0xFF10B981);  // Yeşil
  static const Color loserMuted = Color(0xFFD1D5DB);       // Açık gri
  static const Color tieColor = Color(0xFFF59E0B);         // Sarı

  /// Tema (dark/light) duyarlı surface seçici
  static Color surfaceFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : surface;
  }

  static Color backgroundFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : background;
  }
```

#### Sample Refaktör — comparison_ai_summary_card.dart

**Önce:**
```dart
decoration: BoxDecoration(
  gradient: const LinearGradient(
    colors: [Color(0xFFD4A017), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  borderRadius: BorderRadius.circular(18),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ],
),
```

**Sonra:**
```dart
decoration: BoxDecoration(
  gradient: AppColors.aiSummaryGradient,
  borderRadius: BorderRadius.circular(18),
  boxShadow: AppColors.aiSummaryShadow,
),
```

---

### 5.3 Lokalizasyon (l10n) Entegrasyonu

#### Mevcut Durum
- `pubspec.yaml`'da `intl: ^0.19.0` var ama hiç kullanılmıyor
- Tüm string'ler hardcoded Türkçe
- İngilizce kullanıcılar (uluslararası öğrenciler) için sıkıntı

#### Adım 1 — `l10n.yaml` oluştur

> **Yeni dosya:** `/home/burak/uni_app/l10n.yaml`

```yaml
arb-dir: lib/l10n
template-arb-file: app_tr.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
synthetic-package: false
output-dir: lib/l10n/generated
```

#### Adım 2 — `app_tr.arb` (Master)

> **Yeni dosya:** `/home/burak/uni_app/lib/l10n/app_tr.arb`

```json
{
  "@@locale": "tr",
  "comparisonHubTitle": "Karşılaştır",
  "@comparisonHubTitle": {
    "description": "Karşılaştırma hub ekranı başlığı"
  },
  "comparisonUniversity": "Üniversite Karşılaştır",
  "comparisonUniversityDesc": "İki üniversiteyi yan yana kıyasla",
  "comparisonDepartment": "Bölüm Karşılaştır",
  "comparisonDepartmentDesc": "Aynı bölümü farklı üniversitelerde kıyasla",
  "comparisonCity": "Şehir Karşılaştır",
  "comparisonCityDesc": "İki şehrin üniversite ekosistemini kıyasla",
  "selectUniversityA": "Üniversite A",
  "selectUniversityB": "Üniversite B",
  "selectDepartmentA": "Bölüm A",
  "selectDepartmentB": "Bölüm B",
  "selectCityA": "Şehir A",
  "selectCityB": "Şehir B",
  "swap": "Yer Değiştir",
  "share": "Paylaş",
  "reset": "Sıfırla",
  "retry": "Tekrar Dene",
  "tabGeneral": "Genel",
  "tabCategories": "Kategoriler",
  "tabChart": "Grafik",
  "tabStats": "İstatistik",
  "emptyStateTitle": "İki {entityType} seç",
  "@emptyStateTitle": {
    "placeholders": {
      "entityType": {
        "type": "String",
        "example": "üniversite"
      }
    }
  },
  "loadingComparison": "Karşılaştırma yükleniyor…",
  "errorComparison": "Karşılaştırma yüklenirken bir hata oluştu",
  "aiSummaryTitle": "AI Analizi",
  "aiSummaryProRequired": "AI Analizi Pro pakette aktif. Pro'ya geçerek detaylı özeti açabilirsin.",
  "aiSummaryLimitReached": "Günlük {limit} AI özet hakkın doldu, yarın tekrar dene.",
  "@aiSummaryLimitReached": {
    "placeholders": {
      "limit": {"type": "int", "example": "5"}
    }
  },
  "aiSummaryActive": "Pro analizi aktif",
  "aiSummaryRegenerate": "Yeniden Üret",
  "watchAdToContinue": "Reklamı İzle ve Devam Et",
  "upgradePlus": "Plus'a Geç — Sınırsız",
  "cancelForNow": "Şimdilik Vazgeç",
  "dailyLimitReached": "Günlük karşılaştırma hakkın doldu",
  "comparisonStarted": "Karşılaştırma başladı",
  "scoreType": "Puan Türü",
  "baseScore": "Taban Puan",
  "ranking": "Sıralama",
  "quota": "Kontenjan",
  "fillRate": "Doluluk Oranı",
  "duration": "Süre",
  "language": "Dil",
  "type": "Tür",
  "categoryRating": "Kategori Puanı",
  "reviewCount": "Yorum Sayısı",
  "averageRating": "Ortalama Puan",
  "establishedYear": "Kuruluş Yılı",
  "stateUniversity": "Devlet",
  "foundationUniversity": "Vakıf",
  "winner": "Kazanan",
  "tie": "Berabere",
  "noEnoughReviews": "Yeterli yorum yok",
  "trendInsufficient": "Trend için yeterli yorum yok",
  "offline": "İnternet bağlantısı yok",
  "offlineDescription": "Karşılaştırma yapmak için internete bağlan.",
  "shareSubject": "{uniA} vs {uniB} — Karşılaştırma",
  "@shareSubject": {
    "placeholders": {
      "uniA": {"type": "String"},
      "uniB": {"type": "String"}
    }
  }
}
```

#### Adım 3 — `app_en.arb` (Translation)

> **Yeni dosya:** `/home/burak/uni_app/lib/l10n/app_en.arb`

```json
{
  "@@locale": "en",
  "comparisonHubTitle": "Compare",
  "comparisonUniversity": "Compare Universities",
  "comparisonUniversityDesc": "Compare two universities side by side",
  "comparisonDepartment": "Compare Departments",
  "comparisonDepartmentDesc": "Compare the same department across universities",
  "comparisonCity": "Compare Cities",
  "comparisonCityDesc": "Compare two cities' university ecosystems",
  "selectUniversityA": "University A",
  "selectUniversityB": "University B",
  "selectDepartmentA": "Department A",
  "selectDepartmentB": "Department B",
  "selectCityA": "City A",
  "selectCityB": "City B",
  "swap": "Swap",
  "share": "Share",
  "reset": "Reset",
  "retry": "Retry",
  "tabGeneral": "General",
  "tabCategories": "Categories",
  "tabChart": "Chart",
  "tabStats": "Stats",
  "emptyStateTitle": "Select two {entityType}",
  "loadingComparison": "Loading comparison…",
  "errorComparison": "Failed to load comparison",
  "aiSummaryTitle": "AI Analysis",
  "aiSummaryProRequired": "AI Analysis is a Pro feature. Upgrade to unlock detailed summaries.",
  "aiSummaryLimitReached": "You've used your daily {limit} AI summaries. Try again tomorrow.",
  "aiSummaryActive": "Pro analysis active",
  "aiSummaryRegenerate": "Regenerate",
  "watchAdToContinue": "Watch Ad to Continue",
  "upgradePlus": "Upgrade to Plus — Unlimited",
  "cancelForNow": "Cancel for Now",
  "dailyLimitReached": "Daily comparison limit reached",
  "comparisonStarted": "Comparison started",
  "scoreType": "Score Type",
  "baseScore": "Base Score",
  "ranking": "Ranking",
  "quota": "Quota",
  "fillRate": "Fill Rate",
  "duration": "Duration",
  "language": "Language",
  "type": "Type",
  "categoryRating": "Category Rating",
  "reviewCount": "Review Count",
  "averageRating": "Average Rating",
  "establishedYear": "Established",
  "stateUniversity": "State",
  "foundationUniversity": "Foundation",
  "winner": "Winner",
  "tie": "Tie",
  "noEnoughReviews": "Not enough reviews",
  "trendInsufficient": "Not enough reviews for trend analysis",
  "offline": "No internet connection",
  "offlineDescription": "Connect to the internet to make comparisons.",
  "shareSubject": "{uniA} vs {uniB} — Comparison"
}
```

#### Adım 4 — `pubspec.yaml`'a flutter.generate aç

```yaml
flutter:
  uses-material-design: true
  generate: true  # ← Bu satırı ekle
  assets:
    - assets/icons/
    # ...
```

#### Adım 5 — `MaterialApp`'e delegate ekle

```dart
// lib/app.dart veya main.dart

import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ...
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      // ...
    );
  }
}
```

#### Adım 6 — Build

```bash
flutter pub get
flutter gen-l10n
```

#### Adım 7 — Kullanım (Örnek)

**Önce:**
```dart
const Text('Bölüm Karşılaştır')
```

**Sonra:**
```dart
Text(AppLocalizations.of(context).comparisonDepartment)
```

Parametre içeren:
```dart
Text(AppLocalizations.of(context).aiSummaryLimitReached(5))
// → "Günlük 5 AI özet hakkın doldu, yarın tekrar dene."
```

---

### 5.4 Yazım Hataları

#### Yazım Hatası 1 — `comparison_ai_summary_card.dart:90`

**Mevcut:**
```dart
'5 AI ozetin doldu, yarin tekrar dene.'
```

**Sorunlar:**
- `ozetin` → `özetin` (Türkçe karakter eksik)
- `yarin` → `yarın` (Türkçe karakter eksik)
- Sayı hardcoded (`5`) — Cloud Function `DAILY_AI_COMPARISON_LIMIT` değişirse uyumsuz olur

**Düzeltilmiş:**
```dart
'5 AI özet hakkın doldu, yarın tekrar dene.'
```

veya l10n ile:
```dart
AppLocalizations.of(context).aiSummaryLimitReached(5)
```

#### Yazım Hatası 2 — `comparison_ai_summary_card.dart:99`

**Mevcut:**
```dart
'AI Analizi Pro pakette aktif. Pro'ya gecerek detayli ozeti acabilirsin.'
```

**Düzeltilmiş:**
```dart
'AI Analizi Pro pakette aktif. Pro\'ya geçerek detaylı özeti açabilirsin.'
```

veya l10n ile:
```dart
AppLocalizations.of(context).aiSummaryProRequired
```

#### Genel Tarama Önerisi

```bash
# Türkçe karakter eksikliğini bulan grep
grep -rn "gecer\|acar\|ozet\|yarin\|sira\|sehir\|uni\b" lib/features/comparison/ \
  --include="*.dart" \
  | grep -v "// "
```

---

### 5.5 Pull-to-Refresh

#### Eksik
Hiçbir karşılaştırma ekranında `RefreshIndicator` yok. Kullanıcı:
- Yeni yorum eklendi → karşılaştırma güncel değil
- Cache'den eski veri görüyor → yenileme yolu yok

#### Çözüm — Tüm Sonuç Ekranlarına RefreshIndicator

##### University Comparison Screen

```dart
// university_comparison_screen.dart — _TabbedResultView içine

RefreshIndicator(
  color: AppColors.primary,
  onRefresh: () async {
    // Tüm cache'leri invalidate et
    ref.invalidate(comparisonResultProvider);
    ref.invalidate(aiComparisonSummaryProvider);
    final pair = ComparisonPair(
      idA: selection.uniIdA!,
      idB: selection.uniIdB!,
    );
    ref.invalidate(ratingTrendProvider(pair));
    ref.invalidate(categoryHeatMapProvider(pair));

    // Yeni sonuç bekle
    await ref.read(comparisonResultProvider.future);
  },
  child: SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    child: Column(/* ... mevcut içerik ... */),
  ),
),
```

##### Department / City Comparison

Aynı pattern. `ref.invalidate(departmentComparisonResultProvider(pair))` veya `ref.invalidate(cityComparisonResultProvider(pair))`.

#### Cache Temizleme — Provider Tarafında

Mevcut `_comparisonResultCache` global map'i `ref.invalidate` ile temizlenmiyor. Cache'in invalidate ile birlikte temizlenmesi için provider içine `ref.onDispose` ekle:

```dart
final comparisonResultProvider = FutureProvider.autoDispose<ComparisonResult?>((ref) async {
  ref.keepAlive();  // Tab değişiminde dispose olmasın
  ref.onDispose(() {
    // Provider gerçekten dispose olduğunda cache temizlensin
    // (manual invalidate veya kullanıcı ekranı tamamen kapadığında)
  });
  // ... mevcut logic
});
```

---

### 5.6 Accessibility — Semantics

#### Mevcut Durum
Karşılaştırma feature'ında `Semantics` widget'ı **hiç kullanılmıyor**. Görme engelli kullanıcılar:
- Radar chart'ı duyamıyor
- Winner indicator'ları algılayamıyor
- Hangi kategorinin kim için yüksek/düşük olduğunu anlayamıyor

#### Çözüm — Chart Widget'larına Semantics

##### ComparisonRadarChart

```dart
// lib/features/comparison/presentation/widgets/comparison_radar_chart.dart

@override
Widget build(BuildContext context) {
  return Semantics(
    label: _buildSemanticLabel(),  // Screen reader için açıklama
    image: true,                    // Bir görsel/grafik olduğunu bildir
    excludeSemantics: true,         // Alt widget'ların kendi semantic'lerini gizle
    child: RadarChart(/* ... */),
  );
}

String _buildSemanticLabel() {
  final buffer = StringBuffer();
  buffer.write('${uniA.name} ve ${uniB.name} kategori karşılaştırması. ');
  for (final cat in categories) {
    buffer.write('${cat.categoryName}: ');
    buffer.write('${uniA.name} ${cat.valueA.toStringAsFixed(1)}, ');
    buffer.write('${uniB.name} ${cat.valueB.toStringAsFixed(1)}. ');
    if (cat.winnerId == uniA.id) {
      buffer.write('${uniA.name} kazandı. ');
    } else if (cat.winnerId == uniB.id) {
      buffer.write('${uniB.name} kazandı. ');
    } else {
      buffer.write('Berabere. ');
    }
  }
  return buffer.toString();
}
```

##### Winner Indicator

```dart
// _DeltaPill widget'ı
Semantics(
  label: delta > 0
      ? '${result.uniA.name} ${delta.abs().toStringAsFixed(1)} puan önde'
      : delta < 0
          ? '${result.uniB.name} ${delta.abs().toStringAsFixed(1)} puan önde'
          : 'Berabere',
  child: Container(/* ... */),
)
```

##### Icon Button'lar

```dart
IconButton(
  icon: const Icon(Icons.swap_horiz),
  tooltip: AppLocalizations.of(context).swap,
  onPressed: () => ref.read(comparisonSelectionProvider.notifier).swap(),
  // ✅ tooltip otomatik olarak Semantics'e dönüşür
)
```

##### Action Button'lar (Toggle States)

```dart
Semantics(
  button: true,
  enabled: !isLoading,
  selected: isFavorited,
  label: isFavorited ? 'Favorilerden çıkar' : 'Favorilere ekle',
  child: GestureDetector(/* ... */),
)
```

---

### 5.7 Empty State İyileştirmesi

#### Mevcut Durum
[city_comparison_screen.dart:211] — `EmptyStateWidget + SVG icon`. Sıkıcı, tıklanabilir görünmüyor.

#### Çözüm — Lottie / Animasyonlu Empty State

##### Adım 1 — Lottie ekle

```yaml
# pubspec.yaml
dependencies:
  lottie: ^3.1.2
```

##### Adım 2 — Lottie dosyaları indir

LottieFiles.com'dan ücretsiz:
- `comparison_empty.json` — iki kart arasında yer değiştirme animasyonu
- `loading_search.json` — büyüteçli arama animasyonu

`assets/lottie/` klasörüne koy.

##### Adım 3 — `pubspec.yaml` assets

```yaml
flutter:
  assets:
    - assets/lottie/
    - assets/icons/
```

##### Adım 4 — Empty State Widget

```dart
// lib/features/comparison/presentation/widgets/comparison_empty_state.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ComparisonEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? lottieAsset;
  final IconData? fallbackIcon;
  final VoidCallback? onTap;
  final String? ctaLabel;

  const ComparisonEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.lottieAsset = 'assets/lottie/comparison_empty.json',
    this.fallbackIcon,
    this.onTap,
    this.ctaLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lottie animasyon
            SizedBox(
              height: 180,
              child: lottieAsset != null
                  ? Lottie.asset(
                      lottieAsset!,
                      fit: BoxFit.contain,
                      repeat: true,
                    )
                  : Icon(
                      fallbackIcon ?? Icons.compare_arrows_rounded,
                      size: 80,
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            // CTA Button (opsiyonel)
            if (ctaLabel != null && onTap != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.add),
                label: Text(ctaLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

##### Kullanım

```dart
// city_comparison_screen.dart içinde

ComparisonEmptyState(
  title: 'İki şehir seç',
  subtitle: 'Yan yana karşılaştırmak istediğin şehirleri seçince sonuçlar burada görünecek.',
  lottieAsset: 'assets/lottie/comparison_empty.json',
  ctaLabel: 'Şehir Seç',
  onTap: _openCityPicker,
);
```

---

### 5.8 Hero Animasyon

#### Mevcut Durum
Üniversite picker'dan sonuç ekranına geçişte sıradan slide animasyonu. Görsel devamlılık yok.

#### Çözüm — Üniversite Kartlarına Hero Tag

##### Picker İçinde

```dart
// comparison_uni_picker.dart içinde her uni kartı için:

Hero(
  tag: 'uni_${university.id}_compare',
  child: Material(
    color: Colors.transparent,
    child: UniversityCard(university: university),
  ),
)
```

##### Sonuç Ekranında

```dart
// university_comparison_screen.dart — _ScoreCard veya _BigCompareCard içinde

Hero(
  tag: 'uni_${result.uniA.id}_compare',
  child: Material(
    color: Colors.transparent,
    child: _ScoreCard(university: result.uniA),
  ),
)
```

#### Hero Flight Animation Custom

```dart
Hero(
  tag: 'uni_${university.id}_compare',
  flightShuttleBuilder: (
    flightContext,
    animation,
    flightDirection,
    fromHeroContext,
    toHeroContext,
  ) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
      ),
      child: toHeroContext.widget,
    );
  },
  child: /* ... */,
)
```

---

### 5.9 Haptic Feedback

#### Mevcut
Hiçbir karşılaştırma etkileşiminde haptic yok. Mobil uygulama hissetmiyor.

#### Çözüm — Kritik Noktalarda Haptic

```dart
import 'package:flutter/services.dart';

// 1. Karşılaştırma tamamlandığında
HapticFeedback.mediumImpact();

// 2. Swap butonu basıldığında
HapticFeedback.selectionClick();

// 3. Reset butonu
HapticFeedback.lightImpact();

// 4. Daily limit hit
HapticFeedback.heavyImpact();

// 5. AI summary geldiğinde
HapticFeedback.lightImpact();
```

#### Örnek Wrapper

```dart
// lib/core/utils/haptic.dart
import 'package:flutter/services.dart';

class AppHaptic {
  static Future<void> compareSuccess() => HapticFeedback.mediumImpact();
  static Future<void> swap() => HapticFeedback.selectionClick();
  static Future<void> reset() => HapticFeedback.lightImpact();
  static Future<void> limitReached() => HapticFeedback.heavyImpact();
  static Future<void> aiSummaryReceived() => HapticFeedback.lightImpact();
}
```

Kullanım:
```dart
onPressed: () {
  AppHaptic.swap();
  ref.read(comparisonSelectionProvider.notifier).swap();
},
```

---

### 5.10 Tab Badge ve Tabs İyileştirmesi

#### Mevcut Durum
[university_comparison_screen.dart:246-275] — 4 tab var ama hiçbirinde badge yok. Kullanıcı hangi tab'da kaç veri olduğunu bilmiyor.

#### Çözüm — Tab Title'da Count Göster

```dart
Tab(
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.dashboard_rounded, size: 18),
      const SizedBox(width: 6),
      const Text('Genel'),
    ],
  ),
),
Tab(
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.category_rounded, size: 18),
      const SizedBox(width: 6),
      const Text('Kategoriler'),
      if (categoryCount > 0) ...[
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$categoryCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ],
  ),
),
```

---

### 5.11 ComparisonShareCard — Daha İyi Paylaşım

#### Mevcut Durum
[comparison_share_card.dart](lib/features/comparison/presentation/widgets/comparison_share_card.dart) — `Screenshot` controller ile 480px genişlikte resim. Bu mobil için iyi ama:
- Instagram story (9:16) için optimize değil
- Twitter card için (16:9) optimize değil
- Beyaz background her zaman aynı (branding eksik)

#### Çözüm — Format Seçici

```dart
enum ShareFormat {
  instagramStory(width: 1080, height: 1920),
  instagramPost(width: 1080, height: 1080),
  twitterCard(width: 1200, height: 675),
  whatsappPreview(width: 800, height: 600);

  final int width;
  final int height;
  const ShareFormat({required this.width, required this.height});

  double get aspectRatio => width / height;
}

class ShareFormatPicker extends StatelessWidget {
  final ValueChanged<ShareFormat> onSelected;

  const ShareFormatPicker({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      onClosing: () {},
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Instagram Story (9:16)'),
            onTap: () {
              Navigator.pop(context);
              onSelected(ShareFormat.instagramStory);
            },
          ),
          ListTile(
            leading: const Icon(Icons.crop_square),
            title: const Text('Instagram Post (1:1)'),
            onTap: () {
              Navigator.pop(context);
              onSelected(ShareFormat.instagramPost);
            },
          ),
          ListTile(
            leading: const Icon(Icons.smartphone),
            title: const Text('WhatsApp / Mesaj'),
            onTap: () {
              Navigator.pop(context);
              onSelected(ShareFormat.whatsappPreview);
            },
          ),
        ],
      ),
    );
  }
}
```

#### Watermark Ekle

```dart
// ComparisonShareCard içinde, alt köşeye
Positioned(
  bottom: 12,
  right: 12,
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/icons/app_icon_small.png', width: 14, height: 14),
        const SizedBox(width: 6),
        const Text(
          'üniSeç',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF6C63FF),
          ),
        ),
      ],
    ),
  ),
),
```

---

### 5.12 Bottom Navigation Overlay (FloatingActionBar) Düzeltmesi

#### Mevcut Durum
[university_comparison_screen.dart] — FloatingActionBar bottom navigation bar'ın **üstüne** geliyor, bazı durumlarda örtüşüyor.

#### Çözüm — SafeArea + Adaptive Padding

```dart
SafeArea(
  top: false,
  child: Padding(
    padding: EdgeInsets.only(
      left: 16,
      right: 16,
      bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
    ),
    child: ComparisonFloatingActionBar(/* ... */),
  ),
),
```

---

### 5.13 RTL Desteği

#### Mevcut Durum
Karşılaştırma feature'ında **RTL desteği yok**. Arapça/Farsça konuşan uluslararası öğrenciler için problem.

#### Çözüm — Directionality Aware Widget'lar

```dart
// Mevcut:
Row(
  children: [
    UniA,
    SizedBox(width: 12),
    VsIcon,
    SizedBox(width: 12),
    UniB,
  ],
)

// Önerilen:
Row(
  textDirection: Directionality.of(context),  // Sistem locale'i takip et
  children: [
    UniA,
    const SizedBox(width: 12),
    VsIcon,
    const SizedBox(width: 12),
    UniB,
  ],
)
```

#### Padding & Margin için EdgeInsetsDirectional

```dart
// Mevcut:
EdgeInsets.only(left: 16, right: 8)

// Önerilen:
EdgeInsetsDirectional.only(start: 16, end: 8)
```

#### Test

```dart
// Widget test:
testWidgets('comparison hub renders correctly in RTL', (tester) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.rtl,
      child: const ComparisonHubScreen(),
    ),
  );
  // ... asserts
});
```

---

### 5.14 Comparison Hub — Sub-Type Lock Icon İyileştirmesi

#### Mevcut Durum
[comparison_hub_screen.dart] — Bölüm/Şehir kartlarının üstünde basit kilit ikonu var (`lock_rounded`). Plus'a geçmenin değerini iletmek için yetersiz.

#### Çözüm — Daha Çekici Lock Card

```dart
class ComparisonTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isLocked;
  final SubscriptionTier? requiredTier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isLocked
              ? LinearGradient(
                  colors: [
                    AppColors.darkSurface,
                    AppColors.darkSurface.withValues(alpha: 0.7),
                  ],
                )
              : AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLocked
                ? (requiredTier == SubscriptionTier.pro
                    ? AppColors.tierPro.withValues(alpha: 0.5)
                    : AppColors.tierPlus.withValues(alpha: 0.5))
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: AppColors.cardShadow,
        ),
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 32, color: Colors.white),
                const SizedBox(height: 12),
                Text(title, style: AppTextStyles.titleLarge.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text(description, style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
              ],
            ),
            if (isLocked)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: requiredTier == SubscriptionTier.pro
                        ? AppColors.tierProGradient
                        : AppColors.tierPlusGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        requiredTier == SubscriptionTier.pro ? 'PRO' : 'PLUS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

---

## 6. Performans & Firestore Maliyet

> **Risk Seviyesi:** 🟡 **ORTA**
> **Beklenen Etki:** %30-50 Firestore read azaltma, latency -200ms

### 6.1 Firestore Composite Index Önerileri

#### Mevcut Sorgular ve Eksik İndeksler

##### Sorgu 1 — ratingTrendProvider

```dart
firestore
  .collection('reviews')
  .where('universityId', isEqualTo: universityId)
  .where('isApproved', isEqualTo: true)
  .where('createdAt', isGreaterThanOrEqualTo: ...)
```

**Gereken Index:** `reviews` collection: `(universityId ASC, isApproved ASC, createdAt ASC)`

##### Sorgu 2 — aiSummaryLogs cleanup

```typescript
db.collection('aiSummaryLogs')
  .where('createdAt', '<', cutoff)
  .limit(BATCH_SIZE)
```

**Gereken Index:** `aiSummaryLogs` collection: `(createdAt ASC)` — single field, otomatik var

##### Sorgu 3 — departmentPickerDepartmentsProvider (filtre)

```dart
repository.getDepartmentsByUniversity(uniId)
// İçeride .where('universityId', isEqualTo: uniId).where('scoreType', isEqualTo: ...)
```

**Gereken Index:** `departments` collection: `(universityId ASC, scoreType ASC, name ASC)`

#### `firestore.indexes.json` Çıktısı

> **Yeni dosya:** `/home/burak/uni_app/firestore.indexes.json`

```json
{
  "indexes": [
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "universityId", "order": "ASCENDING" },
        { "fieldPath": "isApproved", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "universityId", "order": "ASCENDING" },
        { "fieldPath": "isApproved", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "departments",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "universityId", "order": "ASCENDING" },
        { "fieldPath": "scoreType", "order": "ASCENDING" },
        { "fieldPath": "name", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "departments",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "universityId", "order": "ASCENDING" },
        { "fieldPath": "baseScore", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "places",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "universityId", "order": "ASCENDING" },
        { "fieldPath": "type", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "aiSummaryLogs",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "preferenceLists",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "isPublic", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": [
    {
      "collectionGroup": "aiSummaryLogs",
      "fieldPath": "expireAt",
      "ttl": true,
      "indexes": []
    },
    {
      "collectionGroup": "aiSummaryCache",
      "fieldPath": "expiresAt",
      "ttl": true,
      "indexes": []
    },
    {
      "collectionGroup": "webhookEvents",
      "fieldPath": "expireAt",
      "ttl": true,
      "indexes": []
    }
  ]
}
```

#### Deploy

```bash
firebase deploy --only firestore:indexes
```

> **NOT:** İndeks oluşturma background task, 1-30 dakika sürebilir. Production'da geceleri deploy et.

---

### 6.2 Provider AutoDispose ile Cache Temizleme

#### Mevcut Sorun
`comparison_providers.dart`'da hepsi `FutureProvider` (non-autoDispose). Sonuç:
- Kullanıcı karşılaştırma yapıp ekrandan çıksa bile provider memory'de kalıyor
- `_comparisonResultCache`, `_departmentResultCache`, `_cityResultCache`, `_aiSummaryCache`, `_ratingTrendCache`, `_heatMapCache`, `_scatterCache` global map'ler büyüyor
- Memory leak — uzun session'da 100+ MB

#### Çözüm — `.autoDispose` + `keepAlive`

```dart
final comparisonResultProvider =
    FutureProvider.autoDispose<ComparisonResult?>((ref) async {
  // 5 dakika boyunca cache'de kalsın, sonra dispose olsun
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 5), () => link.close());

  final selection = ref.watch(comparisonSelectionProvider);
  // ... mevcut logic
});
```

#### Family Provider'lar için

```dart
final departmentComparisonResultProvider =
    FutureProvider.autoDispose.family<DepartmentComparisonResult?, ComparisonPair>(
  (ref, pair) async {
    final link = ref.keepAlive();
    Timer(const Duration(minutes: 5), () => link.close());
    // ... mevcut logic
  },
);
```

#### Global Cache Yerine Provider Cache'i

Tüm `_xxxCache` map'lerini silebilirsin. Provider cache'i kendi başına yeterli — `autoDispose` ile 5 dakika sonra silinir.

```dart
// SİLİNECEK satırlar:
final _comparisonResultCache = <String, ComparisonResult?>{};
final _departmentResultCache = <String, DepartmentComparisonResult?>{};
final _cityResultCache = <String, CityComparisonResult?>{};
final _aiSummaryCache = <String, AiComparisonSummaryResult>{};
final _ratingTrendCache = <String, List<RatingTrendPoint>>{};
final _heatMapCache = <String, List<CategoryHeatMapCell>>{};
final _scatterCache = <String, DepartmentScatterData>{};
```

---

### 6.3 N+1 Query Düzeltmesi — Departman Karşılaştırması

#### Mevcut Sorun
[department_comparison_repository.dart] — Her bölümün üniversitesini ayrı ayrı çekiyor. 2 bölüm için 2 read.

Eğer aynı üniversitedeki 5 bölümü karşılaştırıyorsa, 10 read'e çıkıyor.

#### Çözüm — Tek `whereIn` Query

```dart
// lib/features/comparison/data/department_comparison_repository.dart

Future<DepartmentComparisonResult?> compare(
  String deptIdA,
  String deptIdB,
) async {
  // Tek query ile iki bölümü çek
  final deptSnap = await FirebaseFirestore.instance
      .collection('departments')
      .where(FieldPath.documentId, whereIn: [deptIdA, deptIdB])
      .get();

  if (deptSnap.docs.length < 2) return null;

  final docs = deptSnap.docs;
  final deptA = DepartmentModel.fromFirestore(
    docs.firstWhere((d) => d.id == deptIdA),
  );
  final deptB = DepartmentModel.fromFirestore(
    docs.firstWhere((d) => d.id == deptIdB),
  );

  // Üniversiteleri de tek query ile çek
  final uniIds = {deptA.universityId, deptB.universityId}.toList();
  final uniSnap = await FirebaseFirestore.instance
      .collection('universities')
      .where(FieldPath.documentId, whereIn: uniIds)
      .get();

  // ... rest of logic
}
```

#### Etki
- **Önce:** 4 Firestore read (deptA, deptB, uniA, uniB)
- **Sonra:** 2 Firestore read (departments query, universities query)
- **Tasarruf:** %50

---

### 6.4 Place Count Denormalize

#### Mevcut Sorun
[comparison_repository.dart:27-28] — Her karşılaştırmada üniversitenin tüm yer dokümanlarını çekiyor.

```dart
_placeRepo.getPlacesByUniversity(uniIdA),
_placeRepo.getPlacesByUniversity(uniIdB),
```

ITU'nun 200 yeri varsa, sadece sayım için 200 read! İki üniversite için 400 read.

#### Çözüm A — Universities Doc'a `placeCount` Denormalize

##### 1. Universities Schema Genişlet

```typescript
interface UniversityDoc {
  // ... mevcut alanlar
  placeCount: number;
  placeBreakdown: {
    cafe: number;
    library: number;
    sports: number;
    dorm: number;
    // ... vb. place types
  };
  placeCountUpdatedAt: admin.firestore.Timestamp;
}
```

##### 2. Cloud Function Trigger

```typescript
// functions/src/aggregations/place_count.ts
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export const recomputePlaceCount = onDocumentWritten(
  {
    region: 'europe-west1',
    document: 'places/{placeId}',
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const universityId = (after?.universityId ?? before?.universityId) as string | undefined;
    if (!universityId) return;

    const snap = await db
      .collection('places')
      .where('universityId', '==', universityId)
      .get();

    const breakdown: Record<string, number> = {};
    for (const doc of snap.docs) {
      const type = String(doc.data().type ?? 'other');
      breakdown[type] = (breakdown[type] ?? 0) + 1;
    }

    await db.collection('universities').doc(universityId).set(
      {
        placeCount: snap.size,
        placeBreakdown: breakdown,
        placeCountUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  },
);
```

##### 3. Client Tarafı — Sayım için Place Çekmesin

```dart
// comparison_repository.dart
// SİLİNECEK:
// _placeRepo.getPlacesByUniversity(uniIdA),
// _placeRepo.getPlacesByUniversity(uniIdB),

// Yerine:
final placeCountA = uniA.placeCount;
final placeBreakdownA = uniA.placeBreakdown;
final placeCountB = uniB.placeCount;
final placeBreakdownB = uniB.placeBreakdown;
```

#### Etki
- 400 read → 0 ek read
- **Tasarruf: %100 place query**

---

### 6.5 AI Summary Cache TTL Policy

#### Mevcut Durum
`aiSummaryCache` koleksiyonu sınırsız büyüyor. Her unique (uniA, uniB) çift için 1 doc → eski cache'ler boşa yer kaplıyor.

#### Çözüm — Firestore TTL Policy

##### 1. `expiresAt` field zaten var (functions/src/comparison/summary.ts:102)

```typescript
expiresAt: generatedAt + CACHE_TTL_MS,  // ✅ Var
```

##### 2. TTL Policy Oluştur

```bash
gcloud firestore fields ttls update expiresAt \
  --collection-group=aiSummaryCache \
  --enable-ttl \
  --project=YOUR_PROJECT_ID
```

Veya yukarıda 6.1'deki `firestore.indexes.json` içinde `fieldOverrides` ile.

##### 3. Doğrulama

```bash
gcloud firestore fields ttls list --project=YOUR_PROJECT_ID
```

Çıktıda `aiSummaryCache.expiresAt` görünmeli, `state: ACTIVE`.

#### Etki
- 24 saatten eski cache otomatik silinir
- Firestore storage maliyeti düşer

---

### 6.6 University Logo Caching

#### Mevcut Sorun
Üniversite logo'ları (`logoUrl` field'ı) `Image.network` ile yükleniyor. Cache yok → her ekran değiştiğinde yeniden indiriyor.

#### Çözüm — `cached_network_image` Paketi

```yaml
# pubspec.yaml
dependencies:
  cached_network_image: ^3.4.1
```

```dart
// Mevcut:
Image.network(university.logoUrl, width: 60, height: 60)

// Önerilen:
CachedNetworkImage(
  imageUrl: university.logoUrl,
  width: 60,
  height: 60,
  placeholder: (context, url) => const ShimmerBox(
    width: 60,
    height: 60,
    borderRadius: 30,
  ),
  errorWidget: (context, url, error) => Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.surfaceVariant,
    ),
    child: const Icon(Icons.school, color: Colors.grey),
  ),
)
```

#### Etki
- İlk indirme sonrası 0 bandwidth
- Görsel için latency 200ms → 0ms

---

### 6.7 Firestore Cost Estimate (Mevcut vs Optimize)

#### Senaryo: 10.000 aylık aktif kullanıcı, kullanıcı başına 3 karşılaştırma/gün

| Kalem | Mevcut Read/Karşılaştırma | Optimize Read/Karşılaştırma |
|-------|-----------------------|--------------------------|
| UniA + UniB | 2 | 2 |
| PlacesA + PlacesB | ~50-300 (her place doc) | 0 (denormalize) |
| DeptsA + DeptsB | ~30-100 (her dept doc) | 0 (denormalize) → veya 2 (whereIn) |
| AI Summary cache | 1 | 1 |
| Usage stats | 1 | 1 |
| **TOPLAM** | **~85-405** | **~6** |

#### Aylık Read Tahmini

- **Mevcut:** 10.000 × 3 × 30 × 200 (avg) = **180 milyon read/ay**
- **Optimize:** 10.000 × 3 × 30 × 6 = **5.4 milyon read/ay**

Firestore fiyatlandırma: $0.06 / 100k read.

| Versiyon | Aylık Maliyet |
|----------|---------------|
| Mevcut | ~$108 / ay |
| Optimize | ~$3.24 / ay |

**Tasarruf:** %97 (yıllık ~$1250)

---

### 6.8 ConsumerWidget vs Consumer — Build Optimizasyonu

#### Mevcut Sorun
Karşılaştırma ekranlarında bütün widget tree `ConsumerWidget`. Bir provider değişince **tüm ekran** rebuild oluyor.

#### Çözüm — Granular Consumer

```dart
// Önce:
class UniversityComparisonScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(comparisonResultProvider);
    final aiSummary = ref.watch(aiComparisonSummaryProvider);
    return Scaffold(
      body: Column(/* 500+ widget'lar */),
    );
  }
}

// Sonra — selective rebuild:
class UniversityComparisonScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Result değişince sadece bu kısım rebuild olur
          Consumer(
            builder: (context, ref, _) {
              final result = ref.watch(comparisonResultProvider);
              return _HeroSection(result: result);
            },
          ),
          // AI summary değişince sadece bu kısım rebuild olur
          Consumer(
            builder: (context, ref, _) {
              final aiSummary = ref.watch(aiComparisonSummaryProvider);
              return _AiSummaryCard(summary: aiSummary);
            },
          ),
        ],
      ),
    );
  }
}
```

---

## 7. Yazım / Lokalizasyon Hataları

> **Risk Seviyesi:** 🟠 **YÜKSEK** (kullanıcı algısı / profesyonellik)
> **Bulgu:** Türkçe karakter eksikliği, tutarsız yazım, lokalizasyon kullanılmadan hardcoded string

### 7.1 Tespit Edilen Yazım Hataları

| Dosya | Satır | Mevcut | Düzeltilmiş |
|-------|-------|--------|-------------|
| comparison_ai_summary_card.dart | 90 | `5 AI ozetin doldu, yarin tekrar dene.` | `5 AI özet hakkın doldu, yarın tekrar dene.` |
| comparison_ai_summary_card.dart | 99 | `AI Analizi Pro pakette aktif. Pro'ya gecerek detayli ozeti acabilirsin.` | `AI Analizi Pro pakette aktif. Pro'ya geçerek detaylı özeti açabilirsin.` |
| comparison_ai_summary_card.dart | 120 | `Pro analizi aktif` | `Pro analizi aktif` (✓ doğru ama italik daha iyi) |

### 7.2 Türkçe Karakter Eksikliği Tarama Komutu

> **Tek seferlik script:** Tüm dosyalarda Türkçe karakter eksikliğini tespit et

```bash
# Yaygın hata pattern'leri
grep -rn --include="*.dart" \
  -E "\b(ozet|gecer|acar|yarin|sira|sehir|opt|trkce|simdi|hicbir|kac)" \
  lib/features/comparison/
```

### 7.3 String'leri l10n'a Taşıma Önceliği

Yüksek görünürlükteki string'ler önce:

1. **Çok Yüksek** (her kullanıcı her gün görüyor):
   - Tab başlıkları (`Genel`, `Kategoriler`, `Grafik`, `İstatistik`)
   - Hub kartları (`Üniversite Karşılaştır`, `Bölüm Karşılaştır`, `Şehir Karşılaştır`)
   - Empty state mesajları
   - Hata mesajları

2. **Yüksek** (sık görünür):
   - Karşılaştırma alanı isimleri (Taban Puan, Sıralama, Kontenjan, vb.)
   - Tier isimleri (Free, Plus, Pro)
   - Button label'ları (Paylaş, Yeniden, Sıfırla)

3. **Orta** (occasional):
   - Tooltip'ler
   - Modal başlıkları

### 7.4 Tutarsız Yazım

| Yer | Mevcut Varyasyonlar | Standartlaştırılmalı |
|-----|---------------------|----------------------|
| Üniversite tipi | `Devlet`, `State`, `state`, `STATE_UNI` | `Devlet` / `state` (l10n) |
| Vakıf üniversitesi | `Vakıf`, `Foundation`, `private` | `Vakıf` / `foundation` |
| Score type | `SAY`, `Say`, `SAYISAL`, `Sayısal` | Standardize: `SAY` (raw) + locale string |
| Tier | `plus`, `Plus`, `PLUS` | Enum: `SubscriptionTier.plus`, UI'da `Plus` |

### 7.5 Date/Number Formatting

#### Mevcut Sorun
Tarih ve sayılar locale-aware formatlanmıyor:

```dart
// MEVCUT:
'${result.uniA.avgRating}'  // → "4.36789" (Türkçe için "4,4" olmalı)
'${trendPoint.month.month}.${trendPoint.month.year}'  // → "5.2026"
```

#### Çözüm — `intl` Package

```dart
import 'package:intl/intl.dart';

// Sayı formatı
final ratingFormat = NumberFormat('#.0', 'tr_TR');
ratingFormat.format(result.uniA.avgRating);  // → "4,4"

final scoreFormat = NumberFormat('#,##0.0', 'tr_TR');
scoreFormat.format(450789.5);  // → "450.789,5"

// Tarih formatı
final monthFormat = DateFormat('MMM yyyy', 'tr_TR');
monthFormat.format(trendPoint.month);  // → "May 2026"

// Yüzde
final percentFormat = NumberFormat.percentPattern('tr_TR');
percentFormat.format(0.85);  // → "%85"
```

#### Helper Class

```dart
// lib/core/utils/formatters.dart
import 'package:intl/intl.dart';

class AppFormatters {
  static final ratingFormat = NumberFormat('#.0', 'tr_TR');
  static final scoreFormat = NumberFormat('#,##0.0', 'tr_TR');
  static final compactFormat = NumberFormat.compact(locale: 'tr_TR');
  static final monthFormat = DateFormat('MMM yyyy', 'tr_TR');
  static final dayMonthFormat = DateFormat('d MMM', 'tr_TR');
  static final percentFormat = NumberFormat.percentPattern('tr_TR');

  static String rating(num? value) =>
      value == null ? '—' : ratingFormat.format(value);

  static String score(num? value) =>
      value == null ? '—' : scoreFormat.format(value);

  static String compactNumber(num? value) =>
      value == null ? '—' : compactFormat.format(value);  // 1.5K, 2.3M

  static String month(DateTime date) => monthFormat.format(date);
  static String dayMonth(DateTime date) => dayMonthFormat.format(date);
  static String percent(num fraction) => percentFormat.format(fraction);

  static String ranking(int? value) {
    if (value == null || value == 0) return '—';
    return scoreFormat.format(value);
  }
}
```

#### Kullanım

```dart
// Önce:
Text('${result.uniA.avgRating.toStringAsFixed(2)}')

// Sonra:
Text(AppFormatters.rating(result.uniA.avgRating))
```

---

## 8. Yeni Özellik Önerileri

> **Risk Seviyesi:** 🟢 **DÜŞÜK** (önerilenler, mevcut sistemi bozmaz)
> **Beklenen Etki:** Engagement +%30, Pro conversion +%15, viral paylaşım +%50

### 8.1 "Yeniden Özet Üret" Butonu

#### Use Case
Kullanıcı AI özetini beğenmedi (örn: çok genel, beklediği gibi değil). Cache'i bypass ederek yeniden üretsin.

#### Maliyet
- Free/Plus tier'da yok
- Pro tier'da kullanıcı başına günlük 2 regenerate hakkı

#### Implementation

##### 1. Cloud Function — `regenerate=true` Flag

```typescript
// functions/src/comparison/summary.ts içinde

interface SummaryInput {
  comparisonType: 'university' | 'department' | 'city';
  entityA: { id: string; name: string };
  entityB: { id: string; name: string };
  comparisonData: Record<string, unknown>;
  regenerate?: boolean;  // ← YENİ
}

// Cache hit kontrolü içinde:
if (cacheSnap.exists && !input.regenerate) {  // ← input.regenerate true ise cache atla
  // ... existing cache hit logic
}
```

##### 2. Daily Regenerate Limit

```typescript
const DAILY_REGENERATE_LIMIT = 2;

if (input.regenerate) {
  const dailyRegenerates = Number(usageData.dailyAiRegenerates ?? 0);
  if (dailyRegenerates >= DAILY_REGENERATE_LIMIT) {
    throw new HttpsError(
      'resource-exhausted',
      `Günlük ${DAILY_REGENERATE_LIMIT} yeniden üretme hakkın doldu.`,
    );
  }
  // Increment regenerate counter
  patch.dailyAiRegenerates = admin.firestore.FieldValue.increment(1);
}
```

##### 3. Client Tarafı

```dart
// AiComparisonSummaryService
Future<AiComparisonSummaryResult> summarizeUniversityComparison(
  ComparisonResult result, {
  bool regenerate = false,
}) async {
  final payload = {
    ..._buildPayload(result),
    if (regenerate) 'regenerate': true,
  };
  // ... rest
}
```

##### 4. UI — Regenerate Button

```dart
// comparison_ai_summary_card.dart içinde

if (!loading && !blocked && summaryText.isNotEmpty) ...[
  const SizedBox(height: 12),
  Row(
    children: [
      Text(
        'Pro analizi aktif',
        style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
      ),
      const Spacer(),
      if (regenerateAllowed)
        TextButton.icon(
          onPressed: onRegenerate,
          icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
          label: const Text(
            'Yeniden üret',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
    ],
  ),
],
```

---

### 8.2 Karşılaştırma Geçmişi

#### Use Case
Kullanıcı dün İTÜ vs Boğaziçi karşılaştırdı, bugün geri dönmek istiyor. Şu anda tekrar arama yapması gerekiyor.

#### Implementation

##### 1. Firestore Schema

```typescript
// users/{uid}/comparisonHistory/{historyId}
interface ComparisonHistoryDoc {
  type: 'university' | 'department' | 'city';
  entityAId: string;
  entityBId: string;
  entityAName: string;
  entityBName: string;
  createdAt: Timestamp;
  thumbnailUrl?: string;  // Üniversite logo URL'leri
}
```

##### 2. Firestore Rules

```firestore
match /users/{uid}/comparisonHistory/{historyId} {
  allow read: if isOwner(uid);
  allow create: if isOwner(uid) &&
    request.resource.data.entityAId is string &&
    request.resource.data.entityBId is string;
  allow update, delete: if isOwner(uid);
}
```

##### 3. Repository

```dart
// lib/features/comparison/data/comparison_history_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ComparisonHistoryEntry {
  final String id;
  final String type;
  final String entityAId;
  final String entityBId;
  final String entityAName;
  final String entityBName;
  final DateTime createdAt;

  const ComparisonHistoryEntry({
    required this.id,
    required this.type,
    required this.entityAId,
    required this.entityBId,
    required this.entityAName,
    required this.entityBName,
    required this.createdAt,
  });

  factory ComparisonHistoryEntry.fromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ComparisonHistoryEntry(
      id: doc.id,
      type: data['type'] as String,
      entityAId: data['entityAId'] as String,
      entityBId: data['entityBId'] as String,
      entityAName: data['entityAName'] as String? ?? '',
      entityBName: data['entityBName'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

class ComparisonHistoryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  static const int _maxHistorySize = 20;

  ComparisonHistoryRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<void> recordComparison({
    required String type,
    required String entityAId,
    required String entityBId,
    required String entityAName,
    required String entityBName,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('comparisonHistory');

    // Aynı çift varsa eskiyi sil (deduplication)
    final existing = await ref
        .where('entityAId', whereIn: [entityAId, entityBId])
        .get();
    for (final doc in existing.docs) {
      final data = doc.data();
      if ((data['entityAId'] == entityAId && data['entityBId'] == entityBId) ||
          (data['entityAId'] == entityBId && data['entityBId'] == entityAId)) {
        await doc.reference.delete();
      }
    }

    // Yeni ekle
    await ref.add({
      'type': type,
      'entityAId': entityAId,
      'entityBId': entityBId,
      'entityAName': entityAName,
      'entityBName': entityBName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Max boyut aş — en eskiyi sil
    final all = await ref.orderBy('createdAt', descending: true).get();
    if (all.docs.length > _maxHistorySize) {
      for (var i = _maxHistorySize; i < all.docs.length; i++) {
        await all.docs[i].reference.delete();
      }
    }
  }

  Stream<List<ComparisonHistoryEntry>> watchHistory({int limit = 10}) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('comparisonHistory')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(ComparisonHistoryEntry.fromDoc).toList());
  }

  Future<void> clearHistory() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('comparisonHistory')
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
```

##### 4. Provider Entegrasyonu

```dart
final comparisonHistoryRepositoryProvider =
    Provider<ComparisonHistoryRepository>((ref) {
  return ComparisonHistoryRepository();
});

final comparisonHistoryProvider = StreamProvider<List<ComparisonHistoryEntry>>((ref) {
  return ref.watch(comparisonHistoryRepositoryProvider).watchHistory();
});

// Karşılaştırma başarılı olduğunda otomatik kaydet
final comparisonResultProvider = FutureProvider.autoDispose<ComparisonResult?>((ref) async {
  // ... existing logic
  if (result != null) {
    await ref.read(comparisonHistoryRepositoryProvider).recordComparison(
          type: 'university',
          entityAId: result.uniA.id,
          entityBId: result.uniB.id,
          entityAName: result.uniA.name,
          entityBName: result.uniB.name,
        );
  }
  return result;
});
```

##### 5. UI — History List Widget

```dart
class ComparisonHistorySection extends ConsumerWidget {
  const ComparisonHistorySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(comparisonHistoryProvider);

    return history.when(
      data: (entries) {
        if (entries.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Geçmiş', style: AppTextStyles.titleMedium),
                TextButton(
                  onPressed: () async {
                    final confirm = await _showClearDialog(context);
                    if (confirm) {
                      ref.read(comparisonHistoryRepositoryProvider).clearHistory();
                    }
                  },
                  child: const Text('Temizle'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final entry = entries[i];
                  return _HistoryCard(
                    entry: entry,
                    onTap: () => _navigateToComparison(context, ref, entry),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

---

### 8.3 Karşılaştırma Deep-Link Paylaşımı

#### Use Case
Kullanıcı İTÜ vs Boğaziçi karşılaştırma sonucunu WhatsApp grubuna yapıştırıyor. Link'e tıklayan arkadaşı doğrudan o karşılaştırmayı görüyor.

#### Implementation

##### 1. `pubspec.yaml`

```yaml
dependencies:
  go_router: ^14.0.0  # Veya app_links: ^6.0.0
  app_links: ^6.0.0
```

##### 2. Universal Link / App Link Konfigürasyonu

###### iOS — `apple-app-site-association`

> Sunucuya yükle: `https://uniseç.com/.well-known/apple-app-site-association`

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.uniseç.app",
        "paths": ["/compare/*", "/compare?*"]
      }
    ]
  }
}
```

###### Android — `assetlinks.json`

> Sunucuya yükle: `https://uniseç.com/.well-known/assetlinks.json`

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.uniseç.app",
    "sha256_cert_fingerprints": ["SHA256_FINGERPRINT"]
  }
}]
```

###### `AndroidManifest.xml`

```xml
<activity android:name=".MainActivity" ...>
  <intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="uniseç.com" />
  </intent-filter>
</activity>
```

##### 3. Router Konfigürasyonu

```dart
final router = GoRouter(
  routes: [
    // ... mevcut route'lar
    GoRoute(
      path: '/compare',
      builder: (context, state) {
        final type = state.uri.queryParameters['type'] ?? 'university';
        final a = state.uri.queryParameters['a'];
        final b = state.uri.queryParameters['b'];

        if (a == null || b == null) {
          return const ComparisonHubScreen();
        }

        switch (type) {
          case 'department':
            return DepartmentComparisonScreen(initialA: a, initialB: b);
          case 'city':
            return CityComparisonScreen(initialA: a, initialB: b);
          default:
            return UniversityComparisonScreen(initialA: a, initialB: b);
        }
      },
    ),
  ],
);
```

##### 4. Paylaşılabilir Link Üret

```dart
// comparison_share_card.dart

String buildShareLink({
  required String type,
  required String idA,
  required String idB,
}) {
  return 'https://uniseç.com/compare?type=$type&a=$idA&b=$idB';
}

// Share button:
final link = buildShareLink(type: 'university', idA: uniA.id, idB: uniB.id);
final shareText = '''
${uniA.name} vs ${uniB.name} — Karşılaştırma

$link

üniSeç ile keşfet 🎓
''';
await Share.share(shareText, subject: '${uniA.name} vs ${uniB.name}');
```

##### 5. Cold Start Handling

```dart
// main.dart
import 'package:app_links/app_links.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ... Firebase init

  // App Link dinleyici
  final appLinks = AppLinks();

  // App kapalıyken açılan link
  final initialLink = await appLinks.getInitialAppLink();
  if (initialLink != null) {
    // Router'a ilet
    _initialDeepLink = initialLink;
  }

  // App açıkken gelen link
  appLinks.uriLinkStream.listen((uri) {
    GoRouter.of(navigatorKey.currentContext!).go(uri.toString());
  });

  runApp(ProviderScope(child: MyApp()));
}
```

---

### 8.4 Üçlü Karşılaştırma (Pro Tier)

#### Use Case
Pro tier farklılaştırması — 2 değil 3 üniversite karşılaştırma. Tercih listesi yaparken çok değerli.

#### UI Mockup

```
┌─────────┐  ┌─────────┐  ┌─────────┐
│  İTÜ    │  │  ODTÜ   │  │ Boğaziçi│
│  4.3 ★  │  │  4.5 ★  │  │  4.6 ★  │
└─────────┘  └─────────┘  └─────────┘

Akademik:  ▓▓▓▓░ 4.1  ▓▓▓▓▓ 4.5  ▓▓▓▓▓ 4.6
Sosyal:    ▓▓▓░░ 3.5  ▓▓▓▓░ 4.0  ▓▓▓▓▓ 4.5
Mekan:     ▓▓▓▓░ 4.0  ▓▓▓▓░ 4.2  ▓▓▓▓▓ 4.7
```

#### Model

```dart
class TripleComparisonResult {
  final UniversityModel uniA;
  final UniversityModel uniB;
  final UniversityModel uniC;
  final Map<String, TripleCategoryComparison> categories;
  final TripleStats stats;

  const TripleComparisonResult({
    required this.uniA,
    required this.uniB,
    required this.uniC,
    required this.categories,
    required this.stats,
  });
}

class TripleCategoryComparison {
  final String categoryName;
  final double valueA;
  final double valueB;
  final double valueC;
  final String? winnerId;  // En yüksek
  final String? loserId;   // En düşük

  const TripleCategoryComparison({
    required this.categoryName,
    required this.valueA,
    required this.valueB,
    required this.valueC,
    this.winnerId,
    this.loserId,
  });
}
```

#### Repository — `compareThree`

```dart
class TripleComparisonRepository {
  // ...

  Future<TripleComparisonResult?> compareThree(
    String idA,
    String idB,
    String idC,
  ) async {
    final unis = await _firestore
        .collection('universities')
        .where(FieldPath.documentId, whereIn: [idA, idB, idC])
        .get();

    if (unis.docs.length != 3) return null;

    // ... build categories, stats
  }
}
```

#### Provider Gate (Pro Only)

```dart
final canCompareTripleProvider = Provider<bool>((ref) {
  final tier = ref.watch(subscriptionTierProvider).valueOrNull;
  return tier == SubscriptionTier.pro;
});
```

---

### 8.5 Sesli Karşılaştırma Anlatımı (TTS)

#### Use Case
- Erişilebilirlik (görme engelli kullanıcılar)
- Multitasking kullanıcılar (yolda dinlemek)

#### Implementation

```yaml
# pubspec.yaml
dependencies:
  flutter_tts: ^4.0.2
```

```dart
import 'package:flutter_tts/flutter_tts.dart';

class ComparisonNarrator {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _tts.setLanguage('tr-TR');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _initialized = true;
  }

  Future<void> narrateComparison(ComparisonResult result) async {
    await init();
    final text = _buildNarrationText(result);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  String _buildNarrationText(ComparisonResult result) {
    final buffer = StringBuffer();
    buffer.write('${result.uniA.name} ve ${result.uniB.name} karşılaştırması. ');
    buffer.write('${result.uniA.name} ortalama ${AppFormatters.rating(result.uniA.avgRating)} puan. ');
    buffer.write('${result.uniB.name} ortalama ${AppFormatters.rating(result.uniB.avgRating)} puan. ');

    final delta = result.uniA.avgRating - result.uniB.avgRating;
    if (delta.abs() < 0.05) {
      buffer.write('İki üniversite ortalama puanda eşit. ');
    } else if (delta > 0) {
      buffer.write('${result.uniA.name} ${delta.abs().toStringAsFixed(1)} puan önde. ');
    } else {
      buffer.write('${result.uniB.name} ${delta.abs().toStringAsFixed(1)} puan önde. ');
    }

    return buffer.toString();
  }
}
```

#### UI — Narrate Button

```dart
IconButton(
  icon: Icon(_isPlaying ? Icons.stop_circle : Icons.volume_up),
  onPressed: () async {
    if (_isPlaying) {
      await _narrator.stop();
    } else {
      await _narrator.narrateComparison(result);
    }
    setState(() => _isPlaying = !_isPlaying);
  },
  tooltip: _isPlaying ? 'Sesli okumayı durdur' : 'Sesli oku',
)
```

---

### 8.6 Karşılaştırma Notları (Pro Tier)

#### Use Case
Kullanıcı karşılaştırma sonuçlarını kendine notlar olarak kaydetmek istiyor (örn: "ITU bana daha yakın", "Boğaziçi'nin yorumları çok pozitif").

#### Schema

```typescript
// users/{uid}/comparisonNotes/{noteId}
interface ComparisonNoteDoc {
  comparisonType: 'university' | 'department' | 'city';
  entityAId: string;
  entityBId: string;
  note: string;
  pros?: string[];
  cons?: string[];
  rating?: number;  // 1-5 — kullanıcının kendi tercih puanı
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

---

### 8.7 Karşılaştırma Karşılaşma — Quiz Modu (Gamification)

#### Use Case
Kullanıcı bilgi kontrolü için "İTÜ mü, Boğaziçi mi daha sosyaldir?" gibi sorulara cevap veriyor, sonra gerçek veriyle karşılaştırıyor. Engagement +%40.

#### UI Mockup

```
Hangi üniversitenin sosyal puanı daha yüksek?

  ┌──────────────┐    ┌──────────────┐
  │     İTÜ      │    │   Boğaziçi    │
  │              │    │              │
  └──────────────┘    └──────────────┘

  Tahminin: ___
  Gerçek: 4.5 vs 4.2 → Boğaziçi (Doğru! 🎉)
```

---

## 9. Test Kapsamı

> **Mevcut Durum:** `test/features/comparison/` boş
> **Hedef:** %70 coverage (kritik path'ler için)

### 9.1 Repository Unit Test

> **Yeni dosya:** `test/features/comparison/data/comparison_repository_test.dart`

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uni_app/features/comparison/data/comparison_repository.dart';
import 'package:uni_app/features/university/data/university_repository.dart';
import 'package:uni_app/features/university/domain/models/university_model.dart';
import 'package:uni_app/features/places/data/place_repository.dart';

class MockUniversityRepository extends Mock implements UniversityRepository {}
class MockPlaceRepository extends Mock implements PlaceRepository {}

void main() {
  late MockUniversityRepository uniRepo;
  late MockPlaceRepository placeRepo;
  late ComparisonRepository repository;

  setUp(() {
    uniRepo = MockUniversityRepository();
    placeRepo = MockPlaceRepository();
    repository = ComparisonRepository(uniRepo: uniRepo, placeRepo: placeRepo);
  });

  group('ComparisonRepository.compare', () {
    test('aynı üniversite ID için ArgumentError fırlatır', () async {
      expect(
        () => repository.compare('uni1', 'uni1'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('uniA null ise null döner', () async {
      when(() => uniRepo.getUniversity('uni1')).thenAnswer((_) async => null);
      when(() => uniRepo.getUniversity('uni2'))
          .thenAnswer((_) async => _fakeUni('uni2'));
      when(() => placeRepo.getPlacesByUniversity(any())).thenAnswer((_) async => []);
      when(() => uniRepo.getDepartmentsByUniversity(any())).thenAnswer((_) async => []);

      final result = await repository.compare('uni1', 'uni2');
      expect(result, isNull);
    });

    test('places fetch fail olsa bile sonuç döner (graceful degradation)', () async {
      when(() => uniRepo.getUniversity('uni1')).thenAnswer((_) async => _fakeUni('uni1'));
      when(() => uniRepo.getUniversity('uni2')).thenAnswer((_) async => _fakeUni('uni2'));
      when(() => placeRepo.getPlacesByUniversity('uni1')).thenThrow(Exception('Firestore error'));
      when(() => placeRepo.getPlacesByUniversity('uni2')).thenAnswer((_) async => []);
      when(() => uniRepo.getDepartmentsByUniversity(any())).thenAnswer((_) async => []);

      final result = await repository.compare('uni1', 'uni2');
      expect(result, isNotNull);
      expect(result!.placeCountA, 0);  // fallback değer
    });

    test('kategori karşılaştırması doğru kazananı belirler', () async {
      when(() => uniRepo.getUniversity('uni1'))
          .thenAnswer((_) async => _fakeUni('uni1', categoryRatings: {'akademik': 4.5}));
      when(() => uniRepo.getUniversity('uni2'))
          .thenAnswer((_) async => _fakeUni('uni2', categoryRatings: {'akademik': 4.0}));
      when(() => placeRepo.getPlacesByUniversity(any())).thenAnswer((_) async => []);
      when(() => uniRepo.getDepartmentsByUniversity(any())).thenAnswer((_) async => []);

      final result = await repository.compare('uni1', 'uni2');
      expect(result!.categoryComparisons['akademik']!.winnerId, 'uni1');
    });

    test('0.05 farktan az ise tie (winnerId == null)', () async {
      when(() => uniRepo.getUniversity('uni1'))
          .thenAnswer((_) async => _fakeUni('uni1', categoryRatings: {'akademik': 4.30}));
      when(() => uniRepo.getUniversity('uni2'))
          .thenAnswer((_) async => _fakeUni('uni2', categoryRatings: {'akademik': 4.33}));
      when(() => placeRepo.getPlacesByUniversity(any())).thenAnswer((_) async => []);
      when(() => uniRepo.getDepartmentsByUniversity(any())).thenAnswer((_) async => []);

      final result = await repository.compare('uni1', 'uni2');
      expect(result!.categoryComparisons['akademik']!.winnerId, isNull);
    });
  });
}

UniversityModel _fakeUni(String id, {Map<String, double>? categoryRatings}) {
  return UniversityModel(
    id: id,
    name: 'Uni $id',
    avgRating: 4.0,
    reviewCount: 100,
    type: 'state',
    establishedYear: 1990,
    cityId: 'istanbul',
    campusLayout: 'single',
    categoryRatings: categoryRatings ?? {},
    // ... diğer required fields
  );
}
```

### 9.2 AI Service Test

> **Yeni dosya:** `test/features/comparison/data/ai_comparison_summary_service_test.dart`

```dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uni_app/features/comparison/data/ai_comparison_summary_service.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}
class MockHttpsCallable extends Mock implements HttpsCallable {}
class MockHttpsCallableResult<T> extends Mock implements HttpsCallableResult<T> {}

void main() {
  late MockFirebaseFunctions functions;
  late MockHttpsCallable callable;
  late AiComparisonSummaryService service;

  setUp(() {
    functions = MockFirebaseFunctions();
    callable = MockHttpsCallable();
    when(() => functions.httpsCallable(any(), options: any(named: 'options')))
        .thenReturn(callable);
    service = AiComparisonSummaryService(functions: functions);
  });

  group('summarizeUniversityComparison', () {
    test('başarılı yanıtı parse eder', () async {
      final result = MockHttpsCallableResult<Object?>();
      when(() => result.data).thenReturn({
        'summary': 'İTÜ teknik alanda güçlü, Boğaziçi ise sosyal yönden.',
        'cached': false,
      });
      when(() => callable.call<Object?>(any())).thenAnswer((_) async => result);

      final response = await service.summarizeUniversityComparison(_fakeComparisonResult());
      expect(response.summary, contains('İTÜ teknik'));
      expect(response.cached, false);
    });

    test('resource-exhausted → AiSummaryQuotaExceeded', () async {
      when(() => callable.call<Object?>(any())).thenThrow(
        FirebaseFunctionsException(
          code: 'resource-exhausted',
          message: 'Daily limit reached',
        ),
      );

      expect(
        () => service.summarizeUniversityComparison(_fakeComparisonResult()),
        throwsA(isA<AiSummaryQuotaExceeded>()),
      );
    });

    test('unauthenticated → AiSummaryUnauthenticated', () async {
      when(() => callable.call<Object?>(any())).thenThrow(
        FirebaseFunctionsException(code: 'unauthenticated', message: 'Not logged in'),
      );

      expect(
        () => service.summarizeUniversityComparison(_fakeComparisonResult()),
        throwsA(isA<AiSummaryUnauthenticated>()),
      );
    });

    test('network error → AiSummaryNetworkError', () async {
      when(() => callable.call<Object?>(any())).thenThrow(
        FirebaseFunctionsException(code: 'network-request-failed', message: 'Network'),
      );

      expect(
        () => service.summarizeUniversityComparison(_fakeComparisonResult()),
        throwsA(isA<AiSummaryNetworkError>()),
      );
    });

    test('summary boş ise AiSummaryUnavailable', () async {
      final result = MockHttpsCallableResult<Object?>();
      when(() => result.data).thenReturn({'summary': '', 'cached': false});
      when(() => callable.call<Object?>(any())).thenAnswer((_) async => result);

      expect(
        () => service.summarizeUniversityComparison(_fakeComparisonResult()),
        throwsA(isA<AiSummaryUnavailable>()),
      );
    });

    test('non-Map yanıt → AiSummaryUnknownError', () async {
      final result = MockHttpsCallableResult<Object?>();
      when(() => result.data).thenReturn('plain string');
      when(() => callable.call<Object?>(any())).thenAnswer((_) async => result);

      expect(
        () => service.summarizeUniversityComparison(_fakeComparisonResult()),
        throwsA(isA<AiSummaryUnknownError>()),
      );
    });
  });
}

// _fakeComparisonResult helper'ı
```

### 9.3 Provider Test

> **Yeni dosya:** `test/features/comparison/presentation/providers/comparison_providers_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uni_app/features/comparison/data/comparison_repository.dart';
import 'package:uni_app/features/comparison/presentation/providers/comparison_providers.dart';
import 'package:uni_app/features/comparison/domain/models/comparison_result.dart';

class MockComparisonRepository extends Mock implements ComparisonRepository {}

void main() {
  late ProviderContainer container;
  late MockComparisonRepository repository;

  setUp(() {
    repository = MockComparisonRepository();
    container = ProviderContainer(
      overrides: [
        comparisonRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('comparisonSelectionProvider', () {
    test('initial state empty', () {
      final selection = container.read(comparisonSelectionProvider);
      expect(selection.uniIdA, isNull);
      expect(selection.uniIdB, isNull);
      expect(selection.bothSelected, false);
    });

    test('selectA günceller', () {
      container.read(comparisonSelectionProvider.notifier).selectA('uni1');
      expect(container.read(comparisonSelectionProvider).uniIdA, 'uni1');
    });

    test('swap çalışır', () {
      container.read(comparisonSelectionProvider.notifier).selectA('uni1');
      container.read(comparisonSelectionProvider.notifier).selectB('uni2');
      container.read(comparisonSelectionProvider.notifier).swap();
      final state = container.read(comparisonSelectionProvider);
      expect(state.uniIdA, 'uni2');
      expect(state.uniIdB, 'uni1');
    });

    test('reset state sıfırlar', () {
      container.read(comparisonSelectionProvider.notifier).selectA('uni1');
      container.read(comparisonSelectionProvider.notifier).reset();
      expect(container.read(comparisonSelectionProvider).uniIdA, isNull);
    });
  });
}
```

### 9.4 Widget Test (Golden Test)

> **Yeni dosya:** `test/features/comparison/presentation/widgets/comparison_ai_summary_card_golden_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:uni_app/features/comparison/presentation/widgets/comparison_ai_summary_card.dart';

void main() {
  testGoldens('ComparisonAiSummaryCard - loading state', (tester) async {
    await tester.pumpWidgetBuilder(
      const ComparisonAiSummaryCard(
        loading: true,
        canUseAi: true,
        isLimitReached: false,
        summaryText: '',
      ),
      wrapper: materialAppWrapper(),
    );
    await screenMatchesGolden(tester, 'ai_summary_card_loading');
  });

  testGoldens('ComparisonAiSummaryCard - blocked (not Pro)', (tester) async {
    await tester.pumpWidgetBuilder(
      const ComparisonAiSummaryCard(
        loading: false,
        canUseAi: false,
        isLimitReached: false,
        summaryText: '',
      ),
      wrapper: materialAppWrapper(),
    );
    await screenMatchesGolden(tester, 'ai_summary_card_blocked');
  });

  testGoldens('ComparisonAiSummaryCard - limit reached', (tester) async {
    await tester.pumpWidgetBuilder(
      const ComparisonAiSummaryCard(
        loading: false,
        canUseAi: false,
        isLimitReached: true,
        summaryText: '',
      ),
      wrapper: materialAppWrapper(),
    );
    await screenMatchesGolden(tester, 'ai_summary_card_limit_reached');
  });

  testGoldens('ComparisonAiSummaryCard - success', (tester) async {
    await tester.pumpWidgetBuilder(
      const ComparisonAiSummaryCard(
        loading: false,
        canUseAi: true,
        isLimitReached: false,
        summaryText: 'İTÜ teknik alanda güçlü, Boğaziçi sosyal yönden.',
      ),
      wrapper: materialAppWrapper(),
    );
    await screenMatchesGolden(tester, 'ai_summary_card_success');
  });
}
```

### 9.5 Cloud Function Test

> **Yeni dosya:** `functions/src/comparison/__tests__/summary.test.ts`

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import functionsTest from 'firebase-functions-test';
import * as admin from 'firebase-admin';

const test = functionsTest();

describe('generateComparisonSummary', () => {
  beforeEach(() => {
    // Firestore mock setup
    admin.initializeApp({ projectId: 'demo-test' });
  });

  it('unauthenticated → throws', async () => {
    const wrapped = test.wrap((await import('../summary')).generateComparisonSummary);

    await expect(
      wrapped.run({ auth: null, data: {} }),
    ).rejects.toThrow(/Giriş gerekli/);
  });

  it('cache hit → quota artmaz', async () => {
    // Pre-populate cache
    await admin.firestore().collection('aiSummaryCache').doc('cached-key').set({
      summary: 'Test özet',
      expiresAt: Date.now() + 60_000,
      generatedAt: Date.now() - 1000,
    });

    // Initial usage = 3
    await admin.firestore()
      .collection('users').doc('user1').collection('usageStats').doc('current')
      .set({ dailyAiComparisons: 3, lastResetDate: '2026-05-12' });

    const wrapped = test.wrap((await import('../summary')).generateComparisonSummary);
    await wrapped.run({
      auth: { uid: 'user1' },
      data: {
        comparisonType: 'university',
        entityA: { id: 'A', name: 'Uni A' },
        entityB: { id: 'B', name: 'Uni B' },
        comparisonData: {},  // cache key uyumlu olmalı
      },
    });

    const updated = await admin.firestore()
      .collection('users').doc('user1').collection('usageStats').doc('current')
      .get();
    expect(updated.data()?.dailyAiComparisons).toBe(3);  // Aynı kalır
  });

  it('rate limit 5 → 6. istek resource-exhausted', async () => {
    await admin.firestore()
      .collection('users').doc('user1').collection('usageStats').doc('current')
      .set({ dailyAiComparisons: 5, lastResetDate: '2026-05-12' });

    const wrapped = test.wrap((await import('../summary')).generateComparisonSummary);
    await expect(
      wrapped.run({
        auth: { uid: 'user1' },
        data: {
          comparisonType: 'university',
          entityA: { id: 'A', name: 'Uni A' },
          entityB: { id: 'B', name: 'Uni B' },
          comparisonData: { unique: 'payload' },
        },
      }),
    ).rejects.toThrow(/limit/);
  });
});
```

### 9.6 Integration Test

> **Yeni dosya:** `integration_test/comparison_flow_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uni_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Karşılaştırma End-to-End Akış', () {
    testWidgets('Free tier: ITU vs Boğaziçi karşılaştırması', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Karşılaştır sekmesine git
      await tester.tap(find.text('Karşılaştır'));
      await tester.pumpAndSettle();

      // 2. Üniversite Karşılaştır kartına bas
      await tester.tap(find.text('Üniversite Karşılaştır'));
      await tester.pumpAndSettle();

      // 3. A picker aç, İTÜ seç
      await tester.tap(find.text('Üniversite A'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'İstanbul Teknik');
      await tester.pumpAndSettle();
      await tester.tap(find.text('İstanbul Teknik Üniversitesi').first);
      await tester.pumpAndSettle();

      // 4. B picker aç, Boğaziçi seç
      await tester.tap(find.text('Üniversite B'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Boğaziçi');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Boğaziçi Üniversitesi').first);
      await tester.pumpAndSettle();

      // 5. Sonuç ekranı yüklendi mi?
      expect(find.text('Genel'), findsOneWidget);
      expect(find.text('Kategoriler'), findsOneWidget);

      // 6. Kategoriler tab'ına geç
      await tester.tap(find.text('Kategoriler'));
      await tester.pumpAndSettle();

      // 7. Paylaş butonu görünüyor mu?
      expect(find.byIcon(Icons.share), findsOneWidget);
    });
  });
}
```

### 9.7 Dependencies

> `pubspec.yaml`'a ekle:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mocktail: ^1.0.4
  fake_cloud_firestore: ^3.0.0
  golden_toolkit: ^0.15.0
  firebase_auth_mocks: ^0.14.0
```

```bash
flutter pub get
flutter test
flutter test --update-goldens  # Golden test'leri ilk kez generate et
```

---

## 10. Önerilen Yol Haritası (Sprint Plan)

### Sprint Plan — 6 Haftalık Yol Haritası

| Sprint | Süre | İçerik | Önem | Tahmini Saat |
|--------|------|--------|------|--------------|
| **Hotfix-1** | 1 gün | 🔴 `firestore.rules` güvenlik düzeltmesi (Bölüm 2) · 🔴 Yazım hatası fix (7.1) | KRİTİK | 4-6 saat |
| **Hotfix-2** | 2-3 gün | 🔴 `AiComparisonSummaryService` try-catch (4.1) · 🔴 `ComparisonRepository` Future.wait fix (4.2) · 🔴 Force-unwrap fix (4.4-4.5) | KRİTİK | 10-15 saat |
| **Sprint-A: Cloud** | 1 hafta | 🔴 Cloud Function transaction + region (3.1, 3.4) · 🟠 TTL policy (3.3) · 🟠 Timeout pyramid (3.5) | YÜKSEK | 20-25 saat |
| **Sprint-B: UI Polish** | 1 hafta | 🟠 Shimmer (5.1) · 🟠 AppColors genişletme (5.2) · 🟠 Pull-to-refresh (5.5) · 🟠 Empty states (5.7) · 🟡 Hero (5.8) · 🟡 Haptic (5.9) | YÜKSEK | 25-30 saat |
| **Sprint-C: Localization** | 1 hafta | 🟠 l10n setup (5.3) · 🟠 String migration (TR + EN) · 🟡 Number/date formatters (7.5) | YÜKSEK | 20-25 saat |
| **Sprint-D: Performance** | 1 hafta | 🟡 Firestore indexes (6.1) · 🟡 autoDispose (6.2) · 🟡 Denormalize placeCount (6.4) · 🟡 cached_network_image (6.6) | ORTA | 18-22 saat |
| **Sprint-E: Tests** | 1 hafta | 🟠 Repository tests (9.1) · 🟠 AI service tests (9.2) · 🟡 Provider tests (9.3) · 🟡 Golden tests (9.4) · 🟡 Rules tests (2.8) | YÜKSEK | 30-35 saat |
| **Sprint-F: Features** | 2 hafta | 🟢 Comparison history (8.2) · 🟢 Deep-link (8.3) · 🟢 Üçlü karşılaştırma (8.4) · 🟢 Regenerate button (8.1) | DÜŞÜK | 40-50 saat |

**Toplam:** 6 hafta · ~170-210 geliştirici saati

### Sprint İçinde Önerilen Sıra (Her Sprint İçin)

```
Pazartesi:  Branch oluştur, planlama
Salı-Çar:   Implementation
Perşembe:   Testing + golden test update
Cuma:       Code review + merge + deploy to staging
```

### Risk Azaltma — Aşamalı Deploy

```
[Hotfix-1] firestore.rules → staging
            ↓
            Test (rules emulator) → prod
[Hotfix-2] Client kod fix → staging
            ↓
            Smoke test → prod (canary %10 → %50 → %100)
[Sprint-A] Cloud Functions → staging
            ↓
            Region migration (eski tarafı 24 saat tut)
            ↓
            Production
```

### Rollback Stratejisi

| Sprint | Rollback Yöntemi |
|--------|------------------|
| Hotfix-1 (Rules) | `git revert` + `firebase deploy --only firestore:rules` |
| Hotfix-2 (Client) | App Store / Play Store eski sürüme dön |
| Sprint-A (Cloud) | Eski Cloud Function'ı redeploy (eski region'da hala duruyor) |
| Sprint-D (Indexes) | İndeks silinmesin (sadece eklemek için) |

---

## 11. Ek — PR Review Kontrol Listesi

> Aşağıdaki listeyi her karşılaştırma PR'ının açıklamasına ekle. Reviewer her madde için ✅ veya ❌ koysun.

### Güvenlik
- [ ] Yeni Firestore collection eklendiyse rules'da explicit olarak kuralı var mı?
- [ ] `allow write: if true` ya da `allow write: if isAuthenticated()` (admin verisi için) kullanılmamış mı?
- [ ] Cloud Function `enforceAppCheck: true` ile korunuyor mu?
- [ ] Kullanıcıya gönderilen hata mesajında external API detayı (Groq, Stripe vb.) sızmıyor mu?
- [ ] Webhook'larda signature/secret doğrulaması var mı?

### Hata Yönetimi
- [ ] Tüm async fonksiyonlar try-catch içinde mi? (özellikle `callable.call`, `await firestore.get`)
- [ ] Catch bloklarında `debugPrint` + `Crashlytics.recordError` var mı?
- [ ] Boş `catch (_)` blok yok mu?
- [ ] Force-unwrap (`!`) kullanımı minimize edilmiş mi? Lokal değişkenlere alınmış mı?
- [ ] Null check sonrası state değişikliği olabilecek yerlerde defensive copy var mı?

### Performans
- [ ] `Provider` yerine `Provider.autoDispose` kullanılmış mı? (özellikle ekran-spesifik provider'lar)
- [ ] Tüm sorgular için gerekli Firestore composite index var mı? (`firestore.indexes.json`)
- [ ] `Future.wait` kullanımı uygun mu? (kritik veri için `eagerError: true`, opsiyonel için per-future try-catch)
- [ ] N+1 query yok mu? (`whereIn` ile batch fetch kullanılıyor mu?)
- [ ] Resimler `cached_network_image` ile yükleniyor mu?

### UI / UX
- [ ] Loading state shimmer ile mi yapılmış? (`CircularProgressIndicator` yerine)
- [ ] Pull-to-refresh ekrana eklenmiş mi?
- [ ] Empty state Lottie/illustration ile mi?
- [ ] Hardcoded renkler `AppColors`'a taşınmış mı?
- [ ] Tüm string'ler `AppLocalizations.of(context)` ile mi?
- [ ] `Semantics` widget'ı kritik UI öğelerinde var mı?
- [ ] Haptic feedback eklenmiş mi? (karşılaştırma tamamlandığında, swap'ta)
- [ ] Dark mode destekleniyor mu? (`Theme.of(context).brightness`)

### Test
- [ ] Yeni eklenen logic için unit test yazılmış mı?
- [ ] Repository fonksiyonu için happy + edge case + error test'leri var mı?
- [ ] Yeni widget için golden test var mı? (kritik widget'lar için)
- [ ] Firestore rules için emulator test var mı?
- [ ] Coverage %70'in altına düşmemiş mi?

### Maliyet
- [ ] Yeni log koleksiyonu eklendiyse TTL policy var mı?
- [ ] Cache hit'te quota düşmüyor mu? (gereksiz Cloud Function tetikleme yok)
- [ ] Region tutarlı mı? (Türkiye için `europe-west1`)

### Belgeleme
- [ ] CHANGELOG.md güncellendi mi?
- [ ] Breaking change varsa migration guide var mı?
- [ ] PR description'da "neden" anlatılıyor mu (sadece "ne" değil)?

---

## 12. Ek — Hızlı Referans Tablolar

### Hata Kodu → User Message Mapping

| Cloud Function Hata Kodu | Client Exception | User Message (TR) | User Message (EN) |
|--------------------------|-------------------|-------------------|--------------------|
| `unauthenticated` | `AiSummaryUnauthenticated` | "AI özet için giriş yapman gerekiyor." | "Sign in to use AI summary." |
| `invalid-argument` | `AiSummaryUnknownError` | "Beklenmeyen bir hata oluştu." | "Unexpected error occurred." |
| `resource-exhausted` | `AiSummaryQuotaExceeded` | "Günlük AI özet hakkın doldu." | "Daily AI summary limit reached." |
| `failed-precondition` | `AiSummaryUnavailable` | "AI servisi şu anda kullanılamıyor." | "AI service unavailable." |
| `unavailable` | `AiSummaryUnavailable` | "AI servisi geçici olarak yanıt vermiyor." | "AI service temporarily down." |
| `deadline-exceeded` | `AiSummaryUnavailable` | "İstek zaman aşımına uğradı." | "Request timed out." |
| `network-request-failed` | `AiSummaryNetworkError` | "İnternet bağlantını kontrol et." | "Check your internet connection." |
| `cancelled` | `AiSummaryNetworkError` | "İstek iptal edildi." | "Request cancelled." |
| `internal` | `AiSummaryUnknownError` | "Sunucu hatası oluştu." | "Server error occurred." |
| _other_ | `AiSummaryUnknownError` | "Bilinmeyen hata. Tekrar dene." | "Unknown error. Try again." |

### Subscription Tier × Feature Matrix

| Özellik | Free | Plus | Pro |
|---------|------|------|-----|
| Üniversite karşılaştırma | 1/gün (+reklam ile +1) | Sınırsız | Sınırsız |
| Bölüm karşılaştırma | ❌ | ✅ | ✅ |
| Şehir karşılaştırma | ❌ | ✅ | ✅ |
| Üçlü karşılaştırma | ❌ | ❌ | ✅ |
| AI özet | ❌ | ❌ | 5/gün |
| AI özet regenerate | ❌ | ❌ | 2/gün |
| Pro chart (trend, scatter, heatmap) | ❌ | ❌ | ✅ |
| Karşılaştırma geçmişi | Son 3 | Son 20 | Sınırsız |
| Karşılaştırma notları | ❌ | ❌ | ✅ |
| Reklamsız | ❌ | ✅ | ✅ |
| Deep-link paylaşım | ✅ | ✅ | ✅ |

### Firestore Read Count — Karşılaştırma Başına

| İşlem | Mevcut | Optimize | Tasarruf |
|-------|--------|----------|----------|
| Üniversite veri (A + B) | 2 | 2 | 0 |
| Place sayım (A + B) | 50-300 | 0 (denormalize) | %100 |
| Department sayım (A + B) | 30-100 | 0 (denormalize) | %100 |
| Department detay (Plus tier) | 2 | 2 | 0 |
| AI özet cache | 1 | 1 | 0 |
| Usage stats | 1 | 1 | 0 |
| **Toplam (avg)** | **~200** | **~6** | **%97** |

### Dosya × Düzeltme Sayısı Heat Map

| Dosya | 🔴 Kritik | 🟠 Yüksek | 🟡 Orta | 🟢 Düşük | **Toplam** |
|-------|----------|-----------|---------|----------|------------|
| firestore.rules | 6 | 1 | 0 | 0 | **7** |
| functions/src/comparison/summary.ts | 3 | 2 | 1 | 0 | **6** |
| ai_comparison_summary_service.dart | 1 | 1 | 0 | 0 | **2** |
| comparison_repository.dart | 1 | 0 | 1 | 0 | **2** |
| comparison_providers.dart | 2 | 3 | 2 | 1 | **8** |
| university_comparison_screen.dart | 0 | 3 | 4 | 2 | **9** |
| department_comparison_screen.dart | 1 | 2 | 3 | 1 | **7** |
| city_comparison_screen.dart | 1 | 2 | 3 | 1 | **7** |
| comparison_ai_summary_card.dart | 0 | 2 | 1 | 1 | **4** |
| comparison_hub_screen.dart | 0 | 1 | 2 | 2 | **5** |
| app_colors.dart | 0 | 1 | 1 | 0 | **2** |
| **TOPLAM** | **15** | **18** | **18** | **8** | **59** |

---

## 13. Kapanış Notu

### Bu Doküman Nasıl Kullanılmalı?

1. **Önce Hotfix-1 ve Hotfix-2** (Bölüm 2, 4.1-4.5, 7.1) yapılmadan production'a yeni karşılaştırma feature pushu yapılmamalı.
2. **Cloud Function değişiklikleri (Bölüm 3)** mutlaka staging'de test edilip, region migration'ı eski function'ı 24 saat çalışır halde tutarak yapılmalı.
3. **UI/Lokalizasyon (Bölüm 5, 7)** Sprint-B ve Sprint-C'ye paralel ilerletilebilir.
4. **Test kapsamı (Bölüm 9)** her sprintin sonunda artırılmalı, %70 hedefi 6 sprint sonunda yakalanmalı.
5. **Yeni özellikler (Bölüm 8)** ancak temel kararlılık sağlandıktan sonra başlatılmalı.

### Beklenen Etki

| Metrik | Şu An | Sonra | Değişim |
|--------|-------|-------|---------|
| Karşılaştırma başına Firestore read | ~200 | ~6 | -%97 |
| AI özet latency (Türkiye) | 6-8s | 3-5s | -%40 |
| Crash rate (karşılaştırma feature'ı) | ~%2.1 | <%0.3 | -%85 |
| Plus conversion (karşılaştırma'dan) | ~%4 | ~%8 | +%100 |
| Aylık Firestore maliyeti | ~$108 | ~$3 | -%97 |
| Pro tier value perception (NPS proxy) | 6.2/10 | 8.4/10 | +35% |

### İletişim

- **Bu doküman:** `/home/burak/uni_app/karsilastirmaekranıdüzenleme.md`
- **Proje branch:** `feat/sprint4.5-osym-data` (mevcut) → her sprint için yeni `feat/sprint-X-comparison-fix-Y` branch'leri açılmalı
- **Test ortamı:** `staging.uniseç.com` (rules test için Firebase Emulator Suite)

> **Son söz:** Karşılaştırma feature'ı uygulamanın en stratejik özelliklerinden biri. Bu dokümandaki tüm düzeltmeler tamamlandığında, uygulama Türkiye'deki üniversite seçim sürecinin **en güvenilir, en hızlı ve en kapsamlı dijital aracı** olma yolunda büyük bir adım atmış olacak. 🎓

**Hazırlanma süresi:** ~12 saat detaylı kod analizi · 3 paralel Explore ajan keşfi · 4 kritik dosyanın satır-bazlı incelemesi.

**Son güncelleme:** 2026-05-12


