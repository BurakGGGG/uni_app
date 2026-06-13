# ÜniSeç — UI Zayıflık Analizi

Uygulamanın tüm tema sistemi, ana ekranlar, widget'lar ve navigasyon yapısı incelendi. Aşağıda kategorilere göre tespit edilen UI zayıflıkları yer almaktadır.

---

## 🔴 Kritik Sorunlar

### 1. Profil Ekranı Aşırı Büyük — **1890 satır** tek dosyada
- [profile_screen.dart](file:///home/burak/uni_app/lib/features/profile/presentation/screens/profile_screen.dart) → **73 KB**, **1890 satır**
- Tek bir dosyada guest profili, user kartı, istatistikler, admin paneli, ayarlar bottom sheet, plan detayları, seed data migration script'leri gibi **farklı sorumluluklar** var
- Bu kadar büyük bir widget rebuild'leri yavaşlatır, bakımı ve UX iterasyonunu zorlaştırır

> [!WARNING]
> Bu dosya acilen 5-6 ayrı widget/section dosyasına bölünmeli. `_SettingsBottomSheet`, `_buildStats`, `_buildUserCard`, `_buildGuestProfile`, `_showPlanDetails` bağımsız widget'lara dönüşmeli.

### 2. Dark Mode Snackbar Metin Rengi Hatalı
- [app_theme.dart:599-604](file:///home/burak/uni_app/lib/core/theme/app_theme.dart#L598-L604): Dark modda snackbar arka planı **beyaz** ama metin rengi `AppColors.textOnPrimary` yani **beyaz**
- **Sonuç:** Dark modda snackbar'daki yazılar **görünmez** (beyaz zemin üstüne beyaz metin)

```diff
 snackBarTheme: SnackBarThemeData(
   backgroundColor: Colors.white,
   contentTextStyle: GoogleFonts.inter(
     fontSize: 14,
     fontWeight: FontWeight.w400,
-    color: AppColors.textOnPrimary,  // Beyaz — HATA!
+    color: AppColors.textPrimary,     // Koyu renk olmalı
   ),
```

### 3. Dark Mode ColorScheme'de `primaryContainer` Light Renk Kullanılıyor
- [app_theme.dart:335](file:///home/burak/uni_app/lib/core/theme/app_theme.dart#L334): `primaryContainer: AppColors.primaryLight` → Bu light mode değeri, dark'ta çok açık kalır
- `secondaryContainer: AppColors.secondaryLight` da aynı sorun

---

## 🟠 Orta Seviye Sorunlar

### 4. ✅ Erişilebilirlik (a11y) Eksiklikleri — TAMAMLANDI
| Konum | Sorun | Durum |
|-------|-------|-------|
| [home_screen.dart:509](file:///home/burak/uni_app/lib/features/home/presentation/screens/home_screen.dart#L508-L515) | Hero banner'daki hardcoded Türkçe metin → `loc.homeHeroBannerTitle` ile değiştirildi | ✅ |
| [review_list.dart:96-98](file:///home/burak/uni_app/lib/features/reviews/presentation/widgets/review_list.dart#L96-L99) | `AppColors.textSecondary` → `AppColors.textSecondaryFor(context)` ile değiştirildi | ✅ |
| [review_list.dart:119-123](file:///home/burak/uni_app/lib/features/reviews/presentation/widgets/review_list.dart#L119-L123) | `AppColors.borderLight` → `AppColors.borderLightFor(context)` ile değiştirildi | ✅ |
| [review_card.dart:222-225](file:///home/burak/uni_app/lib/features/reviews/presentation/widgets/review_card.dart#L222-L226) | `compact ? titleSmall : titleSmall` → `compact ? bodyMedium : titleSmall` olarak düzeltildi | ✅ |

### 5. ✅ Loading State'leri Tutarsız — TAMAMLANDI
| Ekran | Loading Gösterimi | Durum |
|-------|-------------------|-------|
| Home — Popüler Üniversiteler | `HomeListSkeleton` (shimmer) | ✅ |
| Home — Yorumlar | `HomeListSkeleton` (shimmer) | ✅ |
| University Detail — Bölümler | `DepartmentsSkeleton` (shimmer) | ✅ Düzeltildi |
| University Detail — Yorumlar | `ReviewsSkeleton` (shimmer) | ✅ Düzeltildi |
| University Detail — Ana body | `UniversityDetailSkeleton` (shimmer) | ✅ Düzeltildi |
| University Detail — Mekanlar | `PlacesSkeleton` (shimmer) | ✅ Düzeltildi |
| Explore Screen | `ListSkeleton` (shimmer) | ✅ |
| Review List | `ListSkeleton` (shimmer) | ✅ |

> [!NOTE]
> `university_detail_skeleton.dart` dosyası oluşturuldu: `UniversityDetailSkeleton`, `DepartmentsSkeleton`, `ReviewsSkeleton`, `PlacesSkeleton` widget'ları eklendi.

### 6. ✅ Error State Tutarsızlıkları — TAMAMLANDI
- ~~Ana hata durumu sadece `Text(e.toString())`~~ → `ErrorStateWidget` + retry butonu eklendi ✅
- ~~Bölüm yükleme hatası sadece `Text('...')`~~ → `ErrorStateWidget(compact: true)` + retry eklendi ✅
- Mekanlar hata durumu → `ErrorStateWidget(compact: true)` + retry eklendi ✅
- Yorumlar hata durumu → `ErrorStateWidget(compact: true)` + retry eklendi ✅
- Tüm error state'ler artık ana sayfadakiyle aynı `ErrorStateWidget` pattern'ini kullanıyor ✅

### 7. Pull-to-Refresh Eksikliği
- **Home Screen** → `RefreshIndicator` yok — kullanıcı yeni içerik almak isterse uygulamayı yeniden açmalı
- **Explore Screen** → `RefreshIndicator` yok
- **University Detail** → var ✅

### 8. ✅ Hardcoded Türkçe Metinler (l10n eksikleri) — TAMAMLANDI

| Dosya | Metin | l10n Key | Durum |
|-------|-------|----------|-------|
| university_detail_screen.dart | `'Bölümler'` | `loc.uniDetailDepartments` | ✅ |
| university_detail_screen.dart | `'Yorumlar'` | `loc.uniDetailReviews` | ✅ |
| university_detail_screen.dart | `'Galeri'` | `loc.uniDetailGallery` | ✅ |
| university_detail_screen.dart | `'Haritada Aç'` | `loc.uniDetailOpenMap` | ✅ |
| university_detail_screen.dart | `'Üniversiteyi Değerlendir'` | `loc.uniDetailRateUniversity` | ✅ |
| university_detail_screen.dart | `'Kategori Puanları'` | `loc.uniDetailCategoryRatings` | ✅ |
| university_detail_screen.dart | `'Mekanlar'` | `loc.uniDetailPlaces` | ✅ |
| university_detail_screen.dart | `'Tüm bölümleri gör'` | `loc.uniDetailSeeAllDepartments` | ✅ |
| university_detail_screen.dart | `'Tüm yorumları gör'` | `loc.uniDetailSeeAllReviews` | ✅ |
| university_detail_screen.dart | `'Tüm mekanları gör'` | `loc.uniDetailSeeAllPlaces` | ✅ |
| university_detail_screen.dart | `'Henüz yorum yok'` | `loc.uniDetailNoReviews` | ✅ |
| university_detail_screen.dart | `'Kafeler Yakında!'` | `loc.uniDetailPlacesEmptyTitle` | ✅ |
| explore_screen.dart | `'XXX üniversite bulundu'` | `loc.exploreFoundCount(count)` | ✅ |
| explore_screen.dart | `'Sonuçları Göster'` | `loc.exploreShowResults` | ✅ |
| home_screen.dart | `'Puanını Hesapla,\nHedefini Belirle!'` | `loc.homeHeroBannerTitle` | ✅ (Madde 4'te) |

> [!NOTE]
> TR ve EN arb dosyalarına toplam ~20 yeni key eklendi. Parametreli key'ler (`{count}`) ile dinamik metinler de l10n'a taşındı.

---

## 🟡 İyileştirme Önerileri

### 9. Animasyon ve Mikro-etkileşim Eksiklikleri
- **Explore listesi**: `UniCard`'lar düz `ListView.builder` ile gösteriliyor — giriş animasyonu (staggered fade-in / slide-up) yok
- **Home popüler üniversiteler**: Yatay scroll'da kart giriş animasyonu yok
- **Bottom Navigation**: Seçili tab değiştiğinde sayfa geçişi anlık — hafif bir crossfade olabilir
- **Favorilere ekleme**: Haptic feedback veya kalp animasyonu yok (sadece icon değişiyor)

### 10. Tipografi Tutarsızlıkları
- Splash ekranında `fontFamily: 'SpaceGrotesk'` doğrudan kullanılıyor, `GoogleFonts` ile değil → font yüklenme garantisi yok
- Home ekranındaki logo metninde de aynı `fontFamily: 'SpaceGrotesk'` kalıbı → `GoogleFonts.spaceGrotesk()` kullanılmalı veya `pubspec.yaml`'da asset olarak eklenmeli

### 11. Widget Derinliği (Nesting) Problemi
- [home_screen.dart:614-724](file:///home/burak/uni_app/lib/features/home/presentation/screens/home_screen.dart#L614-L724): `_PopularUniCard` widget'ı 8 seviye iç içe Container → çok derin widget ağacı, debug zorlaşır
- [uni_card.dart:40-152](file:///home/burak/uni_app/lib/core/widgets/uni_card.dart#L40-L152): `Container > Material > Semantics > InkWell > Padding > Row` → 6 seviye nesting

### 12. Boş State UX İyileştirmeleri
- `_PlacesEmptyState` güzel tasarlanmış ama aksiyon butonu yok (ör. "Mekan öner" butonu)
- Home'daki yorum boş state'inde CTA (call-to-action) butonu yok → kullanıcıyı yorum yazmaya yönlendirilmeli

### 13. Responsive Tasarım Eksikliği
- Tablet görünümü için herhangi bir `LayoutBuilder` veya `MediaQuery` adaptasyonu yok
- Popüler üniversite kartları sabit `160px` genişlikte — büyük ekranlarda küçük kalır
- Hero Banner `minHeight: 160` — çok küçük/büyük ekranlarda uyumsuz olabilir

### 14. Dark Mode'da Border ve Divider Renkleri
- [review_list.dart](file:///home/burak/uni_app/lib/features/reviews/presentation/widgets/review_list.dart): Sort bar'daki `ChoiceChip`'ler `AppColors.borderLight` kullanıyor (`AppColors.borderLightFor(context)` yerine) — dark modda neredeyse görünmez

### 15. `withAlpha()` vs `withValues()` Karışıklığı  
- [university_detail_screen.dart:544](file:///home/burak/uni_app/lib/features/university/presentation/screens/university_detail_screen.dart#L544): `withAlpha(80)` (int tabanlı, 0-255)
- Geri kalan her yerde: `withValues(alpha: 0.12)` (double tabanlı, 0-1)
- **Tutarsız API kullanımı** — `withAlpha(80)` aslında ~0.31 alpha demek, okunabilirlik açısından kötü

---

## 📊 Öncelik Matrisi

| # | Sorun | Etki | Efor | Öncelik |
|---|-------|------|------|---------|
| 2 | Dark mode snackbar metin görünmez | 🔴 Yüksek | Düşük | **P0** |
| 5 | Loading state tutarsızlığı | 🟠 Orta | Orta | **P1** |
| 6 | Error state tutarsızlığı | 🟠 Orta | Orta | **P1** |
| 1 | Profile screen 1890 satır | 🟠 Orta | Yüksek | **P1** |
| 7 | Pull-to-refresh eksik | 🟠 Orta | Düşük | **P1** |
| 14 | Dark mode border/chip renkleri | 🟡 Düşük | Düşük | **P2** |
| 8 | Hardcoded metinler (l10n) | 🟡 Düşük | Orta | **P2** |
| 3 | Dark mode primaryContainer | 🟡 Düşük | Düşük | **P2** |
| 9 | Animasyon eksiklikleri | 🟡 Düşük | Orta | **P3** |
| 13 | Responsive tasarım | 🟡 Düşük | Yüksek | **P3** |

---

## ✅ İyi Yapılmış Noktalar

- **Tema sistemi** çok detaylı ve iyi organize — `AppColors`, `AppTextStyles`, `AppTheme` ayrımı doğru
- **Dark mode desteği** kapsamlı — `For(context)` helper'ları güzel bir pattern
- **Splash animasyonu** profesyonel düzeyde
- **Onboarding / Showcase turu** iyi entegre edilmiş
- **Shimmer skeleton'lar** var ve güzel görünüyor
- **ReviewCard widget** iyi tasarlanmış — expandable text, photo grid, pros/cons chip'leri var
- **Semantics** bazı widget'lara eklenmiş (UniCard, EmptyState)
