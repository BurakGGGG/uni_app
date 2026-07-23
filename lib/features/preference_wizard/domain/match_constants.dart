/// Eşleştirme kalibrasyonu — TEK kaynak.
///
/// Tüm sabitler assets/data/department_scores.json (2025-2-rankings-yokatlas,
/// 7.386 program) üzerinde 2026-07-17'de ölçülen istatistiklerden türetildi.
/// Motor (preference_match_engine), uygunluk rozeti (feasibility_chip), liste
/// sağlığı (list_health) ve puan hesaplayıcı (score_calculator_engine) aynı
/// sabitleri kullanır — eşik burada değişir, her yüzey birlikte kayar.
library;

/// Uygunluk eğrisi çapa noktaları: (öğrenciSırası / programTabanSırası) → fit.
///
/// Oran küçüldükçe öğrenci taban sıradan öndedir (iyi). Parçalı doğrusal:
/// çapa aralarında lerp, uçlarda kelepçe. Bant genişliği ölçüme dayanır:
/// 2025/2024 taban sıra oranı medyan 0,862; %5–%95 aralığı 0,677–1,148;
/// programların %28,6'sı ±%20-25 bandının dışına savruldu (7.071 program).
/// Yani "geçen yılın tabanı" ±%10'dan çok daha gürültülü bir referanstır —
/// eğri bu belirsizliği yansıtacak şekilde yayvan tutuldu.
const List<({double ratio, double fit})> kFitCurveAnchors = [
  (ratio: 0.60, fit: 95),
  (ratio: 0.75, fit: 85),
  (ratio: 0.90, fit: 70),
  (ratio: 1.00, fit: 55),
  (ratio: 1.10, fit: 40),
  (ratio: 1.30, fit: 22),
  (ratio: 1.60, fit: 10),
];

/// Eğri dışı taban değer (ratio > 1.60).
const double kFitFloor = 5;

/// Fit kelepçesi — asla %0/%100 kesinlik iddia edilmez ("tahmindir" dili).
const int kFitMin = 3;
const int kFitMax = 97;

/// Kategori eşikleri (fit üzerinden): ≥70 yüksek şans, ≥40 ulaşılabilir.
/// 0,90/1,10 oran sınırları eğride tam 70/40'a denk gelir — v1 sınır
/// davranışı (%90 garanti, %110 hedef) korunur, aradaki geçiş yumuşar.
const int kFitGuaranteedMin = 70;
const int kFitTargetMin = 40;

// ── Düzelticiler (uygulama sırası: trend → boş kontenjan → oynaklık →
//    bayat yıl → tahmini sıra → kelepçe) ─────────────────────────────

/// Program sırası son iki yılda sıkılaştıysa (şimdiki/önceki < 0,85) ceza,
/// gevşediyse (> 1,15) küçük ödül. Medyan drift 0,862 olduğundan sıkılaşma
/// "normal"e yakındır — ceza bilinçli olarak küçük tutuldu.
const double kTrendTightenRatio = 0.85;
const double kTrendRelaxRatio = 1.15;
const double kTrendTightenDelta = -6;
const double kTrendRelaxDelta = 4;

/// Geçen yıl kontenjan boş kaldıysa (placedCount < quota) güven artar.
/// Veri: 108 programda boş kontenjan.
const double kEmptySeatsDelta = 8;

/// |ln(sıra_şimdi / sıra_önceki)| bu eşiği aşan program "oynak" sayılır ve
/// fit'i belirsiz ortaya (50) çekilir. %28,6 bandı-dışı ölçümünün karşılığı.
const double kVolatilityLnThreshold = 0.25;
const double kVolatilityPullToMid = 0.20;

/// Referans sıra 2024 ve öncesinden geliyorsa (2025 verisinde 90 program,
/// %1,2) hafif belirsizlik.
const double kStaleYearPullToMid = 0.15;

/// Öğrenci sırası puandan TAHMİN edildiyse (gerçek sıra girilmemiş)
/// belirsizlik payı. Puan enflasyonu ölçümü: programların %78'inin tabanı
/// 2024→2025'te ≥1 puan yükseldi — ham puan karşılaştırması yanıltıcıdır,
/// tahmin sıraya çevrilir ama güven düşürülür.
const double kEstimatedRankPullToMid = 0.25;

/// Fit'in çekildiği belirsizlik orta noktası.
const double kFitUncertainMid = 50;

// ── Yumuşak tercih sinyalleri (WizardPrefs) ─────────────────────────
// Sert filtre değildir: yalnız uygunluk sıralamasındaki anahtara eklenir,
// görünen fit skoru ve kategoriler DEĞİŞMEZ, hiçbir program elenmez.
const double kPrefCityBoost = 5;
const double kPrefInterestBoost = 5;
const double kPrefUniTypeBoost = 2;

/// Öğretim dili tercihi — üniversite türüyle aynı ağırlıkta, ikisi de
/// "olsa iyi olur" cinsinden sinyaller.
const double kPrefLanguageBoost = 2;

// ── Puan-farkı son çare eşikleri ────────────────────────────────────
// Yalnızca hiçbir sıra sinyali kurulamadığında (tanınmayan puan türü ya da
// sırasız program + tahminci yok) kullanılır. Yıllar arası puan enflasyonu
// nedeniyle kaba bir yaklaşımdır; birincil yol her zaman sıralamadır.
const double kScoreDiffGuaranteedMin = 2;
const double kScoreDiffTargetMin = -3;
