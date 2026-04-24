# 🐛 Sprint 3 — Hata Ayıklama & Polish Programı

> **Süre:** 5 iş günü (1 hafta)
> **Ekip:** Kişi A + Kişi B
> **Amaç:** Sprint 3'ten Sprint 4'e geçmeden önce tespit edilen 8 kritik bug'ı çözüp, temel optimizasyonları yapmak
> **Giriş noktası:** Sprint 3 sonunda `v0.3.0` deploy edildi, develop branch'i stabil ama bu 8 sorun var
> **Çıkış hedefi:** `v0.3.1` — bug-free, optimize, Sprint 4'e hazır

---

## 📋 Bug Özeti ve Önceliklendirme

| # | Bug | Önem | Sahip | Tahmini Süre |
|---|-----|------|-------|--------------|
| 1 | Yayınlanmamış yorumlar "Yorumlarım"da belirtilmiyor | Orta | Kişi A | 2-3 saat |
| 2 | Bazı yorumlara tıklayınca "Üniversite bulunamadı" hatası | **Kritik** | Kişi B | 1 saat |
| 3 | Ana sayfa "Tümünü Gör" butonu pasif + filtreli tüm yorumlar ekranı | Yüksek | Kişi B | 6-8 saat |
| 4 | Yorum silindiğinde profilde reviewCount hemen güncellenmiyor | Yüksek | Kişi A | 1-2 saat |
| 5 | Genel performans optimizasyonu (kasma sorunları) | Yüksek | **Birlikte** | 4-5 saat |
| 6 | Photo gallery'de beyaz fotoda geri tuşu görünmüyor | Düşük | Kişi B | 30 dk |
| 7 | Kendi üniversitesi olmayan kullanıcıya "Değerlendir" butonu gösteriliyor | Yüksek | Kişi A | 2 saat |
| 8 | Galeriden tek tek foto seçiliyor (çoklu seçim olmalı) | Orta | Kişi A | 1 saat |

**Toplam tahmin:** ~20 saat × 2 kişi = 40 person-hours → 5 iş gününe rahat sığar.

---

## 🎯 Görev Dağılımı (Çakışma Haritası)

### Kişi A — State & Flow
- Bug 1: Onay Bekliyor rozeti (write flow + owner view)
- Bug 4: Cache invalidation (auth_repository + controller)
- Bug 7: Koşullu Değerlendir butonu (write entry points)
- Bug 8: Çoklu foto seçimi (photo_upload_section)
- Optimizasyon bloğu: `write_review_screen`, `photo_upload_section`, `auth_repository`

### Kişi B — UI & Navigation
- Bug 2: Yorum navigation (home_screen, review_card onTap)
- Bug 3: `AllReviewsScreen` + filtreleri + provider
- Bug 6: Photo gallery AppBar görünürlüğü
- Optimizasyon bloğu: `review_card`, `home_screen`, `favorites_screen`, liste animasyonları

### Çakışma Noktaları (Dikkat!)
- **`review_card.dart`**: Hem A (badge eklenecek) hem B (optimize edilecek) dokunacak → **A önce gün 2'de push, B gün 4'te üstüne build et**
- **`review_providers.dart`**: A cache helper ekleyecek, B `allReviewsProvider` ekleyecek → **Farklı section'larda çalışın, import çakışmasına dikkat**
- **`home_screen.dart`**: B iki bug için de dokunacak (2 ve 3) → sorun yok, tek sahip

---

## 🎬 Başlamadan Önce: Hazırlık (30dk, birlikte)

### 1. Develop Branch'i Güncelle
```bash
git checkout develop
git pull origin develop
flutter pub get
flutter run
# Uygulama düzgün açılıyor mu? Evet → devam.
```

### 2. Yeni Branch'ler Aç
```bash
# Kişi A
git checkout -b fix/sprint3-state-flow

# Kişi B
git checkout -b fix/sprint3-ui-nav
```

### 3. GitHub Issue Aç
Her bug için birer issue aç, sahibini ata. Bu 8 issue sprint boyunca takip için referans olacak. Label: `bug`, `sprint3-fix`.

### 4. Test Hesapları Hazırla
- Hesap A: `test.kullanici@odtu.edu.tr` (ODTÜ doğrulamalı)
- Hesap B: `test.admin@bogazici.edu.tr` (Boğaziçi doğrulamalı)
- Farklı üniversitelerdeki iki kullanıcı olsun ki Bug 7 test edilebilsin.

### 5. Mevcut Durumu Belgele
Herhangi bir testçiyle uygulamayı 10dk kullanın. Bug'ların **gerçekten yaşandığını** video veya ekran görüntüsüyle belgele. Fix sonrası karşılaştırma için değerli.

---

## 📆 GÜN 1: Hızlı Kazançlar

> **Hedef:** En hızlı çözülen 4 bug (2, 6, 7, 8) bu gün bitmeli. Bu dördü sprinte momentum kazandırıyor.

### 🌅 Sabah Standup (15dk)
Bugün odak dört bug. İkiniz de net, paralel çalışabilirsiniz.

---

### 🧑‍💻 Kişi A — Bug 7 + Bug 8

#### **Bug 7: Koşullu "Değerlendir" Butonu**

**Kök sebep:** `university_detail_screen.dart` ve `department_detail_screen.dart` içindeki "Değerlendir" butonu her kullanıcıya gösteriliyor. Firestore rules yoruma engel oluyor ama kullanıcı butona basınca form ekranı açılıyor, sonra submit'te permission-denied alıyor — kötü UX.

**Fix 1:** `university_detail_screen.dart` içindeki mevcut Row'u Consumer ile sarmala ve kullanıcının üniversitesini kontrol et:

```dart
// university_detail_screen.dart
// Eski "Değerlendir" butonu olan Row'u bul ve şöyle güncelle:

Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Row(
      children: [
        const Icon(Icons.rate_review_rounded, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Text('Yorumlar', style: AppTextStyles.headlineMedium),
      ],
    ),
    // YENİ: Consumer ile sarmala
    Consumer(
      builder: (context, ref, _) {
        final currentUserAsync = ref.watch(currentUserProvider);
        return currentUserAsync.when(
          data: (profile) {
            // Sadece kendi üniversitesine yorum yazabilir + edu.tr doğrulamalı olmalı
            final canReview = profile != null &&
                profile.universityId == universityId &&
                profile.isVerifiedStudent;

            if (!canReview) {
              // Buton yerine küçük bilgi metni
              if (profile == null) {
                return TextButton.icon(
                  onPressed: () => context.push('/login'),
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: const Text('Giriş yap'),
                );
              }
              if (profile.universityId != universityId) {
                return Tooltip(
                  message: 'Sadece kendi üniversitene yorum yapabilirsin',
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.textTertiary,
                    size: 18,
                  ),
                );
              }
              if (!profile.isVerifiedStudent) {
                return Tooltip(
                  message: 'edu.tr doğrulaması gerekli',
                  child: Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.warning,
                    size: 18,
                  ),
                );
              }
              return const SizedBox.shrink();
            }

            return TextButton.icon(
              onPressed: () =>
                  context.push('/write-review/university/$universityId'),
              icon: const Icon(Icons.add_comment_rounded, size: 18),
              label: const Text('Değerlendir'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
              ),
            );
          },
          loading: () => const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    ),
  ],
)
```

Import gereken: `currentUserProvider` için zaten import'lar var.

**Fix 2:** `department_detail_screen.dart` için aynı mantık, ama burada `dept.universityId` kullanılmalı:

```dart
// department_detail_screen.dart
// "Değerlendir" butonunu şöyle koşullu yap:

Consumer(
  builder: (context, ref, _) {
    final currentUserAsync = ref.watch(currentUserProvider);
    return currentUserAsync.when(
      data: (profile) {
        final canReview = profile != null &&
            profile.universityId == dept.universityId &&
            profile.isVerifiedStudent;

        if (!canReview) {
          // Giriş yapmamış veya uygun değil
          return Tooltip(
            message: profile == null
                ? 'Giriş yapın'
                : profile.universityId != dept.universityId
                    ? 'Sadece kendi üniversitenin bölümlerine yorum yapabilirsin'
                    : 'edu.tr doğrulaması gerekli',
            child: Icon(
              Icons.info_outline_rounded,
              color: AppColors.textTertiary,
              size: 18,
            ),
          );
        }

        return TextButton.icon(
          onPressed: () => context.push(
            '/write-review/department/$departmentId?uni=${dept.universityId}',
          ),
          icon: const Icon(Icons.add_comment_rounded, size: 18),
          label: const Text('Değerlendir'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              side:
                  BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  },
)
```

**Test:**
1. ODTÜ öğrencisi olarak giriş yap
2. ODTÜ sayfası → "Değerlendir" butonu görünmeli ✅
3. Boğaziçi sayfası → tooltip'li info icon görünmeli ✅
4. Çıkış yap → iki sayfada da "Giriş yap" butonu ✅
5. edu.tr doğrulamamış hesapla gir → tooltip'li uyarı ikonu ✅

---

#### **Bug 8: Çoklu Foto Seçimi**

**Kök sebep:** `photo_upload_section.dart` içindeki `_pickImage` metodu `pickImage()` kullanıyor — tek foto. `pickMultiImage()` kullanılmalı (sadece galeri için; kamera zaten tek foto mantıklı).

**Fix:** `lib/features/reviews/presentation/widgets/review_form_sections/photo_upload_section.dart`

```dart
// Mevcut _pickImage metodunu şöyle güncelle:

Future<void> _pickImage(ImageSource source) async {
  if (!_canAddMore) return;

  if (source == ImageSource.gallery) {
    // Çoklu seçim
    final picked = await _picker.pickMultiImage(
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 75,
    );

    if (picked.isEmpty) return;

    // Kalan slotu hesapla ve sınırla
    final remainingSlots =
        PhotoUploadSection.maxPhotos - _totalPhotos;
    final toAdd = picked.take(remainingSlots).toList();

    for (final file in toAdd) {
      widget.onAdd(File(file.path));
    }

    // Eğer daha fazla foto seçtiyse uyar
    if (picked.length > remainingSlots && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'En fazla ${PhotoUploadSection.maxPhotos} foto yüklenebilir. '
            '${toAdd.length} tanesi eklendi.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } else {
    // Kamera — tek foto
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 75,
    );

    if (picked != null) {
      widget.onAdd(File(picked.path));
    }
  }
}
```

> [!NOTE]
> `pickMultiImage` API'si `image_picker ^1.0.0` ve üzerinde mevcut. `pubspec.yaml`'de versiyonu kontrol et. Eğer eskiyse:
> ```bash
> flutter pub upgrade image_picker
> ```

**Test:**
1. Değerlendir ekranına git
2. Foto Ekle → Galeriden Seç
3. 5 fotoyu bir arada seç → sadece 3'ü eklendi, snackbar uyarıyor ✅
4. Mevcut 1 foto var → 2 daha seç, 2'si de eklenir ✅
5. Kamera ile çek → hala tek foto (beklenen) ✅

---

### 🎨 Kişi B — Bug 2 + Bug 6

#### **Bug 2: "Üniversite bulunamadı" Hatası**

**Kök sebep:** `home_screen.dart` içindeki `recentReviewsProvider` yorumlarına tıklanınca:

```dart
onTap: () => context.push('/university/${review.targetId}'),
```

Ama **bölüm yorumu** için `review.targetId` = **bölüm ID'si**. `/university/:uniId` route'u bölüm ID'si alınca eşleşme bulamıyor ve "Üniversite bulunamadı" döndürüyor.

**Fix:** Tip kontrolü ile doğru route'a yönlendir.

`home_screen.dart` içindeki ReviewCard yönlendirmesini güncelle:

```dart
// home_screen.dart — recentReviewsProvider bölümü
return ReviewCard(
  review: review,
  compact: true,
  showReportMenu: false,
  showActions: false,
  // YENİ: Tip bazlı navigation
  onTap: () {
    if (review.type == ReviewType.department) {
      context.push('/department/${review.targetId}');
    } else {
      context.push('/university/${review.targetId}');
    }
  },
);
```

**İleri seviye kontrol:** `review_list.dart` ve `my_reviews_screen.dart`'ta da aynı hata var mı? Bak:

- `review_list.dart`: ReviewCard'a `onTap` vermiyor, sadece action menu bağlı. Sorun yok.
- `my_reviews_screen.dart`: Aynı şekilde onTap yok. Sorun yok.
- `favorites_screen.dart`: Sadece üniversiteler, sorun yok.

**Bonus fix:** Kullanıcı hatalı bir URL'e giderse düzgün bir hata sayfası göstermek için `app_router.dart`'a errorBuilder ekle:

```dart
// app_router.dart GoRouter içine ekle:
errorBuilder: (context, state) => Scaffold(
  appBar: AppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => context.go('/'),
    ),
  ),
  body: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
        const SizedBox(height: 16),
        Text('Sayfa bulunamadı', style: AppTextStyles.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Aradığınız içerik taşınmış veya silinmiş olabilir.',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.home_rounded),
          label: const Text('Ana Sayfaya Dön'),
        ),
      ],
    ),
  ),
),
```

**Test:**
1. Bir bölüme yorum yaz
2. Ana sayfa son yorumlarda bu bölüm yorumu çıkmalı
3. Yoruma tıkla → **bölüm detay sayfası** açılmalı ✅ (önceden "üniversite bulunamadı" dolardı)
4. Bir üniversite yorumu da tıkla → üniversite detayına gitmeli ✅

---

#### **Bug 6: Photo Gallery AppBar Görünürlüğü**

**Kök sebep:** `photo_gallery_screen.dart` içinde:
```dart
appBar: AppBar(
  backgroundColor: Colors.transparent,
  iconTheme: const IconThemeData(color: Colors.white),
  ...
),
extendBodyBehindAppBar: true,
```

Beyaz fotoda beyaz ikonlar kayboluyor.

**Fix:** İkonları semi-transparent daireler içine al, başlığı da pill içine koy.

`lib/features/reviews/presentation/screens/photo_gallery_screen.dart`:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      // YENİ: Icon'u container içinde semi-transparent daire
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      // YENİ: Başlığı pill içine al
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      centerTitle: true,
    ),
    body: PhotoViewGallery.builder(
      // ... mevcut kod
    ),
  );
}
```

**Test:**
1. Yoruma beyaz arka planlı bir foto ekle
2. Foto galeriyi aç
3. Geri tuşu ve sayfa numarası artık her fotoda görünür ✅

---

### 🌆 Akşam Sync (20dk)
- 4 bug'ın demosunu yapın
- İki kişi de branch'ini push etsin, küçük PR açsın
- Develop'a merge
- Yarın: Kişi A bug 1 ve 4, Kişi B bug 3'e başlıyor

### ✅ Gün 1 Bitişinde Durum
- [x] Bug 2 çözüldü (navigation)
- [x] Bug 6 çözüldü (gallery appbar)
- [x] Bug 7 çözüldü (koşullu buton)
- [x] Bug 8 çözüldü (çoklu foto)
- [x] Kalan: Bug 1, 3, 4, 5

---

## 📆 GÜN 2: State Yönetimi + All Reviews Başlangıcı

> **Hedef:** Kişi A "Onay Bekliyor" badge + cache invalidation'ı bitirecek, Kişi B `AllReviewsScreen` iskeleti kuracak.

### 🌅 Sabah Standup (10dk)
Dün ne bitti, bugün ne yapılacak — hızlıca geç.

---

### 🧑‍💻 Kişi A — Bug 1 + Bug 4

#### **Bug 1: Onay Bekliyor Rozeti**

**Kök sebep:** `firestore.rules` içinde:
```
allow read: if resource.data.isApproved == true
  || (request.auth != null && request.auth.uid == resource.data.userId);
