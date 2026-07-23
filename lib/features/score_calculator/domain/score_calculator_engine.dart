import 'models/score_input.dart';
import 'models/multi_score_result.dart';

/// YKS Puan Hesaplama Motoru
/// 2022-2026 katsayılarını kullanarak uygulanabilir tüm puan türlerini
/// hesaplar. Sıra/dilim [ScoreOutcomeService]'te, bölüm eşleştirme
/// sihirbaz motorunda (matchAllPrograms) yapılır.
class ScoreCalculatorEngine {
  // ═══════════════════════════════════════════════════════════════
  //  YKS Katsayıları — seneyegorenetler.md'den alındı
  // ═══════════════════════════════════════════════════════════════

  static const Map<int, _TYTCoefficients> _tytData = {
    2022: _TYTCoefficients(turkce: 2.84, sosyal: 3.14, matematik: 2.87, fen: 3.13, baseScore: 145.89),
    2023: _TYTCoefficients(turkce: 2.89, sosyal: 3.02, matematik: 3.02, fen: 3.06, baseScore: 141.90),
    2024: _TYTCoefficients(turkce: 2.91, sosyal: 2.94, matematik: 2.93, fen: 3.15, baseScore: 144.953),
    2025: _TYTCoefficients(turkce: 2.83, sosyal: 2.99, matematik: 3.28, fen: 2.53, baseScore: 145.47),
    2026: _TYTCoefficients(turkce: 2.7138, sosyal: 3.1328, matematik: 3.2484, fen: 2.5786, baseScore: 150.6785),
  };

  static const Map<int, _SAYCoefficients> _sayData = {
    2022: _SAYCoefficients(tytTurkce: 1.19, tytSosyal: 1.32, tytMat: 1.21, tytFen: 1.32, aytMat: 2.59, aytFizik: 3.19, aytKimya: 2.95, aytBiyo: 3.11, baseScore: 125.41),
    2023: _SAYCoefficients(tytTurkce: 1.19, tytSosyal: 1.24, tytMat: 1.24, tytFen: 1.26, aytMat: 2.82, aytFizik: 2.48, aytKimya: 2.94, aytBiyo: 3.10, baseScore: 128.23),
    2024: _SAYCoefficients(tytTurkce: 1.11, tytSosyal: 1.12, tytMat: 1.11, tytFen: 1.20, aytMat: 3.19, aytFizik: 2.43, aytKimya: 3.07, aytBiyo: 2.51, baseScore: 133.28),
    2025: _SAYCoefficients(tytTurkce: 1.20, tytSosyal: 1.27, tytMat: 1.39, tytFen: 1.07, aytMat: 2.89, aytFizik: 2.46, aytKimya: 2.53, aytBiyo: 2.61, baseScore: 132.87),
    2026: _SAYCoefficients(tytTurkce: 1.2300, tytSosyal: 1.4199, tytMat: 1.4723, tytFen: 1.1688, aytMat: 3.0215, aytFizik: 2.5347, aytKimya: 2.5160, aytBiyo: 2.6142, baseScore: 121.6515),
  };

  static const Map<int, _EACoefficients> _eaData = {
    2022: _EACoefficients(tytTurkce: 1.22, tytSosyal: 1.35, tytMat: 1.23, tytFen: 1.34, aytMat: 2.65, aytEdebiyat: 3.21, aytTarih1: 3.33, aytCografya1: 2.28, baseScore: 127.4),
    2023: _EACoefficients(tytTurkce: 1.17, tytSosyal: 1.22, tytMat: 1.22, tytFen: 1.23, aytMat: 2.78, aytEdebiyat: 3.14, aytTarih1: 3.27, aytCografya1: 3.06, baseScore: 128.96),
    2024: _EACoefficients(tytTurkce: 1.14, tytSosyal: 1.15, tytMat: 1.15, tytFen: 1.23, aytMat: 3.28, aytEdebiyat: 2.83, aytTarih1: 2.38, aytCografya1: 2.54, baseScore: 132.28),
    2025: _EACoefficients(tytTurkce: 1.19, tytSosyal: 1.26, tytMat: 1.38, tytFen: 1.07, aytMat: 2.88, aytEdebiyat: 2.94, aytTarih1: 2.53, aytCografya1: 2.85, baseScore: 129.34),
    2026: _EACoefficients(tytTurkce: 1.1987, tytSosyal: 1.3837, tytMat: 1.4348, tytFen: 1.1390, aytMat: 2.9445, aytEdebiyat: 3.2829, aytTarih1: 2.3663, aytCografya1: 2.5453, baseScore: 123.3392),
  };

