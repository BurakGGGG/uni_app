# 🐛 Sprint 4 — Hata Ayıklama Raporu (v0.4.1)

> **Durum:** Sprint 4 tamamlandı, beta test sırasında 40+ bug tespit edildi
> **Hedef:** v0.4.1 hotfix sürümünde tüm P0/P1 bug'larını kapatmak, Sprint 5'e temiz geçmek
> **Tahmini Süre:** 4-5 iş günü (kişi başı)
> **Sürüm Numaraları:** v0.4.0 (mevcut) → v0.4.1 (hotfix)

---

## 📑 İçindekiler

1. [Yönetici Özeti](#-yönetici-özeti)
2. [Bug Severity Skalası](#-bug-severity-skalası)
3. [P0 — Kritik Buglar (Production Blocker)](#-p0--kritik-buglar)
4. [P1 — Önemli Buglar (Functional)](#-p1--önemli-buglar)
5. [P2 — UX/UI Polish](#-p2--uxui-polish)
6. [P3 — Nice-to-Have / Sprint 5'e Devir](#-p3--nice-to-have--sprint-5e-devir)
7. [Çözüm Sırası — 4 Günlük Hotfix Planı](#-çözüm-sırası--4-günlük-hotfix-planı)
8. [Regresyon Test Listesi](#-regresyon-test-listesi)

---

## 📊 Yönetici Özeti

Sprint 4 testlerinde toplam **47 sorun** tespit edildi. Bunların:

| Kategori | Adet | Tahmini Süre |
|----------|------|--------------|
| 🔴 P0 — Kritik (production-blocker) | 8 | 1.5 gün |
| 🟠 P1 — Önemli (kullanıcıyı engelleyen) | 16 | 1.5 gün |
| 🟡 P2 — UX/UI polish | 14 | 1 gün |
| 🟢 P3 — Sprint 5'e devir | 9 | — |

### En kritik 3 bulgu

1. **Mekan filter sistemi tamamen ölü** — `PlaceFilterSheet` filtreleri `placeFilterProvider`'a yazıyor ama `PlaceList` widget'ı bu provider'ı dinlemiyor. Day 5'in en büyük feature'ı UI'da çalışmıyor.
2. **Department rating agregasyonu yok** — Bölüm yorumları yazılıyor ama `avgRating`/`reviewCount`/`categoryRatings` güncellenmiyor. Bölüm detayında "Henüz yeterli yorum yok" görünmesinin sebebi bu.
3. **FCM bildirimleri çalışmıyor** — Kullanıcı zaten bir composite index ekleyip bazı bildirimleri çözmüş, ama `onReviewLiked` ve `onNewReviewForFavorite` hâlâ tetiklemiyor; index hatası dışında trigger logic'inde de problem var.

---

## 🎚️ Bug Severity Skalası

- **P0 (Kritik):** Sürümün store'a çıkmasını engeller. Veri kaybı, crash, ana feature ölü.
- **P1 (Önemli):** Feature çalışıyor ama kullanıcıyı engelliyor veya yanlış bilgi gösteriyor.
- **P2 (Polish):** UI tutarsızlık, küçük UX sürtünmesi, edge case.
- **P3 (Nice-to-have):** İyileştirme, uzun vadeli — Sprint 5'e devredilebilir.

---

## 🔴 P0 — Kritik Buglar

### P0-1: Mekan filter sistemi UI'da bağlı değil

**Belirti:** Kullanıcı: *"hayır filtre çalışmıyor — birden fazla filtre kombinasyonu (Kafe + ₺ + WiFi) çalışmıyor"*. Filter sheet'te seçim yapılıyor, "Filtreleri Uygula" basılıyor, sheet kapanıyor — ama liste değişmiyor.

**Kök Sebep:**
`lib/features/places/presentation/widgets/place_list.dart` doğrudan `placesByUniversityProvider`'ı izliyor:
```dart
// MEVCUT — YANLIŞ
final placesAsync = ref.watch(placesByUniversityProvider(widget.universityId));
```
Oysa `lib/features/places/presentation/providers/place_filter_provider.dart` içinde özellikle bu iş için yazılmış `filteredPlacesProvider` var ama hiçbir yerden çağrılmıyor. Filter sheet ise state'i `placeFilterProvider`'a yazıyor — yani veri akışı yarıda kesik.

Ek olarak `_PlacesTab` (`university_detail_screen.dart`) içindeki tip filter chip'leri (Tümü/Kafe/Yurt/Kütüphane) `_PlaceListState._selectedType` lokal state'ini kullanıyor; bu da filter sheet'inkiyle sync değil. İki ayrı filter mekanizması paralel çalışıyor.

**Çözüm:**
1. `PlaceList` widget'ını `filteredPlacesProvider` izlemeye çevir; lokal `_selectedType` state'ini kaldır, type chip'leri de `placeFilterProvider.notifier.toggleType()` çağırsın. Tek source of truth.
2. `_PlacesTab` içinde `placeFilterProvider(universityId)` watch edilirken filter sheet'teki "Sıfırla" butonu hem chip'leri hem sheet seçimlerini birlikte sıfırlasın.
3. `place_filter_sheet.dart`'taki "Filtreleri Uygula" butonu zaten reactive update yaptığı için sadece pop yeterli — ama empty state mesajı filter sayısına göre değişmeli ("3 filtreyle eşleşen mekan yok, filtreleri gevşetmeyi deneyin").

**Etkilenen Dosyalar:**
- `lib/features/places/presentation/widgets/place_list.dart` (tam yeniden yazım)
- `lib/features/places/presentation/screens/place_filter_sheet.dart` (apply mesajı)
- `lib/features/university/presentation/screens/university_detail_screen.dart` (`_PlacesTab` küçük)

**Kabul Kriteri:** Sheet'te "Kafe + ₺ + WiFi" seç → liste anında 3 filtre AND'lenmiş şekilde filtrelenir; filter ikonunda mavi nokta görünür; üst chip'ler de sync olur.

---

### P0-2: Department rating agregasyon Cloud Function'ı yok

**Belirti:** Kullanıcı: *"bölüm detayında yorum olmasına rağmen 'henüz değerlendirme yok' diyor"*.

**Kök Sebep:**
`functions/src/` altında üniversite ve mekan için aggregate CF'leri var ama bölüm için yok. `DepartmentModel`'in `avgRating`, `reviewCount`, `categoryRatings` alanları var; `CategoryRatingsChart` widget'ı bu alanlardan render ediyor; ama bunlara hiç değer yazılmıyor. `getDepartmentReviews` çalışıyor (yani yorum listesi gelir) ama agregat boş kalır.

`category_ratings_chart.dart`'taki:
```dart
if (ratings.isEmpty || reviewCount == 0) {
  return _buildEmptyState();  // "Henüz yeterli değerlendirme yok"
}
```
Yorumlar gerçekten var ama `reviewCount` 0 olduğu için empty state çıkıyor.

**Çözüm:**
1. `functions/src/aggregations/aggregate_department_ratings.ts` oluştur. `reviews/{reviewId}` `onWrite` trigger'ı, eğer `type == 'department'` ise `targetId` üzerinden departments/{deptId} dokümanına ortalama yazsın.
2. Aynı pattern `aggregate_university_ratings`'tekiyle bire bir aynı; sadece `type` filter ve target collection değişir.
3. Mevcut bölüm yorumları için tek seferlik backfill script'i çalıştırılmalı (Firebase Console → Functions → manuel invoke veya yerel admin script).

```ts
// functions/src/aggregations/aggregate_department_ratings.ts (taslak)
export const aggregateDepartmentRatings = onDocumentWritten(
  'reviews/{reviewId}',
  async (event) => {
    const after = event.data?.after.data();
    const before = event.data?.before.data();
    const review = after ?? before;
    if (!review || review.type !== 'department') return;
    if (!review.isApproved) return;

    const deptId = review.targetId;
    const reviewsSnap = await db.collection('reviews')
      .where('targetId', '==', deptId)
      .where('type', '==', 'department')
      .where('isApproved', '==', true)
      .get();

    // ... avg + categoryRatings hesapla ve departments/{deptId}'ye yaz
  }
);
```

**Kabul Kriteri:** Bir bölüme test yorumu yaz → 5 sn içinde bölüm detay header'ında avgRating + kategori chart dolar.

---

### P0-3: Logout sonrası ProfileScreen'de kalıyor

**Belirti:** Kullanıcı: *"logout sonrası sign in ekranı değil profil ekranında kaldım"*.

**Kök Sebep:**
`app_router.dart`'taki redirect logic'inde profil sayfası protected route listesine alınmamış. Profile, login değilken `_buildGuestProfile()` (Hoş Geldin kartı) gösterdiği için "guest-friendly" bir route. Ancak kullanıcı **logout** ettiğinde — yani daha önce login'di ve şimdi değil — beklenen davranış login ekranına dönmek. Şu an `auth_state` değişiyor ama route değişmediği için aynı sayfada kalıyor.

`profile_screen.dart` `signOut` butonunda `signOut` çağrıldıktan sonra hiçbir navigation yok; sadece auth controller state'i değiştiriliyor.

**Çözüm:**
İki opsiyondan biri:

**A) (önerilen) Logout butonunda explicit redirect:**
```dart
if (confirmed == true) {
  await ref.read(authControllerProvider.notifier).signOut();
  if (context.mounted) context.go('/login');
}
```

**B) Router-level: `auth_state` null'a geçince ve mevcut route protected listesinde değilse de bazı durumlarda /login'e yönlendir:**
Bu daha karmaşık ve onboarding'i bozma riski var. A önerilir.

**Etkilenen:** `lib/features/profile/presentation/screens/profile_screen.dart`

**Kabul Kriteri:** Logout → confirmation → login ekranı.

---

### P0-4: FCM "Yorumun Beğenildi" ve "Favori Yeni Yorum" bildirimleri çalışmıyor

**Belirti:** Kullanıcı: *"bildirim sistemi çalışmıyor, beğenide de çalışmıyor, sadece küfürlü yorumda (moderation) çalışıyor"*. Composite index'i kullanıcı manuel ekledi, ama hâlâ çoğu push gelmiyor.

**Kök Sebep (3 katmanlı):**

1. **Index eksikti** — kullanıcı `notifications` koleksiyonu için `data.reviewId + type + userId + createdAt` index'ini eklemiş, bu kısmen çözülmüş. Ama bu index'in `firestore.indexes.json`'a da eklenmesi gerek (yoksa redeploy'da gider).
2. **`notifications` koleksiyonu için Firestore rules `allow create: if false`** — sadece CF (admin) yazabiliyor. Bu doğru. Ama CF `admin.firestore()` ile mi yoksa user context ile mi yazıyor? `functions/src/notifications/*.ts` dosyalarında admin SDK kullanılmalı.
3. **`onReviewLiked` trigger logic'i yanlış olabilir** — yorum sahibi kendine like attığında bildirim gelmesin; başka kullanıcı like attığında gelsin. Bu kontrol eksikse hiç bildirim oluşmuyor olabilir. Kullanıcı tek hesapla test ediyor olabilir.

**Çözüm:**

1. **`firestore.indexes.json`'a eksik index'i ekle:**
   ```json
   {
     "collectionGroup": "notifications",
     "queryScope": "COLLECTION",
     "fields": [
       { "fieldPath": "userId", "order": "ASCENDING" },
       { "fieldPath": "createdAt", "order": "DESCENDING" }
     ]
   }
   ```
   (Mevcut `firestore.indexes.json`'da `notifications` için hiç index yok.)

2. **`functions/src/notifications/on_review_liked.ts`'i baştan denetle:**
   - Likes subcollection'ındaki `onCreate` trigger mı? (review.likes increment doğru ama subcollection ayrı tetiklenmeli)
   - Likes ekleyen `auth.uid != review.userId` kontrolü
   - Throttle: 5 dk içinde aynı yoruma 3+ like → tek toplu bildirim
   - Push payload'da `data: { route: '/all-reviews?reviewId=...' }` veya `/notifications` olmalı (deep link için)
   - User'ın `notificationPrefs.reviewLikedEnabled` kontrolü
   - Tüm `fcmTokens` array'ine multicast send

3. **İki hesapla manuel test:**
   - Hesap A bir yorum yazsın, A'da edu.tr verified olsun
   - Hesap B (farklı edu.tr ya da gmail) o yorumu like'lasın
   - 10 sn bekle → Hesap A'ya hem in-app (notifications koleksiyonunda yeni doc) hem de push gelmeli

**Etkilenen:**
- `firestore.indexes.json` (index ekleme)
- `functions/src/notifications/on_review_liked.ts` (review)
- `functions/src/notifications/on_new_review_for_favorite.ts` (review)

**Kabul Kriteri:** İki hesapla like akışı test edildiğinde push + in-app bildirim < 10 sn içinde geliyor; tek hesapla self-like'ta bildirim YOK.

---

### P0-5: Mekan yorumu sonrası üni ana sayfasındaki rating güncellenmiyor

**Belirti:** Kullanıcı: *"yorum yazdım, mekan detayında rating güncellendi ama üni ana sayfasında güncellenmedi"*.

**Kök Sebep:**
`write_review_screen.dart`'ta `widget.type == ReviewType.place` durumunda:
```dart
ref.read(placeRepositoryProvider).clearCache();
ref.invalidate(placesByUniversityProvider(widget.universityId));
```
Bu `places/{placeId}` koleksiyonundaki güncel veriyi getirmek için yeterli, **ama**: `_PlacesTab` widget'ı `PlaceList` üzerinden `placesByUniversityProvider` watch ediyor. Provider invalidate edilirse tekrar fetch ediliyor — burası doğru.

Sorun, Cloud Function'ın `places/{placeId}` üzerine yazma latency'sinde. CF'nin `aggregatePlaceRatings`'ı tetiklenmesi 5-10 sn sürebilir, ama kullanıcı yorum yazıp hemen geri dönüyor. Kısa vadede yeterli; ama UX olarak optimistic update gerekli:

**Çözüm:**
1. **Optimistic local update** — yorum gönderildiği anda, cache'deki ilgili `PlaceModel`'in `reviewCount`'unu +1 ve `avgRating`'i basit ortalamayla güncelle. CF gerçek değerle override ederse zaten doğrulanır.
2. **Daha basit:** `places_byUniversityProvider`'ı `StreamProvider` yap (mevcut `FutureProvider` yerine) — Firestore snapshot listener ile CF güncellemesi anında client'a gelir. PlaceRepository'de `getPlacesByUniversity` zaten cache'liyor, ama stream variant ekle:
   ```dart
   Stream<List<PlaceModel>> watchPlacesByUniversity(String uniId) {
     return _placesRef
       .where('universityId', isEqualTo: uniId)
       .orderBy('promotionPriority', descending: true)
       .orderBy('avgRating', descending: true)
       .snapshots()
       .map(...)
   }
   ```
3. Stream variant tek başına 509 mekan için maliyetli olabilir — `where('universityId', isEqualTo: uniId)` sayesinde sadece o üni'nin mekanları (max ~30 doc) snapshot olur. Maliyet kabul edilebilir.

**Etkilenen:**
- `lib/features/places/data/place_repository.dart`
- `lib/features/places/presentation/providers/place_providers.dart`
- `lib/features/places/presentation/widgets/place_list.dart`

**Kabul Kriteri:** Mekan yorumu yaz → geri dön → 5 sn içinde mekan kartında rating + reviewCount güncellenmiş.

---

### P0-6: Boğaziçi/Koç/Sabancı/Bilkent/İYTE/Yaşar/Bilgi üniversiteleri "boş üni" gösteriyor

**Belirti:** Kullanıcı: *"içeriği olmayan bazı üniler vardı, boğaziçi koç gibi, bunları kaldıralım"*. Sprint 4 dökümanında bu 7 üni için CSV verisi olmadığı kabul ediliyordu, "Henüz mekan eklenmedi" empty state'i ile bırakılması planlanmıştı. Ancak kullanıcı bu deneyimden memnun değil — bu üniler kullanıcıya bozuk uygulama hissi veriyor.

**İki seçenekli çözüm:**

**A) (önerilen) Üniversiteleri **kalıcı tut**, sadece Mekanlar tab'ında veri yokken UI'ı zenginleştir:**
- Mevcut empty state'in kopyasını "Bu üniversite için mekan verisi henüz toplanıyor — Sprint 5'te eklenecek" şeklinde rewrite et
- Bu üniler için Bölümler tab'ı zaten dolu (10 bölüm seed ediliyor), Yorumlar tab'ı kullanıcı yorumlarına açık. Yani üni "boş" değil, sadece mekanları yok.
- Empty state'e "Mekan ekle" CTA — Sprint 5'te admin onaylı user-submitted mekan feature'ına bağlanabilir

**B) Bu 7 üniyi geçici olarak listeden kaldır:**
- `seed_data_service.dart`'ta `universities` array'inden çıkar
- Risk: Bu uniler için varsa kullanıcı yorumları orphan kalır; yorum yazan kullanıcılar hata görür
- Mevcut kullanıcı verisi varsa migration gerekli

**Önerim:** A seçeneği. Empty state metni daha açıklayıcı yap, "yakında eklenecek" mesajı ver, böylece kullanıcı boş ekran görmesin ama veri kaybı da olmasın.

**Etkilenen:** `lib/features/places/presentation/widgets/place_list.dart` `_PlacesEmptyState` widget'ı.

---

### P0-7: Kayıt şifre kuralı zayıf (6 karakter)

**Belirti:** Kullanıcı: *"şifre kısmını en az 8 karakter yapalım, büyük harf ve sayılar da içermeli"*.

**Kök Sebep:** `register_screen.dart`:
```dart
if (value.length < 6) return 'Şifre en az 6 karakter olmalı';
```
Sadece uzunluk kontrolü, kompleksite yok.

**Çözüm:**
```dart
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Şifre gerekli';
  if (value.length < 8) return 'Şifre en az 8 karakter olmalı';
  if (!RegExp(r'[A-Z]').hasMatch(value)) {
    return 'Şifre en az bir büyük harf içermeli';
  }
  if (!RegExp(r'[0-9]').hasMatch(value)) {
    return 'Şifre en az bir rakam içermeli';
  }
  return null;
}
```

Ek olarak şifre güç göstergesi (Zayıf/Orta/Güçlü) eklenebilir — bu P2.

**Mevcut hesaplar:** Geriye dönük uyumlu — eski 6 karakterli hesaplar login olabilmeli, sadece yeni kayıt + reset password yeni kuralla.

**Etkilenen:** `lib/features/auth/presentation/screens/register_screen.dart`

---

### P0-8: App ismi "uni_app" görünüyor (ÜniSeç olmalı)

**Belirti:** Kullanıcı: *"app ismi ÜniSeç olarak görünmüyor, uni_app olarak gözüküyor"*.

**Kök Sebep:** `lib/firebase_options.dart`'ta `iosBundleId: 'com.example.uniApp'` ve muhtemelen platform-specific manifest'lerde label "uni_app".

**Çözüm:**
1. **Android:** `android/app/src/main/AndroidManifest.xml` → `<application android:label="ÜniSeç" ...>`
2. **iOS:** `ios/Runner/Info.plist` → `<key>CFBundleDisplayName</key><string>ÜniSeç</string>`
3. **Bundle ID:** Eğer henüz store'a yüklenmediyse `com.example.uniApp` → `com.uniseckitap.uniseckitap` (veya seçilen domain) olarak değiştirilmeli — store öncesi son şans, yüklenince değişmez
4. `firebase_options.dart` `iosBundleId` da uyumlu olarak güncellenmeli, Firebase Console → iOS app bundle ID güncellenmeli
5. `pubspec.yaml`: `name: uni_app` → `name: unisec` (paket adı, küçük harf + underscore zorunlu)

**Risk:** Paket adı değişikliği import path'leri etkilemez (paket içindeki tüm import'lar relative değil package: ile, ama `package:uni_app/...` → `package:unisec/...` değişmeli — toplu replace).

---

## 🟠 P1 — Önemli Buglar

### P1-1: PlaceDetailScreen foto galerisi eksik

**Belirti:** *"SliverAppBar foto galerisi yok, çoklu fotoğraf swipe yapılamıyor, fotoya tıklayınca tam ekran açılmıyor"*.

**Kök Sebep:** `place_detail_screen.dart`'ta PageView var ama `onTap` yok ve indicator yok. Ayrıca seed_data'daki çoğu mekan için `imageUrls` boş — bu yüzden `expandedHeight: 0` davranışı.

**Çözüm:**
1. PageView içine `GestureDetector` ile `onTap: () => Navigator.push(MaterialPageRoute(builder: (_) => PhotoGalleryScreen(imageUrls: place.imageUrls, initialIndex: pageIndex)))`. `PhotoGalleryScreen` zaten Sprint 3'te yazılmıştı, `lib/features/reviews/presentation/screens/photo_gallery_screen.dart` — review'a özel ama generic, mekan için de kullanılabilir.
2. PageView altına dot indicator ekle (3+ foto varsa).
3. Seed_data'ya en azından type'a göre placeholder image URL'ler ekle (Unsplash topic-based: `https://source.unsplash.com/featured/?cafe`, `?library`, `?dorm`).

**Etkilenen:**
- `lib/features/places/presentation/screens/place_detail_screen.dart`
- `lib/features/reviews/presentation/screens/photo_gallery_screen.dart` (rename'e gerek yok, genel kullanılabilir)
- `assets/data/places_seed.json` (placeholder image URL'ler) — opsiyonel

---

### P1-2: PlaceDetailScreen description ve openHours boş gösteriliyor

**Belirti:** *"açıklama metni, çalışma saatleri görünüyor mu? hayır"*.

**Kök Sebep:** `_buildInfoSection` boş kontrol yapıyor; CSV import'unda bu alanlar dolduruluyor mu?

**Çözüm:**
1. `assets/data/places_seed.json`'da description ve openHours alanlarının dolu olduğunu doğrula. CSV'deki "Neden Seçmelisin?" alanı `description`'a, kütüphanedeki "Çalışma Saatleri" alanı `openHours`'a map'lenmeli.
2. Eğer CSV import script'i bu alanları yazmıyorsa, parser'ı düzelt — bu Sprint 4'ün build script'i.
3. Ayrıca yurt için "Kontenjan Tipi" + "Kampüse Yakınlık" → description'a concat edilmeli.

**Etkilenen:** Build/import script (muhtemelen ayrı dart script), `places_seed.json`

---

### P1-3: PlaceAmenitiesGrid boş — amenities import edilmedi

**Belirti:** *"PlaceAmenitiesGrid widget WiFi/priz/sessiz ikonlarıyla görünüyor mu? hayır"*.

**Kök Sebep:** Yine seed import'unda amenities array'i boş; CSV'deki bilgilerden derive edilmiyor.

**Çözüm import script'inde:**
- Yurt için `Tür` ("KYK"/"Özel") + `Kontenjan Tipi` ("Kız"/"Erkek"/"Karma") → `amenities: ["KYK", "Kız Yurdu"]`
- Kafe için `Neden Seçmelisin?` metnini parse et: "Wi-Fi", "Sessiz", "7/24" gibi keyword'leri amenity tag'ine çevir
- Kütüphane için `Konfor`, `Sessizlik` alanlarını amenity'ye çevir

Bu işin yapılacak yeri Sprint 4'ün CSV→JSON build script'i; o script'in Sprint 4 sonu çıktısı `places_seed.json` ama amenity'ler eksik kalmış.

---

### P1-4: "Haritada Aç" butonu çoğu mekan için açmıyor

**Belirti:** *"google maps açılmıyor"* — bazıları çalışıyor, bazıları çalışmıyor.

**Kök Sebep:** `_openMap`:
```dart
final query = Uri.encodeComponent('${place.name} ${place.address}');
final url = Uri.parse('https://www.google.com/maps/search/$query');
```
Sadece text query. `place.address` boşsa veya hatalıysa Google Maps başka şehre/mekana götürebilir. `place.location` (GeoPoint) ve `place.mapUrl` field'ları model'de var ama kullanılmıyor.

**Çözüm — fallback chain:**
```dart
Future<void> _openMap(PlaceModel place) async {
  Uri? url;
  // 1. Önce explicit mapUrl varsa onu kullan (CSV'den gelirse)
  if (place.mapUrl != null && place.mapUrl!.isNotEmpty) {
    url = Uri.parse(place.mapUrl!);
  }
  // 2. GeoPoint varsa lat/lng ile aç
  else if (place.location != null) {
    final lat = place.location!.latitude;
    final lng = place.location!.longitude;
    url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
  }
  // 3. Son çare: name + address text search
  else {
    final query = Uri.encodeComponent('${place.name} ${place.address}');
    url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
  }
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    if (mounted) {
      showAppSnackBar(context, message: 'Harita açılamadı', isError: true);
    }
  }
}
```

**Bonus iOS:** iOS'ta Apple Maps tercih ediliyorsa `maps://?q=...` schema ile dene, fallback Google.

**Etkilenen:** `lib/features/places/presentation/screens/place_detail_screen.dart`

---

### P1-5: Yurt detay info kartında "açılış saati" yanlış field

**Belirti:** *"yurt için açılış saati var, bunun yerine giriş çıkış saati olmalı veya bina bilgisi falan"*.

**Kök Sebep:** `_buildInfoSection` tüm tipler için aynı UI'ı render ediyor. Yurt için `openHours` "kafenin saati" gibi anlamsız.

**Çözüm:** Type'a göre koşullu render:
- **Cafe / Library:** `openHours` (mevcut)
- **Dorm:** `openHours` yerine "Giriş-Çıkış saatleri" etiketi, veya hiç gösterme. Onun yerine `dormType` (KYK/Özel) ve `dormGenderType` öne çıksın — ki zaten `DormInfoCard` widget'ı var.
- Studyarea/sports: değişiklik yok

```dart
if (place.openHours != null && place.type != PlaceType.dorm) ...[
  // ... mevcut openHours render
]
```

---

### P1-6: ODTÜ/İTÜ gibi kısaltmalarla arama yapılamıyor

**Belirti:** *"odtü yaz → çıkmıyor, orta doğu teknik üniversitesi olarak çıkıyor"*.

**Kök Sebep:** `university_repository.dart` `searchUniversities` sadece `name.toLowerCase().contains(query)`. Kısaltma yok.

**Çözüm — iki seviyeli:**

**Seviye 1 (hızlı):** `UniversityModel`'e `aliases: List<String>` field'ı ekle. Seed data'ya elle yaz:
```dart
{'id': 'odtu', 'name': 'Orta Doğu Teknik Üniversitesi', 'aliases': ['odtü', 'metu']},
{'id': 'itu', 'name': 'İstanbul Teknik Üniversitesi', 'aliases': ['itü']},
{'id': 'iyte', 'name': 'İzmir Yüksek Teknoloji Enstitüsü', 'aliases': ['iyte']},
{'id': 'comu', 'name': 'Çanakkale Onsekiz Mart Üniversitesi', 'aliases': ['çomü', 'comu']},
{'id': 'ktu', 'name': 'Karadeniz Teknik Üniversitesi', 'aliases': ['ktü']},
{'id': 'ogu', 'name': 'Eskişehir Osmangazi Üniversitesi', 'aliases': ['ogu', 'ögü']},
{'id': 'btu', 'name': 'Bursa Teknik Üniversitesi', 'aliases': ['btü']},
{'id': 'estu', 'name': 'Eskişehir Teknik Üniversitesi', 'aliases': ['estü']},
// ...
```

`searchUniversities`:
```dart
return allUnis.where((uni) {
  final lq = query.toLowerCase().trim();
  if (uni.name.toLowerCase().contains(lq)) return true;
  if (uni.aliases.any((a) => a.toLowerCase().contains(lq))) return true;
  return false;
}).toList();
```

**Seviye 2 (sonra):** Türkçe normalize (ı/i, ş/s, ç/c) — kullanıcı "odtu" yazınca da "odtü"yü matchle. Basit replace map yeterli.

**Etkilenen:**
- `lib/features/university/domain/models/university_model.dart` (aliases field)
- `lib/features/university/data/university_repository.dart` (search logic)
- `lib/scripts/seed_data_service.dart` (seed data + aliases)

---

### P1-7: Şehirler listesi Türkçe alfabetik sıralaması yanlış (Ç, İ, Ş, Ö, Ü sona düşüyor)

**Belirti:** *"türkçe karakter Ç İ liste sonunda, tam sıralama doğru değil"*.

**Kök Sebep:** Firestore `orderBy('name')` UTF-8 byte order kullanır. `Ç` (U+00C7) `Z`'den (U+005A) sonra geldiği için listeyi sona atar.

**Çözüm:** Client-side Türkçe collation. Dart'ta yerleşik bir Türkçe Collator yok, ama basit bir approach:
```dart
// city_model.dart veya helper
int turkishCompare(String a, String b) {
  const order = 'aAbBcCçÇdDeEfFgGğĞhHıIiİjJkKlLmMnNoOöÖpPrRsSşŞtTuUüÜvVyYzZ';
  for (int i = 0; i < a.length && i < b.length; i++) {
    final ai = order.indexOf(a[i]);
    final bi = order.indexOf(b[i]);
    if (ai == -1 || bi == -1) {
      final cmp = a[i].compareTo(b[i]);
      if (cmp != 0) return cmp;
    } else {
      if (ai != bi) return ai - bi;
    }
  }
  return a.length - b.length;
}

// university_repository.dart
final cities = snapshot.docs
  .map((doc) => CityModel.fromMap(doc.data(), doc.id))
  .toList();
cities.sort((a, b) => turkishCompare(a.name, b.name));
return cities;
```

**Etkilenen:**
- `lib/core/utils/turkish_compare.dart` (yeni helper)
- `lib/features/university/data/university_repository.dart` (cities + universities sort)

---

### P1-8: Geri tuşu zinciri bozuk (yorum kartı → bölüm → üni → ana sayfa atlamaları)

**Belirti:** *"son yorumlardan bir bölüme yorum yapılmış, giriyorum, sonra bölüm kartından üniversite ismine basıyorum, ana ekrana atıyor — bu zincir bozuk"*.

**Kök Sebep:** GoRouter'da `push` vs `go` karışık kullanılmış. `home_screen.dart` review kartına tıklayınca `context.push('/department/${review.targetId}')` doğru. Ama `department_detail_screen.dart` içindeki üniversite link'i muhtemelen `context.pop()` çağırıyor; o da doğru ama eğer Department'a `push` ile geldiysek, üniversiteye push yerine pop'la dönmek mantıklı. Sorun: home → department → tap "uni name" → muhtemelen `pop` department'tan çıkıyor ama biz home'a değil university'ye gitmek istiyoruz.

`department_detail_screen.dart`'ta:
```dart
GestureDetector(
  onTap: () => context.pop(),  // ← Bu home'a değil, mevcut stack'e bağlı
  child: ...uni name...
),
```

**Çözüm:**
```dart
onTap: () => context.push('/university/${dept.universityId}'),
```
Bu, stack'e ekler — geri basınca department'a döner, sonra home'a. Doğru zincir.

Ayrıca `_PopularUniCard`, `UniCard`, `ReviewCard` review-tap callback'leri tutarlı şekilde `push` kullanmalı (zaten kullanıyor görünüyor, kontrol edilmeli).

**Etkilenen:**
- `lib/features/university/presentation/screens/department_detail_screen.dart` (uni name tap)

---

### P1-9: Bottom nav alt sekmelerinden geri basınca uygulama kapanıyor

**Belirti:** *"bottom nav alt sekmelerinden geri basınca app kapanıyor — bu olmamalı, ana sayfaya gitmeli"*.

**Kök Sebep:** `app_shell.dart`'ta `PopScope` veya custom back handler yok. Default Android davranışı: stack boşsa Activity kapanır.

**Çözüm:**
```dart
return PopScope(
  canPop: navigationShell.currentIndex == 0,  // Sadece Home'dayken çıkışa izin ver
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    // Home değilse Home'a dön
    navigationShell.goBranch(0);
  },
  child: Scaffold( ... ),
);
```

**Bonus:** İki kez geri ile çıkış (double-back-to-exit) eklemek istenirse:
```dart
DateTime? _lastBack;
// Home'dayken:
final now = DateTime.now();
if (_lastBack != null && now.difference(_lastBack!) < Duration(seconds: 2)) {
  // exit
} else {
  _lastBack = now;
  showAppSnackBar(context, message: 'Çıkmak için tekrar bas');
}
```

**Etkilenen:** `lib/router/app_shell.dart`

---

### P1-10: Comparison "henüz yeterli yorum yok" banner sadece her iki uni 0 olduğunda gösteriliyor

**Belirti:** *"bu tam çalışmıyor, kontrol et"*.

**Kök Sebep:** `comparison_category_row.dart`:
```dart
if (comparison.valueA == 0 && comparison.valueB == 0) { ... }
```
Sadece her iki üni de 0 ise banner. Ama A=4.5, B=0 durumunda kullanıcıya 4.5 bar + 0 bar gösteriyor; B'nin 0 olması "puanı kötü" değil "hiç yorum yok" anlamına gelir. Bu yanıltıcı.

**Çözüm:** Per-side empty handling. `ComparisonResult` zaten review count'ları biliyor:
```dart
// comparison_category_row.dart
final aHasData = comparison.valueA > 0;
final bHasData = comparison.valueB > 0;

if (!aHasData && !bHasData) {
  // Banner: "Henüz yeterli yorum yok"
} else if (!aHasData) {
  // Sol bar yerine "Yorum yok" placeholder
} else if (!bHasData) {
  // Sağ bar yerine "Yorum yok" placeholder
}
```

**Etkilenen:** `lib/features/comparison/presentation/widgets/comparison_category_row.dart`

---

### P1-11: Hızlı tıklama ile "yorum yaz" butonu hata veriyor (mekan)

**Belirti:** *"hızlıca giriş yapıp mekana yorum yaza basınca hata verdi, ardından bir kez daha tıkladım, düzeldi"*.

**Kök Sebep:** Race condition — login flow tamamlanmadan WriteReviewScreen açılıyor, `currentUser` henüz null. `_submitReview`'da `if (user == null) throw` falan yapıyor.

**Çözüm:**
1. `app_router.dart`'taki `/write-review/:type/:targetId` redirect'inde:
   ```dart
   redirect: (context, state) {
     final userAsync = ProviderScope.containerOf(context).read(currentUserProvider);
     final user = userAsync.valueOrNull;
     if (user == null) { ... }
   }
   ```
   `currentUserProvider` async; `valueOrNull` yetersiz çünkü loading state'de null döner. Loading durumunda redirect false-pozitif login'e gönderir.
   
   Düzeltme:
   ```dart
   if (userAsync.isLoading) return null;  // Bekle, yeniden eval olacak
   if (userAsync.value == null) return '/login?from=...';
   ```
   GoRouter `refreshListenable` (auth stream) sayesinde state değişince redirect re-evaluate edilir.

2. WriteReviewScreen'de defensive: button disabled olsun ta ki `currentUser` resolve olana kadar.

**Etkilenen:**
- `lib/router/app_router.dart`
- `lib/features/reviews/presentation/screens/write_review_screen.dart`

---

### P1-12: Login'den sonra "yorum yazmak için" geldiyse oraya geri dönmüyor, ana sayfaya atıyor

**Belirti:** *"ana sayfaya atıyor, en son neredeysem oraya atsa iyi olur"*.

**Kök Sebep:** Mevcut router redirect'inde `from` query parametresi var ama login_screen'in `_onLoginSuccess`'i kontrol ediyor. Kontrol et:
```dart
// login_screen.dart
final from = GoRouterState.of(context).uri.queryParameters['from'];
if (from != null && from.isNotEmpty) {
  context.go(from);
} else {
  context.go('/');
}
```
Bu doğru görünüyor. Ama redirect'e gönderilirken from doğru kodlanıyor mu? `app_router.dart`:
```dart
final encodedPath = Uri.encodeComponent(state.uri.toString());
return '${AppRoutes.login}?from=$encodedPath';
```
Bu doğru. **Muhtemel sorun:** Yorum yaz butonu `/write-review/place/<id>?uni=<uniId>&pt=cafe` route'una push ediyor ama redirect tetiklendiğinde `state.uri.toString()` query string'leri içeriyor. encode/decode iki kere oluyor olabilir.

**Çözüm — debug yöntemi:**
- `_onLoginSuccess`'te log ekle: `print('LOGIN SUCCESS, going to: $from');`
- Eğer `from` boşsa, redirect tarafında bug var
- Eğer `from` doluysa ama `context.go(from)` ana sayfaya gidiyor → GoRouter'ın query parsing hatası olabilir; `Uri.decodeComponent(from)` ile manuel decode dene

Ayrıca register screen'de de aynı kontrolü yap (kullanıcı login değilken bir register edebilir).

**Etkilenen:**
- `lib/features/auth/presentation/screens/login_screen.dart`
- `lib/features/auth/presentation/screens/register_screen.dart`

---

### P1-13: Bildirim ayarları ekranında "Sistem ayarlarını aç"tan dönünce status güncellenmiyor

**Belirti:** *"kabul edip geri gelince bildirim ayarlarında hala 'ayarları aç' butonu var, geri çıkıp girince gidiyor — anında gitmeli"*.

**Kök Sebep:** `notification_settings_screen.dart`:
```dart
ElevatedButton(
  onPressed: () => openAppSettings().then((_) => _checkSystemPermission()),
  ...
)
```
`openAppSettings()` `Future<bool>` döner ama bu future user app'ten dönmesini beklemez — sadece ayar ekranını açtığını döner. `then` immediately invoke olur, ama o sırada user hâlâ ayar ekranında.

**Çözüm:** `WidgetsBindingObserver` ile lifecycle:
```dart
class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSystemPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSystemPermission();  // App'a dönünce yeniden kontrol et
    }
  }
}
```
Bu, kullanıcı ayar ekranından döner dönmez status'u günceller.

**Etkilenen:** `lib/features/notifications/presentation/screens/notification_settings_screen.dart`

---

### P1-14: Login değilken NotificationBell tıklanabilir (giriş ekranına yönlendirmeli)

**Belirti:** *"login değilken bell görünüyor, basınca 'giriş yap' falan desin"*.

**Kök Sebep:** `notification_bell.dart`:
```dart
onPressed: () => context.push('/notifications'),
```
Authenticated kontrolü yok. Login değilken bell'e basıp `/notifications` route'una gidiliyor; orada `myNotificationsProvider` boş döner ama beyaz ekran kalır.

**Çözüm:**
```dart
onPressed: () {
  final user = ref.read(authStateProvider).value;
  if (user == null) {
    showAppSnackBar(
      context,
      message: 'Bildirimleri görmek için giriş yapın',
      action: SnackBarAction(
        label: 'Giriş Yap',
        onPressed: () => context.push('/login?from=/notifications'),
      ),
    );
    return;
  }
  context.push('/notifications');
},
```
Aynı mantık `LikeButton` için de geçerli (P1-15).

**Etkilenen:** `lib/features/notifications/presentation/widgets/notification_bell.dart`

---

### P1-15: Login değilken Like butonu hiçbir şey yapmıyor (giriş yap yönlendirmesi)

**Belirti:** *"login değilken beğenmeye de basamasın, basınca login olman gerek desin"*.

**Kök Sebep:** `like_button.dart`:
```dart
onTap: user == null ? null : () { ... }
```
`null` callback = pasif (gri görünüm), tıklanabilir değil. Kullanıcı butonun işlevini anlamıyor.

**Çözüm:**
```dart
onTap: () {
  if (user == null) {
    showAppSnackBar(
      context,
      message: 'Beğenmek için giriş yapın',
      action: SnackBarAction(
        label: 'Giriş',
        onPressed: () => context.push('/login'),
      ),
    );
    return;
  }
  ref.read(likeControllerProvider.notifier).toggleLike(...);
},
```

**Etkilenen:** `lib/features/reviews/presentation/widgets/like_button.dart`

---

### P1-16: Favorilerden silerken confirmation yok ve UI sırıtıyor

**Belirti:** *"favorilerden silerken tekrar mı sorsa kaldırayım mı diye, ve favoriler listesinde kalp ikonu kartın yanında biraz sırıtıyor"*.

**Kök Sebep:** `favorites_screen.dart`'ta `IconButton` `trailing`'e konmuş. `UniCard`'ın native trailing'i ratings için tasarlanmış; kalp button'u `Container` içinde shadow'lu daire olarak konmuş, kart düzeniyle uyumsuz.

**Çözüm:**
1. Confirmation dialog: `_handleRemove`:
   ```dart
   final confirmed = await showDialog<bool>(...AlertDialog(
     title: Text('Favorilerden çıkar?'),
     content: Text('${uni.name} favorilerinden çıkarılacak.'),
     actions: [
       TextButton(onPressed: ()=>pop(false), child: Text('İptal')),
       FilledButton(onPressed: ()=>pop(true), child: Text('Çıkar')),
     ],
   ));
   if (confirmed == true) await toggleFavorite(...);
   ```
2. UI iyileştirme: Trailing yerine **swipe-to-delete** kullan (Dismissible) — bu daha modern ve mobil-native. Veya kalp butonunu yerine sadece "X" ikonu koy, daha az dikkat çeken.

**Etkilenen:** `lib/features/favorites/presentation/screens/favorites_screen.dart`

---

## 🟡 P2 — UX/UI Polish

### P2-1: AppBar tutarsız (font, yer, başlık tarzı)

**Belirti:** *"hepsinin fontu ve yerleri farklı duruyor, bunları tek yapmamız lazım"*.

**Çözüm:** Tüm `Scaffold`'larda AppBar'ı `AppTheme.lightTheme.appBarTheme` kullanmaya zorla:
- `centerTitle: false` (sola yaslı, modern)
- Title: `AppTextStyles.titleLarge` (zaten theme'de set edilmiş, override yapmasınlar)
- Background: `AppColors.background` (sayfa rengiyle aynı, transparan hissi)

Etkilenen 8+ ekran var: `home_screen`, `explore_screen`, `comparison_screen`, `favorites_screen`, `profile_screen`, `notification_center_screen`, `notification_settings_screen`, `all_reviews_screen`, `my_reviews_screen`, `all_cities_screen`, `city_universities_screen`. Hepsinde AppBar override'larını silip theme defaults'a bırak.

---

### P2-2: Kayıt onaylama maili spam'a düşüyor

**Belirti:** *"verification email spama düştü"*.

**Kök Sebep:** Firebase'in default verification email'i SPF/DKIM kayıtları olmadan gönderiliyor.

**Çözüm:**
1. **Firebase Console → Authentication → Templates → Email address verification**
   - Sender domain'i kendi domain'inizle değiştir (örn: `noreply@uniseckitap.com`)
   - DNS'te SPF, DKIM, DMARC kayıtlarını ekle
2. **Email içeriğini Türkçe'ye çevir** (default İngilizce)
3. **Plain HTML template** — Firebase'in default template'i çok minimal, spam filter'a takılıyor

Bu DevOps/domain ayarı, kod değişikliği değil.

---

### P2-3: Splash screen 3 saniye sürüyor

**Belirti:** *"splash 3 saniye gözüküyor, hafif yavaş"*.

**Kök Sebep:** `main.dart`'ta `Firebase.initializeApp + SharedPreferences.getInstance + FCM.init` paralel async başlıyor, ama FCM permission istiyor — bu bloklayıcı.

**Çözüm:**
1. **FCM init'i defer et** — runApp() çağrıldıktan sonra `addPostFrameCallback` ile arka planda init et:
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp(...);
     final prefs = await SharedPreferences.getInstance();
     // FCM init kaldırıldı — arka planda yapılacak
     runApp(...);
   }

   // UniSecApp initState
   @override
   void initState() {
     super.initState();
     WidgetsBinding.instance.addPostFrameCallback((_) async {
       await FCMService().init();
       // ... onNotificationTap binding
     });
   }
   ```
2. **Native splash kısalt** — `flutter_native_splash` package kullanılıyorsa `pubspec.yaml`'da `min_duration: 0` (ya da paketten tamamen vazgeç).

---

### P2-4: Bildirim merkezinde silme/işaretleme UI iyileştirme

**Belirti:** *"bildirim silme ve okuma kısmını detaylandırmamız lazım, silme için buton falan olsun, hepsini sil diye buton olsun, 3 nokta gibi olsun, alttan açılsın, UI güzel olsun"*.

**Çözüm:**
1. AppBar'a sağ üstte `PopupMenuButton<String>`:
   ```dart
   PopupMenuButton(
     itemBuilder: (_) => [
       PopupMenuItem(value: 'mark_all', child: Text('Tümünü oku')),
       PopupMenuItem(value: 'delete_all', child: Text('Tümünü sil')),
     ],
     onSelected: (val) async {
       if (val == 'mark_all') ...
       if (val == 'delete_all') ... confirmation dialog ...
     },
   )
   ```
2. Her tile'da swipe yerine veya ek olarak long-press menu — silme + okundu işaretleme
3. Görsel: read/unread için sol kenar 3px renkli border (mavi=okunmamış)

**Etkilenen:** `lib/features/notifications/presentation/screens/notification_center_screen.dart`, `notification_tile.dart`

---

### P2-5: Search'ten çıkınca üniversite listesi boş kalıyor

**Belirti:** *"boş oluyor, geri tuşuna basıp keşfete dönmem gerekiyor — search ile aramayı kapat → liste otomatik dönsün"*.

**Kök Sebep:** `search_screen.dart`'ta `initState` query'i sıfırlıyor:
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  ref.read(searchQueryProvider.notifier).state = '';
});
```
Query boşken `searchResultsProvider` `getAllUniversities` döner, ama `_searchController.text` da boş; "Üniversite Ara" empty state çıkıyor.

**Çözüm:** Query boşken default olarak tüm üniversitelerin listelensin (zaten provider yapıyor). Empty state sadece query var ama sonuç 0 ise göstersin:
```dart
body: query.trim().isEmpty
  ? _buildAllUniversitiesList()  // ← Tüm uniler
  : searchResultsAsync.when(...),
```

Bu mevcut tasarım da hem search hem browse hissi verir.

---

### P2-6: Karşılaştırma ekranı UI yenilenmeli + Reset butonu

**Belirti:** *"reset butonu yok, eklenmeli", "karşılaştırma ekranına ve paylaşım ekranına daha güzel bir UI yapmak lazım"*.

**Çözüm:**
1. AppBar'a Reset action ekle:
   ```dart
   if (selection.uniIdA != null || selection.uniIdB != null)
     IconButton(
       icon: Icon(Icons.refresh_rounded),
       tooltip: 'Sıfırla',
       onPressed: () => ref.read(comparisonSelectionProvider.notifier).reset(),
     ),
   ```
2. UI redesign — Sprint 5'e bırakılabilir, P2 olarak. Mevcut yapı işlevsel.

---

### P2-7: Aynı sekmeye iki kez tıklayınca scroll-to-top

**Belirti:** *"aynı sekmeye iki kez tıklayınca scroll-to-top oluyor mu? yok bu olsun"*.

**Çözüm:** `app_shell.dart`:
```dart
onDestinationSelected: (index) {
  if (index == widget.navigationShell.currentIndex) {
    // Aynı tab — scroll to top için PrimaryScrollController
    final ctrl = PrimaryScrollController.of(context);
    if (ctrl.hasClients) {
      ctrl.animateTo(0, duration: 300.ms, curve: Curves.easeOut);
    }
  } else {
    widget.navigationShell.goBranch(index);
  }
},
```

Ekranların en dış scroll widget'ları `PrimaryScrollController.attached` olmalı (zaten default `ListView`/`SingleChildScrollView` öyle).

---

### P2-8: Yurt için DormInfoCard'da bina/giriş-çıkış bilgisi

**Belirti:** *"açılış saati var, bunun yerine giriş çıkış saati olmalı veya bina bilgisi falan"*.

**Çözüm:** `DormInfoCard` widget'ında ek alan:
- "Bina sayısı / Oda tipi" (3 kişilik / 4 kişilik)
- "Giriş-Çıkış saatleri" (KYK için bilinen)
- Bu bilgiler CSV'de yoksa Sprint 5'te admin panelden eklenir; şu an placeholder gösterilebilir

---

### P2-9: Bildirim izni reddedildiğinde tekrar isteme

**Belirti:** *"reddettikten sonra Bildirim Ayarları'ndan tekrar aç deneyince → cihaz ayarlarına yönlendirme var mı?"*.

Mevcut `_buildSystemPermissionWarning` zaten bunu yapıyor (`openAppSettings`). Ama **app içinden ilk istekte permission denied'sa**, ikinci kez sormayı `Permission.notification.request()` izin vermez (Android 13+ kalıcı). Bu yüzden direkt cihaz ayarlarına yönlendirmek tek yol — bu zaten doğru implement edilmiş, P1-13 (lifecycle observer) düzeltilince tam çalışacak.

---

### P2-10: Logo eksik (placeholder yerine gerçek logolar)

**Belirti:** *"şuan logo yok, daha eklemedik, ekliycez"*.

**Çözüm:** Sprint 5'e bırak. Bu hotfix değil, content task. Şu an `Icon(Icons.school_rounded)` placeholder yeterli.

---

### P2-11: Bio alanı ekle

**Belirti:** *"bio yok, eklenebilir"*.

**Çözüm:** `UserModel`'e `bio: String?` field'ı, `EditProfileScreen`'de TextField, `ProfileScreen`'de görüntüleme. Sprint 5'e bırakılabilir.

---

### P2-12: My Reviews sekmesinde tip filtreleme (Üni / Mekan / Bölüm)

**Belirti:** *"tip filtreleme var mı? (Üni / Mekan) yok eklenebilir"*.

**Çözüm:** `my_reviews_screen.dart`'a üst chip filter ekle. State lokal `ReviewType?` ile yetiştirilebilir, basit.

---

### P2-13: Splash → Welcome geçişi takılıyor

**Belirti:** *"çok az kasıyor"*.

**Çözüm:** P2-3'te FCM defer + SharedPreferences cache ile hızlanacak. Ek olarak first-frame'de heavy widget olmamalı (OnboardingScreen mevcut hali OK).

---

### P2-14: Eski/zayıf telefonlarda scroll takılıyor

**Belirti:** *"bazı düşük telefonlarda takılıyor, optimizasyon yapılabilir"*.

**Çözüm:**
1. `UniCard`'larda `cached_network_image`'in `memCacheWidth` zaten 128 — cap edilmiş. OK.
2. `_PopularUniCard` zaten `RepaintBoundary` ile sarılı.
3. Ek: Profile ekranında stats ve settings list'in `ListView.builder` yerine `Column` ile sabit list — küçük olduğu için OK.
4. Belirli ekranlarda `physics: BouncingScrollPhysics()` yerine `ClampingScrollPhysics` Android'de daha hafif olabilir.

Bu aslında perf profiling gerektirir; belirli bir ekranı pinpoint etmeden iyileştirme zor.

---

## 🟢 P3 — Sprint 5'e Devir

Bunlar bug değil, feature/iyileştirme; Sprint 5 polish ve beta'ya bırakılır:

1. Boğaziçi/Koç/Sabancı/vb. için manuel mekan datası eklenmesi
2. Üniversite logoları (görsel asset'leri)
3. Dark mode
4. Bio alanı (Profile)
5. Notification merkezi rich UI redesign
6. Comparison ekranı UI redesign + share card redesign
7. Şehir kartlarında foto yerine emoji yerine gerçek görseller
8. App icon rebrand (eğer "uni_app" → "ÜniSeç" geçişi sırasında icon da değişecekse)
9. Şifre güç göstergesi (Zayıf/Orta/Güçlü)

---

## 🗓️ Çözüm Sırası — 4 Günlük Hotfix Planı

### Gün 1 — Temel Altyapı (Kişi A + Kişi B birlikte)

| Saat | Görev | Kim | P |
|------|-------|-----|---|
| 09:00-10:00 | Sync + bug listesi review | İkisi | — |
| 10:00-13:00 | **P0-1** Mekan filter sistemi rewire | Kişi A | P0 |
| 10:00-13:00 | **P0-2** Department aggregate CF | Kişi B | P0 |
| 14:00-15:30 | **P0-8** App ismi + bundle ID | Kişi A | P0 |
| 14:00-15:30 | **P0-7** Şifre policy | Kişi B | P0 |
| 15:30-17:00 | **P0-3** Logout redirect | İkisi pair | P0 |

### Gün 2 — FCM ve Mekan Detay

| Saat | Görev | Kim | P |
|------|-------|-----|---|
| 09:00-12:00 | **P0-4** FCM index + on_review_liked debug | Kişi B | P0 |
| 09:00-12:00 | **P0-5** Place stream provider migration | Kişi A | P0 |
| 13:00-15:00 | **P0-6** Empty state messaging | Kişi A | P0 |
| 13:00-15:00 | **P1-1** PlaceDetailScreen photo gallery | Kişi A | P1 |
| 15:00-17:00 | **P1-2 P1-3** Seed data zenginleştirme (description, amenities) | Kişi B | P1 |

### Gün 3 — Navigation, Search, Comparison

| Saat | Görev | Kim | P |
|------|-------|-----|---|
| 09:00-11:00 | **P1-4 P1-5** Map URL + Yurt openHours | Kişi A | P1 |
| 09:00-11:00 | **P1-6 P1-7** Aliases + Türkçe sort | Kişi B | P1 |
| 11:00-13:00 | **P1-8 P1-9** Geri zinciri + bottom nav | Kişi A | P1 |
| 11:00-13:00 | **P1-10** Comparison empty side | Kişi B | P1 |
| 14:00-16:00 | **P1-11 P1-12** Login redirect + race | İkisi pair | P1 |
| 16:00-17:00 | **P1-13** Notification settings lifecycle | Kişi A | P1 |
| 16:00-17:00 | **P1-14 P1-15 P1-16** Auth gate + favorites confirm | Kişi B | P1 |

### Gün 4 — Polish + QA

| Saat | Görev | Kim |
|------|-------|-----|
| 09:00-12:00 | P2-1 AppBar normalization (8+ ekran) | İkisi paralel |
| 13:00-15:00 | P2-3 Splash + FCM defer + P2-7 scroll-to-top | Kişi A |
| 13:00-15:00 | P2-4 Notification center UI + P2-12 my reviews filter | Kişi B |
| 15:00-17:00 | **Tam regresyon testi** (aşağıdaki liste) | İkisi |

### Gün 5 — Release (Buffer)

- Beta TestFlight + Play Console internal testing build
- 5+ kullanıcıyla 1 günlük canlı test
- Kalan ufak düzeltmeler
- v0.4.1 release notes

---

## ✅ Regresyon Test Listesi

Hotfix bitince aşağıdaki check'leri **mutlaka** geçir:

### Sprint 3 Regresyonları (önemli — bozulmuş olmamalı)
- [ ] Like flicker yok (B1)
- [ ] Search debounce çalışıyor (B7)
- [ ] Tab switch flicker yok (B4)
- [ ] Avatar memCache stable (B5)

### Sprint 4 Yeni — P0/P1 Sonrası
- [ ] Mekan filter sheet'ten 3'lü kombinasyon liste anında güncelleniyor
- [ ] Bölüm yorumu yaz → 5 sn sonra bölüm detayında rating görünüyor
- [ ] Logout → login ekranına dönüyor
- [ ] İki hesapla like → push bildirim geliyor
- [ ] Mekan yorumu sonrası üni ana sayfası rating güncel
- [ ] App ismi tüm yerlerde "ÜniSeç"
- [ ] Şifre 8+ karakter + büyük harf + rakam zorunlu
- [ ] Kalp dolu → çıkar dialog → onay → çıkarıldı
- [ ] Profile'dan "Bildirim Ayarları" → ayarları aç → cihazda izin ver → app'e dön → status anında güncel
- [ ] Login değilken bell + like → "Giriş yap" snackbar
- [ ] Comparison'da tek tarafı 0 yorumlu → o taraf "Yorum yok" placeholder
- [ ] ODTÜ aramada çıkıyor
- [ ] Şehir listesi: Çorum doğru sıralamada
- [ ] Bottom nav alt sekmelerden geri → Home'a, ikinci geri → app çıkışı

### Cold Start Performans
- [ ] Cold start < 2.5 sn (önceki 3 sn'den iyileşme)
- [ ] FCM init main thread'i bloklamıyor

---

## 📌 Notlar

- **CSV → JSON parser script'i** (P1-2, P1-3 için) Sprint 4'ün build dosyalarında olmalı; eğer yoksa "tek seferlik script" olarak yazılır ve commit edilmez (privacy: sadece çıktı `places_seed.json` commit edilir).
- **Backfill script for department ratings** (P0-2): mevcut bölüm yorumları için tek seferlik aggregate. Local Node script + admin SDK ile çalıştırılabilir.
- **App ismi değişikliği** (P0-8) bundle ID değişimi yaparsa: Firebase Console'da yeni iOS app oluşturmak gerekebilir, eski hesaplar bozulmaz ama analytics sıfırlanır.
- v0.4.1 release notes kullanıcıya: "Kararlılık iyileştirmeleri ve bildirim sistemi düzeltmeleri" — bug listesini paylaşma, sadece özet.

---

*Bu dosyayı debug süreci boyunca canlı tut. Her bug çözüldükçe kutucuğunu işaretle, kapatma sebebini ve commit hash'ini yaz. Sprint 4 retrospektifinde bu dosya başvuru kaynağı olacak.*