```

Kullanıcı kendi onaysız yorumunu görüyor — **bu doğru davranış**. Sorun: UI'da bu yorumun henüz **yayınlanmadığını** belirten bir gösterge yok. Kullanıcı yorumunun yayında olduğunu sanıyor, tekrar yazmaya çalışıyor veya şüpheleniyor.

**Fix:** `review_card.dart` içine bir "Moderasyon Durumu Banner'ı" ekle. Sadece `!isApproved && showActions` (yani kendi kartı) ise göster.

`lib/features/reviews/presentation/widgets/review_card.dart`:

```dart
// build() metodunun içindeki Padding'in Column'unun EN BAŞINA ekle:

Padding(
  padding: const EdgeInsets.all(AppConstants.spacingLg),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // YENİ: Onay bekliyor banner'ı (sadece sahibine ve onaylanmamışsa)
      if (!review.isApproved && showActions) _buildPendingApprovalBanner(),
      if (!review.isApproved && showActions) const SizedBox(height: 12),
      
      _buildHeader(context),
      const SizedBox(height: 12),
      _buildComment(),
      // ... mevcut kodlar
    ],
  ),
),

// Yeni metot — class'ın içine ekle:

Widget _buildPendingApprovalBanner() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.warning.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        Icon(Icons.pending_actions_rounded, color: AppColors.warning, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yayınlanmadı',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Yorumun otomatik moderasyon sistemimize takıldı. '
                'Uygunsuz içerik tespit edildiyse düzenleyerek tekrar gönderebilirsin.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.warning,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
```

**Bonus:** `my_reviews_screen.dart` içine liste başlığı olarak "Onaylanmamış yorumlarınız var" bildirimi ekle:

```dart
// my_reviews_screen.dart, reviewsAsync.when içinde:
data: (reviews) {
  if (reviews.isEmpty) return _buildEmptyState(context);
  
  // YENİ: Onaylanmamış yorum sayısı
  final pendingCount = reviews.where((r) => !r.isApproved).length;
  
  return Column(
    children: [
      if (pendingCount > 0)
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$pendingCount yorumun moderasyon nedeniyle yayınlanmadı. '
                  'Aşağıda işaretlendi.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: reviews.length,
          itemBuilder: (_, i) {
            final r = reviews[i];
            return ReviewCard(
              review: r,
              showActions: true,
              showReportMenu: false,
              // ... mevcut onEdited/onDeleted
            );
          },
        ),
      ),
    ],
  );
},
```

**Test:**
1. Küfürlü bir yorum yaz
2. 10 saniye bekle (Cloud Function moderation çalışsın)
3. Yorumlarım ekranına git
4. Üstte uyarı bandı, yorumun üstünde "Yayınlanmadı" banner'ı görünmeli ✅
5. Üniversite detayında bu yorum görünmemeli (isApproved=false) ✅

---

#### **Bug 4: reviewCount Cache Sorunu**

**Kök sebep:** `auth_repository.dart` 10 dakikalık in-memory cache tutuyor:
```dart
static const _cacheTtl = Duration(minutes: 10);
```

`ref.invalidate(currentUserProvider)` provider'ı yeniden çalıştırıyor ama `getUserProfile()` cache'den dönüyor. Sonuç: silindiği halde reviewCount güncellenmiyor.

Aynı sorun **yorum ekleyince** de var — reviewCount artmış olsa bile profilde eski sayı görünüyor.

**Fix 1:** `ReviewActionController`'a cache clear ekle. Ama `StateNotifier`'ın Ref erişimi yok — yapıyı bozmadan çözmek için:

**Fix 2 (önerilen):** Silme ve ekleme operasyonlarından sonra UI katmanında cache clear + invalidate yapacak bir helper oluştur.

`lib/features/reviews/presentation/providers/review_providers.dart` içine:

```dart
// Dosyanın en altına ekle:

/// Yorum ekleme/silme sonrası kullanıcı profili cache'ini temizler ve provider'ı invalidate eder.
/// Bu sayede reviewCount UI'da anında güncellenir.
void invalidateUserProfileAfterReviewChange(WidgetRef ref) {
  ref.read(authRepositoryProvider).clearCache();
  ref.invalidate(currentUserProvider);
}
```

**Fix 3:** Bu helper'ı her silme ve ekleme sonrası çağır.

**`my_reviews_screen.dart`**:
```dart
onDeleted: () async {
  await ref.read(reviewActionControllerProvider.notifier).deleteReview(r);
  invalidateUserProfileAfterReviewChange(ref); // YENİ
  if (context.mounted) {
    showAppSnackBar(
      context,
      message: 'Yorumunuz başarıyla silindi',
      isSuccess: true,
    );
  }
},
```

**`review_list.dart`**:
```dart
onDeleted: isOwner
    ? () async {
        await ref.read(reviewActionControllerProvider.notifier).deleteReview(review);
        invalidateUserProfileAfterReviewChange(ref); // YENİ
        if (context.mounted) {
          showAppSnackBar(context, message: 'Yorumunuz başarıyla silindi', isSuccess: true);
        }
      }
    : null,
```

**`write_review_screen.dart`** (yorum ekleme sonrası):
```dart
// _submitReview metodunda, success kısmında:
if (mounted) {
  setState(() {
    _isLoading = false;
    _showSuccess = true;
  });

  // YENİ: Profile cache'i temizle
  invalidateUserProfileAfterReviewChange(ref);

  await Future.delayed(const Duration(milliseconds: 1500));
  if (mounted) context.pop();
}
```

**Fix 4 (defansif):** Pull-to-refresh ekle `MyReviewsScreen`'e ki kullanıcı istediğinde manuel yenileyebilsin:

```dart
// my_reviews_screen.dart body:
body: RefreshIndicator(
  onRefresh: () async {
    invalidateUserProfileAfterReviewChange(ref);
    await Future.delayed(const Duration(milliseconds: 500));
  },
  child: reviewsAsync.when(
    // ... mevcut
  ),
),
```

**Test:**
1. 5 yorum yaz (reviewCount=5)
2. Profilde "5 yorum" görün ✅
3. Yorumlarım'a git, bir yorum sil
4. Profile geri dön (pop)
5. **Anında** 4 yorum yazmalı ✅ (önceden hala 5 yazıyordu)
6. Tekrar yorum yaz, profile dön → 5 ✅

---

### 🎨 Kişi B — Bug 3 (1. Kısım: Provider + Screen İskeleti)

#### **Bug 3: Tüm Yorumlar Ekranı + Filtreler**

**Kök sebep:** `home_screen.dart`:
```dart
SectionHeader(
  title: 'Son Yorumlar',
  actionText: 'Tümünü Gör',
  // onAction: null — bağlı değil!
),
```

Buton var ama hiçbir şey yapmıyor + ayrıca kullanıcıdan üniversite ve tip filtresi istenmiş.

**Yaklaşım:** 
- Yeni screen: `all_reviews_screen.dart`
- Yeni provider: `allReviewsProvider` (filtreli)
- Route: `/all-reviews`
- Filtre state: Riverpod NotifierProvider

**Adım 1:** Filtre state'i için notifier oluştur.

`lib/features/reviews/presentation/providers/review_providers.dart` içine (Kişi A'nın helper'ının ALTINA ekle, aynı dosyada):

```dart
// ─── Sprint 3 Fix — Bug 3: Tüm Yorumlar Filtre State ───────────────

class AllReviewsFilterState {
  /// Seçili üniversite ID'si (null = hepsi)
  final String? universityId;
  /// Filtre tipi (null = hepsi, "university" veya "department")
  final ReviewType? reviewType;
  /// Sıralama
  final ReviewSort sort;

