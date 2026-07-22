/// Tek puan türü için motor çıktısı (veri setinden bağımsız).
class TypeScore {
  final String scoreType; // 'TYT', 'SAY', 'EA', 'SÖZ', 'DİL'
  final int year;
  final double rawScore; // ham puan
  final double placementScore; // yerleştirme puanı (ham + OBP)
  /// Ek puanlı yerleştirme (meslek lisesi kendi alanı açıkken; yoksa null).
  final double? extraPlacementScore;

  const TypeScore({
    required this.scoreType,
    required this.year,
    required this.rawScore,
    required this.placementScore,
    this.extraPlacementScore,
  });
}

/// Uygulanabilir tüm türlerin puanları — [ScoreCalculatorEngine.calculateAllTypes] çıktısı.
class MultiScoreResult {
  final int year;
  final List<TypeScore> scores; // sabit sırada: TYT, SAY, EA, SÖZ, DİL
  final double obpContribution;

  const MultiScoreResult({
    required this.year,
    required this.scores,
    required this.obpContribution,
  });

  TypeScore? byType(String scoreType) {
    for (final s in scores) {
      if (s.scoreType == scoreType) return s;
    }
    return null;
  }

  bool get isEmpty => scores.isEmpty;
}

/// Puana sıra + dilim eklenmiş hali — [ScoreOutcomeService] çıktısı.
class ScoreTypeOutcome {
  final TypeScore score;
  final int? estimatedRank; // tahmini başarı sırası
  final int? rankCurveYear; // sıra eğrisinin veri yılı
  final double? percentile; // yüzdelik dilim (0-100, "İlk %X")
  final int? percentileYear; // aday sayısının veri yılı

  /// Sıra kullanıcı tarafından girildi (sıra modu) — tahmin edilmedi.
  /// UI bu durumda sıradan "~"/"tahmini" ibaresini kaldırır ve belirsizliği
  /// puana taşır (puan sıradan türetilmiştir).
  final bool rankIsUserEntered;

  const ScoreTypeOutcome({
    required this.score,
    this.estimatedRank,
    this.rankCurveYear,
    this.percentile,
    this.percentileYear,
    this.rankIsUserEntered = false,
  });

  /// Sıra, puanın yılından farklı bir yılın eğrisinden geldi
  /// (ör. 2026 puanı × 2025 eğrisi) — UI "2025 verisine göre" etiketi basar.
  bool get rankIsProxy => rankCurveYear != null && rankCurveYear != score.year;
}

class MultiScoreOutcome {
  final int year;
  final List<ScoreTypeOutcome> outcomes;
  final double obpContribution;

  const MultiScoreOutcome({
    required this.year,
    required this.outcomes,
    required this.obpContribution,
  });

  ScoreTypeOutcome? byType(String scoreType) {
    for (final o in outcomes) {
      if (o.score.scoreType == scoreType) return o;
    }
    return null;
  }

  /// En güçlü tür: en düşük tahmini sıra; hiçbirinde sıra yoksa ilk tür.
  ScoreTypeOutcome? get best {
    if (outcomes.isEmpty) return null;
    ScoreTypeOutcome? withRank;
    for (final o in outcomes) {
      final rank = o.estimatedRank;
      if (rank == null) continue;
      if (withRank == null || rank < withRank.estimatedRank!) withRank = o;
    }
    return withRank ?? outcomes.first;
  }

  bool get isEmpty => outcomes.isEmpty;
}

/// Yıl karşılaştırması satırı: aynı netler, farklı yılın katsayıları.
class YearOutcome {
  final int year;
  final double placementScore;
  final int? estimatedRank;
  final int? rankCurveYear;

  const YearOutcome({
    required this.year,
    required this.placementScore,
    this.estimatedRank,
    this.rankCurveYear,
  });

  bool get rankIsProxy => rankCurveYear != null && rankCurveYear != year;
}
