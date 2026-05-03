# Changelog

Tüm önemli değişiklikler bu dosyada belgelenir.

## [1.4.0] - 2026-05-02 — Sprint 4 v2: Hata Ayıklama & Polish

### 🆕 Yeni Özellikler
- **Profil ekranı overhaul:** Favori ve yorum stat'larına tıklama, üyelik süresi gösterimi, şifre değiştirme dialogu
- **Küfür filtresi:** Bio ve yorum alanlarında gerçek zamanlı küfür algılama (regex tabanlı, Türkçe karakter desteği)
- **Üniversite detay yenileme:** Tab yapısı kaldırıldı, tek scroll önizleme kartları (bölümler, mekanlar, yorumlar) + "Tümünü Gör" alt-rotaları
- **Favoriler ekranı yeni UI:** Dolu kalp ikonu, animasyonlu silme, 4sn undo snackbar, güzel boş state
- **Pull-to-refresh:** Üniversite detay sayfasında tüm verileri yenileyen çekme hareketi

### ⚡ Performans İyileştirmeleri
- **Logout hızlandırma:** FCM token silme fire-and-forget, navigasyon öncelikli — <200ms algılanan gecikme
- **PopularUniCard rebuild optimizasyonu:** `favoritesProvider.select()` ile sadece ilgili kart yeniden çiziliyor
- **AppShell lifecycle debounce:** Doğrulama kontrolü 5dk arayla, gereksiz Firebase çağrıları engellendi
- **PlaceCard memory fix:** AnimationController kaldırıldı → AnimatedScale ile controller-free press feedback
- **keepAlive audit:** Review/place provider'larında gereksiz keepAlive kaldırıldı, placeDetail/placeWatch 5dk timer ile otomatik dispose
- **RepaintBoundary:** Üniversite detay kartlarına eklendi — scroll performansı artırıldı
- **SeedDataService deferred import:** Debug utility'si lazy-load ile release build'de tree-shake

### 🔒 Güvenlik
- **Firestore rules sertleştirme:** `isAdmin()` artık `request.auth.token.admin == true` kontrolü yapıyor
- **Admin custom claims:** Seed data yükleme sadece admin kullanıcılarla sınırlandırıldı
- **PII koruma:** Public profilde email nullify, anonim yorumlar gizli

### 🎨 UI/UX İyileştirmeleri
- **Animasyonlar:** Üniversite detay kartlarına sequenced fade+slide animasyonları
- **Empty state'ler:** Bölüm/mekan/yorum olmayan üniversiteler için şık boş durumlar
- **Şifre değiştirme dialogu:** Firebase reauthentication destekli, validation kuralları (8 karakter, büyük harf, rakam)

### 🧹 Kod Kalitesi
- **Integration test:** Üniversite detay navigasyonu + pull-to-refresh testi
- **Dart analyze:** Sıfır hata, sıfır uyarı
- **Provider yapısı:** autoDispose + timer pattern ile bellek yönetimi iyileştirildi

---

## [1.3.0] - Sprint 3: Like Sistemi, Sort/Filter, Bildirimler

### Yeni Özellikler
- Like sistemi (optimistic reconcile pattern)
- Yorum sıralama (En Yeni / En Beğenilen)
- FCM push bildirimler
- Tüm yorumlar ekranı (filtrelenebilir)

---

## [1.2.0] - Sprint 2: Mekanlar, Yorumlar, Karşılaştırma

### Yeni Özellikler
- Mekan ekleme ve yönetimi
- Üniversite karşılaştırma
- Yorum yazma ekranı
- Fotoğraf yükleme

---

## [1.1.0] - Sprint 1: Temel Altyapı

### Yeni Özellikler
- Firebase Auth (email + Google)
- Üniversite/bölüm listeleme
- Favoriler
- Profil yönetimi
