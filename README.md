# ÜniSeç 🎓

Türkiye'deki üniversiteleri keşfet, karşılaştır ve değerlendir.

## 📱 Özellikler

### Üniversite Keşfi
- **208+ üniversite** — devlet ve vakıf üniversiteleri, şehir bazlı filtreleme
- **Bölüm detayları** — taban puanları, fakülte bilgileri, dil seçenekleri
- **Mekan rehberi** — kafe, yurt, kütüphane, spor tesisleri, çalışma alanları
- **Haritada göster** — mekanları Google Maps / Apple Maps'te aç

### Değerlendirme & Sosyal
- **Yorum yazma** — kategori bazlı puanlama (eğitim, sosyal, altyapı vb.)
- **Fotoğraf ekleme** — mekan ve deneyim fotoğrafları
- **Like sistemi** — optimistic UI ile anında geri bildirim
- **Anonim yorum** — gizliliğini koruyarak deneyimini paylaş
- **Küfür filtresi** — gerçek zamanlı içerik moderasyonu

### Karşılaştırma
- **İki üniversiteyi yan yana** — puan, bölüm, mekan dağılımı karşılaştırması
- **Radar chart** — 6 kategoride görsel karşılaştırma
- **Paylaşım kartı** — karşılaştırma sonucunu PNG olarak paylaş

### Profil & Güvenlik
- **edu.tr doğrulama** — öğrenci kimliği onayı
- **Şifre değiştirme** — Firebase reauthentication destekli
- **Favoriler** — animasyonlu ekleme/çıkarma + undo
- **Bildirimler** — FCM push bildirimleri

## 🛠️ Teknoloji Altyapısı

| Katman | Teknoloji |
|---|---|
| Framework | Flutter 3.x |
| State Management | Riverpod 2.x |
| Backend | Firebase (Auth, Firestore, Storage, FCM) |
| Routing | GoRouter |
| Animasyonlar | flutter_animate |
| Resim Cache | CachedNetworkImage |

## 🚀 Kurulum

```bash
# Repoyu klonla
git clone https://github.com/BurakGGGG/uni_app.git
cd uni_app

# Bağımlılıkları yükle
flutter pub get

# Firebase yapılandırması (FlutterFire CLI)
flutterfire configure

# Uygulamayı çalıştır
flutter run
```

## 📂 Proje Yapısı

```
lib/
├── core/               # Tema, sabitler, ortak widget'lar, utils
├── features/
│   ├── auth/           # Giriş, kayıt, doğrulama
│   ├── home/           # Ana sayfa, keşfet, arama
│   ├── university/     # Üniversite detay, bölümler
│   ├── places/         # Mekan listesi, detay, filtre
│   ├── reviews/        # Yorum yazma, listeleme, like
│   ├── comparison/     # Karşılaştırma ekranı
│   ├── favorites/      # Favori yönetimi
│   ├── profile/        # Profil, düzenleme, şifre
│   └── notifications/  # Bildirim merkezi, ayarlar
├── router/             # GoRouter yapılandırması, AppShell
└── main.dart
```

## 📋 Sprint Geçmişi

- **Sprint 1:** Temel altyapı — Auth, üniversite listeleme, favoriler
- **Sprint 2:** Mekanlar, yorumlar, karşılaştırma
- **Sprint 3:** Like sistemi, bildirimler, sort/filter
- **Sprint 4 v2:** Hata ayıklama, performans optimizasyonu, güvenlik sertleştirme

## 👥 Ekip

- **Kişi A:** Profil, favoriler, üniversite detay, performans
- **Kişi B:** Public profile, mekanlar, karşılaştırma, güvenlik

## 📄 Lisans

Bu proje eğitim amaçlı geliştirilmiştir.
