# ÜniSeç Uygulaması Güvenlik, UI ve Geliştirme Raporu

Tarih: 2026-06-10  
Kapsam: Flutter mobil uygulaması, Firebase Firestore/Storage kuralları, Cloud Functions, Android yapılandırması, admin/moderasyon akışları ve yerel test/build çıktıları.

## Güncel İlerleme Notu

Tarih: 2026-06-18

Tamamlanan kritik/yüksek öncelikli düzeltmeler:

- `users` dokümanları owner/admin dışına kapatıldı; public profil alanları `publicProfiles` koleksiyonuna ayrıldı.
- FCM tokenları `users/{uid}/fcmTokens/{tokenId}` alt koleksiyonuna taşındı.
- Admin yetkisi Firestore `role` alanından Firebase Auth custom claim `admin == true` modeline taşındı.
- Story Storage write/delete işlemleri admin custom claim'e bağlandı; `application/octet-stream`, SVG ve wildcard image/video MIME kabulü kaldırıldı.
- Review ve story dokümanları silindiğinde ilişkili Storage dosyalarını Admin SDK ile best-effort temizleyen `cleanupDeletedReviewMedia` / `cleanupDeletedStoryMedia` trigger'ları eklendi.
- Admin route'ları client tarafında custom claim guard ile korundu ve 403 erişim reddi ekranı netleştirildi.
- Review create akışı doğrudan Firestore client write yerine App Check zorunlu `submitReview` callable function'ına taşındı; Firestore `reviews` create client'a kapatıldı.
- Review update kuralları schema whitelist, pending-first moderation ve immutable alan korumasıyla sıkılaştırıldı.
- Parent `reviews/{reviewId}.likes` client write'a kapatıldı; like sayımı Cloud Function ile server-side senkronlanacak hale getirildi.
- Yorum create/edit sonrası moderation function temiz içeriği otomatik onaylayacak, uygunsuz içeriği onaysız bırakacak şekilde güncellendi.
- Üniversite/user review count hesaplamaları onaylı yorumlara göre çalışacak şekilde düzeltildi.
- AI tercih önerisi enrichment function'ı Pro entitlement kontrolü, atomik günlük quota (10/gün), kısa pencere rate limit (12/dk) ve App Check hazırlık yorumuyla sertleştirildi.
- AI öneri cache hit'leri günlük kotadan düşmeyecek; gerçek Groq çağrıları transaction içinde hak tüketecek şekilde düzenlendi.
- Flutter tarafında Firebase App Check aktive edildi; debug build'lerde debug provider, release Android'de Play Integrity, release Apple platformlarında App Attest + DeviceCheck fallback kullanılacak.
- Kritik callable Cloud Functions için App Check zorunlu hale getirildi: `verifyStudentUniversity`, `generateComparisonSummary`, `enrichRecommendations`, `trackAnalyticsEvent`, `incrementPreferenceListView`, `performAdminModerationAction`, `getReviewSubmissionStatus`, `submitReview`, `submitReviewReport`, `submitFeedback`.
- Firestore analytics sayaçları client write'a kapatıldı; event yazımları App Check zorunlu `trackAnalyticsEvent` callable function'ına taşındı.
- Analytics event adları server-side whitelist'e alındı ve kullanıcı başına kısa pencere rate limit eklendi.
- `trackAnalyticsEvent` callable için accepted/rejected/failed structured log alanları, invalid payload/rate limit/write failure ayrımı ve Cloud Logging alert filtreleri eklendi.
- Preference list `viewCount` client write'a kapatıldı; görüntülenme sayacı App Check zorunlu `incrementPreferenceListView` callable function'ına taşındı.
- Preference list create/update kuralları schema whitelist, immutable alan koruması, server timestamp zorunluluğu ve item payload doğrulamasıyla sıkılaştırıldı.
- Admin moderasyon aksiyonları `performAdminModerationAction` callable function'ına taşındı; report/feedback/review güncelleme, gizleme ve silme işlemleri App Check + admin custom claim ile server-side yapılıyor ve `adminAuditLogs` koleksiyonuna Admin SDK üzerinden loglanıyor.
- Review oluşturma `submitReview` callable function'ına taşındı; doğrulanmış edu.tr hesabı, kullanıcının kendi üniversitesi, server-side author alanları, pending-first moderation ve 10 dakikada 3 yorum rate limit'i Admin SDK tarafında uygulanıyor. Flutter tarafında `getReviewSubmissionStatus` preflight kontrolüyle limit doluyken kullanıcı yorum yazma ekranına alınmadan uyarılıyor.
- Report ve feedback gönderimleri doğrudan Firestore client write yerine App Check zorunlu `submitReviewReport` / `submitFeedback` callable function'larına taşındı; duplicate report, kısa pencere rate limit ve `suspiciousActivityLogs` kaydı server-side uygulanıyor.
- Mekan önerisi oluşturma ve admin onay/red akışı App Check zorunlu callable function'lara taşındı; kullanıcı/admin doğrudan `place_suggestions` yazamıyor, fotoğraf path/MIME doğrulaması, create-only görsel bütünlüğü, rate limit, custom claim kontrolü ve admin audit log server-side uygulanıyor.
- Mekan öneri sistemi ürün tarafında genişletildi: rate limit korumalı gönderim öncesi mükerrer mekan kontrolü, OpenStreetMap tabanlı konum seçimi, fiyat/saat/telefon/olanak alanları, kullanıcı bazlı otomatik taslak, admin düzenlenebilir onay ekranı, gelişmiş moderasyon filtreleri, sıralı işlem geçmişi ve tüm Storage sayfalarını tarayarak 24 saatten eski sahipsiz öneri fotoğraflarını temizleyen scheduled function eklendi.
- Admin paneline read-only Güvenlik Logları ekranı eklendi; `adminAuditLogs` ve `suspiciousActivityLogs` kayıtları arama, tip/aksiyon filtresi ve detay sheet'iyle incelenebiliyor.
- Admin claim'i olmayan veya girişsiz kullanıcıların admin callable denemeleri `failed_admin_callable_access` tipiyle `suspiciousActivityLogs` koleksiyonuna düşecek şekilde sertleştirildi.
- Security observability dokümanı eklendi; admin callable, review/report/feedback abuse, Storage cleanup ve App Check reject olayları için Cloud Logging filtreleri ve önerilen alert eşikleri tanımlandı.
- `usageStats` başlangıç dokümanı Firestore rules tarafında whitelist/zero-counter validasyonuna alındı.
- Günlük quota reset job'u ve RevenueCat webhook'u `lastAiRecommendationResetDate` alanıyla AI öneri reset takibini tutarlı hale getirecek şekilde güncellendi.
- Firestore rules testleri emulator ile çalışır hale getirildi ve kritik exploit senaryoları eklendi.
- Callable review akışından kalan kullanılmayan eski Firestore review create helper'ları kaldırıldı; direct review create kapalı kalırken rules testleri 48/48 geçti.
- Android release build guard eklendi; release build artık debug signing'e düşmüyor ve production AdMob App ID olmadan devam etmiyor.
- Profil/review görsel ve story medya Storage kuralları açık MIME whitelist, dosya adı ve kullanıcı/admin path doğrulamasıyla sıkılaştırıldı; Storage emulator testleri CI rules gate kapsamına alındı.
- Admin ekranlarındaki story summary, reports summary, stats kartları, detail sheet aksiyonları ve uzun metin satırları responsive davranacak şekilde düzeltildi.

18 Haziran 2026 production eşitlemesi:

- `submitPlaceSuggestion`, `checkPlaceSuggestionDuplicates`, `performPlaceSuggestionAction` ve `cleanupOrphanPlaceSuggestionMedia` function'ları `europe-west1` bölgesinde aynı kaynak revizyonuyla deploy edildi ve `ACTIVE` durumda doğrulandı.
- `cleanupOrphanPlaceSuggestionMedia` için her gün Türkiye saatiyle 04:00'te çalışan Cloud Scheduler job'u oluşturuldu. Job, 24 saatten eski ve Firestore öneri dokümanı olmayan `place_suggestions/` dosyalarını sayfalı taramayla temizliyor.
- `place_suggestions(status, createdAt)` ve `adminAuditLogs(targetId, createdAt)` birleşik indeksleri production Firestore'da `READY` durumda doğrulandı.
- Eski `revenuecatWebhook(us-central1)` function'ı silindi. Aktif webhook yalnızca `revenuecatWebhook(europe-west1)` olarak kaldı.
- Mekan callable URL'leri kimliksiz istekte 404 yerine beklenen 401 cevabını veriyor; kaldırılan eski RevenueCat URL'si 404, yalnızca POST kabul eden aktif Avrupa URL'si ise GET isteğine 405 döndürüyor.
- Functions lock dosyasındaki `form-data` high advisory'si `2.5.6` sürümüne yükseltilerek giderildi. Production dependency audit sonucu 0 high, 0 critical ve transitive `uuid` zincirinde 9 moderate bulgudur.

