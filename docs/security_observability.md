# Security Observability

Tarih: 2026-06-15

Bu doküman admin moderasyon, review/report/feedback submit akışı ve şüpheli aktivite kayıtları için izleme/alert planını tanımlar.

## Kapsam

İzlenen güvenlik yüzeyleri:

- `performAdminModerationAction` callable function.
- `getReviewSubmissionStatus` callable function.
- `submitReview` callable function.
- `submitReviewReport` callable function.
- `submitFeedback` callable function.
- `adminAuditLogs` Firestore koleksiyonu.
- `suspiciousActivityLogs` Firestore koleksiyonu.
- `cleanupDeletedReviewMedia` / `cleanupDeletedStoryMedia` Storage cleanup trigger'ları.

## Structured Log Alanları

### Admin Moderation

`performAdminModerationAction` loglarında kullanılan ana alanlar:

| Alan | Açıklama |
| --- | --- |
| `component` | `admin.performModerationAction` |
| `uid` | Çağrıyı yapan kullanıcı ID'si |
| `action` | İstenen admin aksiyonu |
| `type` | Şüpheli olay tipi. Örn. `failed_admin_callable_access` |
| `reason` | Red sebebi. Örn. `unauthenticated`, `missing_admin_claim` |
| `requestedAction` | Yetkisiz çağrıda gönderilen aksiyon adı |
| `appCheckPresent` | Handler'a ulaşan çağrıda App Check bilgisi var mı |
| `appId` | App Check app ID |

### User Submissions

`getReviewSubmissionStatus`, `submitReview`, `submitReviewReport` ve `submitFeedback` loglarında kullanılan ana alanlar:

| Alan | Açıklama |
| --- | --- |
| `component` | `reviews.submitReview` veya `abuse.userSubmissions` |
| `uid` | Çağrıyı yapan kullanıcı ID'si |
| `type` | Şüpheli olay tipi |
| `targetId` | Review oluşturulan hedef ID |
| `universityId` | Review üniversite ID'si |
| `reviewId` | Şikayet edilen yorum |
| `reason` | Report nedeni veya rate limit metadata sebebi |
| `nextCount` | Rate limit penceresindeki denenen sayaç |
| `limit` | Pencere limiti |
| `windowAgeMs` | Aktif pencerenin yaşı |
| `appId` | App Check app ID |

## Cloud Logging Filtreleri

Başarısız admin callable erişimleri:

```text
jsonPayload.component="admin.performModerationAction"
jsonPayload.type="failed_admin_callable_access"
```

Admin claim olmayan kullanıcının admin callable denemesi:

```text
jsonPayload.component="admin.performModerationAction"
jsonPayload.type="failed_admin_callable_access"
jsonPayload.reason="missing_admin_claim"
```

Girişsiz admin callable denemesi:

```text
jsonPayload.component="admin.performModerationAction"
jsonPayload.type="failed_admin_callable_access"
jsonPayload.reason="unauthenticated"
```

Başarılı admin moderasyon aksiyonları:

```text
jsonPayload.component="admin.performModerationAction"
jsonPayload.message="Admin moderation action accepted"
```

Tüm kullanıcı submission şüpheli aktiviteleri:

```text
(
  jsonPayload.component="reviews.submitReview" OR
  jsonPayload.component="abuse.userSubmissions"
)
jsonPayload.message="Suspicious activity logged"
```

Review create rate limit:

```text
jsonPayload.component="reviews.submitReview"
jsonPayload.type="review_create_rate_limited"
```

Report rate limit:

```text
jsonPayload.component="abuse.userSubmissions"
jsonPayload.type="report_rate_limited"
```

Feedback rate limit:

```text
jsonPayload.component="abuse.userSubmissions"
jsonPayload.type="feedback_rate_limited"
```

Tekrarlı report denemesi:

```text
jsonPayload.component="abuse.userSubmissions"
jsonPayload.type="duplicate_report_attempt"
```

Storage cleanup sonucu:

```text
jsonPayload.component="storage.cleanupDeletedMedia"
jsonPayload.message="Storage media cleanup complete"
```

Storage cleanup hatası:

```text
jsonPayload.component="storage.cleanupDeletedMedia"
jsonPayload.message="Storage media cleanup failed"
```

Callable App Check reject izleme:

```text
resource.type="cloud_run_revision"
(
  resource.labels.service_name="performadminmoderationaction" OR
  resource.labels.service_name="getreviewsubmissionstatus" OR
  resource.labels.service_name="submitreview" OR
  resource.labels.service_name="submitreviewreport" OR
  resource.labels.service_name="submitfeedback"
)
httpRequest.status=401
```

## Önerilen Alert'ler

| Alert | Filtre | Eşik |
| --- | --- | --- |
| Failed admin access | `failed_admin_callable_access` | 5 dakika içinde 1+ |
| Missing admin claim spike | `reason="missing_admin_claim"` | 10 dakika içinde 3+ |
| Review create rate limit spike | `type="review_create_rate_limited"` | 10 dakika içinde 5+ |
| Report rate limit spike | `type="report_rate_limited"` | 10 dakika içinde 5+ |
| Feedback rate limit spike | `type="feedback_rate_limited"` | 10 dakika içinde 5+ |
| Duplicate report spike | `type="duplicate_report_attempt"` | 10 dakika içinde 10+ |
| Storage cleanup failure | `component="storage.cleanupDeletedMedia"` ve `message="Storage media cleanup failed"` | 10 dakika içinde 1+ |
| App Check reject spike | callable 401 filtresi | 10 dakika içinde 10+ veya debug rollout baseline'ı üstü |
| Destructive admin action | `action="review_deleted"` veya `action="feedback_deleted"` | 5 dakika içinde 1+ bilgi alert'i |

## Firebase Console Kurulum Adımları

1. Google Cloud Console > Logging > Logs Explorer ekranını açın.
2. Yukarıdaki filtrelerden birini query alanına yapıştırın.
3. `Create alert` seçin.
4. Alert adını tabloyla aynı tutun.
5. Rolling window değerini eşik tablosuna göre seçin.
6. Notification channel olarak e-posta veya mobil bildirim kanalını seçin.
7. Alert policy'yi kaydedin.

## Manuel Doğrulama Kontrol Listesi

- Normal admin aksiyonu sonrası `adminAuditLogs` koleksiyonunda kayıt oluşmalı.
- Normal admin aksiyonu sonrası Cloud Logging'de `Admin moderation action accepted` görünmeli.
- Admin claim'i olmayan kullanıcı callable çağırırsa `suspiciousActivityLogs` içinde `failed_admin_callable_access` oluşmalı.
- Aynı deneme Cloud Logging'de `reason="missing_admin_claim"` ile görünmeli.
- Review oluşturma rate limit aşımında `review_create_rate_limited` kaydı oluşmalı.
- Aynı yorumu tekrar report eden kullanıcı için `duplicate_report_attempt` kaydı oluşmalı.
- Report/feedback rate limit aşımında `report_rate_limited` veya `feedback_rate_limited` kaydı oluşmalı.
- Review/story dokümanı silinince Cloud Logging'de `Storage media cleanup complete` görünmeli.
- Debug App Check token Console'dan kaldırıldığında callable request loglarında 401 görünmeli.
