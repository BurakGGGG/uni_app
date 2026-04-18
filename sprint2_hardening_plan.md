# 🛠️ Sprint 2 Hardening Planı

> Sprint 3 (Yorum Sistemi) öncesi kapatılması gereken eksikler. Sıralama önem sırasınadır — yukarıdan aşağıya gitmeni öneririm çünkü her sprint bir öncekine dayanıyor.

---

## Sprint 2.1 — Auth ve Router Sağlamlaştırma (1–2 gün)

Yorum sistemi "kim yazıyor" ve "yazma yetkisi var mı" sorularına net cevap verebilmek zorunda. Bugün bu cevaplar belirsiz.

### 2.1.1 Onboarding kontrolünü bağla
`main.dart` `SharedPreferences.getBool('onboarding_completed')` okumuyor, onboarding ekranı ölü kod.

- [ ] `main.dart`'ta `runApp`'tan önce `SharedPreferences`'ı oku
- [ ] `app_router.dart`'ta `initialLocation`'ı dinamik yap ya da `redirect` ekleyerek ilk açılışta `/onboarding`'e yönlendir
- [ ] Debug için profil ekranına "Onboarding'i sıfırla" gizli butonu ekle (test etmek için)

### 2.1.2 Router'a auth redirect'i ekle
Sprint 3'te yorum yazma ekranı korumalı olmak zorunda. Altyapıyı şimdi kur.

- [ ] `app_router.dart`'a `refreshListenable` + `redirect` fonksiyonu ekle
- [ ] `authStateProvider` dinle, korumalı route listesi tanımla (yorum yazma, edit-profile gibi)
- [ ] Giriş yapılmamışken korumalı route açılırsa `/login`'e yönlendir, `extra` ile geri dönüş path'i taşı
- [ ] Giriş yapılmış kullanıcı `/login` veya `/register`'a gitmeye çalışırsa `/` ile değiştir

### 2.1.3 edu.tr doğrulama akışını düzelt
`checkAndUpdateVerification()` hiç çağrılmıyor. Bu haliyle edu.tr ile kayıt olan kimse yorum yazamaz (Sprint 3 battı).

- [ ] Uygulama her açıldığında (splash veya home ilk build'de) giriş yapılmış edu.tr kullanıcısı için `checkAndUpdateVerification` tetikle
- [ ] Profil ekranında "Doğrulama bekleniyor" durumu varsa manuel "Yenile" butonu ekle
- [ ] `authStateChanges` stream'ini dinleyen bir `AsyncNotifier` yap — `emailVerified` değişince Firestore'u güncelle
- [ ] Alternatif ve daha sağlam: Firebase Functions'ta `onUserCreated` + `onAuthStateChanged` trigger'ı yaz (Sprint 3 için kritik değil, MVP sonrası)

### 2.1.4 Auth repository retry ve fallback mantığını temizle
`signInWithGoogle`'daki catch bloğu `createdAt: DateTime.now()` ile sahte UserModel üretiyor — veri bütünlüğü riski.

- [ ] `_createOrUpdateUser`'daki retry zaten var, signInWithGoogle'daki ikinci catch'i kaldır ya da en azından Firestore yazma başarısızsa auth'tan da çıkış yap (inconsistent state önlemi)
- [ ] Hata mesajlarını kullanıcı diline çevir

---

## Sprint 2.2 — Veri Modeli ve Seed (1 gün)

Sprint 3'te yorumlar üniversiteye/bölüme bağlanacak. Modellerin eksikleri şimdi görülsün.

### 2.2.1 Seed verisindeki eksikleri tamamla
`seed_data_service.dart` bölüm template'inde `baseScore`, `ranking`, `scoreType`, `duration`, `quota` yok — ama `DepartmentModel` bekliyor, `DepartmentDetailScreen` gösteriyor. Şu an her bölüm "Taban puanı yok" gibi görünüyor.

- [ ] Her bölüm template'ine 2025 tahmini taban puan ekle (YÖK Atlas'tan manuel)
- [ ] `scoreType` ekle (Tıp→SAY, Hukuk→EA, Bilgisayar Müh→SAY vb.)
- [ ] Her üniversitede template'teki puanı ±20 aralığında random'la (seed verisi daha gerçekçi görünsün)
- [ ] `quota` alanını da ekle
- [ ] `SeedDataService`'i profil ekranında debug butonuyla çağır (production build'de gizle — `kDebugMode`)

### 2.2.2 UniversityModel'e rating alanları ekle
Şu an üniversite kartlarında `rating: 0, reviewCount: 0` hardcoded — Sprint 3 geldiğinde bu değerleri canlı güncellemek lazım.

- [ ] `UniversityModel`'e şu alanları ekle:
  - `double avgRating`
  - `int reviewCount`
  - `Map<String, double> categoryRatings` (kampüs, eğitim, sosyal, ulaşım, yemek, yurt)
- [ ] Aynısını `DepartmentModel` için de yap (eğitim kalitesi, hoca, iş imkanı, staj, ders yükü)
- [ ] Seed verisine varsayılan değerler ekle (0.0)
- [ ] Firestore'da bu alanlar olmasa `fromMap` güvenli default döndürsün (zaten öyle)

### 2.2.3 Review modelini hazırla (Sprint 3'ün bel kemiği)
Sprint 3'e geçmeden model ve repository iskeleti hazır olsun, UI'a başlarken vakit kaybetmeyelim.

