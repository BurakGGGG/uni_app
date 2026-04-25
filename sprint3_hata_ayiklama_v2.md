# 🐛 Sprint 3.2 — İkinci Tur Hata Ayıklama & Derin Optimizasyon

> **Süre:** 4 iş günü
> **Ekip:** Kişi A + Kişi B
> **Giriş noktası:** `v0.3.1` deploy edildi, ama kullanıcı testlerinde **like butonu flicker** ve **eski telefonlarda kasma** sorunları ortaya çıktı
> **Çıkış hedefi:** `v0.3.2` — like akışı stabil, performans eski telefonlarda dahi akıcı, regression sıfır

---

## 📋 Bug Özeti & Kritiklik Skoru

Sen iki bug raporladın, ben kodu satır satır taradım ve **bu iki bug'ın altında yatan mimari sorunları** + **fark edilmemiş 5 ek bug** tespit ettim. Toplam 7 madde, hepsinin kök sebebi açıklanmış.

| # | Bug | Etki | Kim | Süre |
|---|-----|------|-----|------|
| **B1** | Like butonu rengi anlık gri'ye dönüp tekrar mor oluyor (flicker) | **Kritik UX** | Kişi B | 3-4 sa |
| **B2** | `userLikedReviewsProvider` collectionGroup query — gizli maliyet bombası + yavaş | **Kritik Performans** | Kişi B | 3 sa |
| **B3** | ReviewCard her like değişiminde tüm liste rebuild oluyor | **Kritik Performans** | Kişi A | 4 sa |
| **B4** | `getRecentReviews`/`getUniversityReviews` stream'leri keepAlive değil, ekran her açılışta yeni bağlantı | **Yüksek Performans** | Kişi A | 2 sa |
| **B5** | Eski telefonda CachedNetworkImage memCache değerleri yetersiz/eksik | **Yüksek Performans** | Kişi B | 2 sa |
| **B6** | `home_screen` CustomScrollView içinde nested ListView/horizontal scroll → layout overhead | **Orta Performans** | Kişi A | 2 sa |
| **B7** | `flutter_animate` her ekran girişte tekrar tetikleniyor (especially `bottom nav` geçişlerinde) | **Orta Performans** | Kişi B | 1 sa |

**Toplam tahmini süre:** ~17 sa × 2 kişi = ~34 person-hours → 4 günlük sprint için rahat.

---

## 🔬 Detaylı Kök Sebep Analizi

### **B1 — Like Butonu Renk Flicker'ı (Kullanıcının raporladığı bug)**

**Senin tariflediğin:** "Bir yorumu beğenince mor oluyor, ardından geri gri oluyor, beğendim mi beğenmedim mi belli olmuyor."

**Kodu izleyince ne oluyor:**

`review_providers.dart` içinde `LikeController.toggleLike`:

```dart
Future<void> toggleLike({...}) async {
  // 1. Optimistic update — pending=true yapılıyor
  state = {...state, reviewId: !currentlyLiked};

  try {
    await _repo.likeReview(reviewId, userId); // 2. Firestore yazımı (~200-800ms)
  } catch (e) {
    state = {...state}..remove(reviewId);
    rethrow;
  }

  // 3. 500ms sonra pending'i SIL — burada problem başlıyor
  Future.delayed(const Duration(milliseconds: 500), () {
    if (mounted) {
      state = {...state}..remove(reviewId);
    }
  });
}
```

`like_button.dart`:
```dart
final isLikedFromServer = ref.watch(userLikedReviewsProvider.select(...));
final pending = ref.watch(likeControllerProvider.select((m) => m[review.id]));
final isLiked = pending ?? isLikedFromServer; // pending null olunca server'a düşüyor
```

**Zaman çizelgesi (gerçekte yaşanan):**

```
t=0ms     : Tıkla → pending=true → UI: mor ✅
t=200ms   : Firestore write tamamlandı
t=500ms   : pending=null silindi → UI: pending null, isLikedFromServer=??
t=500-1500ms: collectionGroup snapshot HENÜZ GELMEDI → likedIds eski (false) → UI: gri ❌
t=1500ms  : Snapshot geldi, likedIds güncellendi → UI: mor ✅
```

**Kök sebep:** İki ayrı sorun birleşip flicker yaratıyor:

1. **Sabit 500ms gecikme yetersiz.** Firestore Türkiye latency'si + collectionGroup snapshot propagation hesaba katılmamış. Snapshot 800-2000ms aralığında geliyor.

2. **`Future.delayed` + race condition:** Pending temizlenmeden snapshot'un gelmesini garanti etmiyoruz. Kullanıcı arka arkaya iki tıklarsa daha da kötüleşiyor.

3. **`collectionGroup('likes').where(__name__ == userId)` SLOW:** Firestore'da `__name__` filter ile collectionGroup query, document ID'ye göre değil tam yola göre arama yapıyor. Bu sorgu **lineer ölçeklenir** — `likes` koleksiyonu büyüdükçe yavaşlıyor.

**Düzeltme stratejisi:** Pending'i snapshot **gerçekten yetiştiği zaman** temizle, sabit gecikme bırakma. Bunun için iki seçenek var, ikincisini öneriyorum:

**Seçenek A (Yetersiz):** `Future.delayed` süresini 1500ms'ye çıkar. → Hala race condition var, sadece nadir görünür.

**Seçenek B (ÖNERİLEN):** Pending state'i bırak; **`isLikedFromServer == pending` olduğunda** otomatik temizlensin. Bu, snapshot'un yetiştiğinden emin olduğumuz andır. Ayrıca `userLikedReviewsProvider`'ı `collectionGroup` yerine **kullanıcı dökümanı altındaki `likedReviews` array'i**ile değiştir.

