# ÜniSeç Uygulaması Güvenlik, UI ve Geliştirme Raporu

Tarih: 2026-06-10  
Kapsam: Flutter mobil uygulaması, Firebase Firestore/Storage kuralları, Cloud Functions, Android yapılandırması, admin/moderasyon akışları ve yerel test/build çıktıları.

## Güncel İlerleme Notu

Tarih: 2026-06-14

Tamamlanan kritik/yüksek öncelikli düzeltmeler:

- `users` dokümanları owner/admin dışına kapatıldı; public profil alanları `publicProfiles` koleksiyonuna ayrıldı.
- FCM tokenları `users/{uid}/fcmTokens/{tokenId}` alt koleksiyonuna taşındı.
- Admin yetkisi Firestore `role` alanından Firebase Auth custom claim `admin == true` modeline taşındı.
- Story Storage write/delete işlemleri admin custom claim'e bağlandı ve `application/octet-stream` kabulü kaldırıldı.
- Admin route'ları client tarafında custom claim guard ile korundu ve 403 erişim reddi ekranı netleştirildi.
- Review create/update kuralları schema whitelist, pending-first moderation ve immutable alan korumasıyla sıkılaştırıldı.
- Parent `reviews/{reviewId}.likes` client write'a kapatıldı; like sayımı Cloud Function ile server-side senkronlanacak hale getirildi.
- Yorum create/edit sonrası moderation function temiz içeriği otomatik onaylayacak, uygunsuz içeriği onaysız bırakacak şekilde güncellendi.
- Üniversite/user review count hesaplamaları onaylı yorumlara göre çalışacak şekilde düzeltildi.
- AI tercih önerisi enrichment function'ı Pro entitlement kontrolü, atomik günlük quota (10/gün), kısa pencere rate limit (12/dk) ve App Check hazırlık yorumuyla sertleştirildi.
- AI öneri cache hit'leri günlük kotadan düşmeyecek; gerçek Groq çağrıları transaction içinde hak tüketecek şekilde düzenlendi.
- Flutter tarafında Firebase App Check aktive edildi; debug build'lerde debug provider, release Android'de Play Integrity, release Apple platformlarında App Attest + DeviceCheck fallback kullanılacak.
- Kritik callable Cloud Functions için App Check zorunlu hale getirildi: `verifyStudentUniversity`, `generateComparisonSummary`, `enrichRecommendations`, `trackAnalyticsEvent`, `incrementPreferenceListView`, `performAdminModerationAction`, `submitReviewReport`, `submitFeedback`.
- Firestore analytics sayaçları client write'a kapatıldı; event yazımları App Check zorunlu `trackAnalyticsEvent` callable function'ına taşındı.
- Analytics event adları server-side whitelist'e alındı ve kullanıcı başına kısa pencere rate limit eklendi.
- `trackAnalyticsEvent` callable için accepted/rejected/failed structured log alanları, invalid payload/rate limit/write failure ayrımı ve Cloud Logging alert filtreleri eklendi.
- Preference list `viewCount` client write'a kapatıldı; görüntülenme sayacı App Check zorunlu `incrementPreferenceListView` callable function'ına taşındı.
- Preference list create/update kuralları schema whitelist, immutable alan koruması, server timestamp zorunluluğu ve item payload doğrulamasıyla sıkılaştırıldı.
- Admin moderasyon aksiyonları `performAdminModerationAction` callable function'ına taşındı; report/feedback/review güncelleme, gizleme ve silme işlemleri App Check + admin custom claim ile server-side yapılıyor ve `adminAuditLogs` koleksiyonuna Admin SDK üzerinden loglanıyor.
- Report ve feedback gönderimleri doğrudan Firestore client write yerine App Check zorunlu `submitReviewReport` / `submitFeedback` callable function'larına taşındı; duplicate report, kısa pencere rate limit ve `suspiciousActivityLogs` kaydı server-side uygulanıyor.
- `usageStats` başlangıç dokümanı Firestore rules tarafında whitelist/zero-counter validasyonuna alındı.
- Günlük quota reset job'u ve RevenueCat webhook'u `lastAiRecommendationResetDate` alanıyla AI öneri reset takibini tutarlı hale getirecek şekilde güncellendi.
- Firestore rules testleri emulator ile çalışır hale getirildi ve kritik exploit senaryoları eklendi.
- Admin ekranlarındaki story summary, reports summary, stats kartları, detail sheet aksiyonları ve uzun metin satırları responsive davranacak şekilde düzeltildi.

