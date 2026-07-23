import '../../../practice_exams/domain/practice_exam_analytics.dart';
import '../../../score_calculator/domain/models/yks_subject.dart';
import '../../../score_calculator/domain/osym_score_distribution.dart';
import '../../../score_calculator/domain/score_calculator_engine.dart';

/// Yol haritasının tek adımı: şu dersten şu kadar net daha.
class RoadmapStep {
  final YksSubject subject;

  /// Bu dersten eklenmesi önerilen net.
  final double netsNeeded;

  /// Bu netlerin ham puana katkısı.
  final double scoreGain;

  /// Dersin şu anki ortalama neti — kullanıcı "nereden nereye" görsün.
  final double currentNet;

  /// Dersin o yıl puana yansıyan tavanı.
  final double maxNet;

  const RoadmapStep({
    required this.subject,
    required this.netsNeeded,
    required this.scoreGain,
    required this.currentNet,
    required this.maxNet,
  });

  double get targetNet => currentNet + netsNeeded;
}

/// "Hedefine ulaşmak için hangi dersten kaç net" hesabının sonucu.
class TargetRoadmap {
  /// Hedef programın taban sırası.
  final int targetRank;

  /// Hedef sıranın karşılığı olan yerleştirme puanı.
  final double targetScore;

  /// Öğrencinin son denemesindeki yerleştirme puanı.
  final double currentScore;

  /// Son denemedeki sıra; bilinmiyorsa null.
  final int? currentRank;

  /// Kapatılması gereken puan farkı; ≤ 0 ise hedef zaten aşılmış.
  final double scoreGap;

  /// Önerilen adımlar, katkısı büyükten küçüğe. Hedef aşılmışsa boş.
  final List<RoadmapStep> steps;

  /// Elde kalan tüm potansiyel farkı kapatıyor mu? false ise bu derslerde
  /// kalan boşlukla bu hedefe ulaşılamaz — Üni ara hedef önerir, sahte umut
  /// vermez.
  final bool reachable;

  /// Hesabın dayandığı puan türü ve ÖSYM veri yılı.
  final String scoreType;
  final int year;

  const TargetRoadmap({
    required this.targetRank,
    required this.targetScore,
    required this.currentScore,
    required this.currentRank,
    required this.scoreGap,
    required this.steps,
    required this.reachable,
    required this.scoreType,
    required this.year,
  });

  bool get reached => scoreGap <= 0;

  /// Adımların toplam neti — "≈ 11,5 net daha" cümlesi bunu söyler.
  double get totalNetsNeeded => steps.fold(0, (sum, s) => sum + s.netsNeeded);

  /// Hedefe doğru kat edilen yolun oranı (0..1).
  ///
  /// [startScore] ilk denemenin puanı; yoksa null döner — referans olmadan
  /// "yüzde kaç yol aldın" sorusunun cevabı yoktur.
  double? progress({double? startScore}) {
    if (startScore == null) return null;
    final distance = targetScore - startScore;
    if (distance <= 0) return 1;
    final covered = currentScore - startScore;
    return (covered / distance).clamp(0.0, 1.0);
  }
}

/// Hedef yol haritası hesabı — saf, LLM'siz, deterministik.
///
/// Parçalar uygulamada zaten vardı ama kimse çarpmıyordu:
/// `OsymScoreDistribution.estimateScore` sıra→puan ters tablosunu,
/// `ScoreCalculatorEngine.netWeights` ders başına puan ağırlığını,
/// `subjectStats` hangi derste zayıf olunduğunu biliyor. Üçünü birleştiren
/// cümle bugüne dek hiçbir ekranda yoktu: "hedefe 11,5 net — en verimli yol
/// AYT Matematik +5, Fizik +3."
abstract final class RoadmapPlanner {
  /// En fazla kaç ders önerilir. Üçten fazlası plan değil liste olur;
  /// kullanıcı yine neye odaklanacağını bilemez.
  static const int maxSteps = 3;

  /// Bir adımda önerilen en küçük net. Altındaki öneri gürültüdür ve zaten
  /// ölçüm hatasının içinde kalır.
  static const double minStepNet = 0.5;