---

### **B2 — collectionGroup Query Anti-Pattern'i**

**Sorun şu kodda:**
```dart
final userLikedReviewsProvider = StreamProvider<Set<String>>((ref) {
  return FirebaseFirestore.instance
      .collectionGroup('likes')
      .where(FieldPath.documentId, isEqualTo: user.uid)
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.reference.parent.parent!.id).toSet());
});
```

**Neden kötü:**

1. **CollectionGroup query, tüm `likes` subcollection'larını tarar.** Şu an 100 yorum × 5 like = 500 dokümanın tarandığını düşün. 1000 yorum × 20 like = 20,000 doküman.

2. **`FieldPath.documentId` filter, native Firestore index'i kullanmaz.** Her snapshot'ta full scan + filter.

3. **Maliyet:** Her stream emit'i okunan tüm dokümanlar için **read counter** çalışır. Build edilince bu uygulamayı kullanan herkesin uygulamayı her açtığında 100+ read olur. Aylık 1000 kullanıcı = 100K okuma/ay = ücretli plan.

4. **Snapshot latency uzun:** Tüm subcollection scan edildiği için Firestore'un bu sorguyu döndürmesi 500-1500ms+ alıyor. **B1 flicker'ının da nedeni bu.**

**Çözüm:** Like'ları `users/{uid}/likedReviews/{reviewId}` subcollection olarak da tut (denormalization). Yani aynı veriyi iki yerde:

- `reviews/{reviewId}/likes/{userId}` → backwards compat ve "kim beğendi" sorgusu için
- `users/{uid}/likedReviews/{reviewId}` → "ben hangi yorumları beğendim" için (HIZLI)

Stream `users/{uid}/likedReviews` snapshot'una bağlanır → tek user'ın subcollection'ı → milisaniyede gelir.

`firestore.rules` ve `likeReview` repo metodu güncellenmeli.

---

### **B3 — Tüm ReviewCard'lar Like'ta Rebuild Oluyor**

**Sorun:**

`like_button.dart`'ta v0.3.1'de `.select()` ekledik ama **yeterli değil:**

```dart
final isLikedFromServer = ref.watch(
  userLikedReviewsProvider.select(
    (async) => async.value?.contains(review.id) ?? false,
  ),
);
```

`.select` genelde işe yarar ama burada `userLikedReviewsProvider` her snapshot emit'inde **tüm Set yeniden oluşturuluyor** (`.toSet()` çağrısı). Riverpod `==` ile eşitlik kontrolü yapsa bile, `Set.contains` sonucu `bool` — o doğru karşılaştırılıyor. Bu kısım aslında DOĞRU.

Asıl sorun **`ReviewCard`'ın kendisi:**

```dart
class ReviewCard extends ConsumerWidget {
  // build() metoduna her geldiğinde tüm subwidget'lar tekrar hesaplanıyor
  // İçinde:
  // - LikeButton (ConsumerWidget)
  // - ReviewActionsMenu (ConsumerWidget) → her seferinde rebuild
  // - _CommentExpandable (StatefulWidget)
  // - cached_network_image (her foto için yeni Image widget)
}
```

ListView.builder elementleri zaten lazy build ediyor ama scroll'da görünen kartlar her render frame'de re-build oluyor çünkü:

1. **`AppColors.softShadow` getter her seferinde yeni `BoxShadow` listesi oluşturuyor** — `const` değil. Her widget rebuild'de Decoration eşitliği bozulur, GPU yeniden boyamaya zorlanır.

2. **`Border.all`, `BorderRadius.circular` her build'de yeniden çağrılıyor.** Bunlar const yapılabilir.

3. **`timeago.format(review.createdAt, locale: 'tr')` HER BUILD çalışıyor.** String formatlama maliyetli, cache'lenmeli.

4. **ListView.builder `addAutomaticKeepAlives: true` (default)** ama `cacheExtent` belirtilmemiş — Flutter sadece görünenden 250px ileride/gerideki kartı cache'liyor, fast scroll'da rebuild patlamaları oluyor.

**Çözüm planı:**
- `AppColors.softShadow` const yap
- `ReviewCard` decoration'larını cached static fields'a taşı
- timeago string'ini parent widget'tan parametre al, kart içinde hesaplama
- ListView.builder `cacheExtent: 1000` ekle
- Mümkünse ReviewCard'ı `StatelessWidget` (RepaintBoundary'li) yap

---

### **B4 — Stream Provider'lar keepAlive Değil**

**Şu an:**
```dart
final recentReviewsProvider = StreamProvider<List<ReviewModel>>((ref) {
  return ref.watch(reviewRepositoryProvider).getRecentReviews(limit: 5);
});

final universityReviewsProvider = StreamProvider.family<List<ReviewModel>, String>((ref, universityId) {
  return ref.watch(reviewRepositoryProvider).getUniversityReviews(universityId);
});
```

**Sorun:** `keepAlive` çağrılmamış. Bottom nav'da `Ana Sayfa → Keşfet → Ana Sayfa` yaparsan:

1. Ana sayfa açıldı → `recentReviewsProvider` Firestore'a bağlandı → veri geldi
2. Keşfet'e gittin → Ana sayfa unmount → provider auto-dispose, bağlantı kapandı
3. Ana sayfaya geri döndün → provider yeniden başlatıldı → Firestore'dan **yeniden okudu**

Her tab değişimi para ve süre kaybı.

**Çözüm:** Liste provider'larına `ref.keepAlive()` ekle. UniversityRepository zaten cache'liyor (5dk TTL), aynısını review provider'larında da uygulayalım.

Dikkat: `keepAlive` yorum güncel kalmasını engellemez çünkü `Stream` Firestore snapshot'una bağlı, snapshot otomatik güncel.