Son doğrulama çıktıları:

| Komut | Sonuç |
| --- | --- |
| `npm run build` (`functions`) | Başarılı |
| `npm test` (`rules-tests`) | Başarılı, 37 test geçti |
| `flutter analyze` | Başarılı |
| `flutter test` | Başarılı, 74 test geçti |
| `./gradlew :app:lintDebug` | Başarılı. 0 hata, 15 uyarı |
| `flutter build apk --debug` | Başarılı |

## 1. Yönetici Özeti

Uygulama genel olarak geniş bir ürün yüzeyine sahip: öğrenci doğrulama, yorumlar, favoriler, tercih listeleri, admin panelleri, hikayeler, bildirimler, abonelikler, AI karşılaştırma/öneri özellikleri ve Firebase tabanlı sunucu işlevleri bulunuyor. Flutter tarafında statik analiz ve birim/widget testleri temiz geçti; Cloud Functions TypeScript build de geçti. Buna karşın Firebase güvenlik kurallarında birkaç kritik açık var.

En önemli risk, `users/{userId}` dokümanlarının herkese okunabilir ve kullanıcı sahibine çok geniş yazılabilir olmasıdır. Aynı dokümanda `role`, `email`, `fcmTokens`, `universityId`, `reviewCount` gibi hassas ve yetki etkileyen alanlar tutuluyor. Firestore `isAdmin()` fonksiyonu da adminliği bu kullanıcı dokümanındaki `role == 'admin'` alanından okuduğu için, bir kullanıcı kendi dokümanında `role` alanını değiştirebilirse admin yetkisi kazanabilir. Bu, veritabanı yazma yetkilerinin, admin panellerinin ve içerik yönetiminin bütünlüğünü etkileyen kritik bir yetki yükseltme riskidir.

İkinci kritik risk, kullanıcı dokümanlarının `allow read: if true` ile herkese açılmasıdır. Uygulama kodunda public profil okurken `email` ve `fcmTokens` client tarafında maskeleniyor; fakat Firestore kuralları doküman seviyesinde çalıştığı için doğrudan Firestore okuması yapan herhangi biri bu alanları okuyabilir. Bu durum e-posta, FCM token, bildirim tercihleri, rol ve okul bilgileri gibi özel verilerin sızmasına yol açabilir.

Yorum/moderasyon tarafında da yüksek riskli bütünlük sorunları var. Yorum oluşturma kuralı `isApproved`, `likes`, `createdAt`, `targetId`, `type`, metin uzunlukları ve görsel sayısı gibi alanları yeterince doğrulamıyor. Modelde `isApproved` varsayılan olarak `true`; moderasyon fonksiyonu sadece yorum oluşturulduğunda çalışıyor. Kullanıcı, güncelleme kuralı sayesinde kendi yorumunun birçok alanını sonradan değiştirebilir ve onay durumunu manipüle edebilir. Beğeni sayısı da doğrudan sayı olarak değiştirilebilir.

Storage tarafında `/stories/{fileName}` yazma izni tüm giriş yapmış kullanıcılara açık. Firestore story dokümanları admin kontrolü yapıyor olsa da medya dosyası yükleme kuralı admin kontrolü yapmadığı için herhangi bir authenticated kullanıcı story bucket alanına 100 MB'a kadar medya yükleyebilir. Bu hem maliyet hem de içerik güvenliği açısından yüksek risklidir.

