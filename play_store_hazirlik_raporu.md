# 🚀 ÜniSeç — Play Store Yayınlama Hazırlık Raporu

> **Tarih:** 5 Haziran 2026  
> **Proje:** ÜniSeç — Üniversite Yaşam Rehberi  
> **Versiyon:** 1.0.0+1 (`com.unisec.app`)  
> **Dart Dosya Sayısı:** ~217 | **Toplam Satır (lib):** ~51,878  
> **Mimari:** Feature-first + Riverpod | **Backend:** Firebase + Cloud Functions  
> **Lokalizasyon:** TR / EN | **Tema:** Light + Dark Mode  

---

## 📊 Genel Durum Özeti

| Kategori | Durum | Puan |
|----------|-------|------|
| **Proje Mimarisi** | ✅ Çok İyi | 9/10 |
| **Android Build Config** | ⚠️ Neredeyse Hazır | 7/10 |
| **Güvenlik & Kurallar** | 🔴 Kritik Sorun Var | 4/10 |
| **Monetizasyon (RevenueCat)** | ⚠️ Yapılandırma Gerekli | 6/10 |
| **Reklamlar (AdMob)** | 🔴 Test ID'leri Aktif | 3/10 |
| **Gizlilik & Yasal** | ✅ İyi | 8/10 |
| **UX & Performans** | ✅ İyi | 8/10 |
| **Test Kapsamı** | 🔴 Yetersiz | 2/10 |
| **Play Store Materyalleri** | ⚠️ Klasör Var, İçerik Kontrolü Gerekli | 6/10 |

---

## 🔴 KRİTİK ENGELLER (Yayın Öncesi Düzeltilmeli)

### 1. 🔥 Firestore Güvenlik Kuralları — Açık Yazma Yetkisi

> [!CAUTION]
> `cities`, `universities`, `departments` ve `places` koleksiyonlarında **`allow write: if true`** kuralı var. Bu, herhangi bir kullanıcının bu verileri silmesine veya değiştirmesine olanak tanır. **Google, güvenli olmayan kuralları tespit eden uygulamaları reddedebilir.**

