# Sprint 5: Polish & Yayın Planı (UniSeç v1.0)

> **Sprint hedefi:** Uygulamayı Play Store'da yayına hazırlamak. Mevcut özellik
> setini bitirmek, tutarlı bir UI'a kavuşturmak, performans ve a11y
> iyileştirmeleri yapmak, internal/closed beta turlarını geçmek ve **production
> release** çıkmak.
>
> **Süre:** 21 gün (3 hafta) — başlangıç tarihi takıma bağlı.
> **Takım:** 2 kişi (Kişi A + Kişi B).
> **Çıktı:** Play Store'da yayında, sürüm `1.0.0+1`.

---

## İçindekiler

1. [Genel Bakış](#1-genel-bakış)
2. [Definition of Done (v1.0)](#2-definition-of-done-v10)
3. [Takım, Roller, İletişim](#3-takım-roller-iletişim)
4. [Dosya & Dizin Sahipliği (Conflict Önleme)](#4-dosya--dizin-sahipliği-conflict-önleme)
5. [Branching Stratejisi ve PR Akışı](#5-branching-stratejisi-ve-pr-akışı)
6. [Tasarım Sistemi Sözleşmesi](#6-tasarım-sistemi-sözleşmesi)
7. [Gün Gün Plan (1-21)](#7-gün-gün-plan-1-21)
8. [UI Tutarlılığı Düzeltme Programı](#8-ui-tutarlılığı-düzeltme-programı)
9. [Performans Optimizasyon Programı](#9-performans-optimizasyon-programı)
10. [Test Planı](#10-test-planı)
11. [Play Store Hazırlık Checklist'i](#11-play-store-hazırlık-checklisti)
12. [Yayın Günü Runbook'u](#12-yayın-günü-runbooku)
13. [Post-Launch İzleme ve Destek (İlk 14 Gün)](#13-post-launch-i̇zleme-ve-destek)
14. [Öneriler ve İyileştirmeler (v1.1 Backlog)](#14-öneriler-ve-i̇yileştirmeler-v11-backlog)
15. [Risk Matrisi ve Önlemler](#15-risk-matrisi-ve-önlemler)
16. [Ek A: PR Template](#ek-a-pr-template)
17. [Ek B: Commit Konvansiyonu](#ek-b-commit-konvansiyonu)
18. [Ek C: Play Console Store Listing Metinleri](#ek-c-play-console-store-listing-metinleri)
19. [Ek D: Komut Cheat Sheet](#ek-d-komut-cheat-sheet)

---

## 1. Genel Bakış

UniSeç MVP'sinin son sprint'idir. Önceki sprint'lerde tüm büyük özellikler
(auth, üniversite/bölüm verisi, yorum sistemi, karşılaştırma, mekanlar,
favori, monetization) inşa edildi. Sprint 4.5'te karşılaştırma notları ve
3-way karşılaştırma üzerinde çalışıldı — bu özellikler v1.0'a dahil edilecek.

### Sayılarla durum (Sprint 5 başlangıcı)

| Metrik | Değer |
|--------|-------|
| Tamamlanan büyük özellik | 14 |
| Dosya sayısı (`lib/`) | ~280 |
| Test dosyası | 3 (yetersiz, sprint sonuna ~10 olacak) |
| Hardcoded hex color (theme dışı) | 35+ |
| Hardcoded TR string | ~127 |
| Bare error state (retry yok) | 14 |
| Bare CircularProgressIndicator | 8 |
| ListView eager render (`.builder` yok) | 13 |
| Uncommitted modification | 11 dosya |
| Untracked feature dosyası | 9 dosya |
| **Ana branch (`feat/sprint4.5-osym-data`) açık merge conflict** | 1 (`comparison_uni_picker.dart`) |
| Play Store release signing | DEBUG (kritik bloker) |
| Store listing assets | Yok |

### Yayın hedefi

- **Hafta 3 sonu (Gün 21):** Production release `%20 staged rollout`.
- **Gün 22-23:** Rollout %50 → %100.
- **Sürüm:** `1.0.0+1` (versionName 1.0.0, versionCode 1).
- **Track:** Google Play, Türkiye + global.
- **Bölge önceliği:** Türkiye (TR locale).

---

## 2. Definition of Done (v1.0)

Aşağıdakilerin hepsi karşılanmadan production release çıkmaz:

### Özellik tamamlığı
- [ ] Karşılaştırma notları (Pro) → açma/kaydetme/silme/listeleme + Firestore rules deploy edilmiş
- [ ] 3-way karşılaştırma (Pro) → A/B/C üniversite, paywall gate'i çalışıyor, sonuç ekranı stabil
- [ ] Tüm Sprint 1-4 özellikleri manuel E2E checklist'inde "PASS"
- [ ] Tüm Pro feature gate'leri doğru çalışıyor (free user paywall görüyor, Pro user erişiyor)

### Kalite
- [ ] `flutter analyze` 0 issue
- [ ] `flutter test` tüm testler geçiyor
- [ ] Hardcoded hex color sayısı (theme dışı) < 5 (sadece intentional brand renkleri)
- [ ] Bare error state sayısı = 0 (hepsi `ErrorState` widget + retry)
- [ ] Bare `CircularProgressIndicator` sayısı = 0 (uzun async = skeleton)
- [ ] Dark mode her ekranda doğru render ediyor (manuel test)
- [ ] L10n: kalan hardcoded string sayısı < 30 (kritik path'ler 100% l10n)

### Performans
- [ ] Eager `ListView(children: ...)` patern sayısı = 0
- [ ] `Image.network` doğrudan kullanım = 0 (hepsi `cached_network_image`)
- [ ] APK/AAB boyutu < 35 MB
- [ ] Soğuk başlatma < 3 saniye (release build, orta seviye Android)
- [ ] Karşılaştırma sonuç ekranı build süresi < 16ms (60fps korunuyor)

### Release
- [ ] Release signing config gerçek keystore ile yapılmış
- [ ] `key.properties` ve `upload.jks` gitignore'da, repo'ya commit edilmemiş
- [ ] Adaptive icon (`mipmap-anydpi-v26/ic_launcher.xml`) oluşturulmuş
- [ ] `main.dart`'ta global Crashlytics handler (`FlutterError.onError` +
      `PlatformDispatcher.instance.onError`) entegre
- [ ] ProGuard kuralları RevenueCat dahil
- [ ] Play Console Store listing tamamlanmış (TR + EN)
- [ ] Feature graphic (1024×500) + en az 4 ekran görüntüsü yüklenmiş
- [ ] Data safety form doldurulmuş
- [ ] Privacy policy URL erişilebilir
- [ ] Internal testing track'inde 2+ takım üyesi onayı
- [ ] Closed beta'da en az 5 test kullanıcısı + kritik crash yok

---

## 3. Takım, Roller, İletişim

### Kişi A — UI / Polish / Product
**Ana sorumluluklar:**
- UI tutarlılığı, dark mode kapsama, a11y
- L10n tamamlama
- Auth/Home/Profile/Places/University polish
- Tasarım sistemi enforcement (`AppColors`, `AppTextStyles`)
- Store assets (feature graphic, screenshot, açıklama metinleri)
- Privacy policy / Data Safety form içerik hazırlığı

### Kişi B — Logic / Release / Monetization
**Ana sorumluluklar:**
- Sprint 4.5 in-flight feature finalizasyonu (notes, 3-way)
- Comparison/Monetization/Reviews/Recommendation feature'larda bug fix
- Service layer (RevenueCat, Analytics, AI, Ad)
- Android signing, ProGuard, manifest
- Firestore rules + Cloud Functions
- Crashlytics global handler
- Beta tester koordinasyonu
- Production rollout

### İletişim ritmi
- **Sabah standup (15 dk):** Bugün ne yapacaksın? Engel var mı?
- **Öğle sync (10 dk):** Açık PR durumu, conflict riski, paylaşılan dosya
  dokunma planı
- **Akşam wrap-up (10 dk):** Bugün ne mergelendi? Yarın hangi PR'lar açık
  kalacak? `flutter analyze` sonucu temiz mi?

### Karar kuralları
- Tek başına karar verilemiyorsa (örn. paywall layout değişikliği) →
  sabah standup'ta tartış.
- Acil bir bug için ownership dışına çıkmak gerekirse → ilgili kişiye Slack
  veya WhatsApp ile haber ver, sonra PR aç.
- Code review zorunlu: A→B veya B→A. Self-merge sadece "hotfix" prefix'li
  PR'larda (örn. Crashlytics critical error fix).

---

## 4. Dosya & Dizin Sahipliği (Conflict Önleme)

Bu matris, aynı dosyaya aynı gün iki kişinin dokunmasını engelleyerek
merge conflict riskini düşürür. Sprint boyunca **kesinlikle** uyulacak.

### Kişi A'nın owner olduğu dizinler

```
lib/features/auth/
lib/features/home/
lib/features/profile/
lib/features/places/
lib/features/university/
lib/features/favorites/
lib/features/notifications/
lib/features/preference_lists/
lib/core/theme/app_colors.dart
lib/core/theme/app_text_styles.dart
lib/core/widgets/
play_store_assets/          (yeni, A oluşturur)
docs/screenshots/           (yeni, A oluşturur)
```

### Kişi B'nin owner olduğu dizinler

```
lib/features/comparison/
lib/features/monetization/
lib/features/reviews/
lib/features/recommendation/
lib/features/search/
lib/services/
lib/main.dart
lib/router/app_router.dart
android/                    (tüm dizin)
ios/                        (v1.1 için, dokunma)
firestore.rules
firestore.indexes.json
cloud_functions/
pubspec.yaml
pubspec.lock                (B mergeler)
```

### Paylaşılan dosyalar (günlük tek-touch kuralı)

| Dosya | Kural |
|-------|-------|
| `lib/l10n/app_tr.arb` | A günü A dokunur, B günü B. Day-end sync'te merge |
| `lib/l10n/app_en.arb` | Aynı |
| `lib/core/theme/app_theme.dart` | A owner, B sadece talep ederse |
| `README.md` | İkili sync ile günceller (sprint sonu) |
| `.gitignore` | Kim eklerse o günceller, ufak dosya conflict olmaz |

### "Hot zone" — Dokunulmayacak dosyalar (sprint boyunca donmuş)

```
lib/features/auth/data/auth_repository.dart
lib/features/university/data/university_repository.dart
lib/features/places/data/place_repository.dart   (TODO hariç)
lib/services/revenuecat_service.dart             (sadece API key fix - B)
```

Bu dosyalar production'da test edilmiş ve güvenlidir. Bug bulunmadıkça refactor edilmez.

### Çakışma senaryosu protokolü

İki kişi farkında olmadan aynı dosyayı değiştirdiyse:
1. PR açan ikinci kişi `git fetch && git rebase origin/develop` yapar.
2. Conflict varsa Slack'te ilk kişiye haber verir.
3. Hangi tarafın değişikliği prevail edecekse onu manuel mergeler, "fix:
   resolve conflict with <feature>" commit'i atar.
4. Sprint 5'te `git merge` yerine **`git rebase`** tercih edilir (lineer
   history daha temiz).

---

## 5. Branching Stratejisi ve PR Akışı

### Branch hiyerarşisi

```
main                                  ← production (korumalı, sadece tag'li)
  └── develop                         ← integration, sprint'in resmi hattı
        ├── feature/s5-<scope>-<desc> ← her görev için yeni branch
        ├── fix/s5-<scope>-<desc>     ← bug fix
        └── chore/s5-<scope>-<desc>   ← konfig, dokümantasyon, refactor
```

### Branch isimlendirme örnekleri

```
feature/s5-comparison-notes-finalize
feature/s5-places-dark-mode
feature/s5-paywall-yearly-default
fix/s5-comparison-uni-picker-merge-conflict
chore/s5-android-release-signing
chore/s5-l10n-profile-extraction
```

### PR akışı

1. Görev başlamadan `git checkout develop && git pull && git checkout -b <branch>`.
2. Küçük commit'ler at, anlamlı mesajlar yaz (bkz: [Ek B](#ek-b-commit-konvansiyonu)).
3. PR'ı `develop`'e aç. Şablonu doldur (bkz: [Ek A](#ek-a-pr-template)).
4. Karşı taraftan review iste.
5. `flutter analyze` ve `flutter test` lokalde geçtiğini PR description'a yaz.
6. Onaydan sonra **squash merge** veya **rebase merge** (preferred).
7. Branch otomatik silinsin (GitHub setting).

### PR boyut kuralları
- **İdeal:** 1 feature alanı, max 10 dosya, max 400 satır değişiklik.
- **Eğer 600+ satır olursa:** Daha küçük PR'lara böl.
- **İstisna:** Otomatik refactor (örn. tüm `padding: 6` → `padding: 8`) tek PR'da olabilir, ama önceden duyur.

### Release branch

Gün 17'de `release/v1.0.0` branch'i `develop`'ten ayrılır. Bundan sonra
sadece beta-fix commit'leri release branch'e gider. Yeni feature ya da
büyük refactor `develop`'te bekler (v1.1 backlog).

```
git checkout develop
git pull
git checkout -b release/v1.0.0
git push -u origin release/v1.0.0
```

Production release sonrası:
```
git checkout main
git merge --no-ff release/v1.0.0
git tag -a v1.0.0 -m "v1.0.0 - First production release"
git push origin main --tags

git checkout develop
git merge --no-ff release/v1.0.0    # backport bug fix'leri
```

---

## 6. Tasarım Sistemi Sözleşmesi

Bu kurallar Sprint 5'in **yasası**dır. PR review'da bu kurallara aykırı kod
mergelenmez.

### 6.1 Renk kullanımı

```dart
// ✅ İZİNLİ
AppColors.primary
AppColors.tierPro
AppColors.textPrimary.withValues(alpha: 0.6)
Theme.of(context).colorScheme.surface
Colors.transparent
Colors.white         // Sadece gradient overlay veya icon foreground
Colors.black         // Sadece overlay (Scrim) veya icon foreground

// ❌ YASAK
const Color(0xFFE3F2FD)
Color(0xFF1B5E20)
const Color.fromARGB(255, 12, 34, 56)
```

**İstisnalar (tek tek belgelendirilecek):**
- `dorm_room_floor_plan.dart` — Oda tipi renk kodlaması semantik olduğu için
  hardcoded kalabilir ama `class DormRoomColors` içine taşınmalı (PR ile).
- Brand renkleri (Apple/Google login butonu) — provider'ın resmi rengi.

### 6.2 Text style

```dart
// ✅ İZİNLİ
AppTextStyles.titleLarge
AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)
Theme.of(context).textTheme.headlineSmall

// ❌ YASAK
TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
const TextStyle(fontFamily: 'Inter', fontSize: 14)
```

### 6.3 Spacing scale

İzinli değerler: `4, 8, 12, 16, 20, 24, 32, 40, 48, 64`.

```dart
// ✅
EdgeInsets.all(16)
EdgeInsets.symmetric(horizontal: 20, vertical: 12)
SizedBox(height: 24)

// ❌
EdgeInsets.all(13)            // 12 veya 16 seç
EdgeInsets.symmetric(vertical: 14)  // 12 veya 16 seç
SizedBox(height: 17)
```

### 6.4 Border radius scale

İzinli değerler: `4, 8, 12, 16, 20, 24, 28, 32` (özel: pill button için
`100` veya `999`).

```dart
// ✅
BorderRadius.circular(12)
BorderRadius.circular(20)
const BorderRadius.vertical(top: Radius.circular(24))

// ❌
BorderRadius.circular(13)
BorderRadius.circular(7)
BorderRadius.circular(19)
```

### 6.5 Loading state

| Durum | Bileşen |
|-------|---------|
| Çok kısa async (<500ms, buton içi) | `CircularProgressIndicator` (mini) |
| Listede 3+ kart yüklenecek | `Shimmer` skeleton (yeni `shared/widgets/list_skeleton.dart`) |
| Detay ekranı | `<Feature>DetailSkeleton` widget (var olanlar kullanılacak) |
| Resim yükleme | `cached_network_image` placeholder builder |

### 6.6 Error state

Yeni `lib/core/widgets/error_state.dart` widget'ı oluşturulacak (Kişi A,
Gün 10):

```dart
class ErrorState extends StatelessWidget {
  final String? title;       // 'Bir şeyler ters gitti'
  final String? message;     // örn. e.toString() kısa hali
  final VoidCallback? onRetry;
  final IconData icon;       // default: Icons.wifi_off_rounded
  ...
}
```

Tüm `AsyncValue.error` çağrıları bu widget'a geçecek.

### 6.7 Empty state

`lib/core/widgets/empty_state.dart` (yeni, A Gün 10):

```dart
class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;     // örn. "Karşılaştır" butonu
  ...
}
```

### 6.8 Dark mode kontrolü

```dart
// ✅ İZİNLİ - Helper kullan
final isDark = Theme.of(context).brightness == Brightness.dark;
color: isDark ? AppColors.darkSurface : AppColors.surface;

// Daha iyi: helper
color: AppColors.surfaceFor(context);

// ❌ YASAK - Hardcoded
color: Colors.white;          // Light bg, dark mode'da bozar
color: const Color(0xFF1A1A1A);
```

### 6.9 Animasyon ilkeleri

- Sayfa geçişi: 280ms, `Curves.easeOutCubic`
- Tap reaksiyonu: 120ms, `Curves.easeOut`
- Fade-in: 200-300ms
- Heavy element (modal, paywall): 400ms max
- AnimationController **her zaman** `dispose()` edilir

---

## 7. Gün Gün Plan (1-21)

> Her gün için: **Kişi A görevleri**, **Kişi B görevleri**, **Sync point**,
> **Beklenen PR'lar**, **Riskler**. Görev başına yaklaşık süre 1-3 saat.

### Gün 1 — Kickoff & Branch Hijyeni

**Sabah standup (45 dk):**
- Bu planı birlikte oku (bu dosya).
- Rolleri ve dosya sahipliğini doğrula.
- Slack/WhatsApp pinli mesaj: "Sprint 5 dosya sahipliği matrisi"
- GitHub'da `develop` branch'ini protect et: PR zorunlu, 1 onay, force-push yasak.
- `feat/sprint4.5-osym-data` branch'inde açık conflict'i çöz (`comparison_uni_picker.dart`).

**Kişi A:**
1. `comparison_uni_picker.dart`'taki merge conflict'i çöz (HEAD tarafını koru
   çünkü güncel UI o, develop'taki eski layout — `git checkout --ours`).
   - PR: `fix/s5-resolve-uni-picker-merge-conflict`
2. `feat/sprint4.5-osym-data` üzerindeki tüm modified + untracked dosyaları
   gözden geçir. B ile birlikte commit gruplarını planla.
3. Yeni dizinler oluştur:
   - `play_store_assets/` (gitkeep ile)
   - `docs/screenshots/` (gitkeep ile)
   - `lib/core/widgets/` (varsa kontrol et)
4. Bu plan dosyasını `docs/` altına symlink veya kopya yap (referans
   kolaylığı için).

**Kişi B:**
1. Gerçek dünya conflict önleme: develop branch'ini `feat/sprint4.5-osym-data`
   ile sync et. Eğer feature branch develop'ten ciddi diverged'sa, yeni bir
   `feature/s5-sprint45-rebase` branch'i aç ve aşamalı mergele.
2. `firestore.rules`'taki uncommitted değişiklikleri commit et:
   - PR: `chore/s5-firestore-rules-comparison-notes`
   - Mesaj: `chore(firestore): add comparison notes collection rules`
3. Lokal `firebase emulators:start` ile yeni kuralları test et (yazma + okuma
   + diğer kullanıcı dataset'ine erişim engeli).
4. Production'a deploy'u **gün 17'ye** ertele (release branch açıldıktan sonra).

**Day-end sync:**
- Tüm uncommitted dosyalar artık ya commit'lendi ya da bilinçli silindi.
- `git status` her iki kişide de temiz.
- Yarın hangi PR'lar açılacak açıklığa kavuştu.

**Beklenen PR'lar:** 2 PR mergelenmiş (conflict fix + firestore.rules).

---

### Gün 2 — In-flight Feature Finalize (Part 1)

**Kişi A — Auth & Profile L10n + A11y başlangıç:**
1. `lib/features/auth/presentation/screens/login_screen.dart` içindeki
   ~40 hardcoded TR string'i `app_tr.arb`'a taşı, key'leri `auth.*`
   prefix'i ile organize et.
2. Aynı ekrandaki IconButton'lara `tooltip` ekle (line 289 vd.).
3. `lib/features/auth/presentation/screens/register_screen.dart` — aynı flow.
4. `app_en.arb`'a placeholder İngilizce çeviriler ekle (gerçek çeviri Gün 14'te).
5. PR: `feature/s5-auth-l10n-a11y`

**Kişi B — Comparison Notes finalize:**
1. `comparison_notes_repository.dart` (untracked) → commit. Kod review:
   - try/catch silent failure yok mu?
   - `addPostFrameCallback` ile race condition yok mu?
   - Maks not uzunluğu validate ediliyor mu?
2. `comparison_note_bottom_sheet.dart` + `comparison_note_card.dart`
   + `comparison_notes_section.dart` → commit + UI gözden geçir.
3. Paywall gate doğrulaması: free user not ekleyemiyor → "Pro Plana Yükselt"
   bottom sheet'i çıkıyor mu?
4. Edge case'ler:
   - Boş not save edilebilir mi? → engelle
   - 1000 karakterden uzun not? → max length sınırlayıcı
   - Offline iken yazılırsa? → Firestore offline persistence devreye girer mi?
5. PR: `feature/s5-comparison-notes-finalize`

**Sync point (öğle):**
- A: l10n key naming convention'ı B'ye göster (`auth.signInWithGoogle`,
  `auth.passwordTooShort` gibi). B kendi feature'ında da aynı naming'i kullanır.

**Beklenen PR'lar:** 2 PR açıldı, biri öğleden sonra mergelendi.

**Riskler:**
- L10n .arb dosyasını ikisi de aynı gün açtıysa conflict. → Bugün sadece A
  ARB dosyalarına dokunur, B yarın.

---

### Gün 3 — In-flight Feature Finalize (Part 2)

**Kişi A — Profile + Edit Profile L10n + Polish:**
1. `lib/features/profile/presentation/screens/profile_screen.dart`'taki ~15
   hardcoded string l10n'a taşı.
   - `Text('Hesabım')` → `Text(loc.profileTitle)`
   - "Gizlilik politikası yakında" → `loc.privacyPolicyComingSoon` (gerçek
     URL'yi Gün 16'da ekleyeceğiz)
2. `edit_profile_screen.dart` (5 hardcoded string).
3. Profile fotoğraf yükleme akışını test et (camera + galeri).
4. PR: `feature/s5-profile-l10n-polish`

**Kişi B — Triple Comparison stabilize:**
1. `triple_third_uni_picker.dart` (untracked) → commit + review.
2. `triple_comparison_result.dart` model → commit + review. Score
   normalization mantığı doğru mu? (A > B > C sıralaması).
3. `comparison_providers.dart` içindeki `tripleComparisonResultProvider`
   error handling'i sağlamlaştır (FirebaseCrashlytics.recordError çağrısı var ✓).
4. Free user 3-way deneme → paywall gösterilmeli (gate test).
5. Pro user happy path: 3 farklı üniversite seç → sonuç ekranı stabil.
6. Edge case: aynı üniversite 2 kez seçilemez (filtreleme var, ama 3. üni
   filtresi A/B'yi exclude ediyor mu?).
7. PR: `feature/s5-triple-comparison-finalize`

**Sync point:**
- B, A'ya `comparison_providers.dart` içinde yeni provider eklediğinde
  paywall route'unun changed olmadığını teyit etsin.

**Beklenen PR'lar:** A bitirdi, B PR açtı, mergesi yarın.

---

### Gün 4 — Places Dark Mode + Color Token (A) / Paywall Final (B)

**Kişi A — Places feature dark mode + AppColors enforcement:**
1. `lib/features/places/presentation/widgets/dorm_info_card.dart` — 0xFFE3F2FD
   ve 0xFFFFF3E0 renklerini AppColors token'larına dönüştür. Yoksa yeni
   `AppColors.infoLight`, `AppColors.warningLight` ekle.
2. `lib/features/places/presentation/widgets/dorm_room_floor_plan.dart` —
   30+ hardcoded color. Bunları yeni bir `lib/features/places/presentation/
   widgets/dorm_room_colors.dart` içine taşı (semantik enum + getter).
3. `place_detail_screen.dart` — Colors.white70/white54 yerine `Colors.white
   .withValues(alpha: 0.7)` dark mode-aware kullan.
4. `place_filter_sheet.dart` — dark mode background fix.
5. `place_detail_skeleton.dart` — hardcoded Colors.white container'ları
   `AppColors.shimmerBase / shimmerHighlight` ile değiştir.
6. PR: `feature/s5-places-dark-mode-colors`

**Kişi B — Paywall yenileme finalize:**
1. Mevcut paywall_screen.dart (yeni tier-reactive UI) → manuel test.
   - Free seçili → "Ücretsiz Devam Et" → pop ✓
   - Plus seçili → mor gradient + Aylık/Yıllık ✓
   - Pro seçili → altın-turuncu + tasarruf rozeti ✓
2. RevenueCat sandbox ile satın alma akışını test et:
   - Test card → success → success dialog → Pro user
   - Test card → cancel → error snackbar
   - Restore purchases → tier doğru dönüyor
3. Paywall hatası: paket bulunamadığında SnackBar yerine in-card error mesajı.
4. PR: `fix/s5-paywall-error-states` (varsa düzeltme)

**Sync point:**
- A AppColors'a yeni token (infoLight, warningLight) ekledi → B onay versin
  (paylaşılan dosya).

**Beklenen PR'lar:** 2 mergelenebilir.

---

### Gün 5 — Recommendation Polish (A) / Reviews Polish (B)

**Kişi A — Home + University polish:**
1. `home_screen.dart` line 403-407: 5 inline gradient color → AppColors.
2. `splash_screen.dart`: 6 hardcoded color → AppColors.
3. `university_detail_screen.dart` 9 hardcoded TR string → l10n.
4. Bare `CircularProgressIndicator` (3 yerde, home line 136/175/211) →
   `<HomeListSkeleton>` adlı yeni widget'a dönüştür.
5. PR: `feature/s5-home-university-polish`

**Kişi B — Reviews + Recommendation polish:**
1. `recommendation_result_screen.dart`: 4 raw TextStyle (line 107, 169,
   284, 349) → AppTextStyles.
2. `all_reviews_screen.dart` line 296: ListView eager → ListView.builder.
3. `my_reviews_screen.dart` line 135 → ErrorState widget kullan (A'nın Gün
   10'da yapacağı, şimdilik temporary inline).
4. `write_review_screen.dart` final test + edge case'ler (anonim mode'da
   submit, kategori puanı atlanırsa hata).
5. PR: `feature/s5-reviews-recommendation-polish`

**Sync point:**
- A'ya: "Bugün AppColors'a ekleme yapacak mısın?" → B planlıyorsa koordine et.

---

### Gün 6 — Design System Unification (Ortak Gün)

**Bugün her ikisi de paylaşılan dosyaları olabildiğince az touch eder.
Hedef: AppColors ve AppTextStyles'ı tamamlamak.**

**Kişi A:**
1. `lib/core/theme/app_colors.dart` final pass:
   - Eksik token'ları ekle: `shimmerBase`, `shimmerHighlight`, `infoLight`,
     `warningLight`, `successLight`, `errorLight`, `darkSurface2`
   - Helper'ları yaz: `surfaceFor(context)`, `textOnSurfaceFor(context)`,
     `dividerFor(context)`.
   - Yorumla: hangi renk hangi tier için (free/plus/pro/brand/semantic).
   - PR: `chore/s5-app-colors-complete`
2. `app_text_styles.dart` review: tüm boyutlar (caption, label, body, title,
   headline, display) ve weights tanımlı mı?

**Kişi B:**
1. `pubspec.yaml`'da kullanılmayan paket var mı? `flutter pub deps`
   çıktısına bak. Varsa kaldır.
2. RevenueCat hardcoded API key (revenuecat_service.dart:27) → `--dart-define`
   ile inject et. Konfigürasyonu doc'a yaz.
3. Analytics service kullanılan/eklenmesi gereken event'leri listele
   (`event_inventory.md` yeni dosya `docs/` altında).
4. PR: `chore/s5-config-cleanup`

**Sync point (uzun, 30 dk):**
- A'nın AppColors PR'ını birlikte review et.
- Hangi feature'ın hangi gün AppColors enforcement'ı yapacağını planla
  (Gün 8-9 detaylı plan).

---

### Gün 7 — Karşılaştırma Notları/3-way Beta Test & Feature Freeze

**Bugün son özellik kararı verilir. Sprint 4.5 işi tamamen bitmiş olmalı.**

**Kişi A:**
1. `lib/features/auth/presentation/screens/login_screen.dart` ve
   `register_screen.dart` üzerinde tam manuel test:
   - Google sign-in → çalışıyor ✓
   - Apple sign-in → (varsa) iOS'a kadar bekleyebilir
   - Email/password → register → email verification akışı
   - Edu.tr verification (varsa)
2. Auth ekranlarında dark mode test (eski raporda gap var).
3. PR varsa: `fix/s5-auth-dark-mode`

**Kişi B:**
1. Karşılaştırma notları + 3-way için Pro user happy path E2E manuel test.
2. Edge case bombing:
   - 100 karakter sınırını aş → trim çalışıyor mu?
   - Hızlı tap-tap → race condition?
   - Notunu kaydederken internet kes → offline mode davranışı
3. `comparison_providers.dart`'taki tüm error handling'i review et.
4. Karar: bu özellikler **stabil** ve **v1.0'a hazır** → resmi olarak
   "feature freeze" deklare et.
5. Eğer kritik bug bulunursa **Gün 8'e** taşınır, daha sonrası YASAK.

**Sync point:**
- Feature freeze deklarasyonu: GitHub'da `feature-freeze-v1.0` etiketi.
- Sprint 5'in geri kalan 14 günü **sadece polish, perf, release**.
- Yeni özellik isteği gelirse → v1.1 backlog.

---

### Gün 8 — AppColors Enforcement Wave 1

**A ve B kendi feature alanlarında hardcoded color'ları temizler.**

**Kişi A — Feature'larında AppColors enforcement:**
1. `lib/features/places/` (en yoğun, Gün 4'te başlandı, devam)
2. `lib/features/home/` (Gün 5 başlangıç, finalize)
3. `lib/features/university/`
4. PR: `chore/s5-app-colors-features-a`

**Kişi B — Feature'larında AppColors enforcement:**
1. `lib/features/comparison/` — hex colors:
   - `comparison_hero_section.dart:22,185,189`
   - `comparison_hub_screen.dart:94`
2. `lib/features/monetization/`:
   - `subscription_gate_widget.dart:98,99,203,204`
   - `paywall_screen.dart:1020,238` (eğer hala varsa)
3. PR: `chore/s5-app-colors-features-b`

**Sync point:**
- A AppColors'a token EKLEYECEKSE B'ye haber ver.
- Her ikisi de `git pull --rebase` yapsın PR açmadan önce.

---

### Gün 9 — AppTextStyles + Spacing/Radius Enforcement Wave

**Kişi A:**
1. Kendi feature'larında raw TextStyle → AppTextStyles dönüşümü.
2. Spacing/Radius non-standard değer auditi:
   - `EdgeInsets.all(14)` → `EdgeInsets.all(12)` veya `16`
   - `BorderRadius.circular(14)` → `12` veya `16`
3. Aşağıdaki dosyalarda en az 30 düzeltme:
   - `preference_lists/screens/list_edit_screen.dart` (4 raw TextStyle)
   - `preference_lists/screens/my_lists_screen.dart` (2)
   - `preference_lists/screens/shared_list_screen.dart` (2)
4. PR: `chore/s5-typography-spacing-a`

**Kişi B:**
1. `comparison_history_sheet.dart:522` raw TextStyle fix.
2. `paywall_screen.dart:1041` dynamic fontSize → const.
3. `recommendation_result_screen.dart` daha önce yapılmadıysa devam.
4. Spacing/Radius cleanup kendi feature'larında.
5. PR: `chore/s5-typography-spacing-b`

**Riskler:**
- AppTextStyles'a yeni style EKLEMEK gerekirse A ile koordine.

---

### Gün 10 — Shared Widgets: ErrorState + EmptyState + Skeleton

**Kişi A — Shared widget'ları oluştur ve kendi feature'larında kullan:**
1. `lib/core/widgets/error_state.dart` oluştur (bkz: §6.6).
2. `lib/core/widgets/empty_state.dart` oluştur (bkz: §6.7).
3. `lib/core/widgets/list_skeleton.dart` — generic shimmer list skeleton.
4. Kendi feature'larında bare error/empty state'leri değiştir:
   - `favorites/screens/favorites_screen.dart:84,97`
   - `university/screens/uni_ratings_screen.dart:23`
   - `city_universities_screen.dart:101,126`
   - `home/screens/explore_screen.dart` bare spinners → ListSkeleton
5. PR: `feature/s5-core-error-empty-skeleton-widgets`

**Kişi B — Comparison/Reviews/Monetization'da kullanım:**
1. A'nın PR'ı mergelendikten sonra (öğleden sonra):
2. `comparison_screen_v1.dart:99` bare error → ErrorState
3. `comparison/widgets/department_picker_bottom_sheet.dart:291,438` 2 yer
4. `comparison/widgets/city_picker_bottom_sheet.dart:123`
5. `reviews/screens/my_reviews_screen.dart:135` → kalan inline placeholder'ı
   gerçek widget'a değiştir.
6. PR: `chore/s5-error-state-rollout-b`

**Sync point:**
- A öğleden önce widget'ları bitirir.
- B'nin PR'ı A'nınkini bekleyecek (dependency).
- Eğer A geciktiyse B paralel başka iş yapar (örn. ProGuard araştırması).

---

### Gün 11 — Skeleton Loader Rollout

**Kişi A:**
1. `lib/features/home/screens/explore_screen.dart` 2 bare spinner → skeleton
2. `lib/features/home/screens/search_screen.dart:89`
3. `lib/features/home/screens/splash_screen.dart:280` (kısa süreli, OK
   bırakılabilir)
4. `lib/features/profile/screens/profile_screen.dart:64,68`
5. `lib/features/university/screens/uni_ratings_screen.dart:23`
6. PR: `feature/s5-skeleton-loaders-a`

**Kişi B:**
1. `lib/features/reviews/screens/my_reviews_screen.dart:135`
2. Kendi feature'larında kalan bare spinner'lar.
3. PR: `feature/s5-skeleton-loaders-b`

---

### Gün 12 — Performans Profiling + ListView.builder Dönüşümleri

**Hedef:** 13 eager ListView'ı `.builder`'a dönüştür.

**Kişi A:**
1. `places/widgets/place_list.dart:82`
2. `places/screens/place_filter_sheet.dart:65`
3. `university/screens/uni_reviews_screen.dart:29`
4. `university/screens/uni_departments_screen.dart:39`
5. `university/screens/uni_places_screen.dart:41`
6. `university/screens/university_gallery_screen.dart:94`
7. `university/screens/score_detail_sheet.dart:56`
8. `home/screens/explore_screen.dart:135,327`
9. PR: `perf/s5-listview-builder-a`

**Kişi B:**
1. `reviews/screens/all_reviews_screen.dart:296`
2. `reviews/screens/my_reviews_screen.dart:79`
3. `reviews/widgets/photo_upload_section.dart:172`
4. `recommendation/screens/recommendation_result_screen.dart:201`
5. **Profiling:** Release build alıp DevTools ile en yoğun ekranı (üniversite
   karşılaştırma sonuç) ölç. Frame'ler 16ms altında mı?
6. PR: `perf/s5-listview-builder-b` + `docs/perf-profile-baseline.md`

---

### Gün 13 — Accessibility Pass + Image Caching Audit

**Kişi A — A11y kapsamı:**
1. Tüm `IconButton` ve `InkWell` öğelerine `tooltip` veya `Semantics` ekle:
   - `comparison_hub_screen.dart:209`
   - `auth/screens/login_screen.dart:289`
   - `auth/screens/register_screen.dart:173,293,331`
   - `places/screens/place_detail_screen.dart:93`
   - `notifications/widgets/notification_bell.dart:18`
2. Tüm `Image.asset` çağrılarına `semanticLabel` ekle (10+).
3. InkWell tappable areas < 48×48 düzelt (minimum hit target).
4. PR: `chore/s5-accessibility-a`

**Kişi B — Image caching + ufak perf:**
1. Tüm `Image.network` çağrılarını `cached_network_image` ile değiştir
   (audit'te 3 kalan vardı).
2. `cacheWidth/cacheHeight` parametresi eklenmeli (örn. avatar 96 px, list
   thumbnail 200 px).
3. Crashlytics manual error reporting'i 5+ yere ekle (yapılmayan ekranlar).
4. PR: `perf/s5-image-cache-b` + `chore/s5-crashlytics-coverage`

---

### Gün 14 — L10n Final + İlk Bug Bash

**Sabah — L10n final pass:**

**Kişi A:**
1. `app_tr.arb` review — eksik key var mı? Naming convention tutarlı mı?
2. `app_en.arb` — placeholder İngilizce çevirileri gerçek çevirilere
   güncelle. Native speaker yoksa DeepL ile pre-translate + manuel review.
3. PR: `chore/s5-l10n-finalize`

**Kişi B:**
1. Kendi feature'larında kalan hardcoded TR string'leri l10n'a taşı.
2. Lokalize edilemeyen string'ler (debug log, internal) → comment ile işaretle.

**Öğleden sonra — Bug bash (2-3 saat birlikte):**
- Her ikisi de farklı cihazlarda (Android 11, Android 13+) uygulamayı kullan.
- Tüm ekranları gez, dark/light, TR/EN switch, offline mode.
- Bulunan her bug için GitHub issue aç (`bug-bash-day14` label).
- Kritik bug'lar Gün 15-16'da fix edilir.

**Day-end:**
- Bug bash sonuçları → Slack pinli mesaj.
- Yarın hangi P0/P1 bug'lar düzeltilecek.

---

### Gün 15 — Release Engineering Day 1

**Kişi A — Store Assets üretimi:**
1. **App icon 512×512** — `assets/icons/unisec-icon-ink-1024.png`'den
   downscale, Play Store gereği. Figma veya Photoshop'ta keskin downscale.
2. **Feature graphic 1024×500** — branded banner:
   - Üst arkaplan: AppColors.darkSurface gradient
   - Sol: UniSeç logo + tagline ("Üniversite Hayatın Burada Şekilleniyor")
   - Sağ: 2-3 üniversite kartı mockup
   - PNG, < 1 MB
3. **Screenshot çekimleri** (en az 6 adet, ideal 8):
   - Android emulator Pixel 7 (1080×2400)
   - Sahneler:
     1. Karşılaştırma sonuç ekranı (hero)
     2. Üniversite detay sayfası
     3. Bölüm karşılaştırma (Plus özelliği vurgulu)
     4. Şehir karşılaştırma
     5. Yorum yazma ekranı
     6. Mekanlar (yurt detayı)
     7. Profil ekranı
     8. Paywall (Pro tier seçili, çekici görünüyor)
   - Her birinde alt yazı/caption ekle (Figma overlay)
   - PNG'leri `play_store_assets/screenshots/phone/` altına
4. PR: `chore/s5-play-store-assets`

**Kişi B — Adaptive icon + Crashlytics global handler:**
1. `flutter_launcher_icons` config'i güncel mi?
   ```yaml
   flutter_launcher_icons:
     android: true
     ios: false
     image_path: "assets/icons/unisec-icon-ink-1024.png"
     min_sdk_android: 21
     adaptive_icon_background: "#1A1A2E"
     adaptive_icon_foreground: "assets/icons/unisec-icon-fg.png"
   ```
   - `unisec-icon-fg.png` foreground asset'i (transparent bg, 432×432
     centered logo) hazırlat veya mevcut PNG'den crop et.
2. `flutter pub run flutter_launcher_icons` çalıştır.
3. Sonucu kontrol et: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
   oluşmuş mu?
4. `lib/main.dart`'ta global Crashlytics handler:
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

     FlutterError.onError = (errorDetails) {
       FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
     };
     PlatformDispatcher.instance.onError = (error, stack) {
       FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
       return true;
     };

     runApp(ProviderScope(...));
   }
   ```
5. ProGuard kurallarını güncelle (`android/app/proguard-rules.pro`):
   ```
   # RevenueCat
   -keep class com.revenuecat.** { *; }
   -dontwarn com.revenuecat.**

   # Riverpod (kod gen kullanılmıyor ama eğer kullanılırsa)
   -keepclassmembers class * {
     @androidx.annotation.Keep *;
   }
   ```
6. PR: `chore/s5-adaptive-icon-crashlytics-proguard`

---

### Gün 16 — Release Engineering Day 2

**Kişi A — Privacy Policy + Data Safety içeriği:**
1. `https://unisec.app/privacy` URL'sinin canlı ve doğru içerikli olduğunu
   doğrula. Değilse içerik yaz:
   - Toplanan veriler (email, ad, fotoğraf, yorum, rating, FCM token,
     ödeme bilgileri)
   - Kullanım amacı
   - 3. taraf paylaşımı (Firebase/Google, RevenueCat)
   - Kullanıcı hakları (silme, indirme, KVKK)
   - İletişim email'i
2. Aynı sayfada veya ayrı `/terms` için kullanım şartları taslağı.
3. Play Console "Data Safety" form'u için TR cevapları hazırla (örnek):
   ```
   - Veri toplanıyor mu? Evet
   - Veri tipleri:
     * Kişisel Bilgi: Email, Ad
     * Fotoğraflar: Profil fotoğrafı
     * App Etkinliği: Sayfa görüntülemeleri (Analytics)
     * App Bilgileri: Crash log'ları (Crashlytics)
     * Cihaz Tanımlayıcıları: FCM Token (push için)
   - Veri toplanma amaçları: App işlevselliği, analitik, hesap yönetimi
   - 3. taraf SDK: Firebase, RevenueCat, Google Mobile Ads
   - Veri silinebilir mi? Evet (Hesabım > Hesap Sil)
   - Şifreleniyor mu (transit)? Evet (HTTPS)
   ```
4. PR: `docs/s5-privacy-data-safety`

**Kişi B — Release keystore + signing config:**
1. **Upload keystore oluştur (LOKAL, repo'ya commitleme):**
   ```bash
   keytool -genkey -v -keystore ~/secure/unisec_upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias upload
   ```
   - Parolaları **Bitwarden / 1Password**'a kaydet. KAYBETME, recovery yok.
2. `android/key.properties` oluştur (gitignore'da):
   ```properties
   storePassword=<store-pass>
   keyPassword=<key-pass>
   keyAlias=upload
   storeFile=/Users/<you>/secure/unisec_upload.jks
   ```
3. `.gitignore`'a ekle: `android/key.properties` + `*.jks`
4. `android/app/build.gradle.kts` güncelle:
   ```kotlin
   import java.util.Properties
   import java.io.FileInputStream

   val keystoreProperties = Properties()
   val keystorePropertiesFile = rootProject.file("key.properties")
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(FileInputStream(keystorePropertiesFile))
   }

   android {
       signingConfigs {
           create("release") {
               keyAlias = keystoreProperties["keyAlias"] as String
               keyPassword = keystoreProperties["keyPassword"] as String
               storeFile = file(keystoreProperties["storeFile"] as String)
               storePassword = keystoreProperties["storePassword"] as String
           }
       }
       buildTypes {
           release {
               signingConfig = signingConfigs.getByName("release")
               isMinifyEnabled = true
               isShrinkResources = true
               proguardFiles(
                   getDefaultProguardFile("proguard-android-optimize.txt"),
                   "proguard-rules.pro"
               )
           }
       }
   }
   ```
5. İlk release build alın:
   ```bash
   flutter clean
   flutter pub get
   flutter build appbundle --release
   ```
   AAB dosyası: `build/app/outputs/bundle/release/app-release.aab`
6. PR: `chore/s5-release-signing-config`

**Sync point:**
- B build başardıysa, A AAB'yi al ve test yükle (kendi cihazına `bundletool`
  ile install).

---

### Gün 17 — Release Branch + Internal Testing Track

**Sabah — Release branch açılışı:**
```bash
git checkout develop
git pull
git checkout -b release/v1.0.0
git push -u origin release/v1.0.0
```

**Bundan sonra develop'e yeni feature commit girmez** (sadece v1.1 backlog).
Release branch'e sadece bug fix gelir.

**Kişi A:**
1. **Play Console'da app oluştur** (eğer yoksa):
   - Application name: "UniSeç — Üniversite Karşılaştırma"
   - Default language: Turkish (Türkiye)
   - Type: App / Free
2. **Store Listing TR:**
   - App name: UniSeç
   - Short description (80 kr.): bkz Ek C
   - Full description (4000 kr.): bkz Ek C
   - App icon, feature graphic, screenshots upload
3. **Store Listing EN:** çevirisi
4. **Categories:** Education + Lifestyle
5. **Contact details:** email, website, privacy policy URL
6. PR: `docs/s5-play-listing-content`

**Kişi B:**
1. Production AAB'yi Play Console'a **Internal Testing track**'ine yükle.
2. Internal tester listesi oluştur (2-3 takım üyesi + dostlar email).
3. Opt-in link'i Internal tester'lara WhatsApp/email ile gönder.
4. **firestore.rules'u production'a deploy:**
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes
   ```
5. RevenueCat dashboard'da production environment doğrulama:
   - Product ID'ler kayıtlı (`unisec_plus_monthly`, etc.)
   - Webhooks (varsa) yapılandırılmış
6. AdMob production ad unit ID'leri envanterle (test ID yerine değişecek
   Gün 18'de).

**Day-end:**
- Internal testing track aktif. 2-3 kişi test yüklemiş.
- Crashlytics dashboard açık, ilk reports izleniyor.

---

### Gün 18 — Internal Test Feedback Fix

**Sabah — Internal feedback topla:**
- Internal tester'lara 24 saat verildi.
- Slack/WhatsApp'ta bulunan bug'ları topla, kategorize et (P0/P1/P2/P3).

**P0 (Bloker, çıkmadan önce mutlaka fix):**
- Crash on launch
- Auth failure
- Purchase failure
- Data loss

**P1 (Yüksek öncelik, mümkünse fix):**
- UI bozulma (yazılar overflow)
- Yanlış veriler (üniversite skoru hatalı)

**P2 (Orta, fix edilebilirse):**
- Animasyon takılma
- Yazım hatası

**P3 (Düşük, v1.1):**
- Nice-to-have iyileştirme

**Kişi A & B — P0/P1 bug fix yarışı:**
- Bugün maksimum 6-8 saat sürede P0'ları kapat, P1'leri triage.
- Her fix için ayrı küçük PR, `fix/s5-<bug-id>` formatında.
- Her PR mergelenince yeni AAB build et:
  ```bash
  ./scripts/build_release.sh    # versionCode auto-increment + build
  ```
- Yeni AAB'yi Internal testing'e yükle (yeni release).

**Versiyon notu:**
- versionCode 1 → 2 → 3 ... (her yüklemede increment)
- versionName 1.0.0 sabit (sadece bug fix yapıyoruz)

---

### Gün 19 — Closed Beta Açılış

**Sabah:**
- P0 bug yok mu son kontrol.
- Crashlytics dashboard temiz mi?
- Internal'da test edilmiş build → **Closed Testing track**'e promote.

**Kişi A:**
1. Closed beta tester listesi oluştur (5-10 kişi):
   - 3-5 üniversite öğrencisi (gerçek hedef kitle)
   - 1-2 teknik kullanıcı (bug bulur)
   - 1-2 dost-aile (anlamlandırılabilirlik testi)
2. Onboarding email/WhatsApp şablonu hazırla:
   ```
   Merhaba <name>,
   UniSeç'in beta sürümünü test ediyoruz!
   Adımlar:
   1. https://play.google.com/apps/testing/com.unisec.app linkini aç
   2. "Become a tester" tıkla
   3. Birkaç dakika sonra Play Store'da uygulamayı bulup yükle
   Geribildirim için: bu WhatsApp grubu / forms.gle/...
   Teşekkürler!
   ```
3. Test odakları:
   - Auth + email verification
   - Üniversite karşılaştırma 2-way ve 3-way
   - Yorum yazma + okuma
   - Paywall + satın alma (sandbox card)
   - Dark mode
   - Offline akış

**Kişi B:**
1. Google Forms ile feedback toplama formu:
   - Genel deneyim (1-5)
   - Hangi feature'ı sevdin?
   - Hangi feature'ı sevmedin?
   - Bug raporu (text + screenshot)
   - Crash yaşadın mı?
2. AdMob production ad unit ID'lerini koda yedirir:
   - Test ID değiştirir (`ad_service.dart`)
   - Yine de dart-define ile env-based seçim yapsın.
3. Beta build #2 yükle (eğer Gün 18 sonu fix'leri varsa).

---

### Gün 20 — Beta Feedback Fix + Release Notes

**Sabah — Feedback topla ve triage:**
- 24 saatte 5-10 tester'dan ne kadar feedback geldi?
- Crashlytics'te yeni crash var mı?
- En kritik 3-5 bug'ı belirle.

**Öğleden önce — Bug fix:**
- Kişi A ve B sırayla beta-fix PR'ları açar.
- Test, mergele, yeni build, Closed Testing'e yükle.

**Öğleden sonra — Release notes:**

**Kişi A — TR release notes (`docs/release-notes/v1.0.0.md`):**
```markdown
# UniSeç v1.0.0 — İlk Sürüm! 🎉

## Yenilikler
- Türkiye'deki devlet ve özel üniversiteleri karşılaştır
- Bölüm karşılaştırma — taban puan, kontenjan, başarı sıralaması
- Şehir karşılaştırma — yaşam maliyeti, ulaşım, eğlence
- Pro üyelik ile:
  - 3 üniversiteyi aynı anda karşılaştır
  - Karşılaştırmaya kişisel notlar ekle
  - AI destekli özet ve öneri
  - Reklamsız deneyim
- Yorumlar ve değerlendirmeler — anonim seçeneği ile
- Yurt, kafe, çalışma alanı keşfi
- Türkçe + İngilizce dil desteği
- Dark mode

## Yakında (v1.1)
- iOS sürümü
- Apple Sign-in
- Üniversite hakkındaki bildirimlere abone olma

## Teşekkürler
Beta test sürecinde geri bildirim veren herkese teşekkürler!
```

**Kişi B — EN release notes:**
- Aynı içeriği İngilizce'ye çevir.
- Play Console "What's new" alanı için 500 karakterlik kısa versiyon hazırla.

**Akşam — Production hazırlık:**
- Production track'i Play Console'da "Setup release" durumuna getir.
- AAB henüz **upload edilmez** — yarın gün 21 sabahında upload.

---

### Gün 21 — **PRODUCTION RELEASE**

> Tüm günü release prosedürüne odaklan. Yeni feature/refactor yasak.

**Sabah Runbook (bkz §12):**

**Kişi A:**
1. Son bir kez Crashlytics dashboard kontrol (son 48 saat).
2. Privacy policy URL'sini Play Console'da doğrula.
3. Data Safety form'unu yeniden review.
4. Store listing'in tüm dil sürümlerinde tamamlığını teyit et.
5. Screenshot'lar yüksek kalite mi?

**Kişi B:**
1. `release/v1.0.0` branch'inde son fix var mı? Eğer varsa main'e
   merge etmeden önce dahil et.
2. Final AAB build (versionCode son hali):
   ```bash
   flutter clean
   flutter pub get
   flutter build appbundle --release
   ```
3. AAB'yi Play Console **Production** track'ine yükle.
4. "Submit for review" tıkla — **%20 staged rollout** seçeneği ile.
5. Google review süresi: tipik olarak 1-3 saat (basit app), max 7 gün.

**Onay sonrası (saatler içinde):**
- Production'da yayında!
- Tag oluştur:
  ```bash
  git checkout main
  git merge --no-ff release/v1.0.0
  git tag -a v1.0.0 -m "v1.0.0 - First production release"
  git push origin main --tags
  git checkout develop
  git merge --no-ff release/v1.0.0
  git push origin develop
  git branch -d release/v1.0.0
  git push origin --delete release/v1.0.0
  ```
- Slack/WhatsApp'a "YAYINDAYIZ" mesajı + Play Store linki paylaş.
- Kişisel sosyal medya hesaplarından paylaşım (organik launch).

**Akşam:**
- Crashlytics dashboard sürekli açık.
- İlk 24 saat hangi crash'ler oluşacak izle.
- Acil bug için "hotfix" branch hazır.

**Day +1, +2:**
- %20 → %50 rollout (crash rate < 1% ise)
- %50 → %100 rollout (crash rate < 0.5% ise)

---

## 8. UI Tutarlılığı Düzeltme Programı

Bu bölüm, audit'te bulunan sorunların **toplamını** ve **fix planını**
özetler. Detay günlük plana yedirilmiş.

### Renk hijyeni

| Konum | Sorun sayısı | Sorumlu | Gün |
|-------|--------------|---------|-----|
| `lib/features/places/widgets/dorm_room_floor_plan.dart` | 30+ | A | 4, 8 |
| `lib/features/places/widgets/dorm_info_card.dart` | 2 | A | 4 |
| `lib/features/places/screens/place_detail_screen.dart` | 4 | A | 4 |
| `lib/features/comparison/widgets/comparison_hero_section.dart` | 3 | B | 8 |
| `lib/features/home/screens/splash_screen.dart` | 6 | A | 5 |
| `lib/features/monetization/widgets/subscription_gate_widget.dart` | 4 | B | 8 |
| `lib/features/home/screens/home_screen.dart` | 5 | A | 5 |

### Text style hijyeni

| Konum | Sorun sayısı | Sorumlu | Gün |
|-------|--------------|---------|-----|
| `lib/features/recommendation/screens/recommendation_result_screen.dart` | 4 | B | 5, 9 |
| `lib/features/preference_lists/screens/list_edit_screen.dart` | 4 | A | 9 |
| `lib/features/preference_lists/screens/shared_list_screen.dart` | 2 | A | 9 |
| `lib/features/preference_lists/screens/my_lists_screen.dart` | 2 | A | 9 |
| Diğer (5+) | 5 | A & B | 9 |

### Dark mode kapsama

| Ekran | Sorumlu | Gün |
|-------|---------|-----|
| `places/widgets/place_detail_skeleton.dart` | A | 4 |
| `places/screens/place_detail_screen.dart` | A | 4 |
| `places/screens/place_filter_sheet.dart` | A | 4 |
| `auth/screens/login_screen.dart` | A | 7 |
| `auth/screens/register_screen.dart` | A | 7 |
| `profile/screens/profile_screen.dart` | A | 11 |

### Error state retry'le (14 yer)

Hepsi A'nın Gün 10'da oluşturacağı `ErrorState` widget'ına dönecek.

| Dosya | Satır | Sorumlu | Gün |
|-------|-------|---------|-----|
| `preference_lists/widgets/department_picker_sheet.dart` | 249, 373 | A | 10 |
| `reviews/screens/my_reviews_screen.dart` | 135 | B | 10 |
| `university/screens/uni_ratings_screen.dart` | 23 | A | 10 |
| `city_universities_screen.dart` | 101 | A | 10 |
| `favorites/screens/favorites_screen.dart` | 84, 97 | A | 10 |
| `comparison/screens/comparison_screen_v1.dart` | 99 | B | 10 |
| `university/screens/university_detail_screen.dart` | 262, 306, 343 | A | 10 |
| `places/screens/place_detail_screen.dart` | 41 | A | 10 |
| `comparison/widgets/department_picker_bottom_sheet.dart` | 291, 438 | B | 10 |
| `comparison/widgets/city_picker_bottom_sheet.dart` | 123 | B | 10 |

### Skeleton loader rollout (8 yer)

A: Gün 11 — home/profile/university feature'larında 6 yer
B: Gün 11 — reviews'da 2 yer

### Spacing/Radius normalizasyon

A: kendi 6 feature'ında ~50 düzeltme (Gün 9)
B: kendi 5 feature'ında ~30 düzeltme (Gün 9)

### L10n kalan ~127 string

A: auth + profile + university ~60 (Gün 2, 3, 7, 14)
B: comparison + monetization + reviews ~60 (Gün 14)
Kalan ~7 debug/log string: yorum eklenerek bırakılır

---

## 9. Performans Optimizasyon Programı

### Hedefler (Definition of Done):

- Soğuk başlatma < 3s (release build, mid-tier Android)
- Karşılaştırma sonuç ekranı 60fps (frame build < 16ms)
- APK/AAB boyutu < 35 MB
- Bellek pik kullanımı < 250 MB (orta seviye telefon)

### Aksiyonlar

#### 9.1 ListView eager → builder (Gün 12)

13 ListView dönüştürülecek. Pattern:
```dart
// Önce
ListView(
  children: items.map((i) => ItemCard(i)).toList(),
)

// Sonra
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, idx) => ItemCard(items[idx]),
)
```

`ListView.separated` da geçerli (separator gerekiyorsa).

#### 9.2 Image caching (Gün 13)

Tüm `Image.network` → `CachedNetworkImage`:
```dart
CachedNetworkImage(
  imageUrl: url,
  cacheWidth: 200,                    // resampling
  cacheHeight: 200,
  placeholder: (_, __) => const ListSkeleton.image(),
  errorWidget: (_, __, ___) =>
      Icon(Icons.image_not_supported_rounded),
)
```

#### 9.3 Const constructor adoption

Audit: 139 dosyada const var, kalan ~140 dosya optional iyileştirme.
**Sprint 5'te yapma**, v1.1'e bırak (yüksek effort, düşük getiri).

#### 9.4 Riverpod provider granularity

Audit: 6 Consumer, çoğunlukla iyi. Sprint 5'te yapma.

#### 9.5 Asset boyut optimizasyonu

`assets/data/department_scores.json` 548 KB. Sprint 5'te dokunma; v1.1'de
Firestore'a taşı (lazy load).

#### 9.6 Build size audit (Gün 12 sonu)

```bash
flutter build appbundle --release --analyze-size
```

Çıktıyı `docs/perf-profile-baseline.md`'ye yaz. Beklenmedik büyük modüller
var mı? (Örn. fl_chart > 5MB değilse OK)

#### 9.7 Crashlytics fatal/non-fatal ayrımı

`main.dart`'ta `FlutterFatal` ve `recordError(fatal: true/false)` doğru
kullanılsın. Audit: çoğu `recordError` çağrısı `fatal` parametresi eklenmemiş.

#### 9.8 Cold start ölçümü (Gün 12)

Profile mode'da release build:
```bash
flutter build apk --profile
adb shell am start -W com.unisec.app/.MainActivity
```

`Total time` < 3000ms olmalı.

---

## 10. Test Planı

### 10.1 Otomatik testler (5-8 yeni dosya, kritik path)

**Kişi B'nin yazacakları (Gün 7-9 arası, polish ile paralel):**

1. **`test/features/comparison/data/comparison_notes_repository_test.dart`**
   - Not ekleme, güncelleme, silme
   - Pro user değilse erişim engellendi mi?
   - Firestore mock (FakeFirebaseFirestore)

2. **`test/features/comparison/widgets/comparison_picker_slot_test.dart`**
   - Empty state render
   - Filled state ile uni render
   - Tap callback çağırılıyor mu

3. **`test/features/monetization/screens/paywall_screen_test.dart`**
   - Tier seçimi → gradient renk doğru
   - Ücretsiz → CTA "Ücretsiz Devam Et" + pop
   - Plus → Aylık/Yıllık card görünür

**Kişi A'nın yazacakları (Gün 13-14):**

4. **`test/features/auth/screens/login_screen_validation_test.dart`**
   - Geçersiz email → hata mesajı
   - Boş şifre → buton disabled

5. **`test/features/reviews/screens/write_review_screen_form_test.dart`**
   - Kategori puanı atlanırsa hata
   - Anonim mode toggle çalışıyor

6. **`test/core/widgets/error_state_test.dart`** (A oluşturuyor Gün 10)
   - Retry callback çağırılıyor
   - Title/message renderlanıyor

7. **`test/core/theme/app_colors_test.dart`** (opsiyonel)
   - Tüm tier color'ları kontrast WCAG AA geçiyor mu? (background üzerinde
     metin okunabilir mi?)

### 10.2 Manuel E2E Checklist (~50 senaryo)

> **Çalıştırma:** Gün 14 ve Gün 18 öncesinde tam pass.
> **Cihaz:** 1 Android 11 + 1 Android 13+. Hem light hem dark.

#### Auth (8 senaryo)
- [ ] Google ile giriş yap (yeni hesap) → onboarding'e gidiyor mu?
- [ ] Google ile giriş yap (mevcut hesap) → home'a gidiyor mu?
- [ ] Email/şifre ile kayıt ol → verification email geliyor mu?
- [ ] Yanlış email format → hata gösteriliyor mu?
- [ ] Şifre çok kısa → hata gösteriliyor mu?
- [ ] Şifremi unuttum → reset email geliyor mu?
- [ ] Logout → login ekranına geri dönülüyor mu?
- [ ] Hesap silme → tüm veriler temizleniyor mu?

#### Home (5 senaryo)
- [ ] Splash 1-2s sonra home'a açılıyor
- [ ] Keşfet tab'ı şehir kartlarını gösteriyor
- [ ] Ara tab'ı placeholder yok, gerçek search çalışıyor
- [ ] Bottom nav switching smooth
- [ ] Pull-to-refresh çalışıyor

#### University (8 senaryo)
- [ ] Üniversite detayı açılıyor (logo, hero, tabs)
- [ ] Bölümler tab'ı tüm bölümleri listeliyor
- [ ] Yorumlar tab'ı yorumları listeliyor
- [ ] Mekanlar tab'ı çalışıyor
- [ ] Galeri full-screen viewer açıyor
- [ ] Puanlar detay sheet'i açıyor
- [ ] Favori toggle çalışıyor (kalp doluyor/boşalıyor)
- [ ] Paylaşım (share_plus) deep link üretiyor

#### Comparison (10 senaryo)
- [ ] 2 üniversite seç → karşılaştırma sonuçları yükleniyor
- [ ] Hero section logoları, VS badge'i, skorlar görünüyor
- [ ] 4 tab (Özet, Kategoriler, İstatistik, Notlar) çalışıyor
- [ ] Pro yoksa "Notlar" tab'ı paywall açıyor
- [ ] Pro var → not ekle/düzenle/sil
- [ ] 3-way: Pro yoksa AppBar buton paywall açıyor
- [ ] Pro var → 3. üni seç → sonuç ekranı 3'lü render
- [ ] Share (ios_share) image paylaşımı
- [ ] Reset → seçimleri temizliyor
- [ ] History → eski karşılaştırmaları listeliyor

#### Reviews (5 senaryo)
- [ ] Yorum yaz açılıyor
- [ ] Tüm kategori puanları zorunlu
- [ ] Anonim toggle çalışıyor
- [ ] Submit → success snackbar → my reviews'da görünüyor
- [ ] Like/dislike çalışıyor

#### Places (4 senaryo)
- [ ] Mekanlar tab'ı 3 kategoriyi (yurt/kafe/çalışma) gösteriyor
- [ ] Yurt detay sayfası floor plan açılıyor
- [ ] Mekan yorumları çalışıyor
- [ ] Mekan paylaşımı

#### Monetization (6 senaryo)
- [ ] Paywall 3 tier chip + tier-reactive gradient
- [ ] Ücretsiz → "Ücretsiz Devam Et" → pop
- [ ] Plus seç → Aylık/Yıllık card göründü → satın al (sandbox)
- [ ] Pro seç → Aylık/Yıllık card → satın al
- [ ] Restore purchases (önceden satın alan) → tier dönüyor
- [ ] Pro user paywall'a girince "Zaten Pro'sun" mesajı veya direct pop

#### Profile (4 senaryo)
- [ ] Profil görüntüle (premium status, sayılar)
- [ ] Profili düzenle (foto, ad, bio)
- [ ] Dil değiştir (TR ↔ EN)
- [ ] Tema (Auto/Light/Dark)

#### Cross-cutting (5 senaryo)
- [ ] Dark mode tüm ekranlarda görünüyor (manuel her ekran tıkla)
- [ ] Wi-Fi kapalı → offline banner / cached data
- [ ] Push notification permission isteme akışı
- [ ] Deep link (https://unisec.app/university/<id>) doğru ekranı açıyor
- [ ] App background → foreground geri dönüş smooth

### 10.3 Cihaz matrisi

| Cihaz | Android sürüm | Kullanım |
|-------|---------------|----------|
| Pixel 7 emulator | 13 | Geliştirme + screenshot çekimi |
| Samsung Galaxy A-serisi (gerçek) | 12 | Mid-tier performans testi |
| Xiaomi düşük sınıf (gerçek veya emulator) | 11 | Düşük bellek testi |
| Tablet emulator (Pixel Tablet) | 14 | Geniş ekran layout testi (opsiyonel) |

### 10.4 Beta dağıtım

- **Internal Testing:** Gün 17 başlangıç, sadece takım (3-5 kişi).
- **Closed Testing:** Gün 19 başlangıç, 5-10 davetli tester.
- **Production:** Gün 21 başlangıç, %20 staged.

---

## 11. Play Store Hazırlık Checklist'i

40 adımlık tam liste. Her madde tickli olunca yayına hazırız.

### A. Code Side
- [ ] Versioning: `pubspec.yaml` version `1.0.0+1`
- [ ] `flutter analyze` 0 issue
- [ ] `flutter test` tüm testler pass
- [ ] Tüm Firestore rules deploy edildi
- [ ] Tüm Cloud Functions deploy edildi
- [ ] RevenueCat product ID'ler production'da
- [ ] AdMob test ID'ler production ID'lerle değiştirildi
- [ ] Crashlytics global handler eklendi
- [ ] firebase_options.dart production project'i pointing

### B. Build Konfigürasyonu
- [ ] `android/app/build.gradle.kts`: applicationId = `com.unisec.app`
- [ ] minSdk 21+, targetSdk 34+ (Play Store şartı)
- [ ] versionCode 1, versionName `1.0.0`
- [ ] `release` signing config gerçek keystore'a bağlı
- [ ] `key.properties` gitignore'da, repo'da değil
- [ ] Keystore yedeği güvenli yerde (1Password / encrypted disk)
- [ ] ProGuard `-keep` kuralları: Firebase, Crashlytics, RevenueCat
- [ ] minifyEnabled + shrinkResources true (release)

### C. AndroidManifest.xml
- [ ] `android:label` = "UniSeç"
- [ ] `android:icon` = `@mipmap/ic_launcher`
- [ ] `android:allowBackup="false"` (KVKK + auth/payments hassasiyeti)
- [ ] `android:fullBackupContent` ayarlandı veya scope yok
- [ ] Permissions: sadece `INTERNET`, `POST_NOTIFICATIONS` (varsa
      `READ_MEDIA_IMAGES` for image picker)
- [ ] Deep link intent-filter doğru host (`unisec.app`)

### D. Assets
- [ ] App icon (mipmap-mdpi → xxxhdpi) generate edildi
- [ ] Adaptive icon (`mipmap-anydpi-v26/ic_launcher.xml`) generate edildi
- [ ] Splash screen branded (light + dark + Android 12+ variant)
- [ ] Launch background drawable doğru

### E. Play Console
- [ ] App oluşturuldu
- [ ] Default language: tr-TR
- [ ] **Store listing TR:**
  - [ ] App name: UniSeç
  - [ ] Short description (80 char)
  - [ ] Full description (4000 char)
  - [ ] App icon 512×512
  - [ ] Feature graphic 1024×500
  - [ ] Screenshot 1-8 (1080×2400 phone, opsiyonel tablet)
- [ ] **Store listing EN:**
  - [ ] Tüm yukarıdakiler İngilizce
- [ ] **App content:**
  - [ ] Privacy policy URL (https://unisec.app/privacy)
  - [ ] App access (login required mı?)
  - [ ] Ads (var → AdMob)
  - [ ] Content rating questionnaire (Education, low-risk)
  - [ ] Target audience: 13+ (ergenlik üstü)
  - [ ] News app? Hayır
  - [ ] COVID-19 app? Hayır
  - [ ] Data safety form:
    - [ ] Personal info: Email, name (collected, encrypted in transit,
          user can delete)
    - [ ] Photos: Profile picture (optional, collected, encrypted)
    - [ ] User-generated content: Reviews, ratings (collected, public)
    - [ ] App activity: Page views (Analytics)
    - [ ] App info & performance: Crash logs (Crashlytics)
    - [ ] Device IDs: FCM token (for notifications)
- [ ] **Pricing & distribution:**
  - [ ] Free app
  - [ ] In-app purchases: yes (RevenueCat)
  - [ ] Countries: Turkey + global
  - [ ] Contains ads: yes
- [ ] **App signing:**
  - [ ] Google Play App Signing enabled (Google rotates signing key)

### F. Testing tracks
- [ ] Internal testing track AAB upload (1.0.0+1)
- [ ] Internal tester emails added
- [ ] Closed testing track AAB upload (1.0.0+2 veya üstü)
- [ ] Closed tester opt-in link paylaşıldı

### G. Production
- [ ] Production track release notes (TR + EN)
- [ ] Staged rollout %20 ile başla
- [ ] Pre-launch report (Play Console auto-test) temiz
- [ ] Final AAB upload
- [ ] "Submit for review" clicked

### H. Post-submission
- [ ] Crashlytics dashboard izleme açık
- [ ] Analytics events flowing
- [ ] RevenueCat dashboard production mode
- [ ] %20 → %50 (24-48 saat sonra crash < 1%)
- [ ] %50 → %100 (48-72 saat sonra)

---

## 12. Yayın Günü Runbook'u

> Gün 21'in adım adım planı. Her madde tikledikten sonra bir sonrakine geç.

### T-2 saat (sabah 09:00)

**Kişi A:**
- [ ] Slack'te "Launch günü, başlıyoruz" mesajı
- [ ] Crashlytics dashboard aç, son 48 saat temiz mi kontrol
- [ ] Play Console > Internal testing > son build crash-free mi
- [ ] Store listing TR ve EN final review

**Kişi B:**
- [ ] `git status` temiz mi?
- [ ] `git checkout release/v1.0.0 && git pull`
- [ ] Son fix commit'leri var mı?
  ```bash
  git log --oneline develop ^release/v1.0.0
  ```
  Varsa cherry-pick et release branch'e
- [ ] `flutter clean && flutter pub get`
- [ ] `flutter analyze` 0 issue
- [ ] `flutter test`

### T-1 saat (10:00)

**Kişi B:**
- [ ] versionCode'u son haline getir (gün 18-20'de increment olmuştu, son
      değeri pubspec.yaml'da, örn. `1.0.0+5`)
- [ ] Production build:
  ```bash
  flutter build appbundle --release
  ```
- [ ] AAB dosya boyutu < 35 MB?
  ```bash
  ls -lh build/app/outputs/bundle/release/app-release.aab
  ```
- [ ] AAB'yi son bir kez kendi telefonuna `bundletool`'la install et:
  ```bash
  bundletool build-apks --bundle=app-release.aab --output=app.apks \
    --ks=~/secure/unisec_upload.jks --ks-pass=pass:<pwd> \
    --ks-key-alias=upload --key-pass=pass:<pwd>
  bundletool install-apks --apks=app.apks
  ```

### T-0 (Submit, 11:00)

**Kişi A:**
- [ ] Play Console > Production track aç
- [ ] "Create new release" tıkla
- [ ] AAB'yi yükle (B'nin paylaştığı dosya)
- [ ] Release notes (TR + EN) yapıştır
- [ ] Staged rollout: **20%** seç
- [ ] "Review release" → "Start rollout to production"

### T+0 (review bekleme)

- Google review tipik 1-3 saat (basit MVP).
- Onay sonrası Play Store'da görünür hale gelir.
- Kullanıcılar bildirilmez, organik discovery (search "UniSeç").

### T+1 saat: Lansman tetiği

**Onay alındığında:**

**Kişi A:**
- [ ] Sosyal medya postu hazır mı? (Twitter/X, Instagram, LinkedIn)
- [ ] Üniversite öğrenci forumları / Reddit r/Turkey, r/UniversityTurkey
      paylaşımı (mümkünse)
- [ ] WhatsApp grupları (ekibe, dostlara)

**Kişi B:**
- [ ] Git tag oluştur ve push:
  ```bash
  git checkout main
  git merge --no-ff release/v1.0.0
  git tag -a v1.0.0 -m "v1.0.0 - First production release 🚀"
  git push origin main --tags
  ```
- [ ] develop'e backport:
  ```bash
  git checkout develop
  git merge --no-ff release/v1.0.0
  git push origin develop
  ```
- [ ] release/v1.0.0 branch'i sil:
  ```bash
  git branch -d release/v1.0.0
  git push origin --delete release/v1.0.0
  ```
- [ ] GitHub release oluştur (tag → release notes)

### T+4 saat (akşam, 17:00)

- [ ] Crashlytics dashboard: kaç session, kaç crash?
- [ ] Analytics: install rate, retention day-0
- [ ] Beta tester'larla "Production'dan indirebilirsiniz" haber

### T+24 saat

- [ ] Crash-free user rate > %99? → %20 rollout %50'ye çıkar
- [ ] Crash > %1 ise → durdur, fix, hotfix release

### T+48 saat

- [ ] Crash-free rate > %99.5? → %50 → %100
- [ ] İlk 100 kullanıcı feedback'i monitor et

---

## 13. Post-Launch İzleme ve Destek

### İlk 72 saat (hyper-care mode)

**Crashlytics izleme:**
- Her sabah ve akşam dashboard kontrol
- Yeni crash event → 24 saat içinde fix değerlendirme

**Analytics event'leri (production'da takip edilmeli):**
- `app_open`
- `sign_in_completed` (method: google/email)
- `university_view` (uni_id)
- `comparison_started` (mode: 2way/3way)
- `comparison_completed`
- `review_submitted` (uni_id, anonymous)
- `paywall_viewed`
- `purchase_started` (tier, billing)
- `purchase_completed` (tier, billing)
- `restore_attempted`

Eksikleri B'nin Gün 6'da `event_inventory.md` doc'ında listelemesi gerekiyor.

**Performance Monitoring (Firebase):**
- Aktifleştir → `firebase_performance` paketi pubspec'te yoksa ekle
- Cold start time, screen rendering time izle

### Hafta 1 retrospektif (Gün 28)

- Sprint 5'i değerlendir:
  - Hangi günler planın gerisinde kaldı?
  - En büyük conflict noktası neydi?
  - En değerli polish hangisiydi?
- v1.1 backlog'u güncelle

### Hotfix prosedürü

Production'da P0 bug çıkarsa:

1. `git checkout main && git pull`
2. `git checkout -b hotfix/v1.0.1-<short-desc>`
3. Fix + commit + push
4. PR aç → main'e ve develop'e merge
5. versionCode increment, versionName 1.0.1
6. `flutter build appbundle --release`
7. Play Console → Production → Yeni release → tüm kullanıcılar (%100)
8. Tag: `v1.0.1`

---

## 14. Öneriler ve İyileştirmeler (v1.1 Backlog)

Sprint 5'e dahil olmayan, v1.1 için tutulan öneriler. Gün 28
retrospektif'te önceliklendir.

### Yüksek değer
- **iOS sürümü** — Apple Developer hesabı + Xcode build + TestFlight + App Store Connect. ~2-3 hafta.
- **App Check (Firebase Anti-Abuse)** — Cloud Functions ve Firestore'a sahte
  istek koruması. ~1 gün entegrasyon.
- **Cloud Functions rate limiting** — yorum spam'ini engelle. ~2 gün.
- **AdMob GDPR/CCPA consent flow** — `google_mobile_ads` UMP SDK ile. ~1 gün.
- **Performance monitoring** — Firebase Performance + custom traces. ~1 gün.
- **`department_scores.json` Firestore'a taşı** — APK boyutu 0.5MB azalır, lazy
  load + cache. ~1 gün.

### Orta değer
- **CI/CD pipeline (GitHub Actions)** — push → analyze + test, tag → AAB
  build + Play Console upload. ~2 gün.
- **A/B testing** — Firebase Remote Config + Analytics. Paywall metni A/B.
- **Onboarding skip A/B** — daha hızlı time-to-value mu?
- **Refund automation** — RevenueCat webhook → Firestore subscription
  güncelle. ~1 gün.
- **Email magic link auth** (parolasız) — ~2 gün.
- **In-app messaging** — Firebase In-App Messaging ile launch promo. ~1 gün.

### Düşük değer / nice-to-have
- **Reddit/Twitter community share kampanyası** — organik launch.
- **Üniversite hakkındaki bildirimlere abone olma** — Cloud Messaging
  topic-based + UI.
- **Dashboard admin UI** — moderasyon panel (web). ~1 hafta.
- **Web build (PWA)** — Flutter web zaten destekleniyor, asset adapter
  yazılması gerek. ~1 hafta.
- **Apple Sign-in** (iOS launch'tan sonra).

### Tech debt cleanup
- 140+ widget dosyasında const constructor adoption pass
- `places/widgets/dorm_room_floor_plan.dart` → semantik enum'a refactor (Gün
  4'te başlandı, finish'i v1.1)
- L10n'da kalan ~30 hardcoded string
- Riverpod kod gen migration (`@riverpod` decorator) — daha tip güvenli
- Const Color literal'ları AppColors helper'a sarma (DartLint ile enforce)

---

## 15. Risk Matrisi ve Önlemler

| Risk | Olasılık | Etki | Önlem | Sorumlu |
|------|----------|------|-------|---------|
| Branch conflict (A↔B aynı dosya) | Orta | Orta | Dosya sahipliği matrisi (§4) + günlük standup | İkisi |
| `comparison_uni_picker.dart` conflict çözülmemiş | **Yüksek** | Orta | Gün 1 sabahı ilk iş | A |
| Triple comparison v1.0'a geç | Orta | Yüksek | Gün 7'de freeze, gecikirse v1.1 | B |
| Release signing config bozuk | Orta | **Çok Yüksek** | Gün 16 detaylı test, Gün 17 internal upload erken | B |
| Keystore kaybı | Düşük | **Felaket** | 1Password yedek, encrypted disk yedek | B |
| Google review reddi | Düşük | Yüksek | Data Safety form + privacy policy önceden hazır | A |
| Beta'da kritik bug bulundu | Yüksek | Orta | Gün 18, 20'de rezerv bandı | İkisi |
| RevenueCat sandbox vs prod karışıklığı | Orta | Yüksek | Gün 16-17 production key migration | B |
| Crashlytics gizli crash production'da | Orta | Yüksek | İlk 72 saat hyper-care + staged rollout | İkisi |
| AdMob "test ID kalmış" warning | Düşük | Orta | Gün 19 production ID swap | B |
| Privacy policy URL erişilemez | Düşük | Yüksek | Gün 16 site doğrulama | A |
| Performans regresyonu (release vs debug) | Düşük | Orta | Gün 12 profile build measure | B |
| L10n eksiklik → kullanıcı kafa karışıklığı | Düşük | Düşük | Gün 14 review | İkisi |
| App size > 50MB → Play Store delivery uyarısı | Düşük | Düşük | Gün 12 build size analyze | B |
| Cihaz uyumsuzluk (eski Android) | Orta | Orta | Gerçek cihaz test (mid-low tier) Gün 14 | A |
| Network security (cleartext) | Çok düşük | Çok düşük | Default Android 9+ OK | — |

### Kararı çağırılacak durumlar

**"Çık vs Bekle" karar matrisi:**

Eğer Gün 21'de:
- ✅ Crashlytics son 7 gün 0 crash → ÇIK
- ⚠️ Son 7 gün 1-2 minor crash → ÇIK, hotfix hazırlığı paralel
- ❌ Son 24 saatte P0 crash → BEKLE, fix, gün 22 çık

---

## Ek A: PR Template

`.github/pull_request_template.md` oluştur:

```markdown
## Ne yapıyor?

<!-- 1-2 cümle özetle. -->

## Neden?

<!-- Hangi sorunu çözüyor? Hangi sprint görevini kapsıyor? -->

## Etkilenen Dosyalar/Modüller

- [ ] Tek feature alanı (sahiplik matrisine uyuyor)
- [ ] Paylaşılan dosya değiştirildi → karşı tarafa haber verildi
- [ ] Yeni dependency eklendi → pubspec onaylı

## Test

- [ ] `flutter analyze` 0 issue
- [ ] `flutter test` geçiyor
- [ ] Manuel olarak gerçek cihazda test edildi
- [ ] Dark mode test edildi
- [ ] Light mode test edildi

## Ekran görüntüsü (UI değişiklikleri için)

<!-- Drag & drop ya da link -->

## Risk

<!-- Bu PR'ın breaking olduğu/olmadığı senaryolar. -->

## Reviewer notes

<!-- Reviewer'ın özellikle dikkat etmesi gereken yerler. -->
```

---

## Ek B: Commit Konvansiyonu

[Conventional Commits](https://www.conventionalcommits.org/) temelli:

```
<tip>(<scope>): <kısa açıklama>

[opsiyonel body — neden]

[opsiyonel footer — issue ref]
```

**Tipler:**
- `feat` — yeni özellik
- `fix` — bug fix
- `refactor` — kod yapısı değişimi, davranış aynı
- `perf` — performans iyileştirme
- `style` — formatting, lint
- `docs` — dokümantasyon
- `test` — test ekleme/değişikliği
- `chore` — config, dependency, infra
- `i18n` — l10n / çeviri

**Örnekler:**
```
feat(comparison): add triple comparison feature gate
fix(paywall): dismiss bottom sheet on free tier select
perf(places): convert ListView to ListView.builder
chore(android): configure release signing
i18n(profile): extract hardcoded TR strings to ARB
```

---

## Ek C: Play Console Store Listing Metinleri

### TR — App Name
```
UniSeç — Üniversite Karşılaştırma
```

### TR — Short description (80 char max)
```
Türkiye'deki üniversiteleri karşılaştır, doğru bölümü ve şehri seç.
```

### TR — Full description (4000 char max)
```
UniSeç, üniversite tercih sürecindeki öğrencilere yöneliktir.

🎓 Öne Çıkan Özellikler

- Üniversite Karşılaştırma: 2 veya 3 (Pro) üniversiteyi yan yana karşılaştır.
  Puanlar, kontenjan, kategori başarısı, sosyal yaşam ve daha fazlasını
  tek ekranda gör.

- Bölüm Karşılaştırma: Taban puan, başarı sıralaması, yerleşme oranları,
  iş bulma istatistikleri. Aynı bölümün farklı üniversitelerdeki
  performansını ölç.

- Şehir Karşılaştırma: Yaşam maliyeti, ulaşım, eğlence, sosyal hayat,
  güvenlik. Üniversite şehrini seçerken nelere dikkat etmeli?

- Yorumlar ve Değerlendirmeler: Gerçek öğrencilerin değerlendirmelerini
  oku, anonim olarak kendi yorumunu paylaş. Kampüs, eğitim, sosyal hayat,
  yurt ve daha fazlası için kategori bazlı puanlama.

- Mekan Keşfi: Yurtlar, kafeler, çalışma alanları. Detaylı bilgi, fotoğraf,
  öğrenci yorumları.

- Pro Üyelik:
  • 3 üniversiteyi aynı anda karşılaştır
  • Kişisel notlar ekle (arşivlenir, asla kaybolmaz)
  • AI destekli akıllı özet ve öneri
  • Reklamsız deneyim
  • Sınırsız karşılaştırma

🌙 Tasarım

- Dark mode ile gözlerini yorma
- Modern, hızlı arayüz
- Türkçe ve İngilizce dil desteği

🔒 Gizlilik

- Verilerin sadece sana ait
- Anonim yorum seçeneği
- KVKK uyumlu
- Hesabını istediğin zaman silebilirsin

📝 Kimler İçin?

- Üniversite tercih dönemindeki YKS adayları
- Yatay/dikey geçiş düşünen öğrenciler
- Yurt dışı eğitimi alıp ülkeye dönmek isteyenler
- Mevcut öğrencilik deneyimini paylaşmak isteyen üniversite öğrencileri

UniSeç — geleceğin için doğru karar.

unisec.app — destek için info@unisec.app
```

### EN — App Name
```
UniSec — Compare Universities
```

### EN — Short description (80 char max)
```
Compare universities, departments and cities in Turkey. Find your fit.
```

### EN — Full description (4000 char max)
```
UniSec helps prospective university students in Turkey make an informed choice.

🎓 Key Features

- University Comparison: Compare 2 (or 3 with Pro) universities side-by-side.
  See scores, capacities, category strengths, social life and more in one view.

- Department Comparison: Score thresholds, rank, placement rates, post-grad
  employment stats. Compare the same department across universities.

- City Comparison: Cost of living, transport, entertainment, safety. Picking
  a university also means picking a city.

- Reviews and Ratings: Read real student reviews, share your own anonymously.
  Category-based ratings for campus, education, social life, dorms and more.

- Discover Places: Dormitories, cafés, study spaces with details, photos and
  student reviews.

- Pro Membership:
  • Compare 3 universities at the same time
  • Add personal notes (saved, never lost)
  • AI-powered smart summaries and recommendations
  • Ad-free experience
  • Unlimited comparisons

🌙 Design

- Dark mode for eye comfort
- Modern, fast UI
- Turkish and English language support

🔒 Privacy

- Your data is yours
- Anonymous review option
- GDPR & KVKK compliant
- Delete your account anytime

📝 Who is it for?

- High school students preparing for the YKS exam
- Students considering horizontal/vertical transfers
- Returnees from abroad
- Current students sharing their experience

UniSec — make the right choice for your future.

unisec.app — info@unisec.app
```

### Release notes (TR)
```
🎉 İlk sürüm!

- Üniversite, bölüm ve şehir karşılaştırma
- Yorum ve değerlendirme sistemi
- Mekan keşfi (yurt, kafe, çalışma alanı)
- Pro üyelik ile 3'lü karşılaştırma, kişisel notlar, AI özet
- Dark mode + Türkçe/İngilizce dil desteği

Geri bildirim için: info@unisec.app
```

### Release notes (EN)
```
🎉 First release!

- Compare universities, departments and cities
- Reviews and ratings system
- Discover places (dorms, cafés, study spots)
- Pro: 3-way comparison, notes, AI summaries
- Dark mode + Turkish/English

Feedback: info@unisec.app
```

---

## Ek D: Komut Cheat Sheet

### Geliştirme

```bash
# Lokal başlat
flutter pub get
flutter run                    # debug
flutter run --profile          # release-like perf
flutter run --release          # tam release build

# Analiz
flutter analyze                # lint + type check
flutter test                   # unit + widget testler
flutter test --coverage        # coverage raporu

# l10n
flutter gen-l10n               # ARB → Dart codegen

# Format
dart format lib/ test/
```

### Build & Release

```bash
# Debug APK
flutter build apk --debug

# Release APK (single)
flutter build apk --release

# AAB (Play Store için zorunlu)
flutter build appbundle --release

# Size analyze
flutter build appbundle --release --analyze-size

# Çıktı path
ls build/app/outputs/bundle/release/app-release.aab
```

### Keystore yönetimi

```bash
# Oluştur (BİR KEZ, yedekle!)
keytool -genkey -v -keystore ~/secure/unisec_upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# İçeriği gör
keytool -list -v -keystore ~/secure/unisec_upload.jks

# Fingerprint (Firebase için)
keytool -list -v -keystore ~/secure/unisec_upload.jks \
  -alias upload | grep -i sha
```

### AAB → APK (local test)

```bash
# bundletool indir: https://github.com/google/bundletool/releases

bundletool build-apks \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=app.apks \
  --ks=~/secure/unisec_upload.jks \
  --ks-pass=pass:<storepass> \
  --ks-key-alias=upload \
  --key-pass=pass:<keypass>

bundletool install-apks --apks=app.apks
```

### Firebase deploy

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only functions
firebase deploy --only hosting       # privacy policy hostuna göre
```

### Git workflow

```bash
# Sprint başı
git checkout develop && git pull
git checkout -b feature/s5-<scope>-<desc>

# Çalış, commit'ler at
git add lib/...
git commit -m "feat(scope): description"

# Push
git push -u origin feature/s5-<scope>-<desc>

# PR sonrası develop güncel olsun
git checkout develop
git pull

# Conflict olursa
git fetch origin
git rebase origin/develop      # tercih: rebase, lineer history

# Release tag
git checkout main
git tag -a v1.0.0 -m "..."
git push origin v1.0.0
```

### Crashlytics (lokal test)

```bash
# Crashlytics force crash (development)
# Dart kodundan: FirebaseCrashlytics.instance.crash();
# Bu sadece release build'de gerçek crash atar.
```

### Performance

```bash
# DevTools aç
flutter pub global activate devtools
flutter pub global run devtools

# Profile build çalıştırırken DevTools açılır otomatik
flutter run --profile
```

---

## Kapanış

Bu plan **yönlendiricidir, kutsal değildir**. Gerçek hayatta her şey
plana göre gitmez. Sprint 5 boyunca her akşam plan'a karşı progress check
yap; gerçekçi değilse plan'ı revize et — ama Definition of Done'dan ödün
verme.

**Sprint 5 sonunda hedef:**
- UniSeç Play Store'da yayında
- v1.0.0 tag'i çekilmiş
- İlk 100 kullanıcı 72 saat içinde
- Crash-free user rate %99+
- v1.1 backlog'u güncel
- Ekibin moral'i yüksek

Başarılar! 🚀

— Plan: Sprint 5 Polish & Yayın
— Yazıldı: 2026-05-13
— Versiyon: 1.0