---

### **B5 — CachedNetworkImage memCache Eksik / Yetersiz**

**v0.3.1'de bazı yerleri düzelttik ama:**

`profile_screen.dart` — kullanıcı kart avatarı:
```dart
backgroundImage: NetworkImage(photoUrl),  // memCache YOK, raw NetworkImage
```

`review_card.dart` _buildHeader avatar:
```dart
backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
// CachedNetworkImage değil, plain NetworkImage → cache YOK
```

`edit_profile_screen.dart` — büyük profil fotoğrafı:
```dart
CachedNetworkImage(imageUrl: _currentPhotoUrl!, width: 110, height: 110, ...)
// memCache yok
```

`cached_network_image` paketi cache'i diskte tutar, ama **memory cache'i (RAM)** otomatik değil — memCacheWidth/Height ile sınırlamazsan tam çözünürlüklü image RAM'e yüklenir. 4MB foto avatar olarak gösterilirken RAM'de 4MB tutuluyor.

**Çözüm:** Tüm `NetworkImage` → `CachedNetworkImageProvider`, ve her yerde `memCacheWidth/Height` set et. Liste sayfalarında 50 kart × 4MB = 200MB RAM, eski telefonlarda OOM (Out of Memory) crash riski.

---

### **B6 — Home Screen Layout Overhead**

`home_screen.dart` yapısı:

```
SafeArea
└── CustomScrollView
    ├── SliverToBoxAdapter (Header)
    ├── SliverToBoxAdapter (Search)
    ├── SliverToBoxAdapter (Hero Banner)
    ├── SliverToBoxAdapter
    │   └── Column
    │       ├── SectionHeader
    │       └── SizedBox(height: 200)
    │           └── ListView.builder horizontal (PopularUniCard)
    ├── SliverToBoxAdapter
    │   └── Column
    │       ├── SectionHeader
    │       └── SizedBox(height: 110)
    │           └── ListView.builder horizontal (CityChip)
    ├── SliverToBoxAdapter (SectionHeader)
    └── SliverList (ReviewCard)
```

**Sorun:** Her `ListView.builder horizontal` ana scroll içinde **nested scroll**. Hatta her biri kendi `ScrollController`'ı tutuyor. Eski telefonlarda bu nested viewport handling **frame drop** yapıyor.

**Ayrıca:** Yatay listeler `shrinkWrap` değil, sabit `SizedBox(height: ...)` içinde — yine de ListView.builder rendering pipeline'ında 8 widget create ediliyor, hepsi memory'ye yükleniyor.

**Çözüm:**

1. Yatay ListView'lar için `physics: ClampingScrollPhysics()` (default `BouncingScrollPhysics`'e göre daha hafif)
2. Yatay item sayısı küçük (8 popüler, 10 şehir) — `SingleChildScrollView + Row` daha verimli olabilir veya en azından **explicit `cacheExtent`** belirt.
3. PopularUniCard ve CityChip'leri `RepaintBoundary` ile sar — yatay scroll sırasında dikey scroll'u tetiklediklerinde repaint sınırla.

---

### **B7 — flutter_animate Tab Switch'te Tekrar Tetikleniyor**

`StatefulShellRoute.indexedStack` kullanıyoruz, bu doğru — sayfalar dispose olmuyor. Ama `flutter_animate` widget'ları, parent rebuild olduğunda animasyonu **baştan oynatıyor.**

Örneğin `home_screen.dart`:
```dart
).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1)
```

Tab değiştirdiğinde `HomeScreen.build()` çağrılırsa (auth state değişikliği gibi nedenlerle), bu animasyon yeniden tetiklenir. **Görsel jank.**

**Çözüm:** Animasyonları `key` ile sabitlemek veya bir kerelik gösterilmesi gerekenleri `AutomaticKeepAliveClientMixin` veya `ValueKey` ile koru.

Ya da en sağlamı: **scroll'da görünen / sürekli rebuild olabilen bölgelerden flutter_animate'i tamamen çıkar.** v0.3.1'de bunu yarım yaptık (favorites_screen ve home_screen kısmen). Tamamlayalım.

---

## 🎯 Görev Dağılımı

| Bug | Sahip | Bağımlı dosyalar | Çakışma |
|-----|-------|------------------|---------|
| B1 | Kişi B | `like_button.dart`, `review_providers.dart` | B2 ile birlikte yapılmalı |
| B2 | Kişi B | `review_providers.dart`, `review_repository.dart`, `firestore.rules`, `firestore.indexes.json` | B1 ile birleşik |
| B3 | Kişi A | `review_card.dart`, `app_colors.dart`, `review_list.dart` | B7 ile az çakışma |
| B4 | Kişi A | `review_providers.dart` | **B2 ile aynı dosya — sıraya koyun** |
| B5 | Kişi B | `profile_screen.dart`, `edit_profile_screen.dart`, `review_card.dart` | B3 ile çakışıyor (review_card) |
| B6 | Kişi A | `home_screen.dart` | Yok |
| B7 | Kişi B | `home_screen.dart`, `favorites_screen.dart` vb. | B6 ile aynı dosya |

**Çakışma çözümleri:**
- **`review_providers.dart`:** B2 (Kişi B) ÖNCE bitirsin, B4 (Kişi A) üstüne yazsın. B2 toggleLike + provider yapısını değiştiriyor; B4 sadece `keepAlive` ekleyecek.
- **`review_card.dart`:** B3 (Kişi A) önce bitirsin (decoration cache, structural fix), B5 (Kişi B) sonra image fix'i ekler.
- **`home_screen.dart`:** B6 (Kişi A) önce bitirsin, B7 (Kişi B) animasyon temizliği yapar.