**Dosya:** [firestore.rules](file:///home/burak/uni_app/firestore.rules#L26-L47)

```diff
 match /cities/{cityId} {
   allow read: if true;
-  allow write: if true;
+  allow write: if isAdmin();
 }

 match /universities/{uniId} {
   allow read: if true;
-  allow write: if true;
+  allow write: if isAdmin();
 }

 match /departments/{deptId} {
   allow read: if true;
-  allow write: if true;
+  allow write: if isAdmin();
 }

 match /places/{placeId} {
   allow read: if true;
-  allow write: if true;
+  allow write: if isAdmin();
 }
```

**Etki:** ⛔ Play Store red riski + veri güvenliği açığı

---

### 2. 🔥 AdMob Test ID'leri Production'da Kullanılıyor

> [!CAUTION]
> Hem AndroidManifest.xml hem de `ad_service.dart` dosyasında Google'ın **test AdMob ID'leri** kullanılıyor. Test ID'leriyle yayınlanan uygulamalar **AdMob politika ihlali** nedeniyle hesap askıya alınmasına neden olabilir.

**Dosyalar:**
- [AndroidManifest.xml](file:///home/burak/uni_app/android/app/src/main/AndroidManifest.xml#L13) — `ca-app-pub-3940256099942544~3347511713` (test)
- [ad_service.dart](file:///home/burak/uni_app/lib/features/monetization/data/ad_service.dart#L24-L32) — Test rewarded ad unit ID'leri

**Çözüm:**
1. AdMob'dan gerçek App ID ve Ad Unit ID oluşturun
2. AndroidManifest.xml'deki `APPLICATION_ID`'yi güncelleyin
3. `ad_service.dart`'taki ID'leri `--dart-define` ile inject edin (hardcode etmeyin)

---

### 3. 🔥 Versiyon Numarası `1.0.0+1` — Güncelleme Stratejisi Belirlenmeli

**Dosya:** [pubspec.yaml:4](file:///home/burak/uni_app/pubspec.yaml#L4)

`versionCode` (build number) her yüklemede artırılmalıdır. Play Store aynı `versionCode` ile yeni APK/AAB kabul etmez. Release pipeline'ınızda otomatik artırma olduğundan emin olun.

---

### 4. 🔥 Keystore / Signing Yapılandırması

[build.gradle.kts](file:///home/burak/uni_app/android/app/build.gradle.kts#L46-L55) keystore yapılandırması mevcut ancak:

- `android/key.properties` dosyası **repoda yok** (.gitignore'da). ✅ Bu doğru.
- Keystore dosyası (`.jks`) da repoda yok. ✅ Bu da doğru.

> [!IMPORTANT]
> Keystore'u **kaybetmemeniz** kritik. Play Store'a yüklenen ilk APB'nin imzası kalıcıdır. Yedek alın ve güvenli bir yerde saklayın (Google Play App Signing kullanmanız önerilir).

---

## ⚠️ ÖNEMLİ UYARILAR

### 5. `--obfuscate` ve `--split-debug-info` Kullanılmıyor

Release build'de Dart kodunun obfuscate edilmesi ve debug info'nun ayrılması önerilir:

```bash
flutter build appbundle \
  --obfuscate \
  --split-debug-info=build/debug-info \
  --dart-define=REVENUECAT_API_KEY_ANDROID=goog_xxx
```

Bu Crashlytics ile entegre çalışır ve stack trace'leri çözümlemeye devam eder.

---

### 6. `debugLogDiagnostics: true` — Router'da Debug Log Açık

**Dosya:** [app_router.dart:80](file:///home/burak/uni_app/lib/router/app_router.dart#L80)

```diff
 return GoRouter(
   initialLocation: AppRoutes.splash,
-  debugLogDiagnostics: true,
+  debugLogDiagnostics: kDebugMode,
```

Production'da gereksiz log üretimini engeller.

---

### 7. `debugPrint` Çağrıları Yaygın (~19 dosya)

`debugPrint` release modda çıktı üretmez ama yine de best practice olarak önemli servislerde log seviyesi kontrol edilmelidir. Özellikle:
- [revenuecat_service.dart](file:///home/burak/uni_app/lib/services/revenuecat_service.dart) — 15+ debugPrint
- [ad_service.dart](file:///home/burak/uni_app/lib/features/monetization/data/ad_service.dart) — 3 debugPrint
- Çeşitli repository dosyaları

> [!NOTE]
> `debugPrint` release modda strip olur, kritik değil ama kod temizliği için `kDebugMode` guard ile sarılabilir.

---

### 8. `lib/scripts/` Klasöründe Migration Scriptleri Hata Veriyor

4 migration scripti (`city_population_migration.dart`, `delete_missing_departments.dart`, `department_scores_migration.dart`, `seed_data_service.dart`) analiz hatası veriyor. Bunlar production kodu değil ama:

> [!TIP]
> Bu dosyaları `analysis_options.yaml`'da exclude edin ya da `tools/` klasörüne taşıyın:
> ```yaml
> analyzer:
>   exclude:
>     - lib/scripts/**
> ```

---

### 9. TODO Maddeleri (3 adet)

| Dosya | Satır | İçerik |
|-------|-------|--------|
| [university_match_card.dart:88](file:///home/burak/uni_app/lib/features/score_calculator/presentation/widgets/university_match_card.dart#L88) | `match.university.cityId, // TODO: city name` |
| [place_repository.dart:84](file:///home/burak/uni_app/lib/features/places/data/place_repository.dart#L84) | `// TODO(sprint5): Şehir bazlı mekan listesi` |
| [dorm_info_card.dart:79](file:///home/burak/uni_app/lib/features/places/presentation/widgets/dorm_info_card.dart#L79) | `value: 'Bilinmiyor', // TODO: Add to PlaceModel` |

---

### 10. Hesap Silme — Google Play Gereksinimi

Google Play, **uygulama içinden hesap silme** seçeneği sunulmasını zorunlu kılıyor. Lokalizasyon dosyalarınızda `profileDeleteAccount` anahtarı var ama profile ekranında implementasyonun tamamlanıp tamamlanmadığını doğrulayın.

> [!IMPORTANT]
> "Hesabımı Sil" işlemi sadece Firebase Auth'tan değil, Firestore'daki tüm kullanıcı verisini de (favorites, reviews, likedReviews, comparisonHistory, usageStats vb.) silmelidir. Cloud Function ile yapılması önerilir.

---

## ✅ İYİ DURUMDA OLAN ALANLAR

### Mimari & Kod Kalitesi
- ✅ **Feature-first mimari** düzgün uygulanmış (13 feature modülü)
- ✅ **Riverpod** state management tutarlı kullanılmış
- ✅ **GoRouter** ile deklaratif routing, auth guard'ları mevcut
- ✅ **TR/EN lokalizasyon** (ARB dosyaları ile)
- ✅ **Light/Dark tema** desteği

### Android Build
- ✅ `applicationId: com.unisec.app` — benzersiz
- ✅ ProGuard kuralları mevcut (Firebase, Crashlytics, RevenueCat, Google Sign-In)
- ✅ R8 minify + shrink aktif
- ✅ Release signing config mevcut
- ✅ Multidex enabled
- ✅ Core library desugaring aktif

### Firebase & Backend
- ✅ Crashlytics entegrasyonu (global handler + `recordError`)
- ✅ Analytics event tracking (custom events)
- ✅ FCM push notification entegrasyonu
- ✅ Cloud Functions (12+ fonksiyon: moderation, aggregation, notifications, AI, webhook)
- ✅ Firestore offline persistence + unlimited cache
- ✅ Storage rules güvenli (boyut + content type kontrolü)

### UX & Performans
- ✅ Native splash → animated Flutter splash geçişi
- ✅ Shimmer loading states (ShimmerBox, ListSkeleton, ShimmerCard)
- ✅ Error state widget'ı (retry desteğiyle)
- ✅ Empty state widget'ı
- ✅ Image cache limiti (50 MB)
- ✅ Cold start optimizasyonu (paralel init)
- ✅ In-app review entegrasyonu
- ✅ Connectivity kontrolü (connectivity_plus)
- ✅ Deep linking (unisec.app)

### Monetizasyon
- ✅ RevenueCat entegrasyonu (API key'ler dart-define ile)
- ✅ Tier sistemi (Free / Plus / Pro)
- ✅ Firestore fallback (offline tier)
- ✅ Restore purchases desteği
- ✅ Paywall ekranı

### Güvenlik & Gizlilik
- ✅ Gizlilik politikası dokümanı hazır
- ✅ Kullanım şartları hazır
- ✅ Data Safety form cevapları hazır
- ✅ KVKK uyumu düşünülmüş
- ✅ Keystore ve API key'ler .gitignore'da
- ✅ .edu.tr email doğrulama (yorum yazma için)

---

## 🆕 EKLENEBİLECEK ÖZELLİKLER & İYİLEŞTİRMELER

### Yüksek Öncelikli (v1.0 veya v1.1)

| # | Özellik | Açıklama | Efor |
|---|---------|----------|------|
| 1 | **Force Update Mekanizması** | Firebase Remote Config ile minimum versiyon kontrolü. Kritik bug'larda kullanıcıları güncellemeye zorla. | Orta |
| 2 | **Crash-Free Rate İzleme** | Crashlytics dashboard'u düzenli izleme, crash-free oranı %99+ hedefi. | Düşük |
| 3 | **Daha Fazla Analytics Event** | Screen view tracking, funnel analizi (onboarding → register → first review), retention metrikler. | Orta |
| 4 | **Rate Limiting (Client)** | API çağrılarına rate limiter ekleyin (özellikle AI summary, comparison). | Orta |
| 5 | **Offline Mode Banner** | İnternet yokken kullanıcıya görsel bir uyarı gösterin (persistent banner). | Düşük |
| 6 | **App Links Verification** | `assetlinks.json` dosyasını web sunucunuza deploy edin (deep link doğrulama). | Düşük |

### Orta Öncelikli (v1.2+)

| # | Özellik | Açıklama | Efor |
|---|---------|----------|------|
| 7 | **Accessibility (Erişilebilirlik)** | `Semantics` widget'ları çok sınırlı (sadece 2 yerde). Talkback/VoiceOver uyumluluğu artırın. | Yüksek |
| 8 | **Widget/Unit Test Kapsamı** | Şu an sadece 1 integration test var. En azından repository + provider katmanlarına unit test ekleyin. | Yüksek |
| 9 | **Performans Profiling** | Release modda jank analizi, startup trace, memory profiling yapın. | Orta |
| 10 | **A/B Testing** | Firebase Remote Config ile paywall varyantları, onboarding akışı testleri. | Orta |
| 11 | **User Feedback / Bug Report** | Uygulama içi "Geri Bildirim" butonu (shake-to-report veya profil menüsünden). | Orta |
| 12 | **Çevrimdışı Favori Senkronizasyonu** | Offline eklenen favorilerin online olunca otomatik sync edilmesi. | Orta |

### Düşük Öncelikli (v2.0+)

| # | Özellik | Açıklama | Efor |
|---|---------|----------|------|
| 13 | **Widget Testleri ile Visual Regression** | Golden tests ile UI regresyon tespiti. | Yüksek |
| 14 | **Dynamic Links / Deferred Deep Links** | Paylaşılan linklerin uygulama yüklü olmasa bile doğru sayfaya yönlendirmesi. | Yüksek |
| 15 | **Çoklu Dil Genişletme** | Almanca, Arapça, Kürtçe gibi diller (hedef kitleye göre). | Orta |
| 16 | **Tablet Optimizasyonu** | Responsive layout'lar, adaptive breakpoints. | Yüksek |
| 17 | **Web Versiyonu** | Flutter web ile marketing sayfası veya lite versiyon. | Yüksek |
| 18 | **Gamification** | Rozet sistemi, liderlik tablosu (en çok yorum yapan, en yardımcı). | Yüksek |
| 19 | **Chat / Soru-Cevap** | Üniversite öğrencileri arasında canlı iletişim. | Çok Yüksek |
| 20 | **Kampüs Haritası** | Üniversite kampüs haritası entegrasyonu (Google Maps + özel katmanlar). | Yüksek |

---

## 📋 YAYINDAN ÖNCE YAPILMASI GEREKENLER CHECKLIST

### 🔴 Zorunlu (Blokleyici)
- [x] Firestore rules'da `cities`, `universities`, `departments`, `places` write yetkisini `isAdmin()` ile kısıtla ✅ (zaten yapılmıştı)
- [x] AdMob Application ID'yi `--dart-define` ile inject edilebilir hale getir (AndroidManifest.xml + build.gradle.kts) ✅
- [x] AdMob Ad Unit ID'lerini `--dart-define` ile inject et (`ad_service.dart` — `String.fromEnvironment`) ✅
- [ ] Release keystore oluştur ve güvenli yedekle
- [ ] `key.properties` dosyasını doğru konuma yerleştir
- [ ] `flutter build appbundle --release` ile AAB oluştur ve test et
- [ ] Gizlilik politikasını bir web sayfasında yayınla (Play Store URL gerektirir)

### ⚠️ Önemli (Önerilen)
- [ ] `--obfuscate --split-debug-info` ile release build al
- [ ] Router'daki `debugLogDiagnostics: true`'yu `kDebugMode` ile sarınla
- [ ] `lib/scripts/` klasörünü analysis'den exclude et
- [ ] 3 TODO maddesini çöz veya bilet aç
- [ ] Hesap silme akışının tüm kullanıcı verisini temizlediğini doğrula
- [ ] RevenueCat API key'lerinin doğru inject edildiğinden emin ol
- [ ] versionCode artırma stratejisini belirle

### ✅ İsteğe Bağlı (v1.1 için)
- [ ] Force update mekanizması ekle
- [ ] Accessibility iyileştirmeleri yap
- [ ] Unit test kapsamını artır
- [ ] App Links verification'ı tamamla
- [ ] Crashlytics'te özel log'lar ekle

---

## 🎯 Sonuç

ÜniSeç uygulaması mimari, UX ve özellik açısından **oldukça olgun** bir durumda. **13 feature modülü**, **Cloud Functions backend**, **RevenueCat monetizasyon**, **çift dil desteği** ve **dark mode** ile profesyonel bir ürün ortaya konmuş.

Ancak **Play Store'a yüklemeden önce mutlaka yapılması gereken 3 kritik düzeltme** var:

1. 🔴 **Firestore güvenlik kuralları** — Açık write yetkisi kapatılmalı
2. 🔴 **AdMob test ID'leri** — Gerçek ID'lerle değiştirilmeli
3. 🔴 **Release build konfigürasyonu** — Keystore, obfuscation, version code

Bu 3 madde çözüldüğünde uygulama **Play Store'a yüklenmeye hazır** olacaktır.