UI tarafında otomatik Flutter analizinde hata bulunmadı. Admin story istatistik satırı, rapor özet kartı, stats kart gridleri, detail sheet aksiyonları ve uzun metin satırlarında tespit edilen başlıca responsive taşma riskleri kod tarafında giderildi. Görsel taşmaları otomatik yakalamak için küçük genişlik ve yüksek text scale widget/golden testleri hâlâ eklenebilir.

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
| `flutter test` | Başarılı. 74 test geçti. |
| `npm run build` (`functions`) | Başarılı. TypeScript build geçti. |
| `npm run lint` (`functions`) | Başarılı. ESLint config eklendi ve hata yok. |
| `npm audit --omit=dev --audit-level=high` (`functions`) | Başarılı. High/critical açık yok; moderate `uuid` zinciri dependency migration maddesinde takip edilmeli. |
| `flutter pub outdated` | Birçok paket major sürüm gerisinde. Firebase, go_router, notifications, ads ve permission paketleri özellikle eski. |
| `npm test` (`rules-tests`) | Başarılı. Firestore emulator ile 37 test geçti. |
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
| Kritik | Firestore users/admin | Kullanıcı kendi `role` alanını değiştirerek admin olabilir | Tam yetki yükseltme, admin verilerine/yazmalarına erişim |
| Kritik | Firestore users/privacy | Tüm kullanıcı dokümanları herkese okunabilir | E-posta, FCM token, rol ve profil verisi sızıntısı |
| Yüksek | Reviews/moderation | Yorum onayı, beğeni, içerik ve tarih alanları client tarafından manipüle edilebilir | Sahte/uygunsuz içerik, puan ve beğeni manipülasyonu |
| Yüksek | Users/universityId | Kullanıcı kendi `universityId` alanını değiştirebilir | Başka üniversite adına yorum yazma |
| Yüksek | Storage stories | Tüm authenticated kullanıcılar story medyası yükleyebilir | Maliyet, içerik güvenliği, bucket kirliliği |
| Yüksek | Functions AI | Recommendation enrichment quota/rate limit ve callable App Check enforcement eklendi | Firebase Console provider ayarları/debug token kaydı yapılmazsa client çağrıları reddedilir |
| Orta | Analytics | Client analytics write kapatıldı; server-side callable endpoint'e taşındı | Debug token/App Check olmadan client event çağrıları reddedilir |
| Orta | Preference lists | `viewCount` client write kapatıldı; liste schema validasyonu eklendi | App Check function deploy edilmeden eski client sayaç artıramaz |
| Orta (giderildi) | Admin route | `/admin*` rotaları custom claim guard ve 403 ekranıyla kapatıldı | Admin olmayan kullanıcı admin UI'a erişemeden engellenir |
| Orta | Android lint | Manifest/style hataları var | Release kalitesi ve bazı cihazlarda runtime uyumsuzluk riski |
| Orta | Dependency | Functions dependency audit açıkları var | Transitive paket açıkları, bakım riski |

## 4. Kritik ve Yüksek Güvenlik Bulguları

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

Kanıt:

- `firestore.rules:61-77`: review create/update kuralları sınırlı doğrulama yapıyor.
- `firestore.rules:65-71`: create sırasında sadece verified student, `userId`, `universityId` ve rating aralığı kontrol ediliyor.
- `firestore.rules:73-77`: owner update sırasında `userId` değişmemesi yeterli; diğer alanlar serbest.
- `lib/features/reviews/domain/models/review_model.dart:47-50`: `likes = 0`, `isApproved = true` varsayılanları.
- `lib/features/reviews/domain/models/review_model.dart:85-105`: `isApproved`, `likes`, `createdAt`, `updatedAt`, `imageUrls`, `categoryRatings` Firestore'a yazılıyor.
- `functions/src/moderation.ts:50-74`: moderasyon yalnızca `onDocumentCreated` ile yeni yorumda çalışıyor.
- `lib/features/reviews/data/review_repository.dart:38-43`: update sırasında `createdAt` yeniden `serverTimestamp()` yapılıyor.

