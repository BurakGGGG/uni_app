# 🛠️ Sprint 4 — Hata Ayıklama v2

**Hedef:** Sprint 4 sonrası tespit edilen 14 kullanıcı bug/iyileştirme talebi + kod incelemesinde bulunan ek 8 sorunu, **2 geliştirici (A & B)** ile **7 günde**, **çakışma yaratmadan** çözmek.

**Çalışma kuralı:**
- Her gün öncesi en güncel `main`'i çek (`git pull`).
- Her görev kendi feature branch'ında: `fix/A-D1-T1-profanity-filter` gibi.
- Aynı dosyaya iki kişi aynı gün dokunmaz — Çakışma Matrisi (§4) kraldır.
- Gün sonu PR aç, ertesi gün sabah karşı taraf review eder.

---

## 1) Görev Özeti

### 1.1 — Kullanıcının Bildirdiği 14 Madde

| # | Talep | Kişi | Gün |
|---|---|---|---|
| 1 | Profil "Hakkımda"ya küfür filtresi | A | D1 |
| 2 | Profil → Favori istatistiği tıklanır olsun | A | D2 |
| 3 | **Yorumdaki avatara basınca kullanıcı profili (BÜYÜK)** | B | D1+D2 |
| 4 | Favorilerden çıkarma için daha şık tasarım | A | D4 |
| 5 | Profil "Puan 4.5" stat'i anlamsız → değiştir | A | D2 |
| 6 | Profil → Güvenlik onTap aktif olsun | A | D2 |
| 7 | Çıkış yapınca login'e geçiş yavaş | A | D3 |
| 8 | Genel optimizasyon (telefonu yoruyor) | A | D3+D4 |
| 9 | Üni detayında tab butonları sıkıcı → görsel kartlar | A | D5+D6 |
| 10 | "Haritada Aç" bazı telefonlarda çalışmıyor | B | D3 |
| 11 | Veri olmayan üniversiteleri sil (Boğaziçi, Koç vs.) | B | D4 |
| 12 | Karşılaştırmada yorum yoksa "iki üni çok yakın" yanlış | B | D5 |
| 13 | Karşılaştır → Sıfırla butonu daha belirgin olsun | B | D5 |
| 14 | Karşılaştırma metriklerini zenginleştir + UI şıklaşsın | B | D5+D6 |

### 1.2 — Kod İncelemesinde Bulunan Ek Sorunlar

| # | Sorun | Dosya | Kişi | Gün |
|---|---|---|---|---|
| E1 | **firestore.rules → `isAdmin() = true` (KRİTİK GÜVENLİK AÇIĞI)** | `firestore.rules` | B | D7 |
| E2 | Profil ekranında 4 dead link (`onTap: () {}`) | `profile_screen.dart` | A | D2 |
| E3 | `_PopularUniCard` favorites her değişiklikte 8 kartı rebuild ediyor | `home_screen.dart` | A | D3 |
| E4 | `AppShell` lifecycle resume'da her seferinde `reloadAndCheckVerification` çağrılıyor (pahalı) | `app_shell.dart` | A | D3 |
| E5 | `PlaceCard` her kartta ayrı `AnimationController` (yorucu) | `place_card.dart` | A | D4 |
| E6 | `keepAlive()` her provider'da → uzun session'da memory büyüyor | birden fazla | A | D4 |
| E7 | Seed data'da `aliases` boş — "ODTÜ" araması alias'tan değil normalize'den çalışıyor | `seed_data_service.dart` | B | D4 |
| E8 | `users/{userId}` herkese açık okuma — email gibi PII sızıyor (avatar tap için public profile gerekiyor zaten, fırsat) | `firestore.rules` + `auth_repository.dart` | B | D7 |

---

## 2) Günlük Plan

### 🗓️ Gün 1 — Kurulum

#### Kişi A — Profanity Filter (Talep #1)
**Branch:** `feat/A-D1-profanity-filter`

**Yapılacaklar:**
1. `lib/core/utils/profanity_filter.dart` oluştur:
   - Türkçe küfür/hakaret listesi (~150 kelime, normalize edilmiş)
   - Leet-speech ve harf değiştirme korumalı: `s1k`, `s!k`, `am1n4` gibi varyantları yakalar
   - `bool containsProfanity(String text)` fonksiyonu
   - `String? sanitize(String text)` ile maskeleme (`***`)
   - Kelime sınırı (`\b`) kontrolü ile false-positive önle (`siktir` ≠ `sıkıştır`)
2. `edit_profile_screen.dart` Bio TextField'ına bağla:
   - `onChanged` içinde realtime kontrol
   - Hata varsa kırmızı border + alttaki helper text: "Uygunsuz içerik tespit edildi"
   - `validator` içinde de kontrol — kaydet butonu disabled olsun
   - State değişkeni `_bioHasProfanity` ekle
3. Birim test: `test/core/utils/profanity_filter_test.dart` (en az 10 case)

**Dokunulan dosyalar:**
- 🆕 `lib/core/utils/profanity_filter.dart`
- ✏️ `lib/features/profile/presentation/screens/edit_profile_screen.dart`
- 🆕 `test/core/utils/profanity_filter_test.dart`

**Kabul Kriterleri:**
- [ ] "merhaba" → OK
- [ ] "**ş** **i** **k** **t** **i** **r**" varyantları → BLOCK
- [ ] "sıkıştır" → OK (false positive yok)
- [ ] Bio TextField hata varsa kırmızı + helper text görünür
- [ ] Kaydet butonu küfür içerirken çalışmaz

---

#### Kişi B — Public Profile Scaffold (Talep #3 — Bölüm 1/2)
**Branch:** `feat/B-D1-public-profile-scaffold`

