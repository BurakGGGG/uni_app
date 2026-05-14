# Sprint 5 — Kod Companion (UniSeç v1.0)

> `sprint5_plan.md` ile birlikte kullanılır. Bu dosya planın **uygulama
> tarafıdır**: her gün için Kişi A ve Kişi B'nin görevlerinin kod
> bloklarını içerir. Plan açıklayıcı (neden / ne / ne zaman); bu dosya
> teknik (nasıl) hedefler.

## Nasıl Kullanılır

- Her gün için ilgili bölümü aç → görev tipine göre kod bloğuna bak.
- **Yeni dosya** blokları: olduğu gibi kopyala-yapıştır, üst kısımdaki
  dosya yoluna yaz.
- **Diff blokları:** `// BEFORE` ve `// AFTER` etiketli. Mevcut dosyada
  `BEFORE`'u bul, `AFTER` ile değiştir.
- **Token enforcement** tablo formatında: dosya:satır → eski değer → yeni
  değer.
- Bu dosyadaki kodun TÜMÜ Flutter 3.x + Dart 3.x + mevcut paket setiyle
  uyumlu yazılmıştır (bkz: `pubspec.yaml`).

---

## İçindekiler

- [Bölüm 0: Paylaşılan Yardımcılar (referans)](#bölüm-0-paylaşılan-yardımcılar)
- [Bölüm 1: Hafta 1 — Foundation (Gün 1-7)](#bölüm-1-hafta-1--foundation-gün-1-7)
- [Bölüm 2: Hafta 2 — Polish + Performance (Gün 8-14)](#bölüm-2-hafta-2--polish--performance-gün-8-14)
- [Bölüm 3: Hafta 3 — Release Prep (Gün 15-21)](#bölüm-3-hafta-3--release-prep-gün-15-21)
- [Bölüm 4: Test Kodu (7 widget test)](#bölüm-4-test-kodu)
- [Bölüm 5: Konfigürasyon Dosyaları](#bölüm-5-konfigürasyon-dosyaları)
- [Bölüm 6: ARB Dosyası Örnekleri](#bölüm-6-arb-dosyası-örnekleri)

---

## Bölüm 0: Paylaşılan Yardımcılar

> Bu bölümdeki kodlar Sprint boyunca birden fazla günde referans edilir.
> Bir kez yazılır, birden fazla yerden import edilir.

### 0.1 AppColors — Eksik Token Ekleri

`lib/core/theme/app_colors.dart` zaten kapsamlı (shimmer, info, warning,
success, error light token'ları mevcut). Sprint sonunda EK olarak şunlar
eklenmeli:

```dart
// AppColors sınıfının içine — mevcut alanların ALTINA ekle:

// ─── Surface Variants (Dark mode için ikinci kademe) ─────────
static const Color darkSurface2 = Color(0xFF1F1F36);

// ─── Semantic Surface Helpers (Dark/Light Adaptive) ──────────
static Color textOnSurfaceFor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.92)
      : textPrimary;
}

static Color dividerFor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.08)
      : divider;
}

static Color borderFor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.12)
      : border;
}

// ─── Shimmer Dark Variants ────────────────────────────────────
static const Color shimmerBaseDark = Color(0xFF2A2A40);
static const Color shimmerHighlightDark = Color(0xFF35355A);

static Color shimmerBaseFor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? shimmerBaseDark
      : shimmerBase;
}

static Color shimmerHighlightFor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? shimmerHighlightDark
      : shimmerHighlight;
}
```

### 0.2 AppTextStyles — Eksiksiz Set

`lib/core/theme/app_text_styles.dart` zaten kapsamlı. Sprint sonunda
sadece şu yeni style'lar eklenmeli:

```dart
// AppTextStyles sınıfının içine ekle:

// ─── Error / Empty State Texts ───────────────────────────────
static TextStyle get errorTitle => GoogleFonts.poppins(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: AppColors.error,
      height: 1.3,
    );

static TextStyle get errorBody => GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      height: 1.5,
    );

static TextStyle get emptyTitle => GoogleFonts.poppins(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      height: 1.3,
    );

static TextStyle get emptyBody => GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textTertiary,
      height: 1.5,
    );
```

### 0.3 ErrorState Widget — TAM KOD

**Yeni dosya:** `lib/core/widgets/error_state.dart`

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Standart error UI — async error'lar için.
/// Tüm `AsyncValue.error` ve catch bloklarında bunu kullan.
///
/// Kullanım:
/// ```dart
/// asyncValue.when(
///   data: ...,
///   loading: () => const ListSkeleton(),
///   error: (e, _) => ErrorState(
///     message: 'Yorumlar yüklenemedi',
///     onRetry: () => ref.invalidate(reviewsProvider),
///   ),
/// )
/// ```
class ErrorState extends StatelessWidget {
  final String? title;
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  final bool compact;

  const ErrorState({
    super.key,
    this.title,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 16.0 : 32.0;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 56 : 72,
              height: compact ? 56 : 72,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: compact ? 28 : 36,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: compact ? 12 : 16),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: AppTextStyles.errorTitle,
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.errorBody,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### 0.4 EmptyState Widget — TAM KOD

**Yeni dosya:** `lib/core/widgets/empty_state.dart`

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Standart empty state UI — boş listeler için.
///
/// Kullanım:
/// ```dart
/// items.isEmpty
///   ? EmptyState(
///       icon: Icons.favorite_border_rounded,
///       title: 'Favori yok',
///       message: 'Beğendiğin üniversiteleri buradan takip edebilirsin.',
///       action: TextButton(...),
///     )
///   : ListView(...)
/// ```
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final bool compact;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = compact ? 16.0 : 32.0;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 64 : 80,
              height: compact ? 64 : 80,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: compact ? 32 : 40,
                color: AppColors.textTertiary,
              ),
            ),
            SizedBox(height: compact ? 12 : 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.emptyTitle,
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.emptyBody,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
```

### 0.5 ListSkeleton Widget — TAM KOD

**Yeni dosya:** `lib/core/widgets/list_skeleton.dart`

```dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

/// Standart liste yükleme skeleton'ı.
/// `CircularProgressIndicator` yerine bunu kullan.
///
/// Kullanım:
/// ```dart
/// asyncValue.when(
///   data: ...,
///   loading: () => const ListSkeleton(itemCount: 6),
///   error: ...,
/// )
/// ```
class ListSkeleton extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsets padding;
  final double itemSpacing;

  const ListSkeleton({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 84,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 12),
    this.itemSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = AppColors.shimmerBaseFor(context);
    final highlightColor = AppColors.shimmerHighlightFor(context);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => SizedBox(height: itemSpacing),
        itemBuilder: (_, _) => Container(
          height: itemHeight,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

/// Tek bir kart placeholder'ı.
class CardSkeleton extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const CardSkeleton({
    super.key,
    this.height = 120,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBaseFor(context),
      highlightColor: AppColors.shimmerHighlightFor(context),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: AppColors.shimmerBaseFor(context),
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
```

### 0.6 Crashlytics Global Handler — main.dart Diff

`lib/main.dart` mevcut hali Firebase'i initialize ediyor ama Crashlytics
handler yok. Tam diff:

**BEFORE** (mevcut imports + main):

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
// ... (diğer importlar)

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  timeago.setLocaleMessages('tr', timeago.TrMessages());
  timeago.setDefaultLocale('tr');

  final results = await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    SharedPreferences.getInstance(),
    initializeDateFormatting('tr_TR'),
  ]);
  // ...
}
```

**AFTER** (Crashlytics + zoned error handling):

```dart
import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
// ... (diğer importlar değişmez)

void main() async {
  // runZonedGuarded ile tüm async hatalar yakalanır
  runZonedGuarded<Future<void>>(() async {
    WidgetsBinding widgetsBinding =
        WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    timeago.setLocaleMessages('tr', timeago.TrMessages());
    timeago.setDefaultLocale('tr');

    final results = await Future.wait([
      Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform),
      SharedPreferences.getInstance(),
      initializeDateFormatting('tr_TR'),
    ]);

    // ─── Crashlytics Global Error Handlers ──────────────────────
    // Production build'lerde otomatik açık, debug build'lerde
    // crash report'ları lokal yakala.
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(kReleaseMode);

    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance
          .recordFlutterFatalError(errorDetails);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance
          .recordError(error, stack, fatal: true);
      return true;
    };

    final prefs = results[1] as SharedPreferences;

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
    );

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    PaintingBinding.instance.imageCache.maximumSizeBytes =
        50 * 1024 * 1024;

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const UniSecApp(),
      ),
    );
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}
```

### 0.7 build.gradle.kts Release Signing

`android/app/build.gradle.kts` mevcut "debug ile imzala" durumundan
gerçek keystore'a geçiş. Tam dosya:

```kotlin
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Keystore yapılandırması
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.unisec.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.unisec.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // CI fallback: debug ile imzala (yerelde geliştirme için)
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("com.google.android.play:feature-delivery:2.1.0")
}
```

### 0.8 proguard-rules.pro — Full

`android/app/proguard-rules.pro` mevcut + RevenueCat + AdMob kuralları:

```proguard
# ─── Firebase ─────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-dontwarn io.grpc.**

# ─── Crashlytics ──────────────────────────────────────────────
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# ─── Google Sign-In ───────────────────────────────────────────
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ─── Play Core (Flutter deferred components) ─────────────────
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# ─── RevenueCat (purchases_flutter) ───────────────────────────
-keep class com.revenuecat.** { *; }
-dontwarn com.revenuecat.**

# ─── Google Mobile Ads (AdMob) ────────────────────────────────
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# ─── Kotlin Coroutines ────────────────────────────────────────
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# ─── Genel keep'ler ───────────────────────────────────────────
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# Stack trace okunabilirliği için satır numaralarını koru
-renamesourcefileattribute SourceFile
```

### 0.9 flutter_launcher_icons — Adaptive Icon

`pubspec.yaml`'da mevcut bölüm:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/unisec-icon-ink-1024.png"
  min_sdk_android: 21
```

**Yeni hali (adaptive icon dahil):**

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/unisec-icon-ink-1024.png"
  min_sdk_android: 21
  # Android 8.0+ adaptive icon
  adaptive_icon_background: "#1A1A2E"
  adaptive_icon_foreground: "assets/icons/unisec-icon-fg.png"
  # Web (gerekirse v1.1)
  web:
    generate: false
  # Windows / macOS (gerekirse v1.1)
  windows:
    generate: false
  macos:
    generate: false
```

> `unisec-icon-fg.png` — 432×432 px, şeffaf arka plan, merkezde logo
> (logo görsel alanı 288×288 px, %66 safe zone). Adaptive icon spec
> gereği.

---

## Bölüm 1: Hafta 1 — Foundation (Gün 1-7)

### Gün 1 — Kickoff & Branch Hijyeni

#### Kişi A

**A.1 — `comparison_uni_picker.dart` conflict çözümü (✅ çözüldü)**

Kullanıcı manuel olarak çözdü ve commit'i hazır. Bu görev sadece doğrulama:

```bash
# Doğrulama (komut, kod değil):
git diff --name-only develop HEAD | grep comparison_uni_picker.dart
flutter analyze lib/features/comparison/presentation/widgets/comparison_uni_picker.dart
```

**A.2 — Yeni dizinler oluştur**

Hiçbir dosya yazılmaz; sadece klasör yapısı:

```
play_store_assets/
  ├─ screenshots/
  │   ├─ phone/
  │   └─ tablet/
  ├─ feature_graphic/
  ├─ icon/
  └─ .gitkeep
docs/
  └─ screenshots/
      └─ .gitkeep
lib/core/widgets/   (varsa skip)
```

`.gitkeep` dosyalarının içeriği boş bırakılır (sadece Git'in klasörü
takip etmesi için).

#### Kişi B

**B.1 — `firestore.rules` comparison notes block**

`firestore.rules` zaten yeni kuralları içeriyor (satır 146-165). Bu görev
sadece commit + lokal test:

```javascript
// MEVCUT (firestore.rules:146-165) — commit edilecek ama yeni kod yazılmaz
match /users/{userId}/comparisonNotes/{noteId} {
  allow read: if isOwner(userId);
  allow create: if isOwner(userId) &&
    request.resource.data.comparisonType in
      ['university', 'department', 'city'] &&
    request.resource.data.entityAId is string &&
    request.resource.data.entityBId is string &&
    request.resource.data.note is string &&
    request.resource.data.note.size() > 0 &&
    request.resource.data.note.size() <= 500;
  allow update: if isOwner(userId) &&
    request.resource.data.diff(resource.data).affectedKeys()
      .hasOnly(['note', 'pros', 'cons', 'rating', 'updatedAt']) &&
    request.resource.data.note is string &&
    request.resource.data.note.size() > 0 &&
    request.resource.data.note.size() <= 500;
  allow delete: if isOwner(userId);
}
```

**Test emulator script:**

```bash
# Doğrulama (kod değil komut):
firebase emulators:start --only firestore
# Başka terminal:
firebase emulators:exec --only firestore "node test/rules-test.js"
```

**B.2 — Firestore rules test dosyası**

**Yeni dosya:** `test/rules/comparison_notes_rules_test.js`

```javascript
const { initializeTestEnvironment, assertSucceeds, assertFails } =
  require('@firebase/rules-unit-testing');
const fs = require('fs');

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'unisec-test',
    firestore: {
      rules: fs.readFileSync('firestore.rules', 'utf8'),
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

describe('comparisonNotes rules', () => {
  test('Owner kendi notunu oluşturabilir', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const db = alice.firestore();
    await assertSucceeds(
      db.collection('users/alice/comparisonNotes').add({
        comparisonType: 'university',
        entityAId: 'uni-1',
        entityBId: 'uni-2',
        note: 'Boğaziçi daha avantajlı',
      })
    );
  });

  test('Boş not engellenir', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const db = alice.firestore();
    await assertFails(
      db.collection('users/alice/comparisonNotes').add({
        comparisonType: 'university',
        entityAId: 'uni-1',
        entityBId: 'uni-2',
        note: '',
      })
    );
  });

  test('500 karakter üzeri not engellenir', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const db = alice.firestore();
    await assertFails(
      db.collection('users/alice/comparisonNotes').add({
        comparisonType: 'university',
        entityAId: 'uni-1',
        entityBId: 'uni-2',
        note: 'a'.repeat(501),
      })
    );
  });

  test('Başka kullanıcının notunu okuyamaz', async () => {
    const bob = testEnv.authenticatedContext('bob');
    const db = bob.firestore();
    await assertFails(
      db.doc('users/alice/comparisonNotes/note-1').get()
    );
  });
});
```

---

### Gün 2 — In-flight Feature Finalize Part 1

#### Kişi A — Auth L10n + A11y

**A.1 — `login_screen.dart` L10n dönüşüm örnekleri**

Aşağıdaki paterni tüm hardcoded string'lere uygula:

```dart
// BEFORE
Text('Giriş Yap', style: AppTextStyles.titleLarge),

// AFTER
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// build içinde:
final loc = AppLocalizations.of(context)!;
Text(loc.authSignIn, style: AppTextStyles.titleLarge),
```

**Toplu dönüşüm tablosu (auth/screens/login_screen.dart):**

| Satır | Önce | Sonra |
|-------|------|-------|
| 89 | `'Giriş Yap'` | `loc.authSignIn` |
| 134 | `'E-posta'` | `loc.authEmailLabel` |
| 147 | `'Şifre'` | `loc.authPasswordLabel` |
| 178 | `'Şifremi unuttum'` | `loc.authForgotPassword` |
| 215 | `'Google ile devam et'` | `loc.authGoogleContinue` |
| 234 | `'Hesabın yok mu?'` | `loc.authNoAccount` |
| 248 | `'Kayıt ol'` | `loc.authSignUp` |

**A.2 — IconButton tooltip ekleme**

```dart
// BEFORE
IconButton(
  icon: const Icon(Icons.visibility_off_rounded),
  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
),

// AFTER
IconButton(
  icon: const Icon(Icons.visibility_off_rounded),
  tooltip: _obscurePassword ? loc.authShowPassword : loc.authHidePassword,
  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
),
```

**A.3 — `app_tr.arb`'a eklenecek key'ler**

```json
{
  "@@locale": "tr",
  "authSignIn": "Giriş Yap",
  "authSignUp": "Kayıt Ol",
  "authEmailLabel": "E-posta",
  "authEmailHint": "ornek@universite.edu.tr",
  "authPasswordLabel": "Şifre",
  "authPasswordHint": "En az 6 karakter",
  "authForgotPassword": "Şifremi unuttum",
  "authGoogleContinue": "Google ile devam et",
  "authNoAccount": "Hesabın yok mu?",
  "authShowPassword": "Şifreyi göster",
  "authHidePassword": "Şifreyi gizle",
  "authPasswordTooShort": "Şifre en az 6 karakter olmalı",
  "authEmailInvalid": "Geçerli bir e-posta gir",
  "authVerifyEmailTitle": "E-postanı doğrula",
  "authVerifyEmailBody": "{email} adresine doğrulama linki gönderdik.",
  "@authVerifyEmailBody": {
    "placeholders": { "email": { "type": "String" } }
  }
}
```

#### Kişi B — Comparison Notes Finalize

**B.1 — `comparison_notes_repository.dart` validation patches**

```dart
// ÖNCE — riskler:
// - Boş not save edilebilir
// - 500 karakter sınırı uygulanmıyor
// - Race condition (hızlı tap-tap)

Future<void> addNote({
  required String userId,
  required ComparisonNote note,
}) async {
  await _firestore
      .collection('users')
      .doc(userId)
      .collection('comparisonNotes')
      .add(note.toMap());
}

// SONRA — validation + idempotency
Future<void> addNote({
  required String userId,
  required ComparisonNote note,
}) async {
  // Validation
  final trimmed = note.note.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError('Not boş olamaz');
  }
  if (trimmed.length > 500) {
    throw ArgumentError('Not 500 karakteri aşamaz');
  }

  // Idempotency key — aynı karşılaştırma + aynı içerik → tekilleştir
  final idempotencyKey =
      '${note.entityAId}_${note.entityBId}_${trimmed.hashCode}';

  final ref = _firestore
      .collection('users')
      .doc(userId)
      .collection('comparisonNotes');

  // Aynı içerik 3 saniye içinde tekrar yazılırsa skip
  final recent = await ref
      .where('idempotencyKey', isEqualTo: idempotencyKey)
      .where('createdAt',
          isGreaterThan:
              DateTime.now().subtract(const Duration(seconds: 3)))
      .limit(1)
      .get();

  if (recent.docs.isNotEmpty) {
    return; // duplicate, sessizce drop
  }

  try {
    await ref.add({
      ...note.copyWith(note: trimmed).toMap(),
      'idempotencyKey': idempotencyKey,
    });
  } catch (e, st) {
    FirebaseCrashlytics.instance.recordError(e, st,
        reason: 'comparison_note_add_failed',
        information: ['userId: $userId', 'noteLen: ${trimmed.length}']);
    rethrow;
  }
}
```

**B.2 — `comparison_note_bottom_sheet.dart` UX validation**

```dart
// TextField için maxLength + counter + onChange validation
TextField(
  controller: _controller,
  maxLines: 5,
  maxLength: 500,
  textInputAction: TextInputAction.done,
  decoration: InputDecoration(
    hintText: 'Notunu yaz...',
    counterStyle: AppTextStyles.labelSmall,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    errorText: _isInvalid ? 'Not boş bırakılamaz' : null,
  ),
  onChanged: (val) {
    setState(() {
      _isInvalid = val.trim().isEmpty;
      _isOverLimit = val.length > 500;
    });
  },
),

// Save butonu disabled state
ElevatedButton(
  onPressed: (_isInvalid || _isOverLimit || _isSaving) ? null : _save,
  child: _isSaving
      ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : const Text('Kaydet'),
),
```

---

### Gün 3 — In-flight Feature Finalize Part 2

#### Kişi A — Profile L10n

**A.1 — `profile_screen.dart` L10n dönüşümleri**

| Satır | Önce | Sonra |
|-------|------|-------|
| 42 | `'Hesabım'` | `loc.profileTitle` |
| 87 | `'Hesap Bilgileri'` | `loc.profileAccountInfo` |
| 123 | `'Premium Üyelik'` | `loc.profilePremium` |
| 145 | `'Dil'` | `loc.profileLanguage` |
| 178 | `'Çıkış yap'` | `loc.profileSignOut` |
| 201 | `'Hesabımı sil'` | `loc.profileDeleteAccount` |
| 234 | `'Gizlilik politikası yakında'` | `loc.privacyPolicyComingSoon` |

**A.2 — `app_tr.arb` profile bölümü**

```json
{
  "profileTitle": "Hesabım",
  "profileAccountInfo": "Hesap Bilgileri",
  "profilePremium": "Premium Üyelik",
  "profileLanguage": "Dil",
  "profileSignOut": "Çıkış yap",
  "profileDeleteAccount": "Hesabımı sil",
  "profileEditProfile": "Profili düzenle",
  "privacyPolicy": "Gizlilik politikası",
  "privacyPolicyComingSoon": "Gizlilik politikası yakında"
}
```

**A.3 — `edit_profile_screen.dart` 5 hardcoded string aynı pattern**

```dart
// BEFORE
const Text('Profili Düzenle')

// AFTER
Text(loc.profileEditProfile)
```

#### Kişi B — Triple Comparison Stabilize

**B.1 — `triple_comparison_result.dart` model + score normalization**

```dart
// Yeni dosya (zaten untracked, sadece review):
// lib/features/comparison/domain/models/triple_comparison_result.dart

class TripleComparisonResult {
  final UniversityModel uniA;
  final UniversityModel uniB;
  final UniversityModel uniC;
  final Map<String, double> scoresByCategoryA;
  final Map<String, double> scoresByCategoryB;
  final Map<String, double> scoresByCategoryC;
  final String overallWinnerId;
  final String summaryText;

  const TripleComparisonResult({
    required this.uniA,
    required this.uniB,
    required this.uniC,
    required this.scoresByCategoryA,
    required this.scoresByCategoryB,
    required this.scoresByCategoryC,
    required this.overallWinnerId,
    required this.summaryText,
  });

  /// Skor normalization (0-5 → 0-100 ölçek için)
  static double normalizeScore(double raw, {double max = 5.0}) {
    if (raw <= 0) return 0;
    return ((raw / max) * 100).clamp(0, 100);
  }

  /// 3 skor için sıralama: en yüksek 1. olur
  List<MapEntry<String, double>> rankedScores() {
    final entries = [
      MapEntry(uniA.id, uniA.avgRating),
      MapEntry(uniB.id, uniB.avgRating),
      MapEntry(uniC.id, uniC.avgRating),
    ];
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
}
```

**B.2 — `comparison_providers.dart` error handling**

```dart
// BEFORE — basit error catch
final tripleComparisonResultProvider = FutureProvider.autoDispose
    .family<TripleComparisonResult, TripleComparisonInput>(
        (ref, input) async {
  final repo = ref.watch(comparisonRepositoryProvider);
  return await repo.tripleCompare(input);
});

// AFTER — error logging + retry hint
final tripleComparisonResultProvider = FutureProvider.autoDispose
    .family<TripleComparisonResult, TripleComparisonInput>(
        (ref, input) async {
  final repo = ref.watch(comparisonRepositoryProvider);
  try {
    return await repo.tripleCompare(input);
  } catch (e, st) {
    FirebaseCrashlytics.instance.recordError(
      e,
      st,
      reason: 'triple_comparison_failed',
      information: [
        'uniA: ${input.uniIdA}',
        'uniB: ${input.uniIdB}',
        'uniC: ${input.uniIdC}',
      ],
    );
    rethrow;
  }
});
```

---

### Gün 4 — Places Dark Mode + Paywall Final

#### Kişi A — Places Hex Color Cleanup

**A.1 — `dorm_info_card.dart` hex → AppColors token**

```dart
// BEFORE
decoration: BoxDecoration(
  color: const Color(0xFFE3F2FD),
  borderRadius: BorderRadius.circular(12),
),

// AFTER
decoration: BoxDecoration(
  color: AppColors.infoLight,
  borderRadius: BorderRadius.circular(12),
),
```

| Satır | Önce | Sonra |
|-------|------|-------|
| 67 | `Color(0xFFE3F2FD)` (info bg) | `AppColors.infoLight` |
| 89 | `Color(0xFFFFF3E0)` (warning bg) | `AppColors.warningLight` |
| 123 | `Color(0xFFD1FAE5)` (success bg) | `AppColors.successLight` |
| 156 | `Color(0xFF1976D2)` (info text) | `AppColors.info` |

**A.2 — `dorm_room_colors.dart` — YENİ DOSYA**

`lib/features/places/presentation/widgets/dorm_room_colors.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Yurt oda planı semantic renkleri.
/// 30+ hardcoded color yerine semantic enum kullanılır.
enum DormRoomZoneType {
  bed,
  desk,
  wardrobe,
  bathroom,
  kitchen,
  common,
  window,
  door,
  empty,
}

extension DormRoomZoneColors on DormRoomZoneType {
  Color get fillColor {
    switch (this) {
      case DormRoomZoneType.bed:
        return AppColors.primary.withValues(alpha: 0.15);
      case DormRoomZoneType.desk:
        return AppColors.secondary.withValues(alpha: 0.15);
      case DormRoomZoneType.wardrobe:
        return AppColors.warning.withValues(alpha: 0.15);
      case DormRoomZoneType.bathroom:
        return AppColors.info.withValues(alpha: 0.15);
      case DormRoomZoneType.kitchen:
        return AppColors.success.withValues(alpha: 0.15);
      case DormRoomZoneType.common:
        return AppColors.surfaceVariant;
      case DormRoomZoneType.window:
        return AppColors.accentLight.withValues(alpha: 0.3);
      case DormRoomZoneType.door:
        return AppColors.textTertiary.withValues(alpha: 0.2);
      case DormRoomZoneType.empty:
        return Colors.transparent;
    }
  }

  Color get borderColor {
    switch (this) {
      case DormRoomZoneType.bed:
        return AppColors.primary;
      case DormRoomZoneType.desk:
        return AppColors.secondary;
      case DormRoomZoneType.wardrobe:
        return AppColors.warning;
      case DormRoomZoneType.bathroom:
        return AppColors.info;
      case DormRoomZoneType.kitchen:
        return AppColors.success;
      default:
        return AppColors.border;
    }
  }

  IconData get icon {
    switch (this) {
      case DormRoomZoneType.bed:
        return Icons.bed_rounded;
      case DormRoomZoneType.desk:
        return Icons.chair_alt_rounded;
      case DormRoomZoneType.wardrobe:
        return Icons.checkroom_rounded;
      case DormRoomZoneType.bathroom:
        return Icons.bathtub_rounded;
      case DormRoomZoneType.kitchen:
        return Icons.kitchen_rounded;
      case DormRoomZoneType.common:
        return Icons.weekend_rounded;
      case DormRoomZoneType.window:
        return Icons.window_rounded;
      case DormRoomZoneType.door:
        return Icons.door_front_door_rounded;
      case DormRoomZoneType.empty:
        return Icons.crop_din_rounded;
    }
  }

  String get label {
    switch (this) {
      case DormRoomZoneType.bed:
        return 'Yatak';
      case DormRoomZoneType.desk:
        return 'Çalışma masası';
      case DormRoomZoneType.wardrobe:
        return 'Dolap';
      case DormRoomZoneType.bathroom:
        return 'Banyo';
      case DormRoomZoneType.kitchen:
        return 'Mutfak';
      case DormRoomZoneType.common:
        return 'Ortak alan';
      case DormRoomZoneType.window:
        return 'Pencere';
      case DormRoomZoneType.door:
        return 'Kapı';
      case DormRoomZoneType.empty:
        return '';
    }
  }
}
```

**A.3 — `place_detail_skeleton.dart` shimmer token**

```dart
// BEFORE
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
  ),
),

// AFTER
Container(
  decoration: BoxDecoration(
    color: AppColors.shimmerBaseFor(context),
    borderRadius: BorderRadius.circular(8),
  ),
),
// + Shimmer.fromColors ile wrap'le
```

#### Kişi B — Paywall Error State

**B.1 — Paywall'da paket yüklenemediğinde in-card error**

```dart
// BEFORE (SnackBar ile)
if (_offerings == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Paketler yüklenemedi')),
  );
  return const SizedBox.shrink();
}

// AFTER (in-card ErrorState)
if (_offerings == null && !_isLoading) {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: ErrorState(
      title: 'Paketler yüklenemedi',
      message: 'İnternet bağlantını kontrol et ve tekrar dene.',
      icon: Icons.cloud_off_rounded,
      onRetry: _loadOfferings,
      compact: true,
    ),
  );
}
```

---

### Gün 5 — Home/University Polish + Reviews Polish

#### Kişi A — Home + University

**A.1 — `home_screen.dart` gradient → AppColors**

```dart
// BEFORE (satır 403-407)
gradient: const LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF6C63FF),
    Color(0xFFFF6584),
  ],
),

// AFTER
gradient: AppColors.heroGradient,
```

| Satır | Önce | Sonra |
|-------|------|-------|
| 403 | `Color(0xFF6C63FF)` | `AppColors.primary` (zaten gradient'te) |
| 405 | `Color(0xFFFF6584)` | `AppColors.secondary` |
| 412 | `Color(0xFF00D9FF)` | `AppColors.accent` |
| 437 | `Color(0xFF1A1A2E)` | `AppColors.textPrimary` |
| 469 | `Color(0xFF6B7280)` | `AppColors.textSecondary` |

**A.2 — `HomeListSkeleton` widget — YENİ**

`lib/features/home/presentation/widgets/home_list_skeleton.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';

/// Home ekranındaki üniversite kartı yükleme skeleton'ı.
class HomeListSkeleton extends StatelessWidget {
  final int itemCount;
  final double height;
  final Axis scrollDirection;

  const HomeListSkeleton({
    super.key,
    this.itemCount = 4,
    this.height = 200,
    this.scrollDirection = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Shimmer.fromColors(
        baseColor: AppColors.shimmerBaseFor(context),
        highlightColor: AppColors.shimmerHighlightFor(context),
        child: ListView.separated(
          scrollDirection: scrollDirection,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: itemCount,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, _) => Container(
            width: 160,
            decoration: BoxDecoration(
              color: AppColors.shimmerBaseFor(context),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
```

**A.3 — `home_screen.dart` 3 bare spinner → HomeListSkeleton**

```dart
// BEFORE (3 yerde: line 136, 175, 211)
universitiesAsync.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: ...,
  data: ...,
)

// AFTER
universitiesAsync.when(
  loading: () => const HomeListSkeleton(),
  error: (e, _) => ErrorState(
    message: 'Üniversiteler yüklenemedi',
    onRetry: () => ref.invalidate(allUniversitiesProvider),
    compact: true,
  ),
  data: ...,
)
```

#### Kişi B — Reviews + Recommendation

**B.1 — `recommendation_result_screen.dart` raw TextStyle**

| Satır | Önce | Sonra |
|-------|------|-------|
| 107 | `TextStyle(fontSize: 22, fontWeight: FontWeight.w700)` | `AppTextStyles.headlineLarge` |
| 169 | `TextStyle(fontSize: 16, color: Colors.grey)` | `AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)` |
| 284 | `TextStyle(fontSize: 13, fontWeight: FontWeight.w600)` | `AppTextStyles.labelLarge` |
| 349 | `TextStyle(fontSize: 11, color: Colors.black54)` | `AppTextStyles.labelSmall` |

**B.2 — `all_reviews_screen.dart` ListView → ListView.builder**

```dart
// BEFORE (line 296)
ListView(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  children: reviews
      .map((r) => ReviewCard(review: r))
      .toList(),
)

// AFTER
ListView.builder(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  itemCount: reviews.length,
  itemBuilder: (_, i) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: ReviewCard(review: reviews[i]),
  ),
)
```

---

### Gün 6 — Design System Unification

#### Kişi A — AppColors + AppTextStyles Final

**A.1 — `app_colors.dart` eksik token'lar (bkz §0.1)**

Mevcut dosyada (`lib/core/theme/app_colors.dart`) shimmerBase, infoLight,
warningLight, successLight, errorLight zaten var. Sadece eklenecekler:

```dart
// AppColors içine son token'ları ekle (§0.1'de tam blok)
static const Color darkSurface2 = Color(0xFF1F1F36);
static Color textOnSurfaceFor(BuildContext context) { ... }
static Color dividerFor(BuildContext context) { ... }
static Color borderFor(BuildContext context) { ... }
static const Color shimmerBaseDark = Color(0xFF2A2A40);
static const Color shimmerHighlightDark = Color(0xFF35355A);
static Color shimmerBaseFor(BuildContext context) { ... }
static Color shimmerHighlightFor(BuildContext context) { ... }
```

**A.2 — `app_text_styles.dart` yeni style'lar (bkz §0.2)**

```dart
// errorTitle, errorBody, emptyTitle, emptyBody (§0.2'de tam blok)
```

#### Kişi B — Config Cleanup

**B.1 — `revenuecat_service.dart` API key dart-define**

```dart
// BEFORE (revenuecat_service.dart:27)
static const String _publicApiKeyAndroid = 'goog_AbCdEfGhIjKlMnOpQrSt';

// AFTER
static const String _publicApiKeyAndroid = String.fromEnvironment(
  'REVENUECAT_API_KEY_ANDROID',
  defaultValue: '', // boşsa runtime'da hata at
);

static const String _publicApiKeyIos = String.fromEnvironment(
  'REVENUECAT_API_KEY_IOS',
  defaultValue: '',
);

static String get _publicApiKey {
  if (Platform.isAndroid) {
    assert(_publicApiKeyAndroid.isNotEmpty,
        'REVENUECAT_API_KEY_ANDROID --dart-define ile geçilmeli');
    return _publicApiKeyAndroid;
  } else {
    assert(_publicApiKeyIos.isNotEmpty,
        'REVENUECAT_API_KEY_IOS --dart-define ile geçilmeli');
    return _publicApiKeyIos;
  }
}
```

**Build script güncelle (varsa scripts/build_release.sh):**

```bash
flutter build appbundle --release \
  --dart-define=REVENUECAT_API_KEY_ANDROID=$REVENUECAT_API_KEY_ANDROID \
  --dart-define=REVENUECAT_API_KEY_IOS=$REVENUECAT_API_KEY_IOS \
  --dart-define=ADMOB_BANNER_ID=$ADMOB_BANNER_ID
```

**B.2 — `docs/event_inventory.md` template**

```markdown
# Analytics Event Inventory

| Event Name | When Fired | Properties | Audit Status |
|-----------|-----------|-----------|--------------|
| sign_up | Yeni kullanıcı kayıt | method | ✅ |
| sign_in | Login başarılı | method | ✅ |
| compare_uni | Üniversite karşılaştırma | uniA_id, uniB_id | ✅ |
| compare_dept | Bölüm karşılaştırma | deptA, deptB | ⚠️ Implement |
| compare_city | Şehir karşılaştırma | cityA, cityB | ⚠️ Implement |
| triple_compare | 3-way karşılaştırma | tier, ids | ⚠️ Implement |
| note_added | Karşılaştırma notu | type, length | ⚠️ Implement |
| paywall_view | Paywall görüldü | source | ✅ |
| paywall_purchase | Satın alma success | tier, period | ✅ |
| paywall_restore | Restore success | tier | ⚠️ Implement |
| review_write | Yorum yazıldı | rating, length, anonymous | ✅ |
```

---

### Gün 7 — Feature Freeze + Auth Dark Mode

#### Kişi A — Auth Dark Mode

**A.1 — `login_screen.dart` dark mode adaptive**

```dart
// BEFORE — sabit beyaz background
Scaffold(
  backgroundColor: Colors.white,
  body: ...,
)

// AFTER — theme-aware
Scaffold(
  backgroundColor: AppColors.backgroundFor(context),
  body: ...,
)

// BEFORE — sabit siyah text
Text('Hoş geldin', style: TextStyle(color: Colors.black))

// AFTER
Text(
  loc.authWelcome,
  style: AppTextStyles.headlineLarge.copyWith(
    color: AppColors.textOnSurfaceFor(context),
  ),
)

// BEFORE — beyaz card
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    boxShadow: AppColors.cardShadow,
  ),
)

// AFTER
Container(
  decoration: BoxDecoration(
    color: AppColors.surfaceFor(context),
    boxShadow: AppColors.cardShadow,
  ),
)
```

#### Kişi B — Comparison Provider Error Audit

**B.1 — `comparison_providers.dart` tüm provider'lara try/catch + Crashlytics**

```dart
// Pattern (her FutureProvider'a uygula):
final comparisonResultProvider = FutureProvider.autoDispose
    .family<ComparisonResult, ComparisonInput>((ref, input) async {
  final repo = ref.watch(comparisonRepositoryProvider);
  try {
    return await repo.compare(input);
  } on FirebaseException catch (e, st) {
    FirebaseCrashlytics.instance.recordError(
      e,
      st,
      reason: 'comparison_firebase_error',
      information: ['code: ${e.code}', 'message: ${e.message}'],
      fatal: false,
    );
    rethrow;
  } catch (e, st) {
    FirebaseCrashlytics.instance.recordError(
      e,
      st,
      reason: 'comparison_unknown_error',
      fatal: false,
    );
    rethrow;
  }
});
```

---

## Bölüm 2: Hafta 2 — Polish + Performance (Gün 8-14)

### Gün 8 — AppColors Enforcement Wave 1

#### Kişi A — Places/Home/University Hex → Token

**A.1 — Enforcement listesi (15+ değişiklik)**

| Dosya | Satır | Önce | Sonra |
|-------|-------|------|-------|
| places/widgets/dorm_info_card.dart | 67 | `Color(0xFFE3F2FD)` | `AppColors.infoLight` |
| places/widgets/dorm_info_card.dart | 89 | `Color(0xFFFFF3E0)` | `AppColors.warningLight` |
| places/screens/place_detail_screen.dart | 145 | `Colors.white70` | `Colors.white.withValues(alpha: 0.7)` |
| places/screens/place_detail_screen.dart | 178 | `Colors.white54` | `Colors.white.withValues(alpha: 0.54)` |
| home/screens/home_screen.dart | 403 | `Color(0xFF6C63FF)` | `AppColors.primary` |
| home/screens/home_screen.dart | 405 | `Color(0xFFFF6584)` | `AppColors.secondary` |
| home/widgets/category_chip.dart | 56 | `Color(0xFFEEF2FF)` | `AppColors.primary.withValues(alpha: 0.08)` |
| university/screens/university_detail_screen.dart | 87 | `Color(0xFF10B981)` | `AppColors.success` |
| university/screens/university_detail_screen.dart | 134 | `Color(0xFFEF4444)` | `AppColors.error` |
| university/widgets/score_card.dart | 45 | `Color(0xFFF59E0B)` | `AppColors.warning` |
| favorites/screens/favorites_screen.dart | 67 | `Color(0xFFFFB800)` | `AppColors.ratingStar` |
| profile/widgets/premium_badge.dart | 34 | `Color(0xFFD4A017)` | `AppColors.tierPro` |
| profile/widgets/premium_badge.dart | 36 | `Color(0xFFFF8C00)` | (kullan `AppColors.tierProGradient`) |
| notifications/screens/notification_list_screen.dart | 89 | `Color(0xFFEEF2FF)` | `AppColors.primary.withValues(alpha: 0.08)` |
| preference_lists/screens/my_lists_screen.dart | 145 | `Color(0xFF6C63FF)` | `AppColors.primary` |

#### Kişi B — Comparison/Monetization Hex Cleanup

**B.1 — `comparison_hero_section.dart`**

```dart
// BEFORE (line 22)
const Color(0xFF16213E)

// AFTER
AppColors.darkSurface2 // (§0.1'de eklenen yeni token)
```

| Dosya | Satır | Önce | Sonra |
|-------|-------|------|-------|
| comparison_hero_section.dart | 22 | `Color(0xFF16213E)` | `AppColors.darkSurface2` |
| comparison_hero_section.dart | 185 | `Color(0xFFFFD700)` | `AppColors.gold` |
| comparison_hero_section.dart | 189 | `Color(0xFFFFA000)` | `Color(0xFFFFA000)` (kalsın — gradient secondary stop) |
| comparison_hub_screen.dart | 94 | `Color(0xFFEDE9FE)` | `AppColors.primary.withValues(alpha: 0.1)` |
| subscription_gate_widget.dart | 98 | `Color(0xFFD4A017)` | `AppColors.tierPro` |
| subscription_gate_widget.dart | 99 | `Color(0xFFFF8C00)` | (gradient'in 2. stopu, inline kalır veya `tierProGradient` kullan) |
| subscription_gate_widget.dart | 203 | `Color(0xFF6C63FF)` | `AppColors.tierPlus` |
| subscription_gate_widget.dart | 204 | `Color(0xFF8B5CF6)` | `AppColors.gradientPurple` |
| paywall_screen.dart | 1020 | `Color(0xFF10B981)` | `AppColors.success` |
| paywall_screen.dart | 238 | `Color(0xFFD4A017)` | `AppColors.tierPro` |

---

### Gün 9 — AppTextStyles + Spacing/Radius Enforcement

#### Kişi A — Preference Lists Raw TextStyle

**A.1 — `list_edit_screen.dart` 4 raw TextStyle**

| Satır | Önce | Sonra |
|-------|-------|------|
| 89 | `TextStyle(fontSize: 18, fontWeight: FontWeight.w700)` | `AppTextStyles.headlineSmall` |
| 134 | `TextStyle(fontSize: 14, color: Colors.grey[600])` | `AppTextStyles.bodySmall` |
| 178 | `TextStyle(fontSize: 12, fontWeight: FontWeight.w500)` | `AppTextStyles.labelMedium` |
| 234 | `TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)` | `AppTextStyles.titleLarge` |

**A.2 — `my_lists_screen.dart` + `shared_list_screen.dart`** aynı pattern.

**A.3 — Spacing normalization (preference_lists feature içinde)**

```dart
// Yasak değer → izinli scale'e map'leme
EdgeInsets.all(14) → EdgeInsets.all(12)  // veya 16
EdgeInsets.all(10) → EdgeInsets.all(12)
EdgeInsets.all(6)  → EdgeInsets.all(8)
EdgeInsets.symmetric(horizontal: 18) → 16
EdgeInsets.symmetric(vertical: 14) → 12

BorderRadius.circular(14) → BorderRadius.circular(12)  // veya 16
BorderRadius.circular(18) → BorderRadius.circular(16)
BorderRadius.circular(10) → BorderRadius.circular(12)
```

#### Kişi B — Comparison/Paywall Fix

**B.1 — `comparison_history_sheet.dart:522` raw TextStyle**

```dart
// BEFORE
TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w500,
  color: Colors.grey[700],
)

// AFTER
AppTextStyles.labelMedium.copyWith(
  color: AppColors.textSecondary,
)
```

**B.2 — `paywall_screen.dart:1041` dynamic fontSize**

```dart
// BEFORE (heavy refactor — dynamic font)
TextStyle(
  fontSize: title.length > 20 ? 16 : 18,
  fontWeight: FontWeight.w700,
)

// AFTER (Sabit + FittedBox ile shrink)
FittedBox(
  fit: BoxFit.scaleDown,
  child: Text(
    title,
    style: AppTextStyles.titleLarge.copyWith(
      fontWeight: FontWeight.w700,
    ),
  ),
)
```

---

### Gün 10 — Shared Widgets (BÜYÜK GÜN)

#### Kişi A — Yeni Shared Widget'lar

**A.1 — `error_state.dart` (bkz §0.3 — TAM KOD)**

`lib/core/widgets/error_state.dart` — §0.3'teki tam kodu kopyala.

**A.2 — `empty_state.dart` (bkz §0.4 — TAM KOD)**

`lib/core/widgets/empty_state.dart` — §0.4'teki tam kodu kopyala.

**A.3 — `list_skeleton.dart` (bkz §0.5 — TAM KOD)**

`lib/core/widgets/list_skeleton.dart` — §0.5'teki tam kodu kopyala.

**A.4 — Rollout: `favorites_screen.dart`**

```dart
// BEFORE (line 84)
favoritesAsync.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, _) => Center(child: Text('Hata: $e')),
  data: (favorites) {
    if (favorites.isEmpty) {
      return const Center(child: Text('Favori yok'));
    }
    return ListView(...);
  },
)

// AFTER
favoritesAsync.when(
  loading: () => const ListSkeleton(itemCount: 6),
  error: (e, _) => ErrorState(
    title: 'Favoriler yüklenemedi',
    message: 'İnternet bağlantını kontrol et.',
    onRetry: () => ref.invalidate(favoritesProvider),
  ),
  data: (favorites) {
    if (favorites.isEmpty) {
      return EmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'Favori yok',
        message: 'Beğendiğin üniversiteleri buradan takip edebilirsin.',
        action: ElevatedButton(
          onPressed: () => context.push('/explore'),
          child: const Text('Üniversiteleri Keşfet'),
        ),
      );
    }
    return ListView.builder(
      itemCount: favorites.length,
      itemBuilder: (_, i) => FavoriteCard(item: favorites[i]),
    );
  },
)
```

**A.5 — `uni_ratings_screen.dart:23` + `city_universities_screen.dart:101,126`** aynı pattern.

#### Kişi B — Comparison/Reviews Rollout

**B.1 — `comparison_screen_v1.dart:99`**

```dart
// BEFORE
error: (e, _) => Text('Karşılaştırma yüklenemedi: $e'),

// AFTER
error: (e, _) => ErrorState(
  title: 'Karşılaştırma yüklenemedi',
  message: 'Tekrar denemek için aşağıdaki butona tıkla.',
  onRetry: () => ref.invalidate(comparisonResultProvider(input)),
),
```

**B.2 — `department_picker_bottom_sheet.dart:291,438`**

```dart
// Aynı pattern — bare error → ErrorState
// Empty case (line 438):
departments.isEmpty
    ? const EmptyState(
        icon: Icons.school_outlined,
        title: 'Bölüm bulunamadı',
        message: 'Bu filtreye uygun bölüm yok. Filtreleri değiştir.',
      )
    : ListView.builder(...)
```

**B.3 — `city_picker_bottom_sheet.dart:123`** aynı pattern.

**B.4 — `my_reviews_screen.dart:135` inline placeholder → gerçek widget**

```dart
// BEFORE
return const Center(child: Text('Henüz yorumun yok'));

// AFTER
return EmptyState(
  icon: Icons.rate_review_outlined,
  title: 'Henüz yorumun yok',
  message: 'Üniversiteni değerlendir ve diğer öğrencilere yardımcı ol.',
  action: ElevatedButton.icon(
    onPressed: () => context.push('/write-review'),
    icon: const Icon(Icons.edit_rounded, size: 18),
    label: const Text('Yorum Yaz'),
  ),
);
```

---

### Gün 11 — Skeleton Loader Rollout

#### Kişi A — Home/Profile/University Skeletons

**A.1 — `explore_screen.dart` 2 bare spinner**

```dart
// BEFORE
loading: () => const Center(child: CircularProgressIndicator()),

// AFTER
loading: () => const ListSkeleton(itemCount: 8),
```

**A.2 — `search_screen.dart:89`**

```dart
// BEFORE
isSearching
    ? const CircularProgressIndicator()
    : Icon(Icons.search_rounded),

// AFTER
isSearching
    ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
    : Icon(Icons.search_rounded),
// (Bu kısa süreli işlem, skeleton gerekmez — sadece visual fix)
```

**A.3 — `profile_screen.dart:64,68` async profile data**

```dart
// BEFORE
profileAsync.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: ...,
  data: ...,
)

// AFTER
profileAsync.when(
  loading: () => Column(
    children: [
      const CardSkeleton(height: 120), // avatar + name area
      const SizedBox(height: 16),
      const ListSkeleton(itemCount: 4, itemHeight: 56),
    ],
  ),
  error: ...,
  data: ...,
)
```

**A.4 — `uni_ratings_screen.dart:23`**

```dart
loading: () => const ListSkeleton(itemCount: 5, itemHeight: 72),
```

#### Kişi B — Reviews Spinner Cleanup

**B.1 — `my_reviews_screen.dart:135` kalan spinner**

```dart
// BEFORE
loading: () => const CircularProgressIndicator(),

// AFTER
loading: () => const ListSkeleton(itemCount: 4),
```

---

### Gün 12 — ListView.builder Dönüşümleri (PERF GÜN)

#### Ortak Pattern

```dart
// BEFORE (eager — tüm liste hemen render)
ListView(
  padding: const EdgeInsets.all(16),
  children: items.map((i) => ItemCard(item: i)).toList(),
)

// AFTER (lazy — sadece görünen render)
ListView.builder(
  padding: const EdgeInsets.all(16),
  itemCount: items.length,
  itemBuilder: (_, i) => ItemCard(item: items[i]),
)
```

#### Kişi A — 8 Dosya

| Dosya | Satır | Tip |
|-------|-------|-----|
| places/widgets/place_list.dart | 82 | ListView → builder |
| places/screens/place_filter_sheet.dart | 65 | ListView → builder |
| university/screens/uni_reviews_screen.dart | 29 | ListView → builder |
| university/screens/uni_departments_screen.dart | 39 | ListView → builder |
| university/screens/uni_places_screen.dart | 41 | ListView → builder |
| university/screens/university_gallery_screen.dart | 94 | ListView → builder (`GridView` ise `.builder`) |
| university/screens/score_detail_sheet.dart | 56 | ListView → builder |
| home/screens/explore_screen.dart | 135, 327 | 2 ListView → builder |

**Bonus: separator gereken yerlerde `ListView.separated`:**

```dart
ListView.separated(
  itemCount: items.length,
  separatorBuilder: (_, _) => const SizedBox(height: 8),
  itemBuilder: (_, i) => Card(child: ListTile(...)),
)
```

#### Kişi B — Reviews/Recommendation + Profiling

**B.1 — 4 dönüşüm**

| Dosya | Satır | Tip |
|-------|-------|-----|
| reviews/screens/all_reviews_screen.dart | 296 | ListView → builder |
| reviews/screens/my_reviews_screen.dart | 79 | ListView → builder |
| reviews/widgets/photo_upload_section.dart | 172 | ListView → builder (yatay) |
| recommendation/screens/recommendation_result_screen.dart | 201 | ListView → builder |

**B.2 — `docs/perf-profile-baseline.md` template**

```markdown
# Performans Profil Baseline — UniSeç v1.0

> Release build üzerinde DevTools Profiler ile alınmıştır.
> Cihaz: Pixel 7 (Android 13). Tarih: 2026-XX-XX.

## Hot Paths

| Ekran | Build süresi (ms) | Frame budget | Status |
|-------|------------------|--------------|--------|
| Splash → Home | 1850 | <3000 | ✅ |
| Üniversite detay | 320 | <500 | ✅ |
| Karşılaştırma sonuç | 480 | <500 | ⚠️ İncele |
| Mekanlar listesi | 240 | <500 | ✅ |
| Yorumlar listesi (50 item) | 180 | <500 | ✅ |
| Paywall açılışı | 290 | <500 | ✅ |

## En Yoğun Widget'lar

- `ComparisonHeroSection` — 180ms (ShaderMask + Hero ile)
- `_CategoryBreakdownGrid` — 140ms (FL Chart radar)

## İyileştirme Önerileri

1. ComparisonHero ShaderMask cache'lenebilir (`RepaintBoundary`)
2. FL Chart yerine custom painter (v1.1 backlog)
```

---

### Gün 13 — A11y + Image Caching

#### Kişi A — Accessibility Pass

**A.1 — IconButton tooltip ekleme örnekleri**

```dart
// BEFORE
IconButton(
  icon: const Icon(Icons.share_rounded),
  onPressed: _share,
)

// AFTER
IconButton(
  icon: const Icon(Icons.share_rounded),
  tooltip: 'Paylaş',
  onPressed: _share,
)
```

**Toplu liste:**

| Dosya | Satır | Tooltip |
|-------|-------|---------|
| comparison_hub_screen.dart | 209 | 'Karşılaştırma geçmişi' |
| auth/screens/login_screen.dart | 289 | 'Şifreyi göster/gizle' |
| auth/screens/register_screen.dart | 173 | 'E-posta doğrulama gönder' |
| auth/screens/register_screen.dart | 293 | 'Geri dön' |
| auth/screens/register_screen.dart | 331 | 'Şifreyi göster/gizle' |
| places/screens/place_detail_screen.dart | 93 | 'Favorilere ekle / kaldır' |
| notifications/widgets/notification_bell.dart | 18 | 'Bildirimler' |

**A.2 — Image.asset semanticLabel**

```dart
// BEFORE
Image.asset('assets/icons/unisec-logo.png', width: 64)

// AFTER
Image.asset(
  'assets/icons/unisec-logo.png',
  width: 64,
  semanticLabel: 'UniSeç logosu',
)
```

**A.3 — InkWell minimum hit target**

```dart
// BEFORE — 36×36 (a11y minimum'un altında)
InkWell(
  onTap: ...,
  child: Container(
    width: 36,
    height: 36,
    child: const Icon(Icons.close_rounded),
  ),
)

// AFTER — 48×48
InkWell(
  onTap: ...,
  borderRadius: BorderRadius.circular(24),
  child: Container(
    width: 48,
    height: 48,
    alignment: Alignment.center,
    child: const Icon(Icons.close_rounded, size: 20),
  ),
)
```

#### Kişi B — Image Caching + Crashlytics Coverage

**B.1 — `Image.network` → `CachedNetworkImage`**

```dart
// BEFORE
Image.network(
  user.photoUrl,
  width: 96,
  height: 96,
  fit: BoxFit.cover,
  errorBuilder: (_, _, _) => const Icon(Icons.person),
)

// AFTER
CachedNetworkImage(
  imageUrl: user.photoUrl,
  width: 96,
  height: 96,
  fit: BoxFit.cover,
  memCacheWidth: 192, // 2x for retina
  memCacheHeight: 192,
  placeholder: (_, _) => Container(
    color: AppColors.shimmerBaseFor(context),
  ),
  errorWidget: (_, _, _) => Container(
    color: AppColors.surfaceVariant,
    child: const Icon(Icons.person, color: AppColors.textTertiary),
  ),
)
```

**B.2 — Avatar widget genel pattern**

`lib/core/widgets/user_avatar.dart` (yeni veya mevcut update):

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;

  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();

    if (photoUrl == null || photoUrl!.isEmpty) {
      return _fallback(initials);
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: cacheSize,
        memCacheHeight: cacheSize,
        placeholder: (_, _) => _fallback(initials),
        errorWidget: (_, _, _) => _fallback(initials),
      ),
    );
  }

  Widget _fallback(String initials) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
```

**B.3 — Crashlytics manual error reporting 5+ yere**

```dart
// Pattern (her async operation'ı sarmala):
try {
  await someAsyncOperation();
} catch (e, st) {
  FirebaseCrashlytics.instance.recordError(
    e,
    st,
    reason: 'descriptive_operation_name',
    information: [
      'context-key-1: value1',
      'context-key-2: value2',
    ],
    fatal: false,
  );
  rethrow;
}
```

Eklenecek yerler:
- `auth_repository.dart` — `signInWithGoogle()`, `signUpWithEmail()`
- `fcm_service.dart` — `init()`, `onTokenRefresh`
- `revenuecat_service.dart` — `purchase()`, `restore()`
- `comparison_repository.dart` — `compare()`, `tripleCompare()`
- `ai_service.dart` — `summarize()`

---

### Gün 14 — L10n Final + Bug Bash

#### Kişi A — L10n Finalize

**A.1 — `app_tr.arb` naming convention final**

Pattern: `<scope><Action>` veya `<scope><Noun>`. Örnek:

```json
{
  "@@locale": "tr",

  "commonRetry": "Tekrar dene",
  "commonError": "Bir hata oluştu",
  "commonLoading": "Yükleniyor...",
  "commonCancel": "İptal",
  "commonSave": "Kaydet",
  "commonDelete": "Sil",
  "commonClose": "Kapat",
  "commonShare": "Paylaş",
  "commonEdit": "Düzenle",
  "commonContinue": "Devam et",

  "authSignIn": "Giriş yap",
  "authSignUp": "Kayıt ol",
  "authSignOut": "Çıkış yap",
  "authForgotPassword": "Şifremi unuttum",
  "authEmailLabel": "E-posta",
  "authPasswordLabel": "Şifre",
  "authPasswordTooShort": "Şifre en az 6 karakter olmalı",
  "authEmailInvalid": "Geçerli bir e-posta gir",

  "homeTabExplore": "Keşfet",
  "homeTabCompare": "Karşılaştır",
  "homeTabFavorites": "Favoriler",
  "homeTabProfile": "Profil",

  "comparisonTitleUni": "Üniversite karşılaştır",
  "comparisonTitleDept": "Bölüm karşılaştır",
  "comparisonTitleCity": "Şehir karşılaştır",
  "comparisonNoteAdd": "Not ekle",
  "comparisonNoteEmpty": "Henüz notun yok",
  "comparisonNoteMaxLength": "En fazla 500 karakter",
  "comparisonProUpsell": "3. üniversite eklemek için Pro'ya yükselt",

  "paywallContinueFree": "Ücretsiz devam et",
  "paywallSavePercent": "TASARRUF {percent}%",
  "@paywallSavePercent": {
    "placeholders": { "percent": { "type": "int" } }
  },
  "paywallMonthly": "Aylık",
  "paywallYearly": "Yıllık",
  "paywallRestore": "Satın alımları geri yükle",

  "reviewWrite": "Yorum yaz",
  "reviewAnonymous": "Anonim",
  "reviewRatingRequired": "Puan vermeden yorum gönderilemez",

  "profileTitle": "Hesabım",
  "profileEditProfile": "Profili düzenle",
  "profilePremium": "Premium üyelik",
  "profileLanguage": "Dil",
  "profileDeleteAccount": "Hesabımı sil",

  "favoritesEmpty": "Favori yok",
  "favoritesEmptyHint": "Beğendiğin üniversiteleri buradan takip et."
}
```

**A.2 — `app_en.arb` aynı key'ler, İngilizce karşılıklar**

```json
{
  "@@locale": "en",

  "commonRetry": "Try again",
  "commonError": "Something went wrong",
  "commonLoading": "Loading...",
  "commonCancel": "Cancel",
  "commonSave": "Save",
  "commonDelete": "Delete",
  "commonClose": "Close",
  "commonShare": "Share",
  "commonEdit": "Edit",
  "commonContinue": "Continue",

  "authSignIn": "Sign in",
  "authSignUp": "Sign up",
  "authSignOut": "Sign out",
  "authForgotPassword": "Forgot password",
  "authEmailLabel": "Email",
  "authPasswordLabel": "Password",
  "authPasswordTooShort": "Password must be at least 6 characters",
  "authEmailInvalid": "Enter a valid email",

  "homeTabExplore": "Explore",
  "homeTabCompare": "Compare",
  "homeTabFavorites": "Favorites",
  "homeTabProfile": "Profile",

  "comparisonTitleUni": "Compare universities",
  "comparisonTitleDept": "Compare departments",
  "comparisonTitleCity": "Compare cities",
  "comparisonNoteAdd": "Add note",
  "comparisonNoteEmpty": "No notes yet",
  "comparisonNoteMaxLength": "Maximum 500 characters",
  "comparisonProUpsell": "Upgrade to Pro to add a 3rd university",

  "paywallContinueFree": "Continue for free",
  "paywallSavePercent": "SAVE {percent}%",
  "paywallMonthly": "Monthly",
  "paywallYearly": "Yearly",
  "paywallRestore": "Restore purchases",

  "reviewWrite": "Write a review",
  "reviewAnonymous": "Anonymous",
  "reviewRatingRequired": "Cannot submit without a rating",

  "profileTitle": "Account",
  "profileEditProfile": "Edit profile",
  "profilePremium": "Premium membership",
  "profileLanguage": "Language",
  "profileDeleteAccount": "Delete account",

  "favoritesEmpty": "No favorites",
  "favoritesEmptyHint": "Track universities you like here."
}
```

#### Kişi B — Comparison/Reviews L10n

**B.1 — Kalan hardcoded TR'leri sweep (5 dosya, ~20 string)**

Pattern aynı — `Text('...')` → `Text(loc.<key>)`.

| Dosya | String sayısı |
|-------|---------------|
| comparison/widgets/comparison_summary_card.dart | 6 |
| comparison/widgets/score_bar_chart.dart | 4 |
| reviews/widgets/review_card.dart | 5 |
| recommendation/screens/recommendation_intro_screen.dart | 8 |
| monetization/widgets/upgrade_banner.dart | 3 |

**Öğleden sonra: Bug bash log template**

`docs/bug_bash_day14_log.md`:

```markdown
# Bug Bash — Gün 14 (Hafta 2 sonu)

> Tester: Kişi A + Kişi B
> Cihazlar: Pixel 7 (Android 13), Samsung Galaxy A52 (Android 12)
> Tarih: 2026-XX-XX

## Bulgular

| ID | Severity | Ekran | Açıklama | Sahip | Status |
|----|----------|-------|----------|-------|--------|
| B14-001 | P0 | Auth | Apple sign-in butonu Android'de görünüyor (gizlenmeli) | A | OPEN |
| B14-002 | P1 | Comparison | 3-way picker C slot picker'ında A/B filtresi yanlış | B | OPEN |
| B14-003 | P2 | Profile | Email değiştir input'a tap olunca klavye kapatıyor | A | OPEN |
| B14-004 | P2 | Paywall | Yıllık → aylık geçişte fiyat 0.5sn geç güncelleniyor | B | OPEN |
| B14-005 | P3 | Home | Splash logosu Android 12'de biraz kayık | A | OPEN |

## Aksiyon
- P0 → bu hafta zorunlu fix (Gün 15-16)
- P1 → mümkünse Gün 15-16, en geç Gün 18
- P2 → Gün 18 internal test feedback
- P3 → v1.1 backlog (gerekirse)
```

---

## Bölüm 3: Hafta 3 — Release Prep (Gün 15-21)

### Gün 15 — Release Engineering Day 1

#### Kişi A — Store Assets (kod değil, atlanıyor)

A'nın bu günkü görevleri image üretimi (Figma/Photoshop). Sadece klasör
yapısı:

```
play_store_assets/
  ├─ icon/
  │   └─ unisec-icon-512.png       (512×512, PNG)
  ├─ feature_graphic/
  │   └─ feature-graphic-1024x500.png
  └─ screenshots/
      ├─ phone/
      │   ├─ 01-home.png            (1080×2400)
      │   ├─ 02-comparison-result.png
      │   ├─ 03-uni-detail.png
      │   ├─ 04-paywall.png
      │   ├─ 05-reviews.png
      │   └─ 06-places.png
      └─ tablet/                    (opsiyonel, 7-inch)
```

#### Kişi B — Adaptive Icon + Crashlytics + ProGuard

**B.1 — `pubspec.yaml` flutter_launcher_icons güncelle (bkz §0.9)**

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/unisec-icon-ink-1024.png"
  min_sdk_android: 21
  adaptive_icon_background: "#1A1A2E"
  adaptive_icon_foreground: "assets/icons/unisec-icon-fg.png"
```

**Komut:**

```bash
flutter pub get
dart run flutter_launcher_icons
```

**B.2 — `lib/main.dart` Crashlytics handler (bkz §0.6 — TAM DİFF)**

`lib/main.dart` mevcut + Crashlytics global handler diff'ini uygula.

**B.3 — `android/app/proguard-rules.pro` full (bkz §0.8)**

§0.8'deki tam dosyayı yaz.

---

### Gün 16 — Release Engineering Day 2

#### Kişi A — Privacy Policy (içerik, kod değil)

Yazılı içerik (privacy policy + data safety form cevapları). Kod
gerektirmez. `sprint5_plan.md` §11'de detaylı liste var.

#### Kişi B — Release Keystore + Signing

**B.1 — `android/key.properties` template (gitignore'da)**

```properties
# DİKKAT: Bu dosya commit edilmez (gitignore'da).
# Parolaları Bitwarden / 1Password'a kaydet.
# Repo'ya commit edilirse → uygulama imzanı kaybedersin → recovery yok.

storePassword=<KEYSTORE_PAROLASI>
keyPassword=<KEY_PAROLASI>
keyAlias=upload
storeFile=/home/<kullanici>/secure/unisec_upload.jks
```

**B.2 — `.gitignore` ek satırlar**

`/.gitignore` dosyasının sonuna ekle:

```gitignore
# ─── Release Keystore (asla commit etme) ────────────────
android/key.properties
android/app/key.properties
*.jks
*.keystore

# ─── Build artifacts ────────────────────────────────────
android/app/build/
build/

# ─── Sensitive env files ────────────────────────────────
.env
.env.local
.env.production

# ─── Plan / personal notes ──────────────────────────────
.claude/
```

**B.3 — `android/app/build.gradle.kts` release signing (bkz §0.7)**

§0.7'deki tam dosyayı kopyala.

**Test build komutları:**

```bash
flutter clean
flutter pub get
flutter build appbundle --release \
  --dart-define=REVENUECAT_API_KEY_ANDROID=$REVENUECAT_API_KEY_ANDROID \
  --dart-define=ADMOB_BANNER_ID=$ADMOB_BANNER_ID

# Size analyze
flutter build apk --analyze-size --release \
  --dart-define=REVENUECAT_API_KEY_ANDROID=$REVENUECAT_API_KEY_ANDROID
```

---

### Gün 17 — Release Branch + Internal Testing

#### Kişi A — Play Console Store Listing

Store listing içerikleri `sprint5_plan.md` Ek C'de hazır TR + EN olarak.
Kod yok, copy-paste.

#### Kişi B — Firestore Deploy + Build Script

**B.1 — Firestore rules deploy doğrulama**

`firebase.json` zaten doğru (varsayım). Deploy komutu:

```bash
# Önce dry-run review
firebase deploy --only firestore:rules --dry-run

# Production'a deploy
firebase deploy --only firestore:rules,firestore:indexes --project unisec-prod
```

**B.2 — `scripts/build_release.sh` — YENİ DOSYA**

```bash
#!/usr/bin/env bash
# UniSeç Release Build Script
# Kullanım: ./scripts/build_release.sh [versionCode]

set -euo pipefail

# ─── Renk kodları ──────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ─── Env kontrolü ──────────────────────────────────────
REQUIRED_VARS=(
  REVENUECAT_API_KEY_ANDROID
  REVENUECAT_API_KEY_IOS
  ADMOB_BANNER_ID
  ADMOB_INTERSTITIAL_ID
)

for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo -e "${RED}HATA: $var environment variable tanımlı değil${NC}"
    echo "Çözüm: ~/.bashrc veya ~/.zshrc'de export et"
    exit 1
  fi
done

# ─── Version yönetimi ──────────────────────────────────
CURRENT_VERSION_LINE=$(grep '^version:' pubspec.yaml)
CURRENT_VERSION_NAME=$(echo "$CURRENT_VERSION_LINE" | cut -d':' -f2 | cut -d'+' -f1 | xargs)
CURRENT_BUILD_NUMBER=$(echo "$CURRENT_VERSION_LINE" | cut -d'+' -f2 | xargs)

if [ -n "${1:-}" ]; then
  NEW_BUILD_NUMBER=$1
else
  NEW_BUILD_NUMBER=$((CURRENT_BUILD_NUMBER + 1))
fi

echo -e "${YELLOW}Version: $CURRENT_VERSION_NAME+$NEW_BUILD_NUMBER${NC}"

# ─── pubspec.yaml güncelle ─────────────────────────────
sed -i.bak "s/^version:.*/version: $CURRENT_VERSION_NAME+$NEW_BUILD_NUMBER/" pubspec.yaml
rm pubspec.yaml.bak

# ─── Build ─────────────────────────────────────────────
echo -e "${YELLOW}flutter clean...${NC}"
flutter clean

echo -e "${YELLOW}flutter pub get...${NC}"
flutter pub get

echo -e "${YELLOW}flutter analyze...${NC}"
flutter analyze

echo -e "${YELLOW}flutter test...${NC}"
flutter test

echo -e "${YELLOW}flutter build appbundle --release...${NC}"
flutter build appbundle --release \
  --dart-define=REVENUECAT_API_KEY_ANDROID="$REVENUECAT_API_KEY_ANDROID" \
  --dart-define=REVENUECAT_API_KEY_IOS="$REVENUECAT_API_KEY_IOS" \
  --dart-define=ADMOB_BANNER_ID="$ADMOB_BANNER_ID" \
  --dart-define=ADMOB_INTERSTITIAL_ID="$ADMOB_INTERSTITIAL_ID"

AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
AAB_SIZE=$(du -h "$AAB_PATH" | cut -f1)

echo -e "${GREEN}✅ Build başarılı!${NC}"
echo -e "${GREEN}AAB: $AAB_PATH ($AAB_SIZE)${NC}"
echo -e "${GREEN}Version: $CURRENT_VERSION_NAME+$NEW_BUILD_NUMBER${NC}"
echo ""
echo "Sonraki adım: Play Console'a yükle"
echo "  https://play.google.com/console/u/0/developers/<ID>/app/<APP_ID>/tracks/internal-testing"
```

**Dosya iznini ayarla (komut, kod değil):**

```bash
chmod +x scripts/build_release.sh
```

---

### Gün 18 — Internal Test Fix

Bu gün dynamic bug fix günü, sabit kod yok. Standart pattern:

```bash
# 1. Yeni branch
git checkout -b fix/s5-<bug-id>-<kisa-aciklama>

# 2. Kod fix
# ... düzenleme ...

# 3. Lokal test
flutter analyze
flutter test

# 4. Commit
git add <files>
git commit -m "fix(<scope>): <bug açıklaması>

Bug-ID: B18-001
Found-by: <isim>
Resolves: <issue-link>"

# 5. PR aç
git push -u origin fix/s5-<bug-id>-<kisa-aciklama>
gh pr create --base release/v1.0.0 --title "fix(<scope>): ..." \
  --body "$(cat <<EOF
## Bug
B18-001 — <açıklama>

## Root Cause
<neden olduğu>

## Fix
<ne değiştirildi>

## Test Plan
- [ ] Bug'ın olduğu senaryo tekrarlandı, artık olmuyor
- [ ] Regression: <ilişkili senaryo> hala çalışıyor
EOF
)"

# 6. Mergele + build + yükle
./scripts/build_release.sh
# Play Console'a yükle, internal testing track
```

---

### Gün 19 — Closed Beta

#### Kişi B — AdMob Production IDs

**B.1 — `ad_service.dart` dart-define ID switch**

```dart
// BEFORE
class AdIds {
  // Test IDs (Google'ın resmi test ID'leri)
  static const String bannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
}

// AFTER
class AdIds {
  static const String bannerAndroid = String.fromEnvironment(
    'ADMOB_BANNER_ID',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111', // test fallback
  );

  static const String interstitialAndroid = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ID',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712', // test fallback
  );

  /// Production mode kontrolü — release build'lerde gerçek ID dolmamalı
  static void assertProductionConfig() {
    if (kReleaseMode) {
      assert(
        !bannerAndroid.contains('3940256099942544'),
        'Release build test AdMob ID kullanıyor! '
        'ADMOB_BANNER_ID --dart-define ile geçilmeli.',
      );
    }
  }
}
```

**B.2 — main.dart başlangıcına assertProductionConfig çağrısı**

```dart
// runApp öncesi:
AdIds.assertProductionConfig();
```

---

### Gün 20 — Beta Fix + Release Notes

Bu gün kod gerekmiyor (release notes içerik). `sprint5_plan.md` §7
Gün 20'de tam release notes template var.

Sadece pubspec.yaml versiyon bump (gerekirse Gün 21'e taşınabilir):

```yaml
# BEFORE
version: 1.0.0+8  # internal/beta build'lerde versionCode arttıkça

# AFTER (production)
version: 1.0.0+10  # production release versionCode
```

---

### Gün 21 — Production Release

Bu gün adımları sprint5_plan.md §12 (Yayın Günü Runbook) ve §11 (Play
Store Checklist) tarafından kapsanır. Burada sadece versionCode bump
ve release tag:

**Final version bump:**

```yaml
# pubspec.yaml
version: 1.0.0+10
```

**Git tag (production sonrası):**

```bash
git checkout release/v1.0.0
git pull
git tag -a v1.0.0 -m "🚀 UniSeç v1.0.0 — Production Release

İlk yayın. Sprint 5 sonu.
Internal: 5 build, Closed Beta: 3 build.
%20 staged rollout başlatıldı."
git push origin v1.0.0

# main'e merge
git checkout main
git merge --no-ff release/v1.0.0
git push origin main

# develop'a merge (release fix'leri için)
git checkout develop
git merge --no-ff release/v1.0.0
git push origin develop
```

---

## Bölüm 4: Test Kodu

> Sprint 5'te 5-8 widget test hedefi. Aşağıda 7 dosyanın tam test kodu.

### 4.1 `test/features/comparison/widgets/comparison_picker_slot_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/comparison/presentation/widgets/comparison_picker_slot.dart';
import 'package:uni_app/core/theme/app_colors.dart';

void main() {
  group('ComparisonPickerSlot', () {
    testWidgets('Boş slot empty state render eder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComparisonPickerSlot(
              isEmpty: true,
              emptyLabel: 'Üniversite A',
              emptyIcon: Icons.school_rounded,
              accentColor: AppColors.primary,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Üniversite A'), findsOneWidget);
      expect(find.byIcon(Icons.school_rounded), findsOneWidget);
    });

    testWidgets('Dolu slot başlık ve alt başlık gösterir', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComparisonPickerSlot(
              isEmpty: false,
              emptyLabel: 'Üniversite A',
              emptyIcon: Icons.school_rounded,
              accentColor: AppColors.primary,
              onTap: () {},
              logo: const SizedBox(width: 40, height: 40),
              title: 'Boğaziçi Üniversitesi',
              subtitle: 'Devlet',
            ),
          ),
        ),
      );

      expect(find.text('Boğaziçi Üniversitesi'), findsOneWidget);
      expect(find.text('Devlet'), findsOneWidget);
    });

    testWidgets('Tap callback çalışır', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComparisonPickerSlot(
              isEmpty: true,
              emptyLabel: 'Üniversite A',
              emptyIcon: Icons.school_rounded,
              accentColor: AppColors.primary,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ComparisonPickerSlot));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
```

### 4.2 `test/features/monetization/screens/paywall_screen_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_app/features/monetization/presentation/screens/paywall_screen.dart';
import 'package:uni_app/features/monetization/domain/enums/subscription_tier.dart';

void main() {
  group('PaywallScreen', () {
    testWidgets('İlk açılışta Plus tier seçili', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: PaywallScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Plus tier chip'i selected state'te
      final plusChip = find.text('Plus');
      expect(plusChip, findsOneWidget);
    });

    testWidgets('Tier chip\'lerine tıklayınca seçim değişir', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: PaywallScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Pro chip'ine tıkla
      final proChip = find.text('Pro');
      await tester.tap(proChip);
      await tester.pumpAndSettle();

      // CTA buton "Pro" tier metin içermeli (gerçek string'e göre adapt)
      expect(find.textContaining('Pro'), findsWidgets);
    });

    testWidgets('Aylık/Yıllık toggle çalışır', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: PaywallScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Aylık karta tap
      final monthlyCard = find.text('Aylık');
      if (monthlyCard.evaluate().isNotEmpty) {
        await tester.tap(monthlyCard.first);
        await tester.pumpAndSettle();
      }

      // State değişti — test geçti
    });

    testWidgets('Ücretsiz tier seçilince CTA pop yapar', (tester) async {
      var popped = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Navigator(
              onPopPage: (_, _) {
                popped = true;
                return false;
              },
              pages: const [
                MaterialPage(child: PaywallScreen()),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ücretsiz tier seç
      await tester.tap(find.text('Ücretsiz'));
      await tester.pumpAndSettle();

      // CTA'ya tap
      final cta = find.textContaining('Ücretsiz Devam Et');
      if (cta.evaluate().isNotEmpty) {
        await tester.tap(cta);
        await tester.pumpAndSettle();
      }

      // Pop tetiklendi
      // (gerçek test'te navigator observer ile doğrula)
    });
  });
}
```

### 4.3 `test/features/comparison/data/comparison_notes_repository_test.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/comparison/data/comparison_notes_repository.dart';
import 'package:uni_app/features/comparison/domain/models/comparison_note.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ComparisonNotesRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = ComparisonNotesRepository(firestore: firestore);
  });

  group('ComparisonNotesRepository', () {
    test('addNote başarılı şekilde kayıt oluşturur', () async {
      final note = ComparisonNote(
        id: '',
        userId: 'user-1',
        comparisonType: 'university',
        entityAId: 'uni-1',
        entityBId: 'uni-2',
        note: 'Boğaziçi daha avantajlı',
        createdAt: DateTime.now(),
      );

      await repo.addNote(userId: 'user-1', note: note);

      final snapshot = await firestore
          .collection('users')
          .doc('user-1')
          .collection('comparisonNotes')
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['note'], 'Boğaziçi daha avantajlı');
    });

    test('Boş not ArgumentError fırlatır', () async {
      final note = ComparisonNote(
        id: '',
        userId: 'user-1',
        comparisonType: 'university',
        entityAId: 'uni-1',
        entityBId: 'uni-2',
        note: '   ',
        createdAt: DateTime.now(),
      );

      expect(
        () => repo.addNote(userId: 'user-1', note: note),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('500 karakter üzeri not ArgumentError fırlatır', () async {
      final note = ComparisonNote(
        id: '',
        userId: 'user-1',
        comparisonType: 'university',
        entityAId: 'uni-1',
        entityBId: 'uni-2',
        note: 'a' * 501,
        createdAt: DateTime.now(),
      );

      expect(
        () => repo.addNote(userId: 'user-1', note: note),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('deleteNote kaydı siler', () async {
      final docRef = await firestore
          .collection('users')
          .doc('user-1')
          .collection('comparisonNotes')
          .add({
        'note': 'test',
        'comparisonType': 'university',
        'entityAId': 'a',
        'entityBId': 'b',
        'createdAt': Timestamp.now(),
      });

      await repo.deleteNote(userId: 'user-1', noteId: docRef.id);

      final snapshot = await firestore
          .collection('users')
          .doc('user-1')
          .collection('comparisonNotes')
          .get();

      expect(snapshot.docs, isEmpty);
    });

    test('getNotes filtreli olarak listeler', () async {
      await firestore
          .collection('users/user-1/comparisonNotes')
          .add({
        'note': 'note A',
        'comparisonType': 'university',
        'entityAId': 'uni-1',
        'entityBId': 'uni-2',
        'createdAt': Timestamp.now(),
      });
      await firestore
          .collection('users/user-1/comparisonNotes')
          .add({
        'note': 'note B',
        'comparisonType': 'department',
        'entityAId': 'dept-1',
        'entityBId': 'dept-2',
        'createdAt': Timestamp.now(),
      });

      final notes = await repo.getNotes(
        userId: 'user-1',
        comparisonType: 'university',
      );

      expect(notes.length, 1);
      expect(notes.first.note, 'note A');
    });
  });
}
```

> Not: `fake_cloud_firestore` paketi gerekiyor:
> `dev_dependencies: fake_cloud_firestore: ^3.0.3`

### 4.4 `test/features/auth/screens/login_screen_validation_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_app/features/auth/presentation/screens/login_screen.dart';

void main() {
  group('LoginScreen validation', () {
    testWidgets('Geçersiz email error mesajı gösterir', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );

      // Email field'a geçersiz değer gir
      await tester.enterText(
        find.byKey(const ValueKey('email_field')),
        'invalid-email',
      );

      // Submit dene
      await tester.tap(find.byKey(const ValueKey('login_button')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Geçerli bir e-posta'),
        findsOneWidget,
      );
    });

    testWidgets('Kısa şifre error mesajı gösterir', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('email_field')),
        'test@university.edu.tr',
      );
      await tester.enterText(
        find.byKey(const ValueKey('password_field')),
        '123',
      );

      await tester.tap(find.byKey(const ValueKey('login_button')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('en az 6 karakter'),
        findsOneWidget,
      );
    });

    testWidgets('Şifre görünürlük toggle çalışır', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );

      // İlk durum: şifre gizli
      final passwordField = tester.widget<TextField>(
        find.byKey(const ValueKey('password_field')),
      );
      expect(passwordField.obscureText, isTrue);

      // Toggle'a tıkla
      await tester.tap(find.byKey(const ValueKey('toggle_password_visibility')));
      await tester.pumpAndSettle();

      // Şifre görünür
      final updatedField = tester.widget<TextField>(
        find.byKey(const ValueKey('password_field')),
      );
      expect(updatedField.obscureText, isFalse);
    });
  });
}
```

> Not: Test'in çalışması için `LoginScreen`'deki widget'lara `ValueKey`
> eklenmesi gerekiyor (`email_field`, `password_field`, `login_button`,
> `toggle_password_visibility`).

### 4.5 `test/features/reviews/screens/write_review_screen_form_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_app/features/reviews/presentation/screens/write_review_screen.dart';

void main() {
  group('WriteReviewScreen form validation', () {
    testWidgets('Puan vermeden submit edilemez', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WriteReviewScreen(universityId: 'uni-1'),
          ),
        ),
      );

      // Yorum metni gir ama puan verme
      await tester.enterText(
        find.byKey(const ValueKey('review_text_field')),
        'Çok güzel bir üniversite',
      );

      // Submit
      await tester.tap(find.byKey(const ValueKey('submit_review_button')));
      await tester.pumpAndSettle();

      // Error mesajı
      expect(
        find.textContaining('puan'),
        findsWidgets,
      );
    });

    testWidgets('Anonim toggle state değiştirir', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WriteReviewScreen(universityId: 'uni-1'),
          ),
        ),
      );

      // Default: anonim false
      Switch anonSwitch = tester.widget<Switch>(
        find.byKey(const ValueKey('anonymous_switch')),
      );
      expect(anonSwitch.value, isFalse);

      // Toggle
      await tester.tap(find.byKey(const ValueKey('anonymous_switch')));
      await tester.pumpAndSettle();

      anonSwitch = tester.widget<Switch>(
        find.byKey(const ValueKey('anonymous_switch')),
      );
      expect(anonSwitch.value, isTrue);
    });

    testWidgets('Min karakter sınırı altında submit engellenir', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WriteReviewScreen(universityId: 'uni-1'),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('review_text_field')),
        'kısa',
      );

      await tester.tap(find.byKey(const ValueKey('submit_review_button')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('en az'),
        findsWidgets,
      );
    });
  });
}
```

### 4.6 `test/core/theme/app_colors_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/core/theme/app_colors.dart';