  static const Map<int, _SOZCoefficients> _sozData = {
    2022: _SOZCoefficients(tytTurkce: 1.15, tytSosyal: 1.27, tytMat: 1.16, tytFen: 1.27, aytEdebiyat: 3.03, aytTarih1: 3.15, aytCografya1: 2.15, aytTarih2: 3.51, aytCografya2: 2.22, aytFelsefe: 3.89, aytDkab: 2.93, baseScore: 127.68),
    2023: _SOZCoefficients(tytTurkce: 1.13, tytSosyal: 1.18, tytMat: 1.18, tytFen: 1.19, aytEdebiyat: 3.03, aytTarih1: 3.16, aytCografya1: 2.96, aytTarih2: 3.07, aytCografya2: 2.99, aytFelsefe: 3.67, aytDkab: 2.81, baseScore: 128.44),
    2024: _SOZCoefficients(tytTurkce: 1.23, tytSosyal: 1.24, tytMat: 1.24, tytFen: 1.33, aytEdebiyat: 3.06, aytTarih1: 2.57, aytCografya1: 2.74, aytTarih2: 3.16, aytCografya2: 2.82, aytFelsefe: 3.85, aytDkab: 3.13, baseScore: 130.36),
    2025: _SOZCoefficients(tytTurkce: 1.13, tytSosyal: 1.19, tytMat: 1.31, tytFen: 1.01, aytEdebiyat: 2.79, aytTarih1: 2.39, aytCografya1: 2.70, aytTarih2: 3.80, aytCografya2: 2.47, aytFelsefe: 3.76, aytDkab: 2.36, baseScore: 129.61),
    2026: _SOZCoefficients(tytTurkce: 1.1439, tytSosyal: 1.3205, tytMat: 1.3693, tytFen: 1.0869, aytEdebiyat: 3.1330, aytTarih1: 2.2583, aytCografya1: 2.4290, aytTarih2: 3.2361, aytCografya2: 2.9326, aytFelsefe: 4.2030, aytDkab: 1.9917, baseScore: 122.7197),
  };

  static const Map<int, _DILCoefficients> _dilData = {
    2022: _DILCoefficients(tytTurkce: 1.47, tytSosyal: 1.62, tytMat: 1.48, tytFen: 1.62, ydt: 2.62, baseScore: 110.47),
    2023: _DILCoefficients(tytTurkce: 1.49, tytSosyal: 1.56, tytMat: 1.55, tytFen: 1.57, ydt: 2.64, baseScore: 109.86),
    2024: _DILCoefficients(tytTurkce: 1.50, tytSosyal: 1.51, tytMat: 1.50, tytFen: 1.62, ydt: 2.61, baseScore: 110.58),
    2025: _DILCoefficients(tytTurkce: 1.53, tytSosyal: 1.62, tytMat: 1.77, tytFen: 1.37, ydt: 2.60, baseScore: 105.92),
    2026: _DILCoefficients(tytTurkce: 1.4248, tytSosyal: 1.6448, tytMat: 1.7054, tytFen: 1.3538, ydt: 2.5854, baseScore: 109.7669),
  };

  // 2026'da AYT Matematik ve AYT Edebiyat'ta birer soru iptal edildi;
  // son netin katkısı yok (kaynak modelde net bu tavanda kırpılıyor).
  static const Map<int, double> _aytMatNetCap = {2026: 39};
  static const Map<int, double> _aytEdebiyatNetCap = {2026: 23};

  static double _capped(double net, double? cap) =>
      (cap != null && net > cap) ? cap : net;

  /// Katsayısı olmayan yıllar en güncel yılın modeline düşer.
  static const int _latestYear = 2026;

  // ═══════════════════════════════════════════════════════════════
  //  Puan Hesaplama
  // ═══════════════════════════════════════════════════════════════

  /// Sabit tür sırası — sonuçlar hep bu sırayla listelenir.
  static const List<String> allScoreTypes = ['TYT', 'SAY', 'EA', 'SÖZ', 'DİL'];

  /// Verilen girdiye göre ham puanı hesaplar (OBP hariç)
  static double calculateRawScore(ScoreInput input) =>
      calculateRawScoreFor(input, input.scoreType);

  /// Tek tür için ham puan; [yearOverride] verilirse girdinin yılı yerine
  /// o yılın katsayıları kullanılır (yıl karşılaştırması için).
  static double calculateRawScoreFor(
    ScoreInput input,
    String scoreType, {
    int? yearOverride,
  }) {
    switch (scoreType) {
      case 'TYT':
        return _calculateTYT(input, yearOverride: yearOverride);
      case 'SAY':
        return _calculateSAY(input, yearOverride: yearOverride);
      case 'EA':
        return _calculateEA(input, yearOverride: yearOverride);
      case 'SÖZ':
        return _calculateSOZ(input, yearOverride: yearOverride);
      case 'DİL':
        return _calculateDIL(input, yearOverride: yearOverride);
      default:
        return 0;
    }
  }