**Yapılacaklar:**
1. `lib/features/profile/presentation/screens/public_profile_screen.dart` oluştur:
   - Route param: `userId`
   - İskelet UI: avatar, isim, üniversite, bölüm, sınıf, bio, "Doğrulanmış öğrenci" rozeti, yorum sayısı, kullanıcının yorumları listesi
   - Email **göstermez** (privacy)
   - Loading + error + empty state
2. `auth_repository.dart` içine **YENİ METOD** ekle (logout zonu A'ya ait olduğu için kendi alanı):
   ```dart
   Future<UserModel?> getPublicProfile(String uid) async { ... }
   ```
   - Sadece public alanları döner; private alanlar (varsa) maskelenir
3. Riverpod provider:
   ```dart
   final publicProfileProvider = FutureProvider.family<UserModel?, String>(...)
   ```
4. `app_router.dart`'a yeni route ekle:
   ```
   /user/:userId
   ```
5. **ReviewCard'a HENÜZ DOKUNMA** — D2'de B yapacak (avatar onTap)

**Dokunulan dosyalar:**
- 🆕 `lib/features/profile/presentation/screens/public_profile_screen.dart`
- 🆕 `lib/features/profile/presentation/providers/public_profile_provider.dart`
- ✏️ `lib/features/auth/data/auth_repository.dart` (sadece yeni metod ekle, logout/cache satırlarına dokunma)
- ✏️ `lib/router/app_router.dart` (sadece yeni route ekle)

**Kabul Kriterleri:**
- [ ] `/user/<bilinen-uid>` URL'iyle ekran açılır
- [ ] Avatar, isim, üniversite, bölüm görünür; email görünmez
- [ ] Bilinmeyen UID → "Kullanıcı bulunamadı" empty state
- [ ] Loading shimmer var

---

### 🗓️ Gün 2 — Profil + Avatar Tap

#### Kişi A — Profil Ekranı Overhaul (#2, #5, #6, E2)
**Branch:** `feat/A-D2-profile-overhaul`

**Yapılacaklar:**
1. **Favori stat tıklanır olsun (#2):** `_StatCard(label: 'Favori')`'a `onTap: () => context.push('/favorites')` ekle.
2. **"Puan 4.5" hardcoded stat'i kaldır (#5):** Yerine "**Üye olduğu süre**" göster:
   ```dart
   final daysSince = DateTime.now().difference(profile.createdAt).inDays;
   _StatCard(icon: Icons.cake_rounded, label: 'Üyelik', value: '$daysSince gün', color: AppColors.warning)
   ```
   Alternatif: "Beğeni aldı" — kullanıcının yorumlarına gelen toplam like sayısı (Cloud Function gerekirse v3'e ertelenebilir, şimdilik üyelik süresi yeterli).
3. **Güvenlik onTap aktif (#6):** `change_password_dialog.dart` (yeni widget) oluştur:
   - Mevcut şifre + yeni şifre + yeni şifre tekrar
   - Validator: min 8 karakter, büyük harf, rakam (RegisterScreen ile aynı kurallar — utility'ye çekilebilir)
   - `FirebaseAuth.currentUser.reauthenticateWithCredential` → `updatePassword`
   - Hata mesajları Türkçe
   - Sadece email/password provider için göster (Google ile girenler için zaten gizli, mevcut kod doğru)
4. **Dead onTap'leri çöz (E2):**
   - "Hakkında" → `showAboutDialog` (Material native)
   - "Uygulamayı Puanla" → `package:in_app_review` ile (yoksa `url_launcher` ile Play Store URL'i)
   - "Arkadaşına Öner" → `Share.share('ÜniSeç indir: <playstore-url>')`
   - "Gizlilik Politikası" → `url_launcher` ile statik bir URL (ör. `https://unisec.app/privacy`) — yoksa "Yakında" snackbar
5. **Pubspec güncellemesi:** `share_plus` zaten var, `in_app_review` ekle (~110 KB)

**Dokunulan dosyalar:**
- ✏️ `lib/features/profile/presentation/screens/profile_screen.dart` (B'nin yeni route'u kullanmaya gerek yok, çakışma yok)
- 🆕 `lib/features/profile/presentation/widgets/change_password_dialog.dart`
- ✏️ `pubspec.yaml`

**Kabul Kriterleri:**
- [ ] Favori stat'a basınca `/favorites` açılıyor
- [ ] "Üyelik X gün" görünüyor (4.5 puan kalktı)
- [ ] Güvenlik → şifre değiştirme dialog'u çalışıyor
- [ ] Hakkında → AboutDialog
- [ ] Puanla → Play Store
- [ ] Öner → Share sheet
- [ ] Gizlilik → URL açılıyor

---

#### Kişi B — Avatar Tap → Public Profile (#3 — Bölüm 2/2)
**Branch:** `feat/B-D2-avatar-tap`

**Yapılacaklar:**
1. `review_card.dart` içinde `_buildHeader`'daki `CircleAvatar`'ı `GestureDetector` ile sar:
   ```dart
   GestureDetector(
     onTap: review.isAnonymous ? null : () => context.push('/user/${review.userId}'),
     child: CircleAvatar(...),
   )
   ```
2. **Anonim yorumlarda navigation çalışmasın** — `onTap: null` ve hafifçe gri tone.
3. Public profile ekranındaki yorum listesi: kullanıcının kendi yorumlarını çek (`userReviewsProvider` zaten var).
4. **Önemli:** Public profile ekranında ReviewCard'a **`showActions: false, showReportMenu: false, onTap: <ilgili-targete-git>`** geçir, yoksa "yorumumu sil" butonu başkasının profilinde gözükür!
5. Kullanıcının üniversitesi varsa, ekranda "Üniversitesini görüntüle" butonu (small) ile `/university/<uniId>` route'una gitsin.
6. Anonim yorumlarda da review listesinde anonim olarak göstermek için: public profile sayfasına `showAnonymousReviews: false` filtresi koy → kullanıcının kendi anonim yorumları başkalarına ifşa olmasın.

**Dokunulan dosyalar:**
- ✏️ `lib/features/reviews/presentation/widgets/review_card.dart`
- ✏️ `lib/features/profile/presentation/screens/public_profile_screen.dart` (D1'de oluşturulan iskeleti doldur)

**Kabul Kriterleri:**
- [ ] Yorum kartındaki avatara basınca `/user/<uid>` açılıyor
- [ ] Anonim yorumlarda avatar tıklanmaz (gri tone + cursor disabled)
- [ ] Public profile'da kullanıcının onaylanmış yorumları görünüyor
- [ ] Public profile'da kendi anonim yorumları görünmüyor (privacy)
- [ ] Public profile'daki yorum kartlarında "düzenle/sil" yok

---

### 🗓️ Gün 3 — Performans + Map Fix

#### Kişi A — Logout Hızlandır + Performans Pass 1 (#7, #8 part1, E3, E4)
**Branch:** `fix/A-D3-perf-logout`

**Yapılacaklar:**

1. **Logout hızlandır (#7):**
   `auth_repository.dart` → `signOut`:
   ```dart
   Future<void> signOut() async {
     // Token unregister'ı fire-and-forget — login'e geçişi yavaşlatma
     unawaited(FCMService().unregisterToken());
     _cachedUser = null;
     _lastCacheTime = null;
     await Future.wait([
       _auth.signOut(),
       _googleSignIn.signOut(),
     ]);
   }
   ```
   `profile_screen.dart` → çıkış handler:
   ```dart
   if (confirmed == true) {
     // Önce nav, sonra signOut → kullanıcı bekleme algılamasın
     if (context.mounted) context.go('/login');
     ref.read(authControllerProvider.notifier).signOut();
   }
   ```
   ⚠️ Sıralama önemli: route değişimi ardından signOut, çünkü `authStateProvider` stream'i zaten authStateChanges'i dinliyor; router redirect logout'u algılayıp aynı yere yönlendirmeyecek.

2. **`_PopularUniCard` rebuild fix (E3):**
   Şu anda `ref.watch(favoritesProvider)` ile her kart tüm favori değişikliğinde rebuild oluyor. `.select()` kullan:
   ```dart
   final isFavorite = ref.watch(
     favoritesProvider.select((async) => async.value?.contains(university.id) ?? false),
   );
   ```

3. **`AppShell` lifecycle gereksiz token refresh (E4):**
   Her resume'da `reloadAndCheckVerification` çağırmak yerine:
   - Eğer kullanıcı zaten verified ise hiç çağırma
   - Son çağrıdan beri 5 dakika geçtiyse çağır (debounce)

4. **`SeedDataService`'i debug-only build'e taşı:** Release build'e dahil etmemek için (boyut + güvenlik). `kReleaseMode` kontrolü zaten profil ekranında var ama `lib/scripts/` klasörünü `tree shaking` için lazy import et.

**Dokunulan dosyalar:**
- ✏️ `lib/features/auth/data/auth_repository.dart` (signOut bölümü — B'nin getPublicProfile'ı ile çakışmaz, farklı satırlar)
- ✏️ `lib/features/profile/presentation/screens/profile_screen.dart`
- ✏️ `lib/features/home/presentation/screens/home_screen.dart` (sadece `_PopularUniCard`)
- ✏️ `lib/router/app_shell.dart`

**Kabul Kriterleri:**
- [ ] Logout butonuna basıldıktan max 200ms içinde login ekranı açılıyor
- [ ] DevTools timeline'da `_PopularUniCard` rebuild count favori toggle'da 1'den 8'e çıkmıyor
- [ ] Uygulama background'a alıp 1 saniye sonra geri açınca lag yok

---

#### Kişi B — Map "Haritada Aç" Düzeltmesi (#10)
**Branch:** `fix/B-D3-map-open`

**Yapılacaklar:**

1. `lib/core/utils/map_launcher.dart` (yeni utility) oluştur:
   ```dart
   class MapLauncher {
     static Future<bool> open({
       String? mapUrl,
       GeoPoint? location,
       String? name,
       String? address,
     }) async {
       // 1. Native intent (Android: geo:, iOS: maps://)
       // 2. Google Maps URL
       // 3. Yandex Maps URL fallback (bazı bölgelerde alternatif)
       // 4. Hiçbiri açılmazsa false döner
     }
   }
   ```

2. **Android için `geo:` scheme:** Manifest'te `<queries>` bloğu ekle:
   ```xml
   <queries>
     <intent>
       <action android:name="android.intent.action.VIEW" />
       <data android:scheme="geo" />
     </intent>
     <intent>
       <action android:name="android.intent.action.VIEW" />
       <data android:scheme="https" />
     </intent>
   </queries>
   ```
   Yoksa Android 11+ `canLaunchUrl` her zaman false döner.

3. **iOS için Info.plist:**
   ```xml
   <key>LSApplicationQueriesSchemes</key>
   <array>
     <string>maps</string>
     <string>comgooglemaps</string>
   </array>
   ```

4. `place_detail_screen.dart` → `_openMap` metodunu MapLauncher'a refactor et:
   ```dart
   final ok = await MapLauncher.open(
     mapUrl: place.mapUrl,
     location: place.location,
     name: place.name,
     address: place.address,
   );
   if (!ok && mounted) showAppSnackBar(...);
   ```

5. **Snackbar mesajı düzelt:** "Harita açılamadı" yerine "Harita uygulaması bulunamadı. Lütfen Google Maps yükleyin." + Play Store linki action'ı.

**Dokunulan dosyalar:**
- 🆕 `lib/core/utils/map_launcher.dart`
- ✏️ `lib/features/places/presentation/screens/place_detail_screen.dart`
- ✏️ `android/app/src/main/AndroidManifest.xml`
- ✏️ `ios/Runner/Info.plist`

**Kabul Kriterleri:**
- [ ] Google Maps yüklü Android'de → Maps uygulamasında açılıyor
- [ ] Google Maps yüklü olmayan Android'de → varsayılan harita / Yandex / browser fallback
- [ ] iOS Simulator'da → Apple Maps açılıyor
- [ ] iOS gerçek cihazda Google Maps yüklüyse → Google Maps tercih ediliyor (kullanıcıya seçim sun)
- [ ] Hiçbir harita yoksa → snackbar net mesaj + Play Store CTA

---

### 🗓️ Gün 4 — Favoriler UI + Seed Cleanup

#### Kişi A — Favoriler Ekranı Yeni UI (#4) + Performans Pass 2 (E5, E6)
**Branch:** `feat/A-D4-favorites-redesign`

**Yapılacaklar:**

1. **Favoriler ekranı yeni UI (#4):**
   - `Dismissible` swipe'ı **kaldır** veya secondary action olarak sakla.
   - Her kartın sağ üst köşesine **dolu kalp ikonu** koy (zaten favoride olduğu için).
   - Kalbe basınca:
     - **Animasyonla küçülerek listeden çıksın** (`AnimatedSwitcher` + `SizeTransition`)
     - 4 saniyelik **undo snackbar**: "Favorilerden çıkarıldı — GERİ AL"
     - Geri al basılırsa eklenen favori geri eklensin
   - Boş state: pencere ortasında büyük kalp + "Henüz favorin yok" + "Keşfet'e Git" CTA
   - Üst kısımda toplam favori sayısı ve "Tümünü temizle" outline button (long press confirm)

2. **`PlaceCard` AnimationController kaldır (E5):**
   Tek `AnimationController` × N kart yerine `InkWell`'in default ripple'ı yeterli. Press animation gerekiyorsa `AnimatedScale` (1.0 ↔ 0.97) ile, controller'sız.

3. **`keepAlive()` audit (E6):**
   - `popularUniversitiesProvider`, `recentReviewsProvider` → keepAlive **kalmalı** (ana sayfa hızı için)
   - `userReviewsProvider`, `placeReviewsProvider`, `departmentReviewsProvider` → keepAlive **kaldır**, autoDispose ekle (kullanıcı ekrandan ayrılınca temizlensin)
   - `placeDetailProvider`, `placeWatchProvider` → keepAlive yerine `5 dakika autoDispose timer` (Riverpod 2.x: `keepAlive()` + custom timer)

**Dokunulan dosyalar:**
- ✏️ `lib/features/favorites/presentation/screens/favorites_screen.dart`
- ✏️ `lib/features/places/presentation/widgets/place_card.dart` (B'nin seed cleanup'ı `seed_data_service`'i; çakışmaz)
- ✏️ `lib/features/reviews/presentation/providers/review_providers.dart`
- ✏️ `lib/features/places/presentation/providers/place_providers.dart`

**Kabul Kriterleri:**
- [ ] Favoriler ekranında her kartta dolu kalp ikonu var
- [ ] Kalbe basınca smooth animasyonla çıkıyor + undo snackbar
- [ ] Undo'ya basınca geri ekleniyor (data persist)
- [ ] Boş state göze hoş gelen tasarım
- [ ] DevTools'da PlaceCard memory profile düzgün (controller leak yok)
- [ ] Liste ekranlarından çıkıp girince provider yeniden yükleniyor (autoDispose çalışıyor)

---

#### Kişi B — Seed Data Temizliği (#11) + Aliases (E7)
**Branch:** `chore/B-D4-seed-cleanup`

**Yapılacaklar:**

1. **Veri olmayan üniversiteleri tespit:**
   `assets/data/places_seed.json` aç, **`universityId` listesini çıkar**, sonra `seed_data_service.dart` içindeki üniversite listesini bu setle filtrele:
   ```dart
   final unisWithPlaces = placesData.map((p) => p['universityId']).toSet();
   ```

2. **Üniversite listesini güncelle:** `seed_data_service.dart` içindeki `universities` array'inden `unisWithPlaces` setinde olmayanları çıkar. `cities` array'indeki `appUniversityCount` alanını da güncelle.

3. **Mevcut prod verisini temizleme komutu yaz:** `lib/scripts/cleanup_universities.dart` (Cloud Function olarak da yazılabilir, basit Dart script de yeter):
   - Tüm üniversiteleri çek
   - `places` koleksiyonunda `universityId` olmayan üniversiteleri listele
   - Confirm prompt + cascading delete: üni + departments + (yorumlar varsa orphan, B'ye sor)
   - **Yorum olan üni asla silinmemeli** — uyarı verip atla

4. **Aliases doldur (E7):** `seed_data_service.dart`'ta her üniversiteye `aliases` ekle:
   ```dart
   'odtu' → ['ODTÜ', 'METU', 'Orta Doğu']
   'itu'  → ['İTÜ', 'İstanbul Teknik']
   'bogazici' → ['Boğaziçi', 'BOUN', 'Bosphorus']
   'koc'  → ['Koç', 'KU']
   ...
   ```
   Notu: Boğaziçi & Koç eğer #11 nedeniyle silinecekse alias'a gerek yok. Listenin son halini A'ya bildir ki o `_PopularUniCard` mock'u güncellesin (gerek varsa).

5. **Migration playbook hazırla:** `docs/migrations/2026-05-cleanup.md` — önce dev DB, sonra staging, sonra prod nasıl çalıştırılacak.

**Dokunulan dosyalar:**
- ✏️ `lib/scripts/seed_data_service.dart`
- 🆕 `lib/scripts/cleanup_universities.dart`
- ✏️ `assets/data/places_seed.json` (gerekirse)
- 🆕 `docs/migrations/2026-05-cleanup.md`

**Kabul Kriterleri:**
- [ ] Seed data sadece place'i olan üniversiteleri içeriyor
- [ ] `cities.appUniversityCount` doğru değerler
- [ ] Cleanup script kuru (dry-run) modunda neyi sileceğini gösteriyor
- [ ] Yorum olan üni listede ise atlama uyarısı veriyor
- [ ] ODTÜ/İTÜ vs. için alias'lar set edilmiş — arama "ODTÜ" ile çalışıyor

---

### 🗓️ Gün 5 — University Detail UI + Comparison Fix

#### Kişi A — Üniversite Detay UI Yenileme (#9 — Bölüm 1/2)
**Branch:** `feat/A-D5-uni-detail-cards`

**Yapılacaklar:**

1. **Tab yapısını kaldır.** Yerine **single-scroll + sticky section header** + **görsel preview kartları** koy.
2. Yeni iskelet:
   ```
   [Hero header — mevcut]
   [Compact info card — mevcut]
   ├─ Genel Puanlar Kartı (CategoryRatingsChart preview, "Tümünü Gör →")
   ├─ Bölümler Önizleme Kartı:
   │   ├─ İlk 3 popüler bölüm (görselli ikon + isim + taban puan)
   │   └─ "Tüm 30 bölümü gör →" CTA
   ├─ Mekanlar Önizleme Kartı:
   │   ├─ Tip filtresi chip-row (Kafe/Yurt/Kütüphane)
   │   ├─ İlk 4 mekanın grid kartı (foto thumbnail + isim + rating)
   │   └─ "Tüm mekanları gör →" CTA
   └─ Yorumlar Önizleme Kartı:
       ├─ İlk 3 popüler yorum (compact ReviewCard)
       └─ "Tüm yorumları gör →" CTA
   ```
3. **"Tümünü Gör"** linkleri yeni alt-route'lara gitsin:
   - `/university/:uniId/departments` — sadece bölüm listesi (mevcut tab içeriği aynen)
   - `/university/:uniId/places` — sadece mekan listesi
   - `/university/:uniId/reviews` — sadece yorum listesi
4. Bu alt-rotaları `app_router.dart`'a ekle.
5. **Önemli:** Mevcut `ReviewList`, `PlaceList`, `_DepartmentsTab` widget'larını **DEĞİŞTİRME** — sadece üst seviyeden çağıran `university_detail_screen.dart`'ı yeniden yaz. Alt route'lar bu widget'ları olduğu gibi kullanacak.

**Dokunulan dosyalar:**
- ✏️ `lib/features/university/presentation/screens/university_detail_screen.dart`
- 🆕 `lib/features/university/presentation/screens/uni_departments_screen.dart`
- 🆕 `lib/features/university/presentation/screens/uni_places_screen.dart`
- 🆕 `lib/features/university/presentation/screens/uni_reviews_screen.dart`
- ✏️ `lib/router/app_router.dart` (B'nin D6'da dokunmayacağı dosya — A güvenle değiştirir)

**Kabul Kriterleri:**
- [ ] University detail ekranında tab yok
- [ ] 3 önizleme kartı görsel + bilgilendirici (ilk 3-4 öğe + CTA)
- [ ] "Tümünü gör" linkleri ilgili sub-route'a gidiyor
- [ ] Sub-route'lar mevcut listeyi tam olarak gösteriyor (regression yok)

---

#### Kişi B — Karşılaştırma Quick Wins (#12, #13)
**Branch:** `fix/B-D5-compare-quickwins`

**Yapılacaklar:**

1. **`summaryText` mantığını düzelt (#12):**
   `comparison_result.dart`:
   ```dart
   String get summaryText {
     final aHasReviews = uniA.reviewCount > 0;
     final bHasReviews = uniB.reviewCount > 0;
     
     if (!aHasReviews && !bHasReviews) {
       return 'Henüz yorum bulunmuyor — tarafsız karşılaştırma için yorum bekleniyor';
     }
     if (!aHasReviews) {
       return '${uniA.name} için henüz yorum yok';
     }
     if (!bHasReviews) {
       return '${uniB.name} için henüz yorum yok';
     }
     if (overallWinnerId == null) {
       return 'İki üniversite genel puanlarda çok yakın';
     }
     final winner = overallWinnerId == uniA.id ? uniA.name : uniB.name;
     return '$winner genel olarak öne çıkıyor';
   }
   ```

2. **Sıfırla butonunu belirginleştir (#13):**
   `comparison_screen.dart` üst çubuğunda IconButton yerine:
   ```dart
   if (selection.uniIdA != null || selection.uniIdB != null)
     TextButton.icon(
       icon: const Icon(Icons.refresh_rounded, size: 18),
       label: const Text('Sıfırla'),
       style: TextButton.styleFrom(
         foregroundColor: AppColors.error,
         backgroundColor: AppColors.error.withValues(alpha: 0.08),
         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
       ),
       onPressed: () => ref.read(...).reset(),
     ),
   ```
   Yer değiştir & Paylaş zaten icon — onlar kalsın. Sıfırla en önemli olduğu için text+icon.

3. **Empty state mesajları:**
   Her bir kategori için `valueA == 0 && valueB == 0` ise zaten "Henüz yeterli yorum yok" gösteriyor (kod doğru). Ama A tarafında 5 yorum, B tarafında 0 olduğunda görsel bar'ın 0 sıfır olarak gösterilmesi yanıltıcı. Açıkça **"yorum yok"** etiketi koy (zaten var, kontrol et — `_NoDataLabel`).

**Dokunulan dosyalar:**
- ✏️ `lib/features/comparison/domain/models/comparison_result.dart`
- ✏️ `lib/features/comparison/presentation/screens/comparison_screen.dart`

**Kabul Kriterleri:**
- [ ] İki üni de 0 yorum → "Henüz yorum bulunmuyor..." mesajı
- [ ] Sadece bir tarafta yorum varsa → "X için yorum yok" mesajı
- [ ] Sıfırla butonu artık metin+ikon — kullanıcı net görüyor
- [ ] Sıfırla rengi error tonunda (kırmızımsı) — dikkat çekiyor

---

### 🗓️ Gün 6 — University Detail Polish + Comparison Enrichment

#### Kişi A — Uni Detay Cilalama + Test (#9 — Bölüm 2/2)
**Branch:** `feat/A-D6-uni-detail-polish`

**Yapılacaklar:**

1. **Animasyonlar:** Önizleme kartlarına `flutter_animate` ile fade+slide (sequenced).
2. **Empty state'ler:** Bölümü/yorumu/mekanı olmayan üniversiteler için her kartın empty state'i (small, hoş).
3. **Pull-to-refresh:** Üniversite detay sayfasında `RefreshIndicator` — 3 listeyi de invalidate et.
4. **Performans:** `RepaintBoundary` her ana karta sar ki scroll'da diğerleri yeniden çizilmesin.
5. **Manual smoke test:** ODTÜ, ITÜ, Anadolu, Bilkent gibi 5 farklı üni profilini elle gez — bug yok mu?
6. **Integration test:** `integration_test/university_detail_test.dart` — temel navigasyon: ana sayfa → üni → bölüm sub-route → geri.

**Dokunulan dosyalar:**
- ✏️ `lib/features/university/presentation/screens/university_detail_screen.dart`
- ✏️ Yeni sub-route screens (D5'te oluşturulan)
- 🆕 `integration_test/university_detail_test.dart`

**Kabul Kriterleri:**
- [ ] Animasyonlar pürüzsüz (60 FPS hedef)
- [ ] Empty state'lerde de kart şık
- [ ] Pull-to-refresh çalışıyor (verifyable)
- [ ] Integration test geçiyor

---

#### Kişi B — Karşılaştırma UI Zenginleştirme (#14)
**Branch:** `feat/B-D6-compare-rich`

**Yapılacaklar:**

1. **`comparison_result.dart`'a yeni metrikler:**
   ```dart
   class ComparisonStats {
     // ...mevcut
     final int totalDepartmentsA, totalDepartmentsB;
     final double avgBaseScoreA, avgBaseScoreB;  // Bölümlerin ortalama taban puanı
     final Map<PlaceType, int> placeBreakdownA;  // {cafe: 3, dorm: 2, ...}
     final Map<PlaceType, int> placeBreakdownB;
     final int undergradCountA, undergradCountB;  // Lisans sayısı
     final int associateCountA, associateCountB; // Önlisans sayısı
   }
   ```

2. **`ComparisonRepository.compare`** — bu ek verileri hesapla:
   ```dart
   final deptsA = await _uniRepo.getDepartmentsByUniversity(uniIdA);
   final deptsB = await _uniRepo.getDepartmentsByUniversity(uniIdB);
   ```
   `Future.wait` listesine ekle.

3. **Radar Chart** ile 6 kategoriyi tek görselde göster:
   - Paket: `fl_chart` (zaten projede var)
   - `lib/features/comparison/presentation/widgets/comparison_radar_chart.dart`
   - 2 dataset: A (primary) ve B (secondary), yarı transparent

4. **Yeni stat kartları:**
   - "Ortalama Taban Puanı" karşılaştırma
   - "Toplam Bölüm" (Lisans + Önlisans breakdown)
   - "Mekan Çeşitliliği" (kategori bazlı barchart)

5. **Animasyon:** Bar'lar `0 → final value` smooth transition (mevcut `AnimatedContainer` var, polish).

6. **Dark mode hazır mı kontrolü:** Comparison ekranı tüm renkleri AppColors üzerinden alıyor mu?

7. **`comparison_share_card.dart`** PNG export'u — radar chart ve yeni stat'lar paylaşım kartında da görünsün.

**Dokunulan dosyalar:**
- ✏️ `lib/features/comparison/domain/models/comparison_result.dart`
- ✏️ `lib/features/comparison/data/comparison_repository.dart`
- 🆕 `lib/features/comparison/presentation/widgets/comparison_radar_chart.dart`
- ✏️ `lib/features/comparison/presentation/widgets/comparison_stats_table.dart`
- ✏️ `lib/features/comparison/presentation/widgets/comparison_share_card.dart`
- ✏️ `lib/features/comparison/presentation/screens/comparison_screen.dart`

**Kabul Kriterleri:**
- [ ] Radar chart 6 kategoriyi tek görselde gösteriyor
- [ ] Ortalama taban puanı, toplam bölüm, mekan dağılımı yeni kartlar olarak var
- [ ] Animasyonlar smooth
- [ ] Paylaşım kartı zenginleşmiş hâliyle PNG'ye çıkıyor
- [ ] AppColors üzerinden tüm renkler — tema değişikliğinde sorun yok

---

### 🗓️ Gün 7 — Güvenlik + Entegrasyon

#### Kişi A — Çakışma Çözümü + Manual QA + Bug Fix Buffer
**Branch:** `chore/A-D7-qa`

**Yapılacaklar:**

1. **B'nin firestore.rules değişiklikleri yüzünden client-side çağrılarda regression var mı** — manuel test:
   - Login (anon değil verified)
   - Yorum yaz, like at, sil
   - Favori ekle/çıkar
   - Profili düzenle
2. **B'nin tüm PR'larını review et.**
3. **A'nın kendi tüm PR'larını B review ettiğinde gelen feedback'leri çöz.**
4. **Crashlytics check:** Test cihazında 30 dakika kullan, crash log'u temiz mi?
5. **Tüm dilbilgisi & yazım hatalarını gez:** Türkçe metinleri okuduktan sonra tweak.
6. **README + CHANGELOG güncellemesi:**
   - `CHANGELOG.md`'ye Sprint 4 v2 değişiklikleri (kullanıcı odaklı dil)
   - `README.md` ekran görüntülerini güncelle (yeni profil, yeni karşılaştırma, yeni üni detay)

---

#### Kişi B — Firestore Güvenlik Sertleştirme (E1, E8)
**Branch:** `security/B-D7-firestore-rules`

**Yapılacaklar:**

1. **`isAdmin()` fonksiyonunu DÜZELT (E1):**
   ```
   function isAdmin() {
     return isAuthenticated() && 
       request.auth.token.admin == true;
   }
   ```
   Bu şu anda **production'a deploy edilirse** herkes seed verisi yazabiliyor. KRİTİK.

2. **Custom claim setup:** Admin user'larına custom claim ver (Firebase Admin SDK ile):
   ```
   admin.auth().setCustomUserClaims(uid, {admin: true})
   ```
   Adımları `docs/admin-setup.md`'de belgele.

3. **Geliştirme/test için:** Admin claim'i olan bir test user oluştur. Geliştirici dokümanına ekle. Seed data sadece admin'ler tarafından yüklenebilecek artık. `profile_screen.dart`'taki "Seed Verisini Yükle" debug butonu admin kontrolü yapsın.

4. **Users koleksiyonu PII koruma (E8):**
   ```
   match /users/{userId} {
     // Public okuma sınırlandır — tüm dökümanı göstermek yerine
     // sadece public alanları
     allow read: if true;
     // YETERSİZ — Firestore field-level security yok, çözüm:
     // 1. publicProfile alt koleksiyonu oluştur (server-side trigger)
     // 2. veya Cloud Function'la public/{userId} mirror tut
   }
   ```
   En pratik çözüm: `publicProfile` field-set'i Cloud Function ile sync tut (`onUpdate` trigger).
   - Şimdilik fast-fix: `allow read: if true` kalsın ama `auth_repository.getPublicProfile` istemci tarafında email'i nullify etsin (zaten yaptık).
   - v3'te Cloud Function'a geçiş için issue aç.

5. **Yeni kuralları test et:** `firebase emulators:start` + `npm test` (Firestore rules test suite — yoksa kur).

**Dokunulan dosyalar:**
- ✏️ `firestore.rules`
- 🆕 `docs/admin-setup.md`
- 🆕 `test/firestore-rules.test.ts` (rules test'i, JS — opsiyonel)
- ✏️ `lib/features/profile/presentation/screens/profile_screen.dart` (admin claim kontrolü debug butonu için)
- ✏️ `lib/scripts/seed_data_service.dart` (admin only)

**Kabul Kriterleri:**
- [ ] `isAdmin()` artık `request.auth.token.admin == true` döner
- [ ] Test admin claim'i ile seed yükleme çalışır
- [ ] Normal user ile seed yükleme reddedilir
- [ ] Admin setup dokümanı net adım adım

---

## 3) Çakışma Önleme — Dosya Sahiplik Matrisi

| Dosya | D1 | D2 | D3 | D4 | D5 | D6 | D7 |
|---|---|---|---|---|---|---|---|
| `auth_repository.dart` | **B** (yeni metod) | — | **A** (signOut) | — | — | — | — |
| `profile_screen.dart` | — | **A** | **A** (logout nav) | — | — | — | **B** (admin button) |
| `edit_profile_screen.dart` | **A** | — | — | — | — | — | — |
| `review_card.dart` | — | **B** | — | — | — | — | — |
| `home_screen.dart` | — | — | **A** | — | — | — | — |
| `app_shell.dart` | — | — | **A** | — | — | — | — |
| `app_router.dart` | **B** | — | — | — | **A** | — | — |
| `place_detail_screen.dart` | — | — | **B** | — | — | — | — |
| `place_card.dart` | — | — | — | **A** | — | — | — |
| `seed_data_service.dart` | — | — | — | **B** | — | — | **B** (admin) |
| `favorites_screen.dart` | — | — | — | **A** | — | — | — |
| `university_detail_screen.dart` | — | — | — | — | **A** | **A** | — |
| `comparison_screen.dart` | — | — | — | — | **B** | **B** | — |
| `comparison_result.dart` | — | — | — | — | **B** | **B** | — |
| `comparison_repository.dart` | — | — | — | — | — | **B** | — |
| `firestore.rules` | — | — | — | — | — | — | **B** |
| `*_providers.dart` (review/place) | — | — | — | **A** | — | — | — |

**Kritik nokta:** `auth_repository.dart` D1'de B, D3'te A dokunuyor — **D1 PR'ı D3 başlamadan merge olmalı.** Aksi halde rebase gerekir.

---

## 4) Bağımlılıklar (Sıralama Kritik)

```
D1 (B: PublicProfileScreen iskelet)
   └─> D2 (B: ReviewCard avatar onTap → public profile)
        └─> Bu D2 görevi D1 merge olmadan başlayamaz

D1 (A: Profanity filter utility)
   └─> D2 (A: edit_profile bio kullanır — aslında D1'de bağlanıyor)

D5 (A: Yeni sub-route'lar)
   └─> D6 (A: polish bunlara da uygulanıyor)

D5 (B: Comparison fix)
   └─> D6 (B: Comparison enrichment)

D7 (B: firestore.rules sertleştirme) → en sona bilinçli olarak konuldu
   ki diğer feature'lar düzgün test edilebilsin (rules sıkılınca debug yapılamayan akışlar olabilir).
```

---

## 5) Risk Notları

| # | Risk | Etki | Çare |
|---|---|---|---|
| R1 | Profanity filter false positive (`sıkıştır` → block) | Orta | Kelime sınırı `\b` + birim test ≥10 case |
| R2 | Public profile'da anonim yorum sızıntısı | Yüksek (privacy) | `userReviewsProvider` filter'ında `isAnonymous == false` |
| R3 | Logout nav-first → race condition (signOut tamamlanmadan login'e gidiş) | Düşük | `authStateChanges` zaten gözlemleniyor; route redirect dahil mevcut |
| R4 | Map intent flag'leri Android 11+ olmadan çalışmaz | Yüksek | Manifest `<queries>` mutlaka eklenmeli — checklist |
| R5 | Seed cleanup yorumlu üniyi siler → veri kaybı | Çok yüksek | Cleanup script "yorum varsa atla" kuralı + dry-run + 2-step confirm |
| R6 | Firestore rules sertleşince mevcut akışlar bozulur | Yüksek | D7'de tutuldu — D1-D6 işleri etkilenmesin |
| R7 | Radar chart cihaz performansını düşürür | Düşük | `RepaintBoundary` ve `static decorations` ile optimize |
| R8 | Üni detay kart hierarchy'si ile alt-route navigation back-stack karışır | Orta | `context.push` (pop'la geri) tercih et, `context.go` değil |
| R9 | Senkron çıkış (`unawaited`) kullanıcı offline iken token silmez | Düşük | Sonraki login'de eski token override olur — kabul edilebilir |
| R10 | `keepAlive` kaldırılan provider'lar tekrar yüklenirken kullanıcı 1-2sn boş ekran görür | Orta | Shimmer loading mevcut — UX bozulmaz |

---

## 6) Test Listesi (Her Görev İçin Manuel)

### Profil
- [ ] Bio'ya küfür yaz → realtime kırmızı border + helper
- [ ] Bio'ya normal metin yaz → kaydedilebilir
- [ ] Favori stat'a bas → favoriler ekranı açılıyor
- [ ] Yorum stat'a bas → yorumlarım açılıyor
- [ ] Üyelik gün sayısı doğru hesaplanıyor
- [ ] Güvenlik → şifre değişimi başarılı + Firebase'de güncel
- [ ] Hakkında, Puanla, Öner, Gizlilik linkleri çalışıyor

### Public Profile
- [ ] Yorumdaki avatara bas → public profile açılıyor
- [ ] Anonim yorumda avatar tıklanmıyor
- [ ] Public profile email göstermez
- [ ] Public profile kullanıcının onaylanmış yorumlarını gösterir
- [ ] Anonim yorumlar public profile'da görünmez

### Logout
- [ ] Çıkış butonuna basınca <200ms login'e geçiş
- [ ] Bir sonraki login'de FCM token doğru kaydoluyor

### Map
- [ ] Android Maps yüklü → uygulama açılıyor
- [ ] Android Maps yok → fallback çalışıyor
- [ ] iOS → Apple Maps açılıyor
- [ ] Hiçbir harita yok → snackbar net mesaj

### Favoriler
- [ ] Kalp tıkla → animasyonla çıkıyor
- [ ] Undo snackbar 4sn göründü
- [ ] Geri al → favori geri eklendi
- [ ] Boş state şık

### University Detail
- [ ] Tab yok, kart önizlemeleri var
- [ ] "Tümünü gör" linkleri çalışıyor
- [ ] Sub-route'larda mevcut listeler aynen görünüyor
- [ ] Pull-to-refresh çalışıyor

### Comparison
- [ ] Her iki üni 0 yorum → "Henüz yorum bulunmuyor"
- [ ] Tek tarafta yorum yok → "X için yorum yok"
- [ ] Sıfırla butonu metin+ikon olarak belirgin
- [ ] Radar chart 6 kategoriyi gösteriyor
- [ ] Ortalama taban puan, bölüm sayısı, mekan dağılımı kartları var

### Performans
- [ ] Profile DevTools'da `_PopularUniCard` rebuild count düşük
- [ ] PlaceCard memory leak yok
- [ ] App background/foreground hızlı
- [ ] Provider autoDispose çalışıyor (Riverpod inspector)

### Güvenlik
- [ ] Normal user `cities` yazmaya çalışırsa reddedilir
- [ ] Admin claim'li user yazabilir
- [ ] Public profile email sızıntısı yok

### Veri
- [ ] Boğaziçi/Koç gibi place'siz üniler artık listede yok
- [ ] "ODTÜ" araması Orta Doğu Teknik'i bulur

---

## 7) Sprint Sonu Demo Senaryosu

**5 dakikalık akış** (paydaş demo'su için):

1. Login (verified edu.tr user)
2. Ana sayfa → "Popüler" listesi smooth scroll → bir üniversiteye bas
3. Yeni kart-tabanlı üni detay tanıtımı → "Tüm bölümleri gör"
4. Geri → Mekanlar önizleme → bir mekana bas → "Haritada Aç" çalışıyor
5. Profilim → Üyelik X gün, Favori sayısı tıklanır → favoriler ekranı yeni UI
6. Bir yorumun avatarına bas → public profile (yeni özellik!)
7. Karşılaştır → 2 üni seç → radar chart + zengin stat'lar → "Sıfırla" butonu net
8. Çıkış yap → anında login ekranı (D3 hızlandırması)

---

## 8) Onay & Yayın

- **Hedef merge tarihi:** D7 sonu (cuma EOD)
- **Beta release:** D7+1 cumartesi
- **Production release:** D7+3 pazartesi (hafta sonu manual QA + Crashlytics izleme)
- **Rollback planı:** Önceki Sprint 4 v1 build'i Play Console'da yedek olarak kalsın

---

**Hazırlayan:** Claude (kod incelemesi + kullanıcı talepleri sentezi)  
**Versiyon:** v2 — Sprint 4 hata ayıklama  
**Tarih:** Mayıs 2026