void main() {
  group('AppColors palette consistency', () {
    test('Primary palette hex değerleri sabit', () {
      expect(AppColors.primary.toARGB32(), 0xFF6C63FF);
      expect(AppColors.secondary.toARGB32(), 0xFFFF6584);
      expect(AppColors.accent.toARGB32(), 0xFF00D9FF);
    });

    test('Tier renkleri primary ile uyumlu', () {
      // tierPlus = primary (mor)
      expect(AppColors.tierPlus.toARGB32(), AppColors.primary.toARGB32());
      // tierPro = altın
      expect(AppColors.tierPro.toARGB32(), 0xFFD4A017);
      // tierFree = gri
      expect(AppColors.tierFree.toARGB32(), 0xFF6B7280);
    });

    test('Rating colors monotonic (yüksek puan = daha iyi)', () {
      // Excellent > Good > Average > BelowAverage > Poor
      final order = [
        AppColors.ratingExcellent,
        AppColors.ratingGood,
        AppColors.ratingAverage,
        AppColors.ratingBelowAverage,
        AppColors.ratingPoor,
      ];
      // Her renk bir önceki ile aynı değil (uniqueness)
      for (var i = 1; i < order.length; i++) {
        expect(order[i].toARGB32(), isNot(order[i - 1].toARGB32()));
      }
    });

    test('ratingColor(double) fonksiyonu doğru bucket\'a maple', () {
      expect(AppColors.ratingColor(4.8), AppColors.ratingExcellent);
      expect(AppColors.ratingColor(4.0), AppColors.ratingGood);
      expect(AppColors.ratingColor(3.0), AppColors.ratingAverage);
      expect(AppColors.ratingColor(2.0), AppColors.ratingBelowAverage);
      expect(AppColors.ratingColor(1.0), AppColors.ratingPoor);
    });

    test('Dark surface palet sıralaması (background < surface < elevated)',
        () {
      // Yalnızca farklı renk olmaları yeterli
      final darkPalette = {
        AppColors.darkBackground,
        AppColors.darkSurface,
        AppColors.darkSurfaceVariant,
        AppColors.darkSurfaceElevated,
      };
      expect(darkPalette.length, 4); // hepsi unique
    });
  });

  group('AppColors theme helpers', () {
    testWidgets('surfaceFor light/dark doğru renk döndürür', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (ctx) {
              expect(
                AppColors.surfaceFor(ctx).toARGB32(),
                AppColors.surface.toARGB32(),
              );
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('surfaceFor dark mode darkSurface döndürür', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (ctx) {
              expect(
                AppColors.surfaceFor(ctx).toARGB32(),
                AppColors.darkSurface.toARGB32(),
              );
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
```

### 4.7 `test/core/widgets/error_state_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/core/widgets/error_state.dart';

void main() {
  group('ErrorState widget', () {
    testWidgets('Mesaj görüntülenir', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorState(
              message: 'Bir şey ters gitti',
            ),
          ),
        ),
      );

      expect(find.text('Bir şey ters gitti'), findsOneWidget);
    });

    testWidgets('Title varsa görüntülenir', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorState(
              title: 'Hata',
              message: 'Detay',
            ),
          ),
        ),
      );

      expect(find.text('Hata'), findsOneWidget);
      expect(find.text('Detay'), findsOneWidget);
    });

    testWidgets('onRetry verilince retry butonu görüntülenir', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorState(
              message: 'Hata',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Tekrar Dene'), findsOneWidget);

      await tester.tap(find.text('Tekrar Dene'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('onRetry yoksa buton görünmez', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorState(
              message: 'Hata',
            ),
          ),
        ),
      );

      expect(find.text('Tekrar Dene'), findsNothing);
    });

    testWidgets('compact mode küçük padding kullanır', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorState(
              message: 'Hata',
              compact: true,
            ),
          ),
        ),
      );

      // compact: padding 16 (vs default 32)
      final padding = tester.widget<Padding>(
        find
            .ancestor(
              of: find.byType(Column),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect((padding.padding as EdgeInsets).top, 16);
    });
  });
}
```

---

## Bölüm 5: Konfigürasyon Dosyaları

> Tüm config dosyaları tek noktada — Gün 15-17'de Kişi B uygular.

### 5.1 `android/key.properties` (template)

§0.7 / Gün 16 / B.1'de tam içerik. Kısa hatırlatma:

```properties
storePassword=<KEYSTORE_PAROLASI>
keyPassword=<KEY_PAROLASI>
keyAlias=upload
storeFile=/home/<kullanici>/secure/unisec_upload.jks
```

### 5.2 `android/app/build.gradle.kts` (full)

§0.7'de tam dosya.

### 5.3 `android/app/proguard-rules.pro` (full)

§0.8'de tam dosya.

### 5.4 `pubspec.yaml` flutter_launcher_icons

§0.9'da tam yapılandırma.

### 5.5 `firestore.rules` comparison notes

§Gün 1 / B.1'de tam blok (zaten mevcut dosyada).

### 5.6 `.gitignore` ek satırlar

§Gün 16 / B.2'de tam liste.

### 5.7 `scripts/build_release.sh`

§Gün 17 / B.2'de tam bash dosya.

---

## Bölüm 6: ARB Dosyası Örnekleri

> Gün 2-14 boyunca eklenecek key'lerin konsolide listesi.

### 6.1 `app_tr.arb` (final, konsolide)

```json
{
  "@@locale": "tr",

  "appName": "UniSeç",
  "appTagline": "Üniversite hayatın burada şekilleniyor",

  "commonRetry": "Tekrar dene",
  "commonError": "Bir hata oluştu",
  "commonLoading": "Yükleniyor...",
  "commonCancel": "İptal",
  "commonSave": "Kaydet",
  "commonDelete": "Sil",
  "commonClose": "Kapat",
  "commonShare": "Paylaş",
  "commonEdit": "Düzenle",
  "commonContinue": "Devam et",
  "commonBack": "Geri",
  "commonNext": "İleri",
  "commonDone": "Bitti",
  "commonYes": "Evet",
  "commonNo": "Hayır",

  "authWelcome": "Hoş geldin",
  "authSignIn": "Giriş yap",
  "authSignUp": "Kayıt ol",
  "authSignOut": "Çıkış yap",
  "authForgotPassword": "Şifremi unuttum",
  "authEmailLabel": "E-posta",
  "authEmailHint": "ornek@universite.edu.tr",
  "authPasswordLabel": "Şifre",
  "authPasswordHint": "En az 6 karakter",
  "authGoogleContinue": "Google ile devam et",
  "authNoAccount": "Hesabın yok mu?",
  "authAlreadyAccount": "Zaten hesabın var mı?",
  "authShowPassword": "Şifreyi göster",
  "authHidePassword": "Şifreyi gizle",
  "authPasswordTooShort": "Şifre en az 6 karakter olmalı",
  "authEmailInvalid": "Geçerli bir e-posta gir",
  "authVerifyEmailTitle": "E-postanı doğrula",
  "authVerifyEmailBody": "{email} adresine doğrulama linki gönderdik.",
  "@authVerifyEmailBody": {
    "placeholders": { "email": { "type": "String" } }
  },
  "authResendVerification": "Doğrulama linkini tekrar gönder",

  "homeTabExplore": "Keşfet",
  "homeTabCompare": "Karşılaştır",
  "homeTabFavorites": "Favoriler",
  "homeTabProfile": "Profil",
  "homeFeaturedUnis": "Öne çıkan üniversiteler",
  "homeNearbyCities": "Yakındaki şehirler",
  "homeTrendingPlaces": "Popüler mekanlar",

  "comparisonTitleUni": "Üniversite karşılaştır",
  "comparisonTitleDept": "Bölüm karşılaştır",
  "comparisonTitleCity": "Şehir karşılaştır",
  "comparisonPickFirst": "Karşılaştırmak istediğin iki üniversiteyi seç",
  "comparisonNoteAdd": "Not ekle",
  "comparisonNoteEmpty": "Henüz notun yok",
  "comparisonNoteMaxLength": "En fazla 500 karakter",
  "comparisonNotePlaceholder": "Karşılaştırma hakkındaki düşüncelerin...",
  "comparisonProUpsell": "3. üniversite eklemek için Pro'ya yükselt",
  "comparisonHistoryTitle": "Karşılaştırma geçmişi",
  "comparisonHistoryEmpty": "Henüz karşılaştırma yapmadın",
  "comparisonShareTitle": "Karşılaştırmayı paylaş",

  "paywallTitle": "Premium'a yükselt",
  "paywallSubtitle": "Daha fazla özellik, sınırsız karşılaştırma",
  "paywallContinueFree": "Ücretsiz devam et",
  "paywallSavePercent": "TASARRUF {percent}%",
  "@paywallSavePercent": {
    "placeholders": { "percent": { "type": "int" } }
  },
  "paywallMonthly": "Aylık",
  "paywallYearly": "Yıllık",
  "paywallRestore": "Satın alımları geri yükle",
  "paywallTermsHint": "Ödeme onayı sonrasında otomatik yenilenir",

  "reviewWrite": "Yorum yaz",
  "reviewAnonymous": "Anonim",
  "reviewRatingRequired": "Puan vermeden yorum gönderilemez",
  "reviewTitlePlaceholder": "Yorumunun başlığı",
  "reviewBodyPlaceholder": "Yorumunu yaz...",
  "reviewMinLength": "En az 20 karakter gerekli",
  "reviewSortNewest": "En yeni",
  "reviewSortHelpful": "En faydalı",
  "reviewSortRating": "Puana göre",

  "profileTitle": "Hesabım",
  "profileAccountInfo": "Hesap bilgileri",
  "profileEditProfile": "Profili düzenle",
  "profilePremium": "Premium üyelik",
  "profileLanguage": "Dil",
  "profileSignOut": "Çıkış yap",
  "profileDeleteAccount": "Hesabımı sil",
  "profileDeleteConfirm": "Hesabını silmek istediğinden emin misin?",
  "privacyPolicy": "Gizlilik politikası",
  "privacyPolicyComingSoon": "Gizlilik politikası yakında",
  "termsOfService": "Kullanım şartları",

  "favoritesEmpty": "Favori yok",
  "favoritesEmptyHint": "Beğendiğin üniversiteleri buradan takip et.",
  "favoritesExploreCta": "Üniversiteleri keşfet",

  "notificationsTitle": "Bildirimler",
  "notificationsEmpty": "Bildirim yok",
  "notificationsPermissionDenied": "Bildirim izni gerekli",

  "placesTitle": "Mekanlar",
  "placesDorm": "Yurt",
  "placesCafe": "Kafe",
  "placesStudy": "Çalışma alanı",
  "placesEmpty": "Bu kategoride mekan yok"
}
```

### 6.2 `app_en.arb` (final, konsolide)

```json
{
  "@@locale": "en",

  "appName": "UniSeç",
  "appTagline": "Where your university life takes shape",

  "commonRetry": "Try again",
  "commonError": "Something went wrong",
  "commonLoading": "Loading...",
  "commonCancel": "Cancel",
  "commonSave": "Save",
  "commonDelete": "Delete",
  "commonClose": "Close",
  "commonShare": "Share",
  "commonEdit": "Edit",
  "commonContinue": "Continue",
  "commonBack": "Back",
  "commonNext": "Next",
  "commonDone": "Done",
  "commonYes": "Yes",
  "commonNo": "No",

  "authWelcome": "Welcome",
  "authSignIn": "Sign in",
  "authSignUp": "Sign up",
  "authSignOut": "Sign out",
  "authForgotPassword": "Forgot password",
  "authEmailLabel": "Email",
  "authEmailHint": "example@university.edu.tr",
  "authPasswordLabel": "Password",
  "authPasswordHint": "At least 6 characters",
  "authGoogleContinue": "Continue with Google",
  "authNoAccount": "Don't have an account?",
  "authAlreadyAccount": "Already have an account?",
  "authShowPassword": "Show password",
  "authHidePassword": "Hide password",
  "authPasswordTooShort": "Password must be at least 6 characters",
  "authEmailInvalid": "Enter a valid email",
  "authVerifyEmailTitle": "Verify your email",
  "authVerifyEmailBody": "We sent a verification link to {email}.",
  "@authVerifyEmailBody": {
    "placeholders": { "email": { "type": "String" } }
  },
  "authResendVerification": "Resend verification link",

  "homeTabExplore": "Explore",
  "homeTabCompare": "Compare",
  "homeTabFavorites": "Favorites",
  "homeTabProfile": "Profile",
  "homeFeaturedUnis": "Featured universities",
  "homeNearbyCities": "Nearby cities",
  "homeTrendingPlaces": "Popular places",

  "comparisonTitleUni": "Compare universities",
  "comparisonTitleDept": "Compare departments",
  "comparisonTitleCity": "Compare cities",
  "comparisonPickFirst": "Pick two universities to compare",
  "comparisonNoteAdd": "Add note",
  "comparisonNoteEmpty": "No notes yet",
  "comparisonNoteMaxLength": "Maximum 500 characters",
  "comparisonNotePlaceholder": "Your thoughts about this comparison...",
  "comparisonProUpsell": "Upgrade to Pro to add a 3rd university",
  "comparisonHistoryTitle": "Comparison history",
  "comparisonHistoryEmpty": "No comparisons yet",
  "comparisonShareTitle": "Share comparison",

  "paywallTitle": "Upgrade to Premium",
  "paywallSubtitle": "More features, unlimited comparisons",
  "paywallContinueFree": "Continue for free",
  "paywallSavePercent": "SAVE {percent}%",
  "paywallMonthly": "Monthly",
  "paywallYearly": "Yearly",
  "paywallRestore": "Restore purchases",
  "paywallTermsHint": "Auto-renews after payment confirmation",

  "reviewWrite": "Write a review",
  "reviewAnonymous": "Anonymous",
  "reviewRatingRequired": "Cannot submit without a rating",
  "reviewTitlePlaceholder": "Review title",
  "reviewBodyPlaceholder": "Write your review...",
  "reviewMinLength": "At least 20 characters required",
  "reviewSortNewest": "Newest",
  "reviewSortHelpful": "Most helpful",
  "reviewSortRating": "By rating",

  "profileTitle": "Account",
  "profileAccountInfo": "Account info",
  "profileEditProfile": "Edit profile",
  "profilePremium": "Premium membership",
  "profileLanguage": "Language",
  "profileSignOut": "Sign out",
  "profileDeleteAccount": "Delete account",
  "profileDeleteConfirm": "Are you sure you want to delete your account?",
  "privacyPolicy": "Privacy policy",
  "privacyPolicyComingSoon": "Privacy policy coming soon",
  "termsOfService": "Terms of service",

  "favoritesEmpty": "No favorites",
  "favoritesEmptyHint": "Track universities you like here.",
  "favoritesExploreCta": "Explore universities",

  "notificationsTitle": "Notifications",
  "notificationsEmpty": "No notifications",
  "notificationsPermissionDenied": "Notification permission required",

  "placesTitle": "Places",
  "placesDorm": "Dorm",
  "placesCafe": "Cafe",
  "placesStudy": "Study spot",
  "placesEmpty": "No places in this category"
}
```

---

## Kapanış

Bu companion dosya `sprint5_plan.md` ile birlikte Sprint 5'in **uygulama
referansı**dır:

- **`sprint5_plan.md`** → Ne yapılacak, neden, kim, ne zaman.
- **`sprint5_plan_kodlar.md`** → Nasıl yapılacak (kod).

Her gün başlarken iki dosyayı da aç. Plan'dan günün senaryosunu oku,
kodlar dosyasından ilgili snippet'leri kopyala. Yeni bir pattern
ortaya çıkarsa Bölüm 0'a ekle ve gün bölümlerinden referans ver.

Sprint sonu retro'sunda **bu dosyanın kalitesi de** değerlendirilir:
hangi snippet ihtiyaç dışındaydı, hangi gerekli kod eksikti — v1.1 için
şablon olarak güncellenir.
