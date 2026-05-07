# 🚀 Karşılaştırma Ekranı — Büyük Sprint Planı
**Süre:** 14 Gün (2 Hafta) | **Ekip:** Kişi A + Kişi B  
**Conflict Stratejisi:** A = Backend/Data/Monetization | B = UI/Widgets/Screens  
**Son Güncelleme:** Mayıs 2026

---

## 📋 İçindekiler

1. [Sprint Genel Bakış](#1-sprint-genel-bakış)
2. [Monetizasyon Planı (Detaylı)](#2-monetizasyon-planı)
3. [Mimari Kararlar](#3-mimari-kararlar)
4. [Firestore Şema Değişiklikleri](#4-firestore-şema)
5. [Dosya Sahiplik Haritası](#5-dosya-sahiplik-haritası)
6. [Hafta 1 — Günlük Görevler](#6-hafta-1)
7. [Hafta 2 — Günlük Görevler](#7-hafta-2)
8. [UI/UX Spesifikasyonları](#8-uiux-spesifikasyonları)
9. [API Limitleri ve Token Yönetimi](#9-api-limitleri)
10. [Test Senaryoları](#10-test-senaryoları)
11. [Risk Analizi](#11-risk-analizi)

---

## 1. Sprint Genel Bakış

### Hedefler

| # | Hedef | Öncelik |
|---|-------|---------|
| 1 | Karşılaştırma ekranı UI'ını uygulamanın en şık ekranı yap | 🔴 Kritik |
| 2 | 3 kademeli monetizasyon sistemi kur (Free / Plus / Pro) | 🔴 Kritik |
| 3 | Bölüm karşılaştırması (Plus+) | 🟠 Yüksek |
| 4 | Şehir karşılaştırması (Plus+) | 🟠 Yüksek |
| 5 | Pro grafik paketi (scatter, trend, heat map) | 🟡 Orta |
| 6 | AI karşılaştırma özeti (Pro) | 🟡 Orta |
| 7 | Rewarded reklam entegrasyonu (Free) | 🟡 Orta |

### Conflict Önleme Kuralları

```
KİŞİ A = lib/features/comparison/data/
          lib/features/comparison/domain/
          lib/features/comparison/presentation/providers/
          lib/features/monetization/          (YENİ — tamamen A'nın)
          firestore.rules
          firestore.indexes.json

KİŞİ B = lib/features/comparison/presentation/screens/
          lib/features/comparison/presentation/widgets/
          lib/features/monetization/presentation/screens/  (sadece UI)
          lib/features/monetization/presentation/widgets/

PAYLAŞIMLI (PR'dan önce sync gerekir):
          lib/core/constants/app_constants.dart  (sadece sabitler ekle)
          lib/core/router/app_router.dart         (yeni route'lar)
```

---

## 2. Monetizasyon Planı

### 2.1 Plan Özeti

```
┌─────────────────────────────────────────────────────────────────┐
│  FREE          │  PLUS (39.90₺/ay)  │  PRO (69.90₺/ay)        │
├─────────────────────────────────────────────────────────────────┤
│ Üniversite     │ Üniversite          │ Üniversite               │
│ karşılaştırma  │ karşılaştırma       │ karşılaştırma            │
│ (1/gün ücretsiz│ (sınırsız)          │ (sınırsız)               │
│  +1 reklam)    │                     │                          │
│                │ Bölüm               │ Bölüm                    │
│                │ karşılaştırma       │ karşılaştırma            │
│                │ (sınırsız)          │ (sınırsız)               │
│                │                     │                          │
│                │ Şehir               │ Şehir                    │
│                │ karşılaştırma       │ karşılaştırma            │
│                │                     │                          │
│                │ Standart grafikler  │ Pro grafik paketi        │
│                │ (radar, bar)        │ (trend, scatter,         │
│                │                     │  ısı haritası)           │
│                │                     │                          │
│                │ Reklam yok          │ Reklam yok               │
│                │                     │                          │
│                │ ❌ AI öneri desteği  │ ✅ AI öneri desteği      │
│                │                     │ (10 sorgu/gün)           │
│                │                     │                          │
│                │                     │ AI karşılaştırma         │
│                │                     │ özeti (5/gün)            │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Free Plan Detayı

**Reklam Mantığı (Rewarded Ad):**

```
Her gün 1 ücretsiz üniversite karşılaştırması hakkı sıfırlanır (00:00'da).

Akış:
  1. Kullanıcı iki üniversite seçer
  2. "Karşılaştır" butonuna basar
  3. Firestore'daki dailyComparisonCount kontrol edilir
     - count == 0  → Direkt karşılaştırma yap
     - count >= 1  → Rewarded ad ekranı göster
  4. Kullanıcı reklamı tamamen izlerse → Karşılaştırma açılır
  5. Reklamı kapatırsa → "Reklamı izle veya Plus'a geç" banner'ı

dailyComparisonCount günlük 00:00'da sıfırlanır.
Sıfırlama: Cloud Function (scheduled, her gece) veya client-side date kontrolü.
```

**Firestore Yapısı (Free quota tracking):**
```
users/{uid}/usageStats:
  dailyComparisons: int          // bugünkü karşılaştırma sayısı
  lastComparisonDate: Timestamp  // son sıfırlama tarihi
  totalComparisons: int          // toplam (analitik için)
```

### 2.3 Plus Plan Detayı (39.90₺/ay)

**Kapsam:**
- Sınırsız üniversite + bölüm + şehir karşılaştırması
- Reklam yok
- Standart grafikler: Radar chart, bar chart, kategori karşılaştırma
- Bölüm karşılaştırması: taban puan, sıralama, kontenjan, dil, süre
- Şehir karşılaştırması: üniversite sayısı, devlet/vakıf dağılımı, şehir büyüklüğü

**Kısıtlamalar:**
- AI öneri asistanı aktif değil
- AI karşılaştırma özeti yok
- Trend/scatter/ısı haritası grafikleri yok

**Ödeme:**
- Google Play Billing (Android) + App Store (iOS)
- Aylık otomatik yenileme
- 7 gün ücretsiz deneme (ilk kez)

### 2.4 Pro Plan Detayı (69.90₺/ay)

**Kapsam (Plus'a ek olarak):**

1. **AI Öneri Asistanı** (günde 10 sorgu):
   - Tercih asistanı akışındaki son adım AI zenginleştirmesini kullanır
   - Groq Llama 3 üzerinden çalışır
   - Limit: 10 AI sorgusu/gün (token maliyeti kontrolü)

2. **AI Karşılaştırma Özeti** (günde 5 sorgu):
   - İki üniversiteyi/bölümü/şehri seçince "Bu karşılaştırmayı analiz et" butonu
   - Groq API → 2-3 cümle Türkçe özet
   - Limit: 5 AI özeti/gün

3. **Pro Grafik Paketi:**
   - **Trend Grafiği:** Seçilen üniversitelerin yıllık rating trendi (6 ay, 1 yıl)
   - **Scatter Plot:** Bölümlerin taban puan vs. sıralama dağılımı
   - **Isı Haritası:** Kategori bazlı güçlü/zayıf alan görselleştirmesi
   - **Radar Chart (gelişmiş):** 8 kategori (şu an 6)

4. **Detaylı Bölüm Karşılaştırması:**
   - Taban puan trend grafiği (scoreData.previousYears kullanarak)
   - Yıl bazlı delta gösterimi

**Token Maliyet Kontrolü:**

```
AI özeti için kullanılan prompt yaklaşık 800 token.
Groq Llama 3 70B fiyatı: ~$0.0009/1K token (input)

5 özet/gün × 800 token = 4.000 token/gün/kullanıcı
Pro plan aylık 69.90₺ (~$2.1) — makul.

Limit aşımında:
  - "Günlük AI limitine ulaştınız. Yarın tekrar deneyin." mesajı
  - Limit sayacı Firestore'da tutulur, Cloud Function her gece sıfırlar.
```

### 2.5 Abonelik Durum Akışı

```dart
// SubscriptionTier enum
enum SubscriptionTier { free, plus, pro }

// Kontrol zinciri:
// 1. RevenueCat → aktif abonelik var mı?
// 2. Yoksa → free tier
// 3. Abonelik varsa tier'ı al (plus / pro)
// 4. Her özellik için tier kontrolü yap

// Feature gate örneği:
bool canCompareDepartments(SubscriptionTier tier) =>
    tier == SubscriptionTier.plus || tier == SubscriptionTier.pro;

bool canUseAiComparison(SubscriptionTier tier) =>
    tier == SubscriptionTier.pro;
```

### 2.6 Paywall Ekranı Stratejisi

**Tetikleyiciler:**
1. Plus gerektirenler: "Bölüm Karşılaştır" veya "Şehir Karşılaştır" butonuna basma
2. Pro gerektirenler: "AI Özeti" butonuna basma
3. Free limit: Günlük ücretsiz hakkı dolunca reklam modal'ı

**Paywall Tasarımı (Kişi B):**
- Üç kart yan yana (Free / Plus / Pro)
- Önerilen plan vurgulu (Plus — "En Popüler" badge'i)
- Yıllık ödeme seçeneği (yıllık %20 indirim = 32.90₺/ay)
- Feature check-list her plan altında
- Animasyonlu geçiş

---

## 3. Mimari Kararlar

### 3.1 Abonelik Kütüphanesi: RevenueCat

```yaml
# pubspec.yaml'e eklenecek (Kişi A — Gün 1)
purchases_flutter: ^6.x.x
```

**Neden RevenueCat?**
- Google Play + App Store tek entegrasyon
- Sandbox test ortamı hazır
- Webhook → Firestore sync için Cloud Function çok kolay
- Ücretsiz plan 2500 MAU'ya kadar

### 3.2 Rewarded Reklam: Google Mobile Ads

```yaml
# pubspec.yaml'e eklenecek (Kişi A — Gün 1)
google_mobile_ads: ^4.x.x
```

**Entegrasyon Stratejisi:**
- `AdService` singleton (FCMService gibi)
- Rewarded ad önceden yüklenir (preload)
- Ad gösterimi sırasında `ComparisonPaywallScreen` açılır

### 3.3 Yeni Veri Modelleri

```
lib/features/comparison/domain/models/
  ├── comparison_result.dart      (mevcut — dokunma)
  ├── department_comparison.dart  (YENİ — Kişi A)
  └── city_comparison.dart        (YENİ — Kişi A)

lib/features/monetization/domain/models/
  ├── subscription_model.dart     (YENİ — Kişi A)
  └── usage_stats_model.dart      (YENİ — Kişi A)
```

### 3.4 Comparison Screen Routing

```
/compare                    → ComparisonHubScreen (yeni — tip seçimi)
/compare/university         → Üniversite karşılaştırma (mevcut)
/compare/department         → Bölüm karşılaştırma (YENİ — Plus+)
/compare/city               → Şehir karşılaştırma (YENİ — Plus+)
/compare/paywall            → Paywall ekranı
```

---

## 4. Firestore Şema

### 4.1 Yeni Collection: `subscriptions`

```
subscriptions/{uid}:
  tier: "free" | "plus" | "pro"
  status: "active" | "expired" | "trial"
  platform: "android" | "ios"
  expiresAt: Timestamp
  rcCustomerId: string          // RevenueCat customer ID
  trialUsed: bool
  createdAt: Timestamp
  updatedAt: Timestamp
```

**Firestore Rules (eklenecek):**
```javascript
match /subscriptions/{uid} {
  allow read: if isOwner(uid);
  allow write: if false;  // Sadece Cloud Function (webhook)
}
```

### 4.2 Yeni Subcollection: `users/{uid}/usageStats`

```
users/{uid}/usageStats:
  dailyComparisons: int          // Free: bugün yapılan karşılaştırma sayısı
  dailyAiComparisons: int        // Pro: bugün yapılan AI özet sayısı
  dailyAiRecommendations: int    // Pro: bugün yapılan AI öneri sayısı
  lastResetDate: string          // "2026-05-07" formatında
  totalComparisons: int
```

**Firestore Rules:**
```javascript
match /users/{uid}/usageStats {
  allow read: if isOwner(uid);
  allow update: if isOwner(uid) &&
    request.resource.data.diff(resource.data)
      .affectedKeys().hasOnly(['dailyComparisons', 'lastResetDate', 'totalComparisons']);
  // dailyAiXxx alanları sadece Cloud Function değiştirir
}
```

### 4.3 Yeni Firestore Indexes

```json
// firestore.indexes.json'a eklenecek
{
  "collectionGroup": "subscriptions",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "tier", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" }
  ]
}
```

---

## 5. Dosya Sahiplik Haritası

### Kişi A — Backend/Data/Monetization

```
YENİ oluşturulacak:
  lib/features/monetization/
    ├── data/
    │   ├── subscription_repository.dart
    │   ├── ad_service.dart
    │   └── usage_stats_repository.dart
    ├── domain/
    │   ├── models/
    │   │   ├── subscription_model.dart
    │   │   └── usage_stats_model.dart
    │   └── enums/
    │       └── subscription_tier.dart
    └── presentation/
        └── providers/
            ├── subscription_providers.dart
            └── usage_stats_providers.dart

  lib/features/comparison/domain/models/
    ├── department_comparison.dart      (YENİ)
    └── city_comparison.dart           (YENİ)

  lib/features/comparison/data/
    ├── department_comparison_repository.dart  (YENİ)
    └── city_comparison_repository.dart        (YENİ)

  lib/services/revenuecat_service.dart         (YENİ)

DEĞİŞTİRİLECEK (A'nın sormadan dokunmayacağı dosyalar):
  lib/features/comparison/data/comparison_repository.dart
  lib/features/comparison/presentation/providers/comparison_providers.dart
  firestore.rules
  firestore.indexes.json
  pubspec.yaml  (bağımlılık ekle — B'ye haber ver)
```

### Kişi B — UI/Screens/Widgets

```
YENİ oluşturulacak:
  lib/features/comparison/presentation/
    ├── screens/
    │   ├── comparison_hub_screen.dart          (YENİ — ana hub)
    │   ├── university_comparison_screen.dart   (mevcut YENIDEN YAZILACAK)
    │   ├── department_comparison_screen.dart   (YENİ)
    │   ├── city_comparison_screen.dart         (YENİ)
    │   └── comparison_result_screen.dart       (YENİ — ortak sonuç)
    └── widgets/
        ├── comparison_type_card.dart           (YENİ)
        ├── comparison_metric_row.dart          (YENİ)
        ├── pro_chart_widgets/
        │   ├── trend_line_chart.dart           (YENİ)
        │   ├── scatter_plot_chart.dart         (YENİ)
        │   └── heat_map_widget.dart            (YENİ)
        ├── paywall_card.dart                   (YENİ)
        └── subscription_gate_widget.dart       (YENİ)

  lib/features/monetization/presentation/
    └── screens/
        ├── paywall_screen.dart                 (YENİ)
        └── subscription_success_screen.dart    (YENİ)

DEĞİŞTİRİLECEK (B'nin başka dosyalara dokunmaması):
  lib/core/router/app_router.dart  (yeni route'lar — A'ya haber ver)
  lib/features/home/presentation/screens/home_screen.dart (küçük link)
```

### Paylaşımlı Dosyalar (PR sync gerektirir)

```
lib/core/constants/app_constants.dart
  → A: Plan ID sabitleri ekler
  → B: Renk/spacing sabitleri ekler
  → KURAL: Commit'ten önce rebase/merge

lib/core/router/app_router.dart
  → B yeni route'ları ekler (A onaylar)
  → KURAL: A branch'ine rebase sonra ekle
```

---

## 6. Hafta 1

### 📅 Gün 1 (Pazartesi) — Kurulum & Mimari

#### Kişi A
- [ ] `pubspec.yaml`'a `purchases_flutter` ve `google_mobile_ads` ekle
- [ ] RevenueCat hesabı + ürün tanımları (App Store / Play Store)
  - Ürün ID'leri: `unisec_plus_monthly`, `unisec_pro_monthly`, `unisec_plus_yearly`, `unisec_pro_yearly`
- [ ] `SubscriptionTier` enum ve `SubscriptionModel` yaz
- [ ] `RevenueCatService` singleton oluştur (FCMService pattern'i)
- [ ] Firestore'a `subscriptions` collection rules ve indexes ekle

#### Kişi B
- [ ] Mevcut `comparison_screen.dart` içeriğini yedekle → `comparison_screen_v1.dart`
- [ ] `ComparisonHubScreen` iskelet yaz (3 kart: Üniversite / Bölüm / Şehir)
- [ ] `comparison_hub_screen.dart` tasarım mockup'ı (statik)
- [ ] `paywall_screen.dart` iskelet (3 plan kartı, statik data)
- [ ] Yeni route'ları `app_router.dart`'a ekle:
  ```dart
  /compare         → ComparisonHubScreen
  /compare/paywall → PaywallScreen
  ```

---

### 📅 Gün 2 (Salı) — Subscription Core

#### Kişi A
- [ ] `SubscriptionRepository` — Firestore read/write
- [ ] `UsageStatsRepository` — dailyCount okuma/yazma + otomatik sıfırlama (lastResetDate kontrolü)
- [ ] `SubscriptionProvider` (Riverpod):
  ```dart
  final subscriptionTierProvider = StreamProvider<SubscriptionTier>((ref) {
    // RevenueCat + Firestore hybrid okuma
    // RC offline → Firestore fallback
  });
  ```
- [ ] `UsageStatsProvider` — günlük limit kontrolü
- [ ] `SubscriptionGateWidget` base class (B ile interface anlaş)

#### Kişi B
- [ ] `PaywallScreen` full UI:
  - Üç plan kartı (Free/Plus/Pro) horizontal scroll
  - Feature check-list animasyonu
  - "En Popüler" badge
  - Yıllık indirim toggle (aylık ↔ yıllık)
  - "Ücretsiz Dene (7 gün)" butonu
- [ ] `SubscriptionGateWidget` UI shell (A'nın logic'ini bekler)
- [ ] `ComparisonTypeCard` widget (hub için: ikon, başlık, açıklama, kilit ikonu)

---

### 📅 Gün 3 (Çarşamba) — Üniversite Karşılaştırma UI (Yeniden Yazım)

#### Kişi A
- [ ] `DepartmentComparisonResult` model yaz:
  ```dart
  class DepartmentComparisonResult {
    final DepartmentModel deptA;
    final DepartmentModel deptB;
    final Map<String, double> scoreDeltas; // taban, sıralama, doluluk
    final String? winnerAId;
    // ...
  }
  ```
- [ ] `DepartmentComparisonRepository.compare()` metodu
- [ ] `CityComparisonResult` model ve `CityComparisonRepository`
- [ ] Comparison providers'a department + city provider ekle

#### Kişi B
- [ ] `UniversityComparisonScreen` tam yeniden yazımı:
  - **Hero Section:** İki üniversite logosu ortada VS badge'i ile
  - **Genel Skor Strip:** büyük puan gösterimi, delta badge
  - **Animasyonlu Tab Bar:** Genel | Kategoriler | Grafik | İstatistik
  - **Genel Tab:** Büyük puan kartları + özet text
  - **Kategoriler Tab:** Her kategori için animasyonlu bar
  - **Grafik Tab:** Radar chart (gelişmiş)
  - **İstatistik Tab:** Tablo görünümü
- [ ] `ComparisonHeroSection` widget (logo + VS + score)
- [ ] `AnimatedComparisonBar` widget (öncekinden daha şık)

---

### 📅 Gün 4 (Perşembe) — Üniversite UI Finalizasyon + Reklam Entegrasyonu

#### Kişi A
- [ ] `AdService` — rewarded ad yükleme ve gösterme:
  ```dart
  class AdService {
    static final AdService _instance = AdService._();
    factory AdService() => _instance;
    
    RewardedAd? _rewardedAd;
    
    Future<void> preloadRewardedAd() async { ... }
    
    Future<bool> showRewardedAd() async {
      // false dönerse paywall aç
    }
  }
  ```
- [ ] `UsageStatsRepository.incrementDailyComparison()` + `canCompare()` kontrolü
- [ ] `comparison_providers.dart`'a ad gate entegre et
- [ ] Free plan için günlük limit logic testi

#### Kişi B
- [ ] `ComparisonScreen`'de rewarded ad gate UX:
  - Limit dolunca: Frosted overlay + "Reklamı İzle / Plus'a Geç" modal
  - Reklam yüklenirken loading spinner
  - Reklam sonrası smooth geçiş
- [ ] Share card yeniden tasarımı (daha premium görünüm)
- [ ] Sonuç ekranında floating action bar (Paylaş | Favorile | Yeniden Karşılaştır)
- [ ] Animasyonlar: sayfa geçişleri, bar animasyonları

---

### 📅 Gün 5 (Cuma) — Bölüm Karşılaştırma

#### Kişi A
- [ ] `DepartmentComparisonRepository.compare()` test + edge case'ler:
  - Aynı bölüm farklı üniversite
  - Farklı puan türü bölümler (uyarı göster)
  - scoreData olmayan bölümler
- [ ] Bölüm picker provider (filtreleme: puan türü, üniversite)
- [ ] Plus gate logic: `canCompareDepartments(tier)`

#### Kişi B
- [ ] `DepartmentComparisonScreen` tam UI:
  - Bölüm picker (2 aşamalı: önce üniversite, sonra bölüm)
  - Taban puan büyük karşılaştırma
  - Sıralama delta gösterimi
  - Kontenjan/doluluk bar'ı
  - Süre / Dil / Tür bilgi satırı
  - Puan türü uyarsama banner'ı (farklı türse)
- [ ] `DepartmentPickerBottomSheet` (DepartmentPickerSheet'ten fork)
- [ ] Plus lock overlay widget

---

### 📅 Hafta 1 Sonu PR Kontrol Listesi

```
Kişi A merge edilecekler:
  ✅ SubscriptionTier, SubscriptionModel
  ✅ RevenueCatService (temel)
  ✅ SubscriptionRepository, UsageStatsRepository
  ✅ DepartmentComparisonResult model
  ✅ DepartmentComparisonRepository (temel)
  ✅ AdService (temel)
  ✅ Firestore rules güncellemesi

Kişi B merge edilecekler:
  ✅ ComparisonHubScreen
  ✅ PaywallScreen (statik, logic bağlantısı hafta 2)
  ✅ UniversityComparisonScreen (yeniden yazım)
  ✅ DepartmentComparisonScreen (iskelet)
  ✅ Yeni widget'lar

SYNC GEREKTİREN:
  ⚠️ app_router.dart — B'nin ekledikleri A'nın branch'ine rebase edilmeli
  ⚠️ pubspec.yaml — lock file conflict check
```

---

## 7. Hafta 2

### 📅 Gün 6 (Pazartesi) — Şehir Karşılaştırma + RevenueCat Entegrasyonu

#### Kişi A
- [ ] `CityComparisonRepository.compare()` tamamla:
  - Şehirdeki üniversite sayısı, devlet/vakıf dağılımı
  - Popüler bölüm türleri
  - Ortalama üniversite puan/yorum sayısı
  - Karşılaştırmalı büyüklük (nüfus — Firestore'daki city modeline `population` ekle)
- [ ] RevenueCat SDK tam entegrasyon:
  - `Purchases.configure(apiKey)`
  - `getCustomerInfo()` → tier tespiti
  - `purchasePackage()` satın alma akışı
  - `restorePurchases()` geri yükleme
- [ ] `subscriptionProvider` RevenueCat'e bağla

#### Kişi B
- [ ] `CityComparisonScreen` tam UI:
  - Şehir seçici (mevcut şehir listesinden)
  - Üniversite sayısı gauge görseli
  - Devlet/Vakıf pasta grafiği (fl_chart PieChart)
  - Top 3 güçlü bölüm chip'leri
  - Şehir özellikleri (konum, plaka, büyüklük)
- [ ] `CityComparPieChart` widget
- [ ] `CityPickerBottomSheet` widget

---

### 📅 Gün 7 (Salı) — Pro Grafik Paketi

#### Kişi A
- [ ] Pro grafik verilerini hazırlayan provider'lar:
  - `ratingTrendProvider`: Üniversitelerin aylık avg rating trendi (reviews collection'dan aggregate)
  - `categoryHeatMapProvider`: 2 üniversite × N kategori matris
  - `departmentScatterProvider`: Bölümlerin baseScore vs ranking scatter verisi
- [ ] Pro gate logic: `canUseProCharts(tier)`
- [ ] Trend verisi için Firestore index ekle

#### Kişi B
- [ ] **Trend Line Chart** (`pro_chart_widgets/trend_line_chart.dart`):
  - İki üniversitenin 6 aylık avg rating trendi
  - fl_chart LineChart
  - Animasyonlu yükleme
  - Pro badge overlay (Pro değilse blur + kilit)

- [ ] **Scatter Plot** (`pro_chart_widgets/scatter_plot_chart.dart`):
  - X ekseni: taban puan | Y ekseni: sıralama
  - Renk: üniversite A (mavi) / üniversite B (turuncu)
  - Her nokta = bir bölüm, tooltip'te bölüm adı

- [ ] **Isı Haritası** (`pro_chart_widgets/heat_map_widget.dart`):
  - 2 üniversite × 6 kategori grid
  - Renk skalası: kırmızı → yeşil
  - Hücreye tıklayınca puan tooltip

---

### 📅 Gün 8 (Çarşamba) — AI Özeti (Pro) + Subscription Gate

#### Kişi A
- [ ] `AiComparisonSummaryService`:
  - Groq API çağrısı (comparison_providers.dart pattern'inden al)
  - Limit kontrolü: `usageStats.dailyAiComparisons < 5`
  - Prompt engineering:
    ```
    "İki Türk üniversitesini karşılaştırıyoruz: {A} ve {B}.
    Veriler: {JSON}
    Lütfen 2-3 cümle Türkçe karşılaştırma özeti yaz.
    Öğrenci perspektifinden, hangi öğrenciye hangisi daha uygun olur?"
    ```
  - Yanıtı Firestore'a cache'le (24 saat geçerli)

- [ ] `SubscriptionGateWidget` tam logic:
  ```dart
  class SubscriptionGateWidget extends ConsumerWidget {
    final SubscriptionTier requiredTier;
    final Widget child;
    final Widget? lockedFallback;
    // ...
  }
  ```
- [ ] Pro AI limit reset Cloud Function konfigürasyonu (günlük sıfırlama)

#### Kişi B
- [ ] AI özeti UI — `ComparisonAiSummaryCard`:
  - TypewriterText animasyonu (mevcut recommendation ekranından al)
  - Gradient kart (Pro rengi: altın/mor)
  - "AI Analizi" başlığı + sparkle ikonu
  - Yükleme skelton
  - Limit dolunca: "5 AI özetin doldu, yarın tekrar dene" mesajı
- [ ] `SubscriptionGateWidget`'ın tüm ekranlara entegrasyonu:
  - Departman karşılaştırma butonu
  - Şehir karşılaştırma butonu
  - Pro grafik bölümleri
- [ ] Paywall ekranı RevenueCat'e bağla

---

### 📅 Gün 9 (Perşembe) — Polish, Animasyonlar, Edge Case'ler

#### Kişi A
- [ ] Tüm provider'lar için error handling:
  - Ağ yoksa → cached data göster
  - RevenueCat offline → son bilinen tier kullan
  - Ad yüklenemezse → direkt paywall'a yönlendir
- [ ] Webhook Cloud Function: RevenueCat → Firestore sync
  ```
  POST /revenuecat-webhook
  → subscriptions/{uid} güncelle
  → usageStats sıfırla (plan değişince)
  ```
- [ ] Rate limiting: AI özetlerin Firestore'da kayıt altına alınması
- [ ] Analytics event'leri (Firebase Analytics):
  - `comparison_started` (type: university/department/city)
  - `paywall_shown` (trigger: limit/feature_lock)
  - `subscription_purchased` (tier: plus/pro)
  - `ad_watched` (result: success/cancelled)

#### Kişi B
- [ ] **Karşılaştırma Hub animasyonları:**
  - Kartlar staggered fade-in
  - Seçilen tip vurgulanma animasyonu
  - Lock badge pulse animasyonu
- [ ] **Sonuç ekranı polish:**
  - Winner üniversite konfeti efekti (basit)
  - Kategori barları sırayla animasyonla dolma
  - Radar chart morph animasyonu (A → B arasında)
- [ ] **Paywall polish:**
  - Plan kartları swipe animasyonu
  - Seçim glow efekti
  - Satın alma success ekranı (konfeti + checkmark)
- [ ] Dark mode kontrolü (tüm yeni widgetlar)

---

### 📅 Gün 10 (Cuma) — Test, Entegrasyon, Deployment

#### Kişi A
- [ ] RevenueCat sandbox testleri:
  - Plus satın alma akışı
  - Pro satın alma akışı
  - Abonelik iptali
  - Geri yükleme
- [ ] Free tier reklam testleri:
  - Test ad unit ID ile rewarded ad
  - Limit sıfırlama
- [ ] Firestore security rules tam test
- [ ] Usage stats sıfırlama Cloud Function deploy

#### Kişi B
- [ ] E2E akış testleri:
  - Free: Günlük limit → Ad → Karşılaştırma
  - Plus: Bölüm karşılaştırma erişimi
  - Pro: AI özeti + Pro grafikler
- [ ] Tablet layout kontrolü
- [ ] Accessibility: tüm butonlar semantic label
- [ ] Screenshot testleri (main flow)
- [ ] Performance: DevTools profiling, rebuild count

---

### 📅 Sprint Sonu Checklist

```
Teslim Kriterleri:
  ✅ Üniversite karşılaştırma yeniden tasarım — şık, animasyonlu
  ✅ 3 kademeli monetizasyon çalışıyor (sandbox)
  ✅ Rewarded ad entegrasyon çalışıyor
  ✅ Bölüm karşılaştırma (Plus+) çalışıyor
  ✅ Şehir karşılaştırma (Plus+) çalışıyor
  ✅ Pro grafik paketi (3 grafik) çalışıyor
  ✅ AI karşılaştırma özeti (Pro, limitli) çalışıyor
  ✅ Paywall ekranı şık ve functional
  ✅ Tüm gate'ler doğru tier'a göre açılıyor
  ✅ Firestore rules güvenli
  ✅ Analytics event'leri çalışıyor
```

---

## 8. UI/UX Spesifikasyonları

### 8.1 Comparison Hub Screen

```
┌─────────────────────────────────────────────┐
│  ← Karşılaştır                              │
│                                             │
│  Hangi tür karşılaştırma yapmak            │
│  istiyorsun?                                │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │  🏫  Üniversite                     │   │
│  │      İki üniversiteyi karşılaştır   │   │
│  │      Ücretsiz • Günde 1 hak        │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │  📚  Bölüm                    🔒  │   │
│  │      Aynı bölümü farklı üni'de     │   │
│  │      karşılaştır                   │   │
│  │      Plus veya Pro gerekli         │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │  🏙️  Şehir                    🔒  │   │
│  │      İki şehrin üniversite          │   │
│  │      ekosistemini karşılaştır       │   │
│  │      Plus veya Pro gerekli         │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  Aboneliğin: Ücretsiz                       │
│  [Plus'a Geç →]                            │
└─────────────────────────────────────────────┘
```

### 8.2 University Comparison Screen (Yeniden Tasarım)

```
┌─────────────────────────────────────────────┐
│  ← Üniversite Karşılaştır         📤 🔄    │
│                                             │
│  ┌──────────┐   VS   ┌──────────┐         │
│  │ ODTÜ    │        │ Hacettepe│         │
│  │ Logosu  │        │ Logosu   │         │
│  │  4.2   ◀ +0.4 ▶  3.8      │         │
│  └──────────┘        └──────────┘         │
│                                             │
│  ODTÜ genel olarak öne çıkıyor             │
│                                             │
│  [Genel] [Kategoriler] [Grafik] [İstatistik]│
│                                             │
│  ─── Grafik Tab ───                        │
│  ┌─────────────────────────────────────┐   │
│  │          Radar Chart                │   │
│  │    (6 kategori, 2 renk)             │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ─── Pro: Trend Grafiği ─── [PRO 🔒]      │
│  ┌─────────────────────────────────────┐   │
│  │  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │   │
│  │  ░░░  BLUR  —  Pro ile aç  ░░░░░  │   │
│  │  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ─── Pro: AI Analizi ─── [PRO 🔒]         │
│  ┌─────────────────────────────────────┐   │
│  │  ✨ Bu karşılaştırmayı analiz et   │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

### 8.3 Paywall Screen

```
┌─────────────────────────────────────────────┐
│  ← Planlar                                  │
│                                             │
│  Daha fazlasına erişmek için               │
│  bir plan seç 🚀                           │
│                                             │
│  [ Aylık ] ← → [ Yıllık — %20 indirim ]   │
│                                             │
│ ┌────────┐  ┌────────────┐  ┌──────────┐  │
│ │ FREE   │  │ PLUS ⭐    │  │  PRO     │  │
│ │        │  │ EN POPÜLER │  │          │  │
│ │ Bedava │  │ 39.90₺/ay  │  │ 69.90₺  │  │
│ │        │  │            │  │    /ay   │  │
│ │ ✅ 1 kar│  │ ✅ Sınırsız│  │ ✅ Plus  │  │
│ │ ❌ Böl │  │ ✅ Bölüm   │  │ ✅ AI    │  │
│ │ ❌ Şeh │  │ ✅ Şehir   │  │ ✅ Pro   │  │
│ │ ❌ AI  │  │ ❌ AI      │  │   grafik │  │
│ │        │  │            │  │          │  │
│ │ Mevcut │  │ [Seç]      │  │ [Seç]   │  │
│ └────────┘  └────────────┘  └──────────┘  │
│                                             │
│  [7 Gün Ücretsiz Dene — Plus]              │
│  Güvenli ödeme • İstediğinde iptal         │
└─────────────────────────────────────────────┘
```

### 8.4 Renk Dili

```dart
// Subscription tier renkleri
// lib/core/theme/app_colors.dart'a eklenecek (B ekler, A onaylar)

static const Color tierFree = Color(0xFF6B7280);     // Gri
static const Color tierPlus = Color(0xFF6C63FF);     // Mor (primary ile aynı)
static const Color tierPro = Color(0xFFD4A017);      // Altın

static const LinearGradient tierPlusGradient = LinearGradient(
  colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
);

static const LinearGradient tierProGradient = LinearGradient(
  colors: [Color(0xFFD4A017), Color(0xFFFF8C00)],
);

// Lock badge — bulanık bölümlerin üstüne
static const Color lockOverlay = Color(0x88000000);
```

---

## 9. API Limitleri

### 9.1 Token Tüketimi Tahmini

```
Senaryo: 1000 Pro kullanıcı, her biri günde 3 AI özeti istiyor

Prompt boyutu (karşılaştırma özeti):
  - System: ~200 token
  - Comparison data (JSON): ~400 token
  - Total input: ~600 token
  - Output: ~150 token
  = ~750 token/istek

1000 kullanıcı × 3 istek × 750 token = 2.250.000 token/gün

Groq Llama 3 70B fiyatı: $0.00059/1K input token
Maliyet: 2.250.000 × 0.00059 / 1000 = ~$1.33/gün = ~$40/ay

Pro plan geliri (1000 kullanıcı × 69.90₺ ≈ $2.1): ~$2100/ay
AI maliyeti: ~$40/ay → MAKUL (gelirin %2'si)
```

### 9.2 Limit Stratejisi

```
SOFT LIMIT (uyarı ver ama blokla):
  - 8/10 AI sorgusu kullanıldıysa: "2 hakkın kaldı" banner

HARD LIMIT (blokla):
  - 10/10 tükenince: modal göster
  - Cloud Function gece 00:00'da sıfırla

ABUSE DETECTION (Cloud Function):
  - 5 dakikada 10 istek → 24 saat ban
  - Firestore'a flagged: true yaz

CACHE STRATEJİSİ:
  - Aynı A+B üniversite çifti için AI özeti 24 saat cache'le
  - Cache key: MD5(uniIdA + "_" + uniIdB)
  - Firestore: aiSummaryCache/{cacheKey}
    - summary: string
    - createdAt: Timestamp
    - expiresAt: Timestamp
```

### 9.3 Firestore Okuma Maliyeti Optimizasyonu

```
Comparison ekranının şu anki okuma sayısı:
  - 2 × getUniversity = 2 reads (cache'li)
  - 2 × getPlacesByUniversity = ~10 reads
  - 2 × getDepartmentsByUniversity = ~60 reads
  TOPLAM: ~72 reads/karşılaştırma

Optimizasyon (Kişi A — Gün 9):
  - Tüm veriler zaten provider cache'inde
  - Sadece ilk açılışta Firestore hit
  - Sonraki karşılaştırmalar in-memory
```

---

## 10. Test Senaryoları

### 10.1 Monetizasyon Testleri

```
TC-M01: Free kullanıcı ilk karşılaştırma
  Given: Free kullanıcı, 0 günlük karşılaştırma
  When: Üniversite karşılaştırma başlat
  Then: Direkt sonuç göster, count = 1

TC-M02: Free kullanıcı ikinci karşılaştırma
  Given: Free kullanıcı, 1 günlük karşılaştırma
  When: Üniversite karşılaştırma başlat
  Then: Rewarded ad ekranı açılır

TC-M03: Free kullanıcı reklamı izler
  Given: Rewarded ad ekranı açık
  When: Kullanıcı reklamı tamamen izler
  Then: Karşılaştırma sonucu açılır, count = 2

TC-M04: Free kullanıcı reklamı kapatır
  Given: Rewarded ad ekranı açık
  When: Kullanıcı reklamı kapatır
  Then: "Plus'a geç veya reklamı izle" modal

TC-M05: Free kullanıcı bölüm karşılaştırma dener
  Given: Free kullanıcı
  When: "Bölüm Karşılaştır" kartına tıklar
  Then: Paywall ekranı açılır (Plus+ required)

TC-M06: Plus kullanıcı bölüm karşılaştırma
  Given: Aktif Plus aboneliği
  When: Bölüm karşılaştırma başlat
  Then: Direkt DepartmentComparisonScreen açılır

TC-M07: Plus kullanıcı Pro grafik dener
  Given: Aktif Plus aboneliği
  When: Trend grafiği bölümüne gelir
  Then: Blurlanmış önizleme + "Pro gerekli" overlay

TC-M08: Pro kullanıcı AI özeti
  Given: Aktif Pro aboneliği, 0 günlük AI özet
  When: "AI Analizi" butonuna basar
  Then: Groq API çağrısı, TypewriterText ile özet

TC-M09: Pro kullanıcı AI limit dolar
  Given: Aktif Pro, 5/5 AI özet kullanıldı
  When: "AI Analizi" butonuna basar
  Then: "Günlük limitiniz doldu" mesajı

TC-M10: Gece sıfırlama
  Given: Free kullanıcı, 3 günlük karşılaştırma
  When: Saat 00:00 geçer (veya lastResetDate != today)
  Then: dailyComparisons = 0, ilk karşılaştırma ücretsiz
```

### 10.2 Karşılaştırma Sonucu Testleri

```
TC-C01: Yorum yok karşılaştırma
  Given: Her iki üniversitede yorum yok
  Then: "Henüz yeterli veri yok" mesajı

TC-C02: Tek yorum var
  Given: Sadece A üniversitesinde yorum var
  Then: B için "Veri yok", A normal göster

TC-C03: Farklı puan türü bölüm karşılaştırma
  Given: Bölüm A SAY, Bölüm B EA
  Then: Uyarı banner + "Taban puanlar karşılaştırılamaz"

TC-C04: Aynı bölüm iki üniversite
  Given: "Bilgisayar Müh." ODTÜ vs Hacettepe
  Then: Taban, sıralama, doluluk karşılaştırması

TC-C05: Karşılaştırma paylaşım
  Given: Sonuç ekranı açık
  When: Paylaş butonuna basılır
  Then: Screenshot alınır, share sheet açılır
```

---

## 11. Risk Analizi

### 11.1 Teknik Riskler

| Risk | Olasılık | Etki | Önlem |
|------|----------|------|-------|
| RevenueCat entegrasyonu zorluğu | Orta | Yüksek | Gün 1-2'de erken test; sorun olursa Gün 3'te in-app purchase direkt entegre |
| Google Ads onayı (rewarded) | Düşük | Orta | Test ad unit ID ile geliştir; canlıda onay süreci 1-3 gün |
| Groq API downtime | Düşük | Düşük | AI özeti opsiyonel feature; fallback = "Şu an mevcut değil" |
| Firestore cost spike (Pro grafikler) | Düşük | Orta | Aggregation data pre-compute; Cloud Function trigger'larla |
| RevenueCat webhook gecikmesi | Orta | Orta | Client-side RC kontrolü primary; Firestore secondary |

### 11.2 İş Riskleri

| Risk | Önlem |
|------|-------|
| 39.90₺ çok pahalı bulunabilir | A/B test: 29.90₺ alternatif; yıllık indirimle 24.90₺/ay |
| Pro AI limiti şikayeti (10/gün) | Uygulamada görünür limit sayacı; "Bu ay 247 AI özet yaptın" profil istatistiği |
| Reklamlar çok sık — UX bozulması | Hard cap: Günde max 3 reklamlı karşılaştırma; sonrası paywall direkt |

### 11.3 Geri Dönüş Planı

```
Eğer RevenueCat 2 günde entegre edilemezse:
  → Gün 3'te "Plus/Pro" toggle'ı Firestore admin console'dan elle set et
  → Monetizasyon gizli kalsın, UI tamamlansın
  → Sprint sonrası ayrı mini-sprint

Eğer Groq AI bütçe aşarsa:
  → Pro'da AI özeti günde 3'e düşür
  → "Token limit" flag'i Cloud Function'da kontrol et
```

---

## Ekler

### Ek A — Yeni pubspec.yaml Bağımlılıkları

```yaml
# Kişi A — Gün 1'de ekler
purchases_flutter: ^6.29.0
google_mobile_ads: ^4.0.0
```

### Ek B — RevenueCat Ürün ID Mapping

```dart
// lib/features/monetization/domain/models/subscription_model.dart
class RevenueCatProductIds {
  static const plusMonthly = 'unisec_plus_monthly';
  static const plusYearly  = 'unisec_plus_yearly';
  static const proMonthly  = 'unisec_pro_monthly';
  static const proYearly   = 'unisec_pro_yearly';
}

class RevenueCatEntitlements {
  static const plus = 'plus_access';
  static const pro  = 'pro_access';
}
```

### Ek C — Cloud Function Listesi

```
compareUsage-resetDailyStats  → Her gün 00:00 (cron)
  - users/{uid}/usageStats reset

compareUsage-resetAiQuota     → Her gün 00:00 (cron)
  - usageStats.dailyAiComparisons = 0
  - usageStats.dailyAiRecommendations = 0

revenuecat-webhook            → HTTP trigger
  - RevenueCat → subscriptions/{uid} sync

aiSummaryCache-cleanup        → Her gün 02:00 (cron)
  - aiSummaryCache'den süresi dolmuşları sil
```

### Ek D — Analytics Event Şeması

```dart
// Tüm event'ler
FirebaseAnalytics.instance.logEvent(name: 'comparison_started', parameters: {
  'type': 'university' | 'department' | 'city',
  'user_tier': 'free' | 'plus' | 'pro',
});

FirebaseAnalytics.instance.logEvent(name: 'paywall_shown', parameters: {
  'trigger': 'daily_limit' | 'feature_lock_department' | 'feature_lock_city' | 'feature_lock_pro',
  'user_tier': 'free' | 'plus',
});

FirebaseAnalytics.instance.logEvent(name: 'subscription_purchased', parameters: {
  'tier': 'plus' | 'pro',
  'billing': 'monthly' | 'yearly',
  'price_try': 39.90 | 69.90 | 32.90 | 58.90,
});

FirebaseAnalytics.instance.logEvent(name: 'ad_rewarded', parameters: {
  'result': 'completed' | 'cancelled',
  'daily_comparison_count': int,
});

FirebaseAnalytics.instance.logEvent(name: 'ai_summary_requested', parameters: {
  'comparison_type': 'university' | 'department' | 'city',
  'daily_ai_count': int,
  'cache_hit': bool,
});
```

---

*Sprint Planı — ÜniSeç Karşılaştırma Ekranı Büyük Atılımı*  
*Hazırlayan: Claude | Mayıs 2026*