  const AllReviewsFilterState({
    this.universityId,
    this.reviewType,
    this.sort = ReviewSort.newest,
  });

  AllReviewsFilterState copyWith({
    String? universityId,
    bool clearUniversityId = false,
    ReviewType? reviewType,
    bool clearReviewType = false,
    ReviewSort? sort,
  }) {
    return AllReviewsFilterState(
      universityId: clearUniversityId ? null : (universityId ?? this.universityId),
      reviewType: clearReviewType ? null : (reviewType ?? this.reviewType),
      sort: sort ?? this.sort,
    );
  }

  int get activeFilterCount =>
      (universityId != null ? 1 : 0) + (reviewType != null ? 1 : 0);

  bool get hasFilters => universityId != null || reviewType != null;
}

class AllReviewsFilterNotifier extends Notifier<AllReviewsFilterState> {
  @override
  AllReviewsFilterState build() => const AllReviewsFilterState();

  void setUniversity(String? id) {
    state = state.copyWith(
      universityId: id,
      clearUniversityId: id == null,
    );
  }

  void setReviewType(ReviewType? type) {
    state = state.copyWith(
      reviewType: type,
      clearReviewType: type == null,
    );
  }

  void setSort(ReviewSort sort) {
    state = state.copyWith(sort: sort);
  }

  void clearAll() {
    state = const AllReviewsFilterState();
  }
}

final allReviewsFilterProvider =
    NotifierProvider<AllReviewsFilterNotifier, AllReviewsFilterState>(
  AllReviewsFilterNotifier.new,
);

/// Filtreli tüm yorumlar stream'i
final allFilteredReviewsProvider = StreamProvider<List<ReviewModel>>((ref) {
  final filter = ref.watch(allReviewsFilterProvider);
  final repo = ref.read(reviewRepositoryProvider);
  return repo.getAllReviews(
    universityId: filter.universityId,
    reviewType: filter.reviewType,
    orderBy: filter.sort == ReviewSort.newest ? 'createdAt' : 'likes',
    limit: 50, // ilk sayfada 50
  );
});
```

**Adım 2:** Repository'ye `getAllReviews` ekle.

`lib/features/reviews/data/review_repository.dart` içine:

```dart
/// Tüm yorumları filtrele ve stream olarak döndür.
/// Firestore index'i: isApproved (asc) + type (asc) + universityId (asc) + orderBy (desc)
Stream<List<ReviewModel>> getAllReviews({
  String? universityId,
  ReviewType? reviewType,
  int limit = 50,
  String orderBy = 'createdAt',
}) {
  Query<Map<String, dynamic>> query = _reviewsRef
      .where('isApproved', isEqualTo: true);

  if (reviewType != null) {
    query = query.where('type', isEqualTo: reviewType.name);
  }

  if (universityId != null) {
    query = query.where('universityId', isEqualTo: universityId);
  }

  query = query.orderBy(orderBy, descending: true).limit(limit);

  return query.snapshots().map((snapshot) => snapshot.docs
      .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
      .toList());
}
```

**Adım 3:** Firestore composite index ekle. `firestore.indexes.json`:

```json
{
  "collectionGroup": "reviews",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "isApproved", "order": "ASCENDING" },
    { "fieldPath": "type", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" },
    { "fieldPath": "__name__", "order": "DESCENDING" }
  ],
  "density": "SPARSE_ALL"
},
{
  "collectionGroup": "reviews",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "isApproved", "order": "ASCENDING" },
    { "fieldPath": "type", "order": "ASCENDING" },
    { "fieldPath": "universityId", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" },
    { "fieldPath": "__name__", "order": "DESCENDING" }
  ],
  "density": "SPARSE_ALL"
},
{
  "collectionGroup": "reviews",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "isApproved", "order": "ASCENDING" },
    { "fieldPath": "type", "order": "ASCENDING" },
    { "fieldPath": "likes", "order": "DESCENDING" },
    { "fieldPath": "__name__", "order": "DESCENDING" }
  ],
  "density": "SPARSE_ALL"
}
```

Deploy:
```bash
firebase deploy --only firestore:indexes
```

Index build 5-10 dakika sürer; arka planda çalışsın.

**Adım 4:** Ekran iskeletini yaz.

`lib/features/reviews/presentation/screens/all_reviews_screen.dart` (yeni dosya):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../domain/models/review_model.dart';
import '../providers/review_providers.dart';
import '../widgets/review_card.dart';

class AllReviewsScreen extends ConsumerWidget {
  const AllReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(allReviewsFilterProvider);
    final reviewsAsync = ref.watch(allFilteredReviewsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Tüm Yorumlar', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          Badge(
            isLabelVisible: filter.activeFilterCount > 0,
            label: Text('${filter.activeFilterCount}'),
            backgroundColor: AppColors.primary,
            offset: const Offset(-4, 4),
            child: IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => _showFilterSheet(context, ref),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildActiveFilterChips(ref, filter),
          Expanded(
            child: reviewsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text('Yorumlar yüklenemedi', style: AppTextStyles.titleMedium),
                      const SizedBox(height: 4),
                      Text('$e',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ),
              data: (reviews) {
                if (reviews.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.rate_review_outlined,
                    title: filter.hasFilters ? 'Bu filtreye uygun yorum yok' : 'Henüz yorum yok',
                    description: filter.hasFilters 
                        ? 'Farklı bir filtre deneyin veya tüm yorumları görün.'
                        : 'İlk yorumu yazan siz olun!',
                    actionText: filter.hasFilters ? 'Filtreleri Temizle' : null,
                    onAction: filter.hasFilters
                        ? () => ref.read(allReviewsFilterProvider.notifier).clearAll()
                        : null,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 100),
                  itemCount: reviews.length,
                  itemBuilder: (context, i) {
                    final review = reviews[i];
                    final currentUser = ref.watch(authStateProvider).value;
                    final isOwner = currentUser?.uid == review.userId;

                    return ReviewCard(
                      review: review,
                      showActions: isOwner,
                      showReportMenu: !isOwner,
                      onTap: () {
                        if (review.type == ReviewType.department) {
                          context.push('/department/${review.targetId}');
                        } else {
                          context.push('/university/${review.targetId}');
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChips(WidgetRef ref, AllReviewsFilterState filter) {
    if (!filter.hasFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (filter.reviewType != null)
            Chip(
              label: Text(
                filter.reviewType == ReviewType.university ? 'Üniversite' : 'Bölüm',
              ),
              onDeleted: () =>
                  ref.read(allReviewsFilterProvider.notifier).setReviewType(null),
              deleteIconColor: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              labelStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
            ),
          if (filter.universityId != null)
            Consumer(
              builder: (context, ref, _) {
                final uniAsync =
                    ref.watch(universityDetailProvider(filter.universityId!));
                return Chip(
                  label: Text(uniAsync.value?.name ?? 'Üniversite'),
                  onDeleted: () => ref
                      .read(allReviewsFilterProvider.notifier)
                      .setUniversity(null),
                  deleteIconColor: AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  labelStyle:
                      AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _FilterBottomSheet(),
    );
  }
}

// Filter bottom sheet — yarın (Gün 3) Kişi B tarafından doldurulacak
class _FilterBottomSheet extends ConsumerWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Gün 3'te doldurulacak
    return const Center(child: Text('Filtreler yarın gelecek'));
  }
}
```

**Adım 5:** Router'a ekle.

`lib/router/app_router.dart`:
```dart
// AppRoutes class'ına:
static const String allReviews = '/all-reviews';

// routes listesine (shell dışına):
GoRoute(
  path: AppRoutes.allReviews,
  builder: (context, state) => const AllReviewsScreen(),
),
```

**Adım 6:** Home screen'deki butonu bağla.

`lib/features/home/presentation/screens/home_screen.dart`:
```dart
SectionHeader(
  title: 'Son Yorumlar',
  actionText: 'Tümünü Gör',
  padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
  onAction: () => context.push('/all-reviews'), // YENİ
),
```