19 Haziran 2026 kapalı test hazırlığı:

- Gizlilik politikası uygulama içinden canlı Vercel sayfasına bağlandı: `https://uni-app-web-sitesi.vercel.app/privacy.html`. URL HTTP 200 dönüyor ve Play Console Privacy Policy alanında kullanılabilir.
- Hesap silme akışı release build'de görünür hale getirildi. Kullanıcı parola hesabında mevcut şifreyle, Google hesabında Google reauth ile doğrulanıyor; ardından `deleteUserAccount` callable function'ı çağrılıyor.
- Hesap silme backend tasarımı veriyi önce temizleyip Firebase Auth hesabını en son silecek şekilde kuruldu. `cleanupDeletedUserAccount` Auth onDelete trigger'ı Console veya başka backend üzerinden silinen kullanıcılar için idempotent fallback sağlar.
- Hesap silme cleanup kapsamı: kullanıcı dokümanı, public profile, subscription dokümanı, favori/tercih/yorum/öneri/notification/feedback/report verileri, kullanıcıya ait like dokümanları, ilgili rate-limit dokümanları ve profil/yorum/mekan önerisi Storage prefix'leri.
- Türkçe cihaz dışındaki cihazlarda uygulamanın İngilizce başlaması ve kullanıcının sonradan seçtiği dilin korunması doğrulandı.
- Closed testing için yeni Android App Bundle üretildi: `build/app/outputs/bundle/release/unisec-closed-1.0.0+3.aab`. Paket `com.unisec.app`, `versionCode=3`, `versionName=1.0.0`, `targetSdk=36` ve production AdMob App ID `ca-app-pub-9125676139820389~4633697387` ile üretildi.
- AAB 16KB zip alignment ve zip bütünlüğü kontrollerinden geçti. SHA-256: `cc7061615b006c2c61e0695e52a5a9c914a98afdc7c4b7120cba0abd0bd92642`.
- Firebase Android app üzerinde 2 SHA-1 ve 2 SHA-256 sertifika kaydı listelendi. Play App Signing sertifikasının Firebase kayıtlarıyla eşleştiği, Play Console > App integrity ekranından son kez kontrol edilmelidir.
- `deleteUserAccount` ve `cleanupDeletedUserAccount` production deploy denemeleri yerel build/lint aşamasını geçti; ancak `cloudfunctions.googleapis.com` DNS çözümlemesinde `EAI_AGAIN` nedeniyle deployment tamamlanamadı. Test kullanıcılarını davet etmeden önce bu iki function deploy'u tekrar denenmelidir.

Son doğrulama çıktıları:

| Komut | Sonuç |
| --- | --- |
| `npm run build` (`functions`) | Başarılı |
| `npm run lint` (`functions`) | Başarılı |
| `npm audit --omit=dev --audit-level=high` (`functions`) | Başarılı; 0 high/critical, 9 moderate |
| `npm test` (`rules-tests`) | Başarılı, 48 test geçti |
| `flutter analyze` | Başarılı |
| `flutter test` | Başarılı, 83 test geçti |
| `./gradlew :app:lintDebug` | Başarılı. 0 hata, 15 uyarı |
| `flutter build apk --debug` | Başarılı |
| Hedefli Functions deploy | Başarılı; 4/4 function aktif |
| `firebase deploy --only firestore:indexes` | Başarılı; gerekli iki indeks `READY` |
| Eski RevenueCat function temizliği | Başarılı; `us-central1` silindi, `europe-west1` aktif |
| `curl -I -L https://uni-app-web-sitesi.vercel.app/privacy.html` | Başarılı; HTTP 200 |
| `npm run build` / `npm run lint -- --quiet` (`functions`, hesap silme eklemesi sonrası) | Başarılı |
| `flutter build appbundle --release --build-name=1.0.0 --build-number=3 ...` | Başarılı; `unisec-closed-1.0.0+3.aab` üretildi |
| `zipalign -c -P 16 4` + `unzip -tq` (`unisec-closed-1.0.0+3.aab`) | Başarılı |
| `firebase deploy --only functions:deleteUserAccount,functions:cleanupDeletedUserAccount` | Beklemede; yerel analiz geçti, Google API DNS `EAI_AGAIN` nedeniyle deploy tamamlanamadı |

## 1. Yönetici Özeti

Uygulama genel olarak geniş bir ürün yüzeyine sahip: öğrenci doğrulama, yorumlar, favoriler, tercih listeleri, admin panelleri, hikayeler, bildirimler, abonelikler, AI karşılaştırma/öneri özellikleri ve Firebase tabanlı sunucu işlevleri bulunuyor. İlk güvenlik incelemesinde bulunan admin yetki yükseltme, private kullanıcı verisi sızıntısı, review bütünlüğü ve Story Storage yazma açıkları güncel kodda giderildi. Firestore/Storage rules testleri 48/48, Flutter testleri 80/80 geçmektedir.

Mekan öneri akışı production ile eşitlenmiştir. Saat seçimi yazısız bottom sheet üzerinden yapılmakta, konum Türkiye geneli arama ile daraltılabilmekte, telefon istemci ve sunucuda yalnızca 10-11 rakam kabul etmekte ve gönderim/duplicate/admin action callable'ları aynı production revizyonunda çalışmaktadır. Sahipsiz öneri medyası için günlük scheduled cleanup da aktiftir.

Gizlilik politikası canlı Vercel URL'sine bağlandı ve closed testing AAB üretildi. Hesap silme akışı kod tarafında hazırdır; ancak `deleteUserAccount` ve `cleanupDeletedUserAccount` production deploy'u Google API DNS `EAI_AGAIN` hatası nedeniyle henüz tamamlanmamıştır. Test kullanıcılarını davet etmeden önce bu deploy tekrar denenmelidir.

Güncel en önemli açık işler güvenlik kuralı düzeltmesinden çok release ve operasyon doğrulamasıdır: hesap silme function deploy'u, Play Console'a yeni AAB yükleme, Play Integrity/App Check gerçek imzalı build doğrulaması, giriş yapılmış gerçek Android cihazında uçtan uca smoke test, veri dışa aktarma talebi süreci, review upload reddinde orphan fotoğraf temizliği ve kritik Cloud Function senaryolarının otomatik testleridir.

UI tarafında otomatik Flutter analizinde hata bulunmadı. Admin story istatistik satırı, rapor özet kartı, stats kart gridleri, detail sheet aksiyonları ve uzun metin satırlarındaki başlıca responsive riskler kod tarafında giderildi. Buna rağmen gerçek cihaz, tablet, landscape, yüksek text scale ve golden/screenshot test kapsamı henüz yeterli değildir.

Android lint hataları kod tarafında giderildi. `./gradlew :app:lintDebug` artık başarılı çalışıyor; sonuç 0 hata, 15 uyarı. Giderilen ana sorunlar `UCropActivity` dependency görünürlüğü ve minSdk 24 ile uyumsuz API 27/29 style attribute kullanımlarıydı. Kalan uyarılar dependency sürüm güncellemeleri, splash asset tekrarları ve Android geniş ekran/orientation önerileri gibi non-blocking kalite maddeleridir.

## 2. İnceleme Yöntemi

İnceleme şu yöntemlerle yapıldı:

- Firestore ve Storage güvenlik kuralları satır satır incelendi.
- Flutter router, auth, user model, review, admin, notification ve UI kodları incelendi.
- Cloud Functions içinde moderation, recommendation, comparison summary, RevenueCat webhook ve aggregation kodları incelendi.
- Android manifest, Gradle yapılandırması, style kaynakları ve backup/data extraction kuralları kontrol edildi.
- Yerel statik analiz, test, audit ve build komutları çalıştırıldı.

Çalıştırılan kontroller:

| Komut | Sonuç |
| --- | --- |
| `flutter analyze` | Başarılı. `No issues found`. |
| `flutter test` | Başarılı. 80 test geçti. |
| `npm run build` (`functions`) | Başarılı. TypeScript build geçti. |
| `npm run lint` (`functions`) | Başarılı. ESLint config eklendi ve hata yok. |
| `npm audit --omit=dev --audit-level=high` (`functions`) | Başarılı. High/critical açık yok; moderate `uuid` zinciri dependency migration maddesinde takip edilmeli. |
| `flutter pub outdated` | Birçok paket major sürüm gerisinde. Firebase, go_router, notifications, ads ve permission paketleri özellikle eski. |
| `npm test` (`rules-tests`) | Başarılı. Firestore + Storage emulator ile 48 test geçti. |
| `./gradlew :app:assembleDebug` | Başarılı. Debug APK derlendi. |
| `./gradlew :app:lintDebug` | Başarılı. 0 hata, 15 uyarı. CI gate'e alındı. |

Sınırlamalar:

- Canlı Firebase projesine karşı penetrasyon testi yapılmadı.
- Gerçek cihaz/emülatör üzerinde görsel screenshot testi yapılmadı.
- UI taşmaları kod yapısından çıkarılan risklerdir; kesinleşmesi için 320 px genişlik, büyük text scale ve farklı locale ekran testleri gerekir.
- Dependency audit sonuçları çalıştırıldığı tarih itibarıyla geçerlidir.