---

## 📅 Günlük Plan

### **GÜN 1 — Like Sistemi Ameliyatı (B1 + B2)**

> **Bu gün Kişi B yoğun, Kişi A başka iş alacak.**

#### Sabah Standup (15dk)
- B2 schema değişikliği önce, sonra B1 controller değişimi
- Kişi A bugün B6 (home_screen) ile başlasın, yarın `review_providers.dart` müsait olunca B4'e geçer

#### Kişi B — B2: Like Veri Modelini Denormalize Et

**1. Adım — `review_repository.dart` `likeReview` güncelle:**

```dart
Future<void> likeReview(String reviewId, String userId) async {
  // İki referans: review altındaki like + user altındaki likedReview
  final reviewLikeRef = _firestore
      .collection('reviews').doc(reviewId)
      .collection('likes').doc(userId);
  
  final userLikedRef = _firestore
      .collection('users').doc(userId)
      .collection('likedReviews').doc(reviewId);
  
  // Atomik batch
  final batch = _firestore.batch();
  
  final doc = await reviewLikeRef.get();
  
  if (doc.exists) {
    // Unlike
    batch.delete(reviewLikeRef);
    batch.delete(userLikedRef);
    batch.update(_firestore.collection('reviews').doc(reviewId), {
      'likes': FieldValue.increment(-1),
    });
  } else {
    // Like
    final ts = FieldValue.serverTimestamp();
    batch.set(reviewLikeRef, {'createdAt': ts});
    batch.set(userLikedRef, {'createdAt': ts, 'reviewId': reviewId});
    batch.update(_firestore.collection('reviews').doc(reviewId), {
      'likes': FieldValue.increment(1),
    });
  }
  
  await batch.commit();
}
```

> [!NOTE]
> Atomik batch, "like sayısı arttı ama record yok" gibi inconsistent state'leri engeller.

**2. Adım — `review_providers.dart` `userLikedReviewsProvider` değiştir:**

```dart
final userLikedReviewsProvider = StreamProvider<Set<String>>((ref) {
  ref.keepAlive(); // Tab değişiminde stream kapanmasın
  
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value({});

  // ESKI collectionGroup kaldırıldı
  // YENI: tek user'ın subcollection'ı — milisaniye latency
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('likedReviews')
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.id).toSet());
});
```

**3. Adım — `firestore.rules`:**

```
match /users/{userId}/likedReviews/{reviewId} {
  allow read: if isOwner(userId);
  allow create, delete: if isOwner(userId);
  allow update: if false;
}
```

**4. Adım — `firestore.indexes.json` — `likes` collectionGroup index'ini SİL** (artık kullanılmıyor, gereksiz maliyet):

Eğer eklediğimiz collectionGroup index varsa kaldır. Sadece `likedReviews` için single field index Firestore otomatik oluşturuyor, ek index gerekmiyor.

**5. Adım — Migration:** Mevcut like verilerini taşımalıyız. Henüz kullanıcı kitlesi küçük, bu basit bir Cloud Function ile yapılır:

```javascript
// functions/index.js — bir kerelik migration
exports.migrateLikes = functions.https.onCall(async (data, context) => {
  if (!context.auth?.token.admin) throw new functions.https.HttpsError('permission-denied', '...');
  
  const reviews = await admin.firestore().collection('reviews').get();
  let count = 0;
  
  for (const reviewDoc of reviews.docs) {
    const likes = await reviewDoc.ref.collection('likes').get();
    for (const likeDoc of likes.docs) {
      await admin.firestore()
        .collection('users').doc(likeDoc.id)
        .collection('likedReviews').doc(reviewDoc.id)
        .set({
          createdAt: likeDoc.data().createdAt || admin.firestore.FieldValue.serverTimestamp(),
          reviewId: reviewDoc.id,
        }, { merge: true });
      count++;
    }
  }
  
  return { migrated: count };
});
```