  /// Yerleştirme puanı = Ham puan + OBP
  static double calculatePlacementScore(ScoreInput input) {
    final raw = calculateRawScore(input);
    return raw + input.obpContribution;
  }

  /// Girilen netlere göre hesaplanabilir puan türleri (hesaplama.net kuralları):
  /// TYT için Türkçe veya Temel Matematik'ten en az 0.5 net; AYT/YDT türleri
  /// TYT şartına ek olarak kendi testinden en az bir pozitif net ister.
  ///
  /// Sıra modunda net yoktur: kullanıcının seçtiği tek tür döner. Hem
  /// "Hesapla" butonu hem `multiScoreOutcomeProvider` bu kapıya bağlı
  /// olduğundan sıra modunun tüm akışı buradan açılır.
  static List<String> applicableScoreTypes(ScoreInput input) {
    if (input.isRankMode) {
      return input.hasValidRank ? [input.scoreType] : const [];
    }
    if (input.isScoreMode) {
      return input.hasValidScore ? [input.scoreType] : const [];
    }
    final tytOk = input.tytTurkceNet >= 0.5 || input.tytMatNet >= 0.5;
    if (!tytOk) return const [];

    final types = <String>['TYT'];
    if (_anyPositive([
      input.aytMatNet,
      input.aytFizikNet,
      input.aytKimyaNet,
      input.aytBiyoNet,
    ])) {
      types.add('SAY');
    }
    if (_anyPositive([
      input.aytMatNet,
      input.aytEdebiyatNet,
      input.aytTarih1Net,
      input.aytCografya1Net,
    ])) {
      types.add('EA');
    }
    if (_anyPositive([
      input.aytEdebiyatNet,
      input.aytTarih1Net,
      input.aytCografya1Net,
      input.aytTarih2Net,
      input.aytCografya2Net,
      input.aytFelsefeNet,
      input.aytDkabNet,
    ])) {
      types.add('SÖZ');
    }
    if (input.ydtNet > 0) types.add('DİL');
    return types;
  }

  static bool _anyPositive(List<double> nets) => nets.any((n) => n > 0);

  /// Uygulanabilir tüm türleri tek geçişte hesaplar (puanlar; sıra/dilim
  /// [ScoreOutcomeService]'te eklenir).
  static MultiScoreResult calculateAllTypes(
    ScoreInput input, {
    int? yearOverride,
  }) {
    final year = yearOverride ?? input.selectedYear;
    final obp = input.obpContribution;
    final ekPuan = input.ekPuanContribution;

    final scores = <TypeScore>[];
    for (final type in applicableScoreTypes(input)) {
      final raw = calculateRawScoreFor(input, type, yearOverride: yearOverride);
      scores.add(TypeScore(
        scoreType: type,
        year: year,
        rawScore: raw,
        placementScore: raw + obp,
        extraPlacementScore: ekPuan > 0 ? raw + obp + ekPuan : null,
      ));
    }
    return MultiScoreResult(year: year, scores: scores, obpContribution: obp);
  }

  // ─── TYT ─────────────────────────────────────────────────────
  static double _calculateTYT(ScoreInput input, {int? yearOverride}) {
    final selected = yearOverride ?? input.selectedYear;
    final c = _tytData[selected] ?? _tytData[_latestYear]!;
    return c.baseScore +
        input.tytTurkceNet * c.turkce +
        input.tytSosyalNet * c.sosyal +
        input.tytMatNet * c.matematik +
        input.tytFenNet * c.fen;
  }

  // ─── SAY ─────────────────────────────────────────────────────
  static double _calculateSAY(ScoreInput input, {int? yearOverride}) {
    final selected = yearOverride ?? input.selectedYear;
    final year = _sayData.containsKey(selected) ? selected : _latestYear;
    final c = _sayData[year]!;
    return c.baseScore +
        input.tytTurkceNet * c.tytTurkce +
        input.tytSosyalNet * c.tytSosyal +
        input.tytMatNet * c.tytMat +
        input.tytFenNet * c.tytFen +
        _capped(input.aytMatNet, _aytMatNetCap[year]) * c.aytMat +
        input.aytFizikNet * c.aytFizik +
        input.aytKimyaNet * c.aytKimya +
        input.aytBiyoNet * c.aytBiyo;
  }

