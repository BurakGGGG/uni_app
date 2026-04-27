# 📅 Sprint 4 — Günlük Çalışma Programı

> **Süre:** 10 iş günü (2 hafta)
> **Ekip:** Kişi A + Kişi B (Sprint 3'ü beraber tamamladılar — ikinci ortak sprint)
> **Günlük aktif çalışma varsayımı:** ~5 saat
> **Hafta sonları:** İzin — planlama hafta içine göre yapıldı
> **Önceki Sürüm:** v0.3.0 (Yorum sistemi tamam, hata ayıklama bitti)
> **Hedef Sürüm:** v0.4.0 (Mekanlar veri tabanı + Karşılaştırma + Bildirimler)

---

## 📑 İçindekiler

1. [Sprint 4 Kapsam Raporu](#-sprint-4-kapsam-raporu)
2. [Yeni Mekan Veri Seti — Önemli Değişiklik](#-yeni-mekan-veri-seti--önemli-değişiklik)
3. [Sprint 3'ten Sprint 4'e Geçiş](#-sprint-3ten-sprint-4e-geçiş)
4. [Mimari Kararlar (Sprint 4'e Özel)](#-mimari-kararlar-sprint-4e-özel)
5. [Görev Bölümü: Kişi A vs Kişi B](#-görev-bölümü-kişi-a-vs-kişi-b)
6. [Başlamadan Önce: Ön Hazırlık](#-başlamadan-önce-ön-hazırlık)
7. [Günlük Ritüeller](#-günlük-ritüeller)
8. [Git Workflow Rehberi](#-git-workflow-rehberi)
9. [GÜN 1: Senkron, Veri Modeli & Üniversite Listesini Genişletme](#-gün-1-senkron-veri-modeli--üniversite-listesini-genişletme)
10. [GÜN 2: Place Repository & Seed Import Pipeline](#-gün-2-place-repository--seed-import-pipeline)
11. [GÜN 3: Place UI — Card, List, Detail](#-gün-3-place-ui--card-list-detail)
12. [GÜN 4: Checkpoint 1 & Place Yorumları](#-gün-4-checkpoint-1--place-yorumları)
13. [GÜN 5: Filtreleme & Karşılaştırma Veri Katmanı](#-gün-5-filtreleme--karşılaştırma-veri-katmanı)
14. [GÜN 6: Karşılaştırma UI Finalize & FCM Setup](#-gün-6-karşılaştırma-ui-finalize--fcm-setup)
15. [GÜN 7: Bildirim Triggers & In-App UI](#-gün-7-bildirim-triggers--in-app-ui)
16. [GÜN 8: Checkpoint 2 & Bildirim Tercihleri](#-gün-8-checkpoint-2--bildirim-tercihleri)
17. [GÜN 9: Büyük Entegrasyon & Polish](#-gün-9-büyük-entegrasyon--polish)
18. [GÜN 10: Final QA & Release](#-gün-10-final-qa--release)
19. [Blocker Protokolü](#-blocker-protokolü)
20. [Sprint 4 Sonu Retrospektifi](#-sprint-4-sonu-retrospektifi-şablon)
21. [Sprint 5'e Hazırlık](#-sprint-5e-hazırlık)
22. [Sprint 4 Özet Kart](#-sprint-4-özet-kart)
23. [Sonsöz](#-sonsöz)

---

## 📊 Sprint 4 Kapsam Raporu

Sprint 4, ÜniSeç MVP'sinin **son özellik sprinti**dir. Sonraki sprint (Sprint 5) sadece polish, beta test ve store yayınına odaklanacak. Bu yüzden bu sprint'in sonunda uygulama, son kullanıcının göreceği tüm temel özelliklere sahip olmalı.

Üç ana feature ekleyeceğiz, ama bu kez **Sprint 3'ten farklı bir başlangıç noktasındayız**: elimizde **509 mekan içeren gerçek veri seti** var (kafeler, yurtlar, kütüphaneler — 31 üniversite için Türkçe alan deneyimiyle hazırlanmış). Bu veri setinin Firebase'e doğru şekilde aktarılması Sprint 4'ün en kritik kısmı.

### Sprint 4'ün Üç Ana Feature'ı

#### 1. ☕ Mekan Sistemi (Places) — Sprint'in Omurgası

**Amaç:** Üniversitelerle ilgili kafe, yurt ve kütüphaneleri (öğrencinin günlük hayatını etkileyen mekanları) listelemek, detaylandırmak ve yorumlamak. Veri seti elimizde — bu sprint'te bu ham veriyi **işlenmiş, indekslenmiş, yorumlanabilir** bir Firestore koleksiyonuna dönüştüreceğiz.

**Kapsamlı görev listesi:**
- `Place` veri modeli ve `PlaceRepository`
- 3 mekan tipi: `cafe`, `dorm`, `library` (CSV'lerden gelen tipler)
- Mekan kartı widget'ı (`PlaceCard`)
- Üniversite detay ekranında "Mekanlar" bölümü
- Mekan detay ekranı (foto galerisi, bilgiler, harita linki, yorumlar)
- Tip ve fiyat filtresi
- Mekan yorumu yazma (`WriteReviewScreen`'in `ReviewType.place` desteği — Sprint 3'te yapı hazırdı)
- Mekan kategori puanlama (`Ortam`, `Fiyat`, `Temizlik`, `Hizmet` — `placeRatingCategories` zaten var)
- Mekan agregasyon Cloud Function
- **509 mekanlık seed data import pipeline'ı** (CSV → Firestore batch upload)
- Place için Firestore rules + indexes
- **8 yeni üniversitenin sisteme eklenmesi** (CSV setinde olup mevcut seed'de olmayanlar)
- **Kampüs yerleşimi (campus layout) alanı** (`campus`, `block`, `distributed`) — yeni veri setinden geldi

#### 2. ⚖️ Karşılaştırma Ekranı (Comparison)

**Amaç:** Kullanıcının 2 üniversiteyi yan yana, kategori puanları ve genel istatistikler bazında kıyaslayabilmesi. Mevcut placeholder ekranı (`comparison_screen.dart`) tam bir feature'a dönüştürülecek.

**Kapsamlı görev listesi:**
- Üniversite seçim mekanizması (favorilerden, son ziyaret edilenlerden veya arama ile)
- Yan yana 6 kategori puanı bar chart'ı
- Kuruluş yılı, tür (Devlet/Vakıf), kampüs yerleşimi, yorum sayısı, mekan sayısı kıyaslama
- "Hangi kategori daha iyi" görsel işaretleme (yeşil tik / fark yüzdesi)
- Genel "kazanan" özeti (kullanıcının karar vermesini kolaylaştırma)
- Karşılaştırmayı paylaşma (screenshot + share_plus)
- "Karşılaştırmayı kaydet" — favori karşılaştırmalar v2'ye

#### 3. 🔔 Push Notification Sistemi

**Amaç:** Kullanıcıyı uygulamaya geri çekmek, yorum sistemine etkileşim eklemek ve kişiselleştirilmiş içerik bildirmek.

**Kapsamlı görev listesi:**
- Firebase Cloud Messaging (FCM) entegrasyonu
- iOS ve Android push permission akışı
- FCM token kayıt ve yenileme (`users/{uid}` altında `fcmTokens` array)
- 3 bildirim tipi:
  1. **Yorumun beğenildi** — başka biri sizin yorumunuzu beğendiğinde (toplu bildirim)
  2. **Yorumun moderasyondan geçti/geçmedi** — moderation sonucu
  3. **Favorindeki üniversite yeni yorum aldı** — engagement bildirimi
- Cloud Functions: 3 yeni notification trigger fonksiyonu
- In-app notification merkezi (zil ikonu + dropdown/sheet)
- Bildirim tercihleri ekranı (her bildirim tipini açıp kapatma)
- Topic subscriptions (favori üniversite için)
- Foreground notification handler (uygulama açıkken gelen bildirim)
- Notification tıklanınca derin link

### Bu Sprint'te NEYİ YAPMAYACAĞIZ

- ❌ Google Maps tam entegrasyonu (sadece "Haritada Aç" linki yeterli)
- ❌ `study_area` ve `sports` mekan tipleri (CSV'de yok — sadece kafe/yurt/kütüphane var, modelde alan korunacak)
- ❌ Mekan rezervasyon / iletişim
- ❌ Promote edilmiş mekan altyapısı (model'de alan var ama UI yok)
- ❌ Bildirim merkezinde mark-all-read, kategori filtreleme
- ❌ Email bildirimleri
- ❌ Karşılaştırmayı kaydetme (sadece anlık, paylaşılabilir)
- ❌ Bilkent, Boğaziçi, Koç, Sabancı, Yaşar, İYTE, İstanbul Bilgi: bu üniversiteler için CSV verisi yok — Sprint 4'te mekan listesi boş kalacak (UI "Henüz mekan eklenmedi" diyecek), Sprint 5'te tek tek doldurulacak

### Sprint 4 Sonu — "Definition of Done"

| Özellik | Tamamlanma Kriteri |
|---------|---------------------|
| Place seed import | 509 mekan Firestore'da doğru yapıda, üniversiteleriyle linked |
| Üni listesi genişletme | 31 üni mevcut + 8 yeni = 39 üni `universities` koleksiyonunda |
| Place sistemi | Bir kullanıcı uni detayında "Mekanlar" tab'ında 5+ mekan görür, birine tıklar, detayını + yorumlarını görür, kendi yorumunu yazabilir |
| Place yorum agregasyonu | Mekan kartında `avgRating` ve `reviewCount` 5sn içinde günceller |
| Mekan filtreleme | Tip ve fiyat filtresi sonuç listesini canlı günceller |
| Karşılaştırma | Favorilerinden 2 uni seçer, kategori barlarını yan yana görür, ekran görüntüsünü paylaşır |
| FCM push | Test cihazında bir başkasının yorumumu beğenmesi sonucu push bildirimi gelir, tıklayınca yorum sayfasına gider |
| In-app bildirim | Zil ikonunda son 10 bildirim görünür, tıklayınca okundu olarak işaretlenir |
| Bildirim tercihleri | Profilde "Bildirim Ayarları" ekranı, her tip için açık/kapalı toggle çalışır |
| Production-ready | `flutter analyze` 0 warning, ana akışlarda crash yok, edge case test edildi |

### Risk Tahmini ve Önlemler

| Risk | Olasılık | Etki | Önlem |
|------|----------|------|-------|
| FCM iOS APNs sertifikası gecikir | Orta | Yüksek | Gün 5'te APNs key al — yoksa Android-only ile yayınla, iOS Sprint 5'te bitsin |
| Seed import edge case'leri (CSV format farkı) | Orta | Orta | Gün 1 sonunda parser'ı doğrula, header varyantlarını manuel test et |
| Cloud Function quota aşılır (notifications) | Düşük | Orta | Pull-batched bildirimler (5dk içinde gelen 3+ like'ı tek bildirim yap) |
| Karşılaştırma ekranı tasarım karmaşıklaşır | Orta | Düşük | Gün 5 sabahı API kontratı yazılı netleştir |
| Bildirim deep link Android/iOS uyumsuzluğu | Orta | Orta | GoRouter ile path standardize et, tek handler |
| Yeni 8 üni için `cityId` yanlış set edilir | Düşük | Orta | Gün 1 sonunda Firestore Console'da manuel check |
| `marmara`, `medipol` gibi sık karşılaşan üni isimleri ID conflict | Düşük | Düşük | ID'leri Gün 1'de finalize et, doc'a yaz |

### Sprint Boyunca Hangi Dosyalar Değişecek?

**Yeni dosyalar (~30 dosya):**
```
lib/features/places/
├── data/
│   └── place_repository.dart
├── domain/
│   └── models/
│       └── place_model.dart
└── presentation/
    ├── providers/
    │   ├── place_providers.dart
    │   └── place_filter_provider.dart
    ├── screens/
    │   ├── place_detail_screen.dart
    │   └── place_filter_sheet.dart
    └── widgets/
        ├── place_card.dart
        ├── place_list.dart
        ├── place_type_chip.dart
        ├── place_amenities_grid.dart
        └── dorm_info_card.dart   ← KYK/Özel + Kız/Erkek/Karma için özel kart

lib/features/comparison/
├── data/
│   └── comparison_repository.dart
├── domain/
│   └── models/
│       └── comparison_result.dart
└── presentation/
    ├── providers/
    │   └── comparison_providers.dart
    ├── widgets/
    │   ├── comparison_uni_picker.dart
    │   ├── comparison_header.dart
    │   ├── comparison_category_row.dart
    │   ├── comparison_stats_table.dart
    │   └── comparison_share_card.dart
    └── (mevcut comparison_screen.dart yeniden yazılacak)

lib/features/notifications/
├── data/
│   ├── notification_repository.dart
│   └── fcm_service.dart
├── domain/
│   ├── models/
│   │   └── app_notification.dart
│   └── enums/
│       └── notification_type.dart
└── presentation/
    ├── providers/
    │   ├── notification_providers.dart
    │   └── notification_preferences_provider.dart
    ├── screens/
    │   ├── notification_center_screen.dart
    │   └── notification_settings_screen.dart
    └── widgets/
        ├── notification_bell.dart
        └── notification_tile.dart

lib/scripts/
├── places_seed_data.dart       ← Generated by build script (büyük JSON)
└── extra_universities_seed.dart ← 8 yeni uni için seed

functions/src/
├── notifications/
│   ├── on_review_liked.ts
│   ├── on_review_moderated.ts
│   └── on_new_review_for_favorite.ts
└── places/
    └── aggregate_place_ratings.ts

assets/data/                     ← YENİ klasör — opsiyonel, JSON'u asset olarak embed etmek için
└── places_seed.json
```

**Değişecek mevcut dosyalar:**
```
lib/features/university/domain/models/university_model.dart  (campusLayout alanı eklenecek)
lib/features/university/presentation/screens/university_detail_screen.dart  (Mekanlar bölümü)
lib/features/comparison/presentation/screens/comparison_screen.dart  (Tamamen yeniden yazılacak)
lib/features/reviews/presentation/screens/write_review_screen.dart  (Place type validation)
lib/features/reviews/data/review_repository.dart  (getPlaceReviews metodu)
lib/features/reviews/presentation/providers/review_providers.dart  (placeReviewsProvider, sortedReviewsProvider place desteği)
lib/features/profile/presentation/screens/profile_screen.dart  (Bildirim ayarları menüsü)
lib/features/auth/domain/user_model.dart  (fcmTokens, notificationPrefs)
lib/features/auth/data/auth_repository.dart  (FCM token register)
lib/features/home/presentation/screens/home_screen.dart  (Notification bell)
lib/router/app_router.dart  (5+ yeni route)
lib/main.dart  (FCM init, deep link handler)
lib/scripts/seed_data_service.dart  (Place seed integration + 8 yeni uni)
lib/core/constants/app_constants.dart  (Yeni amenity tag listeleri, place pros/cons)
firestore.rules  (places, notifications koleksiyonları)
firestore.indexes.json  (place ve notification için yeni index'ler)
functions/src/index.ts  (yeni export'lar)
functions/package.json  (yeni dependencies muhtemelen)
pubspec.yaml  (firebase_messaging, flutter_local_notifications, screenshot, share_plus)
```

**Tahmini commit sayısı:** 100-130
**Tahmini PR sayısı:** 10-14

---

## 🆕 Yeni Mekan Veri Seti — Önemli Değişiklik

Sprint 4'e başlarken **509 mekanlık** gerçek veri seti elinizde:

```
Toplam 509 mekan
├── 196 Kafe
├── 178 Yurt
└── 135 Kütüphane

31 üniversite kapsanıyor
├── Mevcut seed'de olan: 23 üni
└── Yeni eklenecek: 8 üni (marmara, hacibayram, izmir_demokrasi, izmir_katipcelebi, aydin, gelisim, medipol, hitit)
```

### Veri Setinin Yapısı

ZIP içinde her üniversite şu klasör hiyerarşisinde:
```
{ŞEHİR}/{TÜR}/{YERLEŞİM}/{ÜNİVERSİTE_ADI}/
├── kafeler   (CSV)
├── yurtlar   (CSV)
└── kütüphaneler   (CSV)
```

**Önemli özellikler:**
- **Şehir:** İstanbul, Ankara, İzmir, Antalya, Eskişehir, Bursa, Çanakkale, Sivas, Trabzon, Mersin, **Çorum** (yeni — Hitit Üni için)
- **Tür:** DEVLET, VAKIF
- **Yerleşim (Campus Layout):** `KAMPÜSLÜ`, `BLOK YERLEŞKE`, `DAĞINIK KAMPÜS` — bu Sprint 4'te `UniversityModel`'e yeni alan olarak eklenecek

### CSV Header Varyasyonları (Önemli — parser'da handle edilecek)

**Kafeler (3 varyant):**
- `Kafe Adı,Google Puanı,Konum,Neden Seçmelisin?,Fiyat Seviyesi`
- `Kafe Adı,Google Puanı,Konum,Neden Seçmelisin?,Fiyat`
- `Kafe Adı,Google Puanı,Konum / Yakınlık,Öne Çıkan Özellikler,Fiyat Seviyesi`

**Yurtlar (4 varyant):**
- `Yurt Adı,Tür,Kontenjan Tipi,Kampüse Yakınlık / Ulaşım`
- `Yurt Adı,Tür,Kontenjan Tipi,Üniversiteye Mesafe / Ulaşım`
- `Yurt Adı,Tür,Kontenjan,Kampüse Yakınlık`
- `Yurt Adı,Tür,Kontenjan,Kampüse Yakınlık / Ulaşım`

**Kütüphaneler (2 varyant):**
- `Kütüphane Adı,Tür,Konum,Çalışma Saatleri,Ders Çalışmaya Uygunluk`
- `Kütüphane Adı,Konfor,Sessizlik,Yer Bulma Zorluğu,Saat`

> [!IMPORTANT]
> Parser bu header varyasyonlarının hepsini handle etmeli. Tek bir kanonik veri yapısına dönüştürmek için sabit bir mapping katmanı olmalı.

### Bu Veri Setinin Sprint 4'e Etkisi

1. **Place seed data manuel oluşturmaya gerek yok** — gerçek veri var. Sprint 3'te uniler ve bölümler için yaptığınız seed pattern'ini buraya uygulayacaksınız.
2. **`UniversityModel`'e `campusLayout` alanı ekleniyor** — bu yeni bir UI özelliği (üni detayında "Kampüslü" / "Dağınık Kampüs" / "Blok Yerleşke" rozeti) ve **karşılaştırma ekranında** gösterilecek bir özellik.
3. **8 yeni üniversite** mevcut seed listesine eklenecek — bunların `cities` koleksiyonundaki şehir count'ları da güncellenecek.
4. **Çorum şehri yeni eklenecek** (Hitit Üni için).
5. **Boğaziçi, Koç, Sabancı, Bilkent, Yaşar, İYTE, Bilgi** için CSV'de mekan verisi yok — bu uniler kalacak ama "Henüz mekan eklenmedi" empty state'i gösterecek. Sprint 5'te bu uniler için manuel veri girişi yapılacak.

### Veri Setinden Türetilebilen Önemli Bilgiler

**Yurt verisinde:**
- `Tür` alanı: `KYK`, `KYK (Devlet)`, `Özel`
- `Kontenjan Tipi`: `Kız`, `Erkek`, `Karma`
- → `amenities` array'ine otomatik dönüşüm: `["KYK", "Kız Yurdu"]`

**Kafe verisinde:**
- `Google Puanı`: 4.0 - 4.7 arası gerçek değerler → `externalRating` alanı (kullanıcı yorumlarından ayrı, "Google'da 4.5" şeklinde gösterilecek)
- `Fiyat Seviyesi`: `Çok Ekonomik`, `Ekonomik`, `Orta`, `Orta-Üst`, `Üst` → standart `₺/₺₺/₺₺₺` formatına normalize

**Kütüphane verisinde:**
- `Tür`: `Üniversite`, `Devlet` → `amenities`'e
- `Konfor`, `Sessizlik`, `Yer Bulma Zorluğu` (alternatif format) → açıklamaya birleştirilir

---

## 🔄 Sprint 3'ten Sprint 4'e Geçiş

Sprint 3'ü tamamladınız ve hata ayıklamasını yaptınız. Bu, Sprint 4 için size üç önemli avantaj kazandırdı:

### 1. Sprint 3'ten Taşınan Altyapı

**Yorum sistemi `ReviewType.place`'i zaten destekliyor.** `review_model.dart`'ta:
```dart
enum ReviewType {
  university,
  department,
  place,      // ← Hazır, Sprint 4'te aktif olacak
}
```

Ve `app_constants.dart`'ta zaten var:
```dart
static const List<String> placeRatingCategories = [
  'Ortam', 'Fiyat', 'Temizlik', 'Hizmet',
];
```

Sprint 4'ü inanılmaz hızlandırıyor — yorum yazma/listeleme/silme/like/şikayet hepsi place için de çalışacak. Sadece `WriteReviewScreen`'in `_categories` getter'ında bir `else if` daha eklemek yeterli.

**`ReviewCard` widget'ı generic.** Place yorumları aynı kartla render edilecek — değişiklik yok.

**Cloud Function pattern'i kurulu.** `aggregateUniversityRatings` ve `moderateNewReview` zaten çalışıyor. Yeni place aggregator ve 3 notification trigger aynı pattern'i izleyecek.

**Cache pattern'i mevcut.** `UniversityRepository`'deki 5 dakika TTL'li cache `PlaceRepository`'de aynen tekrar edilecek.

**Optimistic UI pattern'i.** `LikeController`'daki reconcile pattern'i FCM token register ve notification mark-as-read için kullanılacak.

### 2. Sprint 3'te Öğrenilen Dersler

Sprint 3 retrospektifinden tipik notlar:

- **API kontratını günü bir yazmak hayat kurtarıyor.** Sprint 3'te `ReviewCard` API'sini Gün 1'de yazılı finalize etmiştiniz — Sprint 4'te aynı şeyi `PlaceCard`, `ComparisonResult` ve `AppNotification` için yapacaksınız.
- **Cloud Function deploy ilk seferde sancılıdır.** Sprint 4'te 4 yeni function var — tek tek değil, batch deploy edin.
- **Foto upload akışı sıralaması kritik.** Önce Storage'a yükle, URL al, sonra Firestore'a yaz.
- **`flutter analyze`'ı her gün koşturun.** Her akşam, push'tan önce.

### 3. İkinci Birlikte Sprint — Daha Hızlı Olmalı

Sprint 3'te ilk kez beraber çalışıyordunuz. Şimdi:
- ✅ Birbirinizin kod yazma stilini biliyorsunuz
- ✅ Git workflow'u oturmuş
- ✅ Standup ritüeli alışkanlık
- ✅ Hangi alanlarda kim güçlü öğrendiniz

Sprint 4'te daha cesur paralel çalışma, daha az merge conflict, daha az "ben ne yapacaktım?" momenti hedefleyin.

---

## 🏗️ Mimari Kararlar (Sprint 4'e Özel)

Sprint başlamadan önce ortak karar gerektiren şeyler. Gün 1 toplantısında konuşulacak ama önceden okumakta fayda var:

### Karar 1: Places Top-Level mi Subcollection mı?

`implementation_planv1.md`'de places `universities/{uniId}/places/{placeId}` subcollection olarak tasarlanmıştı. Ama yorum sisteminde `reviews` top-level collection kullandığınız için tutarlılık adına places de top-level olmalı.

**Karar:** `places/{placeId}` top-level, içeride `universityId` alanı.

**Gerekçe:**
- Top-level query'ler subcollection'a göre daha basit (collection group query gerekmez)
- Cross-university place listesi (örn. "İstanbul'daki tüm kafeler") subcollection'da imkansızdır — Sprint 5'te eklenecek
- Yorum sistemiyle tutarlılık sağlar

### Karar 2: Place Yorumlarında `targetId` Ne Olacak?

Yorum modeli:
```dart
class ReviewModel {
  final ReviewType type;
  final String targetId;       // bu yorumun hedef objesi
  final String universityId;   // her durumda bağlı uni
  // ...
}
```

Place yorumu için: `targetId = placeId`, `universityId = place.universityId`.

**Yeni metod gerekecek** (Gün 2'de yazılacak):
```dart
Stream<ReviewModel>> getPlaceReviews(String placeId, {...});
```

### Karar 3: `UniversityModel`'e `campusLayout` Alanı

Yeni veri setinde `KAMPÜSLÜ`, `BLOK YERLEŞKE`, `DAĞINIK KAMPÜS` bilgisi var. Bu Sprint 4'te:
- `UniversityModel`'e yeni alan: `final CampusLayout campusLayout`
- 3 değer: `campus`, `block`, `distributed`
- UI'da rozet olarak gösterilecek (Sprint 3'teki `Devlet/Vakıf` rozetinin yanına)
- Karşılaştırma ekranında bir kıyaslama metriği

**Backward compatibility:** Mevcut Firestore doc'larında bu alan yok. Default `campus` olacak (`hasCampus: true` olanlar zaten `campus` sayılır). Migration gerekecek — Gün 1'de.

### Karar 4: Mekan Veri Tipi (`PlaceType`) Sadeleştirme

Implementation plan'da 5 tip vardı: `cafe`, `dorm`, `study_area`, `library`, `sports`. Ama elimizdeki veri sadece `cafe`, `dorm`, `library` içeriyor.

**Karar:**
- `PlaceType` enum'una 5 değeri de bırak (gelecek için)
- Sprint 4'te sadece `cafe`, `dorm`, `library` aktif (filter'da görünür)
- `study_area` ve `sports` UI'da görünmeyecek ama model destekleyecek (Sprint 5'te seed eklenebilir)

### Karar 5: Karşılaştırma Anlık mı, Kayıtlı mı?

İki seçenek:
- **A) Anlık hesaplama:** Her açılışta iki üni doc'unu çek, kategori karşılaştır
- **B) Kayıtlı:** `comparisons/{userId}/saved/{compId}` ile favoriye ekle

**Karar:** MVP için **(A) — anlık hesaplama**. Kayıtlı karşılaştırma v2'ye. Ama `ComparisonResult` modeli serializable olsun, gelecekte (B)'ye geçişe açık.

### Karar 6: Bildirim Topic vs Direct Send

FCM'de bildirim göndermenin iki yolu var:
- **Topic-based:** Kullanıcı `favori_uni_odtu` topic'ine subscribe → ODTÜ'ye yorum gelince herkes bildirim alır
- **Direct (token-based):** Cloud Function her user'a tek tek gönderir

**Karar — Hibrit:**
- Topic-based: "Favorindeki üniversite yeni yorum aldı" (kullanıcı favoriye eklerken `topic_uni_<uniId>`'ye subscribe olur)
- Direct: "Yorumun beğenildi" / "Yorumun moderasyondan geçti" — hedef-spesifik

### Karar 7: Bildirim Storage

Push bildirimler FCM ile gönderiliyor ama in-app notification merkezi için Firestore'da saklamalıyız. Yapı:

```
notifications/{notifId}
├── userId: "abc123"
├── type: "review_liked" | "review_moderated" | "favorite_new_review"
├── title: "Yorumun beğenildi 🎉"
├── body: "Ahmet ve 2 kişi daha yorumunuzu beğendi"
├── data: {                       // deep link için
│   ├── route: "/university/odtu",
│   └── reviewId: "xyz",
│   }
├── isRead: false
├── createdAt: Timestamp
└── expireAt: Timestamp           // 90 gün TTL
```

Cloud Function hem FCM push gönderir hem Firestore'a notification doc yazar. In-app merkezi Firestore'dan okur.

> [!NOTE]
> Sprint 4 sonunda `expireAt` TTL ile otomatik silme nice-to-have, eğer Gün 9-10'da zaman varsa eklenir. Yoksa Sprint 5'e itilir.

### Karar 8: Map Integration

`google_maps_flutter` Sprint 4'te **kapsam dışı**. Place detayında "Haritada Aç" butonu `url_launcher` ile Google Maps app'ini açar. Full embed Sprint 5'e.

```dart
final mapUrl = 'https://www.google.com/maps/search/${Uri.encodeComponent("${place.name} ${place.address}")}';
launchUrl(Uri.parse(mapUrl), mode: LaunchMode.externalApplication);
```

### Karar 9: External Rating (Google Puanı)

CSV'lerde kafelerin `Google Puanı` var (4.0-4.7). Bu kullanıcı yorumlarından **ayrı** bir bilgi.

**Karar:**
- `PlaceModel`'a `externalRating` (double?) ve `externalRatingSource` (string? — "google", "tripadvisor" vs) alanları
- UI'da küçük bir rozet: "Google: ⭐4.5"
- `avgRating` ile karıştırılmaz (avgRating = ÜniSeç kullanıcı yorumları)

---

## 👥 Görev Bölümü: Kişi A vs Kişi B

Sprint 3'teki ayrım korunuyor:

### 🔧 Kişi A — "Veri & Backend & Yazma Akışları"

**Sorumluluk alanı:**
- Place domain modeli ve repository
- Place seed import pipeline (CSV → Firestore)
- 8 yeni üniversitenin seed'e eklenmesi + Çorum şehri
- `UniversityModel`'a `campusLayout` migration
- Place yazma (form genişletme — `WriteReviewScreen`)
- Cloud Functions (3 notification trigger + 1 place aggregator)
- FCM service (token register, refresh, topic subscribe/unsubscribe)
- Comparison logic (data fetching, kategori karşılaştırma algoritması)
- Notification repository (CRUD, mark as read)
- Firestore rules + indexes güncellemeleri

**Sprint 4 boyunca yazacağı dosyalar (tahmini):**
```
lib/features/places/data/place_repository.dart
lib/features/places/domain/models/place_model.dart
lib/features/comparison/data/comparison_repository.dart
lib/features/comparison/domain/models/comparison_result.dart
lib/features/notifications/data/notification_repository.dart
lib/features/notifications/data/fcm_service.dart
lib/features/notifications/domain/models/app_notification.dart
lib/features/notifications/domain/enums/notification_type.dart
lib/features/places/presentation/providers/place_providers.dart
lib/features/comparison/presentation/providers/comparison_providers.dart
lib/features/notifications/presentation/providers/notification_providers.dart
lib/features/notifications/presentation/providers/notification_preferences_provider.dart
lib/scripts/places_seed_data.dart
lib/scripts/extra_universities_seed.dart
functions/src/notifications/on_review_liked.ts
functions/src/notifications/on_review_moderated.ts
functions/src/notifications/on_new_review_for_favorite.ts
functions/src/places/aggregate_place_ratings.ts
firestore.rules (places + notifications kuralları)
firestore.indexes.json
```

### 🎨 Kişi B — "UI & Görüntüleme & Etkileşim"

**Sorumluluk alanı:**
- `PlaceCard` widget'ı (mekan kartı)
- `PlaceList` widget'ı (filtre destekli liste)
- Place detay ekranı (foto galerisi, bilgiler, yorumlar)
- `DormInfoCard` widget'ı (KYK/Özel + Kız/Erkek için özel düzen)
- `PlaceAmenitiesGrid` widget'ı
- Üniversite detay ekranına "Mekanlar" entegrasyonu
- Place filtre sheet (tip, fiyat, özellikler)
- Comparison ekran UI (uni picker, header, kategori row, stats table)
- Comparison share card için screenshot widget'ı
- Notification bell widget (zil ikonu + badge)
- Notification center screen (in-app bildirim merkezi)
- Notification settings screen (tercihler)
- FCM foreground listener UI handler
- Üniversite kartı/detayında campusLayout rozeti

**Sprint 4 boyunca yazacağı dosyalar (tahmini):**
```
lib/features/places/presentation/widgets/place_card.dart
lib/features/places/presentation/widgets/place_list.dart
lib/features/places/presentation/widgets/place_type_chip.dart
lib/features/places/presentation/widgets/place_amenities_grid.dart
lib/features/places/presentation/widgets/dorm_info_card.dart
lib/features/places/presentation/screens/place_detail_screen.dart
lib/features/places/presentation/screens/place_filter_sheet.dart
lib/features/places/presentation/providers/place_filter_provider.dart
lib/features/comparison/presentation/screens/comparison_screen.dart (yeniden yazılacak)
lib/features/comparison/presentation/widgets/comparison_uni_picker.dart
lib/features/comparison/presentation/widgets/comparison_header.dart
lib/features/comparison/presentation/widgets/comparison_category_row.dart
lib/features/comparison/presentation/widgets/comparison_stats_table.dart
lib/features/comparison/presentation/widgets/comparison_share_card.dart
lib/features/notifications/presentation/widgets/notification_bell.dart
lib/features/notifications/presentation/widgets/notification_tile.dart
lib/features/notifications/presentation/screens/notification_center_screen.dart
lib/features/notifications/presentation/screens/notification_settings_screen.dart
```

### Ortak Çalışılacak Dosyalar (Pair Programming Önerilir)

| Dosya | Kim Önce Dokunur? | Nasıl Yönetilir? |
|-------|-------------------|------------------|
| `lib/router/app_router.dart` | Kişi B (UI route'ları çoğunluk) | Kişi A FCM deep link route'unu Kişi B'nin merge'inden sonra ekler |
| `lib/main.dart` | Kişi A (FCM init) | Kişi B Notification UI initialization'ı bunun üstüne ekler |
| `pubspec.yaml` | Kişi A önce (firebase_messaging) | Sonra Kişi B (screenshot, share_plus) |
| `lib/features/auth/domain/user_model.dart` | Kişi A (`fcmTokens`, `notificationPrefs`) | Tek dokunuş, akşam push |
| `lib/features/reviews/presentation/screens/write_review_screen.dart` | Kişi A (place validation) | Hassas dosya — sabah anlaş |
| `lib/features/university/domain/models/university_model.dart` | Kişi A (`campusLayout`) | Tek dokunuş, Gün 1 |
| `lib/features/university/presentation/screens/university_detail_screen.dart` | Kişi B (Mekanlar bölümü) | Kişi A buraya değişiklik yapacaksa haber versin |
| `lib/scripts/seed_data_service.dart` | Kişi A | Tek dokunuş, ama büyük |
| `lib/core/constants/app_constants.dart` | İkisi de eklenebilir | Sabah uyumla, ortada görüş |

> [!IMPORTANT]
> **Conflict önleme:** Sabah standupta hangi ortak dosyalara dokunacağınızı söyleyin. Aynı gün ikiniz de aynı dosyaya dokunmayın.

### Görev Bağımlılıkları (Dependency Graph)

```
Day 1: Place model (A) ────────► Day 2: Place repository (A) ──► Day 3: Place card (B)
                                              └─► Day 2: Place seed import (A)
                                              
Day 1: campusLayout migration (A) ────────► Day 1: UI rozet (B)

Day 2: Place repository (A) ────► Day 3: Place detail screen (B)
                          └─────► Day 4: Place agg. function (A)

Day 3: Place card (B) ────► Day 3: Üni detayında "Mekanlar" (B)

Day 4: Place review yazma (A) ──► Day 4: Checkpoint 1

Day 5: Comparison logic (A) ────► Day 5: Comparison UI iskelet (B)
                          └────► Day 6: Comparison finalize (B)

Day 6: FCM service (A) ────────► Day 7: Bell + center UI (B)

Day 7: Notification triggers (A) ► Day 7: Notification tile UI (B)

Day 8: Checkpoint 2

Day 9: Polish + nice-to-haves
Day 10: Release
```


---

## 🎬 Başlamadan Önce: Ön Hazırlık

> [!IMPORTANT]
> Bu bölümü Sprint'e başlamadan bir gün önce ya da ilk günün sabahında **ikiniz birlikte** yapın. ~1.5 saat sürer (Sprint 3'ten daha uzun, çünkü FCM kurulumu + veri seti hazırlığı var).

### 1. Sprint 3'ün Kapandığını Doğrulayın

- [ ] `develop` branch'inde son halinde Sprint 3 özellikleri çalışıyor
- [ ] `main` branch'i `v0.3.0` tag'ini içeriyor
- [ ] Açık kalmış kritik bug var mı? Varsa GitHub Issue'da görünür mü?
- [ ] `flutter analyze` çıktısında 0 warning, 0 error
- [ ] Sprint 3 retrospektif notlarınız erişilebilir bir yerde

Eksik varsa Sprint 4'e başlamadan **önce** bir gün ayırıp toparlayın.

### 2. Geliştirme Ortamını Senkronize Edin

```bash
# Flutter sürüm kontrolü
flutter --version  # Aynı, Flutter 3.x stable

# Firebase CLI
firebase --version  # En az 13.x

# Node (Cloud Functions için)
node --version  # En az 20.x

# Python (CSV parse için, sadece bir kez kullanılacak)
python3 --version  # En az 3.10

# YENİ: Xcode (iOS push için, sadece macOS'ta)
xcodebuild -version  # En az 15.x

# YENİ: CocoaPods (iOS için)
pod --version  # En az 1.14.x
```

> [!WARNING]
> **iOS Push Notifications için Apple Developer Account zorunlu.** APNs sertifikası alabilmek için $99/yıl Apple Developer hesabı lazım. Hesap yoksa Sprint 4'te iOS push'unu **kapsam dışı** bırakın, Android'le ilerleyin. Bu kararı Gün 1 sabahında net olarak alın.

### 3. Mekan Veri Setini Hazırlayın

İndirilen ZIP dosyasını projenin köküne çıkarın:

```bash
cd <proje_root>
mkdir -p data/raw
unzip ~/Downloads/unisec_üniversiteler.zip -d data/raw/
ls data/raw/  # 11 şehir görmelisiniz
```

> [!NOTE]
> `data/raw/` klasörünü `.gitignore`'a ekleyin — ham CSV'leri repo'da tutmaya gerek yok, ama yerelde tutulsun. Parse edilmiş JSON sonucu repoya gidecek.

```gitignore
# .gitignore'a ekle
/data/raw/
```

### 4. Firebase Console'da Hazırlık

İkiniz birlikte Firebase Console'a girin (`unisec-e36e1`):

**a) Cloud Messaging (FCM) Aktivasyonu**
- Console → Project Settings → Cloud Messaging
- Web Push certificates yükle
- Android: Otomatik aktif
- iOS: APNs Authentication Key veya Certificate (Apple Dev hesabı varsa)

**b) Firestore Indexes Hazırlığı**
Sprint 4'te eklenecek index'ler için Console'da yer ayırın (Sprint 4 boyunca tetiklenecek):
- `places`: `universityId + type + avgRating DESC`
- `places`: `universityId + avgRating DESC`
- `places`: `universityId + promotionPriority DESC + avgRating DESC`
- `notifications`: `userId + isRead + createdAt DESC`
- `notifications`: `userId + createdAt DESC`

**c) Cloud Functions Quota Kontrolü**
Spark plan (free) bildirim göndermek için yeterli. Eğer Spark'tasınız Sprint 4'te quota'yı izleyin.

### 5. Yeni Paketleri pubspec.yaml'a Ekleyin

```yaml
dependencies:
  # Mevcut paketler aynı...
  
  # YENİ — Sprint 4
  firebase_messaging: ^15.1.3        # FCM
  flutter_local_notifications: ^17.2.3  # Foreground notifications
  screenshot: ^3.0.0                 # Comparison share
  share_plus: ^10.0.2                # Karşılaştırma paylaşma
  permission_handler: ^11.3.1        # Notification permission
```

```bash
flutter pub get
cd ios && pod install && cd ..
```

> [!TIP]
> Bu paketleri Gün 1'de hep birden eklemeyin. `firebase_messaging` ve `flutter_local_notifications` Gün 6'da, `screenshot` ve `share_plus` Gün 5'te ekleyin. Erken ekleme = erken iOS pod install hatası riski.

### 6. Branch'leri Kurun

```bash
git checkout main
git pull
git checkout develop
git pull
git checkout -b feat/sprint4-data-backend  # Kişi A
# veya
git checkout -b feat/sprint4-ui-views      # Kişi B
git push -u origin feat/sprint4-data-backend  # ya da -ui-views
```

### 7. Rolleri Sesli Onaylayın

```
Kişi A: "Ben veri ve backend yapıyorum — places repo, place seed import,
        comparison logic, FCM service, Cloud Functions, place yazma akışı,
        8 yeni üni eklenmesi"
Kişi B: "Ben UI ve görüntüleme yapıyorum — place card/detail, comparison ekran,
        notification bell/center, ayar ekranları, campusLayout UI rozeti"
İkisi:  "Ortak dosyalarda sabah anlaşacağız."
```

### 8. Sprint 4 Plan Dosyasını İkiniz de Okuyun

Sorularınızı not edin, Gün 1 sabahında 30dk konuşun.

---

## 🔁 Günlük Ritüeller

### Sabah: Standup (10-15 dakika)

Video açın, sırayla 4 soru:
1. **Dün ne bitirdim?** (somut: "place_repository.dart yazıldı, 3 metod tamam")
2. **Bugün ne yapmayı planlıyorum?** (en az 2-3 task ismi)
3. **Önüme çıkan engel var mı?**
4. **Bugün ortak dosyaya dokunacak mıyım?** (conflict önleme — Sprint 3'te yoktu, Sprint 4'te ekledik)

### Öğlen: Kısa Kontrol (Slack/WhatsApp, opsiyonel)

Blocker varsa veya bir şeyin partnerini etkileyeceği fark edildiyse:
> "Kişi A, place_repository.dart'a `getPlacesByCity` ekliyorum. City detayı ekranında bunu kullanacaksan API'ye birlikte bakalım."

### Akşam: Sync & Merge (25-35 dakika)

Sprint 4'te bu daha kritik:

1. **Her iki kişi push** (her gün, her zaman)
2. **Demo time (10dk):** Bugün ne bitti? Ekran paylaşımı şart
3. **Code review (10dk):** Ufak PR'ları açıp karşılıklı yorum
4. **Merge to develop (5dk):** Yeşil ışık varsa merge
5. **Yarın planı (5dk):** Somut hedefler

### Cuma Akşamı (Hafta sonu öncesi): Mini Retrospektif

Hafta sonunda 20dk konuşun:
- Bu hafta neyi öğrendik?
- Sonraki haftaya hangi süreçleri taşıyalım?
- Çıkan bir sürpriz var mı?

---

## 🌿 Git Workflow Rehberi

### Branch Yapısı (Sprint 4)

```
main                                ← v0.3.0 tagged
└── develop                         ← sprint integration branch
    ├── feat/sprint4-data-backend   ← Kişi A
    └── feat/sprint4-ui-views       ← Kişi B
```

### Sabah:
```bash
git checkout feat/sprint4-data-backend  # veya ui-views
git fetch origin
git merge origin/develop
# Conflict varsa partner ile birlikte çöz
```

### Gün İçi:
```bash
git add <dosya>
git commit -m "feat: add place_repository with type filter"
# Commit prefix: feat / fix / refactor / docs / test / chore
```

### Akşam:
```bash
git push origin feat/sprint4-data-backend
# GitHub'da PR aç → develop
# Partnerinden 5dk review iste, merge
```

### Conflict Önleme

1. **Sabah ortak dosya bildirimi yap.** Hangi ortak dosyaya dokunacaksın?
2. **Atomic commits.** Bir özellik, bir commit.
3. **Küçük PR'lar.** 500 satırdan büyük PR açma.
4. **Erken merge.** Bir parça biter bitmez develop'a, çok beklemeden.

### PR Şablonu

```markdown
## Ne Değişti?
[1-2 cümle]

## Hangi Sprint Görevi?
- [ ] Task A1 / B2 / vs.

## Test Edildi Mi?
- [ ] Local'de manuel test ✅
- [ ] flutter analyze ✅
- [ ] (Cloud Function değişti ise) Console'dan test ✅

## Reviewer Dikkat Etmeli
[Hassas bir nokta varsa belirt]

## Ekran Görüntüsü (UI değişti ise)
[Screenshot]
```

---


## 📆 GÜN 1: Senkron, Veri Modeli & Üniversite Listesini Genişletme

> **Hedef:** Sprint 3 retrospektifi yapıldı, Place model + repository iskeleti hazır, API kontratları yazılı, `UniversityModel`'e `campusLayout` eklendi, 8 yeni üni + Çorum şehri seed'e eklendi, ilk küçük PR merge edildi.

### 🌅 Sabah — Birlikte (3 saat)

Bugün Sprint 4'ün en uzun ortak günü. Ekran paylaşımıyla çalışın.

**1. Sprint 3 Retrospektif Hatırlatma (15dk)**

Sprint 3'ü kapatırken aldığınız notları açın. Şunları konuşun:
- Sprint 3'te en iyi giden 3 şey neydi?
- Sprint 3'te en kötü giden 2 şey neydi?
- "Sonraki sprint için ne değişsin?" notunda yazılı önerileri Sprint 4'te uygulayacağınızı söyleyin.

**2. Sprint 4 Kapsam Toplantısı (45dk)**

Bu dosyanın **"Sprint 4 Kapsam Raporu"** ve **"Yeni Mekan Veri Seti"** bölümlerini birlikte okuyun. Soruları not edin, birlikte cevaplayın. Üç ana feature için zihinsel resim oluşsun.

Bunlar net olsun:
- ✅ Mekanlar (places) ne zaman bitiyor? → Gün 4 sonu
- ✅ Karşılaştırma ne zaman bitiyor? → Gün 6 sonu
- ✅ Bildirimler ne zaman bitiyor? → Gün 8 sonu
- ✅ 509 mekan import ne zaman? → Gün 2 öğleden sonra

**3. API Kontratları Finalize (45dk)**

Sprint 3'te bu adım merge conflict'leri büyük ölçüde önlemişti. Sprint 4'te 3 kritik API:

**a) `PlaceCard` API kontratı**

```dart
// SABİT — değişirse ikiniz beraber karar verin
class PlaceCard extends ConsumerWidget {
  final PlaceModel place;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final EdgeInsets? margin;

  const PlaceCard({
    super.key,
    required this.place,
    this.compact = false,
    this.onTap,
    this.onFavoriteToggle,
    this.margin,
  });
}
```

**b) `ComparisonResult` API kontratı**

```dart
class ComparisonResult {
  final UniversityModel uniA;
  final UniversityModel uniB;
  final Map<String, CategoryComparison> categoryComparisons;
  final ComparisonStats stats;

  double get overallScoreDelta;     // uniA.avgRating - uniB.avgRating
  String? get overallWinnerId;      // null = tie

  int get categoriesAWins;
  int get categoriesBWins;
  int get categoriesTied;
}

class CategoryComparison {
  final String categoryName;
  final double valueA;
  final double valueB;
  final double delta;
  final String? winnerId;  // null = tie veya ikisi de 0
}

class ComparisonStats {
  final int reviewCountDelta;       // A - B
  final int placeCountDelta;        // A - B
  final int establishedYearDiff;
  final bool sameType;              // İkisi de Devlet mi?
  final bool sameCity;
  final bool sameCampusLayout;
}
```

**c) `AppNotification` API kontratı**

```dart
class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;  // {route, reviewId, ...}
  final bool isRead;
  final DateTime createdAt;
  final DateTime? expireAt;

  String? get routePath => data['route'] as String?;
  String? get reviewId => data['reviewId'] as String?;
  IconData get icon;
  Color get accentColor;
}

enum NotificationType {
  reviewLiked,
  reviewModerated,
  favoriteNewReview,
}
```

Bu kontratları `notes/sprint4_api_contracts.md` dosyasına yazın, ikiniz onaylayın.

**4. Place Veri Şeması Üzerinde Anlaşın (30dk)**

`PlaceModel`'in son hali:

```dart
class PlaceModel {
  final String id;
  final String universityId;
  final String name;
  final PlaceType type;
  final String description;
  final List<String> imageUrls;
  final String address;
  final String? mapUrl;
  final GeoPoint? location;            // İleride map için
  final String? priceRange;            // ₺ / ₺₺ / ₺₺₺ — sadece cafe için
  final String? openHours;
  final List<String> amenities;
  
  // CSV'den gelen ek bilgiler (yurt için)
  final String? dormType;              // "KYK", "KYK (Devlet)", "Özel" — sadece dorm
  final String? dormGenderType;        // "Kız", "Erkek", "Karma" — sadece dorm
  
  // External rating (Google'dan, kafe için)
  final double? externalRating;        // 4.0 - 5.0
  final String? externalRatingSource;  // "google"
  
  // Aggregation (ÜniSeç kullanıcı yorumları)
  final double avgRating;
  final int reviewCount;
  final Map<String, double> categoryRatings;  // "Ortam", "Fiyat", "Temizlik", "Hizmet"
  
  // Monetization (v2)
  final bool isPromoted;
  final int promotionPriority;
  
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum PlaceType {
  cafe,
  dorm,
  studyArea,    // Sprint 4'te aktif değil ama enum'da var
  library,
  sports,       // Sprint 4'te aktif değil
}
```

> [!IMPORTANT]
> Yurt için `dormType` ve `dormGenderType` alanları kritik. CSV'de "KYK" ile "Özel" yurtlar farklı, bunlar UI'da farklı badge'lerle gösterilecek. Ayrıca `Kız/Erkek/Karma` kontenjan da görsel ayrımla gelecek (Kişi B'nin DormInfoCard widget'ında).

**5. `UniversityModel`'a `campusLayout` Alanı (15dk)**

```dart
enum CampusLayout {
  campus,        // Tek kampüs (KAMPÜSLÜ)
  block,         // Blok yerleşke (BLOK YERLEŞKE)
  distributed;   // Dağınık kampüs (DAĞINIK KAMPÜS)

  String get label {
    switch (this) {
      case CampusLayout.campus: return 'Kampüslü';
      case CampusLayout.block: return 'Blok Yerleşke';
      case CampusLayout.distributed: return 'Dağınık Kampüs';
    }
  }

  IconData get icon {
    switch (this) {
      case CampusLayout.campus: return Icons.location_city_rounded;
      case CampusLayout.block: return Icons.apartment_rounded;
      case CampusLayout.distributed: return Icons.scatter_plot_rounded;
    }
  }

  static CampusLayout fromString(String? value) {
    switch (value) {
      case 'campus': return CampusLayout.campus;
      case 'block': return CampusLayout.block;
      case 'distributed': return CampusLayout.distributed;
      default: return CampusLayout.campus;
    }
  }
}
```

`UniversityModel`'e ekleme:
```dart
class UniversityModel {
  // ... mevcut alanlar
  final CampusLayout campusLayout;  // ← YENİ
  final bool hasCampus;             // mevcut, korunuyor — çelişki olunca campusLayout öncelikli
  
  // fromMap'te:
  campusLayout: CampusLayout.fromString(map['campusLayout']),
  
  // toMap'te:
  'campusLayout': campusLayout.name,
}
```

> [!NOTE]
> Mevcut Firestore doc'larında `campusLayout` alanı yok. Default `campus` (`fromString` null'da bunu döner). Migration: Gün 1'de seed'i yeniden çalıştırınca tüm uniler `campusLayout` ile güncellenecek.

**6. Yeni 8 Üniversite + Çorum Şehri için ID Karar (10dk)**

Şu ID'leri yazıya dökün, kullanıma hazırlayın:

| Yeni Üni | ID | City | Type | Layout |
|----------|-----|------|------|--------|
| Marmara Üniversitesi | `marmara` | 34 | Devlet | campus |
| Ankara Hacı Bayram Veli Üni | `hacibayram` | 06 | Devlet | block |
| İzmir Demokrasi Üni | `izmir_demokrasi` | 35 | Devlet | block |
| İzmir Katip Çelebi Üni | `izmir_katipcelebi` | 35 | Devlet | distributed |
| İstanbul Aydın Üniversitesi | `aydin` | 34 | Vakıf | campus |
| Gelişim Üniversitesi | `gelisim` | 34 | Vakıf | block |
| Medipol Üniversitesi | `medipol` | 34 | Vakıf | block |
| Hitit Üniversitesi | `hitit` | 19 | Devlet | campus |

Yeni şehir:
| ID | Name | PlateCode |
|----|------|-----------|
| 19 | Çorum | 19 |

### 🌞 Öğleden Sonra — Paralel (2.5 saat)

Burada ayrılıyorsunuz, kendi branch'lerinizde çalışın.

**Kişi A — Place Model + Repository İskeleti + Üni Seed Genişletme**

1. **`place_model.dart`** yazın:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum PlaceType {
  cafe,
  dorm,
  studyArea,
  library,
  sports;

  String get firestoreValue {
    switch (this) {
      case PlaceType.cafe: return 'cafe';
      case PlaceType.dorm: return 'dorm';
      case PlaceType.studyArea: return 'study_area';
      case PlaceType.library: return 'library';
      case PlaceType.sports: return 'sports';
    }
  }

  String get label {
    switch (this) {
      case PlaceType.cafe: return 'Kafe';
      case PlaceType.dorm: return 'Yurt';
      case PlaceType.studyArea: return 'Çalışma Alanı';
      case PlaceType.library: return 'Kütüphane';
      case PlaceType.sports: return 'Spor Tesisi';
    }
  }

  IconData get icon {
    switch (this) {
      case PlaceType.cafe: return Icons.local_cafe_rounded;
      case PlaceType.dorm: return Icons.bed_rounded;
      case PlaceType.studyArea: return Icons.menu_book_rounded;
      case PlaceType.library: return Icons.local_library_rounded;
      case PlaceType.sports: return Icons.fitness_center_rounded;
    }
  }

  static PlaceType fromString(String? value) {
    switch (value) {
      case 'cafe': return PlaceType.cafe;
      case 'dorm': return PlaceType.dorm;
      case 'study_area': return PlaceType.studyArea;
      case 'library': return PlaceType.library;
      case 'sports': return PlaceType.sports;
      default: return PlaceType.cafe;
    }
  }
}

class PlaceModel {
  final String id;
  final String universityId;
  final String name;
  final PlaceType type;
  final String description;
  final List<String> imageUrls;
  final String address;
  final String? mapUrl;
  final GeoPoint? location;
  final String? priceRange;
  final String? openHours;
  final List<String> amenities;
  
  // Yurt-spesifik
  final String? dormType;
  final String? dormGenderType;
  
  // External rating
  final double? externalRating;
  final String? externalRatingSource;
  
  // Aggregation
  final double avgRating;
  final int reviewCount;
  final Map<String, double> categoryRatings;
  
  // Monetization
  final bool isPromoted;
  final int promotionPriority;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  PlaceModel({
    required this.id,
    required this.universityId,
    required this.name,
    required this.type,
    this.description = '',
    this.imageUrls = const [],
    this.address = '',
    this.mapUrl,
    this.location,
    this.priceRange,
    this.openHours,
    this.amenities = const [],
    this.dormType,
    this.dormGenderType,
    this.externalRating,
    this.externalRatingSource,
    this.avgRating = 0.0,
    this.reviewCount = 0,
    this.categoryRatings = const {},
    this.isPromoted = false,
    this.promotionPriority = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlaceModel.fromMap(Map<String, dynamic> map, String id) {
    return PlaceModel(
      id: id,
      universityId: map['universityId'] ?? '',
      name: map['name'] ?? '',
      type: PlaceType.fromString(map['type']),
      description: map['description'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      address: map['address'] ?? '',
      mapUrl: map['mapUrl'],
      location: map['location'] as GeoPoint?,
      priceRange: map['priceRange'],
      openHours: map['openHours'],
      amenities: List<String>.from(map['amenities'] ?? []),
      dormType: map['dormType'],
      dormGenderType: map['dormGenderType'],
      externalRating: (map['externalRating'] as num?)?.toDouble(),
      externalRatingSource: map['externalRatingSource'],
      avgRating: (map['avgRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      categoryRatings: Map<String, double>.from(
        (map['categoryRatings'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ) ?? {},
      ),
      isPromoted: map['isPromoted'] ?? false,
      promotionPriority: (map['promotionPriority'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'universityId': universityId,
      'name': name,
      'type': type.firestoreValue,
      'description': description,
      'imageUrls': imageUrls,
      'address': address,
      'mapUrl': mapUrl,
      'location': location,
      'priceRange': priceRange,
      'openHours': openHours,
      'amenities': amenities,
      if (dormType != null) 'dormType': dormType,
      if (dormGenderType != null) 'dormGenderType': dormGenderType,
      if (externalRating != null) 'externalRating': externalRating,
      if (externalRatingSource != null) 'externalRatingSource': externalRatingSource,
      'avgRating': avgRating,
      'reviewCount': reviewCount,
      'categoryRatings': categoryRatings,
      'isPromoted': isPromoted,
      'promotionPriority': promotionPriority,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
```

2. **`place_repository.dart`** iskeleti:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/place_model.dart';

class PlaceRepository {
  final FirebaseFirestore _firestore;
  
  // Cache
  final Map<String, List<PlaceModel>> _placesByUniCache = {};
  final Map<String, PlaceModel> _placeByIdCache = {};
  DateTime? _lastFetchTime;

  PlaceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  bool get _isCacheValid =>
      _lastFetchTime != null &&
      DateTime.now().difference(_lastFetchTime!) < const Duration(minutes: 5);

  void clearCache() {
    _placesByUniCache.clear();
    _placeByIdCache.clear();
    _lastFetchTime = null;
  }

  CollectionReference<Map<String, dynamic>> get _placesRef =>
      _firestore.collection('places');

  Future<List<PlaceModel>> getPlacesByUniversity(String uniId) async {
    if (_placesByUniCache.containsKey(uniId) && _isCacheValid) {
      return _placesByUniCache[uniId]!;
    }
    
    final snapshot = await _placesRef
        .where('universityId', isEqualTo: uniId)
        .orderBy('promotionPriority', descending: true)
        .orderBy('avgRating', descending: true)
        .get(const GetOptions(source: Source.serverAndCache));
    
    final places = snapshot.docs
        .map((doc) => PlaceModel.fromMap(doc.data(), doc.id))
        .toList();
    
    _placesByUniCache[uniId] = places;
    _lastFetchTime = DateTime.now();
    return places;
  }

  Future<PlaceModel?> getPlace(String placeId) async {
    if (_placeByIdCache.containsKey(placeId) && _isCacheValid) {
      return _placeByIdCache[placeId];
    }
    
    final doc = await _placesRef.doc(placeId).get();
    if (!doc.exists || doc.data() == null) return null;
    
    final place = PlaceModel.fromMap(doc.data()!, doc.id);
    _placeByIdCache[placeId] = place;
    return place;
  }

  Future<List<PlaceModel>> getPlacesByType(String uniId, PlaceType type) async {
    final all = await getPlacesByUniversity(uniId);
    return all.where((p) => p.type == type).toList();
  }

  Stream<PlaceModel?> watchPlace(String placeId) {
    return _placesRef.doc(placeId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return PlaceModel.fromMap(doc.data()!, doc.id);
    });
  }

  // TODO(sprint5): Şehir bazlı (cross-uni) mekan listesi
}
```

3. **`place_providers.dart`**:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/place_repository.dart';
import '../../domain/models/place_model.dart';

final placeRepositoryProvider = Provider<PlaceRepository>((ref) {
  return PlaceRepository();
});

final placesByUniversityProvider = 
    FutureProvider.family<List<PlaceModel>, String>((ref, uniId) async {
  ref.keepAlive();
  return ref.read(placeRepositoryProvider).getPlacesByUniversity(uniId);
});

final placeDetailProvider = 
    FutureProvider.family<PlaceModel?, String>((ref, placeId) async {
  ref.keepAlive();
  return ref.read(placeRepositoryProvider).getPlace(placeId);
});

final placeWatchProvider = 
    StreamProvider.family<PlaceModel?, String>((ref, placeId) {
  ref.keepAlive();
  return ref.read(placeRepositoryProvider).watchPlace(placeId);
});
```

4. **`UniversityModel`'a `campusLayout` ekle.** Mevcut `university_model.dart`'a değişiklik:

```dart
import 'package:flutter/material.dart';

enum CampusLayout {
  campus, block, distributed;

  String get label {
    switch (this) {
      case CampusLayout.campus: return 'Kampüslü';
      case CampusLayout.block: return 'Blok Yerleşke';
      case CampusLayout.distributed: return 'Dağınık Kampüs';
    }
  }

  IconData get icon {
    switch (this) {
      case CampusLayout.campus: return Icons.location_city_rounded;
      case CampusLayout.block: return Icons.apartment_rounded;
      case CampusLayout.distributed: return Icons.scatter_plot_rounded;
    }
  }

  static CampusLayout fromString(String? value) {
    switch (value) {
      case 'campus': return CampusLayout.campus;
      case 'block': return CampusLayout.block;
      case 'distributed': return CampusLayout.distributed;
      default: return CampusLayout.campus;
    }
  }
}

class UniversityModel {
  // ... mevcut alanlar
  final CampusLayout campusLayout;  // YENİ

  UniversityModel({
    // ... mevcut
    this.campusLayout = CampusLayout.campus,  // default
  });

  factory UniversityModel.fromMap(Map<String, dynamic> map, String id) {
    return UniversityModel(
      // ... mevcut alanlar
      campusLayout: CampusLayout.fromString(map['campusLayout']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // ... mevcut
      'campusLayout': campusLayout.name,
    };
  }
}
```

5. **`seed_data_service.dart` — 8 yeni üniversite + Çorum şehri ekle.**

Mevcut `cities` listesine ekle:
```dart
{'id': '19', 'name': 'Çorum', 'plateCode': '19', 'photoUrl': 'https://images.unsplash.com/photo-1635224747018-23ada6b1ab02?w=800', 'totalUniversityCount': 2, 'appUniversityCount': 1},
```

Mevcut `universities` listesindeki `appUniversityCount` değerlerini güncelle (yeni unilerle):
- İstanbul: 7 → 10 (marmara, aydin, gelisim, medipol)
- Ankara: 5 → 6 (hacibayram)
- İzmir: 4 → 6 (izmir_demokrasi, izmir_katipcelebi)
- Çorum: 0 → 1 (hitit)

Yeni `universities` listesine ekle:
```dart
{'id': 'marmara', 'cityId': '34', 'name': 'Marmara Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Geniş lisans yelpazesi ve sosyal hayatıyla ünlü.', 'establishedYear': 1883, 'website': 'marmara.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus'},

{'id': 'hacibayram', 'cityId': '06', 'name': 'Ankara Hacı Bayram Veli Üniversitesi', 'type': 'Devlet', 'hasCampus': false, 'logoUrl': '', 'photoUrl': '', 'description': 'Gazi Üni\'den ayrılan, sosyal bilimler odaklı.', 'establishedYear': 2018, 'website': 'hbv.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'block'},

{'id': 'izmir_demokrasi', 'cityId': '35', 'name': 'İzmir Demokrasi Üniversitesi', 'type': 'Devlet', 'hasCampus': false, 'logoUrl': '', 'photoUrl': '', 'description': 'Karabağlar\'da blok yerleşkeli devlet üniversitesi.', 'establishedYear': 2016, 'website': 'idu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'block'},

{'id': 'izmir_katipcelebi', 'cityId': '35', 'name': 'İzmir Katip Çelebi Üniversitesi', 'type': 'Devlet', 'hasCampus': false, 'logoUrl': '', 'photoUrl': '', 'description': 'Çiğli\'de dağınık kampüslü, tıp ağırlıklı.', 'establishedYear': 2010, 'website': 'ikcu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'distributed'},

{'id': 'aydin', 'cityId': '34', 'name': 'İstanbul Aydın Üniversitesi', 'type': 'Vakıf', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Florya kampüsü ile İstanbul\'un büyük vakıf üniversitelerinden.', 'establishedYear': 2003, 'website': 'aydin.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus'},

{'id': 'gelisim', 'cityId': '34', 'name': 'İstanbul Gelişim Üniversitesi', 'type': 'Vakıf', 'hasCampus': false, 'logoUrl': '', 'photoUrl': '', 'description': 'Avcılar bölgesinde blok yerleşkeli vakıf üniversitesi.', 'establishedYear': 2008, 'website': 'gelisim.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'block'},

{'id': 'medipol', 'cityId': '34', 'name': 'İstanbul Medipol Üniversitesi', 'type': 'Vakıf', 'hasCampus': false, 'logoUrl': '', 'photoUrl': '', 'description': 'Sağlık bilimleri ve tıp odaklı vakıf üniversitesi.', 'establishedYear': 2009, 'website': 'medipol.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'block'},

{'id': 'hitit', 'cityId': '19', 'name': 'Hitit Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Çorum\'un köklü devlet üniversitesi, kuzey kampüs alanı.', 'establishedYear': 2006, 'website': 'hitit.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus'},
```

Mevcut `universities` listesindeki diğer uniler için `campusLayout` ekle:
- ODTÜ, İTÜ, Boğaziçi, Hacettepe, Ege, vb. → 'campus' veya CSV'den geldiği gibi
- Yıldız Teknik → 'campus'
- Bilkent → 'campus'
- Hangi uniler hangi layout? Aşağıdaki tabloya bak (Gün 1 sabahında belirlenen):

| Uni ID | Layout |
|--------|--------|
| odtu | campus |
| itu | campus |
| istanbul_uni | distributed |
| yildiz_teknik | campus |
| marmara | campus |
| bogazici | campus |
| koc | campus |
| sabanci | campus |
| bilgi | block |
| aydin | campus |
| gelisim | block |
| medipol | block |
| hacettepe | distributed |
| ankara_uni | distributed |
| gazi | block |
| bilkent | campus |
| hacibayram | block |
| ege | campus |
| dokuz_eylul | distributed |
| iyte | campus |
| yasar | campus |
| izmir_demokrasi | block |
| izmir_katipcelebi | distributed |
| akdeniz | campus |
| alanya | campus |
| anadolu | campus |
| ogu | campus |
| estu | campus |
| uludag | campus |
| btu | block |
| comu | campus |
| cumhuriyet | campus |
| sivas_btu | block |
| ktu | campus |
| trabzon_uni | campus |
| mersin_uni | campus |
| tarsus | distributed |
| hitit | campus |

Bu tabloyu Gün 1 öğleden sonrasında `seed_data_service.dart` içinde uniformly kullan.

> [!IMPORTANT]
> Seed butonu profil ekranındaki debug menüsünden çalıştırılabiliyor. Bu testi Gün 1 sonunda mutlaka yapın — eski data ile çelişki olmadığından emin olun. `merge: true` ile yazarsanız mevcut yorumlar/agg silinmez.

**Kişi B — `PlaceCard` Widget İskeleti + `PlaceTypeChip` + Üniversite Detayında Layout Rozeti**

1. **`place_type_chip.dart`** — küçük yardımcı:

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/place_model.dart';

class PlaceTypeChip extends StatelessWidget {
  final PlaceType type;
  final bool small;
  
  const PlaceTypeChip({super.key, required this.type, this.small = false});

  @override
  Widget build(BuildContext context) {
    final colors = _typeColors(type);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(small ? 6 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: small ? 12 : 14, color: colors.fg),
          SizedBox(width: small ? 4 : 6),
          Text(
            type.label,
            style: AppTextStyles.labelSmall.copyWith(
              color: colors.fg,
              fontWeight: FontWeight.w600,
              fontSize: small ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }
  
  ({Color bg, Color fg}) _typeColors(PlaceType type) {
    switch (type) {
      case PlaceType.cafe:
        return (bg: const Color(0xFFFFF3E0), fg: const Color(0xFFE65100));
      case PlaceType.dorm:
        return (bg: const Color(0xFFE3F2FD), fg: const Color(0xFF0D47A1));
      case PlaceType.library:
        return (bg: const Color(0xFFF3E5F5), fg: const Color(0xFF6A1B9A));
      case PlaceType.studyArea:
        return (bg: AppColors.successLight, fg: AppColors.success);
      case PlaceType.sports:
        return (bg: AppColors.warningLight, fg: AppColors.warning);
    }
  }
}
```

2. **`place_card.dart`** placeholder (görsel finalize Gün 3'te):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/place_model.dart';
import 'place_type_chip.dart';

class PlaceCard extends ConsumerWidget {
  final PlaceModel place;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final EdgeInsets? margin;

  const PlaceCard({
    super.key,
    required this.place,
    this.compact = false,
    this.onTap,
    this.onFavoriteToggle,
    this.margin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: Row(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  ),
                  child: Icon(place.type.icon, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name, style: AppTextStyles.titleMedium,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      PlaceTypeChip(type: place.type, small: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

3. **Üniversite kartlarına `campusLayout` rozeti ekle.** `university_detail_screen.dart`'ta mevcut `_Badge` row'unu güncelle:

```dart
Row(
  children: [
    _Badge(
      text: uni.type,
      color: uni.type == 'Devlet' ? AppColors.stateUni : AppColors.foundationUni,
    ),
    const SizedBox(width: 8),
    _Badge(
      text: uni.campusLayout.label,  // YENİ
      color: AppColors.info,
    ),
    const Spacer(),
    Text(
      'Kuruluş: ${uni.establishedYear}',
      style: AppTextStyles.labelMedium.copyWith(color: AppColors.textTertiary),
    ),
  ],
),
```

4. **Pubspec güncellemesi.** Sprint 4 paketlerini ekle (ilk parti):

```yaml
dependencies:
  # Mevcut...
  
  # Sprint 4 — Day 1
  screenshot: ^3.0.0
  share_plus: ^10.0.2
```

```bash
flutter pub get
```

### 🌆 Akşam — Birlikte (35dk)

**1. Demo (15dk)**
- Kişi A: 
  - `PlaceModel.fromMap` ile bir mock JSON parse edebiliyor mu?
  - `PlaceRepository.getPlacesByUniversity` boş listede crash etmiyor mu?
  - Seed'i çalıştır → Firestore Console'da: `cities` 11 doc, `universities` 38 doc, hepsi `campusLayout` alanına sahip
- Kişi B:
  - `PlaceTypeChip` görsel olarak güzel mi? 5 tip için 5 farklı renk?
  - Mock bir `PlaceModel` ile `PlaceCard` render oluyor mu?
  - Üni detayında "Kampüslü/Blok/Dağınık" rozeti görünüyor mu?

**2. API Kontratı Doğrulaması (5dk)**
- `PlaceCard`'ın aldığı parametreler sabah anlaştığınızla aynı mı?
- `PlaceModel` alanları `place_repository.dart`'ta tutarlı mı?
- `CampusLayout` enum yazılımına uygun mu?

**3. Firestore Doğrulama (10dk)**

Birlikte Console'a girin:
- `cities`: 11 doc (eski 10 + Çorum)
- `universities`: 38 doc (eski 30 + 8 yeni)
- Yeni unilerin `cityId` doğru mu? (örn. `marmara`'nın `cityId` = '34')
- Bütün unilerde `campusLayout` alanı var mı?

**4. Yarın Planı (5dk)**

```bash
# Her iki kişi push
git push origin feat/sprint4-data-backend
git push origin feat/sprint4-ui-views

# develop'a merge — küçük PR'lar
```

Yarın:
- A: CSV → Firestore parse pipeline'ı (Python script + Dart import)
- B: PlaceCard görsel finalize, PlaceList widget oluştur, üni detayında "Mekanlar" bölümü

### ✅ Gün 1 Bitişinde Durum

- [ ] Sprint 3 retrospektifi konuşuldu
- [ ] 3 API kontratı yazılı netleştirildi (`PlaceCard`, `ComparisonResult`, `AppNotification`)
- [ ] `place_model.dart` yazıldı
- [ ] `place_repository.dart` iskeleti hazır (cache, getByUniversity, getPlace, watch, getPlacesByType)
- [ ] `place_providers.dart` 3 provider tanımlı
- [ ] `PlaceCard` ve `PlaceTypeChip` placeholder hazır
- [ ] `UniversityModel`'a `campusLayout` alanı eklendi (model + fromMap + toMap)
- [ ] `seed_data_service.dart`: 8 yeni uni + Çorum şehri eklendi, mevcut unilere `campusLayout` migration yapıldı
- [ ] Firestore'a yeni seed yüklendi (cities 11, universities 38)
- [ ] Üni detayında campus layout rozeti görünüyor
- [ ] `pubspec.yaml`'da `screenshot` ve `share_plus` var
- [ ] İlk PR'lar develop'a merge edildi

---


## 📆 GÜN 2: Place Repository & Seed Import Pipeline

> **Hedef:** 509 mekan Firestore'a doğru şekilde yüklendi, `PlaceCard` görsel olarak finalize, `PlaceList` widget hazır, üniversite detayında "Mekanlar" bölümü görünüyor, ilk birkaç mekan listede güzel duruyor.

### 🌅 Sabah Standupı (15dk)

Sabah ortak dosya kontrolü:
- A: `seed_data_service.dart`'a `_seedPlaces` metodu ekleyeceğim, **CSV parse Python script'i yazacağım**
- B: `university_detail_screen.dart`'a "Mekanlar" bölümü ekleyeceğim

İkisi farklı dosyalar — conflict yok.

### 🌞 Gün İçi — Paralel (4 saat)

**Kişi A — CSV Parse Pipeline + Place Seed Import + Firestore Rules**

Bu Sprint 4'ün **en kritik** parçası. 509 mekanı doğru şekilde Firestore'a almalıyız.

#### Adım 1: Python Parse Script (90dk)

Veri ZIP'ini ham CSV'ler olarak yerelinizde tuttuğunuzu varsayıyorum (`data/raw/`). Şimdi tek bir kanonik JSON üreteceğiz, Dart seed servisi bunu okuyacak.

**Yeni dosya:** `tools/parse_places_csv.py` (proje root'unda `tools/` klasörü, yoksa oluştur)

```python
#!/usr/bin/env python3
"""
Sprint 4 — Place CSV Parser
Mekanları CSV klasör yapısından kanonik JSON'a dönüştürür.

Kullanım:
  python3 tools/parse_places_csv.py \
    --input data/raw/unisec_üniversiteler \
    --output assets/data/places_seed.json
"""
import os, csv, json, re, argparse

# Üniversite adı → ID mapping (Gün 1'de finalize edilen)
UNI_NAME_TO_ID = {
    'BOĞAZİÇİ ÜNİVERSİTESİ': 'bogazici',
    'İSTANBUL TEKNİK ÜNİVERSİTESİ (İTÜ)': 'itu',
    'İSTANBUL ÜNİVERSİTESİ': 'istanbul_uni',
    'YILDIZ TEKNİK ÜNİVERSİTESİ': 'yildiz_teknik',
    'MARMARA ÜNİVERSİTESİ': 'marmara',
    'KOÇ ÜNİVERSİTESİ': 'koc',
    'SABANCI ÜNİVERSİTESİ': 'sabanci',
    'İSTANBUL BİLGİ ÜNİVERSİTESİ': 'bilgi',
    'İSTANBUL AYDIN ÜNİVERSİTESİ': 'aydin',
    'GELİŞİM ÜNİVERSİTESİ': 'gelisim',
    'MEDİPOL ÜNİVERSİTESİ': 'medipol',
    'ODTÜ': 'odtu',
    'HACETTEPE ÜNİVERSİTESİ': 'hacettepe',
    'ANKARA ÜNİVERSİTESİ': 'ankara_uni',
    'GAZİ ÜNİVERSİTESİ': 'gazi',
    'İHSAN DOĞRAMACI BİLKENT ÜNİVERSİTESİ': 'bilkent',
    'ANKARA HACI BAYRAM VELİ ÜNİVERSİTESİ': 'hacibayram',
    'EGE ÜNİVERSİTESİ': 'ege',
    'DOKUZ EYLÜL ÜNİVERSİTESİ': 'dokuz_eylul',
    'İZMİR YÜKSEK TEKNOLOJİ ENSTİTÜSÜ': 'iyte',
    'YAŞAR ÜNİVERSİTESİ': 'yasar',
    'İZMİR DEMOKRASİ ÜNİVERSİTESİ': 'izmir_demokrasi',
    'İZMİR KATİP ÇELEBİ ÜNİVERSİTESİ': 'izmir_katipcelebi',
    'AKDENİZ ÜNİVERSİTESİ': 'akdeniz',
    'ALANYA ALAADDİN KEYKUBAT ÜNİVERSİTESİ': 'alanya',
    'ANADOLU ÜNİVERSİTESİ': 'anadolu',
    'ESKİŞEHİR OSMANGAZİ ÜNİVERSİTESİ': 'ogu',
    'ESKİŞEHİR TEKNİK ÜNİVERSİTESİ': 'estu',
    'BURSA ULUDAĞ ÜNİVERSİTESİ': 'uludag',
    'BURSA TEKNİK ÜNİVERSİTESİ': 'btu',
    'ON SEKİZ MART ÜNİVERSİTESİ': 'comu',
    'SİVAS CUMHURİYET ÜNİVERSİTESİ': 'cumhuriyet',
    'SİVAS BİLİM VE TEKNOLOJİ ÜNİVERSİTESİ': 'sivas_btu',
    'KARADENİZ TEKNİK ÜNİVERSİTESİ': 'ktu',
    'TRABZON ÜNİVERSİTESİ': 'trabzon_uni',
    'MERSİN ÜNİVERSİTESİ': 'mersin_uni',
    'TARSUS ÜNİVERSİTESİ': 'tarsus',
    'HİTİT ÜNİVERSİTESİ': 'hitit',
}

LAYOUT_MAP = {
    'KAMPÜSLÜ': 'campus',
    'BLOK YERLEŞKE': 'block',
    'DAĞINIK KAMPÜS': 'distributed',
    'DAĞINIK KAMPÜSLÜ': 'distributed',
}

PRICE_NORM = {
    'çok ekonomik': '₺',
    'ekonomik': '₺',
    'orta': '₺₺',
    'orta-üst': '₺₺',
    'üst': '₺₺₺',
    'orta / öğrenci dostu': '₺',
}

FILENAME_TYPE_MAP = {
    'kafeler': 'cafe', 'cafeler': 'cafe',
    'yurtlar': 'dorm',
    'kütüphaneler': 'library', 'kütüphane': 'library',
}

def slugify(text):
    if not text: return ''
    tr_map = str.maketrans('çğıöşüÇĞİÖŞÜ', 'cgiosuCGIOSU')
    text = text.translate(tr_map)
    text = re.sub(r'[^a-zA-Z0-9\s]', '', text)
    text = re.sub(r'\s+', '_', text.strip()).lower()
    return text[:60]

def normalize_price(price):
    if not price: return None
    return PRICE_NORM.get(price.strip().lower(), '₺₺')

def parse_kafeler(rows, uni_id):
    places = []
    for row in rows:
        name = row.get('Kafe Adı', '').strip()
        if not name: continue
        location = row.get('Konum', row.get('Konum / Yakınlık', '')).strip()
        why = row.get('Neden Seçmelisin?', row.get('Öne Çıkan Özellikler', '')).strip()
        price = row.get('Fiyat', row.get('Fiyat Seviyesi', '')).strip()
        google_rating = row.get('Google Puanı', '').strip()
        try: gr = float(google_rating) if google_rating else None
        except: gr = None
        slug = slugify(name)
        places.append({
            'id': f"{uni_id}_cafe_{slug}",
            'universityId': uni_id,
            'name': name,
            'type': 'cafe',
            'description': why,
            'address': location,
            'priceRange': normalize_price(price),
            'externalRating': gr,
            'externalRatingSource': 'google' if gr else None,
            'imageUrls': [],
            'amenities': [],
            'openHours': None,
            'mapUrl': None,
            'avgRating': 0.0,
            'reviewCount': 0,
            'categoryRatings': {},
            'isPromoted': False,
            'promotionPriority': 0,
        })
    return places

def parse_yurtlar(rows, uni_id):
    places = []
    for row in rows:
        name = row.get('Yurt Adı', '').strip()
        if not name: continue
        tur = row.get('Tür', '').strip()
        kontenjan = row.get('Kontenjan Tipi', row.get('Kontenjan', '')).strip()
        yakinlik = (row.get('Kampüse Yakınlık / Ulaşım') or
                    row.get('Üniversiteye Mesafe / Ulaşım') or
                    row.get('Kampüse Yakınlık') or '').strip()
        amenities = []
        if 'KYK' in tur.upper(): amenities.append('KYK')
        if 'ÖZEL' in tur.upper() or 'Özel' in tur: amenities.append('Özel Yurt')
        if 'kız' in kontenjan.lower(): amenities.append('Kız Yurdu')
        if 'erkek' in kontenjan.lower(): amenities.append('Erkek Yurdu')
        if 'karma' in kontenjan.lower(): amenities.append('Karma')
        slug = slugify(name)
        places.append({
            'id': f"{uni_id}_dorm_{slug}",
            'universityId': uni_id,
            'name': name,
            'type': 'dorm',
            'description': yakinlik,
            'address': '',
            'priceRange': None,
            'externalRating': None,
            'externalRatingSource': None,
            'imageUrls': [],
            'amenities': amenities,
            'openHours': '7/24',
            'mapUrl': None,
            'dormType': tur,
            'dormGenderType': kontenjan,
            'avgRating': 0.0,
            'reviewCount': 0,
            'categoryRatings': {},
            'isPromoted': False,
            'promotionPriority': 0,
        })
    return places

def parse_kutuphaneler(rows, uni_id):
    places = []
    for row in rows:
        name = row.get('Kütüphane Adı', '').strip()
        if not name: continue
        kutup_tur = row.get('Tür', '').strip()
        konum = row.get('Konum', '').strip()
        saat = row.get('Çalışma Saatleri', row.get('Saat', '')).strip()
        why = row.get('Ders Çalışmaya Uygunluk', '').strip()
        konfor = row.get('Konfor', '').strip()
        sessizlik = row.get('Sessizlik', '').strip()
        zorluk = row.get('Yer Bulma Zorluğu', '').strip()
        desc_parts = []
        if why: desc_parts.append(why)
        elif konfor or sessizlik:
            meta = []
            if konfor: meta.append(f"Konfor: {konfor}")
            if sessizlik: meta.append(f"Sessizlik: {sessizlik}")
            if zorluk: meta.append(f"Yer Bulma: {zorluk}")
            desc_parts.append(' • '.join(meta))
        amenities = []
        if kutup_tur: amenities.append(f"{kutup_tur} Kütüphanesi")
        if 'sessiz' in (sessizlik + zorluk + why).lower(): amenities.append('Sessiz')
        if '7/24' in saat or '24' in saat: amenities.append('7/24 Açık')
        slug = slugify(name)
        places.append({
            'id': f"{uni_id}_lib_{slug}",
            'universityId': uni_id,
            'name': name,
            'type': 'library',
            'description': ' '.join(desc_parts),
            'address': konum,
            'priceRange': None,
            'externalRating': None,
            'externalRatingSource': None,
            'imageUrls': [],
            'amenities': amenities,
            'openHours': saat or None,
            'mapUrl': None,
            'avgRating': 0.0,
            'reviewCount': 0,
            'categoryRatings': {},
            'isPromoted': False,
            'promotionPriority': 0,
        })
    return places

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    
    all_places = []
    layouts = {}
    unmapped = set()
    
    for city in os.listdir(args.input):
        cp = os.path.join(args.input, city)
        if not os.path.isdir(cp): continue
        for tur in os.listdir(cp):
            tp = os.path.join(cp, tur)
            if not os.path.isdir(tp): continue
            for layout in os.listdir(tp):
                lp = os.path.join(tp, layout)
                if not os.path.isdir(lp): continue
                for uni in os.listdir(lp):
                    up = os.path.join(lp, uni)
                    if not os.path.isdir(up): continue
                    
                    uname = uni.upper().strip()
                    uid = UNI_NAME_TO_ID.get(uname) or UNI_NAME_TO_ID.get(re.sub(r'\s*\([^)]*\)', '', uname).strip())
                    if not uid:
                        unmapped.add(uname)
                        continue
                    
                    layouts[uid] = LAYOUT_MAP.get(layout.upper(), 'campus')
                    
                    for fname in os.listdir(up):
                        fp = os.path.join(up, fname)
                        if not os.path.isfile(fp): continue
                        ptype = FILENAME_TYPE_MAP.get(fname.lower())
                        if not ptype: continue
                        with open(fp, encoding='utf-8') as f:
                            rows = list(csv.DictReader(f))
                        if ptype == 'cafe': places = parse_kafeler(rows, uid)
                        elif ptype == 'dorm': places = parse_yurtlar(rows, uid)
                        elif ptype == 'library': places = parse_kutuphaneler(rows, uid)
                        else: continue
                        all_places.extend(places)
    
    out = {
        'meta': {
            'totalPlaces': len(all_places),
            'totalUniversities': len(layouts),
            'cafeCount': sum(1 for p in all_places if p['type'] == 'cafe'),
            'dormCount': sum(1 for p in all_places if p['type'] == 'dorm'),
            'libraryCount': sum(1 for p in all_places if p['type'] == 'library'),
            'unmappedUniversities': sorted(list(unmapped)),
        },
        'campusLayouts': layouts,
        'places': all_places,
    }
    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    
    print(f"✅ {len(all_places)} mekan parse edildi")
    print(f"  Kafe: {out['meta']['cafeCount']}")
    print(f"  Yurt: {out['meta']['dormCount']}")
    print(f"  Kütüphane: {out['meta']['libraryCount']}")
    print(f"  Üniversite: {len(layouts)}")
    if unmapped:
        print(f"⚠️  Mapped olmayan üniler: {sorted(unmapped)}")
    print(f"📁 Çıktı: {args.output}")

if __name__ == '__main__':
    main()
```

Çalıştır:
```bash
mkdir -p assets/data
python3 tools/parse_places_csv.py \
  --input data/raw/unisec_üniversiteler \
  --output assets/data/places_seed.json
```

Beklenen çıktı: 509 mekan, 31 üni mapped, 0 unmapped.

> [!IMPORTANT]
> **`assets/data/places_seed.json` Flutter assets'ine eklenmeli.** `pubspec.yaml`'da:
> ```yaml
> flutter:
>   assets:
>     - assets/data/places_seed.json
>     - assets/icons/  # mevcut
> ```
> Bu Sprint 4'ün asset boyutuna ~200 KB ekler — sorun değil.

#### Adım 2: Dart Seed Service Place Import (60dk)

`lib/scripts/seed_data_service.dart`'a `_seedPlaces` metodu ekle:

```dart
import 'package:flutter/services.dart';

// SeedDataService class içine ekle:

Future<void> _seedPlaces() async {
  // 1. Asset'ten JSON oku
  final jsonStr = await rootBundle.loadString('assets/data/places_seed.json');
  final data = json.decode(jsonStr) as Map<String, dynamic>;
  final places = (data['places'] as List).cast<Map<String, dynamic>>();
  final layouts = (data['campusLayouts'] as Map<String, dynamic>).cast<String, String>();
  
  print('📥 ${places.length} mekan import edilecek');
  
  // 2. Üniversitelere campusLayout migration
  // Bu Gün 1'de seed_data_service.dart'taki universities listesinde elle yapıldı.
  // Ama eğer eksik kalan varsa güvenlik amaçlı buradan da güncelle:
  final batch1 = _firestore.batch();
  var b1Count = 0;
  for (final entry in layouts.entries) {
    final uniRef = _firestore.collection('universities').doc(entry.key);
    batch1.set(uniRef, {'campusLayout': entry.value}, SetOptions(merge: true));
    b1Count++;
    if (b1Count >= 490) {
      await batch1.commit();
      b1Count = 0;
    }
  }
  if (b1Count > 0) await batch1.commit();
  print('✅ Campus layout güncellendi (${layouts.length} üni)');
  
  // 3. Places'i batch ile yaz
  var batch = _firestore.batch();
  var batchCount = 0;
  for (final place in places) {
    final placeId = place['id'] as String;
    final ref = _firestore.collection('places').doc(placeId);
    
    // Timestamp'leri ekle (JSON'da yok)
    final placeData = {
      ...place,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    placeData.remove('id');  // Doc id ayrı, data'da olmayacak
    
    // Null değerleri temizle (Firestore null kabul ediyor ama estetik)
    placeData.removeWhere((k, v) => v == null);
    
    // merge: true ile mevcut yorumlar/agg silinmez
    batch.set(ref, placeData, SetOptions(merge: true));
    batchCount++;
    
    if (batchCount >= 490) {
      await batch.commit();
      batch = _firestore.batch();
      batchCount = 0;
    }
  }
  if (batchCount > 0) await batch.commit();
  print('✅ ${places.length} mekan Firestore\'a yüklendi');
}
```

`uploadSeedData` ana metodunun sonuna `await _seedPlaces();` ekle.

#### Adım 3: Firestore Rules + Indexes (20dk)

`firestore.rules`'a `places` ve daha sonra `notifications` için kurallar:

```
// places: herkes okur, sadece admin yazar
match /places/{placeId} {
  allow read: if true;
  allow write: if isAdmin();
}
```

Mevcut `reviews` create kuralında `universityId` kontrolü var. Place yorumu için `universityId` place'in `universityId`'sine eşit olmalı:

```
// reviews altına ekle (mevcut create rule'unu güncelle)
allow create: if isVerifiedStudent() &&
  request.resource.data.userId == request.auth.uid &&
  request.resource.data.universityId == get(/databases/$(database)/documents/users/$(request.auth.uid)).data.universityId;
```

Yukarıdaki kural zaten Place yorumunda da çalışır (kullanıcı kendi üniversitesinin mekanlarına yorum yapabilir).

`firestore.indexes.json`'a ekle:

```json
{
  "collectionGroup": "places",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "universityId", "order": "ASCENDING" },
    { "fieldPath": "promotionPriority", "order": "DESCENDING" },
    { "fieldPath": "avgRating", "order": "DESCENDING" }
  ]
},
{
  "collectionGroup": "places",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "universityId", "order": "ASCENDING" },
    { "fieldPath": "type", "order": "ASCENDING" },
    { "fieldPath": "avgRating", "order": "DESCENDING" }
  ]
},
{
  "collectionGroup": "reviews",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "targetId", "order": "ASCENDING" },
    { "fieldPath": "type", "order": "ASCENDING" },
    { "fieldPath": "isApproved", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

Deploy:
```bash
firebase deploy --only firestore:rules,firestore:indexes
```

> [!NOTE]
> Index build 5-10 dakika sürer. İlk place query'sinde "indexes building" hatası alırsanız bekleyin veya Firebase Console'dan link tıklayıp manual index oluşturun.

#### Adım 4: Test (15dk)

1. Profil → Debug → "Seed Verisini Yükle" tıkla
2. Console'a bak — mesajlar doğru mu? "509 mekan yüklendi" görmeli
3. Firebase Console → Firestore → `places` koleksiyonu → 509 doc?
4. Bir place'e bakın — alanlar doğru mu? `dormType`, `externalRating`, `categoryRatings` boş?

**Kişi B — `PlaceCard` Görsel Finalize + `PlaceList` + "Mekanlar" Bölümü**

#### Adım 1: `PlaceCard` Görsel Finalize (60dk)

Mevcut placeholder'ı zenginleştir:

```dart
import 'package:cached_network_image/cached_network_image.dart';

@override
Widget build(BuildContext context, WidgetRef ref) {
  return Container(
    margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      border: Border.all(color: AppColors.borderLight),
      boxShadow: AppColors.softShadow,
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(child: _buildInfo()),
              if (place.priceRange != null) _buildPriceBadge(),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildImage() {
  if (place.imageUrls.isEmpty) {
    return Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        color: _typeColor().withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Icon(place.type.icon, color: _typeColor(), size: 32),
    );
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
    child: CachedNetworkImage(
      imageUrl: place.imageUrls.first,
      width: 72, height: 72, fit: BoxFit.cover,
      memCacheWidth: 144, memCacheHeight: 144,
      placeholder: (_, __) => Container(
        width: 72, height: 72, color: AppColors.surfaceVariant,
      ),
      errorWidget: (_, __, ___) => Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: _typeColor().withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
        child: Icon(place.type.icon, color: _typeColor(), size: 32),
      ),
    ),
  );
}

Widget _buildInfo() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(place.name,
        style: AppTextStyles.titleMedium,
        maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 4),
      Row(
        children: [
          PlaceTypeChip(type: place.type, small: true),
          if (place.dormGenderType != null) ...[
            const SizedBox(width: 6),
            _buildDormGenderBadge(),
          ],
        ],
      ),
      if (place.address.isNotEmpty) ...[
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 12, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(place.address,
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ],
      const SizedBox(height: 6),
      _buildRatings(),
    ],
  );
}

Widget _buildDormGenderBadge() {
  final gender = place.dormGenderType!.toLowerCase();
  IconData icon;
  Color color;
  if (gender.contains('kız')) {
    icon = Icons.female_rounded;
    color = const Color(0xFFEC4899);
  } else if (gender.contains('erkek')) {
    icon = Icons.male_rounded;
    color = const Color(0xFF3B82F6);
  } else {
    icon = Icons.people_outline_rounded;
    color = AppColors.success;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Icon(icon, size: 12, color: color),
  );
}

Widget _buildRatings() {
  // ÜniSeç içinden rating
  if (place.avgRating > 0) {
    return Row(
      children: [
        Icon(Icons.star_rounded, size: 14, color: AppColors.ratingStar),
        const SizedBox(width: 3),
        Text(
          place.avgRating.toStringAsFixed(1),
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${place.reviewCount})',
          style: AppTextStyles.labelSmall,
        ),
        if (place.externalRating != null) ...[
          const SizedBox(width: 8),
          _buildExternalRatingBadge(),
        ],
      ],
    );
  }
  // Sadece Google rating varsa
  if (place.externalRating != null) {
    return _buildExternalRatingBadge();
  }
  // Hiçbiri yoksa
  return Text(
    'Henüz değerlendirilmedi',
    style: AppTextStyles.labelSmall.copyWith(
      color: AppColors.textTertiary,
      fontStyle: FontStyle.italic,
    ),
  );
}

Widget _buildExternalRatingBadge() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5E9),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('G ', style: AppTextStyles.labelSmall.copyWith(
          color: const Color(0xFF1B5E20), fontWeight: FontWeight.w700, fontSize: 10)),
        Icon(Icons.star_rounded, size: 11, color: const Color(0xFF1B5E20)),
        const SizedBox(width: 2),
        Text(
          place.externalRating!.toStringAsFixed(1),
          style: AppTextStyles.labelSmall.copyWith(
            color: const Color(0xFF1B5E20),
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ],
    ),
  );
}

Widget _buildPriceBadge() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.success.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      place.priceRange!,
      style: AppTextStyles.titleSmall.copyWith(
        color: AppColors.success,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

Color _typeColor() {
  switch (place.type) {
    case PlaceType.cafe: return const Color(0xFFE65100);
    case PlaceType.dorm: return const Color(0xFF0D47A1);
    case PlaceType.library: return const Color(0xFF6A1B9A);
    case PlaceType.studyArea: return AppColors.success;
    case PlaceType.sports: return AppColors.warning;
  }
}
```

#### Adım 2: `PlaceList` Widget (45dk)

`lib/features/places/presentation/widgets/place_list.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/models/place_model.dart';
import '../providers/place_providers.dart';
import 'place_card.dart';
import 'place_type_chip.dart';

class PlaceList extends ConsumerStatefulWidget {
  final String universityId;
  final PlaceType? initialFilterType;
  final bool showTypeFilter;
  final bool shrinkWrap;
  
  const PlaceList({
    super.key,
    required this.universityId,
    this.initialFilterType,
    this.showTypeFilter = true,
    this.shrinkWrap = true,
  });

  @override
  ConsumerState<PlaceList> createState() => _PlaceListState();
}

class _PlaceListState extends ConsumerState<PlaceList> {
  PlaceType? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialFilterType;
  }

  @override
  Widget build(BuildContext context) {
    final placesAsync = ref.watch(placesByUniversityProvider(widget.universityId));
    
    return placesAsync.when(
      loading: () => const ShimmerList(itemCount: 3),
      error: (e, _) => ErrorStateWidget(message: '$e'),
      data: (places) {
        final filtered = _selectedType == null
            ? places
            : places.where((p) => p.type == _selectedType).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showTypeFilter) _buildFilterBar(places),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: EmptyStateWidget(
                  icon: Icons.place_outlined,
                  title: _selectedType != null
                      ? '${_selectedType!.label} bulunamadı'
                      : 'Henüz mekan eklenmedi',
                  description: _selectedType != null
                      ? 'Bu üniversite için bu kategoride mekan yok.'
                      : 'İlk değerlendiren siz olun!',
                ),
              )
            else
              ListView.builder(
                shrinkWrap: widget.shrinkWrap,
                physics: widget.shrinkWrap
                    ? const NeverScrollableScrollPhysics()
                    : null,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final place = filtered[i];
                  return PlaceCard(
                    place: place,
                    onTap: () => context.push('/place/${place.id}'),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar(List<PlaceModel> all) {
    final types = all.map((p) => p.type).toSet().toList();
    if (types.length < 2) return const SizedBox.shrink();
    
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          _buildFilterChip(null, 'Tümü', all.length),
          ...types.map((t) {
            final count = all.where((p) => p.type == t).length;
            return _buildFilterChip(t, t.label, count);
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(PlaceType? type, String label, int count) {
    final selected = _selectedType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: selected,
        onSelected: (_) => setState(() => _selectedType = type),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: selected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(
          color: selected ? AppColors.primary.withValues(alpha: 0.3) : AppColors.borderLight,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
      ),
    );
  }
}
```

#### Adım 3: Üniversite Detayında "Mekanlar" Bölümü (45dk)

`university_detail_screen.dart`'ta `Bölümler` listesinden sonra, `Yorumlar` başlığından önce ekle:

```dart
// SliverList içinde, Bölümler'in sonundan sonra:

const SizedBox(height: 32),

// ─── Mekanlar ────────────────────────────────────────
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  child: Row(
    children: [
      const Icon(Icons.place_rounded, color: AppColors.primary, size: 22),
      const SizedBox(width: 8),
      Text('Mekanlar', style: AppTextStyles.headlineMedium),
    ],
  ),
),

PlaceList(
  universityId: universityId,
  showTypeFilter: true,
  shrinkWrap: true,
),

const SizedBox(height: 24),
```

> [!NOTE]
> `PlaceList`'in `shrinkWrap: true` olduğu için `CustomScrollView` içinde sorun çıkarmaz. `Sliver` versiyonu yapma — overengineer.

#### Adım 4: Router'a Place Detail Route Ekle (15dk)

`app_router.dart`'a:

```dart
GoRoute(
  path: '/place/:placeId',
  builder: (context, state) => PlaceDetailScreen(
    placeId: state.pathParameters['placeId']!,
  ),
),
```

`PlaceDetailScreen` henüz tam yok → şimdilik placeholder yaz (Gün 3'te tam olacak):

```dart
// lib/features/places/presentation/screens/place_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/place_providers.dart';

class PlaceDetailScreen extends ConsumerWidget {
  final String placeId;
  const PlaceDetailScreen({super.key, required this.placeId});
  
  @override
  Widget build(context, ref) {
    final placeAsync = ref.watch(placeDetailProvider(placeId));
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Mekan Detayı'),
      ),
      body: placeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (place) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(place?.name ?? 'Bulunamadı'),
                const Text('Detay ekranı yarın yapılacak'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### 🌆 Akşam Buluşması (35dk)

**1. Firestore Doğrulama (15dk)**
İkiniz birlikte Firebase Console'a:
- `places` koleksiyonunda 509 doc var mı?
- 31 mapped üni için en az 1 mekan var mı? (`bogazici`, `koc`, `sabanci`, `bilgi`, `bilkent`, `iyte`, `yasar` için olmayacak — bu beklenen)
- Bir cafe doc'una bak: `name`, `type`, `priceRange`, `externalRating`, `address` doğru mu?
- Bir dorm doc'una bak: `dormType`, `dormGenderType`, `amenities` array doğru mu?
- `universities` koleksiyonunda her doc'ta `campusLayout` var mı?

**2. UI Demo (15dk)**
- Kişi B uygulamayı açsın, üniversite detayına gitsin (örn. ODTÜ)
- "Mekanlar" bölümü görünüyor mu?
- 5+ kart listede var mı? Liste içinde tip filtresi (Tümü/Kafe/Yurt/Kütüphane) chip'leri çalışıyor mu?
- Bir kart üstüne tıklayınca placeholder ekran açılıyor mu?
- Yurt kartında Kız/Erkek badge'i görünüyor mu?
- Cafe kartında "G ⭐4.5" Google rating görünüyor mu?

**3. Edge Case Test (5dk)**
- Mekan verisi olmayan bir uniye git (örn. Boğaziçi) — empty state görünüyor mu?
- Çok uzun place name (50+ karakter) → ellipsis çalışıyor mu?

### ✅ Gün 2 Bitişinde Durum

- [ ] Python parse script çalışıyor, 509 mekan parse ediliyor
- [ ] `assets/data/places_seed.json` Flutter assets'inde
- [ ] `seed_data_service.dart`'a `_seedPlaces` metodu eklendi
- [ ] Tüm 509 mekan Firestore'da
- [ ] `firestore.rules` places + reviews güncel, deploy edildi
- [ ] `firestore.indexes.json` 3+ yeni index, deploy edildi (build oluyor)
- [ ] `PlaceCard` görsel tam: tip chip, fiyat badge, dorm gender badge, dual rating (üniseç + google)
- [ ] `PlaceList` filter chip ile tip filtresi
- [ ] Üni detayında "Mekanlar" bölümü çalışıyor
- [ ] `/place/:placeId` placeholder route var
- [ ] CSV varsayılan setinde olmayan uniler için empty state

---


## 📆 GÜN 3: Place UI — Card, List, Detail

> **Hedef:** Place detay ekranı tam, foto galerisi/bilgiler/harita linki/yorumlar bölümleri çalışıyor. Yurt için özel `DormInfoCard` görseli hazır. Place yorum agregasyon Cloud Function deploy edildi. Kullanıcı bir mekanı detayına kadar görüntüleyebiliyor.

### 🌅 Sabah Standupı (15dk)

Sabah ortak dosya kontrolü:
- A: Place agregasyon Cloud Function (`aggregate_place_ratings.ts`) yazıyorum, `WriteReviewScreen`'e dokunmuyorum henüz
- B: `PlaceDetailScreen` tam halini yazıyorum, `DormInfoCard` ve `PlaceAmenitiesGrid` widget'ları
- Ortak dosya yok bugün ✅

### 🌞 Gün İçi — Paralel (4 saat)

**Kişi A — Place Aggregation Cloud Function + Yorum API Genişletme**

#### Adım 1: `aggregate_place_ratings.ts` Cloud Function (90dk)

Sprint 3'teki `aggregateUniversityRatings` pattern'ini kopyalayın, places için adapte edin.

`functions/src/places/aggregate_place_ratings.ts`:

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

const PLACE_CATEGORIES = ['Ortam', 'Fiyat', 'Temizlik', 'Hizmet'];

/**
 * Place yorumları yazıldığında/güncellendiğinde/silindiğinde
 * place doc'unun avgRating, reviewCount ve categoryRatings alanlarını günceller.
 */
export const aggregatePlaceRatings = functions
  .region('europe-west1')
  .firestore.document('reviews/{reviewId}')
  .onWrite(async (change, context) => {
    const before = change.before.exists ? change.before.data() : null;
    const after = change.after.exists ? change.after.data() : null;
    
    // Place yorumu mu kontrol et (type === 'place')
    const reviewType = after?.type ?? before?.type;
    if (reviewType !== 'place') return null;
    
    const placeId = after?.targetId ?? before?.targetId;
    if (!placeId) return null;
    
    // Approval state değişti mi?
    const wasApproved = before?.isApproved === true;
    const isApproved = after?.isApproved === true;
    if (!wasApproved && !isApproved) return null;  // İkisi de pending
    
    console.log(`[aggregatePlaceRatings] place=${placeId}`);
    
    // Tüm onaylı yorumları çek
    const reviewsSnap = await db.collection('reviews')
      .where('targetId', '==', placeId)
      .where('type', '==', 'place')
      .where('isApproved', '==', true)
      .get();
    
    if (reviewsSnap.empty) {
      // Hiç onaylı yorum yok — sıfırla
      await db.collection('places').doc(placeId).set({
        avgRating: 0,
        reviewCount: 0,
        categoryRatings: {},
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      return null;
    }
    
    // Hesapla
    let totalOverall = 0;
    const categoryTotals: Record<string, { sum: number; count: number }> = {};
    for (const cat of PLACE_CATEGORIES) {
      categoryTotals[cat] = { sum: 0, count: 0 };
    }
    
    for (const doc of reviewsSnap.docs) {
      const data = doc.data();
      totalOverall += data.overallRating ?? 0;
      
      const catRatings = (data.categoryRatings as Record<string, number>) || {};
      for (const [cat, rating] of Object.entries(catRatings)) {
        if (categoryTotals[cat]) {
          categoryTotals[cat].sum += rating;
          categoryTotals[cat].count += 1;
        }
      }
    }
    
    const reviewCount = reviewsSnap.size;
    const avgRating = totalOverall / reviewCount;
    
    const categoryRatings: Record<string, number> = {};
    for (const [cat, { sum, count }] of Object.entries(categoryTotals)) {
      if (count > 0) {
        categoryRatings[cat] = parseFloat((sum / count).toFixed(2));
      }
    }
    
    await db.collection('places').doc(placeId).set({
      avgRating: parseFloat(avgRating.toFixed(2)),
      reviewCount,
      categoryRatings,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    
    console.log(`[aggregatePlaceRatings] ✅ place=${placeId} avg=${avgRating.toFixed(2)} count=${reviewCount}`);
    return null;
  });
```

`functions/src/index.ts`'e export ekle:

```typescript
export { aggregatePlaceRatings } from './places/aggregate_place_ratings';
```

Deploy:
```bash
cd functions
npm run build
firebase deploy --only functions:aggregatePlaceRatings
```

> [!IMPORTANT]
> Bu function `onWrite` olarak tanımlı — yani aynı `reviews/{reviewId}` doc değişikliği `aggregateUniversityRatings`, `aggregateDepartmentRatings` ve `aggregatePlaceRatings`'i de tetikler. Ama her function `type` filtrelediği için sadece kendi alanını güncelliyor. Function başında early return ile maliyet düşük.

#### Adım 2: `ReviewRepository`'a Place Methods (45dk)

`lib/features/reviews/data/review_repository.dart`'a Place için metodlar ekle (mevcut `getUniversityReviews` pattern'ini izle):

```dart
Stream<List<ReviewModel>> getPlaceReviews(
  String placeId, {
  ReviewFilter filter = ReviewFilter.newest,
  int limit = 20,
}) {
  Query<Map<String, dynamic>> query = _reviewsRef
      .where('targetId', isEqualTo: placeId)
      .where('type', isEqualTo: 'place')
      .where('isApproved', isEqualTo: true);
  
  switch (filter) {
    case ReviewFilter.newest:
      query = query.orderBy('createdAt', descending: true);
      break;
    case ReviewFilter.oldest:
      query = query.orderBy('createdAt', descending: false);
      break;
    case ReviewFilter.highest:
      query = query.orderBy('overallRating', descending: true);
      break;
    case ReviewFilter.lowest:
      query = query.orderBy('overallRating', descending: false);
      break;
    case ReviewFilter.mostLiked:
      query = query.orderBy('likeCount', descending: true);
      break;
  }
  
  query = query.limit(limit);
  
  return query.snapshots().map((snap) =>
      snap.docs.map((d) => ReviewModel.fromMap(d.data(), d.id)).toList());
}

Future<int> getPlaceReviewCount(String placeId) async {
  final snap = await _reviewsRef
      .where('targetId', isEqualTo: placeId)
      .where('type', isEqualTo: 'place')
      .where('isApproved', isEqualTo: true)
      .count()
      .get();
  return snap.count ?? 0;
}
```

`review_providers.dart`'a:

```dart
final placeReviewsProvider = StreamProvider.family<List<ReviewModel>,
    ({String placeId, ReviewFilter filter})>((ref, params) {
  return ref.read(reviewRepositoryProvider).getPlaceReviews(
    params.placeId,
    filter: params.filter,
  );
});
```

#### Adım 3: `app_constants.dart` — Place Pros/Cons Tag'leri (15dk)

Place yorum yazma akışında "İyi yönleri" ve "Olumsuz yönleri" tag picker'ı için. `app_constants.dart`'a:

```dart
class AppConstants {
  // Mevcut tag'ler...
  
  // Place yorumu için
  static const List<String> placePros = [
    // Genel pozitif
    'Sessiz', 'Geniş', 'Hızlı Wi-Fi', 'Bol Priz', 'Temiz', 'Güvenli',
    'Açık 7/24', 'Manzaralı', 'Ferah Atmosfer', 'Uygun Fiyat',
    
    // Cafe-spesifik
    'Lezzetli Kahve', 'Geniş Menü', 'Çalışmaya Uygun', 'Grup Çalışması İçin İdeal',
    
    // Yurt-spesifik
    'Kampüse Yakın', 'Modern Tesis', 'Sıcak Yemek', 'Çamaşırhane',
    
    // Kütüphane-spesifik
    'Sessiz Çalışma Salonu', 'Grup Odası', 'Geniş Koleksiyon',
  ];
  
  static const List<String> placeCons = [
    // Genel negatif
    'Kalabalık', 'Pahalı', 'Yavaş Servis', 'Gürültülü', 'Soğuk',
    'Az Priz', 'Yetersiz Wi-Fi', 'Kötü Konum', 'Az Yer',
    
    // Cafe-spesifik
    'Bekleme Süresi Uzun', 'Sınırlı Menü',
    
    // Yurt-spesifik
    'Eski Tesis', 'Sınırlı Kontenjan', 'Yemekler Vasat',
    
    // Kütüphane-spesifik
    'Yer Bulmak Zor', 'Sessizlik İhlal Ediliyor', 'Kısıtlı Saatler',
  ];
}
```

#### Adım 4: Test (30dk)

Manuel doğrulama:
1. Firebase Console → Functions → `aggregatePlaceRatings` deployed mi? Logs temiz mi?
2. Test akışı: Bir place'e elle bir review eklemek için Firestore Console → `reviews` koleksiyonuna manuel doc ekle:
```json
{
  "type": "place",
  "targetId": "odtu_cafe_padam_coffee_co",
  "universityId": "odtu",
  "userId": "test_user_id",
  "overallRating": 4.5,
  "categoryRatings": { "Ortam": 5, "Fiyat": 4, "Temizlik": 5, "Hizmet": 4 },
  "comment": "Test yorumu",
  "isApproved": true,
  "isFlagged": false,
  "likeCount": 0,
  "createdAt": "<şu an>"
}
```
3. 5 saniye bekle → `places/odtu_cafe_padam_coffee_co` doc'una bak: `avgRating: 4.5`, `reviewCount: 1`, `categoryRatings` dolu mu?
4. Test review'unu sil → 5sn bekle → place agg sıfırlandı mı?

> [!TIP]
> Test review'unu silmeyi unutmayın yoksa Day 4'te Yorumlar bölümünde sahte yorum gözükür.

**Kişi B — `PlaceDetailScreen` Tam Hali + `DormInfoCard` + `PlaceAmenitiesGrid`**

#### Adım 1: `DormInfoCard` Widget (60dk)

Yurt için özel bilgi kartı — KYK/Özel ve Kız/Erkek/Karma görsel ayrımı.

`lib/features/places/presentation/widgets/dorm_info_card.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/place_model.dart';

class DormInfoCard extends StatelessWidget {
  final PlaceModel place;
  
  const DormInfoCard({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final isKyk = (place.dormType ?? '').toUpperCase().contains('KYK');
    final genderType = place.dormGenderType?.toLowerCase() ?? '';
    final genderInfo = _getGenderInfo(genderType);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isKyk ? const Color(0xFFE3F2FD) : const Color(0xFFFFF3E0),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: (isKyk ? const Color(0xFF0D47A1) : const Color(0xFFE65100))
              .withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bed_rounded, size: 20,
                color: isKyk ? const Color(0xFF0D47A1) : const Color(0xFFE65100)),
              const SizedBox(width: 8),
              Text('Yurt Bilgileri', style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isKyk ? const Color(0xFF0D47A1) : const Color(0xFFE65100),
              )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.business_rounded,
                  label: 'Tür',
                  value: place.dormType ?? '-',
                  color: isKyk ? const Color(0xFF0D47A1) : const Color(0xFFE65100),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  icon: genderInfo.icon,
                  label: 'Kontenjan',
                  value: place.dormGenderType ?? '-',
                  color: genderInfo.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  ({IconData icon, Color color}) _getGenderInfo(String gender) {
    if (gender.contains('kız')) {
      return (icon: Icons.female_rounded, color: const Color(0xFFEC4899));
    } else if (gender.contains('erkek')) {
      return (icon: Icons.male_rounded, color: const Color(0xFF3B82F6));
    } else if (gender.contains('karma')) {
      return (icon: Icons.people_outline_rounded, color: AppColors.success);
    }
    return (icon: Icons.help_outline_rounded, color: AppColors.textSecondary);
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
              )),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
```

#### Adım 2: `PlaceAmenitiesGrid` Widget (30dk)

Mekan özelliklerini grid olarak gösteren küçük widget:

`lib/features/places/presentation/widgets/place_amenities_grid.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class PlaceAmenitiesGrid extends StatelessWidget {
  final List<String> amenities;
  final int? maxVisible;
  
  const PlaceAmenitiesGrid({
    super.key,
    required this.amenities,
    this.maxVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) return const SizedBox.shrink();
    
    final visible = maxVisible != null && amenities.length > maxVisible!
        ? amenities.take(maxVisible!).toList()
        : amenities;
    final hiddenCount = amenities.length - visible.length;
    
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        ...visible.map((a) => _AmenityChip(label: a, icon: _iconFor(a))),
        if (hiddenCount > 0)
          _AmenityChip(label: '+$hiddenCount', icon: Icons.more_horiz_rounded),
      ],
    );
  }
  
  IconData _iconFor(String amenity) {
    final l = amenity.toLowerCase();
    if (l.contains('wi-fi') || l.contains('wifi')) return Icons.wifi_rounded;
    if (l.contains('priz')) return Icons.power_rounded;
    if (l.contains('sessiz')) return Icons.volume_off_rounded;
    if (l.contains('7/24') || l.contains('açık')) return Icons.schedule_rounded;
    if (l.contains('kız')) return Icons.female_rounded;
    if (l.contains('erkek')) return Icons.male_rounded;
    if (l.contains('karma')) return Icons.people_outline_rounded;
    if (l.contains('kyk')) return Icons.account_balance_rounded;
    if (l.contains('özel')) return Icons.business_rounded;
    if (l.contains('kütüphane')) return Icons.local_library_rounded;
    return Icons.check_circle_outline_rounded;
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;
  final IconData icon;
  
  const _AmenityChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
```

#### Adım 3: `PlaceDetailScreen` Tam Hali (90dk)

`lib/features/places/presentation/screens/place_detail_screen.dart`:

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../reviews/domain/models/review_model.dart';
import '../../../reviews/presentation/providers/review_providers.dart';
import '../../../reviews/presentation/widgets/review_card.dart';
import '../../domain/models/place_model.dart';
import '../providers/place_providers.dart';
import '../widgets/place_type_chip.dart';
import '../widgets/dorm_info_card.dart';
import '../widgets/place_amenities_grid.dart';

class PlaceDetailScreen extends ConsumerStatefulWidget {
  final String placeId;
  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  ReviewFilter _filter = ReviewFilter.newest;
  
  @override
  Widget build(BuildContext context) {
    final placeAsync = ref.watch(placeWatchProvider(widget.placeId));
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: placeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (place) {
          if (place == null) {
            return Center(
              child: EmptyStateWidget(
                icon: Icons.error_outline,
                title: 'Mekan bulunamadı',
                description: 'Bu mekan silinmiş olabilir.',
              ),
            );
          }
          return _buildContent(place);
        },
      ),
    );
  }
  
  Widget _buildContent(PlaceModel place) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(place),
        SliverToBoxAdapter(child: _buildHeader(place)),
        if (place.type == PlaceType.dorm) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: DormInfoCard(place: place)),
        ],
        SliverToBoxAdapter(child: _buildInfoSection(place)),
        if (place.amenities.isNotEmpty)
          SliverToBoxAdapter(child: _buildAmenitiesSection(place)),
        SliverToBoxAdapter(child: _buildActionsBar(place)),
        SliverToBoxAdapter(child: _buildReviewsHeader(place)),
        _buildReviewsList(place),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
  
  Widget _buildAppBar(PlaceModel place) {
    return SliverAppBar(
      expandedHeight: place.imageUrls.isNotEmpty ? 240 : 0,
      pinned: true,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: Colors.white70, shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_rounded, size: 20),
        ),
      ),
      flexibleSpace: place.imageUrls.isNotEmpty
        ? FlexibleSpaceBar(
            background: PageView.builder(
              itemCount: place.imageUrls.length,
              itemBuilder: (_, i) => CachedNetworkImage(
                imageUrl: place.imageUrls[i],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.surfaceVariant),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  child: Icon(place.type.icon, size: 80, color: AppColors.primary),
                ),
              ),
            ),
          )
        : null,
      title: place.imageUrls.isEmpty
        ? Text(place.name, style: AppTextStyles.titleMedium)
        : null,
    );
  }
  
  Widget _buildHeader(PlaceModel place) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlaceTypeChip(type: place.type),
              if (place.priceRange != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(place.priceRange!,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.success, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(place.name, style: AppTextStyles.headlineLarge),
          if (place.address.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(child: Text(place.address,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary))),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _buildRatingRow(place),
        ],
      ),
    );
  }
  
  Widget _buildRatingRow(PlaceModel place) {
    return Row(
      children: [
        if (place.avgRating > 0) ...[
          Icon(Icons.star_rounded, size: 18, color: AppColors.ratingStar),
          const SizedBox(width: 4),
          Text(place.avgRating.toStringAsFixed(1),
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Text('(${place.reviewCount} yorum)',
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
        ] else
          Text('Henüz değerlendirilmedi',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textTertiary, fontStyle: FontStyle.italic)),
        if (place.externalRating != null) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Google ', style: AppTextStyles.labelSmall.copyWith(
                color: const Color(0xFF1B5E20), fontWeight: FontWeight.w700)),
              Icon(Icons.star_rounded, size: 12, color: const Color(0xFF1B5E20)),
              const SizedBox(width: 2),
              Text(place.externalRating!.toStringAsFixed(1),
                style: AppTextStyles.labelSmall.copyWith(
                  color: const Color(0xFF1B5E20), fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ],
    );
  }
  
  Widget _buildInfoSection(PlaceModel place) {
    if (place.description.isEmpty && place.openHours == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (place.description.isNotEmpty) ...[
            Text('Hakkında', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Text(place.description,
              style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
          ],
          if (place.openHours != null) ...[
            if (place.description.isNotEmpty) const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.schedule_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Açılış Saatleri: ',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
              Text(place.openHours!,
                style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
            ]),
          ],
        ],
      ),
    );
  }
  
  Widget _buildAmenitiesSection(PlaceModel place) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Özellikler', style: AppTextStyles.titleSmall),
          const SizedBox(height: 12),
          PlaceAmenitiesGrid(amenities: place.amenities),
        ],
      ),
    );
  }
  
  Widget _buildActionsBar(PlaceModel place) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _openMap(place),
              icon: const Icon(Icons.map_rounded, size: 18),
              label: const Text('Haritada Aç'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context.push(
                '/write-review?type=place&placeId=${place.id}'),
              icon: const Icon(Icons.rate_review_rounded, size: 18),
              label: const Text('Yorum Yaz'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _openMap(PlaceModel place) async {
    final query = Uri.encodeComponent('${place.name} ${place.address}');
    final url = Uri.parse('https://www.google.com/maps/search/$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
  
  Widget _buildReviewsHeader(PlaceModel place) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
      child: Row(
        children: [
          Text('Yorumlar', style: AppTextStyles.headlineMedium),
          const Spacer(),
          PopupMenuButton<ReviewFilter>(
            initialValue: _filter,
            onSelected: (f) => setState(() => _filter = f),
            itemBuilder: (_) => const [
              PopupMenuItem(value: ReviewFilter.newest, child: Text('En yeni')),
              PopupMenuItem(value: ReviewFilter.oldest, child: Text('En eski')),
              PopupMenuItem(value: ReviewFilter.highest, child: Text('Yüksek puan')),
              PopupMenuItem(value: ReviewFilter.mostLiked, child: Text('En beğenilen')),
            ],
            child: Row(children: [
              Icon(Icons.sort_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(_filterLabel(), style: AppTextStyles.labelMedium),
            ]),
          ),
        ],
      ),
    );
  }
  
  String _filterLabel() {
    switch (_filter) {
      case ReviewFilter.newest: return 'En yeni';
      case ReviewFilter.oldest: return 'En eski';
      case ReviewFilter.highest: return 'Yüksek puan';
      case ReviewFilter.lowest: return 'Düşük puan';
      case ReviewFilter.mostLiked: return 'En beğenilen';
    }
  }
  
  Widget _buildReviewsList(PlaceModel place) {
    final reviewsAsync = ref.watch(placeReviewsProvider(
      (placeId: place.id, filter: _filter),
    ));
    return reviewsAsync.when(
      loading: () => const SliverToBoxAdapter(child: ShimmerList(itemCount: 2)),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Yorumlar yüklenemedi: $e'),
        ),
      ),
      data: (reviews) {
        if (reviews.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: EmptyStateWidget(
                icon: Icons.rate_review_outlined,
                title: 'Henüz yorum yok',
                description: 'İlk yorum yapan siz olun!',
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => ReviewCard(review: reviews[i]),
            childCount: reviews.length,
          ),
        );
      },
    );
  }
}
```

> [!IMPORTANT]
> `place_amenities_grid.dart`, `dorm_info_card.dart`, `place_type_chip.dart` ve `review_card.dart` import'larının tümü doğru olmalı. Kişi A'nın `placeReviewsProvider`'ı yazdıktan sonra import'u çalışacak.

#### Adım 4: Test (30dk)

1. Uygulamayı çalıştır
2. ODTÜ → "Padam Coffee Co." kartına tıkla → detay ekranı açıldı mı?
3. Bölümler:
   - ✅ Foto yer tutucu (icon)
   - ✅ Type chip + price badge
   - ✅ İsim + adres
   - ✅ Google rating badge
   - ✅ Hakkında bölümü
   - ✅ "Haritada Aç" + "Yorum Yaz" butonları
   - ✅ "Yorumlar" başlığı + sort dropdown
   - ✅ Empty state ("Henüz yorum yok")
4. Bir yurt mekanına git (örn. ODTÜ → "Tahsin Banguoğlu KYK") → `DormInfoCard` görünüyor mu? KYK + Erkek badge'leri doğru renkte mi?
5. "Haritada Aç" butonu → Google Maps açıldı mı?
6. "Yorum Yaz" butonu → henüz tam çalışmayacak (place yorum desteği Day 4'te) — sadece route'un patladığını test et

### 🌆 Akşam Buluşması (30dk)

**1. Demo (15dk)**
- Kişi A: Cloud Function logs'unu Console'dan göster — manuel review eklendi → place doc güncellendi mi?
- Kişi B: Place detail ekranını canlı uygulamada göster — kafe, yurt, kütüphane için sırayla aç

**2. Ortak Test: Cross-User Akış (10dk)**
- İki cihazda (veya bir cihaz + Console) test:
  - Cihaz 1 (Console): Place'e manuel review yaz → `isApproved: true`
  - Cihaz 2 (uygulama): Aynı place detayını aç → 5sn içinde "1 yorum" gözüküyor mu?

**3. Yarın Planı (5dk)**

```bash
git push origin feat/sprint4-data-backend
git push origin feat/sprint4-ui-views
```

Yarın:
- Day 4: Checkpoint 1 (mid-sprint sync) + Place yorum yazma akışı entegre olacak
- A: `WriteReviewScreen` place desteği
- B: Place yorum tamamlanınca yorum kart akışı

### ✅ Gün 3 Bitişinde Durum

- [ ] `aggregatePlaceRatings` Cloud Function deploy edildi, manuel test ile çalıştığı doğrulandı
- [ ] `ReviewRepository.getPlaceReviews` ve `placeReviewsProvider` hazır
- [ ] `app_constants.dart`'ta `placePros` ve `placeCons` tag listesi var
- [ ] `DormInfoCard` widget'ı tam (KYK/Özel + Kız/Erkek/Karma görsel ayrımı)
- [ ] `PlaceAmenitiesGrid` icon mapping ile çalışıyor
- [ ] `PlaceDetailScreen` tam: hero image, type chip, ratings, info, amenities, actions, reviews
- [ ] Yurt detayında `DormInfoCard` öne çıkıyor, kafe/kütüphanede çıkmıyor
- [ ] "Haritada Aç" butonu Google Maps'i açıyor
- [ ] "Yorumlar" bölümü empty state çalışıyor (henüz yorum olmadığı için)

---


## 📆 GÜN 4: Checkpoint 1 & Place Yorumları

> **Hedef:** Sprint'in yarısındayız. Mekan sistemi yorum yazılabilir hale geldi (`WriteReviewScreen` place destekli), ilk gerçek place yorumu yazıldı, akış uçtan uca çalışıyor. Sprint 4'ün geri kalanı için risk değerlendirmesi yapıldı.

### 🌅 Sabah — Birlikte: Checkpoint 1 (45dk)

Bu Sprint 4'ün **mid-sprint sync** noktası. Sprint 3'te de yapmıştınız (Gün 4'te), aynı pattern.

**1. Sprint Sağlık Kontrolü (15dk)**

Şu soruları samimi cevaplayın:

| Soru | Cevap | Aksiyon |
|------|-------|---------|
| Place sistemi planlandığı gibi mi gidiyor? | E/H | H ise: Day 5'te scope kısıtla |
| 509 mekan Firestore'da, kullanıcı görebiliyor mu? | E/H | H ise: bugün öncelik |
| Cloud Function deploy ile sıkıntı var mı? | E/H | H ise: Day 5'te FCM'e geçmeden çöz |
| Mood nasıl? Yorgun musun? | İyi/Orta/Yorgun | Yorgun ise yarına 2 saat fazla bırak |

**2. "Sprint Sonu" Senaryosu (15dk)**

Şu soruyu cevaplayın: "Bugün Day 4. Eğer Sprint 4 yarın akşam bitseydi, neyi mutlaka yetiştirmiş olmamız gerekirdi?"

Cevap muhtemelen: 
- ✅ Place sistemi tam (yorum dahil)
- ⚠️ Karşılaştırma yarım (tasarım hazır, hesaplama eksik)
- ❌ Bildirim sistemi yok

→ Bu **acil senaryoda** kabul edilebilir. Yani place sistemi bitirilmesi GERÇEKTEN kritik.

**3. Risk Listesi Güncelleme (10dk)**

Sprint başında yazdığınız risklere bakın:
- Hangileri hala risk?
- Hangi yenileri çıktı?
- Hangileri çözüldü?

Yeni risk: "Cloud Function deploy zincirinde sorun" → Dün test etti misin?

**4. Tatlı Bir Mola (5dk)**

Bir kahve molası verin. Sprint'in ortasındasınız, kafa dağıtmak iyi gelecek.

### 🌞 Gün İçi — Paralel (3.5 saat)

**Kişi A — `WriteReviewScreen` Place Desteği + Profile Place Yorumları**

#### Adım 1: `WriteReviewScreen` Place Desteği (90dk)

`lib/features/reviews/presentation/screens/write_review_screen.dart`'taki yorum yazma ekranını place için adapte et. Mevcut akış (`university` ve `department` için) zaten var — `place` için extension yapacaksın.

**Mevcut yapı:** Bu ekran route ile şöyle çağrılıyor:
- `/write-review?type=university&universityId=odtu` (Sprint 3)
- `/write-review?type=department&departmentId=...&universityId=odtu` (Sprint 3)
- `/write-review?type=place&placeId=odtu_cafe_padam_coffee_co` (Sprint 4 — YENİ)

**Mevcut `_categories` getter'ını güncelle:**

```dart
List<String> get _categories {
  switch (widget.type) {
    case ReviewType.university:
      return AppConstants.universityRatingCategories;
    case ReviewType.department:
      return AppConstants.departmentRatingCategories;
    case ReviewType.place:
      return AppConstants.placeRatingCategories;  // ['Ortam','Fiyat','Temizlik','Hizmet']
  }
}

List<String> get _availablePros {
  switch (widget.type) {
    case ReviewType.university:
      return AppConstants.universityPros;
    case ReviewType.department:
      return AppConstants.departmentPros;
    case ReviewType.place:
      return AppConstants.placePros;
  }
}

List<String> get _availableCons {
  switch (widget.type) {
    case ReviewType.university:
      return AppConstants.universityCons;
    case ReviewType.department:
      return AppConstants.departmentCons;
    case ReviewType.place:
      return AppConstants.placeCons;
  }
}
```

**`targetId` ve `universityId` doğru set edilmeli:**

```dart
@override
void initState() {
  super.initState();
  _initTargetData();
}

Future<void> _initTargetData() async {
  switch (widget.type) {
    case ReviewType.university:
      _targetId = widget.universityId!;
      _universityId = widget.universityId!;
      break;
    case ReviewType.department:
      _targetId = widget.departmentId!;
      _universityId = widget.universityId!;
      break;
    case ReviewType.place:
      // Place için: targetId = placeId, universityId place'ten gelir
      _targetId = widget.placeId!;
      final place = await ref.read(placeRepositoryProvider).getPlace(widget.placeId!);
      if (place == null) {
        if (mounted) {
          context.pop();
          // Snackbar: "Mekan bulunamadı"
        }
        return;
      }
      _universityId = place.universityId;
      break;
  }
  setState(() {});
}
```

**Ekran başlığı:**

```dart
String get _screenTitle {
  switch (widget.type) {
    case ReviewType.university: return 'Üniversite Değerlendir';
    case ReviewType.department: return 'Bölüm Değerlendir';
    case ReviewType.place: return 'Mekan Değerlendir';
  }
}
```

**Validation:** Place yorumlarında `comment` minimum 20 karakter (uni/dept'te 30'du — mekan yorumları kısa olabilir):

```dart
int get _minCommentLength {
  switch (widget.type) {
    case ReviewType.place: return 20;
    default: return 30;
  }
}
```

**Submit'te `ReviewModel` oluşturma:** Mevcut akış aynı kalır — type otomatik gelir, targetId ve universityId yukarıda set edildi. Sadece dikkat:

```dart
final review = ReviewModel(
  id: '',  // Firestore generate edecek
  type: widget.type,
  targetId: _targetId,
  universityId: _universityId,
  userId: currentUser.uid,
  // ... diğer alanlar
);

await ref.read(reviewRepositoryProvider).submitReview(review);
```

#### Adım 2: Router'a Place Write-Review Route'u Ekle (15dk)

`app_router.dart`'taki mevcut `/write-review` route'unu genişlet:

```dart
GoRoute(
  path: '/write-review',
  builder: (context, state) {
    final typeStr = state.uri.queryParameters['type'] ?? 'university';
    final type = ReviewType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => ReviewType.university,
    );
    
    return WriteReviewScreen(
      type: type,
      universityId: state.uri.queryParameters['universityId'],
      departmentId: state.uri.queryParameters['departmentId'],
      placeId: state.uri.queryParameters['placeId'],  // YENİ
    );
  },
),
```

`WriteReviewScreen` constructor'ında yeni parametre:

```dart
class WriteReviewScreen extends ConsumerStatefulWidget {
  final ReviewType type;
  final String? universityId;
  final String? departmentId;
  final String? placeId;  // YENİ
  
  const WriteReviewScreen({
    super.key,
    required this.type,
    this.universityId,
    this.departmentId,
    this.placeId,
  });
  // ...
}
```

#### Adım 3: Profile Yorumlar Listesinde Place Desteği (45dk)

Profile ekranında "Yorumlarım" sekmesinde (Sprint 3'te yapıldı) place yorumları da gözükmeli. `getMyReviews` zaten type filtrelemeden çekiyor — sorun, `ReviewCard`'ın hangi target'a referans verdiğinin gösterimi.

Mevcut `ReviewCard`'ta target adı şöyle gösteriliyor (uni/dept için):
```dart
// targetName: "ODTÜ" veya "Bilgisayar Mühendisliği"
```

Place için `targetName: "Padam Coffee Co."` olmalı. `ReviewCard`'a opsiyonel `targetSubtitle` eklenebilir (üst satıra "🍷 Padam Coffee Co. (ODTÜ)" şeklinde).

```dart
class ReviewCard extends ConsumerWidget {
  final ReviewModel review;
  final bool showTargetInfo;  // Profile listesinde true
  
  const ReviewCard({
    super.key,
    required this.review,
    this.showTargetInfo = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTargetInfo) _buildTargetHeader(ref),
        // ... mevcut kart içeriği
      ],
    );
  }
  
  Widget _buildTargetHeader(WidgetRef ref) {
    switch (review.type) {
      case ReviewType.place:
        final placeAsync = ref.watch(placeDetailProvider(review.targetId));
        return placeAsync.when(
          loading: () => const SizedBox(height: 24),
          error: (_, __) => const SizedBox(),
          data: (place) {
            if (place == null) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                Icon(place.type.icon, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${place.name} • ${place.type.label}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ]),
            );
          },
        );
      case ReviewType.university:
        // Mevcut akış
        // ...
        return const SizedBox.shrink();
      case ReviewType.department:
        // Mevcut akış
        // ...
        return const SizedBox.shrink();
    }
  }
}
```

#### Adım 4: Test (45dk)

Uçtan uca place yorum yazma akışı:

1. Uygulamayı `flutter run`
2. ODTÜ → Mekanlar → "Padam Coffee Co." → Detay
3. "Yorum Yaz" → `WriteReviewScreen` açıldı mı? Başlık "Mekan Değerlendir" mi?
4. Kategoriler `Ortam`, `Fiyat`, `Temizlik`, `Hizmet` mi?
5. Pros/Cons listeleri `placePros` ve `placeCons` mu?
6. Yorum yaz: 4.5 puan, 30 karakter+, "Lezzetli Kahve" pros, gönder
7. Submit → Firestore Console:
   - `reviews/{newId}` doc oluştu mu?
   - `type: "place"`, `targetId: "odtu_cafe_padam_coffee_co"`, `universityId: "odtu"`?
   - `isApproved: true` mu? (Trust score yüksekse evet)
8. Place detayına geri dön → Yorum kartı listede görünüyor mu?
9. 5 saniye bekle → place doc'ta `avgRating`, `reviewCount`, `categoryRatings` güncellendi mi?
10. Profile → Yorumlarım → place yorumun listede mi? Üst satırda "🍷 Padam Coffee Co. • Kafe" göründü mü?

**Kişi B — Sprint 4 Önemli UI Polish: Loading States, Error States, Empty States**

Place sisteminin görsel polish'i. Day 3'te ana yapı kuruldu, bugün finalize.

#### Adım 1: Place Detay Loading Skeleton (45dk)

Mevcut detay ekranı `CircularProgressIndicator` kullanıyor — ucuza kaçıyor. Sprint 3'teki shimmer pattern'ini place için adapte et:

`lib/features/places/presentation/widgets/place_detail_skeleton.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class PlaceDetailSkeleton extends StatelessWidget {
  const PlaceDetailSkeleton({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: AppColors.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 80, height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Container(width: double.infinity, height: 28, color: Colors.white),
            const SizedBox(height: 8),
            Container(width: 200, height: 16, color: Colors.white),
            const SizedBox(height: 24),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

`PlaceDetailScreen`'da `loading` callback'inde kullan:

```dart
loading: () => const PlaceDetailSkeleton(),
```

#### Adım 2: Empty State'leri Zenginleştir (30dk)

Boğaziçi, Koç, Sabancı gibi mekan verisi olmayan üniler için "Henüz mekan eklenmedi" çok kuru. Aşağıdaki gibi zengin bir empty state yap:

```dart
class _PlacesEmptyState extends StatelessWidget {
  const _PlacesEmptyState();
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.place_outlined, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Bu üniversite için mekan ekleniyor',
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Çok yakında bu üniversitenin kafeleri, yurtları ve kütüphaneleri burada listelenecek.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
```

#### Adım 3: Place Card Hover/Press Animation (30dk)

Sprint 3'te review kartlarında basınca ufak scale animasyonu vardı. Place kart için aynısını ekle:

```dart
// place_card.dart içinde
class PlaceCard extends ConsumerStatefulWidget {
  // mevcut alanlar...
}

class _PlaceCardState extends ConsumerState<PlaceCard> 
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(_controller);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: _buildCard(),
      ),
    );
  }
  // _buildCard() = mevcut Container
}
```

#### Adım 4: Yorum Yazma Butonunda Login Check (30dk)

Şu anda "Yorum Yaz" butonu giriş yapmamış kullanıcı için bile çalışıyor → `WriteReviewScreen` muhtemelen patlıyor. Doğru pattern:

```dart
ElevatedButton.icon(
  onPressed: () {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      // Giriş yapma diyaloğu
      _showLoginPromptDialog(context);
      return;
    }
    if (!user.isVerified) {
      // .edu.tr doğrulanmamış
      _showVerificationRequiredDialog(context);
      return;
    }
    context.push('/write-review?type=place&placeId=${place.id}');
  },
  // ...
),
```

`_showLoginPromptDialog` için Sprint 3'te yapılan reusable widget'ı kullan (varsa). Yoksa hızlıca:

```dart
void _showLoginPromptDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Yorum yapmak için giriş yapın'),
      content: const Text('Mekanlara yorum yazmak için giriş yapmanız gerekiyor.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            context.push('/login');
          },
          child: const Text('Giriş Yap'),
        ),
      ],
    ),
  );
}
```

### 🌆 Akşam Buluşması — Sprint Demo (45dk)

Day 4'ün akşamı önemli — Sprint 4'ün ortasıyız ve **demo edilebilir bir uygulama** olmalı.

**1. Tam Akış Demo (20dk)**

İkiniz birbirinizin cihazında uygulamayı kurun, gerçek bir kullanıcı gibi:

1. Login (.edu.tr ile)
2. Anasayfada üniversite kart listesi → **YENİ** Marmara, Aydın, Medipol gibi unileri görüyor musun?
3. ODTÜ → "Mekanlar" bölümü → 18 mekan listede
4. Tip filtre "Yurt" seç → 6 yurt görünüyor
5. "Tahsin Banguoğlu KYK" → detay → DormInfoCard "KYK + Erkek" doğru
6. Geri → "Padam Coffee Co." → detay → Google rating "G ⭐4.7" görünüyor
7. "Yorum Yaz" → form açılıyor → 4 kategori (Ortam/Fiyat/Temizlik/Hizmet)
8. Yorum yaz, gönder → onay
9. Detay ekranına dön → yorum listede görünüyor
10. 5sn bekle → place avgRating güncellendi
11. Profile → "Yorumlarım" → yeni yorum tepede + "Padam Coffee Co. • Kafe" subtitle

**2. Tüm Önemli Edge Case'leri Tek Tek Test Et (15dk)**

| Edge case | Sonuç |
|-----------|-------|
| Mekan verisi olmayan üni (Boğaziçi) | Empty state |
| Çok uzun place name | Ellipsis |
| Tip filtresinde sonuç yok | "Bu kategoride mekan yok" |
| Giriş yapmadan "Yorum Yaz" | Login dialog |
| Verified olmadan "Yorum Yaz" | Verification dialog |
| Detay ekranında yavaş ağ | Skeleton göster |
| Detay ekranında olmayan placeId | "Mekan bulunamadı" |
| Foto yok | İcon yer tutucu |
| Google rating yok | Sadece avgRating göster |
| Ne avgRating ne externalRating | "Henüz değerlendirilmedi" |

**3. Sprint İlerleme Konuşması (10dk)**

Yarın Day 5'te 2 yeni feature (filtreleme + karşılaştırma) başlıyor. Bunun için yeterince enerji var mı?

- ✅ Place sistemi bitirildi (yorum dahil) — büyük başarı
- ⚠️ Karşılaştırma ekranı henüz iskelet — Day 5-6 yoğun olacak
- ❌ FCM henüz başlamadı — Day 6-8

Karar: Tempo yeterli mi? Yarın için scope kısıtlaması gerekiyor mu?

### ✅ Gün 4 Bitişinde Durum

- [ ] `WriteReviewScreen` place type için tam çalışıyor
- [ ] Place kategori barları (Ortam/Fiyat/Temizlik/Hizmet) doğru
- [ ] Place pros/cons listesi tam (placePros, placeCons)
- [ ] Place yorumu yazıldıktan 5sn içinde place agg güncel
- [ ] Profile "Yorumlarım"da place yorumu görünüyor (target subtitle ile)
- [ ] Place detail loading state shimmer
- [ ] Empty state zengin
- [ ] Card press animation ekli
- [ ] Login/verification check yorum yaz butonunda
- [ ] Checkpoint 1 yapıldı, riskler güncellendi
- [ ] Sprint progress sağlıklı görünüyor

---


## 📆 GÜN 5: Filtreleme & Karşılaştırma Veri Katmanı

> **Hedef:** Place filtreleme bottom sheet'i hazır (tip + fiyat + amenity), karşılaştırma veri katmanı (`ComparisonResult`, `ComparisonRepository`) yazıldı, karşılaştırma UI iskelet hazır.

### 🌅 Sabah Standupı (15dk)

Ortak dosya kontrolü:
- A: `comparison_repository.dart` ve `comparison_result.dart` yazıyorum, ortak dosyaya dokunmuyorum
- B: `place_filter_sheet.dart` ve `comparison_screen.dart`'ı yeniden yazıyorum (Sprint 3'ten kalan placeholder)
- Ortak dosya yok ✅

### 🌞 Gün İçi — Paralel (4 saat)

**Kişi A — Karşılaştırma Veri Katmanı + Place Filter Provider**

#### Adım 1: `ComparisonResult` Modeli (45dk)

Day 1'de API kontratı yazılı netleştirildi. Şimdi tam halini implementasyon:

`lib/features/comparison/domain/models/comparison_result.dart`:

```dart
import '../../../university/domain/models/university_model.dart';

class ComparisonResult {
  final UniversityModel uniA;
  final UniversityModel uniB;
  final Map<String, CategoryComparison> categoryComparisons;
  final ComparisonStats stats;
  final int placeCountA;
  final int placeCountB;
  
  const ComparisonResult({
    required this.uniA,
    required this.uniB,
    required this.categoryComparisons,
    required this.stats,
    required this.placeCountA,
    required this.placeCountB,
  });
  
  /// Genel puan farkı (uniA.avgRating - uniB.avgRating)
  double get overallScoreDelta => uniA.avgRating - uniB.avgRating;
  
  /// Genel "kazanan" — tie ise null
  String? get overallWinnerId {
    if (overallScoreDelta.abs() < 0.05) return null;  // tolerance
    return overallScoreDelta > 0 ? uniA.id : uniB.id;
  }
  
  /// uniA kaç kategoride önde?
  int get categoriesAWins =>
      categoryComparisons.values.where((c) => c.winnerId == uniA.id).length;
  
  /// uniB kaç kategoride önde?
  int get categoriesBWins =>
      categoryComparisons.values.where((c) => c.winnerId == uniB.id).length;
  
  /// Kaç kategoride berabere?
  int get categoriesTied =>
      categoryComparisons.values.where((c) => c.winnerId == null).length;
  
  /// Tek satırlık özet (ekran başlığı için)
  String get summaryText {
    if (overallWinnerId == null) return 'İki üniversite çok yakın';
    final winner = overallWinnerId == uniA.id ? uniA.name : uniB.name;
    return '$winner genel olarak öne çıkıyor';
  }
}

class CategoryComparison {
  final String categoryName;
  final double valueA;
  final double valueB;
  final String? winnerId;  // null = tie
  
  const CategoryComparison({
    required this.categoryName,
    required this.valueA,
    required this.valueB,
    required this.winnerId,
  });
  
  double get delta => valueA - valueB;
  double get absDelta => delta.abs();
  
  /// Yüzde farkı (görsel için)
  double get deltaPercent {
    final base = (valueA + valueB) / 2;
    if (base == 0) return 0;
    return (absDelta / base) * 100;
  }
}

class ComparisonStats {
  final int reviewCountDelta;       // A - B
  final int placeCountDelta;
  final int establishedYearDiff;    // |A.year - B.year|
  final bool sameType;              // İkisi de Devlet veya Vakıf
  final bool sameCity;
  final bool sameCampusLayout;
  
  const ComparisonStats({
    required this.reviewCountDelta,
    required this.placeCountDelta,
    required this.establishedYearDiff,
    required this.sameType,
    required this.sameCity,
    required this.sameCampusLayout,
  });
}
```

#### Adım 2: `ComparisonRepository` (60dk)

`lib/features/comparison/data/comparison_repository.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../university/data/university_repository.dart';
import '../../places/data/place_repository.dart';
import '../domain/models/comparison_result.dart';

class ComparisonRepository {
  final UniversityRepository _uniRepo;
  final PlaceRepository _placeRepo;
  final FirebaseFirestore _firestore;
  
  ComparisonRepository({
    UniversityRepository? uniRepo,
    PlaceRepository? placeRepo,
    FirebaseFirestore? firestore,
  })  : _uniRepo = uniRepo ?? UniversityRepository(),
        _placeRepo = placeRepo ?? PlaceRepository(),
        _firestore = firestore ?? FirebaseFirestore.instance;
  
  Future<ComparisonResult?> compare(String uniIdA, String uniIdB) async {
    if (uniIdA == uniIdB) {
      throw ArgumentError('İki farklı üniversite seçmelisiniz');
    }
    
    // 1. İki üniversiteyi paralel çek
    final results = await Future.wait([
      _uniRepo.getUniversity(uniIdA),
      _uniRepo.getUniversity(uniIdB),
      _placeRepo.getPlacesByUniversity(uniIdA),
      _placeRepo.getPlacesByUniversity(uniIdB),
    ]);
    
    final uniA = results[0] as dynamic;  // UniversityModel?
    final uniB = results[1] as dynamic;
    final placesA = results[2] as List;
    final placesB = results[3] as List;
    
    if (uniA == null || uniB == null) return null;
    
    // 2. Kategori karşılaştırmaları yap
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
        winnerId = null;  // tie
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
    
    // 3. Stats hesapla
    final stats = ComparisonStats(
      reviewCountDelta: uniA.reviewCount - uniB.reviewCount,
      placeCountDelta: placesA.length - placesB.length,
      establishedYearDiff: (uniA.establishedYear - uniB.establishedYear).abs(),
      sameType: uniA.type == uniB.type,
      sameCity: uniA.cityId == uniB.cityId,
      sameCampusLayout: uniA.campusLayout == uniB.campusLayout,
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
}
```

#### Adım 3: `comparison_providers.dart` (30dk)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/comparison_repository.dart';
import '../../domain/models/comparison_result.dart';

final comparisonRepositoryProvider = Provider<ComparisonRepository>((ref) {
  return ComparisonRepository();
});

/// Seçili iki üniversite (state)
final comparisonSelectionProvider = 
    StateNotifierProvider<ComparisonSelectionNotifier, ({String? uniIdA, String? uniIdB})>(
  (ref) => ComparisonSelectionNotifier(),
);

class ComparisonSelectionNotifier extends StateNotifier<({String? uniIdA, String? uniIdB})> {
  ComparisonSelectionNotifier() : super((uniIdA: null, uniIdB: null));
  
  void selectA(String uniId) => state = (uniIdA: uniId, uniIdB: state.uniIdB);
  void selectB(String uniId) => state = (uniIdA: state.uniIdA, uniIdB: uniId);
  void swap() => state = (uniIdA: state.uniIdB, uniIdB: state.uniIdA);
  void clear() => state = (uniIdA: null, uniIdB: null);
}

/// Karşılaştırma sonucu (her iki id seçildiğinde otomatik tetiklenir)
final comparisonResultProvider = FutureProvider<ComparisonResult?>((ref) async {
  final selection = ref.watch(comparisonSelectionProvider);
  if (selection.uniIdA == null || selection.uniIdB == null) return null;
  if (selection.uniIdA == selection.uniIdB) return null;
  
  return ref.read(comparisonRepositoryProvider).compare(
    selection.uniIdA!,
    selection.uniIdB!,
  );
});
```

#### Adım 4: Place Filter State Provider (30dk)

`lib/features/places/presentation/providers/place_filter_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/place_model.dart';

class PlaceFilterState {
  final Set<PlaceType> selectedTypes;
  final Set<String> selectedPriceRanges;  // ['₺', '₺₺', '₺₺₺']
  final Set<String> requiredAmenities;    // ['Sessiz', 'Wi-Fi'...]
  final String? searchQuery;
  
  const PlaceFilterState({
    this.selectedTypes = const {},
    this.selectedPriceRanges = const {},
    this.requiredAmenities = const {},
    this.searchQuery,
  });
  
  bool get isEmpty =>
      selectedTypes.isEmpty &&
      selectedPriceRanges.isEmpty &&
      requiredAmenities.isEmpty &&
      (searchQuery == null || searchQuery!.isEmpty);
  
  int get filterCount =>
      (selectedTypes.isNotEmpty ? 1 : 0) +
      (selectedPriceRanges.isNotEmpty ? 1 : 0) +
      (requiredAmenities.isNotEmpty ? 1 : 0) +
      (searchQuery?.isNotEmpty ?? false ? 1 : 0);
  
  PlaceFilterState copyWith({
    Set<PlaceType>? selectedTypes,
    Set<String>? selectedPriceRanges,
    Set<String>? requiredAmenities,
    String? searchQuery,
    bool clearSearch = false,
  }) {
    return PlaceFilterState(
      selectedTypes: selectedTypes ?? this.selectedTypes,
      selectedPriceRanges: selectedPriceRanges ?? this.selectedPriceRanges,
      requiredAmenities: requiredAmenities ?? this.requiredAmenities,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }
}

class PlaceFilterNotifier extends StateNotifier<PlaceFilterState> {
  PlaceFilterNotifier() : super(const PlaceFilterState());
  
  void toggleType(PlaceType type) {
    final newSet = Set<PlaceType>.from(state.selectedTypes);
    newSet.contains(type) ? newSet.remove(type) : newSet.add(type);
    state = state.copyWith(selectedTypes: newSet);
  }
  
  void togglePrice(String price) {
    final newSet = Set<String>.from(state.selectedPriceRanges);
    newSet.contains(price) ? newSet.remove(price) : newSet.add(price);
    state = state.copyWith(selectedPriceRanges: newSet);
  }
  
  void toggleAmenity(String amenity) {
    final newSet = Set<String>.from(state.requiredAmenities);
    newSet.contains(amenity) ? newSet.remove(amenity) : newSet.add(amenity);
    state = state.copyWith(requiredAmenities: newSet);
  }
  
  void setSearchQuery(String query) =>
      state = state.copyWith(searchQuery: query);
  
  void reset() => state = const PlaceFilterState();
}

/// Her uni için ayrı filter state
final placeFilterProvider =
    StateNotifierProvider.family<PlaceFilterNotifier, PlaceFilterState, String>(
  (ref, uniId) => PlaceFilterNotifier(),
);

/// Filtrelenmiş mekanlar
final filteredPlacesProvider = 
    Provider.family<AsyncValue<List<PlaceModel>>, String>((ref, uniId) {
  final placesAsync = ref.watch(placesByUniversityProvider(uniId));
  final filter = ref.watch(placeFilterProvider(uniId));
  
  return placesAsync.whenData((all) {
    if (filter.isEmpty) return all;
    
    return all.where((p) {
      // Type filter
      if (filter.selectedTypes.isNotEmpty &&
          !filter.selectedTypes.contains(p.type)) return false;
      
      // Price filter (sadece kafe için anlamlı, ama applied)
      if (filter.selectedPriceRanges.isNotEmpty &&
          (p.priceRange == null ||
           !filter.selectedPriceRanges.contains(p.priceRange))) return false;
      
      // Amenity filter (TÜM seçili amenity'ler bulunmalı)
      if (filter.requiredAmenities.isNotEmpty) {
        for (final required in filter.requiredAmenities) {
          if (!p.amenities.any((a) => a.toLowerCase().contains(required.toLowerCase()))) {
            return false;
          }
        }
      }
      
      // Search query
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final q = filter.searchQuery!.toLowerCase();
        if (!p.name.toLowerCase().contains(q) &&
            !p.address.toLowerCase().contains(q) &&
            !p.description.toLowerCase().contains(q)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  });
});
```

#### Adım 5: Test (30dk)

1. Riverpod widget tester ile bir mock uni yarat (uniA + uniB), `comparison_repository.compare()` çağır → `ComparisonResult` üretiyor mu?
2. `placeFilterProvider`'ı manipüle et — types ekleme/çıkarma çalışıyor mu?
3. `filteredPlacesProvider` çağrıldığında doğru sonuç filtreleniyor mu?

**Kişi B — `PlaceFilterSheet` UI + `ComparisonScreen` İskelet**

#### Adım 1: `PlaceFilterSheet` Bottom Sheet (90dk)

`lib/features/places/presentation/screens/place_filter_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/place_model.dart';
import '../providers/place_filter_provider.dart';

class PlaceFilterSheet extends ConsumerWidget {
  final String universityId;
  
  const PlaceFilterSheet({super.key, required this.universityId});
  
  static Future<void> show(BuildContext context, String uniId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: PlaceFilterSheet(universityId: uniId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(placeFilterProvider(universityId));
    final notifier = ref.read(placeFilterProvider(universityId).notifier);
    
    return Column(
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: AppColors.borderLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Text('Filtrele', style: AppTextStyles.headlineMedium),
              const Spacer(),
              if (!filter.isEmpty)
                TextButton(
                  onPressed: notifier.reset,
                  child: const Text('Sıfırla'),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _SectionTitle('Mekan Tipi'),
              _TypeFilters(filter: filter, notifier: notifier),
              const SizedBox(height: 24),
              _SectionTitle('Fiyat Seviyesi'),
              const SizedBox(height: 8),
              _PriceFilters(filter: filter, notifier: notifier),
              const SizedBox(height: 24),
              _SectionTitle('Özellikler'),
              const SizedBox(height: 8),
              _AmenityFilters(filter: filter, notifier: notifier),
              const SizedBox(height: 32),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.borderLight)),
          ),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: AppColors.primary,
            ),
            child: Text(
              filter.isEmpty
                ? 'Tümünü Göster'
                : 'Filtreleri Uygula (${filter.filterCount})',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(title, style: AppTextStyles.titleSmall),
    );
  }
}

class _TypeFilters extends StatelessWidget {
  final PlaceFilterState filter;
  final PlaceFilterNotifier notifier;
  const _TypeFilters({required this.filter, required this.notifier});
  
  @override
  Widget build(BuildContext context) {
    final types = [PlaceType.cafe, PlaceType.dorm, PlaceType.library];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: types.map((t) {
          final selected = filter.selectedTypes.contains(t);
          return FilterChip(
            label: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(t.icon, size: 14, color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(t.label),
            ]),
            selected: selected,
            onSelected: (_) => notifier.toggleType(t),
            backgroundColor: AppColors.surfaceVariant,
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            checkmarkColor: Colors.white,
          );
        }).toList(),
      ),
    );
  }
}

class _PriceFilters extends StatelessWidget {
  final PlaceFilterState filter;
  final PlaceFilterNotifier notifier;
  const _PriceFilters({required this.filter, required this.notifier});
  
  @override
  Widget build(BuildContext context) {
    final prices = ['₺', '₺₺', '₺₺₺'];
    final labels = ['Ekonomik', 'Orta', 'Yüksek'];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: List.generate(prices.length, (i) {
        final selected = filter.selectedPriceRanges.contains(prices[i]);
        return FilterChip(
          label: Text('${prices[i]} ${labels[i]}'),
          selected: selected,
          onSelected: (_) => notifier.togglePrice(prices[i]),
          backgroundColor: AppColors.surfaceVariant,
          selectedColor: AppColors.success,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          checkmarkColor: Colors.white,
        );
      }),
    );
  }
}

class _AmenityFilters extends StatelessWidget {
  final PlaceFilterState filter;
  final PlaceFilterNotifier notifier;
  const _AmenityFilters({required this.filter, required this.notifier});
  
  @override
  Widget build(BuildContext context) {
    // Top 8 popular amenities
    final amenities = [
      'Sessiz', 'Wi-Fi', 'Bol Priz', '7/24', 'KYK',
      'Kız Yurdu', 'Erkek Yurdu', 'Karma',
    ];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: amenities.map((a) {
        final selected = filter.requiredAmenities.contains(a);
        return FilterChip(
          label: Text(a),
          selected: selected,
          onSelected: (_) => notifier.toggleAmenity(a),
          backgroundColor: AppColors.surfaceVariant,
          selectedColor: AppColors.info,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          checkmarkColor: Colors.white,
        );
      }).toList(),
    );
  }
}
```

`PlaceList`'i `filteredPlacesProvider` kullanacak şekilde güncelle:

```dart
@override
Widget build(BuildContext context) {
  final placesAsync = widget.useFilter
      ? ref.watch(filteredPlacesProvider(widget.universityId))
      : ref.watch(placesByUniversityProvider(widget.universityId));
  // ... rest aynı
}
```

Üni detayında "Mekanlar" başlığının yanına filter butonu ekle:

```dart
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  child: Row(
    children: [
      Icon(Icons.place_rounded, color: AppColors.primary, size: 22),
      const SizedBox(width: 8),
      Text('Mekanlar', style: AppTextStyles.headlineMedium),
      const Spacer(),
      Consumer(builder: (context, ref, _) {
        final filter = ref.watch(placeFilterProvider(universityId));
        return IconButton(
          icon: Stack(children: [
            const Icon(Icons.tune_rounded),
            if (filter.filterCount > 0)
              Positioned(
                right: 0, top: 0,
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ]),
          onPressed: () => PlaceFilterSheet.show(context, universityId),
        );
      }),
    ],
  ),
),
```

#### Adım 2: `ComparisonScreen` Tam Yeniden Yazımı (60dk)

Mevcut placeholder'ı sıfırla:

`lib/features/comparison/presentation/screens/comparison_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/comparison_providers.dart';
import '../widgets/comparison_uni_picker.dart';
import '../widgets/comparison_header.dart';
import '../widgets/comparison_category_row.dart';
import '../widgets/comparison_stats_table.dart';

class ComparisonScreen extends ConsumerWidget {
  const ComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(comparisonSelectionProvider);
    final resultAsync = ref.watch(comparisonResultProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Karşılaştır'),
        actions: [
          if (selection.uniIdA != null && selection.uniIdB != null)
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: 'Yer Değiştir',
              onPressed: () => 
                ref.read(comparisonSelectionProvider.notifier).swap(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ComparisonUniPicker(
              uniIdA: selection.uniIdA,
              uniIdB: selection.uniIdB,
              onSelectA: (id) => 
                ref.read(comparisonSelectionProvider.notifier).selectA(id),
              onSelectB: (id) => 
                ref.read(comparisonSelectionProvider.notifier).selectB(id),
            ),
            
            if (selection.uniIdA == null || selection.uniIdB == null)
              Padding(
                padding: const EdgeInsets.all(40),
                child: EmptyStateWidget(
                  icon: Icons.compare_arrows_rounded,
                  title: 'İki üniversite seçin',
                  description: 'Karşılaştırmak istediğiniz üniversiteleri seçin.',
                ),
              )
            else
              resultAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Hata: $e'),
                ),
                data: (result) {
                  if (result == null) return const SizedBox();
                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      ComparisonHeader(result: result),
                      const SizedBox(height: 24),
                      _SectionTitle('Kategori Puanları'),
                      ...result.categoryComparisons.values.map(
                        (c) => ComparisonCategoryRow(
                          comparison: c,
                          uniAId: result.uniA.id,
                          uniBId: result.uniB.id,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle('Genel İstatistikler'),
                      ComparisonStatsTable(result: result),
                      const SizedBox(height: 24),
                      // Share button (Day 6'da)
                      const SizedBox(height: 80),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(children: [
        Text(title, style: AppTextStyles.titleMedium.copyWith(
          fontWeight: FontWeight.w700,
        )),
      ]),
    );
  }
}
```

#### Adım 3: `ComparisonUniPicker` Widget (45dk)

`lib/features/comparison/presentation/widgets/comparison_uni_picker.dart`:

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../university/presentation/providers/university_providers.dart';

class ComparisonUniPicker extends ConsumerWidget {
  final String? uniIdA;
  final String? uniIdB;
  final ValueChanged<String> onSelectA;
  final ValueChanged<String> onSelectB;
  
  const ComparisonUniPicker({
    super.key,
    required this.uniIdA,
    required this.uniIdB,
    required this.onSelectA,
    required this.onSelectB,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _UniSlot(
            uniId: uniIdA,
            label: 'A',
            color: AppColors.primary,
            onTap: () => _showPicker(context, ref, isA: true),
          )),
          const SizedBox(width: 12),
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('VS', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11,
            )),
          ),
          const SizedBox(width: 12),
          Expanded(child: _UniSlot(
            uniId: uniIdB,
            label: 'B',
            color: AppColors.secondary,
            onTap: () => _showPicker(context, ref, isA: false),
          )),
        ],
      ),
    );
  }
  
  void _showPicker(BuildContext context, WidgetRef ref, {required bool isA}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) {
          final uniListAsync = ref.watch(allUniversitiesProvider);
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    isA ? 'A için üniversite seç' : 'B için üniversite seç',
                    style: AppTextStyles.titleMedium,
                  ),
                ),
                Expanded(
                  child: uniListAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (unis) => ListView.builder(
                      controller: controller,
                      itemCount: unis.length,
                      itemBuilder: (_, i) {
                        final uni = unis[i];
                        // Diğer slot'ta seçili olanı disable et
                        final otherId = isA ? uniIdB : uniIdA;
                        final disabled = uni.id == otherId;
                        return ListTile(
                          enabled: !disabled,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: Text(uni.name[0],
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              )),
                          ),
                          title: Text(uni.name),
                          subtitle: Text('${uni.type} • ${uni.campusLayout.label}'),
                          trailing: disabled ? const Icon(Icons.block, size: 16) : null,
                          onTap: () {
                            Navigator.pop(context);
                            isA ? onSelectA(uni.id) : onSelectB(uni.id);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UniSlot extends ConsumerWidget {
  final String? uniId;
  final String label;
  final Color color;
  final VoidCallback onTap;
  
  const _UniSlot({
    required this.uniId,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (uniId == null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: color, size: 32),
              const SizedBox(height: 8),
              Text('Üni $label seç', style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 13,
              )),
            ],
          ),
        ),
      );
    }
    
    final uniAsync = ref.watch(universityProvider(uniId!));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: uniAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (_, __) => const Icon(Icons.error_outline),
          data: (uni) {
            if (uni == null) return const SizedBox();
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: uni.logoUrl.isNotEmpty
                    ? ClipOval(child: CachedNetworkImage(
                        imageUrl: uni.logoUrl,
                        width: 48, height: 48, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Text(
                          uni.name[0],
                          style: TextStyle(color: color, fontWeight: FontWeight.w700),
                        ),
                      ))
                    : Text(uni.name[0], style: TextStyle(
                        color: color, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                Text(
                  uni.name,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

> [!NOTE]
> `allUniversitiesProvider` ve `universityProvider` Sprint 3'te yazıldı. Yeni eklenen 8 üniversite zaten bu provider'lardan geçiyor (Day 1'de seed update edildi).

### 🌆 Akşam Buluşması (30dk)

**1. Demo (15dk)**
- Kişi A: `comparison_repository.compare()` Riverpod widget'ında çalıştır, sonucu print et — `ComparisonResult` doğru mu?
- Kişi B: 
  - Place filter sheet aç → tip + fiyat + amenity ile filtre uygula → liste güncelliyor mu?
  - Comparison ekranında 2 üni seç → VS card'ları doluyor mu? Loading ve sonra empty content görünüyor mu (kategori row'ları henüz yok)?

**2. API Tutarlılık Check (5dk)**
- `ComparisonResult` API'si `comparison_uni_picker` ile tutarlı mı?
- `placeFilterProvider` UI'da çalışıyor mu? `filterCount` doğru sayıyı veriyor mu?

**3. Yarın Planı (10dk)**

```bash
git push
```

Yarın Day 6: 
- A: FCM service implementation (token register, refresh)
- B: Comparison ekranı geri kalan widget'ları (`ComparisonHeader`, `ComparisonCategoryRow`, `ComparisonStatsTable`, `ComparisonShareCard`)

### ✅ Gün 5 Bitişinde Durum

- [ ] `ComparisonResult` ve `CategoryComparison`, `ComparisonStats` modelleri yazıldı
- [ ] `ComparisonRepository.compare()` paralel veri fetch ile çalışıyor
- [ ] `comparisonSelectionProvider` (StateNotifier) ve `comparisonResultProvider` (FutureProvider) hazır
- [ ] `placeFilterProvider` family provider, `filteredPlacesProvider` çalışıyor
- [ ] `PlaceFilterSheet` 3 filtre (tip/fiyat/amenity) ile çalışıyor
- [ ] Üni detayında "Mekanlar" başlığında filter butonu, badge ile filtre count
- [ ] `ComparisonScreen` placeholder'dan gerçek implement'a geçti
- [ ] `ComparisonUniPicker` 2 slot, slot'a tıklayınca üni picker bottom sheet
- [ ] Aynı uni iki slot'ta seçilemiyor (disabled)
- [ ] VS rozeti ortada görünüyor
- [ ] "Yer değiştir" (swap) butonu app bar'da

---


## 📆 GÜN 6: Karşılaştırma UI Finalize & FCM Setup

> **Hedef:** Karşılaştırma ekranı tamamen çalışır halde — kategori barları, istatistik tablosu, paylaş kartı. FCM kuruldu, push permission akışı, token register/refresh çalışıyor.

### 🌅 Sabah Standupı (15dk)

> [!IMPORTANT]
> **Bugün ortak dosya kritik:** `pubspec.yaml`, `main.dart`, `user_model.dart`, `auth_repository.dart`. Sabah Kişi A bunlara dokunacak — Kişi B beklemeli.

- A: `firebase_messaging` ekleyip FCM init yapacağım, `main.dart` ve `user_model.dart`'a dokunacağım. Bittiğinde haber veririm.
- B: O sırada `ComparisonHeader`, `ComparisonCategoryRow` widget'larıyla başlayacağım.

A öğleden önce iletti: "FCM kurulumu bitti, push'ladım." Sonra B `pubspec.yaml`'a `screenshot` ve `share_plus`'ı bugünden değil, dünden zaten eklemişti — sıkıntı yok.

### 🌞 Gün İçi — Paralel (4 saat)

**Kişi A — FCM Setup, Token Service, Permission**

#### Adım 1: pubspec ve native config (30dk)

```yaml
dependencies:
  # ... mevcut
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^17.2.3
  permission_handler: ^11.3.1
```

```bash
flutter pub get
cd ios && pod install && cd ..
```

**Android `AndroidManifest.xml`'a:**

```xml
<manifest ...>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <application ...>
        <!-- FCM channel default -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="default_channel_id"/>
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/notification_color"
            tools:replace="android:resource"/>
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/ic_notification"/>
    </application>
</manifest>
```

`android/app/src/main/res/values/colors.xml`:
```xml
<resources>
    <color name="notification_color">#5C6BC0</color>
</resources>
```

`android/app/src/main/res/drawable/ic_notification.xml`:
```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp"
    android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="@android:color/white"
        android:pathData="M12,22c1.1,0 2,-0.9 2,-2h-4c0,1.1 0.9,2 2,2zM18,16v-5c0,-3.07 -1.64,-5.64 -4.5,-6.32V4c0,-0.83 -0.67,-1.5 -1.5,-1.5s-1.5,0.67 -1.5,1.5v0.68C7.63,5.36 6,7.92 6,11v5l-2,2v1h16v-1l-2,-2z"/>
</vector>
```

**iOS `ios/Runner/Info.plist`'e:**

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

> [!WARNING]
> iOS push için APNs Authentication Key gerekli. Apple Dev hesabı yoksa bu adımı şimdi atla, Android-only ile ilerle. Sprint 5'te iOS'u tamamla.

#### Adım 2: `FCMService` (90dk)

`lib/features/notifications/data/fcm_service.dart`:

```dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

/// Background message handler — top-level fonksiyon olmalı
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background'da çalışır. Burada heavy iş yapma — sadece log.
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class FCMService {
  static final FCMService _instance = FCMService._();
  factory FCMService() => _instance;
  FCMService._();
  
  final _messaging = FirebaseMessaging.instance;
  final _localNotif = FlutterLocalNotificationsPlugin();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  
  bool _initialized = false;
  
  /// On-tap callback — main.dart'ta GoRouter ile bind edilir
  void Function(Map<String, dynamic> data)? onNotificationTap;
  
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    
    // 1. Background handler register
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // 2. Local notifications init (foreground gösterimi için)
    await _initLocalNotifications();
    
    // 3. Permission iste
    await requestPermission();
    
    // 4. Foreground listener
    _foregroundSub = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // 5. Token refresh listener
    _tokenRefreshSub = _messaging.onTokenRefresh.listen(_saveTokenToFirestore);
    
    // 6. Notification tap (background → foreground) listener
    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // 7. Eğer uygulama notification ile cold-start ediliyorsa
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
    
    debugPrint('[FCM] Service initialized');
  }
  
  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@drawable/ic_notification');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,  // FCM ile zaten istiyoruz
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const init = InitializationSettings(android: android, iOS: ios);
    
    await _localNotif.initialize(
      init,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          // Foreground notification'a tıklanınca
          // payload Map'e parse edilemez — sadece route string saklanır
          onNotificationTap?.call({'route': details.payload});
        }
      },
    );
    
    // Android için kanal oluştur
    const channel = AndroidNotificationChannel(
      'default_channel_id',
      'Genel Bildirimler',
      description: 'ÜniSeç bildirimleri',
      importance: Importance.high,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  
  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android 13+ için POST_NOTIFICATIONS izni
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    
    // iOS
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
           settings.authorizationStatus == AuthorizationStatus.provisional;
  }
  
  Future<void> registerToken() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final token = await _messaging.getToken();
    if (token == null) return;
    
    await _saveTokenToFirestore(token);
  }
  
  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    await _firestore.collection('users').doc(user.uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'lastTokenRefresh': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    debugPrint('[FCM] Token saved: ${token.substring(0, 20)}...');
  }
  
  /// Logout sırasında çağrılır
  Future<void> unregisterToken() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final token = await _messaging.getToken();
    if (token == null) return;
    
    await _firestore.collection('users').doc(user.uid).set({
      'fcmTokens': FieldValue.arrayRemove([token]),
    }, SetOptions(merge: true));
    
    await _messaging.deleteToken();
  }
  
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('[FCM] Subscribed to: $topic');
  }
  
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('[FCM] Unsubscribed from: $topic');
  }
  
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground: ${message.notification?.title}');
    
    final notification = message.notification;
    if (notification == null) return;
    
    // Foreground'da OS bildirimi göstermez — local_notifications ile gösteriyoruz
    _localNotif.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel_id',
          'Genel Bildirimler',
          channelDescription: 'ÜniSeç bildirimleri',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['route'] as String?,
    );
  }
  
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.messageId}');
    onNotificationTap?.call(message.data);
  }
  
  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _tokenRefreshSub?.cancel();
    await _onMessageOpenedSub?.cancel();
  }
}
```

#### Adım 3: `main.dart` Entegrasyonu (30dk)

```dart
import 'features/notifications/data/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // FCM init
  final fcm = FCMService();
  await fcm.init();
  
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  // ...
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    
    // Notification tap → router push
    FCMService().onNotificationTap = (data) {
      final route = data['route'] as String?;
      if (route != null && route.isNotEmpty) {
        // Router henüz hazır olmayabilir — postFrameCallback
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(appRouterProvider).push(route);
        });
      }
    };
  }
  // ...
}
```

#### Adım 4: Auth Akışına Token Register/Unregister (30dk)

`auth_repository.dart`'a:

```dart
import '../../notifications/data/fcm_service.dart';

class AuthRepository {
  // ... mevcut
  
  Future<UserModel> signIn(String email, String password) async {
    // ... mevcut sign in
    
    // FCM token kaydet
    await FCMService().registerToken();
    
    return userModel;
  }
  
  Future<void> signOut() async {
    // FCM token sil
    await FCMService().unregisterToken();
    
    // ... mevcut sign out
  }
}
```

`user_model.dart`'a:

```dart
class UserModel {
  // ... mevcut
  final List<String> fcmTokens;
  final NotificationPreferences notificationPrefs;
  
  // ... factory + toMap güncellemeleri
}

class NotificationPreferences {
  final bool reviewLikedEnabled;
  final bool reviewModeratedEnabled;
  final bool favoriteNewReviewEnabled;
  
  const NotificationPreferences({
    this.reviewLikedEnabled = true,
    this.reviewModeratedEnabled = true,
    this.favoriteNewReviewEnabled = true,
  });
  
  factory NotificationPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const NotificationPreferences();
    return NotificationPreferences(
      reviewLikedEnabled: map['reviewLikedEnabled'] ?? true,
      reviewModeratedEnabled: map['reviewModeratedEnabled'] ?? true,
      favoriteNewReviewEnabled: map['favoriteNewReviewEnabled'] ?? true,
    );
  }
  
  Map<String, dynamic> toMap() => {
    'reviewLikedEnabled': reviewLikedEnabled,
    'reviewModeratedEnabled': reviewModeratedEnabled,
    'favoriteNewReviewEnabled': reviewModeratedEnabled,
  };
}
```

#### Adım 5: Test (30dk)

1. `flutter run` Android cihazda
2. Login ol → Console: "[FCM] Token saved: dXyZ123..."
3. Firebase Console → Cloud Messaging → "Send test message"
4. Token'ı Firestore'dan kopyala (`users/{uid}/fcmTokens[0]`)
5. Test mesajı gönder
6. Bildirim geldi mi? Notification panel'de görünüyor mu?
7. Bildirime tıkla → uygulama açıldı mı?

> [!NOTE]
> İlk testte muhtemelen "permission denied" hatası alacaksınız. Settings → App permissions → Notifications enable. Ya da uygulamayı baştan kurun — request permission akışını yeniden tetikler.

**Kişi B — Comparison Ekran Widget'ları**

#### Adım 1: `ComparisonHeader` Widget (45dk)

`lib/features/comparison/presentation/widgets/comparison_header.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/comparison_result.dart';

class ComparisonHeader extends StatelessWidget {
  final ComparisonResult result;
  
  const ComparisonHeader({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.06),
            AppColors.secondary.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _ScoreCard(
                score: result.uniA.avgRating,
                label: result.uniA.name,
                isWinner: result.overallWinnerId == result.uniA.id,
                color: AppColors.primary,
              )),
              const SizedBox(width: 12),
              _Delta(delta: result.overallScoreDelta),
              const SizedBox(width: 12),
              Expanded(child: _ScoreCard(
                score: result.uniB.avgRating,
                label: result.uniB.name,
                isWinner: result.overallWinnerId == result.uniB.id,
                color: AppColors.secondary,
              )),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            result.summaryText,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MiniStat(
                label: 'A önde',
                value: result.categoriesAWins.toString(),
                color: AppColors.primary,
              ),
              _MiniStat(
                label: 'Berabere',
                value: result.categoriesTied.toString(),
                color: AppColors.textTertiary,
              ),
              _MiniStat(
                label: 'B önde',
                value: result.categoriesBWins.toString(),
                color: AppColors.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final double score;
  final String label;
  final bool isWinner;
  final Color color;
  
  const _ScoreCard({
    required this.score,
    required this.label,
    required this.isWinner,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: isWinner ? color : AppColors.borderLight,
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (isWinner)
            Icon(Icons.emoji_events_rounded, size: 18, color: color),
          if (isWinner) const SizedBox(height: 4),
          Text(
            score > 0 ? score.toStringAsFixed(1) : '-',
            style: AppTextStyles.headlineLarge.copyWith(
              color: color, fontWeight: FontWeight.w800, fontSize: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Delta extends StatelessWidget {
  final double delta;
  const _Delta({required this.delta});

  @override
  Widget build(BuildContext context) {
    final absDelta = delta.abs();
    final color = delta > 0.05
      ? AppColors.primary
      : (delta < -0.05 ? AppColors.secondary : AppColors.textTertiary);
    final text = absDelta < 0.05 
      ? '='
      : (delta > 0 ? '◀ ${absDelta.toStringAsFixed(1)}' : '${absDelta.toStringAsFixed(1)} ▶');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(
        color: color, fontWeight: FontWeight.w800, fontSize: 12,
      )),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.titleLarge.copyWith(
          color: color, fontWeight: FontWeight.w800)),
        Text(label, style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary)),
      ],
    );
  }
}
```

#### Adım 2: `ComparisonCategoryRow` Widget (45dk)

`lib/features/comparison/presentation/widgets/comparison_category_row.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/comparison_result.dart';

class ComparisonCategoryRow extends StatelessWidget {
  final CategoryComparison comparison;
  final String uniAId;
  final String uniBId;
  
  const ComparisonCategoryRow({
    super.key,
    required this.comparison,
    required this.uniAId,
    required this.uniBId,
  });

  @override
  Widget build(BuildContext context) {
    final aWins = comparison.winnerId == uniAId;
    final bWins = comparison.winnerId == uniBId;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comparison.categoryName,
                style: AppTextStyles.titleSmall,
              ),
              const Spacer(),
              if (comparison.absDelta > 0.05)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${comparison.absDelta.toStringAsFixed(1)} fark',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: _Bar(
                  value: comparison.valueA,
                  color: AppColors.primary,
                  isWinner: aWins,
                  alignment: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: _Bar(
                  value: comparison.valueB,
                  color: AppColors.secondary,
                  isWinner: bWins,
                  alignment: TextAlign.left,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double value;
  final Color color;
  final bool isWinner;
  final TextAlign alignment;
  
  const _Bar({
    required this.value,
    required this.color,
    required this.isWinner,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final widthFraction = (value / 5.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: alignment == TextAlign.right
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: alignment == TextAlign.right
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
          children: [
            if (isWinner) ...[
              Icon(Icons.check_circle_rounded, size: 12, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              value > 0 ? value.toStringAsFixed(1) : '-',
              style: AppTextStyles.labelMedium.copyWith(
                color: color,
                fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Sağdaki bar A için sağdan, soldaki B için soldan
            Align(
              alignment: alignment == TextAlign.right
                ? Alignment.centerRight
                : Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutQuart,
                height: 6,
                width: MediaQuery.of(context).size.width * 0.4 * widthFraction,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

#### Adım 3: `ComparisonStatsTable` Widget (30dk)

`lib/features/comparison/presentation/widgets/comparison_stats_table.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/comparison_result.dart';

class ComparisonStatsTable extends StatelessWidget {
  final ComparisonResult result;
  
  const ComparisonStatsTable({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final rows = [
      _StatRow(
        label: 'Tür',
        valueA: result.uniA.type,
        valueB: result.uniB.type,
      ),
      _StatRow(
        label: 'Şehir',
        valueA: result.uniA.cityId,  // ID, ama label resolve etmek lazım
        valueB: result.uniB.cityId,
      ),
      _StatRow(
        label: 'Kuruluş',
        valueA: result.uniA.establishedYear.toString(),
        valueB: result.uniB.establishedYear.toString(),
      ),
      _StatRow(
        label: 'Yerleşim',
        valueA: result.uniA.campusLayout.label,
        valueB: result.uniB.campusLayout.label,
      ),
      _StatRow(
        label: 'Yorum Sayısı',
        valueA: result.uniA.reviewCount.toString(),
        valueB: result.uniB.reviewCount.toString(),
      ),
      _StatRow(
        label: 'Mekan Sayısı',
        valueA: result.placeCountA.toString(),
        valueB: result.placeCountB.toString(),
      ),
    ];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final r = rows[i];
          final isLast = i == rows.length - 1;
          return Container(
            decoration: BoxDecoration(
              border: !isLast
                ? Border(bottom: BorderSide(color: AppColors.borderLight))
                : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      r.valueA,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      r.label,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      r.valueB,
                      textAlign: TextAlign.left,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StatRow {
  final String label;
  final String valueA;
  final String valueB;
  const _StatRow({required this.label, required this.valueA, required this.valueB});
}
```

#### Adım 4: `ComparisonShareCard` Widget (60dk)

Karşılaştırmayı paylaşmak için screenshot'lanabilir kompakt kart:

`lib/features/comparison/presentation/widgets/comparison_share_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/comparison_result.dart';

class ComparisonShareCard extends StatelessWidget {
  final ComparisonResult result;
  final ScreenshotController controller;
  
  const ComparisonShareCard({
    super.key,
    required this.result,
    required this.controller,
  });
  
  static Future<void> shareCard(
    BuildContext context,
    ComparisonResult result,
  ) async {
    final controller = ScreenshotController();
    final image = await controller.captureFromWidget(
      MediaQuery(
        data: MediaQuery.of(context),
        child: ComparisonShareCard(result: result, controller: controller),
      ),
      pixelRatio: 2.5,
    );
    
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/karsilastirma.png');
    await file.writeAsBytes(image);
    
    await Share.shareXFiles(
      [XFile(file.path)],
      text: '${result.uniA.name} vs ${result.uniB.name} karşılaştırması — ÜniSeç ile yap!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: controller,
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.school_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'ÜniSeç',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Karşılaştırma',
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _ShareScoreCard(
                        name: result.uniA.name,
                        score: result.uniA.avgRating,
                        color: AppColors.primary,
                        isWinner: result.overallWinnerId == result.uniA.id,
                      )),
                      const SizedBox(width: 12),
                      Text(
                        'VS',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _ShareScoreCard(
                        name: result.uniB.name,
                        score: result.uniB.avgRating,
                        color: AppColors.secondary,
                        isWinner: result.overallWinnerId == result.uniB.id,
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    result.summaryText,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'unisec.app — Türkiye\'nin üniversite rehberi',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareScoreCard extends StatelessWidget {
  final String name;
  final double score;
  final Color color;
  final bool isWinner;
  
  const _ShareScoreCard({
    required this.name,
    required this.score,
    required this.color,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isWinner)
          Icon(Icons.emoji_events_rounded, color: color, size: 24),
        if (isWinner) const SizedBox(height: 4),
        Text(
          score > 0 ? score.toStringAsFixed(1) : '-',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 36,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
```

`ComparisonScreen`'da paylaş butonu:

```dart
// AppBar actions'a ekle
IconButton(
  icon: const Icon(Icons.ios_share_rounded),
  tooltip: 'Paylaş',
  onPressed: () async {
    if (resultAsync.value != null) {
      await ComparisonShareCard.shareCard(context, resultAsync.value!);
    }
  },
),
```

### 🌆 Akşam Buluşması (35dk)

**1. FCM Test (15dk)**
- Kişi A: Console'dan test message gönder, gelmesi
- Foreground'da: Local notification göründü mü?
- Background'da: Sistem notification panel'inde göründü mü?
- Bildirime tıkla → uygulama açıldı mı?
- Logout → token Firestore'dan silindi mi?

**2. Comparison Demo (15dk)**
- Kişi B: ODTÜ vs İTÜ karşılaştırması
- Header doluyor mu? Scoreboard, summary, mini stats?
- Kategori barları yan yana, yüzdeler doğru mu?
- Stats tablosu (Tür, Şehir, Kuruluş, vb.) tüm satırları gösteriyor mu?
- Paylaş butonu → screenshot share sheet açılıyor mu? Kart estetik mi?

**3. Yarın Planı (5dk)**

Yarın Day 7:
- A: 3 notification trigger Cloud Function (onReviewLiked, onReviewModerated, onNewReviewForFavorite) + notification repository
- B: Notification bell + center screen UI + tile widget

### ✅ Gün 6 Bitişinde Durum

- [ ] `firebase_messaging` ve `flutter_local_notifications` paketleri ekli
- [ ] Android manifest + drawable + iOS Info.plist FCM ready
- [ ] `FCMService` singleton tam: init, requestPermission, registerToken, unregisterToken, subscribeToTopic
- [ ] Foreground/background/cold-start mesaj handler'ları
- [ ] `main.dart`'ta FCM init + onTap → router push
- [ ] Auth akışında token register/unregister
- [ ] `UserModel`'a `fcmTokens` ve `notificationPrefs` alanları
- [ ] Test bildirimi cihaza geliyor
- [ ] `ComparisonHeader` (skor kartları + delta + mini stats)
- [ ] `ComparisonCategoryRow` (yan yana barlar + winner check)
- [ ] `ComparisonStatsTable` (6 satır: Tür, Şehir, Kuruluş, Yerleşim, Yorum, Mekan)
- [ ] `ComparisonShareCard` screenshot+share çalışıyor
- [ ] `ComparisonScreen` AppBar'da swap + paylaş butonları

---


## 📆 GÜN 7: Bildirim Triggers & In-App UI

> **Hedef:** 3 Cloud Function deploy edildi (onReviewLiked, onReviewModerated, onNewReviewForFavorite). Notification bell + center + tile UI tamam. Gerçek bir kullanıcı eylemi (yorum like) push bildirim üretiyor.

### 🌅 Sabah Standupı (15dk)

- A: Cloud Functions + notification repository, ortak dosya yok
- B: Bell, center, tile widget'ları + AppBar entegrasyonu (`home_screen.dart`'a dokunacağım)

### 🌞 Gün İçi — Paralel (4 saat)

**Kişi A — 3 Notification Cloud Function + Notification Repository**

#### Adım 1: Helper Function (15dk)

`functions/src/notifications/helpers.ts`:

```typescript
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
```

#### Adım 2: `onReviewLiked` Function (45dk)

`functions/src/notifications/on_review_liked.ts`:

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { sendNotificationToUser } from './helpers';

const db = admin.firestore();

/**
 * Bir review like'landığında, review yazarına bildirim gönder.
 * 
 * NOT: Spam'i önlemek için "batched" yaklaşım — aynı kullanıcının
 * son 10 dakikada gönderdiği "review_liked" bildirimi varsa, yeni gönderme.
 */
export const onReviewLiked = functions
  .region('europe-west1')
  .firestore
  .document('reviews/{reviewId}/likes/{userId}')
  .onCreate(async (snap, context) => {
    const reviewId = context.params.reviewId;
    const likerUserId = context.params.userId;
    
    // 1. Review'ı çek
    const reviewDoc = await db.collection('reviews').doc(reviewId).get();
    if (!reviewDoc.exists) return null;
    const review = reviewDoc.data()!;
    
    const reviewAuthorId = review.userId as string;
    
    // 2. Kendi yorumunu beğenmemize bildirim göndermeyelim
    if (likerUserId === reviewAuthorId) return null;
    
    // 3. Liker bilgisi
    const likerDoc = await db.collection('users').doc(likerUserId).get();
    const likerName = likerDoc.exists 
      ? (likerDoc.data()!.displayName || 'Bir kullanıcı') 
      : 'Bir kullanıcı';
    
    // 4. Spam koruma: son 10 dk'da bu user'a review_liked bildirimi gitti mi?
    const tenMinAgo = admin.firestore.Timestamp.fromMillis(
      Date.now() - 10 * 60 * 1000
    );
    const recentSnap = await db.collection('notifications')
      .where('userId', '==', reviewAuthorId)
      .where('type', '==', 'review_liked')
      .where('data.reviewId', '==', reviewId)
      .where('createdAt', '>=', tenMinAgo)
      .limit(1)
      .get();
    
    if (!recentSnap.empty) {
      // Aynı yoruma yeni like geldi → sayıyı güncelle
      const recentDoc = recentSnap.docs[0];
      const currentCount = (recentDoc.data().data?.likeCount as number) || 1;
      const newCount = currentCount + 1;
      
      await recentDoc.ref.update({
        body: `${likerName} ve ${newCount - 1} kişi daha yorumunuzu beğendi`,
        'data.likeCount': newCount,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`[onReviewLiked] Updated batch notif (${newCount} likes)`);
      return null;
    }
    
    // 5. Yeni bildirim
    const reviewType = review.type as string;
    let routePath = '/';
    if (reviewType === 'university') {
      routePath = `/university/${review.targetId}`;
    } else if (reviewType === 'department') {
      routePath = `/university/${review.universityId}/department/${review.targetId}`;
    } else if (reviewType === 'place') {
      routePath = `/place/${review.targetId}`;
    }
    
    await sendNotificationToUser({
      userId: reviewAuthorId,
      type: 'review_liked',
      title: 'Yorumun beğenildi 🎉',
      body: `${likerName} yorumunuzu beğendi`,
      data: {
        route: routePath,
        reviewId,
        likeCount: '1',
      },
      prefKey: 'reviewLikedEnabled',
    });
    
    return null;
  });
```

> [!IMPORTANT]
> Like sistemini Sprint 3'te `reviews/{reviewId}/likes/{userId}` subcollection olarak yaptığını varsayıyorum. Eğer farklı yapıdaysa (örn. `likedBy` array), trigger path'i ona göre değiştir.

#### Adım 3: `onReviewModerated` Function (30dk)

`functions/src/notifications/on_review_moderated.ts`:

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { sendNotificationToUser } from './helpers';

const db = admin.firestore();

/**
 * Bir review'ın isApproved durumu değiştiğinde yorumun yazarına bildirim gönder.
 * Sadece state geçişinde tetiklenir (false → true veya silindi).
 */
export const onReviewModerated = functions
  .region('europe-west1')
  .firestore
  .document('reviews/{reviewId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const reviewId = context.params.reviewId;
    
    // isApproved değişti mi?
    if (before.isApproved === after.isApproved) return null;
    
    const userId = after.userId as string;
    if (!userId) return null;
    
    let title: string;
    let body: string;
    let routePath = '/';
    
    if (after.isApproved === true && before.isApproved === false) {
      // Onaylandı
      title = 'Yorumun onaylandı ✅';
      body = 'Yorumun yayında, başkaları görebilir.';
    } else if (after.isApproved === false && before.isApproved === true) {
      // Reddedildi (önce onaylıyken redden gelen vakası)
      title = 'Yorumun moderasyonda';
      body = 'Yorumun tekrar inceleniyor. Detay için profilini kontrol et.';
    } else {
      return null;  // Durum belirsiz
    }
    
    // Route hesapla
    const reviewType = after.type as string;
    if (reviewType === 'university') {
      routePath = `/university/${after.targetId}`;
    } else if (reviewType === 'department') {
      routePath = `/university/${after.universityId}/department/${after.targetId}`;
    } else if (reviewType === 'place') {
      routePath = `/place/${after.targetId}`;
    }
    
    await sendNotificationToUser({
      userId,
      type: 'review_moderated',
      title,
      body,
      data: { route: routePath, reviewId },
      prefKey: 'reviewModeratedEnabled',
    });
    
    return null;
  });
```

#### Adım 4: `onNewReviewForFavorite` Function (45dk)

Topic-based bildirim — favori uniye yorum gelince herkese push.

`functions/src/notifications/on_new_review_for_favorite.ts`:

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Yeni bir university review'ı onaylandığında, o üniversiteyi favoriye eklemiş
 * tüm kullanıcılara topic-based bildirim gönder.
 * 
 * Topic name: `uni_{uniId}`
 */
export const onNewReviewForFavorite = functions
  .region('europe-west1')
  .firestore
  .document('reviews/{reviewId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Sadece "approved hale geçen" review'lar
    if (before.isApproved === true || after.isApproved !== true) return null;
    
    // Sadece university review'ları (place ve department için ayrı pattern)
    if (after.type !== 'university') return null;
    
    const uniId = after.targetId as string;
    
    // Üni adını çek
    const uniDoc = await db.collection('universities').doc(uniId).get();
    const uniName = uniDoc.exists ? uniDoc.data()!.name : 'Üniversite';
    
    // Yazarın adı
    const authorDoc = await db.collection('users').doc(after.userId).get();
    const authorName = authorDoc.exists 
      ? (authorDoc.data()!.displayName || 'Biri') 
      : 'Biri';
    
    const topic = `uni_${uniId}`;
    
    await messaging.send({
      topic,
      notification: {
        title: '$uniName için yeni yorum',
        body: `${authorName} ${uniName} hakkında yorum yazdı`,
      },
      data: {
        route: `/university/${uniId}`,
        type: 'favorite_new_review',
        reviewId: context.params.reviewId,
      },
      android: {
        notification: {
          channelId: 'default_channel_id',
          priority: 'high',
        },
      },
      apns: {
        payload: { aps: { badge: 1, sound: 'default' } },
      },
    });
    
    console.log(`[onNewReviewForFavorite] ✅ Sent to topic ${topic}`);
    return null;
  });
```

> [!NOTE]
> Topic-based bildirimler `users/{uid}/notifications` doc'una yazılmıyor — performans için. Eğer in-app notification merkezinde de gösterilmesi istenirse, `sendNotificationToUser` mantığıyla birleştirilebilir, ama o zaman favori user listesini fetch'leyip her birine ayrı doc yazmak gerekiyor (1000 favori kullanıcı = 1000 yazma). Topic = O(1) maliyet. Favori bildirimleri sadece push olarak göster, in-app merkezde göstermeyebiliriz. Sprint 4 için bu kabul edilebilir kompromis.

#### Adım 5: Index Dosyası ve Deploy (15dk)

`functions/src/index.ts`'e ekle:

```typescript
export { onReviewLiked } from './notifications/on_review_liked';
export { onReviewModerated } from './notifications/on_review_moderated';
export { onNewReviewForFavorite } from './notifications/on_new_review_for_favorite';
```

Deploy:
```bash
cd functions
npm run build
firebase deploy --only functions:onReviewLiked,functions:onReviewModerated,functions:onNewReviewForFavorite
```

#### Adım 6: `NotificationRepository` (45dk)

`lib/features/notifications/data/notification_repository.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/models/app_notification.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  
  NotificationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;
  
  CollectionReference<Map<String, dynamic>> get _notifsRef =>
      _firestore.collection('notifications');
  
  Stream<List<AppNotification>> watchMyNotifications({int limit = 50}) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    
    return _notifsRef
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotification.fromMap(d.data(), d.id))
            .toList());
  }
  
  Stream<int> watchUnreadCount() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);
    
    return _notifsRef
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.size);
  }
  
  Future<void> markAsRead(String notifId) async {
    await _notifsRef.doc(notifId).update({'isRead': true});
  }
  
  Future<void> markAllAsRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    final snap = await _notifsRef
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .limit(100)
        .get();
    
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
  
  Future<void> deleteNotification(String notifId) async {
    await _notifsRef.doc(notifId).delete();
  }
}
```

`AppNotification` model:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../enums/notification_type.dart';
import '../../../../core/theme/app_colors.dart';

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? expireAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    required this.isRead,
    required this.createdAt,
    this.expireAt,
  });
  
  String? get routePath => data['route'] as String?;
  String? get reviewId => data['reviewId'] as String?;
  
  IconData get icon {
    switch (type) {
      case NotificationType.reviewLiked: return Icons.favorite_rounded;
      case NotificationType.reviewModerated: return Icons.shield_rounded;
      case NotificationType.favoriteNewReview: return Icons.fiber_new_rounded;
    }
  }
  
  Color get accentColor {
    switch (type) {
      case NotificationType.reviewLiked: return const Color(0xFFEC4899);
      case NotificationType.reviewModerated: return AppColors.success;
      case NotificationType.favoriteNewReview: return AppColors.info;
    }
  }
  
  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      userId: map['userId'] ?? '',
      type: NotificationType.fromString(map['type']),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expireAt: (map['expireAt'] as Timestamp?)?.toDate(),
    );
  }
}
```

`NotificationType` enum:

```dart
enum NotificationType {
  reviewLiked,
  reviewModerated,
  favoriteNewReview;
  
  String get firestoreValue {
    switch (this) {
      case NotificationType.reviewLiked: return 'review_liked';
      case NotificationType.reviewModerated: return 'review_moderated';
      case NotificationType.favoriteNewReview: return 'favorite_new_review';
    }
  }
  
  static NotificationType fromString(String? value) {
    switch (value) {
      case 'review_liked': return NotificationType.reviewLiked;
      case 'review_moderated': return NotificationType.reviewModerated;
      case 'favorite_new_review': return NotificationType.favoriteNewReview;
      default: return NotificationType.reviewLiked;
    }
  }
}
```

Providers:

```dart
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final myNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  return ref.read(notificationRepositoryProvider).watchMyNotifications();
});

final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  return ref.read(notificationRepositoryProvider).watchUnreadCount();
});
```

Firestore rules (`firestore.rules`):

```
match /notifications/{notifId} {
  allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
  allow update: if isAuthenticated() && 
    resource.data.userId == request.auth.uid &&
    request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isRead']);
  allow delete: if isAuthenticated() && resource.data.userId == request.auth.uid;
  // create sadece Cloud Function tarafından yapılır (admin)
  allow create: if false;
}
```

**Kişi B — Notification Bell + Center + Tile UI**

#### Adım 1: `NotificationBell` Widget (45dk)

`lib/features/notifications/presentation/widgets/notification_bell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/notification_providers.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadNotificationCountProvider);
    final unread = unreadAsync.value ?? 0;
    
    return IconButton(
      onPressed: () => context.push('/notifications'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            unread > 0 ? Icons.notifications_active_rounded : Icons.notifications_outlined,
            color: AppColors.textPrimary,
            size: 24,
          ),
          if (unread > 0)
            Positioned(
              right: -4, top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  unread > 99 ? '99+' : unread.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
      tooltip: 'Bildirimler',
    );
  }
}
```

`home_screen.dart`'taki AppBar'a ekle:

```dart
AppBar(
  // ...
  actions: [
    const NotificationBell(),
    const SizedBox(width: 8),
  ],
),
```

#### Adım 2: `NotificationTile` Widget (45dk)

`lib/features/notifications/presentation/widgets/notification_tile.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/app_notification.dart';
import '../providers/notification_providers.dart';

class NotificationTile extends ConsumerWidget {
  final AppNotification notification;
  final VoidCallback? onDismissed;
  
  const NotificationTile({
    super.key,
    required this.notification,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: AppColors.error.withValues(alpha: 0.1),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      onDismissed: (_) async {
        await ref.read(notificationRepositoryProvider)
            .deleteNotification(notification.id);
        onDismissed?.call();
      },
      child: Material(
        color: notification.isRead 
          ? AppColors.surface 
          : AppColors.primary.withValues(alpha: 0.04),
        child: InkWell(
          onTap: () async {
            // Read olarak işaretle
            if (!notification.isRead) {
              await ref.read(notificationRepositoryProvider)
                  .markAsRead(notification.id);
            }
            // Route'a git
            final route = notification.routePath;
            if (route != null && context.mounted) {
              context.push(route);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: notification.accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.accentColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeago.format(notification.createdAt, locale: 'tr'),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

#### Adım 3: `NotificationCenterScreen` (60dk)

`lib/features/notifications/presentation/screens/notification_center_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/notification_providers.dart';
import '../widgets/notification_tile.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(myNotificationsProvider);
    final unreadAsync = ref.watch(unreadNotificationCountProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          unreadAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (unread) {
              if (unread == 0) return const SizedBox();
              return TextButton.icon(
                onPressed: () async {
                  await ref.read(notificationRepositoryProvider).markAllAsRead();
                },
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text('Tümünü okundu işaretle'),
              );
            },
          ),
          IconButton(
            onPressed: () => context.push('/notification-settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Bildirim Ayarları',
          ),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const ShimmerList(itemCount: 5),
        error: (e, _) => ErrorStateWidget(message: '$e'),
        data: (notifs) {
          if (notifs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: EmptyStateWidget(
                  icon: Icons.notifications_off_outlined,
                  title: 'Bildirim yok',
                  description: 'Yorumlarınız beğenildiğinde veya favori üniversitelerinize yorum geldiğinde buradan haberdar olacaksınız.',
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifs.length,
            separatorBuilder: (_, __) => Divider(
              height: 1, thickness: 1,
              color: AppColors.borderLight,
              indent: 56,
            ),
            itemBuilder: (_, i) => NotificationTile(notification: notifs[i]),
          );
        },
      ),
    );
  }
}
```

Router'a:
```dart
GoRoute(
  path: '/notifications',
  builder: (_, __) => const NotificationCenterScreen(),
),
```

### 🌆 Akşam Buluşması (40dk)

**1. End-to-End Bildirim Testi (20dk)**

Bu Sprint 4'ün en kritik testlerinden biri. İki cihaz / hesap gerekiyor:

1. Cihaz 1 (Ali): Bir review yaz (örn. ODTÜ'ye)
2. Cihaz 2 (Ayşe): Ali'nin yorumunu beğen (like)
3. Cihaz 1 (Ali) — push bildirim geldi mi? "Yorumun beğenildi 🎉 Ayşe yorumunuzu beğendi"
4. Bildirime tıkla → ODTÜ detay sayfasına yönlendi mi?
5. Cihaz 1: Bell icon'da "1" badge görünüyor mu?
6. Bell'e tıkla → bildirim merkezi açıldı mı?
7. Bildirimi yine "okundu" olarak işaretle → badge gitti mi?

**2. Spam Koruma Testi (5dk)**

3 saniye içinde 5 farklı kullanıcı Ali'nin aynı yorumunu beğensin → Ali'ye sadece 1 bildirim gelsin (count=5 olarak güncellensin), 5 ayrı bildirim gelmesin.

**3. Moderation Bildirim Testi (10dk)**

1. Yeni bir kullanıcı (low trust) bir review yaz → otomatik `isApproved: false`
2. Admin Console'dan `isApproved: true` yap
3. Kullanıcının cihazına "Yorumun onaylandı ✅" bildirimi gelsin

**4. Yarın Planı (5dk)**

```bash
git push
```

Yarın Day 8: 
- Checkpoint 2 (mid-sprint review)
- Bildirim ayarları ekranı
- Topic subscriptions (favori uniler için)

### ✅ Gün 7 Bitişinde Durum

- [ ] `helpers.ts` — `sendNotificationToUser` ortak fonksiyon
- [ ] `onReviewLiked` deploy + spam koruma (10dk pencere) çalışıyor
- [ ] `onReviewModerated` deploy + state geçişi yakalıyor
- [ ] `onNewReviewForFavorite` deploy + topic-based çalışıyor
- [ ] `NotificationRepository` watch + markAsRead + delete
- [ ] `AppNotification` model + `NotificationType` enum
- [ ] Firestore rules: notifications koleksiyonu (user kendi okur, sadece read update edebilir)
- [ ] `NotificationBell` AppBar'da, badge çalışıyor
- [ ] `NotificationTile` ile dismissable swipe
- [ ] `NotificationCenterScreen` empty/loading/error state'leri
- [ ] "Tümünü okundu işaretle" butonu
- [ ] End-to-end test: cihaz 1 yorum yazar, cihaz 2 like'lar, cihaz 1 push alır, tıklayıp gelir

---


## 📆 GÜN 8: Checkpoint 2 & Bildirim Tercihleri

> **Hedef:** Sprint 4'te 8 gün geçti — kalan 2 gün kritik. Bildirim tercihleri ekranı tamam, topic subscriptions çalışıyor (favoriye eklemekle uni topic'e subscribe olur), checkpoint 2 yapıldı, kalan iş listesi netleşti.

### 🌅 Sabah — Birlikte: Checkpoint 2 (45dk)

İkinci ve son ara değerlendirme.

**1. Sprint Sağlık Kontrolü (15dk)**

Şu listeyi yan yana inceleyin:

| Feature | Day 8'de Olması Gereken | Şu An | Risk? |
|---------|--------------------------|-------|-------|
| Place sistemi | %100 | %100 | ✅ |
| Place yorum yazma | %100 | %100 | ✅ |
| Karşılaştırma | %95 | %?? | ?? |
| FCM kurulum | %100 | %100 | ✅ |
| Bildirim trigger'ları | %100 | %100 | ✅ |
| In-app bildirim | %100 | %100 | ✅ |
| Bildirim ayarları | %0 | %0 | bugün bitir |
| Topic subscriptions | %0 | %0 | bugün bitir |

**2. Risk Değerlendirme (10dk)**

Şu sorular önemli:
- iOS push çalışıyor mu? Çalışmıyorsa Sprint 5'e atılacak mı?
- Karşılaştırma share card production-ready mi?
- Spam koruma gerçek dünyada test edildi mi?
- Hangi feature'lar henüz mobil cihazda gerçek kullanım gibi test edilmedi?

**3. Kalan 2 Gün Planı (15dk)**

Day 9: Polish + entegrasyon (her şey çalışmalı)
Day 10: Final QA + release (v0.4.0 tag)

Bugün (Day 8): 
- Bildirim tercihleri ekranı (~2 saat)
- Topic subscriptions (favoriye eklemekle uni topic'e sub) (~1 saat)
- "Karşılaştırmayı kaydet" eğer zaman kalırsa (nice-to-have, atlanabilir)
- Eksik gördüğünüz herhangi bir feature

**4. "Bitirme" Senaryosu (5dk)**

Şu soruyu cevaplayın: "Bugün akşam Sprint 4 bitseydi, hangi feature'lar hazır olmazdı?" 

Cevaba göre kalan 2 günün önceliklerini belirleyin.

### 🌞 Gün İçi — Paralel (3.5 saat)

**Kişi A — Topic Subscriptions + Backend Polish**

#### Adım 1: Favori → Topic Subscribe Akışı (60dk)

Mevcut favorite system'inde (Sprint 2'de yapıldı) bir uni favoriye eklendiğinde topic'e subscribe ol:

`favorite_repository.dart`'taki mevcut `addFavorite` ve `removeFavorite` metodlarını güncelle:

```dart
import '../../notifications/data/fcm_service.dart';

class FavoriteRepository {
  // ... mevcut
  
  Future<void> addFavorite(String userId, String universityId) async {
    // Mevcut Firestore yazma akışı...
    await _favoritesRef
        .doc('${userId}_$universityId')
        .set({...});
    
    // YENİ — Topic subscribe
    await FCMService().subscribeToTopic('uni_$universityId');
    
    // YENİ — Eğer kullanıcı `favoriteNewReviewEnabled: false` ise unsubscribe
    final user = await _firestore.collection('users').doc(userId).get();
    final prefs = (user.data()?['notificationPrefs'] as Map?) ?? {};
    if (prefs['favoriteNewReviewEnabled'] == false) {
      await FCMService().unsubscribeFromTopic('uni_$universityId');
    }
  }
  
  Future<void> removeFavorite(String userId, String universityId) async {
    // Mevcut Firestore silme akışı...
    await _favoritesRef.doc('${userId}_$universityId').delete();
    
    // YENİ — Topic unsubscribe
    await FCMService().unsubscribeFromTopic('uni_$universityId');
  }
}
```

#### Adım 2: Bildirim Pref Toggle → Bulk Resubscribe (45dk)

Kullanıcı `favoriteNewReviewEnabled`'ı kapatınca tüm favori topic'lerinden çıksın:

`notification_preferences_provider.dart` (Kişi A yazıyor, Kişi B kullanacak):

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/user_model.dart';
import '../../data/fcm_service.dart';

class NotificationPreferencesNotifier 
    extends StateNotifier<AsyncValue<NotificationPreferences>> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  
  NotificationPreferencesNotifier({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        super(const AsyncValue.loading()) {
    _load();
  }
  
  Future<void> _load() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      state = AsyncValue.data(const NotificationPreferences());
      return;
    }
    
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final prefsMap = doc.data()?['notificationPrefs'] as Map<String, dynamic>?;
      state = AsyncValue.data(NotificationPreferences.fromMap(prefsMap));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> toggle(String key, bool value) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    final current = state.value ?? const NotificationPreferences();
    
    // Optimistic update
    NotificationPreferences updated;
    switch (key) {
      case 'reviewLikedEnabled':
        updated = NotificationPreferences(
          reviewLikedEnabled: value,
          reviewModeratedEnabled: current.reviewModeratedEnabled,
          favoriteNewReviewEnabled: current.favoriteNewReviewEnabled,
        );
        break;
      case 'reviewModeratedEnabled':
        updated = NotificationPreferences(
          reviewLikedEnabled: current.reviewLikedEnabled,
          reviewModeratedEnabled: value,
          favoriteNewReviewEnabled: current.favoriteNewReviewEnabled,
        );
        break;
      case 'favoriteNewReviewEnabled':
        updated = NotificationPreferences(
          reviewLikedEnabled: current.reviewLikedEnabled,
          reviewModeratedEnabled: current.reviewModeratedEnabled,
          favoriteNewReviewEnabled: value,
        );
        break;
      default:
        return;
    }
    
    state = AsyncValue.data(updated);
    
    try {
      // Firestore'a yaz
      await _firestore.collection('users').doc(uid).set({
        'notificationPrefs': updated.toMap(),
      }, SetOptions(merge: true));
      
      // Topic subscriptions: favoriteNewReviewEnabled değiştiyse
      if (key == 'favoriteNewReviewEnabled') {
        await _resubscribeAllFavorites(uid, subscribe: value);
      }
    } catch (e) {
      // Revert
      state = AsyncValue.data(current);
      rethrow;
    }
  }
  
  Future<void> _resubscribeAllFavorites(String userId, {required bool subscribe}) async {
    // Kullanıcının tüm favorilerini al
    final favs = await _firestore.collection('favorites')
        .where('userId', isEqualTo: userId)
        .get();
    
    for (final doc in favs.docs) {
      final uniId = doc.data()['universityId'] as String?;
      if (uniId == null) continue;
      
      if (subscribe) {
        await FCMService().subscribeToTopic('uni_$uniId');
      } else {
        await FCMService().unsubscribeFromTopic('uni_$uniId');
      }
    }
  }
}

final notificationPreferencesProvider = StateNotifierProvider<
    NotificationPreferencesNotifier,
    AsyncValue<NotificationPreferences>>(
  (ref) => NotificationPreferencesNotifier(),
);
```

#### Adım 3: Backend Polish: Notification TTL (30dk)

90 günden eski bildirimleri otomatik silen Cloud Function (Sprint 4'te nice-to-have):

`functions/src/notifications/cleanup_expired.ts`:

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Her gün 03:00'te çalışır, expireAt geçmiş notification'ları siler.
 */
export const cleanupExpiredNotifications = functions
  .region('europe-west1')
  .pubsub
  .schedule('0 3 * * *')
  .timeZone('Europe/Istanbul')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const snap = await db.collection('notifications')
      .where('expireAt', '<', now)
      .limit(500)
      .get();
    
    if (snap.empty) {
      console.log('[cleanup] Nothing to delete');
      return null;
    }
    
    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    
    console.log(`[cleanup] Deleted ${snap.size} expired notifications`);
    return null;
  });
```

> [!NOTE]
> Eğer Spark plan'dasınız `pubsub.schedule` (Cloud Scheduler) çalışmaz. Blaze plan gerekiyor. Eğer Spark'tasınız bu function'ı yorumlayın, Sprint 5'te eklersiniz.

#### Adım 4: Test (45dk)

1. Bir uniyi favoriye ekle → Console'a bak: `[FCM] Subscribed to: uni_odtu`
2. Test message Firebase Console'dan o topic'e gönder → bildirim cihaza ulaşıyor mu?
3. Favoriden çıkar → unsubscribe log
4. `favoriteNewReviewEnabled` toggle'ı kapatıp tekrar aç → bulk resubscribe çalışıyor mu? Console log'a bak.

**Kişi B — `NotificationSettingsScreen` + Profile Entegrasyonu**

#### Adım 1: `NotificationSettingsScreen` (90dk)

`lib/features/notifications/presentation/screens/notification_settings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/notification_preferences_provider.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => 
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState 
    extends ConsumerState<NotificationSettingsScreen> {
  bool _systemPermissionGranted = false;
  
  @override
  void initState() {
    super.initState();
    _checkSystemPermission();
  }
  
  Future<void> _checkSystemPermission() async {
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() => _systemPermissionGranted = status.isGranted);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(notificationPreferencesProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Bildirim Ayarları')),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(message: '$e'),
        data: (prefs) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_systemPermissionGranted) _buildSystemPermissionWarning(),
              const SizedBox(height: 8),
              _buildSectionTitle('Bildirim Tipleri'),
              _SettingTile(
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFEC4899),
                title: 'Yorumun beğenildi',
                subtitle: 'Bir başkası yorumunu beğendiğinde bildirim al',
                value: prefs.reviewLikedEnabled,
                onChanged: (v) => ref
                    .read(notificationPreferencesProvider.notifier)
                    .toggle('reviewLikedEnabled', v),
              ),
              _SettingTile(
                icon: Icons.shield_rounded,
                iconColor: AppColors.success,
                title: 'Yorum moderasyon sonucu',
                subtitle: 'Yorumun onaylandığında veya reddedildiğinde bilgilendir',
                value: prefs.reviewModeratedEnabled,
                onChanged: (v) => ref
                    .read(notificationPreferencesProvider.notifier)
                    .toggle('reviewModeratedEnabled', v),
              ),
              _SettingTile(
                icon: Icons.fiber_new_rounded,
                iconColor: AppColors.info,
                title: 'Favori üniversiteme yeni yorum',
                subtitle: 'Favorindeki bir üniversite hakkında yeni yorum gelirse haberdar et',
                value: prefs.favoriteNewReviewEnabled,
                onChanged: (v) => ref
                    .read(notificationPreferencesProvider.notifier)
                    .toggle('favoriteNewReviewEnabled', v),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Bilgi'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'ÜniSeç bildirimleri sadece etkileşim ve bilgilendirme amaçlıdır. Reklam veya pazarlama bildirimi göndermiyoruz.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSystemPermissionWarning() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'Sistem bildirimleri kapalı',
                style: AppTextStyles.titleSmall.copyWith(color: AppColors.warning),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Cihazınızın bildirimleri kapalı. Aşağıdaki ayarları aktif etseniz bile push bildirim gelmez.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => openAppSettings().then((_) => _checkSystemPermission()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sistem ayarlarını aç'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  
  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: AppTextStyles.titleSmall),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}
```

Router'a:
```dart
GoRoute(
  path: '/notification-settings',
  builder: (_, __) => const NotificationSettingsScreen(),
),
```

#### Adım 2: Profile Ekranına "Bildirim Ayarları" Linki (15dk)

Profile ekranındaki menü listesine ekle:

```dart
ListTile(
  leading: const Icon(Icons.notifications_outlined),
  title: const Text('Bildirim Ayarları'),
  trailing: const Icon(Icons.chevron_right_rounded),
  onTap: () => context.push('/notification-settings'),
),
```

#### Adım 3: Notification Bell Polish — Long Press Quick Actions (30dk)

Bell'e uzun basınca quick action sheet:

```dart
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () => _showQuickActions(context, ref),
      child: IconButton(
        onPressed: () => context.push('/notifications'),
        icon: // ... bell icon
      ),
    );
  }
  
  void _showQuickActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.done_all_rounded),
            title: const Text('Tümünü okundu işaretle'),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(notificationRepositoryProvider).markAllAsRead();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Bildirim Ayarları'),
            onTap: () {
              Navigator.pop(context);
              context.push('/notification-settings');
            },
          ),
        ],
      ),
    );
  }
}
```

#### Adım 4: Test (45dk)

Kapsamlı test akışı:

1. Profile → Bildirim Ayarları → ekran açıldı mı?
2. 3 toggle var mı? 
3. "Yorumun beğenildi" → kapat → cihaz 2'den like → bildirim gelmedi mi?
4. Tekrar aç → like → bildirim geldi mi?
5. "Favori uniye yorum" → kapat → bir favori uniye yorum yaz (cihaz 2) → bildirim gelmedi mi?
6. Aç → yorum yaz → bildirim geldi mi?
7. Bildirim sistem permission kapalıyken: ekrana gir → uyarı kartı görünüyor mu? "Sistem ayarlarını aç" çalışıyor mu?
8. Bell'e uzun bas → quick actions açıldı mı?

### 🌆 Akşam Buluşması (35dk)

**1. Topic Subscription Test (15dk)**
- A: Cihaz 1'de ODTÜ favoriye ekle → log "Subscribed to uni_odtu"
- B: Cihaz 2'den ODTÜ'ye yorum yaz → onaylandıktan sonra cihaz 1'e push gelmeli
- A: Cihaz 1'de favoriden çıkar → log "Unsubscribed"
- B: Cihaz 2'den tekrar yorum yaz → cihaz 1'e push gelmemeli

**2. Bildirim Tercihleri Test (10dk)**
- 3 toggle'ın hepsini test edin
- "favoriteNewReviewEnabled" off → tüm topic'lerden çıkış yapılıyor mu? (Console log)

**3. Yarın Planı (10dk)**

Yarın Day 9: BÜYÜK ENTEGRASYON & POLISH
- Tüm akışları uçtan uca test
- Edge case'leri yakala
- UI tutarsızlıklarını düzelt
- Performance bottleneck check
- Tüm `// TODO`'ları gözden geçir

### ✅ Gün 8 Bitişinde Durum

- [ ] Checkpoint 2 yapıldı, kalan iş listesi netleşti
- [ ] Favoriye ekle/çıkar → topic subscribe/unsubscribe çalışıyor
- [ ] `notificationPreferencesProvider` 3 toggle ile çalışıyor
- [ ] `NotificationSettingsScreen` 3 setting tile + system permission warning
- [ ] Profile'da "Bildirim Ayarları" link
- [ ] `cleanupExpiredNotifications` (Blaze ise deploy, Spark ise commented)
- [ ] favoriteNewReviewEnabled toggle bulk topic resubscribe yapıyor
- [ ] Bell long-press quick actions (Tümünü okundu işaretle, Ayarlar)
- [ ] Topic-based bildirim end-to-end çalıştığı doğrulandı

---


## 📆 GÜN 9: Büyük Entegrasyon & Polish

> **Hedef:** Tüm Sprint 4 feature'larını bir kullanıcının yapacağı gibi uçtan uca test edin. UI tutarsızlıklarını düzeltin, edge case'leri yakalayın, performance check yapın, tüm `TODO`'ları gözden geçirin. Sprint 4'ün "production-ready" olmasını sağlayın.

> [!IMPORTANT]
> Day 9 ve Day 10 birlikte çalışılan günler. Paralel iş yok — ikiniz de cihaza karşı oturup birlikte test ediyor, birlikte düzeltiyorsunuz. Bu, "biri eksik gördüğü için ufak şeyler kalakaldı" durumunu önler.

### 🌅 Sabah — Birlikte (45dk): Sprint 4 Tüm Akış Demo

Sprint 4'te yazdığınız tüm feature'ları sırayla, gerçek bir kullanıcı gibi test edeceksiniz. **Hiçbir şey atlamayın.** Ufak bir görsel sıkıntı bile not alın — Sprint 4'ün son polish günleri bunlar.

**Hazırlık (5dk)**
- İki cihaz hazır mı? (Yoksa: 1 cihaz + 1 emulator + 2 farklı .edu.tr hesap)
- Firebase Console açık mı?
- Boş bir not defteri/Notion sayfası açın → "Sprint 4 Polish Listesi"

**Akış Demo (40dk)**

Sırayla yapın, her adımda gözleminizi yazın:

1. **Onboarding** (yeni kullanıcı): 5 sayfa onboarding → register → login → home
2. **Anasayfa**: Tüm üniversiteler listede mi? 38 üni mi? Yeni eklenenler (Marmara, Aydın, vb.) görünüyor mu?
3. **Üniversite detayı (ODTÜ)**: Header → Bilgiler → Bölümler → **Mekanlar** (yeni!) → Yorumlar
4. **Mekanlar bölümü**:
   - Mekan kartları görünüyor mu?
   - Filter butonu çalışıyor mu? Tip + fiyat + amenity ile filtrele → liste güncelleniyor mu?
   - Yurt kartında gender badge, kafede price badge, dual rating görünüyor mu?
5. **Mekan detayı (cafe)**: Foto galeri → tip chip → adres → Google rating → Hakkında → Özellikler → Yorum yaz/Haritada aç → Yorumlar
6. **Mekan detayı (yurt)**: `DormInfoCard` öne çıkıyor mu? KYK + Erkek/Kız doğru renk?
7. **Place yorum yaz**: 4 kategori barı → pros/cons → yorumu gönder → onaylandı mı? → Profile'da yorumum görünüyor mu?
8. **Karşılaştırma**:
   - Karşılaştır sekmesine git → 2 üni seç → header doluyor mu? → kategori barları → istatistik tablosu
   - Swap butonu → A↔B yer değiştiriyor mu?
   - Paylaş butonu → screenshot → share sheet açılıyor → görsel doğru mu?
9. **Bildirim akışı**:
   - Cihaz 2'den cihaz 1'in yorumunu like'la → push gelsin
   - Bell badge görünsün → tıkla → liste → tile'a tıkla → ilgili sayfaya git
   - Bildirim ayarları → toggle test
10. **Logout**: Logout → token Firestore'dan silindi mi? Bell ekranı login gerektiriyor mu?

**Polish Listesi Çıkarma (10dk)**

İkiniz de gözleminizi karşılaştırın. Liste muhtemelen şöyle olacak:

```
[ ] Place card'da rating sıkışık görünüyor — padding artır
[ ] Yurt detayında KYK badge çok büyük
[ ] Comparison header'da "summary" tek satıra sığmıyor — wrap ekle
[ ] FilterSheet "Sıfırla" butonu sağda olmalı, soldda
[ ] Notification tile timeago Türkçe değil
[ ] iOS'ta back gesture place detail'i kapatınca hata
[ ] Empty place list'te illustration yerine sadece text
[ ] Comparison'da aynı uni iki kez seçilemez ama disabled gösterilmiyor
[ ] Place detail "Yorum Yaz" butonu giriş kontrolü yok
[ ] FCM token refresh sonrası eski token Firestore'da kalıyor
```

> [!TIP]
> Listeyi öncelik sırasına dizin. Critical (functional bug) → High (UX issue) → Low (nitpick). Day 9'un kalanı bu listeyi bitirmek.

### 🌞 Gün İçi — Birlikte (4 saat)

Polish listesini ikiniz de aynı dosyaya bakarak, birinin kodladığı bir şeyi diğerinin test ettiği şekilde sırayla bitirin. Aşağıda tipik polish görevlerinin ele alınışı var:

#### Polish Görevi 1: Timeago Türkçe (15dk)

`pubspec.yaml`:
```yaml
dependencies:
  timeago: ^3.7.0
```

`main.dart` (init sırasında):
```dart
import 'package:timeago/timeago.dart' as timeago;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Türkçe locale
  timeago.setLocaleMessages('tr', timeago.TrMessages());
  timeago.setDefaultLocale('tr');
  
  await Firebase.initializeApp();
  // ...
}
```

Notification tile'da:
```dart
Text(
  timeago.format(notification.createdAt, locale: 'tr'),
  // "5 dakika önce", "2 saat önce", "3 gün önce"...
),
```

Aynı pattern'i `ReviewCard`'a da uygulayın (eğer hâlâ raw timestamp gösteriyorsa).

#### Polish Görevi 2: FCM Token Cleanup (30dk)

Eski problem: kullanıcı giriş yapar → token A → 60 gün sonra token refresh → token B → ama token A hâlâ Firestore'da. Bildirim hem token A hem token B'ye gönderiliyor — token A invalid → silinmeli.

Helper fonksiyonda zaten invalid token cleanup var (Day 7'de yazıldı). Ek olarak bir Cloud Function:

`functions/src/notifications/cleanup_stale_tokens.ts`:

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Haftalık çalışır, 90 günden eski "lastTokenRefresh"li kullanıcıların 
 * fcmTokens listesini temizler.
 */
export const cleanupStaleTokens = functions
  .region('europe-west1')
  .pubsub
  .schedule('0 4 * * 0')  // Pazar 04:00
  .timeZone('Europe/Istanbul')
  .onRun(async () => {
    const ninetyDaysAgo = admin.firestore.Timestamp.fromMillis(
      Date.now() - 90 * 24 * 60 * 60 * 1000
    );
    
    const snap = await db.collection('users')
      .where('lastTokenRefresh', '<', ninetyDaysAgo)
      .limit(100)
      .get();
    
    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.update(doc.reference, { fcmTokens: [] });
    }
    
    await batch.commit();
    console.log(`[cleanupStaleTokens] Cleared tokens for ${snap.size} users`);
    return null;
  });
```

(Spark plan'da bu da çalışmaz — yorumlu bırakın, Sprint 5'te aktif edin.)

#### Polish Görevi 3: "Yorum Yaz" Login Kontrolü Tutarlılığı (30dk)

Sprint 3'te `WriteReviewScreen` route'u doğrudan login redirect yapıyordu. Place detail'de Day 4'te dialog yaklaşımı yapıldı. **Bu tutarsızlık.** Tek bir mekanizmaya sabitleyin.

Önerilen: `app_router.dart`'ta `/write-review` route'u `redirect`'le auth check yapsın:

```dart
GoRoute(
  path: '/write-review',
  redirect: (context, state) {
    // ProviderContainer'dan currentUser oku
    final container = ProviderScope.containerOf(context);
    final user = container.read(currentUserProvider);
    if (user == null) {
      // Login'e yönlendir, query param ile geri dönüş URL'ini sakla
      return '/login?next=${Uri.encodeComponent(state.uri.toString())}';
    }
    if (!user.isVerified) {
      return '/verify-email';
    }
    return null;  // İzin ver
  },
  builder: (context, state) {
    // ... mevcut
  },
),
```

Login screen'da `next` parametresi varsa, login sonrası oraya yönlendir. Ardından `PlaceDetailScreen`'daki dialog'u kaldırın — direkt `context.push('/write-review?...')` çağrısı yeter, redirect halleder.

#### Polish Görevi 4: Empty State Illustrations (45dk)

Boş ekranlardaki Material Icon yerine basit özel SVG illustrations kullanın. Eğer SVG yoksa "icon + büyük başlık + açıklama" tutarlı pattern.

`lib/core/widgets/empty_state_widget.dart`'ta varsayılan layout'u güçlendirin:

```dart
class EmptyStateWidget extends StatelessWidget {
  final IconData? icon;
  final Widget? illustration;
  final String title;
  final String description;
  final Widget? action;
  
  const EmptyStateWidget({
    super.key,
    this.icon,
    this.illustration,
    required this.title,
    required this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (illustration != null) illustration!
          else if (icon != null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: AppColors.primary.withValues(alpha: 0.7)),
            ),
          const SizedBox(height: 20),
          Text(title, style: AppTextStyles.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: 20),
            action!,
          ],
        ],
      ),
    );
  }
}
```

Tüm boş ekranların `EmptyStateWidget` kullandığını doğrulayın — özellikle:
- Profile yorumlarım yok
- Notification merkezi boş
- Mekan listesi boş (filter sonrası)
- Comparison ekranı henüz seçim yok
- Yorumlar bölümü boş

#### Polish Görevi 5: Comparison Edge Case'leri (45dk)

Şu durumları test edin ve düzeltin:

a) **Henüz hiç yorum almayan üni karşılaştırması**: ODTÜ (50 yorum) vs Hitit (0 yorum) → "B'de yorum yok" durumunda bar nasıl görünüyor? Kategori puanları 0-0 olacak — bu durumda "Veri yetersiz" göster:

```dart
// CategoryComparison.delta hesabı için
if (valueA == 0 && valueB == 0) {
  // İkisi de hiç yorum almamış
  // UI tarafta "Henüz veri yok" göster
}
```

`ComparisonCategoryRow`'da:
```dart
if (comparison.valueA == 0 && comparison.valueB == 0) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
    ),
    child: Row(children: [
      Icon(Icons.info_outline, size: 16, color: AppColors.textTertiary),
      const SizedBox(width: 8),
      Text('${comparison.categoryName}: Henüz yeterli yorum yok',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary)),
    ]),
  );
}
```

b) **Aynı uni karşılaştırması**: `ComparisonRepository.compare()` zaten `throw ArgumentError`'la engelliyor. UI'da slot'larda disabled gösteriliyor. Yine de bonus: API'nin throw etmesi yerine `null` dönmesi ya da `ComparisonError` model dönmesi UI tarafında daha temiz olabilir — ama Sprint 4'te overengineer'a kaçmayın.

c) **Çok eski yıl farkı**: 1900'de kurulan vs 2020'de kurulan → "120 yıl fark" hesabı doğru olduğu kadar gereksiz.  `establishedYearDiff` 50'den büyükse "50+ yıl" diye göster.

#### Polish Görevi 6: Place Card Görsel Tutarlılık (30dk)

Day 1-2'de yapılan PlaceCard'ı şimdi yan yana göstererek tutarlılık check'i yapın. Tip chip rengi, padding, badge konumu, font ağırlıkları — hepsi tutarlı mı?

Sık görülen sorunlar:
- Cafe vs yurt vs library kartlarında padding farklı
- Rating ikon boyutu tutarsız (16 vs 18 vs 14)
- Kart yükseklikleri eşit değil → ListView.builder'da sabit yükseklik mi liste mi karar verin

Çözüm: `place_card.dart`'ta tüm magic number'ları yukarı taşıyın:

```dart
class PlaceCard extends ConsumerWidget {
  static const double _kCardHeight = 96;
  static const double _kImageSize = 80;
  static const double _kIconSize = 16;
  static const double _kRatingFontSize = 13;
  // ...
}
```

#### Polish Görevi 7: Performance Check (30dk)

DevTools açıp critical akışlarda frame drop'a bakın:

1. Üni listesi scroll → 60fps kalıyor mu?
2. Place liste scroll (ODTÜ → 18 mekan) → CachedNetworkImage'ler smooth mu?
3. Comparison ekranı geçişi → animasyon donmuyor mu?
4. Notification merkezi 50+ bildirim ile → çalışıyor mu? Donma var mı?

Tipik düzeltmeler:
- `ListView.builder` yerine `ListView` kullanılmışsa değiştirin
- `setState` yerine sadece etkilenen kısım için `Consumer` widget kullanın
- Image caching: CachedNetworkImage'in `memCacheWidth` ve `memCacheHeight` parametreleri ile bellek tasarrufu

#### Polish Görevi 8: TODO'ların Gözden Geçirilmesi (30dk)

Tüm projede:
```bash
grep -rn "// TODO" lib/ functions/src/ --include="*.dart" --include="*.ts" | wc -l
```

Her TODO için karar:
- **Şimdi yap**: 5dk'lık küçük bir polish ise
- **Sprint 5**: Daha büyük bir iş ise — TODO comment'i `// TODO(sprint5): ...` haline getir
- **Sil**: Artık alakasız olmuş bir TODO ise

Hedef: Sprint sonunda `// TODO` sayısı belirsiz olmamalı, herkes ne kaldı bilmeli.

### 🌆 Akşam Buluşması (45dk)

**1. Polish Listesi Bitirme Skoru (10dk)**

Sabah çıkarttığınız polish listesine bakın:
- Kaç tane bittik? 
- Kaç tane Day 10'a kaldı (yarın bitir)?
- Kaç tane Sprint 5'e atıldı?

Hedef: %80+ bitirilmiş olsun.

**2. UAT Mini Demo (20dk)**

Bir tanıdığınızı (öğrenci, ideal olarak hedef kullanıcı) çağırıp 10 dakika uygulamayı kullansın. Yan yana izleyin, NOT TUTUN, müdahale etmeyin.

Gözlem soruları:
- Mekanlara nasıl ulaştı? Kolay mı?
- Filter'ı kullanmaya çalıştı mı? Anladı mı?
- Karşılaştırmayı denedi mi? Sonuçtan haberi oldu mu?
- Hangi noktada takıldı?

UAT sonrası 1-2 dakika geri bildirim alın. Bu büyük altın değerinde.

**3. Yarın Planı (15dk)**

Yarın Day 10 — son gün. Plan:
- Sabah: UAT bulgularını uygulamaya yansıt + kalan polish listesi
- Öğlen: Final test (tüm akışlar bir kez daha)
- Öğleden sonra: v0.4.0 tag, build APK, store assets prep
- Akşam: Sprint retrospektifi + Sprint 5 planı

### ✅ Gün 9 Bitişinde Durum

- [ ] Sprint 4 tüm akış uçtan uca demo edildi
- [ ] Polish listesi çıkarıldı, en az %80'i bitirildi
- [ ] Timeago Türkçe locale aktif
- [ ] FCM token cleanup function hazır (deploy edildi veya yorumlu)
- [ ] "Yorum yaz" login kontrolü router redirect'e taşındı (tutarlılık)
- [ ] Tüm boş ekranlar `EmptyStateWidget` ile tutarlı
- [ ] Comparison: 0-yorum durumu, aynı uni, eski yıl farkı edge case'leri
- [ ] Place card görsel tutarlılığı (magic numbers temizlendi)
- [ ] Performance check yapıldı, donma yok
- [ ] TODO'lar gözden geçirildi, sınıflandırıldı
- [ ] UAT mini demo yapıldı, gözlemler not edildi

---


## 📆 GÜN 10: Final QA & Release

> **Hedef:** Sprint 4 kapanıyor. v0.4.0 build'i Internal Testing'de, release notes'u yazıldı, bilinen bug'lar açıkça not edildi, retro yapıldı, Sprint 5 için temel planlandı. **Yeni feature kesinlikle yok.**

### 🌅 Sabah — Final QA Birlikte (90dk)

> [!IMPORTANT]
> Bugün **tek hedef:** Yarın bir kullanıcı uygulamayı açtığında crash ve kötü UX yaşamayacak. Ufak bir polish bile risklidir — sadece kritik bug fix.

**1. Smoke Test (45dk)**

Bir test cihazında, baştan sona, durmadan, **kullanıcı gibi** uygulamayı kullanın. Her ekran için 3 saniye bakın, 1 etkileşim yapın. Hızlı yapın.

Checklist:
- [ ] Splash screen → açılış logosu, gecikme yok
- [ ] Welcome screen → 3 onboarding sayfa scroll
- [ ] Auth → Sign-In, Sign-Up, Forgot Password (her birine git, dön)
- [ ] Onboarding → ilgi alanları seçimi
- [ ] Home → Üniversite listesi yüklendi mi?
- [ ] Search → "ODTÜ" yaz, sonuç çıktı mı?
- [ ] Filter → "Devlet" seç, liste güncellendi mi?
- [ ] Üni detay → ODTÜ → bölümler + mekanlar + yorumlar
- [ ] Place detail → Padam Coffee → tüm bölümler
- [ ] Place yorum yaz → form doldur, gönder
- [ ] 5sn bekle → place rating güncellendi mi?
- [ ] Comparison → ODTÜ vs İTÜ → kategori karşılaştırma
- [ ] Comparison share → screenshot indi mi?
- [ ] Notification bell → tıkla, center açıldı
- [ ] Bildirim ayarları → toggle değiştir, toggle çalışıyor mu?
- [ ] Profile → istatistikler + yorumlarım
- [ ] Logout → login ekranına döndü
- [ ] Login tekrar → state korundu mu?

Smoke test sırasında **kritik bug** bulursan: kaydet, hızlıca fix et, build al. **Non-critical** bug bulursan: GitHub issue, Sprint 5'e at.

**2. Performance Quick Check (15dk)**

DevTools'da:
- App startup time → < 3 saniye?
- Bir uni detayı açma → < 1.5 saniye?
- Place list scroll → 60 FPS sabit mı?
- Bellek kullanımı → < 200 MB?

Sorun varsa not et, kritik değilse Sprint 5.

**3. Test Edilmemiş Senaryolar (15dk)**

- [ ] Hava modu (offline) → empty state'ler düzgün mü?
- [ ] Yavaş 3G → progress indicator'lar yeterli mi?
- [ ] Düşük bellek (eski cihaz) — eğer varsa
- [ ] Background'a alıp dön → state korundu mu?

**4. Cloud Function Final Check (15dk)**

Console → Functions → Each:
- Son 24 saatte invocation sayısı normal mi?
- Hata oranı %1'in altında mı?
- Latency p95 < 5 saniye?

### 🌞 Öğleden Sonra — Release Hazırlığı (3.5 saat)

**Kişi A — Release Notes + Backend Final**

#### Adım 1: Release Notes (60dk)

`CHANGELOG.md` dosyasında v0.4.0 bölümü ekle:

```markdown
## v0.4.0 — Sprint 4 (2 hafta)

### 🆕 Yeni Özellikler

#### ☕ Mekanlar
- 31 üniversite için 509 mekan eklendi:
  - 196 kafe (öğrenci dostu, kampüs yakını seçilmiş)
  - 178 yurt (KYK ve Özel)
  - 135 kütüphane
- Her mekan için detay ekranı: foto galerisi (placeholder), açıklama, açılış saatleri, özellikler
- Yurt için özel kart: KYK/Özel + Kız/Erkek/Karma görsel ayrımı
- Kafeler için Google puanı dahil edildi
- "Haritada Aç" butonu Google Maps'te konumu açar
- Tip filtresi (Kafe / Yurt / Kütüphane)
- Mekan yorumu yazma: 4 kategori puanı (Ortam, Fiyat, Temizlik, Hizmet)

#### ⚖️ Karşılaştırma
- 2 üniversiteyi yan yana kıyaslama
- 6 kategori bazında bar chart
- Genel kazanan özeti (kategorileri kazanma sayısı)
- İstatistik tablosu (kuruluş, tür, şehir, kampüs, yorum sayısı, mekan sayısı)
- Karşılaştırmayı paylaşma (ekran görüntüsü)

#### 🔔 Bildirimler
- Push notification altyapısı (FCM)
- 3 bildirim tipi:
  - Yorumun beğenildi (toplu)
  - Yorumun moderasyondan geçti
  - Favori üniversite yeni yorum aldı
- In-app bildirim merkezi (zil ikonu + sheet)
- Bildirim tercihleri ekranı (her tip için aç/kapat)
- Topic-based subscription (favori uni)

### 🆕 Yeni Üniversiteler
- Marmara Üniversitesi
- Ankara Hacı Bayram Veli Üniversitesi
- İzmir Demokrasi Üniversitesi
- İzmir Katip Çelebi Üniversitesi
- İstanbul Aydın Üniversitesi
- İstanbul Gelişim Üniversitesi
- İstanbul Medipol Üniversitesi
- Hitit Üniversitesi (Çorum)

### 🆕 Yeni Şehir
- Çorum

### ✨ İyileştirmeler
- Üniversite detayında kampüs yerleşimi rozeti (Kampüslü / Blok / Dağınık)
- Profile ekranında genişletilmiş istatistikler (toplam yorum, place yorum, alınan like)
- Place detayında yorum sayısı 5 saniye içinde otomatik güncelleniyor

### 🐛 Bilinen Sorunlar
- iOS push bildirimleri Sprint 5'e ertelendi (APNs sertifikası bekleniyor)
- Boğaziçi, Koç, Sabancı, Bilkent, Yaşar, İYTE, Bilgi: mekan listesi boş — Sprint 5'te eklenecek
- Place foto yükleme henüz admin paneli üzerinden değil, kullanıcı yorumlarından gelen fotolar var
- Karşılaştırmayı kaydetme (favori karşılaştırmalar) Sprint 5'te

### 🔧 Teknik
- Firebase Cloud Messaging entegrasyonu
- 5 yeni Cloud Function (aggregatePlaceRatings, onReviewLiked, onReviewModerated, onNewReviewForFavorite, cleanupExpiredNotifications)
- 3 yeni Firestore koleksiyonu (places, notifications)
- 5+ yeni Firestore composite index
- 4 yeni paket: firebase_messaging, flutter_local_notifications, screenshot, share_plus
```

`README.md`'yi de gerekirse güncelle (yeni özelliklerden bahsediyor mu?).

#### Adım 2: Firestore Console Production Check (30dk)

Final göz gezdir:
- `places` koleksiyonu → 509 doc, indexler hazır
- `notifications` koleksiyonu → boş veya az (henüz kullanıcılar bildirim almadı)
- `universities` → 38 doc, hepsi `campusLayout` alanına sahip
- `cities` → 11 doc

Rules deploy edilmiş mi? Indexes build olmuş mu?

#### Adım 3: Cloud Function Cold Start Optimization (30dk)

Eğer cold start > 5 saniye ise:
- `runWith({ minInstances: 0, memory: '256MB' })` → memory'i artır
- Spark plan'da min instances 1 yapamazsın, sadece Blaze
- Sprint 4 için cold start kabul edilebilir (kullanıcı dakikada bir bildirim almıyor)

#### Adım 4: Backup ve Tag (30dk)

```bash
# develop'tan main'e merge
git checkout main
git merge develop
git push origin main

# v0.4.0 tag
git tag -a v0.4.0 -m "Sprint 4: Places + Comparison + Notifications"
git push origin v0.4.0

# GitHub Release oluştur
# CHANGELOG.md içeriğini Release notes olarak kopyala
```

#### Adım 5: Production Build (60dk)

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS (eğer Apple Dev varsa)
flutter build ios --release
# Xcode → Archive → Distribute → TestFlight
```

`build/app/outputs/bundle/release/app-release.aab` Internal Testing'e yükle.

**Kişi B — UI Final Polish + Internal Beta Yükleme**

#### Adım 1: Internal Beta'ya Yükleme (45dk)

Google Play Console:
- App Bundle yükle (`app-release.aab`)
- "Internal Testing" track'a ata
- Tester listesini güncelle (ekibin emaillari + 5-10 yakın test kullanıcısı)
- Release notes (kısa versiyon, oyuncuya görünür):

```
v0.4.0 — Mekanlar, Karşılaştırma, Bildirimler

🆕 Yenilikler:
• 31 üniversite için 509 öğrenci mekanı (kafe, yurt, kütüphane)
• 8 yeni üniversite: Marmara, Hacı Bayram, İzmir Demokrasi, İzmir Katip Çelebi, Aydın, Gelişim, Medipol, Hitit
• Üniversite karşılaştırma — 2 üniyi yan yana kıyasla, paylaş
• Push bildirimleri — yorumun beğenildiğinde, favori üni'ne yeni yorum geldiğinde

🐛 Düzeltilenler:
• Mekan detayı yorum sayısı şimdi anlık güncelleniyor
• Favori üniversite topic subscription'ı doğru çalışıyor

Geri bildirimleri unisecapp@anthropic.com adresine gönderin.
```

App Store Connect (eğer iOS varsa):
- TestFlight build yükle
- External Testing Group'a ata

#### Adım 2: Smoke Test on Internal Beta (45dk)

Yüklenen build'i kendi cihazınıza Internal Testing üzerinden indirin:
- Update aldı mı?
- Açılışta crash yok mu?
- Bütün ana akışlar çalışıyor mu? (Day 10 sabahındaki smoke test'i tekrarla)
- Push bildirim test → bir başkasının yorumunu beğen → kendin like'lı bildirimi al

#### Adım 3: Release Tutorial / In-App Whats-New (60dk)

> [!NOTE]
> Bu **opsiyonel**. Eğer Sprint 4 sonunda zaman varsa ekle, yoksa Sprint 5'e atla. Sprint 5 polish sprint'i — orada fit in eder.

İlk açılışta v0.4.0 yenilikleri için bottom sheet:
```dart
// SharedPreferences ile bir kez göster
final prefs = await SharedPreferences.getInstance();
final lastSeenVersion = prefs.getString('last_seen_version');

if (lastSeenVersion != '0.4.0') {
  // What's new sheet göster
  showModalBottomSheet(...);
  prefs.setString('last_seen_version', '0.4.0');
}
```

İçerik:
- "🎉 v0.4.0 yenilikleri"
- 4 satır özet (Mekanlar, Karşılaştırma, Bildirimler, 8 yeni üni)
- "Keşfet" butonu

### 🌆 Akşam — Sprint Retrosu + Sprint 5 Planlama (90dk)

**1. Sprint 4 Retrospektifi (30dk)**

Sırayla, kısaca, dürüstçe:

**🟢 İyi Gidenler**
- Hangi 3 şey çok iyi gitti?
- Hangi süreçler Sprint 5'e taşınmalı?

Tipik notlar (örnek):
- API kontratlarını Day 1'de yazmak conflict azalttı
- 509 mekanlık veri seti Python parser ile hızlıca import edildi
- Cloud Function pattern Sprint 3'ten zaten oturmuştu, hızlıca adapte edildi

**🔴 Kötü Gidenler**
- Hangi 2 şey kötü gitti?
- Bir sonraki sprint'te ne değişsin?

Tipik notlar:
- iOS APNs sertifikası geç çıktı, push test gecikti
- Karşılaştırma ekranı tasarım iterasyonu fazlaydı, Day 5-6 yerine 4'te bitebilirdi
- Topic subscription bulk update'i performans için Sprint 5'e taşımak gerekebilir
- (Eğer eklendiyse) "What's new" sheet son anda eklendi, polish değildi

**💡 Aksiyonlar**
- Sprint 5'e taşınacak öğrenmeler

**2. Sprint 5'e Hazırlık Toplantısı (30dk)**

Sprint 5 ne içerecek? Bu Sprint 4'ün son saatinde **net olarak** belirleyin.

Sprint 5 muhtemel kapsamı:
- 🐛 **Bug fix'ler** (Sprint 4'ten kalan critical+medium, GitHub issues label'lı)
- 🍎 **iOS push notifications** (APNs sertifikası geldikten sonra)
- 📸 **Mekan foto upload** — admin paneli olmadan, kullanıcı yorumundan gelenler kullanılacak
- 🏢 **Boğaziçi, Koç, Sabancı, Bilkent, Yaşar, İYTE, Bilgi için manuel mekan girişi**
- 📊 **Admin panel** (web app — Firebase Hosting + minimal React, sadece mekan/üni/yorum CRUD)
- 🌐 **App Store / Play Store yayını için store listing'leri**
- 📈 **Analytics ekleme** (Firebase Analytics — hangi ekranlar popüler?)
- 🎨 **What's new in v0.4.0 onboarding** (eğer yapılmadıysa)

Sprint 5 sürecini kararlaştır:
- Süre: 1.5 hafta? 2 hafta? Bir sonraki sprint başlangıcı?
- 1 hafta polish + 0.5 hafta release prep gibi

**3. Test Kullanıcılarına Davet (15dk)**

5-10 öğrenci arkadaşa Internal Beta'ya davet linki:
```
Merhaba! ÜniSeç beta sürümünü test edebilir misin?

İndir: <play store internal testing link>

İlk hafta için odaklanılmasını istediğimiz alanlar:
1. Mekan listesinden bir kafe seçip yorum yaz, akış sorunsuz mu?
2. Üniversiteni seçtiysen karşılaştırma ekranını dene, paylaşımı çalışıyor mu?
3. Bildirim ayarlarından kapatıp açabiliyor musun?

Sorun yaşarsan: ekran görüntüsü + ne yapıyordun + crash mi yoksa UI bug mı, lütfen yaz.
```

**4. Sprint 4 Kapanışı (15dk)**

Birbirinizi tebrik edin :)

```bash
# Final commit varsa
git add .
git commit -m "chore: sprint 4 final cleanup"
git push origin develop
git checkout main
git merge develop
git push origin main
git tag -a v0.4.0 -m "Sprint 4 release"
git push origin v0.4.0
```

### ✅ Gün 10 Bitişinde Durum

- [ ] Smoke test: tüm ana akışlar test edildi, kritik bug yok
- [ ] CHANGELOG.md v0.4.0 bölümü yazıldı
- [ ] README.md güncel
- [ ] Cloud Functions logs temiz
- [ ] Firestore rules + indexes production-ready
- [ ] APK / AAB / IPA build alındı
- [ ] Internal Testing'e yüklendi
- [ ] Internal Beta build cihazda manuel doğrulandı
- [ ] `v0.4.0` tag oluşturuldu, GitHub release notes yayınlandı
- [ ] main branch güncel
- [ ] Sprint 4 retrospektif yapıldı, notlar yazılı
- [ ] Sprint 5 kapsamı netleştirildi
- [ ] (Opsiyonel) "What's new in v0.4.0" sheet eklendi
- [ ] (Opsiyonel) 5-10 test kullanıcısına Internal Beta davetiyesi gönderildi
- [ ] 🎉 Sprint 4 kapatıldı

---


## 🚧 Blocker Protokolü

> Sprint 3'te öğrendiğiniz prensiplerin tekrar formülasyonu. Herhangi bir blocker'da bu protokolü uygulayın.

### Tanım
**Blocker** = 30 dakika boyunca tek başına çözemediğiniz ve devam edemediğiniz problem.

Bu **bug** değil. Bug → Issue açar, devam edersiniz. Blocker → Akışı durdurur.

### Blocker Anında Adımlar

**1. 30dk Kuralı (kendinle)**
- 15dk dene
- 15dk daha dene + Google + Stack Overflow
- Hâlâ çözüm yok → blocker.

**2. Blocker İlanı (anında)**
WhatsApp / Slack / chat'e yaz:
```
🚧 BLOCKER

Ne yapıyorum: [örn. WriteReviewScreen'e place desteği eklemek]
Ne deniyorum: [örn. WriteReviewScreen'in switch case'inde ReviewType.place case'i ekledim ama _categoryRatings tüm kategoriler için validate olmuyor]
Beklenen: [4 kategori için puan validate olmalı]
Olan: [3 kategoride bile submit edilebiliyor]
Denedin: [setState ile validate, manuel print ile kontrol — tutarsız sonuçlar]
```

> [!IMPORTANT]
> Blocker mesajı **detaylı** olmalı. Karşı taraf 30 saniyede anlasın. "Şu çalışmıyor" YETMEZ.

**3. Karşılıklı Triage (15dk)**
- Karşı taraf bakar, kısa fix önerisi sunar veya
- "Birlikte yapalım" der → ekran paylaşımı

**4. Pair Programming (45-90dk)**
- Birlikte debug
- Birlikte yazılım üretmek bazen çözüm değil **deşifre** etmektir
- Hâlâ çözülmediyse: Sprint 5'e ertelenecek mi karar ver

**5. Sprint Plan Update**
- Eğer ertelendiyse: bugün ki goal'lerden çıkar, GitHub Issue + Sprint 5 backlog'a ekle
- Sprint 4 tamamlanma yüzdesini revize et

### Sık Karşılaşılan Sprint 4 Blocker'lar

**🔥 FCM Token alınmıyor (Android)**
- Çözüm: `google-services.json` doğru paket adıyla mı? Gradle plugin sürümü güncel mi?
- Sık sorun: `firebase_messaging` 14.x → 15.x geçişinde isolate handler değişti

**🔥 Cloud Function timeout**
- Çözüm: 60s default → `runWith({ timeoutSeconds: 120 })`
- Eğer notification topic broadcast 1000+ token → `sendMulticast` 500 chunk'a böl

**🔥 Comparison ekranı çok yavaş**
- Çözüm: `compute()` ile hesapı isolate'a at
- Veya: `FutureProvider` cache'le, aynı 2 uni için tekrar hesaplama

**🔥 Place foto galerisi page indicator çalışmıyor**
- Çözüm: `PageController` state'i koruyamadı → `late final` initialize

**🔥 Notification sheet açılınca rebuild loop**
- Çözüm: `ref.watch` yerine `ref.read` builder dışında, watch sadece liste için

**🔥 Topic subscribe işlem 100+ favorisi olan kullanıcı için yavaş**
- Çözüm: Bulk işlemleri parallel yap (`Future.wait`), UI'ı bloklama (background isolate)

---

## 📋 Sprint 4 Sonu Retrospektifi (Şablon)

> Day 10 akşam toplantısında doldurun. Bu şablonu `sprint4_retro.md` olarak kaydedin.

### 🟢 İyi Gidenler (3 madde)

1. **[başarı 1]**
   - Detay:
   - Sprint 5'e taşıyalım mı? Nasıl?

2. **[başarı 2]**
   - Detay:
   - Sprint 5'e taşıyalım mı? Nasıl?

3. **[başarı 3]**
   - Detay:
   - Sprint 5'e taşıyalım mı? Nasıl?

### 🔴 Zorluklar (3 madde)

1. **[zorluk 1]**
   - Ne oldu:
   - Etkisi:
   - Sonraki sprint'te nasıl önleriz:

2. **[zorluk 2]**
   - Ne oldu:
   - Etkisi:
   - Sonraki sprint'te nasıl önleriz:

3. **[zorluk 3]**
   - Ne oldu:
   - Etkisi:
   - Sonraki sprint'te nasıl önleriz:

### 💡 Sprint 5'e Aksiyonlar

- [ ] **[aksiyon 1]** — Sorumlu: [A/B/Birlikte]
- [ ] **[aksiyon 2]** — Sorumlu: [A/B/Birlikte]
- [ ] **[aksiyon 3]** — Sorumlu: [A/B/Birlikte]

### 📊 Sayılar

- **Tamamlanan task:** /
- **Erteleme oranı (Sprint 5'e atılan):** %
- **Critical bug sayısı (Sprint sonu):**
- **Cloud Function deploy sayısı:**
- **Yeni dosya sayısı:**
- **Lines of code (yaklaşık):**
- **Commit sayısı:**
- **Pair programming saat:**

### 🎓 Bireysel Öğrenmeler

**Kişi A:**
- En çok geliştirdiğim alan:
- En çok zorlandığım alan:
- Sprint 5'te kendime hedef:

**Kişi B:**
- En çok geliştirdiğim alan:
- En çok zorlandığım alan:
- Sprint 5'te kendime hedef:

---

## 🚀 Sprint 5'e Hazırlık

> Bu bölüm Sprint 4 Day 10 akşam toplantısında netleştirilir. Şablon olarak kullanın.

### 🎯 Sprint 5 Tema Önerileri

**Seçenek 1: Polish & Public Release**
- Sprint 4 bug fix'leri (critical + medium)
- iOS push notification (APNs)
- Mekan foto upload (kullanıcı yorum + admin)
- Eksik 7 üni için manuel mekan girişi
- Play Store / App Store yayını
- **Süre:** 1.5 - 2 hafta
- **Avantaj:** Public release ile gerçek kullanıcı edinme başlar

**Seçenek 2: Admin Panel**
- Web tabanlı admin panel (Firebase Hosting + React/Vue)
- Mekan/Üni/Bölüm CRUD
- Yorum moderasyonu (manual override)
- Kullanıcı yönetimi (ban/unban)
- **Süre:** 2 hafta
- **Avantaj:** Sprint sonrası içerik yönetimi backend'e bağlı kalmaz

**Seçenek 3: Analytics & Onboarding**
- Firebase Analytics entegrasyonu
- Funnel analizleri
- "What's new" onboarding
- A/B test infrastructure
- **Süre:** 1 hafta
- **Avantaj:** Veri-odaklı karar verme başlar

**Tavsiye:** Seçenek 1 (Polish & Public Release) — sprint 4 zaten ağır feature build'di. Şimdi gerçek kullanıcı eline almak için polish + iOS bitirmek mantıklı. Admin panel ve analytics Sprint 6'ya.

### 📦 Sprint 5 Hazırlık Checklisti (Sprint 4 sonunda)

**Teknik Hazırlık:**
- [ ] Apple Developer hesabı aktif (yıllık $99 ödendi)
- [ ] APNs Authentication Key veya P12 sertifikası oluşturuldu
- [ ] App Store Connect'te uygulama listing'i taslağı (icon, screenshot, açıklama)
- [ ] Play Store Listing taslağı güncel (yeni özellikler eklendi)
- [ ] Privacy Policy URL hazır (Sprint 5 başında zorunlu)
- [ ] Terms of Service URL hazır

**Backend Hazırlık:**
- [ ] Firebase Blaze plan'a geçiş (eğer Spark'taysa, Cloud Functions usage artacak)
- [ ] Bütçe alarmları kuruldu ($10/ay başlangıç)
- [ ] Firestore production region (`europe-west1`) doğrulandı
- [ ] Backup stratejisi (Firestore export → Cloud Storage haftalık)

**İçerik Hazırlık:**
- [ ] 7 eksik üni için mekan listesi araştırıldı (Sprint 5 Day 1'de import için CSV hazır)
- [ ] Mekan fotoğrafları kaynak listesi (open license fotoğraf siteleri)
- [ ] App icon final hali (1024x1024)
- [ ] Splash screen final hali
- [ ] Mağaza screenshot'ları için 5-6 öne çıkan ekran belirlenmiş

**Süreç Hazırlık:**
- [ ] Sprint 4 retrospektif aksiyonları Sprint 5 backlog'una eklendi
- [ ] Internal Beta test kullanıcılarından gelen feedback toplandı
- [ ] Sprint 5 başında pair programming oturumu planlandı (sprint kickoff)

### 🗓️ Sprint 5 Önerilen Akış (8 gün, 1.5 hafta)

**Day 1 — Kickoff + Critical Bug Fix**
- Sprint 4 retro aksiyonları başlatma
- 3-5 critical bug temizliği
- Sprint 5 dependency check (Apple hesabı, APNs vb.)

**Day 2 — iOS APNs + 7 Üni Mekan İmportu**
- A: APNs sertifikası FCM'e bağla, iOS test
- B: Eksik 7 üni mekan CSV → Firestore import (Day 2 pipeline'ı kullan)

**Day 3-4 — Foto Upload Akışı**
- Cloud Storage rules
- WriteReviewScreen foto upload zaten var (Sprint 3'ten) — Place için extend
- Bir mekan için 5-10 user foto biriktiğinde admin panel ile place doc'una bağlamak (Sprint 6)
- Kısa vadeli: yorum fotoları zaten gözüküyor

**Day 5 — Analytics Lite**
- Firebase Analytics entegrasyonu (sadece event'ler, dashboard yok)
- 10-15 önemli event log'la (place_view, review_create, comparison_create, vs)

**Day 6 — Store Listing Hazırlığı**
- App Store Connect listing tamam
- Play Store listing güncellemesi
- Screenshot'lar (5-6 ekran, telefon + tablet boyutu)
- Privacy Policy, Terms

**Day 7 — Soft Launch**
- Play Store Internal → Closed Beta'ya promote
- App Store TestFlight External
- 30-50 kullanıcıya genişlet
- Crash report monitoring (Firebase Crashlytics)

**Day 8 — Public Release**
- Play Store Production submit
- App Store review submit
- Smoke test on Production builds
- Sprint 5 retro + Sprint 6 planning

> [!IMPORTANT]
> Apple App Store review 1-3 gün sürebilir. Day 8'de submit etseniz bile yayın 1-3 gün sonra. Kullanıcılara duyuruyu yayın aktif olduktan sonra yapın.

### 🎯 Sprint 5 Başlangıç Toplantısı Gündem (Day 1 sabah)

1. **(15dk)** Sprint 4 retro hatırlatma — neyi farklı yapacağız?
2. **(20dk)** Sprint 5 kapsam onayı — kim hangi parçayı alıyor?
3. **(15dk)** Critical bug listesi prioritize — başla, sonra parallel
4. **(10dk)** Apple/Play hesap durumu, store listing
5. **(10dk)** Bağımlılıklar — APNs sertifikası gelmesi nedir?

---

## 🎯 Sprint 4 Özet Kart

> Tek sayfada Sprint 4'ün tamamı.

### Hedef
3 büyük özelliği üretime hazır getir: **Mekanlar** (509 mekan, 31 üni), **Karşılaştırma** (2 üni yan yana), **Bildirimler** (FCM + 3 trigger).

### Teslim
- ✅ 509 mekan Firestore'da, 31 üniversite için listeleniyor
- ✅ Place detay ekranı tam (foto/info/amenities/yorum)
- ✅ Place yorum yazma + 4 kategori puan
- ✅ Karşılaştırma ekranı 6 kategori bar + paylaş
- ✅ Push notification altyapısı (Android, iOS Sprint 5'e)
- ✅ 3 bildirim tipi (review_liked / review_moderated / favorite_new_review)
- ✅ Bildirim merkezi + ayarları
- ✅ 8 yeni üni + 1 yeni şehir (Çorum)
- ✅ Üniversite kampüs yerleşimi (3 tip rozet)

### Yeni Dosyalar (yaklaşık)
- 12 yeni domain model + repository
- 18 yeni widget / screen
- 5 yeni Cloud Function
- 3 yeni Riverpod provider modülü
- ~30 dosya toplam

### Yeni Bağımlılıklar
```yaml
firebase_messaging: ^15.x
flutter_local_notifications: ^17.x
screenshot: ^3.x
share_plus: ^10.x
url_launcher: ^6.x  # zaten varsa skip
```

### Riskler ve Mitigasyon
| Risk | Mitigasyon |
|---|---|
| iOS APNs sertifikası gecikiyor | Sprint 4 Android-only, iOS Sprint 5'e |
| 509 mekan import yavaşlığı | Python parser + chunked write (250'şer batch) |
| Cloud Function cold start | Memory 256MB, timeout 60s, kabul edilir gecikme |
| Topic subscribe scale | 100+ favori bulk parallelization |
| Karşılaştırma ekranı performans | `compute()` isolate, `FutureProvider` cache |

### Bilinen Eksikler (Sprint 5'e taşındı)
- iOS push bildirimleri
- 7 üni (Boğaziçi, Koç, Sabancı, Bilkent, Yaşar, İYTE, Bilgi) için mekan
- Mekan foto upload (admin panel'den)
- Comparison kaydetme (favori karşılaştırmalar)
- Admin panel
- Analytics

### Başarı Metrikleri (Sprint Sonunda Ölçüm)
- Internal Beta'da 1 hafta crash-free oranı: > %98
- 5+ test kullanıcısı en az 1 yorum yazdı
- 3+ test kullanıcısı 1 karşılaştırma yaptı
- Bildirim açılma oranı (delivered → opened): > %30
- Push permission kabul oranı: > %60

---

## 🎬 Sonsöz

İki sprint, iki insan, ciddi bir iş. Sprint 3'te yorum sistemini, Sprint 4'te Mekanlar + Karşılaştırma + Bildirimler'i kurdunuz. ÜniSeç artık MVP'sinin %85'ine ulaştı.

Sprint 4'te öne çıkanlar:
- **509 mekan** seedlendi — Türkiye'deki 31 üniversitenin kafelerini, yurtlarını, kütüphanelerini bir araya getirdiniz
- **8 yeni üniversite** + **Çorum** şehri eklendi
- **Firebase Cloud Messaging** entegrasyonu — production-ready push notification altyapısı
- **5 yeni Cloud Function** — sunucusuz mimari ile veri tutarlılığı, moderasyon, bildirim
- **Karşılaştırma ekranı** — kullanıcılar 2 üniyi yan yana görüp paylaşabiliyor

Sprint 4 bittiğinde elde olan:
- 31 üniversite, 38 toplam (Sprint 5'te yedi tane daha)
- 509 mekan, kategorize edilmiş, detaylı
- 5 Cloud Function (Sprint 3'tekiler dahil 7+)
- Tam yorum sistemi (üni + bölüm + place için)
- Karşılaştırma akışı
- Push notification altyapısı
- ~15-20 ekran toplam

Sprint 5 sonunda elinizde **Production-ready bir uygulama** olacak. Polish + admin panel + store listing + analytics + launch.

Bir sprint daha ✊

---

**Sprint 4 dokümanı sonu.**