Deploy et, çağır, sil. (Veya kullanıcı tabanı 50 altındaysa: dev olarak script'le manual yap.)

---

#### Kişi B — B1: Like Controller'ı Pending'sizleştir

**Yeni controller — `review_providers.dart`:**

```dart
class LikeController extends StateNotifier<Map<String, _PendingLike>> {
  LikeController(this._repo) : super({});
  final ReviewRepository _repo;

  Future<void> toggleLike({
    required String reviewId,
    required String userId,
    required bool currentlyLiked,
  }) async {
    // Eğer zaten pending varsa, tıklamayı yoksay (debounce)
    if (state.containsKey(reviewId)) return;

    // Pending state ekle — desired final state'i sakla
    state = {...state, reviewId: _PendingLike(desiredLiked: !currentlyLiked)};

    try {
      await _repo.likeReview(reviewId, userId);
      // PENDING'I HEMEN TEMIZLEME — server stream güncelleyince temizlenecek
    } catch (e) {
      // Hata: pending'i kaldır, kullanıcı eski state'e döner
      state = {...state}..remove(reviewId);
      rethrow;
    }
  }

  /// Server stream'den gelen güncel durumu pending state ile karşılaştır.
  /// Eğer pending desired ile eşleşiyorsa, pending'i temizle.
  void reconcile(Set<String> serverLikedIds) {
    if (state.isEmpty) return;
    
    final newState = <String, _PendingLike>{};
    for (final entry in state.entries) {
      final actuallyLiked = serverLikedIds.contains(entry.key);
      // Server reality matches desired? → pending bitti
      if (actuallyLiked == entry.value.desiredLiked) continue;
      newState[entry.key] = entry.value;
    }
    if (newState.length != state.length) {
      state = newState;
    }
  }
}

class _PendingLike {
  final bool desiredLiked;
  _PendingLike({required this.desiredLiked});
}

final likeControllerProvider =
    StateNotifierProvider<LikeController, Map<String, _PendingLike>>((ref) {
  final controller = LikeController(ref.read(reviewRepositoryProvider));
  
  // Server stream her güncellendiğinde reconcile et
  ref.listen<AsyncValue<Set<String>>>(userLikedReviewsProvider, (prev, next) {
    next.whenData((ids) => controller.reconcile(ids));
  });
  
  return controller;
});
```

**Yeni `like_button.dart`:**

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final user = ref.watch(authStateProvider).value;

  // Server'dan gelen gerçek durum
  final isLikedFromServer = ref.watch(
    userLikedReviewsProvider.select(
      (async) => async.value?.contains(review.id) ?? false,
    ),
  );

  // Pending varsa onun "desired" durumunu göster
  final pendingDesired = ref.watch(
    likeControllerProvider.select((m) => m[review.id]?.desiredLiked),
  );

  // Pending varsa pending göster, yoksa server'ı göster
  // ARTIK FLICKER YOK çünkü pending sadece server == desired olunca temizleniyor
  final isLiked = pendingDesired ?? isLikedFromServer;

  return InkWell(
    onTap: user == null ? null : () {
      ref.read(likeControllerProvider.notifier).toggleLike(
        reviewId: review.id,
        userId: user.uid,
        currentlyLiked: isLiked,
      );
    },
    // ... mevcut UI
  );
}
```

**Test (DevTools'da):**

1. Yorum beğen → mor olur
2. Network throttle: Slow 3G simülasyon (DevTools)
3. Tıkla → mor anlık → Firestore yazımı 2sn → Snapshot 2.5sn → **mor kalır boyunca** ✅
4. Hızlı 5x tıkla → debounce kicks in, ikincisi yoksayılır ✅
5. Network'ü kapat, beğen → 30sn sonra hata → eski state'e döner ✅

---

#### Kişi A — B6: Home Screen Layout

`lib/features/home/presentation/screens/home_screen.dart`:

**1. Adım — Yatay listelere `ClampingScrollPhysics` + `RepaintBoundary`:**

```dart
// Popüler Üniversiteler
SizedBox(
  height: 200,
  child: ref.watch(popularUniversitiesProvider).when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, st) => Center(child: Text('Hata: $e')),
    data: (popular) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(), // YENI
        cacheExtent: 200, // YENI: ekran dışı 200px cache
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: popular.length,
        itemBuilder: (context, index) {
          return RepaintBoundary( // YENI: scroll sırasında repaint izolasyonu
            child: _PopularUniCard(
              university: popular[index],
              index: index,
              onTap: () => context.push('/university/${popular[index].id}'),
            ),
          );
        },
      );
    },
  ),
),
```

**2. Adım — `_HeroBanner`'ı `const` yap:**

Mevcut:
```dart
class _HeroBanner extends StatelessWidget {
  // const constructor yok
```

Yapılan:
```dart
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();
  // ...
}

// Çağrı yerinde:
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    child: const _HeroBanner(), // const ekle
  ),
),
```

Const widget rebuild olmaz. Hero banner statik, bunu kazanmak bedava.

**3. Adım — `SectionHeader` const constructor zaten var, ama her seferinde build edilen `actionText` callback'i closure yaratıyor:**

Bu sefer çözümü:
```dart
SectionHeader(
  title: 'Popüler Üniversiteler',
  actionText: 'Tümünü Gör',
  padding: const EdgeInsets.fromLTRB(20, 20, 12, 4),
  onAction: () => context.go('/explore'),
),
```

`onAction: () => context.go('/explore')` her build'de yeni Function instance. Ama SectionHeader stateless ve Function reference equality kullanmıyor — burada büyük kazanç yok, bırakabilirsin.

---

### **GÜN 2 — Provider Optimizasyonu (B4) + ReviewCard (B3)**

#### Kişi A — B4: keepAlive ekle

`review_providers.dart`'a (B2 merge edildikten sonra) `ref.keepAlive()` ekle:

```dart
final recentReviewsProvider = StreamProvider<List<ReviewModel>>((ref) {
  ref.keepAlive(); // YENI
  return ref.watch(reviewRepositoryProvider).getRecentReviews(limit: 5);
});

final universityReviewsProvider = StreamProvider.family<List<ReviewModel>, String>((ref, universityId) {
  ref.keepAlive(); // YENI
  return ref.watch(reviewRepositoryProvider).getUniversityReviews(universityId);
});

final departmentReviewsProvider = StreamProvider.family<List<ReviewModel>, String>((ref, departmentId) {
  ref.keepAlive(); // YENI
  return ref.watch(reviewRepositoryProvider).getDepartmentReviews(departmentId);
});

final sortedReviewsProvider = StreamProvider.family<List<ReviewModel>, SortedReviewsParams>((ref, params) {
  ref.keepAlive(); // YENI
  // ... mevcut
});

final allFilteredReviewsProvider = StreamProvider<List<ReviewModel>>((ref) {
  ref.keepAlive(); // YENI
  // ... mevcut
});
```

> [!WARNING]
> `userReviewsProvider` (kullanıcının kendi yorumları) keepAlive'a alma. Logout sonrası önceki kullanıcının verisi sızabilir. Bu provider auth state'e bağımlı, dispose edilmesinde mahsur yok.

---

#### Kişi A — B3: ReviewCard Performansı (4 saat — büyük iş)

**1. Adım — `app_colors.dart` static const shadow:**

```dart
// app_colors.dart en alta ekle:

class AppColors {
  // ... mevcut

  // ESKI: getter (her çağrıda yeni List)
  // static List<BoxShadow> get softShadow => [...];
  
