# Performans Profil Baseline — UniSeç v1.0

> Release build üzerinde DevTools Profiler ile alınmıştır.
> Cihaz: Pixel 7 (Android 13). Tarih: 2026-05-14.

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