Bugün filter sheet'in içini yazmadık — yarın bitireceksin. Şu an için iskelet çalışmalı: empty state ve filtresiz liste gelmeli.

**Hızlı test:**
1. Ana sayfadan "Tümünü Gör" → tüm onaylı yorumlar listelenmeli ✅
2. Filter butonu görünüyor ama içi boş (yarın)

---

### 🌆 Akşam Sync (20dk)
- Kişi A: Pending banner + cache fix demo
- Kişi B: All reviews iskeleti demo
- **ÖNEMLI:** Firestore index deploy edildi mi? 10dk bekle, hala build oluyorsa not al, sabah kontrol et.

### ✅ Gün 2 Bitişinde Durum
- [x] Bug 1 çözüldü (pending banner)
- [x] Bug 4 çözüldü (cache fix)
- [x] Bug 3 iskelet hazır (filter sheet hariç)
- [x] Firestore indexes deploy edildi

---

## 📆 GÜN 3: Filter Sheet + Review Card Polish

> **Hedef:** Kişi B `_FilterBottomSheet`'i bitirecek ve AllReviewsScreen'i tamamlayacak. Kişi A ise A1-A8 arası polish yapıp optimization'a hazırlık yapacak.

### 🌅 Sabah Standup (10dk)
Firestore index'leri build oldu mu? `firebase firestore:indexes` ile listele, "READY" durumda olmalı.

---

### 🎨 Kişi B — Bug 3 Devam: Filter Bottom Sheet

`all_reviews_screen.dart` içindeki `_FilterBottomSheet` class'ını değiştir:

```dart
class _FilterBottomSheet extends ConsumerWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(allReviewsFilterProvider);
    final universitiesAsync = ref.watch(allUniversitiesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filtreler', style: AppTextStyles.titleLarge),
                  if (filter.hasFilters)
                    TextButton(
                      onPressed: () => ref
                          .read(allReviewsFilterProvider.notifier)
                          .clearAll(),
                      child: Text(
                        'Temizle',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(color: AppColors.borderLight, height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Tip Filtresi
                  Text('Yorum Tipi', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _TypeOption(
                        icon: Icons.school_rounded,
                        label: 'Üniversite',
                        isSelected: filter.reviewType == ReviewType.university,
                        onTap: () {
                          final current = filter.reviewType;
                          ref.read(allReviewsFilterProvider.notifier).setReviewType(
                                current == ReviewType.university
                                    ? null
                                    : ReviewType.university,
                              );
                        },
                      ),
                      const SizedBox(width: 10),
                      _TypeOption(
                        icon: Icons.menu_book_rounded,
                        label: 'Bölüm',
                        isSelected: filter.reviewType == ReviewType.department,
                        onTap: () {
                          final current = filter.reviewType;
                          ref.read(allReviewsFilterProvider.notifier).setReviewType(
                                current == ReviewType.department
                                    ? null
                                    : ReviewType.department,
                              );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sıralama
                  Text('Sıralama', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('En Yeni'),
                        selected: filter.sort == ReviewSort.newest,
                        onSelected: (v) {
                          if (v) {
                            ref.read(allReviewsFilterProvider.notifier)
                                .setSort(ReviewSort.newest);
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('En Beğenilen'),
                        selected: filter.sort == ReviewSort.mostLiked,
                        onSelected: (v) {
                          if (v) {
                            ref.read(allReviewsFilterProvider.notifier)
                                .setSort(ReviewSort.mostLiked);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Üniversite Filtresi
                  Text('Üniversite', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 12),
                  universitiesAsync.when(
                    data: (universities) {
                      return Column(
                        children: [
                          ...universities.map(
                            (uni) => RadioListTile<String?>(
                              value: uni.id,
                              groupValue: filter.universityId,
                              onChanged: (val) => ref
                                  .read(allReviewsFilterProvider.notifier)
                                  .setUniversity(val),
                              title: Text(
                                uni.name,
                                style: AppTextStyles.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${uni.type} • ${uni.reviewCount} yorum',
                                style: AppTextStyles.labelSmall,
                              ),
                              dense: true,
                              activeColor: AppColors.primary,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) =>
                        Text('Üniversiteler yüklenemedi', style: AppTextStyles.bodySmall),
                  ),
                ],
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                top: false,
                child: GradientButton(
                  text: 'Sonuçları Göster',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Test:**
1. Tümünü Gör → Filter butonu bas
2. Üniversite seç (mesela ODTÜ) → uygula → sadece ODTÜ yorumları
3. Tip değiştir: Sadece Bölüm → sadece ODTÜ bölüm yorumları
4. Temizle → hepsi geri geliyor ✅
5. En Beğenilen → like sayısına göre sıralı ✅
6. Boş sonuçta empty state + "Filtreleri Temizle" butonu ✅

---

### 🧑‍💻 Kişi A — Polish Round 1 (Gün 1-2 düzeltmeleri)

Dün akşam Kişi B demosunda muhtemelen gördün ki:
- Write ekranında başarı mesajı → profile dön → reviewCount hâlâ eski (eğer timing sıkıntısı varsa)
- Pending banner'ı bazı durumlarda boşlukta kalıyor (compact modda)

Bu kısım sabit bir iş listesi değil, dün bitirdiğin işlerin sonrası ortaya çıkan ufak düzenlemeler. Örnek kontrol listesi:

**Kontrol listesi:**
- [ ] Pending banner'ı `compact: true` modda da görünüyor mu? (Home ekranı son yorumlarda, kullanıcı kendi onaysız yorumunu görüyorsa göstermeli)
  ```dart
  // review_card.dart _buildComment vs.
  // compact mode'u banner'ı da etkilemesin:
  if (!review.isApproved && showActions) _buildPendingApprovalBanner(),
  // Bu zaten showActions'a bağlı, home'da showActions=false, sorun değil
  ```
- [ ] Cache fix tüm yerlerde uygulandı mı?
  - `my_reviews_screen.dart` ✅
  - `review_list.dart` ✅
  - `write_review_screen.dart` ✅
  - Başka delete noktası var mı? Grep at:
    ```bash
    grep -r "deleteReview" lib/
    ```
- [ ] Bug 7 testini farklı kullanıcı profilleri ile tekrar yap. Özellikle:
  - Misafir (null user)
  - edu.tr ama farklı üniversite
  - edu.tr, doğru üniversite, doğrulanmamış
  - edu.tr, doğru üniversite, doğrulanmış ✅

**Yeni: `currentUserProvider` TTL'ini 10 dakikadan 2 dakikaya düşür.** 10 dakika çok uzun:

`auth_repository.dart`:
```dart
static const _cacheTtl = Duration(minutes: 2); // 10'dan 2'ye
```

Bu, cache fix'in yardımcısı — kullanıcı bazı durumları manuel invalidate etmeyi unutursak 2 dakika sonra otomatik yenilenir.

---

### 🌆 Akşam Sync (20dk)

**Entegrasyon testi:** Develop'a merge sonrası tam turluk bir gezinme:

1. Yorum yaz → home → tümünü gör → filtreler çalışıyor mu?
2. Küfürlü yorum yaz → yorumlarım'da pending banner → düzenle → küfürsüz hale getir → yayınlandı mı?
3. Profile git → 5 yorum yaz → profile dön → reviewCount doğru mu?
4. Yorum sil → profile dön → reviewCount düştü mü?

### ✅ Gün 3 Bitişinde Durum
- [x] Bug 3 %100 tamam (filter sheet bitti)
- [x] Gün 1-2 polish turlama
- [x] Bug 1, 2, 3, 4, 6, 7, 8 hepsi tamam
- [x] Yarın: Bug 5 (optimizasyon), birlikte

---

## 📆 GÜN 4: Performans Optimizasyonu (BİRLİKTE)

> **Hedef:** Bug 5 — genel performans iyileştirmesi. Bugün pair-programming. İkiniz aynı ekranda, farklı dosyalar.

### 🌅 Sabah Standup (15dk)

Hangi telefon / emülatörde en çok kasıyor? Testle başla:
- Orta-düşük seviye bir gerçek telefon (4GB RAM) varsa kullan
- Yoksa emülatörün performansını düşür: Android Studio → Emulator → Settings → CPU cores 2, RAM 2048

Profiller kaydet:
```bash
flutter run --profile
```

DevTools'u aç, Performance tab'ı:
- Scroll hangi ekranda jank yapıyor?
- CPU timeline'da hangi build methodları uzun?

---

### 🎯 Optimizasyon Stratejisi (ortak karar)

Kod incelemesi yaptım, en çok jank nereden geliyor, liste:

1. **`flutter_animate` fazlası** — özellikle `favorites_screen.dart` ve `explore_screen.dart`'ta liste item'larına animasyon eklenmiş. Scroll sırasında her yeni görünen item yeniden animasyon yapmaya çalışıyor.
2. **`userLikedReviewsProvider`** — `collectionGroup('likes')` her ReviewCard rebuild'de yeniden hesaplanıyor gibi. `.select()` ile optimize edilmeli.
3. **`ReviewCard`** — her kart içinde `ref.watch(authStateProvider)`, `ref.watch(userLikedReviewsProvider)` vs var. Bunlar değiştiğinde **tüm listedeki** kartlar yeniden build ediliyor.
4. **`app_shell.dart` prefetch** — uygulama açılır açılmaz tüm üniversiteleri çekiyor. Home ekran render'ını geciktiriyor.
5. **`home_screen.dart`** — tek build'de 5+ `.animate().fadeIn(delay: X)` var. İlk açılışta CPU'yu yoruyor.
6. **Images** — `CachedNetworkImage` / `CachedNetworkImageProvider` için `memCacheHeight` / `memCacheWidth` set edilmiyor. Yüksek çözünürlüklü fotolar gereksiz RAM tüketiyor.

---

### 🧑‍💻 Kişi A — Optimizasyon Bloğu

#### **A-Opt-1: `write_review_screen` — Validation Hesaplamasını Cache'le**

`_isFormValid` ve `_validationErrors` her build'de hesaplanıyor. Büyük form'da bu maliyetli.

Hızlı fix yok — bu zaten setState'e bağlı, setState çağrıldığında hesaplanıyor. Ama `_categories`, `_presetPros`, `_presetCons` getter'ları her build'de yeniden oluşturuluyor, const haline getir:

```dart
// write_review_screen.dart - _WriteReviewScreenState içine:

// Getter yerine cached value:
late final List<String> _categories = widget.type == ReviewType.university
    ? AppConstants.uniRatingCategories
    : AppConstants.deptRatingCategories;

late final List<String> _presetPros = widget.type == ReviewType.university
    ? AppConstants.commonUniPros
    : AppConstants.commonDeptPros;

late final List<String> _presetCons = widget.type == ReviewType.university
    ? AppConstants.commonUniCons
    : AppConstants.commonDeptCons;
```

#### **A-Opt-2: `photo_upload_section` — Progress Listener Leak**

`_uploadReviewPhotos` metodunda `uploadTask.snapshotEvents.listen()` var ama dispose edilmiyor. Eğer kullanıcı ekranı kapatırsa listener açık kalır.

`write_review_screen.dart`:

```dart
// _WriteReviewScreenState içine:
StreamSubscription<TaskSnapshot>? _uploadSubscription;

@override
void dispose() {
  _uploadSubscription?.cancel();
  _commentController.dispose();
  super.dispose();
}

// _uploadReviewPhotos içinde listen'i sakla:
_uploadSubscription?.cancel();
_uploadSubscription = uploadTask.snapshotEvents.listen((event) {
  if (mounted) {
    final fileProgress = event.bytesTransferred / event.totalBytes;
    setState(() {
      _uploadProgress = (i + fileProgress) / photos.length;
    });
  }
});

await uploadTask;
await _uploadSubscription?.cancel();
_uploadSubscription = null;
```

#### **A-Opt-3: `auth_repository` — getUserProfile Her Seferinde Server'a Gidiyor**

```dart
final doc = await _firestore.collection('users').doc(uid).get(
  GetOptions(source: forceRefresh ? Source.serverAndCache : Source.serverAndCache),
);
```

`forceRefresh=false` bile `serverAndCache` — yani her zaman server'a gidiyor. Değiştir:

```dart
final doc = await _firestore.collection('users').doc(uid).get(
  GetOptions(
    source: forceRefresh ? Source.server : Source.cache,
  ),
);

// Eğer cache boşsa Source.cache exception fırlatır — yakala:
```

Ama bu çok agresif, belki en iyisi varsayılan `Source.serverAndCache` tutup zaman aşımı ile kontrol:

```dart
Future<UserModel?> getUserProfile(String uid, {bool forceRefresh = false}) async {
  // Memory cache kontrol
  if (!forceRefresh &&
      _cachedUser != null &&
      _cachedUser!.uid == uid &&
      _lastCacheTime != null &&
      DateTime.now().difference(_lastCacheTime!) < _cacheTtl) {
    return _cachedUser;
  }

  // Server/cache sorgu
  final doc = await _firestore.collection('users').doc(uid).get();
  // Firestore SDK zaten offline persistence ile cache yönetir
  
  if (!doc.exists || doc.data() == null) return null;

  _cachedUser = UserModel.fromMap(doc.data()!, uid);
  _lastCacheTime = DateTime.now();
  return _cachedUser;
}
```

Yani explicit `Source` belirtme, Firestore SDK default davranışına güven.

#### **A-Opt-4: App Startup — Prefetch'i Defer Et**

`app_shell.dart`'taki prefetch tüm üniversiteleri çekiyor. Home ekranı render'ını bloklamıyor ama network/CPU kullanıyor. 2 saniye gecikme ver:

```dart
// app_shell.dart initState:
WidgetsBinding.instance.addPostFrameCallback((_) {
  _checkVerification();
  
  // Veriyi home render'dan sonra prefetch et
  Future.delayed(const Duration(seconds: 2), () {
    if (!mounted) return;
    ref.read(allUniversitiesProvider);
    ref.read(citiesProvider);
  });
});
```

---

### 🎨 Kişi B — Optimizasyon Bloğu

#### **B-Opt-1: `review_card` — Provider Watch'ları Daraltma**

Mevcutta `LikeButton` içinde:
```dart
final likedIds = ref.watch(userLikedReviewsProvider).value ?? {};
```

Bu, Set'in tamamını izliyor. Set'e bir item ekleyince **tüm** LikeButton'lar yeniden build ediliyor — 50 yorumluk listede 50 rebuild.

Fix: `.select()` ile sadece ilgili review'un durumunu izle:

`lib/features/reviews/presentation/widgets/like_button.dart`:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final user = ref.watch(authStateProvider).value;

  // YENİ: Sadece bu review için like durumunu izle
  final isLikedFromServer = ref.watch(
    userLikedReviewsProvider.select(
      (async) => async.value?.contains(review.id) ?? false,
    ),
  );

  // YENİ: Sadece bu review için pending durumu
  final pending = ref.watch(
    likeControllerProvider.select((m) => m[review.id]),
  );

  final isLiked = pending ?? isLikedFromServer;

  // ... mevcut UI
}
```

Bu tek değişiklik ciddi fark yaratır — 50 yorumluk liste artık 1 rebuild/like.

#### **B-Opt-2: `favorites_screen` — Liste Animasyonlarını Kaldır**

```dart
return UniCard(...).animate().fadeIn(
  delay: Duration(milliseconds: 50 * index.clamp(0, 10)),
  duration: 300.ms,
);
```

Bu, scroll'da jank yaratıyor. Kaldır:

```dart
return UniCard(
  title: uni.name,
  // ... mevcut
);
// .animate()... SİLİNDİ
```