Etki:

- Kullanıcı yorum oluştururken `isApproved: true` gönderebilir.
- Uygunsuz içerik yorum oluşturulduktan sonra update ile eklenebilir; moderation function tekrar çalışmaz.
- Kullanıcı kendi yorumunda `rating`, `type`, `targetId`, `universityId`, `categoryRatings`, `likes`, `imageUrls`, `createdAt` ve `isApproved` gibi alanları manipüle edebilir.
- Beğeni sayısı yalnızca alt koleksiyondaki like dokümanlarına bağlı değil; parent review dokümanında arbitrary `likes` update yapılabilir.
- Puan ortalamaları ve moderation kuyruğu güvenilmez hale gelir.

Önerilen düzeltme:

- Create kuralında tüm alanları beyaz listeye alın.
- Create sırasında `isApproved == false`, `likes == 0` zorunlu olsun.
- `createdAt` ve `updatedAt` server timestamp yaklaşımıyla backend veya kural düzeyinde tutarlı hale getirilsin.
- Owner update sadece içerik alanlarıyla sınırlansın: `comment`, `pros`, `cons`, `imageUrls`, `categoryRatings`, `updatedAt`.
- İçerik değiştiğinde `isApproved` otomatik `false` yapılmalı ve yeniden moderasyona girmeli.
- `likes` parent dokümanında client tarafından yazılmamalı. Like işlemi `reviews/{reviewId}/likes/{uid}` alt koleksiyonu + Cloud Function aggregation veya transaction ile yönetilmeli.
- `createdAt` update sırasında değiştirilmemeli; repository bug'ı düzeltilmeli.
- Moderasyon fonksiyonu `onDocumentWritten` veya `onDocumentUpdated` için de çalışmalı.

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

### 6.1 Profil ve review image MIME doğrulaması zayıf

Kanıt:

- `storage.rules:6-11`: profil fotoğrafı için `image/.*` ve 5 MB limiti.
- `storage.rules:15-20`: review image için `image/.*` ve 10 MB limiti.

Etki:

`contentType` client metadata'sına dayanır. Bu, gerçek dosya içeriğini garanti etmez. Ayrıca review image alanında kullanıcı başına kaç dosya yükleneceği veya dosyanın gerçek bir review ile ilişkisi doğrulanmıyor.

Önerilen düzeltme:

- MIME whitelist'i daraltın: `image/jpeg`, `image/png`, `image/webp`.
- Dosya adında extension ve UID/reviewId formatı zorunlu olsun.
- Review başına maksimum görsel sayısı uygulayın.
- Upload sonrası Cloud Function ile metadata/content doğrulaması ve gerekiyorsa malware/image scanning ekleyin.

### 6.2 Storage delete davranışı story tarafında orphan dosya riski oluşturabilir

Kanıt:

- `storage.rules:24-28`: story write kuralı `request.resource` üzerinden size/type kontrol ediyor.
- Delete işlemlerinde `request.resource` yoktur; bu kural delete'i de kapsadığı için client delete akışı başarısız olabilir.

Etki:

Admin panel dokümanı silse bile Storage dosyaları silinemeyebilir ve orphan medya maliyet oluşturabilir.

Önerilen düzeltme:

- Delete'i Admin SDK Cloud Function ile yapın.
- Alternatif olarak admin custom claim ile ayrı delete kuralı yazın.
- Story dokümanı silindiğinde Storage cleanup trigger ekleyin.

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

### 7.2 Release signing debug fallback riski

Kanıt:

- `android/app/build.gradle.kts:63-70`: release build, `key.properties` yoksa debug signing kullanıyor.

Etki:

CI veya release ortamında yanlışlıkla debug imzalı build üretilebilir. Bu, store dağıtımı, güvenlik ve release güvenilirliği açısından risklidir.

Önerilen düzeltme:

- Release build'de keystore yoksa build fail olmalı.
- Debug fallback sadece local development flavor'ında kalmalı.
- CI environment için zorunlu secret/keystore kontrolü eklenmeli.

