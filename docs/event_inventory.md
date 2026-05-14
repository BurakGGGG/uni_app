# Analytics Event Inventory

> Son güncelleme: Sprint 5 — Gün 6

Bu belge, uygulamadaki tüm Firebase Analytics event'lerini ve durumlarını listeler.

## Durum Açıklamaları

| Simge | Anlam |
|-------|-------|
| ✅ | Implement edilmiş ve çalışıyor |
| ⚠️ | Henüz implement edilmemiş |
| 🔄 | Kısmen implement, tamamlanması gerekiyor |

---

## Event Listesi

| Event Name | When Fired | Properties | Dosya | Audit Status |
|-----------|-----------|-----------|-------|--------------|
| `comparison_started` | Karşılaştırma başlatıldı | `type`, `user_tier` | `analytics_service.dart` | ✅ |
| `paywall_shown` | Paywall ekranı görüldü | `trigger`, `user_tier` | `analytics_service.dart` | ✅ |
| `subscription_purchased` | Satın alma başarılı | `tier`, `billing` | `analytics_service.dart` | ✅ |
| `ad_watched` | Rewarded reklam izlendi | `result`, `daily_comparison_count` | `analytics_service.dart` | ✅ |
| `compare_dept` | Bölüm karşılaştırma | `deptA_id`, `deptB_id` | — | ⚠️ Implement |
| `compare_city` | Şehir karşılaştırma | `cityA_id`, `cityB_id` | — | ⚠️ Implement |
| `triple_compare` | 3-way karşılaştırma | `tier`, `uniA_id`, `uniB_id`, `uniC_id` | — | ⚠️ Implement |
| `note_added` | Karşılaştırma notu eklendi | `comparison_type`, `note_length` | — | ⚠️ Implement |
| `note_deleted` | Karşılaştırma notu silindi | `note_id` | — | ⚠️ Implement |
| `paywall_restore` | Restore purchases başarılı | `restored_tier` | — | ⚠️ Implement |
| `review_write` | Yorum yazıldı | `rating`, `length`, `anonymous`, `type` | — | ⚠️ Implement |
| `review_like` | Yorum beğenildi | `review_id` | — | ⚠️ Implement |
| `review_delete` | Yorum silindi | `review_id`, `type` | — | ⚠️ Implement |
| `recommendation_started` | Öneri sihirbazı başlatıldı | `user_tier` | — | ⚠️ Implement |
| `recommendation_completed` | Öneri sonuç ekranı gösterildi | `result_count`, `top_uni` | — | ⚠️ Implement |
| `profile_view` | Başka kullanıcı profili görüntülendi | `viewed_user_id` | — | ⚠️ Implement |
| `share_comparison` | Karşılaştırma paylaşıldı | `type`, `uniA_id`, `uniB_id` | — | ⚠️ Implement |

---

## Build Konfigürasyonu

Analytics event'leri Firebase Analytics üzerinden gönderilmektedir.
Event isimleri Firebase'in 40 karakter ve snake_case kısıtlamalarına uygundur.

## Notlar

- `comparison_started` event'i hem üniversite hem bölüm hem şehir karşılaştırması
  için `type` parametresi ile ayrıştırılmaktadır.
- `⚠️ Implement` durumundaki event'ler Sprint 6 veya sonrasında eklenecektir.
- Tüm event'ler `_safeLog` wrapper'ı ile gönderilir, hata durumunda sessizce loglanır.