  // ─── EA ──────────────────────────────────────────────────────
  static double _calculateEA(ScoreInput input, {int? yearOverride}) {
    final selected = yearOverride ?? input.selectedYear;
    final year = _eaData.containsKey(selected) ? selected : _latestYear;
    final c = _eaData[year]!;
    return c.baseScore +
        input.tytTurkceNet * c.tytTurkce +
        input.tytSosyalNet * c.tytSosyal +
        input.tytMatNet * c.tytMat +
        input.tytFenNet * c.tytFen +
        _capped(input.aytMatNet, _aytMatNetCap[year]) * c.aytMat +
        _capped(input.aytEdebiyatNet, _aytEdebiyatNetCap[year]) * c.aytEdebiyat +
        input.aytTarih1Net * c.aytTarih1 +
        input.aytCografya1Net * c.aytCografya1;
  }

  // ─── SÖZ ─────────────────────────────────────────────────────
  static double _calculateSOZ(ScoreInput input, {int? yearOverride}) {
    final selected = yearOverride ?? input.selectedYear;
    final year = _sozData.containsKey(selected) ? selected : _latestYear;
    final c = _sozData[year]!;
    return c.baseScore +
        input.tytTurkceNet * c.tytTurkce +
        input.tytSosyalNet * c.tytSosyal +
        input.tytMatNet * c.tytMat +
        input.tytFenNet * c.tytFen +
        _capped(input.aytEdebiyatNet, _aytEdebiyatNetCap[year]) * c.aytEdebiyat +
        input.aytTarih1Net * c.aytTarih1 +
        input.aytCografya1Net * c.aytCografya1 +
        input.aytTarih2Net * c.aytTarih2 +
        input.aytCografya2Net * c.aytCografya2 +
        input.aytFelsefeNet * c.aytFelsefe +
        input.aytDkabNet * c.aytDkab;
  }

  // ─── DİL ─────────────────────────────────────────────────────
  static double _calculateDIL(ScoreInput input, {int? yearOverride}) {
    final selected = yearOverride ?? input.selectedYear;
    final c = _dilData[selected] ?? _dilData[_latestYear]!;
    return c.baseScore +
        input.tytTurkceNet * c.tytTurkce +
        input.tytSosyalNet * c.tytSosyal +
        input.tytMatNet * c.tytMat +
        input.tytFenNet * c.tytFen +
        input.ydtNet * c.ydt;
  }

}

// ═══════════════════════════════════════════════════════════════
//  Katsayı veri sınıfları
// ═══════════════════════════════════════════════════════════════

class _TYTCoefficients {
  final double turkce, sosyal, matematik, fen, baseScore;
  const _TYTCoefficients({
    required this.turkce,
    required this.sosyal,
    required this.matematik,
    required this.fen,
    required this.baseScore,
  });
}

class _SAYCoefficients {
  final double tytTurkce, tytSosyal, tytMat, tytFen;
  final double aytMat, aytFizik, aytKimya, aytBiyo;
  final double baseScore;
  const _SAYCoefficients({
    required this.tytTurkce,
    required this.tytSosyal,
    required this.tytMat,
    required this.tytFen,
    required this.aytMat,
    required this.aytFizik,
    required this.aytKimya,
    required this.aytBiyo,
    required this.baseScore,
  });
}

class _EACoefficients {
  final double tytTurkce, tytSosyal, tytMat, tytFen;
  final double aytMat, aytEdebiyat, aytTarih1, aytCografya1;
  final double baseScore;
  const _EACoefficients({
    required this.tytTurkce,
    required this.tytSosyal,
    required this.tytMat,
    required this.tytFen,
    required this.aytMat,
    required this.aytEdebiyat,
    required this.aytTarih1,
    required this.aytCografya1,
    required this.baseScore,
  });
}

class _SOZCoefficients {
  final double tytTurkce, tytSosyal, tytMat, tytFen;
  final double aytEdebiyat, aytTarih1, aytCografya1;
  final double aytTarih2, aytCografya2, aytFelsefe, aytDkab;
  final double baseScore;
  const _SOZCoefficients({
    required this.tytTurkce,
    required this.tytSosyal,
    required this.tytMat,
    required this.tytFen,
    required this.aytEdebiyat,
    required this.aytTarih1,
    required this.aytCografya1,
    required this.aytTarih2,
    required this.aytCografya2,
    required this.aytFelsefe,
    required this.aytDkab,
    required this.baseScore,
  });
}

class _DILCoefficients {
  final double tytTurkce, tytSosyal, tytMat, tytFen;
  final double ydt;
  final double baseScore;
  const _DILCoefficients({
    required this.tytTurkce,
    required this.tytSosyal,
    required this.tytMat,
    required this.tytFen,
    required this.ydt,
    required this.baseScore,
  });
}