Gerekirse sadece ilk 3 item'a:
```dart
final card = UniCard(...);
if (index < 3) {
  return card.animate().fadeIn(duration: 300.ms);
}
return card;
```

#### **B-Opt-3: `home_screen` — Çoklu Animate Zincirini Azalt**

`home_screen.dart`'ta 6+ `.animate().fadeIn(delay: X)` var. İlk açılışta görsel ama CPU'ya yük.

Option 1: Hepsini tek `AnimationLimiter` + `AnimatedContainer` ile değiştir (karmaşık)

Option 2 (önerilen): Sadece en görünür 2 bölgenin animasyonunu bırak (Header + Hero), diğerlerini kaldır:

```dart
// Kalsın:
).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0), // Header
).animate().fadeIn(delay: 200.ms, duration: 500.ms).scale(begin: const Offset(0.95, 0.95)), // Hero

// Kaldır: Search bar, Popular, Cities, Reviews section animasyonları
// Bu bölümler zaten içerik yüklendikçe zaten görsel geçiş oluyor
```

#### **B-Opt-4: Cached Network Image — Memory Cache Sınırla**

`lib/core/widgets/uni_card.dart` `_buildImage` metodunda:

```dart
child: imageUrl != null
    ? DecorationImage(
        image: CachedNetworkImageProvider(imageUrl!),  // Max boyut yok
        fit: BoxFit.cover,
      )
    : null,
```

Avatar için 64px yeterli ama tam çözünürlüklü foto yükleniyor:

```dart
// Container yerine doğrudan CachedNetworkImage kullan:
if (imageUrl != null)
  ClipRRect(
    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
    child: CachedNetworkImage(
      imageUrl: imageUrl!,
      width: 64,
      height: 64,
      fit: BoxFit.cover,
      memCacheWidth: 128, // 2x piksel yoğunluğu
      memCacheHeight: 128,
      placeholder: (_, __) => Container(
        color: AppColors.surfaceVariant,
      ),
      errorWidget: (_, __, ___) => const Icon(
        Icons.school_rounded,
        color: AppColors.textTertiary,
        size: 28,
      ),
    ),
  )
else
  Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      color: AppColors.surfaceVariant,
    ),
    child: const Icon(
      Icons.school_rounded,
      color: AppColors.textTertiary,
      size: 28,
    ),
  ),
```

Aynı değişikliği `review_card.dart` `_buildPhotoGrid` için de yap:
```dart
CachedNetworkImage(
  imageUrl: url,
  width: 80,
  height: 80,
  fit: BoxFit.cover,
  memCacheWidth: 160,
  memCacheHeight: 160,
  placeholder: ...
  errorWidget: ...
)
```

Ve `profile_screen.dart` avatarları için — 64 boyutta göster, cache'le:
```dart
memCacheWidth: 128,
memCacheHeight: 128,
```

#### **B-Opt-5: `explore_screen` — Filter Hesabını Memoize**

Şu an `_applyFilters` her build'de çalışıyor. Çok büyük değil ama daha iyisi yapılabilir:

```dart
// _ExploreScreenState class'ına:
List<UniversityModel>? _cachedFilteredList;
ExploreFilterState? _lastFilter;
List<UniversityModel>? _lastInput;

List<UniversityModel> _applyFilters(
    List<UniversityModel> universities, ExploreFilterState filters) {
  // Memo check
  if (_cachedFilteredList != null &&
      _lastFilter == filters &&
      identical(_lastInput, universities)) {
    return _cachedFilteredList!;
  }

  var filtered = universities;
  if (filters.selectedCities.isNotEmpty) {
    filtered = filtered.where((uni) => filters.selectedCities.contains(uni.cityId)).toList();
  }
  if (filters.selectedTypes.isNotEmpty) {
    filtered = filtered.where((uni) => filters.selectedTypes.contains(uni.type)).toList();
  }

  _cachedFilteredList = filtered;
  _lastFilter = filters;
  _lastInput = universities;
  return filtered;
}
```

Not: `ExploreFilterState`'in `operator ==` implementasyonu yok, `equatable` kullansan daha iyi olur ama şimdilik referans eşitliği yeter.

---

### 🌆 Akşam Sync (30dk)

**Performans Demo:**
1. Uygulamayı kapat, tekrar aç
2. Home ekranı ne kadar sürede yükleniyor?
3. Home'da scroll → jank var mı?
4. Keşfet'e git, hızlı scroll yap → smooth mu?
5. Favoriler'de 10+ favori ile scroll → smooth mu?
6. Bir üniversite detayına git, aşağı scroll → jank var mı?
7. Bir yorumu beğen, hızlı unbeğen/beğen yap → gecikme var mı?

Öncesi vs sonrası için kısa video çek.

**Merge:**
```bash
# Her iki branch → develop
```

### ✅ Gün 4 Bitişinde Durum
- [x] Bug 5 optimizasyonu yapıldı
- [x] Image cache'leri sınırlı
- [x] Gereksiz animasyonlar kaldırıldı
- [x] Provider watch'lar daraltıldı
- [x] Startup optimize edildi

---

## 📆 GÜN 5: Regresyon Testi + Release

> **Hedef:** Tüm düzeltmelerin birlikte çalıştığını doğrula, release et.

### 🌅 Sabah (BİRLİKTE)

#### **Tam Regresyon Testi (2 saat)**

İki cihaz kullanın, iki farklı hesapla login olun. Sistematik test edin.

**Set 1: Bug'lar**
- [ ] B1: Küfürlü yorum yaz → yorumlarım'da "Yayınlanmadı" banner görünüyor
- [ ] B1: Yorumlarım üstünde "X yorumun yayınlanmadı" uyarısı
- [ ] B2: Ana sayfada bölüm yorumuna tıkla → bölüm sayfası açılıyor (üni hatası yok)
- [ ] B2: Ana sayfada üni yorumuna tıkla → üni sayfası açılıyor
- [ ] B3: Tümünü Gör → tüm yorumlar → üni filtresi çalışıyor
- [ ] B3: Tüm Yorumlar → tip filtresi çalışıyor (sadece bölüm / sadece üni)
- [ ] B3: Sıralama değişimi etki ediyor
- [ ] B3: Boş sonuç → empty state + Temizle butonu
- [ ] B4: Yorum sil → profile dön → reviewCount anında düştü
- [ ] B4: Yorum ekle → profile dön → reviewCount anında arttı
- [ ] B5: 30+ yorumluk liste scroll → smooth (jank yok)
- [ ] B5: Uygulama cold start ≤ 3 sn
- [ ] B6: Beyaz fotolu galeri → geri tuş + sayı görünür
- [ ] B7: Başka üninin üni/bölüm sayfasında "Değerlendir" görünmüyor (tooltip icon var)
- [ ] B7: Kendi üninde "Değerlendir" görünüyor
- [ ] B7: Giriş yapmamış → "Giriş Yap" butonu
- [ ] B7: edu.tr doğrulamamış → "Doğrulama gerekli" tooltip
- [ ] B8: Galeriden 3+ foto aynı anda seç → 3'ü ekleniyor, uyarı alıyor