### 7.3 AdMob production App ID fallback riski

Kanıt:

- `android/app/build.gradle.kts:45-49`: `ADMOB_APP_ID` verilmezse Google test App ID kullanılıyor.

Etki:

Production build yanlışlıkla test AdMob ID ile çıkabilir; gelir kaybı veya policy sorunları doğabilir.

Önerilen düzeltme:

- Release build'de `ADMOB_APP_ID` zorunlu olsun.
- Debug/profile için test ID kullanılabilir.
- CI'da release config validation ekleyin.

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
- Tam `firebase deploy --only functions`, uzakta kaynakta olmayan `revenuecatWebhook(us-central1)` bulunduğu için silme onayı gerektiriyor; bu orphan function ayrıca ele alınmalı.
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

### 7.6 Firestore rules test paketi çalışır durumda değil

Kanıt:

- `rules-tests/package.json:5-7`: `npm test` placeholder ve her zaman fail ediyor.
- `npx mocha test.js` Firestore emulator host/port ayarı olmadan fail ediyor.
- Testlerde adminliği custom claim ile simüle etme eğilimi varsa mevcut rules kodu `users/{uid}.role` okuduğu için test modeli üretim kuralıyla birebir uyuşmayabilir.

Önerilen düzeltme:

- `firebase emulators:exec --only firestore "npx mocha test.js"` şeklinde çalışan bir test script'i ekleyin.
- Rules tests içinde önce kullanıcı dokümanları seed edilmeli veya kurallar custom claim'e taşındıktan sonra testler ona göre yazılmalı.
- Kritik test senaryoları:
  - Kullanıcı kendi `role` alanını admin yapamamalı.
  - Başka kullanıcının `email`/`fcmTokens` alanı okunamamalı.
  - Yorum create `isApproved: true` ile reddedilmeli.
  - Owner yorum update `likes`/`createdAt`/`userId`/`universityId` değiştirememeli.
  - Story storage upload admin olmayan kullanıcıda reddedilmeli.
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

## 10. Acil Düzeltme Planı

### İlk 24 saat

1. Firestore `users` kuralını kilitleyin:
   - `allow read: if isOwner(userId) || isAdmin()`.
   - Public profil için ayrı koleksiyon hazırlanana kadar public user read'i kapatın.
   - Owner update alanlarını beyaz listeye alın.

2. Adminliği custom claim'e taşıyın:
   - `isAdmin()` artık `request.auth.token.admin == true` kullanmalı.
   - Firestore user `role` alanı yalnızca UI/display amaçlıysa bile güvenlikte kullanılmamalı.

3. Story Storage write kuralını admin-only yapın:
   - `request.auth.token.admin == true`.
   - `application/octet-stream` kaldırın.

4. Review create/update kurallarını sıkılaştırın:
   - `isApproved == false`, `likes == 0`.
   - Owner update alanlarını sınırlandırın.
   - Parent `likes` client write'ı kapatın.

### İlk 3 gün

1. `publicProfiles` ayrımını uygulayın.
2. FCM tokenları owner-only alt koleksiyona taşıyın.
3. Review moderation'ı update sonrası da çalışır hale getirin.
4. University aggregation'a `isApproved == true` filtresi ekleyin.
5. Rules tests'i emulator ile çalışan hale getirin ve kritik exploit senaryolarını test edin.
6. Android lint hatalarını temizleyin. (Tamamlandı; 0 hata, 15 uyarı)

### İlk 7 gün