## 3. Öncelikli Risk Tablosu

| Öncelik | Alan | Risk | Etki |
| --- | --- | --- | --- |
| Yüksek | Release doğrulaması | Closed testing AAB üretildi ancak Play Console'a yüklenmiş gerçek tester build üzerinde uçtan uca test yapılmadı | App Check, auth veya cihaz davranışı kaynaklı production hataları geç fark edilebilir |
| Yüksek | App Check operasyonu | Play Integrity/App Attest provider, Play App Signing SHA eşleşmesi ve release token davranışı Console tarafında son kez doğrulanmadı | Release callable çağrıları reddedilebilir |
| Yüksek | KVKK/Play Store | Gizlilik URL'si yayında ve hesap silme kodu hazır; ancak hesap silme function deploy'u DNS nedeniyle bekliyor, veri dışa aktarma talebi süreci eksik | Store reddi ve veri sahibi talebi uyumsuzluğu |
| Orta | Review Storage | Callable reddedilmeden önce yüklenen review fotoğrafları orphan kalabilir | Storage maliyeti ve bucket kirliliği |
| Orta | Functions testleri | Quota yarış durumu, webhook idempotency ve moderation için doğrudan function testleri eksik | Regresyonlar deploy öncesi yakalanmayabilir |
| Orta | Story upload | Admin-only olmasına rağmen server-side upload rate limit ve gerçek içerik taraması yok | Yetkili hesap ele geçirilmesi veya yanlış kullanımda maliyet riski |
| Orta | Observability | Alert filtreleri dokümante edildi ancak Console alert policy kurulumu doğrulanmadı | Hata ve abuse olaylarına geç müdahale |
| Düşük | UI/accessibility | Tablet, landscape, yüksek text scale ve golden test kapsamı sınırlı | Dar/geniş cihazlarda kullanılabilirlik sorunları |
| Düşük | Dependency/Android | 9 moderate transitive advisory ve 15 Android lint warning kaldı | Uzun vadeli bakım ve platform uyumluluğu riski |

## 4. Kritik ve Yüksek Güvenlik Bulguları

Not: Bu bölüm ilk incelemede bulunan tarihsel bulguları ve yapılan düzeltmeleri ayrıntılı kanıtlarıyla korur. Güncel açık riskler için Bölüm 3 ve Bölüm 10 esas alınmalıdır.

### 4.1 Kritik: Firestore admin yetkisi kullanıcı dokümanındaki değiştirilebilir `role` alanına bağlı

Kanıt:

- `firestore.rules:11-13`: `isAdmin()` fonksiyonu `users/{uid}.role == 'admin'` kontrolü yapıyor.
- `firestore.rules:108-116`: `users/{userId}` için `allow update` yalnızca `isVerifiedStudent` alanını özel olarak ele alıyor; `role`, `email`, `fcmTokens`, `reviewCount`, `universityId` gibi alanları kilitlemiyor.
- `lib/features/auth/domain/user_model.dart:15`: kullanıcı modelinde `role` alanı var.
- `lib/features/auth/domain/user_model.dart:67-84`: `toMap()` içinde `role`, `email`, `fcmTokens`, `reviewCount` ve diğer hassas alanlar Firestore'a yazılıyor.
- `lib/features/auth/domain/user_model.dart:127-128`: client tarafı admin kontrolü `role == 'admin'`.

Etki:

Bir kullanıcı kendi `users/{uid}` dokümanında `role` alanını `admin` yapabilirse Firestore kurallarındaki `isAdmin()` kontrollerini geçebilir. Bu durumda şu alanlar etkilenir:

- `cities`, `universities`, `departments`, `places` koleksiyonlarında write yetkisi.
- `reports`, `feedback`, `stories`, `analytics`, `aiSummaryLogs` gibi admin alanlarına erişim.
- Admin panellerinin ve moderation süreçlerinin bütünlüğü.
- İçerik silme/güncelleme ve public veri manipülasyonu.

Önerilen düzeltme:

- Adminliği Firestore kullanıcı dokümanındaki client-writable `role` alanından çıkartın.
- Firebase Auth custom claims kullanın: örnek kural `request.auth.token.admin == true`.
- Custom claim yalnızca güvenilir backend/admin SDK tarafından atanmalı.
- `users/{userId}` update kuralında `affectedKeys().hasOnly([...])` ile güvenli profil alanları beyaz listeye alınmalı.
- Şu alanlar client update kapsamından çıkarılmalı: `role`, `email`, `fcmTokens`, `reviewCount`, `createdAt`, `lastLoginAt`, `universityId`, `isVerifiedStudent`.
- `isVerifiedStudent` ve `universityId` gibi kimlik/okul doğrulama alanları Cloud Function veya güvenilir backend akışıyla yazılmalı.

Örnek hedef yaklaşım:

```js
function isAdmin() {
  return request.auth != null && request.auth.token.admin == true;
}

allow update: if isOwner(userId) &&
  request.resource.data.diff(resource.data).affectedKeys().hasOnly([
    'displayName',
    'photoUrl',
    'department',
    'grade',
    'bio',
    'notificationPrefs'
  ]);
```

### 4.2 Kritik: Kullanıcı dokümanları herkese açık okunuyor ve özel alanlar sızabilir

Kanıt:

- `firestore.rules:108-109`: `match /users/{userId}` altında `allow read: if true`.
- `lib/features/auth/domain/user_model.dart:7`: `email` alanı.
- `lib/features/auth/domain/user_model.dart:17`: `fcmTokens` alanı.
- `lib/features/auth/domain/user_model.dart:67-84`: bu alanlar kullanıcı dokümanına yazılıyor.
- `lib/features/notifications/data/fcm_service.dart:140-143`: FCM token kullanıcı dokümanına ekleniyor.
- `lib/features/auth/data/auth_repository.dart:355-366`: public profil okuması client tarafında `email` ve `fcmTokens` maskeleyerek dönüyor; ancak bu maskeleme güvenlik kontrolü değil.

Etki:

Firestore kuralları doküman seviyesinde çalışır. Bir dokümanı okumaya izin verildiğinde alan bazlı gizleme yapılmaz. Bu yüzden public profil ekranı client tarafında maskeleme yapsa bile, doğrudan Firestore SDK/REST erişimiyle şu veriler okunabilir:

- E-posta adresleri.
- FCM token listeleri.
- Bildirim tercihleri.
- Kullanıcının rolü.
- Üniversite/bölüm/grade bilgileri.
- Login ve oluşturulma tarihleri.

Önerilen düzeltme:

- `users` dokümanlarını owner/admin dışına kapatın.
- Public bilgiler için ayrı bir `publicProfiles/{uid}` koleksiyonu oluşturun.
- `publicProfiles` içinde yalnızca herkese açık olması istenen alanları tutun: `displayName`, `photoUrl`, `university`, `department`, `bio`, opsiyonel `reviewCount`.
- FCM tokenları ayrı ve owner-only bir alt koleksiyona taşıyın: `users/{uid}/fcmTokens/{tokenId}`.
- E-posta ve rol gibi alanları asla public dokümana koymayın.

### 4.3 Yüksek: Yorum oluşturma/güncelleme kuralları moderasyon ve veri bütünlüğünü korumuyor

Güncel durum (2026-06-15): Bu bulgu büyük ölçüde giderildi. Review oluşturma artık client tarafından doğrudan `reviews` koleksiyonuna yazılmıyor; App Check zorunlu `submitReview` callable function'ı Admin SDK ile pending review oluşturuyor. Function doğrulanmış `.edu.tr` hesabı, kullanıcının kendi üniversitesi, server-side author alanları, içerik schema doğrulaması ve 10 dakikada 3 yorum rate limit'i uyguluyor. Firestore rules tarafında `reviews/{reviewId}` create izni client'a kapatıldı. Owner update ise immutable alanları, parent `likes` değişimini ve doğrudan onay manipülasyonunu reddedecek şekilde sınırlandı.

Kanıt:

- `functions/src/reviews/submit_review.ts`: `getReviewSubmissionStatus` ve `submitReview` callable function'ları App Check, auth, edu.tr, university match, schema validation ve rate limit kontrolleriyle review oluşturma akışını yönetiyor.
- `firestore.rules`: `reviews/{reviewId}` için `allow create: if false`; owner update sadece güvenli içerik alanlarını ve `isApproved == false` geçişini kabul ediyor.
- `lib/features/reviews/data/review_repository.dart`: yeni review oluşturma `submitReview` callable function'ına taşındı.
- `rules-tests/test.js`: doğrudan review create denemeleri artık reddediliyor; owner update/like manipülasyonu testleri korunuyor.

Önceki etki:

- Kullanıcı yorum oluştururken `isApproved: true` gönderebilir.
- Uygunsuz içerik yorum oluşturulduktan sonra update ile eklenebilir; moderation function tekrar çalışmaz.
- Kullanıcı kendi yorumunda `rating`, `type`, `targetId`, `universityId`, `categoryRatings`, `likes`, `imageUrls`, `createdAt` ve `isApproved` gibi alanları manipüle edebilir.
- Beğeni sayısı yalnızca alt koleksiyondaki like dokümanlarına bağlı değil; parent review dokümanında arbitrary `likes` update yapılabilir.
- Puan ortalamaları ve moderation kuyruğu güvenilmez hale gelir.

Uygulanan düzeltme:

- Review create client write kapatıldı ve Admin SDK callable endpoint'e taşındı.
- Create sırasında `isApproved == false`, `likes == 0`, `createdAt/updatedAt` server timestamp olarak backend'de üretiliyor.
- Owner update sadece içerik/anonimlik alanlarını etkileyebiliyor; içerik değiştiğinde yorum tekrar pending duruma alınıyor.
- Parent `likes` client update'e kapatıldı; like sayımı alt koleksiyon + Cloud Function senkronizasyonuna bağlandı.
- Kalan takip işi: Fotoğraf upload'ı hâlâ review dokümanı oluşmadan önce Storage'a yapılıyor; callable rejection sonrası orphan dosya kalmaması için upload cleanup veya signed upload akışı eklenmeli.

### 4.4 Yüksek: Kullanıcı kendi `universityId` alanını değiştirebildiği için üniversite doğrulaması bypass edilebilir

Kanıt:

- `firestore.rules:65-67`: yorum create sırasında `request.resource.data.universityId`, kullanıcının kendi dokümanındaki `universityId` ile karşılaştırılıyor.
- `firestore.rules:111-115`: user update kuralı `universityId` alanını kilitlemiyor.

Etki:

Kullanıcı önce kendi `users/{uid}.universityId` alanını istediği üniversiteye set edebilir, sonra o üniversite için yorum oluşturabilir. Bu, “yalnızca kendi üniversiten için yorum yap” iş kuralını geçersiz kılar.

Önerilen düzeltme:

- `universityId`, client update edilemeyen bir alan olmalı.
- Üniversite eşlemesi doğrulanmış `.edu.tr` e-posta domaininden veya manuel/admin onayından backend tarafından yapılmalı.
- Kullanıcı okul değiştirme isteği ayrı bir `verificationRequests` koleksiyonunda bekletilmeli ve admin/backend onayıyla uygulanmalı.

### 4.5 Yüksek: Story medyaları Storage üzerinde tüm giriş yapmış kullanıcılara açık

Kanıt:

- `storage.rules:23-29`: `/stories/{fileName}` için `allow write: if request.auth != null`.
- Aynı kural `image/*`, `video/*` ve `application/octet-stream` kabul ediyor.
- Firestore story dokümanları admin kontrolü yapsa da Storage medya yüklemesi ayrı bir güvenlik yüzeyidir.

Etki:

- Her authenticated kullanıcı story alanına 100 MB'a kadar dosya yükleyebilir.
- `application/octet-stream` kabul edildiği için içerik türü doğrulaması zayıf.
- Bucket maliyeti artırılabilir.
- Yetkisiz/zararlı/uygunsuz medya public read alanına bırakılabilir.
- Admin client'ın doküman oluşturma adımı başarısız olsa bile Storage tarafında orphan dosya kalabilir.

Önerilen düzeltme:

- Story Storage write kuralına admin custom claim kontrolü ekleyin.
- `application/octet-stream` kaldırın.
- Dosya yollarını UID ve storyId ile bağlayın: `stories/{storyId}/{fileName}` gibi.
- Mümkünse story upload'ı callable Cloud Function veya signed upload URL üzerinden yapın.
- Upload sonrası Cloud Function ile MIME/extension/size doğrulaması ve moderation ekleyin.
- Delete işlemini Admin SDK üzerinden veya admin custom claim'li Storage kuralıyla güvenli hale getirin.

### 4.6 Yüksek: AI recommendation enrichment için server-side kota/rate limit eksik

Güncel durum (2026-06-13): Bu bulgu büyük ölçüde giderildi. `enrichRecommendations` artık Pro entitlement kontrolü, transaction içinde günlük 10 hak, 60 saniyede 12 istek rate limit'i ve cache hit'lerde quota düşmeme davranışıyla çalışacak şekilde güncellendi. Flutter tarafında App Check aktive edildi ve callable function'larda `enforceAppCheck: true` açıldı.

Kanıt:

- `functions/src/recommendations/enrich.ts:47-55`: callable function auth istiyor, CORS açık.
- `functions/src/recommendations/enrich.ts:61-80`: input sınırlanıyor ve cache key oluşturuluyor.
- `functions/src/recommendations/enrich.ts:109-123`: cache miss durumunda Groq çağrısı yapılıyor.
- `functions/src/comparison/summary.ts:54-132`: comparison summary tarafında atomik kota var; recommendation enrichment tarafında benzer kota yok.
- Güncel kodda `verifyStudentUniversity`, `generateComparisonSummary` ve `enrichRecommendations` callable function'larında `enforceAppCheck: true` aktif.

Etki:

Authenticated kullanıcı farklı tag/recommendation kombinasyonlarıyla cache miss üreterek Groq API maliyeti oluşturabilir. Bu, özellikle ücretsiz hesaplarla abuse riskidir.

Önerilen düzeltme:

- Recommendation enrichment için `users/{uid}/usageStats/current` altında günlük kota ekleyin. (Tamamlandı)
- Transaction ile atomik quota increment uygulayın. (Tamamlandı)
- UID bazlı ve gerekirse IP/App Check bazlı rate limit ekleyin. (UID bazlı rate limit tamamlandı)
- Firebase Console'da App Check provider ayarlarını ve debug token kayıtlarını tamamlayın.
- Cache key'i kullanıcı inputlarını normalize ederek daha yüksek cache hit oranı verecek şekilde tasarlayın.

## 5. Orta Risk Bulguları

### 5.1 Analytics koleksiyonları client tarafından serbest yazılabiliyor

Güncel durum (2026-06-14): Bu bulgu giderildi. `analytics/{docId}` ve `analytics/{docId}/items/{itemId}` write izinleri client'a kapatıldı. Flutter `AnalyticsService` artık `trackAnalyticsEvent` callable function'ını çağırıyor; function App Check, auth, event whitelist ve kullanıcı bazlı rate limit ile yazıyor. Ayrıca accepted/rejected/failed sonuçları structured log alanlarıyla ayrıştırıldı ve Cloud Logging alert filtreleri `docs/analytics_observability.md` altında belgelendi.

Kanıt:

- `firestore.rules:247-253`: `analytics/{docId}` ve altındaki `items/{itemId}` için `allow write: if isAuthenticated()`.

Etki:

Her authenticated kullanıcı analytics sayaçlarını veya event dokümanlarını manipüle edebilir. Admin dashboard verileri karar destek amacıyla kullanılıyorsa güvenilirliğini kaybeder.

Önerilen düzeltme:

- Analytics write işlemlerini Cloud Functions/Admin SDK'a taşıyın. (Tamamlandı)
- Client sadece whitelist event adıyla callable endpoint çağırmalı. (Tamamlandı)
- Event adları, hedef ID formatları, tek çağrı event limiti ve rate limit server-side doğrulanmalı. (Tamamlandı)
- Counter dokümanları doğrudan client write'a kapatılmalı. (Tamamlandı)
- Invalid payload, rate limit ve Firestore write failure için Cloud Logging filtreleri ve önerilen alert eşikleri tanımlanmalı. (Tamamlandı; Console alert policy kurulumu manuel)

### 5.2 Preference list update ve viewCount kuralları zayıf

Güncel durum (2026-06-13): Bu bulgu giderildi. `preferenceLists` create/update kuralları alan whitelist'i, immutable `userId/userName/userPhotoUrl/shareSlug/viewCount/createdAt` koruması, server timestamp zorunluluğu ve 24 item için schema kontrolüyle sıkılaştırıldı. `viewCount` artık Firestore client update ile artırılamıyor; public liste görüntülenmesi App Check zorunlu `incrementPreferenceListView` callable function'ı üzerinden Admin SDK ile artırılıyor.

Kanıt:

- `firestore.rules:94-104`: create sadece `userId` ve `items.size() <= 24` kontrol ediyor.
- Owner update için alan/uzunluk doğrulaması yok.
- `viewCount` update için auth şartı yok; sadece affected key kontrolü var.

Etki:

- Public liste view count arbitrary değere set edilebilir.
- Liste başlığı, açıklama, slug, item içeriği ve boyutları kötüye kullanılabilir.
- Büyük veri yazımı veya beklenmeyen schema bozulmaları oluşabilir.

Önerilen düzeltme:

- Create/update için `title`, `description`, `items`, `isPublic`, `shareSlug`, `updatedAt` alanlarını beyaz listeyle doğrulayın. (Tamamlandı)
- `viewCount` için `request.resource.data.viewCount == resource.data.viewCount + 1` gibi kısıt koyun veya Cloud Function kullanın. (Cloud Function ile tamamlandı)
- `items` elemanlarının ID/type formatlarını doğrulayın. (Tamamlandı)

### 5.3 Admin rotalarında client-side guard yok (giderildi)

Önceki kanıt:

- `lib/router/app_router.dart:109-118`: protected routes listesi sadece edit profile, my reviews, write/edit review akışlarını kapsıyor.
- `lib/router/app_router.dart:179-195`: `/admin`, `/admin/stories`, `/admin/reports`, `/admin/stats` rotaları guard olmadan tanımlı.

Güncel durum:

- `/admin*` rotaları giriş yapmamış kullanıcı için login'e yönlendiriliyor.
- Giriş yapmış fakat `admin == true` custom claim'i olmayan kullanıcılar admin ekranı render edilmeden 403 erişim reddi ekranı görüyor.
- `/403` rotası ayrı tanımlandı ve yetki doğrulama hatalarında admin UI güvenli şekilde kapatılıyor.

Etki:

Bu risk kod tarafında giderildi. Firestore rules yine nihai güvenlik katmanı olarak kalmalı; client guard kullanıcı deneyimini ve görünür saldırı yüzeyini azaltır.

Önerilen düzeltme:

- `/admin*` rotaları için router/login guard eklendi. (Tamamlandı)
- Guard, Firebase Auth custom claim `admin == true` kontrolünü kullanıyor. (Tamamlandı)
- Yetkisiz kullanıcılar 403 ekranına yönlendiriliyor/gösteriliyor. (Tamamlandı)
- Admin menü/entry point'leri custom claim doğrulanmadan gösterilmiyor. (Tamamlandı)

### 5.4 Üniversite rating aggregation onaysız yorumları da hesaba katıyor

Kanıt:

- `functions/src/index.ts:27-31`: `aggregateUniversityRatings` sadece `universityId` ile query yapıyor; `isApproved == true` filtresi yok.
- Flutter repository listelerinde public yorumlar çoğunlukla `isApproved == true` ile okunuyor.

Etki:

Onaysız, reddedilmiş veya uygunsuz yorumlar üniversite ortalamasına ve review count değerine yansıyabilir. Bu, public puanların ve sıralamaların güvenilirliğini bozar.

Önerilen düzeltme:

- Aggregation query'sine `.where('isApproved', '==', true)` ekleyin.
- Review onay durumu değiştiğinde aggregation'ın yeniden hesaplandığından emin olun.
- Department/place aggregation fonksiyonlarıyla aynı davranış standardını uygulayın.

### 5.5 RevenueCat webhook küçük sağlamlaştırma ihtiyaçları

Kanıt:

- `functions/src/revenuecat/webhook.ts:34-40`: secret karşılaştırması düz string compare.
- `functions/src/revenuecat/webhook.ts:51-53`: event id yoksa fallback `Date.now()` kullanıyor.
- `functions/src/revenuecat/webhook.ts:145-155`: tier entitlement'lardan, status event type'tan belirleniyor.

Pozitif not:

- Webhook method kontrolü yapıyor.
- CORS kapalı.
- Secret header kontrolü var.
- Firebase Auth user existence check var.
- Idempotency ve subscription write transaction içinde yapılıyor.
- `firestore.rules:237-240` webhook event koleksiyonunu client erişimine kapatıyor.

Önerilen düzeltme:

- Secret compare için constant-time compare kullanın.
- RevenueCat event ID zorunlu değilse deterministic fallback üretin; `Date.now()` duplicate event yakalamaz.
- Expired/cancelled event'lerde entitlement bilgisi gelse bile effective tier/status hesaplamasını netleştirin.
- Webhook payload schema validation ekleyin.

### 5.6 AI summary cache okuma kapsamı geniş

Kanıt:

- `firestore.rules:201-204`: `aiSummaryCache/{cacheKey}` authenticated herkes tarafından okunabilir.
- `functions/src/comparison/summary.ts:63-70`: cache key karşılaştırma tipi, entity id'leri ve comparison data hash'inden oluşuyor; kullanıcıya bağlı değil.

Etki:

Cache key pratikte tahmin edilmesi zor olabilir; ancak doküman public-auth read olduğu için kullanıcıya özel veya hassas veri cache'e girerse başka authenticated kullanıcı tarafından okunabilir.

Önerilen düzeltme:

- Cache dokümanlarını public-only veriyle sınırlayın veya `allowedUserIds`/uid prefix modeli kullanın.
- Eğer summary tamamen public karşılaştırma verilerinden oluşuyorsa bu varsayımı kod yorumunda ve testte netleştirin.

## 6. Storage ve Dosya Güvenliği

### 6.1 Profil ve review image MIME/path doğrulaması sıkılaştırıldı

Güncel durum (2026-06-15): Review oluşturma callable function'ı artık `imageUrls` alanını yalnızca kullanıcının kendi `review_images/{uid}/` Storage path'inden gelen ve güvenli `.jpg` dosya adına sahip Firebase Storage URL'leriyle kabul ediyor. Storage rules tarafında profil fotoğrafları `profile_photos/{uid}.jpg`, review görselleri `review_images/{uid}/{imageId}.jpg` formatına ve `image/jpeg` metadata'sına bağlandı. Review dokümanı silindiğinde `cleanupDeletedReviewMedia` trigger'ı aynı prefix altında kalan dosyaları Admin SDK ile best-effort temizliyor. Kalan risk gerçek dosya içeriği/MIME taramasıdır.

Kanıt:

- `storage.rules`: profil fotoğrafı için owner-only `{uid}.jpg`, `image/jpeg`, 5 MB ve pozitif boyut kontrolü.
- `storage.rules`: review image için owner-only `review_images/{uid}/{imageId}.jpg`, güvenli dosya adı, `image/jpeg`, 10 MB ve pozitif boyut kontrolü.
- `functions/src/reviews/submit_review.ts`: callable review create, image URL path'lerini `review_images/{uid}/{safeName}.jpg` formatıyla doğruluyor.
- `rules-tests/test.js`: profil/review görsellerinde yanlış MIME, yanlış uzantı ve başka kullanıcı path'i reddediliyor.

Etki:

`contentType` client metadata'sına dayanır; bu yüzden metadata sertleştirmesi gerçek dosya içeriğini tek başına garanti etmez. Buna rağmen client'ın rastgele `image/*`, `.png`, `.gif`, başka kullanıcı prefix'i veya callable'a elle sahte path gönderme yüzeyi kapatıldı.

Uygulanan düzeltme:

- Profil ve review upload'ları uygulamanın mevcut `.jpg` + `image/jpeg` akışıyla uyumlu olacak şekilde JPEG-only yapıldı.
- Dosya adında güvenli karakter seti ve `.jpg` extension zorunlu hale getirildi.
- Review başına maksimum 3 görsel callable schema doğrulamasında korunuyor.
- Kalan takip işi: Upload sonrası Cloud Function ile gerçek içerik/MIME doğrulaması ve gerekiyorsa malware/image scanning eklenebilir.

### 6.2 Storage delete davranışı story tarafında orphan dosya riski oluşturabilir

Güncel durum (2026-06-15): Story Storage write/delete kuralları admin custom claim'e bağlandı. Story create/update artık wildcard `image/.*` / `video/.*` yerine açık MIME whitelist kullanıyor: `image/jpeg`, `image/png`, `image/webp`, `image/gif`, `image/heic`, `image/heif`, `video/mp4`, `video/quicktime`, `video/webm`. Ek olarak `cleanupDeletedStoryMedia` trigger'ı `stories/{storyId}` dokümanı silindiğinde `imageUrl`, `thumbnailUrl` ve `videoUrl` alanlarındaki default bucket `stories/` dosyalarını Admin SDK ile best-effort temizliyor. Client tarafında storage dosyası önce silinse bile trigger `ignoreNotFound` davranışıyla güvenli çalışır.

Kanıt:

- `storage.rules`: story write kuralı admin custom claim, pozitif boyut, 100 MB üst limit ve açık MIME whitelist kontrolü yapıyor.
- Delete işlemlerinde `request.resource` yoktur; bu kural delete'i de kapsadığı için client delete akışı başarısız olabilir.

Etki:

Admin panel dokümanı silse bile Storage dosyaları silinemeyebilir ve orphan medya maliyet oluşturabilir.

Önerilen düzeltme:

- Delete'i Admin SDK Cloud Function ile yapın. (Tamamlandı; cleanup trigger eklendi)
- Alternatif olarak admin custom claim ile ayrı delete kuralı yazın. (Tamamlandı)
- Story dokümanı silindiğinde Storage cleanup trigger ekleyin. (Tamamlandı)

## 7. Android, Build ve Dependency Bulguları

### 7.1 Android lint hataları giderildi

Sonuç:

- `./gradlew :app:lintDebug` başarılı.
- 0 hata, 15 uyarı.
- HTML rapor: `build/app/reports/lint-results-debug.html`
- Text rapor: `build/app/intermediates/lint_intermediate_text_report/debug/lintReportDebug/lint-results-debug.txt`

Giderilen hatalar:

- `android/app/src/main/AndroidManifest.xml`: `com.yalantis.ucrop.UCropActivity` için app modülüne doğrudan `com.github.Yalantis:ucrop:2.2.11` dependency'si eklendi.
- `android/build.gradle.kts`: uCrop artifact çözümü için `jitpack.io` repository'si eklendi.
- `android/app/src/main/res/values/styles.xml` ve `values-night/styles.xml`: minSdk 24 ile uyumsuz API 27/29 theme item'ları base resource'lardan çıkarıldı.
- `android/app/src/main/res/values-v27`, `values-night-v27`, `values-v29`, `values-night-v29`: API seviyesine uygun LaunchTheme kaynakları eklendi.

Kalan uyarı sınıfları:

- `ApplySharedPref` / `UseKtx`: `MainActivity.kt` içinde SharedPreferences kullanım polish'i.
- `AndroidGradlePluginVersion` / `GradleDependency`: Gradle/desugar sürüm güncellemeleri.
- `LockedOrientationActivity` / `DiscouragedApi`: crop activity portrait orientation uyarısı.
- `ObsoleteSdkInt`, `IconDuplicatesConfig`, `IconLocation`, `IconDuplicates`: splash/background asset düzenleme uyarıları.

Önerilen takip işi:

- Android lint gate CI'da aktif tutulmalı.
- Kalan 15 warning ayrı polish/maintenance adımı olarak temizlenmeli; şu an pipeline'ı kıran lint error kalmadı.
- API 27/29 gerektiren style item'ları `values-v27` ve `values-v29` klasörlerine taşınmalı ya da `tools:targetApi` ile doğru şekilde işaretlenmeli.
- Lint uyarılarındaki duplicate drawable ve densityless bitmap notları temizlenmeli.

### 7.2 Release signing debug fallback riski giderildi

Güncel durum (2026-06-15): Bu risk kod tarafında giderildi. Android release build artık `key.properties` yokken debug signing config'e düşmüyor. `:app:validateReleaseConfig` Gradle task'i release signing dosyasını, gerekli keystore alanlarını ve keystore dosya varlığını doğruluyor. `Release` içeren Android Gradle task'leri bu validasyona bağlandı.

Önceki kanıt:

- `android/app/build.gradle.kts:63-70`: release build, `key.properties` yoksa debug signing kullanıyor.

Önceki etki:

CI veya release ortamında yanlışlıkla debug imzalı build üretilebilir. Bu, store dağıtımı, güvenlik ve release güvenilirliği açısından risklidir.

Uygulanan düzeltme:

- Release build'de keystore yoksa build fail olur.
- Debug fallback sadece local development flavor'ında kalmalı.
- CI environment için secret/keystore kontrollü release config validation adımı eklendi.

### 7.3 AdMob production App ID fallback riski giderildi

Güncel durum (2026-06-15): Bu risk kod tarafında giderildi. Debug/profile build'ler geliştirme için Google test App ID fallback'ini kullanabilir; release build ise `ADMOB_APP_ID` verilmeden veya Google test App ID ile devam etmez. Gradle yapılandırması hem `-PADMOB_APP_ID=...` hem de Flutter `--dart-define=ADMOB_APP_ID=...` girdisini okuyacak şekilde güncellendi.

Önceki kanıt:

- `android/app/build.gradle.kts:45-49`: `ADMOB_APP_ID` verilmezse Google test App ID kullanılıyor.

Önceki etki:

Production build yanlışlıkla test AdMob ID ile çıkabilir; gelir kaybı veya policy sorunları doğabilir.

Uygulanan düzeltme:

- Release build'de `ADMOB_APP_ID` zorunlu hale getirildi.
- Debug/profile için test ID kullanılabilir.
- CI'da release config validation eklendi.

### 7.4 Functions dependency audit açıkları

Sonuç:

- `functions` altında high/critical audit gate temizlendi.
- Functions runtime hedefi Node.js 22'ye yükseltildi.
- `firebase-functions` major upgrade ile `^7.2.5` seviyesine çıkarıldı.
- `firebase-admin` desteklenen peer aralığındaki en güncel major/minor çizgide `^13.10.0` seviyesine çıkarıldı.
- `firebase-functions-test` `^3.5.0` seviyesine çıkarıldı.
- v1 zincir API kullanan 1st gen fonksiyonlarda importlar `firebase-functions/v1` olarak netleştirildi.
- `firebase deploy --only functions --dry-run` başarılı tamamlandı.
- `trackAnalyticsEvent` hedefli deploy ile Node.js 22 revizyonuna geçti ve Cloud Logging'de `component="analytics.trackAnalyticsEvent"` structured log akışı doğrulandı.
- Eski `revenuecatWebhook(us-central1)` 18 Haziran 2026'da silindi; `revenuecatWebhook(europe-west1)` tek aktif webhook olarak bırakıldı.
- Güncel lock audit özeti hâlâ transitive `uuid <11.1.1` zinciri nedeniyle 9 moderate vulnerability raporluyor:
  - 0 low
  - 9 moderate
  - 0 high
  - 0 critical

Öne çıkanlar:

- Direct dependency `firebase-admin` ve `firebase-functions` major/minor seviyede güncellendi.
- High advisory zincirleri `npm audit fix --omit=dev` ile temizlendi.
- Kalan moderate zincir `uuid`, `google-gax`, `@google-cloud/firestore`, `@google-cloud/storage` ve `firebase-admin` transitive bağımlılıklarından geliyor.
- `firebase-admin@14.0.0` denendi; ancak mevcut `firebase-functions@7.2.5` ve `firebase-functions-test@3.5.0` peer aralığı admin 14'ü henüz desteklemiyor. Ayrıca Admin SDK 14 namespace API tiplerini kaldırdığı için `admin.firestore()`, `admin.auth()` ve `admin.messaging()` kullanılan kodda geniş modular Admin SDK migrasyonu gerektiriyor.
- Functions dry-run sırasında Compute Engine API kapalı olduğu için default compute service account lookup uyarısı alındı; Firebase CLI fallback service account ile dry-run'ı tamamladı.

Önerilen düzeltme:

- Kalan moderate `uuid` zinciri için Admin SDK 14'e geçiş ayrı modular Admin SDK migration işi olarak planlanmalı.
- Bu geçişte `firebase-admin/app`, `firebase-admin/firestore`, `firebase-admin/auth` ve `firebase-admin/messaging` importlarına kontrollü dönüşüm yapılmalı.
- `firebase-functions` ve `firebase-functions-test` paketleri admin 14 peer desteğini yayınladığında peer warning olmadan tekrar denenmeli.
- O zamana kadar CI'da high/critical audit gate korunmalı; full moderate audit sonucu bakım riski olarak takip edilmeli.

### 7.5 Functions lint komutu yapılandırmasız (giderildi)

Kanıt:

- `functions/package.json:4`: lint script `eslint "src/**/*"`.
- Komut ESLint config bulunamadığı için başarısız.

Önceki etki:

CI'da lint gate çalışmayacak veya sürekli fail verecek. Kod standardı ve potansiyel TypeScript/Node hataları yakalanamaz.

Güncel durum:

- `functions/.eslintrc.js` eklendi.
- `npm run lint` localde başarılı.
- `src/scripts/backfill_public_profiles.ts` içindeki constant-condition lint hatası giderildi.

Önerilen düzeltme:

- `.eslintrc.js` veya yeni ESLint flat config ekleyin. (Tamamlandı)
- TypeScript parser/project ayarını yapın. (Tamamlandı)
- `npm run lint` CI'a eklenmeden önce localde temiz hale getirin. (Tamamlandı)

### 7.6 Firebase rules test paketi çalışır hale getirildi

Güncel durum:

- `rules-tests/package.json`: `npm test`, Firestore + Storage emulator'larını birlikte başlatıyor.
- `rules-tests/test.js`: Firestore rules ve Storage rules aynı test ortamında yükleniyor.
- Güncel sonuç: 48 test geçiyor.

Kapsanan kritik senaryolar:

- Kullanıcı kendi `role` alanını admin yapamamalı.
- Başka kullanıcının `email`/`fcmTokens` alanı okunamamalı.
- Review create doğrudan Firestore client write ile reddedilmeli.
- Owner yorum update `likes`/`createdAt`/`userId`/`universityId` değiştirememeli.
- Story storage upload admin olmayan kullanıcıda reddedilmeli.
- Profil/review görsellerinde yanlış MIME, yanlış uzantı ve başka kullanıcı path'i reddedilmeli.
- Analytics client arbitrary write reddedilmeli.

### 7.7 Flutter package sürümleri geride

`flutter pub outdated` birçok paketin major sürüm geride olduğunu gösterdi. Öne çıkan direct dependency güncelleme başlıkları:

- Firebase Flutter paketleri: `firebase_core`, `firebase_auth`, `cloud_firestore`, `cloud_functions`, `firebase_storage`, `firebase_messaging`, `firebase_analytics`, `firebase_remote_config`, `firebase_crashlytics`.
- Routing: `go_router`.
- Notifications: `flutter_local_notifications`.
- Ads: `google_mobile_ads`.
- Permissions: `permission_handler`.
- Auth/social: `google_sign_in`.
- Sharing: `share_plus`.

Önerilen yaklaşım:

- Önce güvenlik kuralları ve tests stabilize edilmeli.
- Sonra paketler grup grup yükseltilmeli: Firebase grubu, routing grubu, Android/platform grubu.
- Her grup için `flutter analyze`, `flutter test`, `assembleDebug`, emulator smoke test çalıştırılmalı.

## 8. UI ve Layout Bulguları

### 8.1 Admin story istatistik satırında yatay taşma riski (giderildi)

Kanıt:

- `lib/features/admin/presentation/screens/admin_story_panel_screen.dart:112-155`: üç `_StatBadge`, sabit spacer'lar, `Spacer` ve medya sayısı `Row` içinde.
- `lib/features/admin/presentation/screens/admin_story_panel_screen.dart:575-606`: `_StatBadge` içinde width constraint, ellipsis veya wrap yok.

Önceki risk:

320 px genişlik, yüksek text scale, 3+ haneli sayaçlar veya uzun Türkçe label durumunda Row yatay overflow verebilir.

Güncel durum:

- Story summary satırı responsive `_StorySummaryBar` içine taşındı.
- Sayaçlar ve medya dağılımı `Wrap` ile satır kırabiliyor.
- Story tile author/time metadata satırı uzun isimlerde ellipsis kullanıyor.

Önerilen düzeltme:

- `Row` yerine `Wrap` veya responsive `LayoutBuilder` kullanın. (Tamamlandı)
- Küçük genişlikte medya sayısı ikinci satıra alınmalı. (Tamamlandı)
- Stat badge için minimum/maximum width ve `FittedBox`/ellipsis stratejisi belirlenmeli. (Tamamlandı)

### 8.2 Reports summary card yatay taşma riski (giderildi)

Kanıt:

- `lib/features/admin/presentation/widgets/reports_summary_card.dart:35-62`: dört stat badge, spacer ve sağ tarafta iki satırlı sayaç tek Row içinde.
- `lib/features/admin/presentation/widgets/reports_summary_card.dart:67-80`: badge textleri constraint almıyor.

Önceki risk:

Küçük ekranlarda veya büyük font ayarında taşma olasıdır. Admin panelleri genellikle veri yoğun olduğu için bu satırlar responsive davranmalı.

Güncel durum:

- Reports summary card tek sabit `Row` yerine `LayoutBuilder` + `Wrap` ile çalışıyor.
- Telefon genişliğinde stat badge'leri iki satıra kırılabiliyor.
- Summary tab grid'i mevcut parent genişliğine göre 2 veya 3 kolona dönüyor.

Önerilen düzeltme:

- `Wrap` ile satır kırılımı. (Tamamlandı)
- Tablet/geniş ekran için tek satır, telefon için iki satır. (Tamamlandı)
- Badge'leri eşit genişlikli grid veya `Expanded` içinde kullanma. (Tamamlandı)

### 8.3 Story tile author/time satırı uzun isimlerde taşabilir (giderildi)

Kanıt:

- `lib/features/admin/presentation/screens/admin_story_panel_screen.dart:337-356`: `story.authorName`, separator ve time textleri tek Row içinde; author text `Flexible` değil ve ellipsis yok.

Önceki risk:

Uzun admin adı, kurum adı veya beklenmeyen displayName geldiğinde tile içinde overflow oluşabilir.

Güncel durum:

- Author/time satırı `Wrap` yapısına alındı.
- Author adı max width, `maxLines: 1` ve ellipsis ile sınırlandı.

Önerilen düzeltme:

- `story.authorName` için `Flexible`/constraint + `maxLines: 1` + `overflow: TextOverflow.ellipsis`. (Tamamlandı)
- Separator ve time sabit kalmalı. (Tamamlandı)

### 8.4 Alt navigation 5 hedef ve alwaysShow label ile dar ekranda sıkışabilir

Kanıt:

- `lib/router/app_shell.dart:198-201`: NavigationBar yüksekliği 64, label behavior `alwaysShow`.
- `lib/router/app_shell.dart:202-297`: 5 destination var; `Karşılaştır`, `Listelerim/Favoriler` gibi Türkçe label'lar kullanılıyor.

Risk:

Hard overflow kesin değil; Material NavigationBar label'ları sıkıştırabilir. Ancak 320 px cihazlarda ve büyük text scale'de okunabilirlik zayıflayabilir.

Önerilen düzeltme:

- Büyük text scale testleri ekleyin.
- Gerekirse yalnızca selected label gösterimi veya daha kısa label kullanımı değerlendirin.
- Tooltip/semantics ile erişilebilirliği koruyun.

### 8.5 UI test eksikleri

Şu anda Flutter testleri geçiyor; ancak görsel taşma risklerini otomatik yakalamak için ek test gerekir.

Öneriler:

- Admin story panel ve reports screen için küçük width widget tests.
- `textScaleFactor` veya `MediaQuery.textScaler` yüksek değer testleri.
- Golden test veya screenshot testleri.
- Ana navigation için 320x640, 360x800, tablet ve landscape kontrolleri.
- Loading/empty/error state görsel testleri.

## 9. Pozitif Güvenlik ve Mimari Notlar

İyi görünen mevcut kontroller:

- `firestore.rules:50-58`: notification read/update/delete owner ile sınırlı.
- `firestore.rules:173-175`: subscriptions client write'a kapalı.
- `firestore.rules:178-198`: usageStats increment kuralı diğer alanlara göre daha sıkı.
- `firestore.rules:237-240`: webhookEvents client read/write'a kapalı.
- `functions/src/comparison/summary.ts:54-132`: AI comparison quota transaction ile uygulanıyor.
- `functions/src/revenuecat/webhook.ts:28-68`: webhook method, secret ve Firebase Auth user check yapıyor.
- `functions/src/revenuecat/webhook.ts:90-141`: idempotency mark ve subscription write transaction içinde.
- Android backup/data extraction tarafında Firebase Auth shared prefs exclusion bulundu; bu iyi bir pratik.
- `flutter analyze` ve `flutter test` temiz; uygulama kodu temel statik kalite kontrolünden geçiyor.
- `./gradlew :app:assembleDebug` başarılı; debug build üretilebiliyor.

## 10. Güncel Uygulama Planı

### Tamamlanan production eşitlemesi

1. Mekan önerisi istemci, admin ve Functions değişiklikleri aynı kaynak revizyonunda birleştirildi.
2. Dört mekan function'ı production'a deploy edildi ve `ACTIVE` durumda doğrulandı.
3. Gerekli iki Firestore birleşik indeksi production'da `READY` hale getirildi.
4. Sahipsiz mekan önerisi medyası için günlük scheduled cleanup aktifleştirildi.
5. Eski `revenuecatWebhook(us-central1)` silindi; Avrupa webhook'u korundu.
6. Functions high advisory'si lock dosyasında giderildi.

### Sonraki işler — önem sırası

1. Hesap silme production deploy'unu tamamla:
   - `deleteUserAccount`,
   - `cleanupDeletedUserAccount`,
   - deploy sonrası callable varlık kontrolü,
   - test kullanıcı hesabıyla silme smoke testi.
2. Closed testing AAB'yi Play Console'a yükle:
   - `build/app/outputs/bundle/release/unisec-closed-1.0.0+3.aab`,
   - sürüm adı: `closed-1.0.0+3`,
   - gizlilik politikası: `https://uni-app-web-sitesi.vercel.app/privacy.html`,
   - Play App Signing SHA değerlerini Firebase/App Check ile son kez eşleştir.
3. Giriş yapılmış gerçek Android cihazında mekan önerisi uçtan uca smoke testi:
   - saat, konum, telefon, fotoğraf ve taslak,
   - duplicate uyarısı,
   - gönderim,
   - admin düzenleme/onay,
   - oluşan mekan ve audit log doğrulaması.
4. İmzalı release AAB ve App Check production doğrulaması:
   - Play Integrity,
   - App Attest/DeviceCheck,
   - release callable çağrıları,
   - production AdMob ve signing kontrolü.
5. KVKK/Play Store uyumluluğu:
   - veri dışa aktarma ve silme talebi.
6. Review fotoğraf upload rollback/orphan cleanup mekanizması.
7. Kritik Cloud Function otomatik testleri:
   - recommendation quota,
   - comparison quota race condition,
   - RevenueCat idempotency,
   - review yeniden moderasyonu,
   - mekan callable auth/App Check/hata senaryoları.