  /// Hedef yol haritası; hesaplanamıyorsa null (hedefin sırası yok, tür
  /// bilinmiyor, puan yok ya da yükseltilecek ders kalmamış).
  ///
  /// Girdiler bilinçli olarak ham modeller değil çözülmüş sayılardır: seriyi
  /// hangi yıla oturtacağına çağıran zaten karar vermiştir ([trendFor] notu),
  /// bu fonksiyon o kararı tekrar etmez.
  ///
  /// [targetScoreFallback] resmî dağılım tablosu o yılı taşımıyorsa devreye
  /// giren yedek — programın kendi taban puanı.
  static TargetRoadmap? compute({
    required int? targetRank,
    required String scoreType,
    required int year,
    required double currentScore,
    required List<SubjectStat> stats,
    double? targetScoreFallback,
    int? currentRank,
  }) {
    if (targetRank == null || targetRank <= 0) return null;
    final type = scoreType.trim().toUpperCase();
    if (type.isEmpty || currentScore <= 0) return null;

    final derived = OsymScoreDistribution.estimateScore(targetRank, type, year);
    final targetScore = derived?.score ?? targetScoreFallback;
    if (targetScore == null || targetScore <= 0) return null;

    final gap = targetScore - currentScore;
    if (gap <= 0) {
      return TargetRoadmap(
        targetRank: targetRank,
        targetScore: targetScore,
        currentScore: currentScore,
        currentRank: currentRank,
        scoreGap: gap,
        steps: const [],
        reachable: true,
        scoreType: type,
        year: year,
      );
    }

    final weights = ScoreCalculatorEngine.netWeights(type, year: year);
    if (weights.isEmpty) return null;

    // Aday dersler: türün kapsamında, ölçülmüş ortalaması olan ve hâlâ
    // yükseltilebilecek yeri kalanlar.
    final candidates = <_Candidate>[];
    for (final stat in stats) {
      final weight = weights[stat.subject];
      if (weight == null || weight <= 0) continue;
      final max = ScoreCalculatorEngine.maxUsableNet(stat.subject, year: year);
      final headroom = max - stat.avgNet;
      if (headroom < minStepNet) continue;
      candidates.add(_Candidate(
        subject: stat.subject,
        weight: weight,
        currentNet: stat.avgNet,
        maxNet: max,
        headroom: headroom,
        successRate: stat.successRate,
      ));
    }
    if (candidates.isEmpty) return null;

    // Katsayısı yüksek VE başarı oranı düşük ders önce gelir. Yalnız
    // katsayıya bakmak zaten iyi olunan dersi büyütmeyi söylerdi; yalnız
    // zayıflığa bakmak puanı en az oynatan derse gönderirdi.
    candidates.sort((a, b) {
      final byPotential = b.potential.compareTo(a.potential);
      return byPotential != 0
          ? byPotential
          : a.subject.index.compareTo(b.subject.index);
    });

    // Açgözlü dağıtım: sırayla, tavana saygıyla, fark kapanana dek.
    final steps = <RoadmapStep>[];
    var remaining = gap;
    for (final c in candidates) {
      if (remaining <= 0 || steps.length >= maxSteps) break;
      final needed = remaining / c.weight;
      final take = needed < c.headroom ? needed : c.headroom;
      if (take < minStepNet) continue;
      // Yarım net adımlarına yuvarla — "3,27 net çıkar" diyen bir plan
      // uygulanamaz. Yukarı yuvarlanır ki hedef eksik kalmasın.
      final rounded = (take * 2).ceil() / 2;
      final capped = rounded > c.headroom ? c.headroom : rounded;
      steps.add(RoadmapStep(
        subject: c.subject,
        netsNeeded: capped,
        scoreGain: capped * c.weight,
        currentNet: c.currentNet,
        maxNet: c.maxNet,
      ));
      remaining -= capped * c.weight;
    }

    // Ulaşılabilirlik seçilen 3 derse değil TÜM adaylara bakar: "bu hedef
    // zor" demek için gerçekten hiç yol kalmamış olmalı.
    final totalPotential =
        candidates.fold<double>(0, (sum, c) => sum + c.headroom * c.weight);

    return TargetRoadmap(
      targetRank: targetRank,
      targetScore: targetScore,
      currentScore: currentScore,
      currentRank: currentRank,
      scoreGap: gap,
      steps: steps,
      reachable: totalPotential >= gap,
      scoreType: type,
      year: year,
    );
  }
}

class _Candidate {
  final YksSubject subject;
  final double weight;
  final double currentNet;
  final double maxNet;
  final double headroom;
  final double successRate;

  const _Candidate({
    required this.subject,
    required this.weight,
    required this.currentNet,
    required this.maxNet,
    required this.headroom,
    required this.successRate,
  });

  /// Sıralama ölçütü: net başına puan × zayıflık (`1 - başarı oranı`).
  /// Aynı katsayıda daha kötü olunan ders öne geçer.
  double get potential => weight * (1 - successRate);
}