- [ ] `lib/features/reviews/domain/models/review_model.dart` oluştur
- [ ] Planındaki şemaya göre alanlar: `type`, `targetId`, `universityId`, `userId`, `userName`, `userUniversity`, `rating`, `categoryRatings`, `comment`, `pros`, `cons`, `imageUrls`, `likes`, `isAnonymous`, `isApproved`, `createdAt`, `updatedAt`
- [ ] `ReviewType` enum: university, department, place
- [ ] `fromMap` / `toMap` / `copyWith`
- [ ] `lib/features/reviews/data/review_repository.dart` boş class oluştur (Sprint 3'te doldurulacak)

### 2.2.4 Ana sayfadaki mock yorum kartlarını işaretle
Şu anki `_RecentReviewCard` içinde sabit liste var — Sprint 3 başlangıcında ne yapacağını bilmek için TODO yorumu ekle.

- [ ] `_RecentReviewCard`'ın üstüne `// TODO(sprint3): Replace with ReviewRepository.getRecentReviews()` yorumu koy
- [ ] Aynısını `UniCard` kullanan her yere koy (rating: 0, reviewCount: 0 olan her yer)

---

## Sprint 2.3 — Eksik UX (1 gün)

### 2.3.1 Arama deneyimini tutarlı yap
Şu an ana sayfada arama barı var ama sadece /explore'a yönlendiriyor. Keşfet'te gerçek arama var. Bu kopukluk kullanıcıyı şaşırtır.

- [ ] Ana sayfadaki `AppSearchBar`'a tıklayınca `/explore`'a path parametresiyle git ve arama alanı otomatik focus olsun
- [ ] `ExploreScreen`'de query string'i oku, `_searchController`'a bas
- [ ] Alternatif olarak daha zarif bir çözüm: search sayfasını ayrı bir route yap (`/search`), hem anasayfadan hem keşfetten ulaşılsın

### 2.3.2 Keşfet filtrelerini genişlet
Plan "Şehir, Tür (Devlet/Vakıf), Puan türü, Puan aralığı" diyor — şu an sadece tür var.

- [ ] Şehir filtresi ekle (bottom sheet'te çoklu seçim)
- [ ] Puan türü filtresi (SAY/EA/SÖZ/DİL/TYT — bölüm seviyesinde arama gerekebilir, karmaşıklaşıyorsa MVP dışı bırak ama en azından şehir filtresi olmalı)
- [ ] Aktif filtre sayısını gösteren rozet

### 2.3.3 Popüler üniversiteler gerçekten popüler olsun
`universities.take(8)` yerine anlamlı bir sıralama.

- [ ] Şimdilik `reviewCount desc` ile sırala (henüz 0 ama altyapı hazır olsun)
- [ ] Yorum olmayınca alfabetik veya kuruluş yılına göre sırala
- [ ] Provider'ı `popularUniversitiesProvider` adıyla ayır ki sprint3'te sadece o provider değişsin

### 2.3.4 Lint uyarısını kapat
`uni_card.dart:74`'teki `if (badge != null) badge!` zaten `// ignore: use_null_aware_elements` ile bastırılmış ama daha temiz yazılabilir.

- [ ] `if (badge != null) badge!` yerine `?badge` (null-aware spread) kullan ya da koşulu bir değişkene alıp spread et
- [ ] `analysis_report.txt` dosyasını `.gitignore`'a ekle (ya da sil, build artifact)

---

## Sprint 2.4 — Favoriler (1–2 gün) — OPSİYONEL

Plan Favori'yi Sprint 4'e koymuş ama yorum sayfalarında "favoriye ekle" butonu göstermek doğal olacak. Sprint 3 öncesi yapmak işini rahatlatır. Süre sıkışırsa atla.

### 2.4.1 Favori repository ve provider
- [x] `lib/features/favorites/data/favorites_repository.dart` — `addFavorite`, `removeFavorite`, `getFavorites(userId)`
- [x] Firestore path: `users/{uid}/favorites/{uniId}` (zaten `firestore.rules`'da yazılı)
- [x] `favoritesProvider` — StreamProvider, canlı güncellensin
- [x] UserModel'deki `favorites: [uniId1, ...]` alanını denormalize mı tutayım subcollection mı — **subcollection daha doğru**, UserModel'deki alanı kaldır veya sadece count tut

### 2.4.2 Favori UI
- [x] `FavoritesScreen` — `favoritesProvider`'ı dinle, boşsa EmptyState, doluysa UniCard listesi
- [x] Üniversite detay sayfasının AppBar'ına kalp ikonu ekle (auth olmayan kullanıcıya dokununca login yönlendirmesi)
- [x] Home'daki popüler kartlara ufak kalp ikonu (opsiyonel)

---

## Bonus: Paket bakımı (30 dakika)

### Google Sign-In 7.x breaking change uyarısı
`pubspec.yaml`'da `^6.2.2` ama `.lock`'ta `6.3.0` — her an 7.x gelebilir ve `AuthRepository.signInWithGoogle` API'si değişti (artık `initialize()` + `authenticate()`).

- [x] `pubspec.yaml`'da `google_sign_in: 6.3.0` şeklinde sabitle (caret yerine kesin sürüm)
- [ ] VEYA `7.x`'e geç ve `AuthRepository`'yi yeni API'ye taşı
- [x] `flutter pub outdated` çalıştır, büyük sürüm atlayanları gözden geçir

---

## Tahmin: Sprint 2.1–2.3 = ~4 gün, 2.4 dahil ~6 gün

Eğer zaman darsa **2.1 + 2.2.3 (Review model iskeleti) + 2.2.1 (seed data düzeltmesi)** şart. Geri kalanlar Sprint 3 içinde organik olarak halledilebilir ama auth redirect'siz bir yorum sistemi yazmak çok acı verir.

## Git commit önerisi
Her alt başlığı ayrı commit yap (`feat(auth): add router redirect`, `fix(auth): update edu.tr verification flow` gibi). Sprint 2.1 biter bitmez tag at: `v0.2.1`.