6. Story upload için server-side rate limit, abuse log ve gerçek içerik/MIME taraması.
7. Cloud Monitoring alert policy'lerini Console'da kurma ve test alarmı üretme.
8. Tablet, landscape, yüksek text scale, bottom navigation ve empty/error state UI testleri.
9. Admin SDK modular migration, 9 moderate advisory ve 15 Android lint warning bakım işi.

## 11. Geliştirilebilecek veya Eklenebilecek Özellikler

### 11.1 Güvenlik ve güvenilirlik özellikleri

- Firebase App Check Console provider ayarları ve debug token kayıt süreci release checklist'e bağlanmalı.
- Admin action audit log ve kritik admin moderation callable akışı eklendi; admin panelinde audit/suspicious log görüntüleme ve filtreleme ekranı tamamlandı. Cloud Logging alert filtreleri/eşikleri `docs/security_observability.md` altında tanımlandı.
- Suspicious activity log başlangıcı eklendi: review create rate limit, duplicate report attempt, report rate limit, feedback rate limit ve başarısız admin callable erişimleri `suspiciousActivityLogs` koleksiyonuna Admin SDK ile yazılıyor; fazla upload ve fazla AI çağrısı hâlâ genişletme maddesidir.
- Rate limit sistemi eklenmeli:
  - Review oluşturma. (Tamamlandı; `getReviewSubmissionStatus` preflight + `submitReview`, 10 dakikada 3 istek)
  - Report gönderme. (Tamamlandı; `submitReviewReport`, 10 dakikada 5 istek)
  - Feedback gönderme. (Tamamlandı; `submitFeedback`, 10 dakikada 3 istek)
  - Story upload.
  - AI recommendation/summary çağrıları. (Tamamlandı)
- Server-side schema validation standardı oluşturulmalı.
- Storage upload sonrası otomatik cleanup ve güvenlik taraması eklenmeli. (Cleanup ve MIME/path rules sertleştirmesi tamamlandı; gerçek içerik scanning ayrı takip işi)
- Firestore TTL politikaları gözden geçirilmeli: logs, webhookEvents, notification cleanup.

### 11.2 Moderasyon ve admin geliştirmeleri

- Moderasyon kuyruğu ayrıştırılmalı: pending, auto-flagged, approved, rejected, appealed.
- Yorum düzenlenince otomatik yeniden moderasyon.
- Kullanıcı rapor geçmişi ve report abuse detection.
- Admin notları ve karar gerekçesi alanı.
- Bulk moderation actions.
- İçerik arama/filtreleme: kullanıcı, üniversite, tarih, risk nedeni.
- Moderasyon kararları için bildirim akışı.
- Story medya yönetiminde orphan dosya temizleme paneli.

### 11.3 Öğrenci doğrulama ve profil gizliliği

- `edu.tr` doğrulama sonrası okul eşlemesi backend'de yapılmalı.
- Kullanıcıya doğrulama durumunu net gösteren onboarding/status ekranı.
- Okul değiştirme talep akışı.
- Public profil gizlilik ayarları:
  - Üniversite göster/gizle.
  - Bölüm göster/gizle.
  - Bio göster/gizle.
- Kullanıcının verilerini dışa aktarma/silme talepleri için KVKK/GDPR uyum akışı.

### 11.4 UI/UX geliştirmeleri

- Admin ekranları için responsive breakpoint sistemi.
- Boş durumlar, hata durumları ve retry UI'ları standartlaştırılmalı.
- Skeleton loading veya shimmer yalnızca veri beklenen alanlarda kullanılmalı.
- Accessibility:
  - Büyük yazı ölçeği testleri.
  - Semantics labels.
  - Kontrast testleri.
  - Touch target minimumları.
- Navigation label'ları dar ekranlarda optimize edilmeli.
- Admin dashboard veri yoğunluğu azaltılmalı; filtre ve segment kontrolleri daha ergonomik hale getirilmeli.

### 11.5 Arama, keşif ve ürün özellikleri

- Üniversite/bölüm arama için daha güçlü index ve typo tolerance.
- Kullanıcı tercih listesi paylaşım sayfası.
- Karşılaştırma sonuçlarını PDF/Share export.
- Favori üniversitelerde yeni yorum bildirimi zaten düşünülmüş; kullanıcıya granular kontrol ekranı güçlendirilebilir.
- Üniversite detaylarında doğrulanmış öğrenci yorumları rozeti.
- Yorumlarda faydalı/yanıltıcı işaretleme.
- Spam/kalite sinyali: yeni hesap, çok kısa yorum, tekrar eden metin.

### 11.6 Observability ve operasyon

- Crashlytics custom keys: user tier, route, feature flag, app version.
- Cloud Functions structured logging standardı.
- Alerting:
  - Groq hata oranı.
  - AI quota abuse.
  - webhook failure.
  - Storage upload spike.
  - Firestore permission denied spike.
- Release checklist:
  - Lint temiz.
  - Audit kabul edilebilir.
  - Keystore mevcut.
  - Production AdMob ID mevcut.
  - App Check aktif.
  - Rules tests geçiyor.

## 12. Önerilen Test Matrisi

### Güvenlik tests

- Firestore:
  - Auth yokken public olmayan dokümanlar okunamamalı.
  - Kullanıcı başka kullanıcının private profilini okuyamamalı.
  - Kullanıcı kendi `role`, `email`, `fcmTokens`, `reviewCount`, `universityId` alanlarını değiştirememeli.
  - Admin custom claim olan kullanıcı admin write yapabilmeli.
  - Custom claim olmayan kullanıcı admin write yapamamalı.
  - Review create doğrudan Firestore client write ile reddedilmeli.
  - Review update `likes`, `createdAt`, `userId`, `universityId` değiştirememeli.
  - Preference list viewCount arbitrary set edilememeli.
  - Preference list create/update immutable alan ve item schema ihlalleri reddedilmeli.
  - Analytics direct client write reddedilmeli.
  - Mekan önerisi create/update/delete doğrudan client write ile reddedilmeli.

- Storage:
  - Admin olmayan kullanıcı story upload yapamamalı.
  - `application/octet-stream` story upload reddedilmeli.
  - `image/svg+xml` gibi whitelist dışı story MIME tipleri reddedilmeli.
  - Profil fotoğrafında sadece beklenen MIME türleri kabul edilmeli. (Tamamlandı)
  - Review image count/path kısıtları test edilmeli. (Path/MIME tamamlandı; count callable schema ile korunuyor)
  - Mekan önerisi fotoğrafları yalnızca sahibin güvenli path'i, `photo_0..4` dosya adı ve JPG/PNG/WebP MIME türleriyle kabul edilmeli. (Tamamlandı)

- Functions:
  - Recommendation quota dolunca function reddetmeli.
  - Comparison quota race condition transaction testi.
  - RevenueCat duplicate event idempotency testi.
  - Review update moderation testi.

### UI tests

- 320x640 telefon, text scale 1.0/1.3/1.6.
- 360x800 telefon.
- 768 px tablet.
- Landscape.
- Türkçe locale uzun label kontrolleri.
- Admin story panel stats row.
- Reports summary card.
- Bottom navigation.
- Empty/loading/error states.

## 13. Sonuç

İlk incelemede bulunan kritik Firestore, admin yetkisi, private profil, review bütünlüğü ve Story Storage açıkları güncel kodda giderildi. Mekan önerisi sistemi de 18 Haziran 2026'da production ile eşitlendi; dört function aktif, gerekli indeksler hazır, scheduled orphan cleanup çalışır durumda ve eski RevenueCat function kopyası kaldırıldı.

19 Haziran 2026 itibarıyla gizlilik politikası canlı Vercel URL'sine bağlandı, hesap silme akışı kod tarafında güvenli callable modele taşındı ve closed testing için `versionCode=3` AAB üretildi. Kalan engel, hesap silme function'larının production deploy'unun yerel DNS `EAI_AGAIN` hatası nedeniyle tamamlanamamış olmasıdır.

Güncel risk profili artık doğrudan yetki yükseltme açıklarından release/operasyon doğrulamasına kaymıştır. En güvenli devam sırası:

1. `deleteUserAccount` ve `cleanupDeletedUserAccount` production deploy'unu DNS düzelince tamamlamak.
2. `unisec-closed-1.0.0+3.aab` dosyasını Closed testing'e yüklemek.
3. Play App Signing SHA/App Check Play Integrity eşleşmesini doğrulamak.
4. Gerçek cihazda girişli uçtan uca smoke test yapmak.
5. Veri dışa aktarma/silme talebi sürecini belgelemek.
6. Review orphan upload temizliği.
7. Kritik Cloud Function otomatik testleri.
8. Story upload abuse koruması ve Monitoring alert'leri.
9. Responsive/accessibility testleri ve dependency bakımı.

Mevcut güvenlik tabanı production için önceki duruma göre belirgin biçimde daha sağlamdır; kalan işler release güvenilirliği, mevzuat uyumu, otomatik regresyon kapsamı ve operasyonel görünürlük üzerine yoğunlaşmaktadır.