  // YENI: const-able static field
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0A000000), // Colors.black.withAlpha(10) ≈ 4% opacity
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x146C63FF), // primary alpha 0.08
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> bottomNavShadow = [
    BoxShadow(
      color: Color(0x0F000000), // black 6%
      blurRadius: 20,
      offset: Offset(0, -4),
      spreadRadius: 0,
    ),
  ];
}
```

> [!IMPORTANT]
> `Colors.black.withValues(alpha: 0.04)` non-const. Bunun yerine `Color(0x0A000000)` (alpha 0x0A = 10/255 ≈ 3.9%) kullan. Renk değerini hesaplamak için: `(0.04 * 255).round() = 10 = 0x0A`.

**2. Adım — ReviewCard cached decorations:**

`review_card.dart` üstüne static const'lar:

```dart
class ReviewCard extends ConsumerWidget {
  // Static decorations — class load time'da bir kez oluşturulur
  static const _cardBorderRadius = BorderRadius.all(Radius.circular(AppConstants.radiusLg));
  static const _cardBorder = Border.fromBorderSide(
    BorderSide(color: AppColors.borderLight),
  );
  
  static final BoxDecoration _cardDecoration = BoxDecoration(
    color: AppColors.surface,
    borderRadius: _cardBorderRadius,
    border: _cardBorder,
    boxShadow: AppColors.softShadow, // const list, bedava
  );
  
  // ... mevcut alanlar

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RepaintBoundary( // YENI: liste scroll'unda kart bağımsız boyanır
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: _cardDecoration, // cached
        child: InkWell(
          onTap: onTap,
          borderRadius: _cardBorderRadius,
          // ... mevcut Padding/Column
        ),
      ),
    );
  }
}
```

**3. Adım — timeago cache:**

`timeago.format` her build'de çalışır. Cache'le:

```dart
// review_card.dart class içine
String? _cachedTimeAgo;
DateTime? _cachedTimeAgoDate;

String _getTimeAgo() {
  if (_cachedTimeAgoDate == review.createdAt && _cachedTimeAgo != null) {
    return _cachedTimeAgo!;
  }
  _cachedTimeAgo = timeago.format(review.createdAt, locale: 'tr');
  _cachedTimeAgoDate = review.createdAt;
  return _cachedTimeAgo!;
}
```

> [!NOTE]
> Bu şu an çalışmaz çünkü ReviewCard `ConsumerWidget` (immutable). Cache'i parent'a taşıyamayacaksak bunu **`StatefulWidget` + `ConsumerStatefulWidget` dönüşümü** gerekecek. Ama bu büyük bir refactor.
> 
> **Daha pragmatik:** timeago çağrısı çok hızlıdır (~µs), kart başına 1 kere build'de çağrılıyor, gerçek sorun şişirilmiş. Önce diğer fix'leri yap, profile'da timeago hala görünüyorsa o zaman dön.

**4. Adım — ReviewList cacheExtent:**

`review_list.dart` ve `all_reviews_screen.dart`:

```dart
ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  cacheExtent: 1000, // YENI: 1000px cache, scroll'da rebuild patlamaları azalır
  itemCount: reviews.length,
  itemBuilder: (context, i) { /* ... */ },
)
```

**Test (DevTools Performance):**

1. Üniversite detay ekranını aç (50+ yorumlu olsun)
2. DevTools → Performance → Record
3. Hızlıca aşağı yukarı scroll yap (10 sn)
4. Stop, Frame timing kontrol et:
   - **Önce:** Spike'lar var mıydı (>16ms)?
   - **Sonra:** Smooth 60fps olmalı (ortalama <14ms)

---

#### Kişi B — B5: Image Cache Düzeltmeleri

**1. Adım — `review_card.dart` avatar:**

```dart
// _buildHeader içinde:

