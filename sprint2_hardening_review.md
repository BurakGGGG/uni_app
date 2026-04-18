# 📋 Sprint 2 Hardening — İnceleme Raporu

> **Proje:** ÜniSeç (uni_app)
> **Rapor Tarihi:** 18 Nisan 2026
> **Durum:** Sprint 3'e Geçiş Öncesi Kontrol
> **Genel Değerlendirme:** Planın ~%90'ı tamamlanmış. Bir kritik bug, birkaç güvenlik eksikliği mevcut.

---

## 📑 İçindekiler

1. [Genel Durum](#-genel-durum)
2. [Sprint 3 Blocker'ları](#-sprint-3-blockerları-önce-bunları-düzelt)
3. [Güvenlik ve Sprint 3 Hazırlığı](#️-güvenlik--sprint-3-hazırlığı)
4. [Plan Maddelerinin Doğrulaması](#-plan-maddelerinin-doğrulaması)
5. [Kod Kokusu ve İyileştirmeler](#-irili-ufaklı-kod-kokusu--iyileştirmeler)
6. [Sprint 3'e Geçiş Checklist'i](#-sprint-3e-geçiş-checklisti)
7. [Sprint 3 İçin Ek Notlar](#-sprint-3-için-ek-notlar)

---

## 🎯 Genel Durum

Sprint 2 hardening planındaki maddelerin büyük çoğunluğu doğru ve temiz bir şekilde uygulanmış. Özellikle aşağıdaki alanlar production-ready hissettiriyor:

- ✅ **Auth & Router sistemi** — redirect mantığı, `from` query parametresi, `refreshListenable` kullanımı çok sağlam
- ✅ **edu.tr doğrulama akışı** — `user.reload()` + `getIdToken(true)` + Firestore senkronizasyonu hem uygulama açılışında hem lifecycle resume'da tetikleniyor
- ✅ **Seed data zenginleştirme** — `baseScore`, `ranking`, `scoreType`, `duration`, `quota` eklenmiş, ±20/±5000/±15 randomize ediliyor
- ✅ **Rating altyapısı** — Model seviyesinde `avgRating`, `reviewCount`, `categoryRatings` hazır
- ✅ **Review model iskeleti** — Plandaki şemaya tam uyumlu
- ✅ **Favoriler** — Subcollection path'i, unauthenticated snackbar yönlendirmesi, home'daki küçük kalp ikonu; plandakinden daha temiz
- ✅ **Search route** — Ayrı `/search` route ile hem home hem explore'dan erişim
- ✅ **Explore filtreleri** — Şehir multi-select, quick filter chips, aktif filtre badge'i

**Ama** Sprint 3'e geçmeden mutlaka düzeltilmesi gereken bir kritik bug ve birkaç güvenlik eksikliği var.

---

## 🚨 Sprint 3 Blocker'ları (önce bunları düzelt)

### 1. `EditProfileScreen`'de `universityId` hiç set edilmiyor — KRİTİK

**Dosya:** `lib/features/profile/presentation/screens/edit_profile_screen.dart`

`_saveProfile()` metodunda `authRepo.updateProfile(...)` çağrısı yapılıyor ama `universityId` parametresi geçilmiyor:

```dart
await authRepo.updateProfile(
  uid: user.uid,
  displayName: _nameController.text.trim(),
  university: _selectedUniversity,   // sadece isim string'i
  department: _selectedDepartment,
  grade: _selectedGrade,
  // universityId EKSİK
);
```

Dahası, dropdown'daki `_universities` listesi **hardcoded** ve seed data'daki gerçek isimlerle eşleşmiyor. Örneğin:

| Hardcoded Dropdown | Seed Data |
|---|---|
| `ODTÜ` | `Orta Doğu Teknik Üniversitesi` (id: `odtu`) |
| `İTÜ` | `İstanbul Teknik Üniversitesi` (id: `itu`) |
| `YTÜ` | `Yıldız Teknik Üniversitesi` (id: `yildiz_teknik`) |

**Neden blocker?**

Sprint 3'te bir kullanıcı yorum yazdığında `review.universityId` alanı dolmalı ve bu kullanıcının kayıtlı üniversitesine bağlanmalı. `firestore.rules` da kullanıcının sadece kendi üniversitesi hakkında yorum yapabilmesini zorlayacaksa `users/{uid}.universityId` alanına ihtiyaç var. Şu an bu alan hiç dolmuyor.

**Fix:**

```dart
class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  // ...
  String? _selectedUniversity;
  String? _selectedUniversityId;  // ← ekle
  // Hardcoded _universities listesini SİL
  
  @override
  void _loadProfile() {
    final userAsync = ref.read(currentUserProvider);
    userAsync.whenData((profile) {
      if (profile != null) {
        _nameController.text = profile.displayName;
        _selectedUniversity = profile.university;
        _selectedUniversityId = profile.universityId;  // ← ekle
        _selectedDepartment = profile.department;
        _selectedGrade = profile.grade;
        _currentPhotoUrl = profile.photoUrl;
      }
    });
  }
}
```

Build metodunda dropdown'u provider'a bağla:

```dart
final universitiesAsync = ref.watch(allUniversitiesProvider);

universitiesAsync.when(
  loading: () => const LinearProgressIndicator(),
  error: (e, _) => Text('Üniversiteler yüklenemedi: $e'),
  data: (unis) => DropdownButtonFormField<UniversityModel>(
    initialValue: unis.firstWhereOrNull((u) => u.id == _selectedUniversityId),
    isExpanded: true,
    decoration: const InputDecoration(
      labelText: 'Üniversite',
      prefixIcon: Icon(Icons.school_outlined),
    ),
    items: unis.map((u) => DropdownMenuItem(
      value: u,
      child: Text(u.name, overflow: TextOverflow.ellipsis),
    )).toList(),
    onChanged: (uni) {
      setState(() {
        _selectedUniversity = uni?.name;
        _selectedUniversityId = uni?.id;
        _hasChanges = true;
      });
    },
  ),
),
```

Save çağrısında ikisini de gönder:

```dart
await authRepo.updateProfile(
  uid: user.uid,
  displayName: _nameController.text.trim(),
  university: _selectedUniversity,
  universityId: _selectedUniversityId,  // ← ekle
  department: _selectedDepartment,
  grade: _selectedGrade,
);
```

---

### 2. Department textfield'ında `setState` eksik

**Dosya:** `lib/features/profile/presentation/screens/edit_profile_screen.dart`

```dart
TextFormField(
  initialValue: _selectedDepartment,
  onChanged: (value) {
    _selectedDepartment = value;
    _hasChanges = true;   // ← setState'in DIŞINDA
  },
),
```

`_hasChanges` değişti ama widget rebuild olmadığı için alt taraftaki `GradientButton`'un `onPressed` koşulu güncellenmiyor. Sonuç: kullanıcı sadece departman alanına yazdığında **"Kaydet" butonu disabled kalıyor**.

**Fix:**

```dart
TextFormField(
  initialValue: _selectedDepartment,
  textCapitalization: TextCapitalization.words,
  decoration: const InputDecoration(
    labelText: 'Bölüm',
    prefixIcon: Icon(Icons.menu_book_outlined),
    hintText: 'Örn: Bilgisayar Mühendisliği',
  ),
  onChanged: (value) {
    setState(() {
      _selectedDepartment = value;
      _hasChanges = true;
    });
  },
),
```

---

## ⚠️ Güvenlik / Sprint 3 Hazırlığı

### 3. Firestore rules — review yazarken üniversite eşleşmesi

**Dosya:** `firestore.rules`

Şu anki kural:

```
allow create: if isVerifiedStudent() &&
  request.resource.data.userId == request.auth.uid;
```

Plandaki şart "kullanıcı sadece kendi üniversitesi hakkında yorum yapabilir" idi. Bu enforce edilmiyor. Sprint 3'e geçmeden ekle:

```
allow create: if isVerifiedStudent() &&
  request.resource.data.userId == request.auth.uid &&
  request.resource.data.universityId == 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.universityId;
```

> ⚠️ **Not:** Bu, madde 1'deki `universityId` fix'i yapılmadan anlamsız. `users/{uid}.universityId` boş olursa kural başarısız olur ve hiç kimse yorum yazamaz.

> 💡 `get()` okuması rule başına ekstra okuma maliyeti yazar ama review creation sık yapılan bir işlem değil — sorun değil.

---

### 4. Firestore composite indexleri henüz tanımlı değil

`reviews` koleksiyonuna yapılacak sorgular (üniversiteye ait, bölüme ait, son yorumlar, kullanıcı yorumları) composite index isteyecek. İlk sorguda Firestore hata mesajıyla gerekli index linkini verir ama hazırda olsun:

**Dosya:** `firestore.indexes.json` (proje kökünde oluştur)

```json
{
  "indexes": [
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "universityId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "targetId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isApproved", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Sonra:

```bash
firebase deploy --only firestore:indexes
```

---

### 5. Rating agregasyon stratejisi belirsiz

`UniversityModel.avgRating`, `reviewCount`, `categoryRatings` alanları seed'de 0 olarak geliyor. Sprint 3'te ne zaman ve nasıl güncellenecek?

**İki seçenek:**

| Seçenek | Artı | Eksi |
|---|---|---|
| **Cloud Function trigger** | Admin SDK ile yazar, güvenli; client kodu basit | Functions kurulumu gerekir, cold start |
| **Client-side transaction** | Ekstra altyapı yok | Firestore rules'u gevşetmek gerekir → güvenlik açığı |

**Öneri:** Cloud Function yolu.

Sprint 3 başında 30 dakika ayırıp basit bir Cloud Function yaz:

```bash
firebase init functions
# TypeScript seç
```

**`functions/src/index.ts` iskeleti:**

```typescript
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const onReviewWritten = onDocumentWritten(
  'reviews/{reviewId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    
    // Hangi üniversiteyi güncelleyeceğiz?
    const universityId = after?.universityId ?? before?.universityId;
    if (!universityId) return;

    const db = admin.firestore();
    const reviewsRef = db.collection('reviews')
      .where('universityId', '==', universityId)
      .where('isApproved', '==', true);

    const snap = await reviewsRef.get();
    
    if (snap.empty) {
      await db.doc(`universities/${universityId}`).update({
        avgRating: 0,
        reviewCount: 0,
        categoryRatings: {},
      });
      return;
    }

    // Ortalama hesapla
    let totalRating = 0;
    const categorySum: Record<string, number> = {};
    const categoryCount: Record<string, number> = {};

    snap.docs.forEach(doc => {
      const r = doc.data();
      totalRating += r.rating ?? 0;
      
      const cats = r.categoryRatings ?? {};
      Object.entries(cats).forEach(([key, value]) => {
        categorySum[key] = (categorySum[key] ?? 0) + (value as number);
        categoryCount[key] = (categoryCount[key] ?? 0) + 1;
      });
    });

    const avgRating = totalRating / snap.size;
    const categoryRatings: Record<string, number> = {};
    Object.keys(categorySum).forEach(key => {
      categoryRatings[key] = categorySum[key] / categoryCount[key];
    });

    await db.doc(`universities/${universityId}`).update({
      avgRating,
      reviewCount: snap.size,
      categoryRatings,
    });
  }
);
```

Bu olmadan rating alanları **hiçbir zaman güncellenmez**, sadece 0 kalır.

---

### 6. Firebase Storage rules eksik

**Dosya:** `storage.rules` (proje kökünde oluştur)

`auth_repository.dart`'taki `uploadProfilePhoto` `profile_photos/{uid}.jpg` path'ine yazıyor. Production'da default kurallar tüm yazmaları bloke eder.

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // ─── Profil Fotoğrafları ─────────────────────────────────
    match /profile_photos/{fileName} {
      allow read: if true;
      allow write: if request.auth != null
        && fileName == request.auth.uid + '.jpg'
        && request.resource.size < 5 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }

    // ─── Yorum Fotoğrafları (Sprint 3) ───────────────────────
    match /review_images/{userId}/{imageId} {
      allow read: if true;
      allow write: if request.auth != null
        && request.auth.uid == userId
        && request.resource.size < 10 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }
  }
}
```

**`firebase.json`'a ekle:**

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  }
}
```

Deploy:

```bash
firebase deploy --only storage
```

---

## ✅ Plan Maddelerinin Doğrulaması

| Plan Maddesi | Durum | Not |
|---|---|---|
| **2.1.1** Onboarding kontrolü | ✅ | `main.dart` → `sharedPreferencesProvider` override → router `initialLocation` dinamik. Debug reset butonu da mevcut. |
| **2.1.2** Router auth redirect | ✅ | `refreshListenable` + `redirect` + `from` query param. Temiz ve sağlam. |
| **2.1.3** edu.tr verification akışı | ✅ | `reloadAndCheckVerification()` → `user.reload()` + `getIdToken(true)` + Firestore update. `AppShell`'de hem `initState` hem `didChangeAppLifecycleState` tetikliyor. Profilde manuel "Yenile" butonu var. |
| **2.1.4** Auth retry/fallback temizliği | ✅ | Sahte `DateTime.now()` UserModel kaldırılmış. Firestore yazımı başarısızsa `signOut()` çağrılıyor. Register'da auth user `delete()` yapılıyor. Retry 2 denemeye düşmüş. |
| **2.2.1** Seed tamamlanması | ✅ | Tüm alanlar eklendi, randomize ediliyor. Debug-only seed butonu var. |
| **2.2.2** Rating alanları | ✅ | `avgRating`, `reviewCount`, `categoryRatings` hem University hem Department modellerinde. `UniCard` gerçek değerleri kullanıyor. |
| **2.2.3** Review model iskeleti | ✅ | Model ve repository plandaki şemada. TODO'lar net. |
| **2.2.4** Mock kart TODO'ları | ✅ | `_RecentReviewCard`, `explore_screen`, `city_universities_screen`'de var. |
| **2.3.1** Tutarlı arama | ✅ | Ayrı `/search` route — planda "daha zarif" seçenek buydu. Home ve Explore ikisi de yönlendiriyor. |
| **2.3.2** Filtre genişletme | ⚠️ Kısmi | Şehir multi-select + quick filter chips + badge mevcut. Puan türü filtresi atlanmış (planda opsiyoneldi). |
| **2.3.3** Popüler üniversiteler | ✅ | Ayrı provider, `reviewCount desc` sonra `establishedYear asc`. `take(8)`. |
| **2.3.4** Lint temizliği | ✅ | `?badge` null-aware spread, `analysis_report.txt` gitignore'da. |
| **2.4** Favoriler | ✅ | Repository, provider, screen, detay sayfası kalp butonu, unauthenticated snackbar, home'da kalp ikonu. Subcollection path `firestore.rules`'la uyumlu. Plandakinden daha kaliteli olmuş. |
| **Bonus** `google_sign_in: 6.3.0` | ✅ | Caret kaldırılmış, sabitlenmiş. |

---

## 💡 İrili Ufaklı Kod Kokusu / İyileştirmeler

Etkisi düşük, ama Sprint 3'e girmeden temizlemek değer.

### 1. `LoginScreen._onLoginSuccess` default `/profile`'a gidiyor

Kullanıcı ana sayfadaki favori ikonundan login'e düştüyse `from` parametresi çalışır, ama favori butonundan gelmediyse login sonrası `/profile` yerine `/` (home) daha doğal bir UX. Ufak ama sık karşılaşılacak bir durum.

### 2. `AuthRepository._cacheTtl` 10 dakika

`isVerifiedStudent` değişince `clearCache()` çağrılıyor, iyi. Sadece şu durumda sorun: bir kullanıcı A cihazda edu.tr doğrulaması yapıp B cihazda login olursa, B'de `getUserProfile` cache'lenen eski veriyi gösterebilir. TTL sonrası düzelir. Kritik değil.

### 3. `home_screen.dart` `_RecentReviewCard` hardcoded 3 review

Sprint 3 başında `getRecentReviews()` çağrısı gelecek. `itemCount: 3` sabit; dinamik olmalı. Eğer 0 review varsa empty state gösterilmeli.

### 4. `cities.totalUniversityCount` manuel hardcode

Yeni üniversite eklersen count'u güncellemeyi unutursun. MVP için sorun değil ama ileride `universities` collection'dan aggregate edilebilir (10 şehir için pahalı olmaz).

### 5. `AuthController` hâlâ `StateNotifier`

Riverpod 2.x'in `Notifier`/`AsyncNotifier`'ını kullanmak daha idiomatik. Zorunlu değil ama `riverpod_lint` uyarı verir.

### 6. `pubspec.yaml` — kullanılmayan code generation dependency'leri

`riverpod_annotation`, `riverpod_generator`, `build_runner` eklenmiş ama şu an `@riverpod` annotation'ı hiç kullanılmıyor. Ya kullanmaya başla, ya çıkar.

### 7. `main.dart` — `firebase_options.dart` yok

`Firebase.initializeApp()` options'sız çağrılıyor. Best practice:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Bu komut `firebase_options.dart` oluşturur. Şu an Android için `google-services.json`'a, iOS için `GoogleService-Info.plist`'e bağımlısın; multiplatform build'lerde sorun çıkarabilir.

### 8. `ReviewModel` rating aralığı validation yok

1.0-5.0 arası olmalı ama constructor zorlamıyor. Sprint 3'te yorum yazma formu validation yapar, ama model seviyesinde `assert(rating >= 1.0 && rating <= 5.0)` savunma katmanı olur.

### 9. `firestore.rules` admin UID hardcoded

`C2Vx6N75h2Zu3aezHnpWwYcTNY82` — repoda açık, UID zaten auth context'te bilinir, güvenlik sorunu değil. Ama yeni admin eklemek zor. İleride `users/{uid}.isAdmin` field'ı + `get()` ile kontrol daha esnek olur.

---

## 📋 Sprint 3'e Geçiş Checklist'i

**Sırasıyla yapılması gerekenler:**

### Kritik (bunlar olmadan Sprint 3 çalışmaz)

- [ ] `EditProfileScreen`'i `allUniversitiesProvider`'a bağla, `universityId` kaydet
- [ ] Department textfield `onChanged` içine `setState` ekle
- [ ] `firestore.rules` review create'e university eşleşme kontrolü ekle
- [ ] `firestore.indexes.json` yaz ve deploy et
- [ ] `storage.rules` yaz ve deploy et
- [ ] Cloud Functions projesi init et (`firebase init functions`)
- [ ] `onReviewWritten` fonksiyonunu yaz ve deploy et

### Önemli (Sprint 3'ün ilk günü yapılabilir)

- [ ] `home_screen` mock review'larını empty state + gerçek provider beklemesine hazırla
- [ ] `LoginScreen` default redirect'i `/` yap
- [ ] `flutterfire configure` ile `firebase_options.dart` oluştur

### Temiz Geçiş

- [ ] `v0.2.1` tag at
- [ ] Sprint 3 branch'ını aç (`feat/sprint3-reviews`)
- [ ] `pubspec.yaml`'dan kullanılmayan code gen dependency'leri çıkar veya kullanmaya başla

---

## 📝 Sprint 3 İçin Ek Notlar

Sprint 3 kapsamında yazılacaklar:

### Yorum Yazma Ekranı

- Kategori bazlı yıldız puanlama (6 kategori üni için, 5 kategori bölüm için)
- Artı/Eksi chip seçimi + özel yazma
- Serbest metin yorum alanı (validation: min 20 karakter)
- Fotoğraf ekleme (`image_picker` → `review_images/{userId}/{uuid}.jpg`)
- Anonim paylaşım seçeneği (`isAnonymous: true`)

### Yorum Listeleme

- `_RecentReviewCard` gerçek veriyle
- Üniversite detayında tab olarak yorumlar
- Bölüm detayında yorumlar
- Sıralama: en yeni / en çok beğenilen
- Pagination (`limit(20)` + `startAfterDocument`)

### Like/Beğeni Sistemi

- `reviews/{reviewId}/likes/{userId}` subcollection
- Atomik transaction ile `review.likes` count güncelleme
- **Cloud Function yerine client-side transaction** burada uygun olabilir

### Moderasyon

- Basit Türkçe küfür filtresi (`functions/moderation.ts`)
- `isApproved: false` başlangıç (MVP için `true` da olabilir, admin manuel moderation)
- Flag/şikayet sistemi (v2)

### Rating Cloud Function

- Yukarıda iskeleti verdim
- Test: Functions emulator ile lokal test et

---

## 🎖️ Sprint 2 Kalite Değerlendirmesi

Auth ve router tarafı production hissediyor. Özellikle fark ettiğim şu detaylar planda yazılmayan ama çok doğru kararlar:

- `registerWithEmail`'de Firestore yazımı başarısız olursa auth user'ı `delete()` etmek — `email-already-in-use` tuzağını önlüyor
- `signInWithGoogle` catch bloğunda `signOut()` çağrısı — inconsistent state önlemi
- `AppShell`'in `WidgetsBindingObserver` ile lifecycle dinlemesi — resume'da edu.tr verification tetikliyor

Bu tür detaylar Sprint 2'nin kalitesinin plandan yüksek olduğunu gösteriyor. Sadece `universityId` boşluğu kapanınca Sprint 3'e rahatlıkla girilir.

---

## 🔗 Kaynaklar

- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [Cloud Functions for Firebase (v2)](https://firebase.google.com/docs/functions)
- [Riverpod 2.x Migration Guide](https://riverpod.dev/docs/migration/from_state_notifier)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)

---

*Bu rapor Sprint 2 hardening planındaki her maddenin kod seviyesinde doğrulanmasıyla hazırlanmıştır. Sprint 3 boyunca referans olarak kullanılabilir.*
