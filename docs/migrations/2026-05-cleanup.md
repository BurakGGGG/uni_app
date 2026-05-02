# Sprint 4 — Üniversite Veri Temizliği (2026-05)

## Amaç
Place verisi olmayan 7 üniversiteyi seed data'dan ve Firestore'dan kaldırmak.

## Silinen Üniversiteler
| ID | İsim | Şehir |
|---|---|---|
| bogazici | Boğaziçi Üniversitesi | İstanbul |
| koc | Koç Üniversitesi | İstanbul |
| sabanci | Sabancı Üniversitesi | İstanbul |
| bilgi | İstanbul Bilgi Üniversitesi | İstanbul |
| bilkent | İhsan Doğramacı Bilkent Üniversitesi | Ankara |
| iyte | İzmir Yüksek Teknoloji Enstitüsü | İzmir |
| yasar | Yaşar Üniversitesi | İzmir |

## Güncellenen Şehir Sayıları
| Şehir | Eski | Yeni |
|---|---|---|
| İstanbul | 10 | 6 |
| Ankara | 6 | 5 |
| İzmir | 6 | 4 |

## Playbook

### 1. Dev ortamında test
```bash
flutter run
# Profil > Seed Data > CleanupUniversities().run()
# Dry-run çıktısını kontrol et
```

### 2. Staging'de çalıştır
```bash
# Firebase projesini staging'e çevir
firebase use staging

# Uygulamayı staging'e bağlayıp seed data'yı yeniden yükle
flutter run --dart-define=ENV=staging
# Profil > Seed Data > uploadSeedData() (yeni data)
# Ardından: CleanupUniversities().run(execute: true)
```

### 3. Prod'da çalıştır
```bash
firebase use production

# ÖNCELİKLE: Firestore backup al
gcloud firestore export gs://unisec-backup/2026-05-cleanup

# Uygulamayı prod'a bağla
flutter run --dart-define=ENV=production
# CleanupUniversities().run()  # Önce dry-run
# CleanupUniversities().run(execute: true)  # Sonra execute
```

## Güvenlik Kuralları
- ⚠️ **Yorum olan üniversite asla silinmez** — script otomatik atlar
- 🔄 **Cascade delete**: Üniversite + bağlı bölümler birlikte silinir
- 📋 **Dry-run zorunlu**: Her ortamda önce `execute: false` ile çalıştır
- 💾 **Backup zorunlu**: Prod'da çalıştırmadan önce Firestore export al
