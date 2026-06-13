# Analytics Observability

Tarih: 2026-06-14

Bu doküman `trackAnalyticsEvent` callable function'ının server-side doğrulama, log ve alert izleme planını tanımlar.

## Kapsam

`trackAnalyticsEvent` şunları backend tarafında uygular:

- Firebase Auth zorunluluğu.
- Firebase App Check enforcement.
- Event adı whitelist doğrulaması.
- Tek callable çağrısında en fazla 10 event.
- Kullanıcı başına 60 saniyede en fazla 120 event.
- `universityViewed` için zorunlu `universityId` ve `universityName`.
- Firestore counter yazımları:
  - `analytics/counters`
  - `analytics/daily_yyyy-MM-dd`
  - `analytics/topUniversities/items/{universityId}`

## Structured Log Alanları

Function logları şu ortak alanlarla yazılır:

| Alan | Açıklama |
| --- | --- |
| `component` | Sabit değer: `analytics.trackAnalyticsEvent` |
| `outcome` | `accepted`, `rejected` veya `failed` |
| `reason` | Red veya hata sebebi |
| `code` | Callable hata kodu |
| `uid` | Authenticated kullanıcı ID'si |
| `appCheckPresent` | Handler'a ulaşan çağrıda App Check verisi var mı |
| `appId` | App Check app ID |
| `eventCount` | Çağrıdaki event sayısı |
| `eventCounts` | Event bazlı sayaç kırılımı |
| `topUniversityUpdated` | Top universities dokümanı güncellendi mi |

Not: App Check token geçersizse istek handler'a düşmeden Firebase tarafından 401 döner. Bu yüzden custom `jsonPayload.component` logu oluşmaz; Cloud Run request logları izlenmelidir.

## Cloud Logging Filtreleri

Başarılı analytics event yazımları:

```text
jsonPayload.component="analytics.trackAnalyticsEvent"
jsonPayload.outcome="accepted"
```

Tüm reddedilen analytics çağrıları:

```text
jsonPayload.component="analytics.trackAnalyticsEvent"
jsonPayload.outcome="rejected"
```

Rate limit reddi:

```text
jsonPayload.component="analytics.trackAnalyticsEvent"
jsonPayload.reason="rate_limited"
```

Geçersiz event veya payload:

```text
jsonPayload.component="analytics.trackAnalyticsEvent"
(
  jsonPayload.reason="missing_event" OR
  jsonPayload.reason="too_many_events" OR
  jsonPayload.reason="invalid_event_type" OR
  jsonPayload.reason="invalid_event_name" OR
  jsonPayload.reason="missing_university_payload" OR
  jsonPayload.reason="invalid_university_length" OR
  jsonPayload.reason="invalid_university_id_format"
)
```

Firestore yazma hatası:

```text
severity>=ERROR
jsonPayload.component="analytics.trackAnalyticsEvent"
jsonPayload.reason="write_failed"
```

App Check 401 izleme:

```text
resource.type="cloud_run_revision"
resource.labels.service_name="trackanalyticsevent"
httpRequest.status=401
```

## Önerilen Alert'ler

| Alert | Filtre | Eşik |
| --- | --- | --- |
| Analytics write failure | `reason="write_failed"` | 5 dakika içinde 1+ |
| Rate limit spike | `reason="rate_limited"` | 10 dakika içinde 20+ |
| Invalid payload spike | Geçersiz payload filtresi | 10 dakika içinde 10+ |
| App Check reject spike | `httpRequest.status=401` | Debug token rollout sonrası baseline'a göre |

## Manuel Doğrulama Kontrol Listesi

- Normal kullanıcıyla üniversite detay ekranına girildiğinde `outcome="accepted"` logu görünmeli.
- `analytics/counters.totalUniversityViews` artmalı.
- `analytics/daily_yyyy-MM-dd.universityViews` artmalı.
- `analytics/topUniversities/items/{universityId}.viewCount` artmalı.
- Geçersiz event adı gönderilirse `reason="invalid_event_name"` logu görünmeli.
- 10'dan fazla event tek çağrıda gönderilirse `reason="too_many_events"` logu görünmeli.
- Kısa sürede 120'den fazla event denenirse `reason="rate_limited"` logu görünmeli.
- App Check debug token kaldırılmış debug cihazdan çağrı yapılırsa request loglarında 401 görünmeli.