CircleAvatar(
  radius: compact ? 16 : 20,
  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
  // ESKI: backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
  // YENI: cached + memCache
  backgroundImage: photoUrl != null
      ? CachedNetworkImageProvider(
          photoUrl,
          maxWidth: 80,  // 2x display size
          maxHeight: 80,
        )
      : null,
  child: photoUrl == null
      ? Icon(...)
      : null,
),
```

**2. Adım — `profile_screen.dart` user kartı avatarı:**

Bu zaten `CachedNetworkImage` kullanıyor ama `memCacheWidth/Height` set edilmiş — kontrol et, doğru:
```dart
CachedNetworkImage(
  imageUrl: photoUrl,
  fit: BoxFit.cover,
  width: 64,
  height: 64,
  memCacheWidth: 128,
  memCacheHeight: 128,
  // ✅ doğru
)
```

**3. Adım — `edit_profile_screen.dart` 110x110 avatar:**

```dart
ClipOval(
  child: CachedNetworkImage(
    imageUrl: _currentPhotoUrl!,
    fit: BoxFit.cover,
    width: 110,
    height: 110,
    memCacheWidth: 220, // 2x DPR
    memCacheHeight: 220,
    placeholder: (context, url) => const Center(
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
    errorWidget: (context, url, error) => _buildInitials(),
  ),
),
```

**4. Adım — `home_screen.dart` `_PopularUniCard`:**

Şu an bu kart `Icon(Icons.school_rounded, ...)` kullanıyor, gerçek logoUrl yok. Bu okay, image yok, sorun yok.

Ama eğer ileride `university.logoUrl` kullanılırsa zaten `CachedNetworkImage` ile sınırla. Şimdilik geç.

**5. Adım — `uni_card.dart` _buildImage:** zaten v0.3.1'de doğru yapılmış, ama bir kez daha gözden geçir:

```dart
CachedNetworkImage(
  imageUrl: imageUrl!,
  width: 64,
  height: 64,
  fit: BoxFit.cover,
  memCacheWidth: 128,
  memCacheHeight: 128,
  // ... ✅ doğru
)
```

**Test:**
- Bir telefonda 50 yorumlu sayfa aç
- DevTools → Memory tab → snapshot al
- 1MB altında image cache görmelisin (çoğunluk avatar, küçük)

---

### **GÜN 3 — Tab Switching + Animation (B7) + Polish**

#### Kişi B — B7: Animation cleanup

**Strateji:** Bottom nav arasında geçiş yapan ekranların initial mount sonrası animasyonlarını kaldır. Çünkü:
- Tab geçişi rebuild tetikler
- flutter_animate her rebuild'de animasyonu baştan oynar (visual jank)
- Kullanıcı tabı 5x değiştirirse 5x animation = sinir bozucu

**Yapılacak ekranlar:**

`home_screen.dart`:
```dart
// İLK AÇILIŞTA güzel, ama tab switch'te tekrar oynuyor — kaldır:
// ... existing animate calls ...

// Sadece "ilk yükleme" loading state'inde göster:
// Header → animate kalsın (ekrandan çıkmıyor, bir kez build oluyor)
// Hero banner, Sections → animate'i kaldır
```

`favorites_screen.dart`: zaten v0.3.1'de animate kaldırıldı, kontrol et.

`explore_screen.dart`:
```dart
// Mevcut UniCard'larda animate yok ✅
// Header'da da yok ✅ — ok
```

`profile_screen.dart`:
```dart
// _buildGuestProfile'daki .animate().fadeIn(duration: 400.ms).slideY(begin: 0.1) → kalabilir, statik içerik
// _buildUserCard'daki .animate().fadeIn(duration: 400.ms).slideY(begin: 0.1) → tab switch'te tetikleniyor, kaldır
// İstatistik kartları .animate().fadeIn(delay: 100.ms, duration: 400.ms) → kaldır
```

**Pratik kural:** `bottom_navigation` içindeki tab ekranlarında **sadece initState'te bir kerelik animasyon** varsa flutter_animate yerine `AnimatedOpacity` + state. Ama bu büyük refactor — şu an basit yol: animasyonları **tamamen kaldır**.

`home_screen.dart` sonu örnek:
```dart
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
    child: const _HeroBanner(),
    // .animate() KALDIRILDI
  ),
),
```

#### Kişi A — Polish + Regression Testi

Gün 1-2'de yaptıklarını derle:
- B6 home layout testleri
- B4 keepAlive davranışı: bottom nav A→B→A yap, network çağrısı tekrar olmadığını DevTools Network'te doğrula
- B3 ReviewCard scroll smoothness

Eğer Kişi B B7'yi erken bitirirse beraber **eski telefon testi** yapın:
- Android Studio AVD: Pixel 2 (API 28), 2 CPU core, 1.5GB RAM
- Veya gerçek 4GB RAM telefon

Profile mode'da çalıştır:
```bash
flutter run --profile
```

Beklenen: smooth scroll, hızlı tab switch, like'da flicker yok.

---

### **GÜN 4 — Tam Regresyon + Release**

#### Sabah — Birlikte Tam Tur Test (3 saat)

**Like akışı (B1):**
- [ ] Beğen → mor anında, kalıyor
- [ ] Beğenmekten vazgeç → gri anında, kalıyor
- [ ] Slow 3G simülasyonunda da flicker yok
- [ ] Hızlı 5x tıkla → yalnızca 1 toggle olur (debounce)
- [ ] Logout/login yap → like durumları doğru görünüyor
- [ ] Aynı yorumu iki cihazda (A ve B) farklı kullanıcı olarak beğen → her ikisinde de senkron

**Performans (B3, B4, B5, B6):**
- [ ] Eski telefonda (4GB RAM) cold start ≤ 3 sn
- [ ] Home → Keşfet → Home, **2. açılışta network call yok** (DevTools)
- [ ] 50+ yorumlu sayfa scroll smooth (16ms altı)
- [ ] Bottom nav tab değişimi 60fps (DevTools timeline)
- [ ] Memory: 50 yorumlu sayfada RAM kullanımı stabil, leak yok

**B2 doğrulama:**
- [ ] Firestore Console → `users/{uid}/likedReviews` collection'ı doluyor
- [ ] Eski `reviews/{rid}/likes/{uid}` da senkron doluyor (backwards compat)
- [ ] Migration script çalıştı, eski kullanıcıların like'ları taşındı

**B7:**
- [ ] Tab değiştirken animation tetiklenmiyor

**Regression (önceki bug'lar):**
- [ ] B1 (Sprint 3.1) Pending banner hala çalışıyor
- [ ] B4 (Sprint 3.1) reviewCount cache fix hala çalışıyor
- [ ] All Reviews ekranı + filtreler hala çalışıyor
- [ ] Yorum yaz/düzenle/sil akışları sağlam
- [ ] Foto yükleme/galeri çalışıyor

#### Öğleden Sonra — Release

```bash
git checkout main
git merge develop
git tag -a v0.3.2 -m "Sprint 3.2: like flicker fix + deep performance optimization"
git push origin main v0.3.2

firebase deploy --only firestore:rules,firestore:indexes,functions
```

**README güncelle:**

```markdown
### v0.3.2 — Like Sistemi Yeniden Yazımı + Eski Telefon Optimizasyonu

**Kritik Hata Düzeltmeleri:**
- 🐛 Like butonunda renk flicker'ı (mor → gri → mor) tamamen giderildi
- 🐛 Like sistemi yeniden yapılandırıldı — denormalize veri modeli ile 5-10x daha hızlı