**Set 2: Entegrasyon / Regresyon (Sprint 3'ten gelen özellikler bozulmamış)**
- [ ] Kayıt ol → edu.tr → doğrulama maili geldi mi?
- [ ] Onboarding sırası → login'e geçiş
- [ ] Google ile giriş çalışıyor
- [ ] Üniversite keşfet + filtre + arama
- [ ] Şehir listesi → tek şehir
- [ ] Bölüm detay + yorum yaz
- [ ] Yorum düzenle → kaydet → değişiklik yansıdı
- [ ] Beğen → anında güncellendi
- [ ] Şikayet et → tekrar şikayet edemiyorum
- [ ] Profil fotoğrafı güncelle
- [ ] Favorilere ekle/çıkar
- [ ] Çıkış yap → auth guard'lı sayfalar login'e yönlendiriyor

**Bulunan her bug → immediate fix (hemen düzelt, ertelemeyiz).**

---

### 🌞 Öğlen 13:00 — 15:00 — Son Polish

Sabah testinde muhtemelen ufak şeyler çıkacak:
- Belki pending banner'ı rengi başka şeyle çakışıyor
- Belki filter bottom sheet'te üniversite listesi uzunsa scroll sorunu var
- Belki optimizasyondan sonra bir yerde UI bozulmuş

Kişi A kendi alanına, Kişi B kendi alanına bakar. 2 saat polish.

---

### 🌆 Öğleden Sonra 15:00 — 16:30 — Release

#### **Merge & Tag**

```bash
# Her iki branch develop'a merge edildi, son kontrol:
git checkout develop
git pull

# Lint kontrolü
flutter analyze
# 0 warning, 0 error olmalı

# Test çalıştır (eğer test varsa)
flutter test

# main'e merge
git checkout main
git merge develop
git push origin main

# Tag
git tag -a v0.3.1 -m "Sprint 3 hotfix: 8 critical bug fixes + optimization"
git push origin v0.3.1

# Branch temizlik
git branch -d fix/sprint3-state-flow
git branch -d fix/sprint3-ui-nav
git push origin --delete fix/sprint3-state-flow
git push origin --delete fix/sprint3-ui-nav
```

#### **README Güncelle**

```markdown
### v0.3.1 (Sprint 3 Hotfix) — 2026-MM-DD
**Hata Düzeltmeleri:**
- 🐛 Yayınlanmamış yorumlar "Yorumlarım"da açıkça belirtiliyor
- 🐛 Bölüm yorumlarına tıklayınca "Üniversite bulunamadı" hatası giderildi
- 🐛 Yorum silindiğinde profil yorum sayacı anında güncelleniyor
- 🐛 Photo gallery'de beyaz fotoğrafta AppBar ikonları görünür
- 🐛 Başka üniversiteye ait sayfalarda "Değerlendir" butonu gizlendi
- 🐛 Galeriden aynı anda birden fazla fotoğraf seçilebilir (max 3)

**Yeni Özellikler:**
- ✨ "Tüm Yorumlar" ekranı (ana sayfadan "Tümünü Gör" ile)
- ✨ Yorumlarda üniversite ve tip filtresi
- ✨ Başlıkta aktif filtre göstergesi

**Performans İyileştirmeleri:**
- ⚡ Yorum listesi scroll performansı iyileştirildi
- ⚡ Image cache optimize edildi (daha az RAM kullanımı)
- ⚡ Like butonunda provider optimizasyonu (daha az rebuild)
- ⚡ Startup sırasında prefetch ertelendi (daha hızlı ilk render)
```

#### **Commit İstatistikleri**

```bash
git log --oneline v0.3.0..v0.3.1 | wc -l
git log v0.3.0..v0.3.1 --shortstat --pretty=format: | grep -v '^$' | awk '{files+=$1; ins+=$4; del+=$6} END {print "Files:", files, "Insertions:", ins, "Deletions:", del}'
```

Bu rakamları retrospektifte kullanacaksın.

---

### 🎉 Retrospektif (45dk)

**1. Ne başardık? (10dk)**
8 bug, her biri için kök sebep → fix → test turu yaptık. Listele:
- Kaç dosya değişti
- Kaç satır eklendi / silindi
- En zorlu bug hangisiydi

**2. Neyi iyi yaptık? (10dk)**
- Görev dağılımı çakışmaları minimize etti
- Sabah standup + akşam sync ritimi çalıştı
- Her bug için önce kök sebep analizi yaptık, sonra fix yazdık

**3. Ne zorlandı? (10dk)**
- Hangi bug beklenenden uzun sürdü?
- Hangi fix başka bir bug'a yol açtı?
- Cache invalidation'da ne öğrendik?

**4. Sprint 4'e geçerken nelere dikkat? (15dk)**
- Performans artık kontrollü — yeni özelliklerde regression olmasın
- Yazılım sözleşmeleri (örn. ReviewCard API) Sprint 3'ten kalıyor — bunlar baza
- Sprint 4 scope'u: Mekanlar (kafe, yurt, çalışma alanı) + Karşılaştırma
- Yorum yapısı bu özelliklere uyarlanabilir mi? Mekan yorumları için `ReviewType.place` eklenebilir

---

### ✅ Gün 5 Bitişinde Durum
- [x] `v0.3.1` production'da
- [x] 8 bug hepsi kapalı
- [x] Performans iyileştirmeleri canlı
- [x] README güncel
- [x] Git tag'i atıldı
- [x] Sprint 4'e hazırız

---

## 🚨 Acil Durum Planı — Olası Takılmalar

Sprint sırasında takılabilecek yerler:

### **Firestore Composite Index Build Olmadı**
- Index 10-30dk sürebilir; 30dk geçtiyse Firebase Console'a bak. Manual olarak state'i kontrol et.
- Eğer `FAILED` ise index definition'ı hatalı. JSON'u dikkatlice tekrar kontrol et.
- Geçici çözüm: `getAllReviews` metodunda bu filtreyi client-side yap (50 yorum için acceptable).

### **`pickMultiImage` çalışmıyor**
- `image_picker` versiyonunu kontrol et. `pubspec.yaml` → `^1.0.0` altındaysa upgrade et.
- iOS'ta Info.plist'te `NSPhotoLibraryUsageDescription` ekli mi?
- Android'de `READ_MEDIA_IMAGES` izni (Android 13+) manifest'te mi?

### **Cache Clear Çalışmıyor**
- `invalidateUserProfileAfterReviewChange` çağrısı doğru yerde mi?
- `clearCache()` metodunun içinde `_cachedUser = null` ve `_lastCacheTime = null` ikisi de var mı?
- Firestore SDK'nın kendi cache'i var — gerekirse `get(GetOptions(source: Source.server))` ile zorla.

### **All Reviews Ekranında "The query requires an index" Hatası**
- Firebase console'a git, error mesajındaki linke tıkla, otomatik index oluştur.
- Veya manuel olarak `firestore.indexes.json`'a ekle + deploy.

### **Optimizasyon Sonrası UI Kırıldı**
- Provider `.select()` kullanımında null safety bozulmuş olabilir. Her `.select` çağrısının dönüş tipini kontrol et.
- Animasyon kaldırınca layout shift olabilir. Önceki boyutları `SizedBox` ile sabitle.

---

## 📌 Son Notlar

### **Birlikte Çalışma İpucu**
Sprint 3'te pair programming günleri vardı. Burada da Gün 4 birlikte. Ama "birlikte" illa aynı fiziksel mekan değil — ekran paylaşımıyla iyi çalışır.

### **Dokümantasyon**
Her fix'in commit mesajına issue numarası koy:
```bash
git commit -m "fix(home): navigate to department on dept review tap (#12)"
```
Böylece sonradan "hangi commit hangi bug'ı çözdü" geriye dönük takip edilebilir.

### **Test Tarzı**
Sprint 4'e geçmeden **unit test** ve **widget test** yazmaya başlamayı düşün. Bug'lar sürekli değişen kodda kaçınılmaz — test edilmemiş kod her yeni özellikte regression riski taşır. Bu sprintte yazmadınız ama Sprint 4'te en azından en kritik fonksiyonlar için (cache invalidation helper, filter state) unit test yazmak iyi olur.

### **Sonraki Sprint**
`implementation_planv1.md`'ye dön. Sprint 4 kapsamı: Mekanlar + Karşılaştırma. Yorum sistemi artık sağlam temel, bu temelin üstüne inşa edilecek.

---

Başarılar! 🚀

*Bu plan sprint3_gunluk_program.md üzerine inşa edildi. Sorular için Sprint 3 planı ve sprint2_hardening_review.md'ye bakabilirsin.*