1. Functions dependency upgrade planını uygulayın. (Kısmen tamamlandı; Node 22 + `firebase-functions@7` + `firebase-admin@13.10` uygulandı, Admin SDK 14 modular migration ayrı iş olarak kaldı)
2. Firebase Console App Check provider ayarlarını ve debug token kayıtlarını tamamlayın.
3. Analytics dashboard için server-side event doğrulama loglarını ve alert'leri izleyin. (Kod ve log filtreleri tamamlandı; Console alert policy kurulumu manuel takip işi)
4. Preference list callable deploy ve Android client rebuild akışını tamamlayın.
5. Admin route guard ve 403 ekranı ekleyin. (Tamamlandı)
6. Admin UI responsive taşma risklerini düzeltin. (Tamamlandı)
7. CI pipeline'a şu gate'leri koyun. (Tamamlandı)
   - `flutter analyze`
   - `flutter test`
   - `npm run build` (`functions`)
   - `npm run lint` (`functions`)
   - `npm audit --omit=dev --audit-level=high` (`functions`)
   - Firestore rules emulator tests
   - `./gradlew :app:lintDebug`
   - `./gradlew :app:assembleDebug`
8. Admin action audit log ekleyin ve kritik admin aksiyonlarını callable function'a taşıyın. (Tamamlandı; `performAdminModerationAction` App Check + admin custom claim zorunlu, `adminAuditLogs` server-side yazılıyor)

## 11. Geliştirilebilecek veya Eklenebilecek Özellikler

### 11.1 Güvenlik ve güvenilirlik özellikleri

- Firebase App Check Console provider ayarları ve debug token kayıt süreci release checklist'e bağlanmalı.
- Admin action audit log ve kritik admin moderation callable akışı eklendi; sonraki sertleştirme adımı admin audit log görüntüleme/filtreleme ekranı ve alert kurallarıdır.
- Suspicious activity log başlangıcı eklendi: duplicate report attempt, report rate limit ve feedback rate limit olayları `suspiciousActivityLogs` koleksiyonuna Admin SDK ile yazılıyor; fazla upload, fazla AI çağrısı ve başarısız admin erişimleri hâlâ genişletme maddesidir.
- Rate limit sistemi eklenmeli:
  - Review oluşturma.
  - Report gönderme. (Tamamlandı; `submitReviewReport`, 10 dakikada 5 istek)
  - Feedback gönderme. (Tamamlandı; `submitFeedback`, 10 dakikada 3 istek)
  - Story upload.
  - AI recommendation/summary çağrıları. (Tamamlandı)
- Server-side schema validation standardı oluşturulmalı.
- Storage upload sonrası otomatik cleanup ve güvenlik taraması eklenmeli.
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
  - Review create `isApproved: true` ile reddedilmeli.
  - Review update `likes`, `createdAt`, `userId`, `universityId` değiştirememeli.
  - Preference list viewCount arbitrary set edilememeli.
  - Preference list create/update immutable alan ve item schema ihlalleri reddedilmeli.
  - Analytics direct client write reddedilmeli.

- Storage:
  - Admin olmayan kullanıcı story upload yapamamalı.
  - `application/octet-stream` story upload reddedilmeli.
  - Profil fotoğrafında sadece beklenen MIME türleri kabul edilmeli.
  - Review image count/path kısıtları test edilmeli.

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

Uygulamanın ürün kapsamı güçlü ve bazı iyi güvenlik temelleri mevcut; ancak Firestore kullanıcı dokümanı yetkileri, admin role modeli, public user read, review moderation bütünlüğü ve Story Storage kuralları acil düzeltilmeli. Bu açıklar production ortamında ciddi yetki yükseltme, veri sızıntısı, içerik manipülasyonu ve maliyet abuse riskleri doğurabilir.

En güvenli sıra şu olmalı:

1. `users` dokümanı read/write kurallarını kilitle.
2. Adminliği custom claim'e taşı.
3. Public/private profil ayrımını yap.
4. Review create/update ve moderation akışını sıkılaştır.
5. Story Storage write'ı admin-only yap.
6. Rules tests ve CI gate'lerini çalışır hale getir.
7. Android lint ve dependency audit açıklarını temizle.

Bu adımlar tamamlandığında uygulamanın güvenlik tabanı çok daha sağlam hale gelir; sonrasında UI responsive iyileştirmeleri, admin ergonomisi, observability ve ürün özellikleri daha güvenli bir zemin üzerinde geliştirilebilir.