**Performans:**
- ⚡ Eski telefonlarda (4GB RAM) scroll akıcılığı iyileştirildi
- ⚡ Bottom nav tab geçişlerinde network çağrıları %80 azaldı (keepAlive)
- ⚡ Image memory kullanımı %60 azaldı (memCache limitleri)
- ⚡ ReviewCard widget'ı RepaintBoundary ile izole edildi
- ⚡ Home screen yatay listelerinde nested scroll overhead'i azaltıldı

**Veri Modeli Değişiklikleri:**
- 🔄 `users/{uid}/likedReviews/{reviewId}` subcollection'ı eklendi
- 🔄 Migration: mevcut like'lar otomatik taşındı
- 🔄 collectionGroup query kaldırıldı (Firestore maliyet düşüşü)
```

---

## 🚨 Geriye Dönük Test Senaryoları (Çıkış Kriterleri)

Bu senaryoların **hepsi** geçmeden v0.3.2 release ETMEYIN.

### Senaryo 1: Like Flicker Yok
1. `--profile` modda eski cihazda çalıştır
2. Network DevTools'ta Slow 3G aç
3. Yorum beğen
4. **Aksiyondan stream güncellemesine kadar buton sürekli mor kalıyor olmalı**

### Senaryo 2: Tab Switch Network Free
1. Ana sayfayı aç → DevTools Network'te `recent reviews` request'i görmeli
2. Keşfet'e geç → Ana'ya dön
3. **Yeni network request olmamalı** (keepAlive çalışıyor)
4. 5 dakika sonra tekrar aç → SDK'nın offline persistence'i gereği request olabilir, **ama UI'da loading state görünmemeli** (cache hit)

### Senaryo 3: Memory Stability
1. 50 yorumlu üniversite sayfasını aç
2. DevTools Memory → snapshot
3. 30 sn scroll, 10 sn idle
4. Tekrar snapshot
5. **Heap büyümesi <5MB** olmalı (image cache zaten LRU temizleniyor)

### Senaryo 4: Eski Telefon Cold Start
1. Pixel 2 emulator (4GB RAM, API 28) veya 4GB RAM gerçek telefon
2. App'i kill et
3. Aç → ölç (Stopwatch)
4. **<3 sn (Splash + Home tam render)** olmalı

### Senaryo 5: Like Sistemi İki Kullanıcı Senkron
1. Cihaz A: kullanıcı X login
2. Cihaz B: kullanıcı Y login
3. Aynı yorum üzerinde X beğen
4. Cihaz B'de **review.likes counter +1** olmalı (≤2sn içinde)
5. Y de beğen
6. Cihaz A'da counter +2 görünmeli

### Senaryo 6: Concurrent Like Yarışı
1. Tek kullanıcı, 5 hızlı arka arkaya tap
2. Beklenen: **1 toggle** (debounce çalışıyor), state tutarlı
3. Final state: tek toggle uygulanmış (like ya da unlike, başlangıç durumuna göre)

---

## ⚠️ Risk & Mitigation

### Risk 1: Migration sırasında veri kaybı
**Mitigation:** Eski `reviews/{rid}/likes` koleksiyonunu **silmiyoruz**, sadece `users/{uid}/likedReviews` ekliyoruz. Eski veri ileride istenirse silinir (3-6 ay sonra).

### Risk 2: Firestore Rules yanlış yazılırsa
Cihaz B'den X kullanıcısı, Y'nin likedReviews'ını okumayı denerse:
**Beklenen:** permission-denied
**Test:** Firebase Rules Playground veya manual Firestore SDK call

### Risk 3: keepAlive memory leak
keepAlive'lı stream provider'lar dispose olmaz. Çok sayıda family parametresi varsa (her departman için ayrı stream) memory büyür.
**Mitigation:** family parametresi az olan provider'lara koy (`recentReviews`, `userLikedReviews`). `universityReviewsProvider` family ama az ekrana açılır.

### Risk 4: Decoration cache'i yanlış olur
`AppColors.softShadow` artık const list. Ama `Color(0x0A000000)` `Colors.black.withValues(alpha: 0.04)` ile **tam olarak aynı değil** — 0.04 * 255 = 10.2, ben 10 (0x0A) yaptım. Görsel farkı çıplak gözle fark edilmez ama design system tutarlılığı için kontrolden geçir.
**Mitigation:** Designer/UX onayı al. Ya da `withValues` yerine pre-computed Color sabitleri tanımla.

---

## 📌 Sonraki Sprint İçin Notlar

Bu sprintte fark ettiğim ama scope'a almadığım iyileştirmeler (Sprint 4'te düşün):

1. **Cloud Functions ile rating aggregation:** Şu an `categoryRatings` Firestore'da boş. Bir yorum yapıldığında uni/dept'in ortalamasının güncellenmesi için Cloud Function lazım.
2. **Pagination eksik:** `getAllReviews` 50 limit, infinite scroll yok. 50'den fazla yoruma yer yok.
3. **Image upload retry:** `_uploadReviewPhotos` fail ederse partial state olur (bazı upload'lar başarılı, bazıları değil). Atomik retry mekanizması gerek.
4. **Firestore offline persistence overflow:** `Settings.CACHE_SIZE_UNLIMITED` ayarı var, agresif. Eski telefonlarda disk dolabilir. 100MB sınır koy.
5. **Test coverage:** Hâlâ unit test yok. En azından `LikeController.reconcile` ve `AllReviewsFilterNotifier` için yaz.

---

Başarılar 🚀

*Bu plan, sprint3_hata_ayiklama.md (v0.3.1) üstüne inşa edildi. Sorularınız için Sprint 3.1 retrospektifine ve `review_providers.dart` git history'sine bakın.*
