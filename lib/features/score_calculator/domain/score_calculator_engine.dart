import 'models/score_input.dart';
import 'models/match_result.dart';
import '../../university/domain/models/department_model.dart';
import '../../university/domain/models/university_model.dart';

/// YKS Puan Hesaplama Motoru
/// 2022-2025 katsayılarını kullanarak puan hesaplar ve
/// bölüm taban puanlarıyla eşleştirme yapar.
class ScoreCalculatorEngine {
  // ═══════════════════════════════════════════════════════════════
  //  YKS Katsayıları — seneyegorenetler.md'den alındı
  // ═══════════════════════════════════════════════════════════════

  static const Map<int, _TYTCoefficients> _tytData = {
    2022: _TYTCoefficients(turkce: 2.84, sosyal: 3.14, matematik: 2.87, fen: 3.13, baseScore: 145.89),
    2023: _TYTCoefficients(turkce: 2.89, sosyal: 3.02, matematik: 3.02, fen: 3.06, baseScore: 141.90),
    2024: _TYTCoefficients(turkce: 2.91, sosyal: 2.94, matematik: 2.93, fen: 3.15, baseScore: 144.953),
    2025: _TYTCoefficients(turkce: 2.83, sosyal: 2.99, matematik: 3.28, fen: 2.53, baseScore: 145.47),
  };

  static const Map<int, _SAYCoefficients> _sayData = {
    2022: _SAYCoefficients(tytTurkce: 1.19, tytSosyal: 1.32, tytMat: 1.21, tytFen: 1.32, aytMat: 2.59, aytFizik: 3.19, aytKimya: 2.95, aytBiyo: 3.11, baseScore: 125.41),
    2023: _SAYCoefficients(tytTurkce: 1.19, tytSosyal: 1.24, tytMat: 1.24, tytFen: 1.26, aytMat: 2.82, aytFizik: 2.48, aytKimya: 2.94, aytBiyo: 3.10, baseScore: 128.23),
    2024: _SAYCoefficients(tytTurkce: 1.11, tytSosyal: 1.12, tytMat: 1.11, tytFen: 1.20, aytMat: 3.19, aytFizik: 2.43, aytKimya: 3.07, aytBiyo: 2.51, baseScore: 133.28),
    2025: _SAYCoefficients(tytTurkce: 1.20, tytSosyal: 1.27, tytMat: 1.39, tytFen: 1.07, aytMat: 2.89, aytFizik: 2.46, aytKimya: 2.53, aytBiyo: 2.61, baseScore: 132.87),
  };

  static const Map<int, _EACoefficients> _eaData = {
    2022: _EACoefficients(tytTurkce: 1.22, tytSosyal: 1.35, tytMat: 1.23, tytFen: 1.34, aytMat: 2.65, aytEdebiyat: 3.21, aytTarih1: 3.33, aytCografya1: 2.28, baseScore: 127.4),
    2023: _EACoefficients(tytTurkce: 1.17, tytSosyal: 1.22, tytMat: 1.22, tytFen: 1.23, aytMat: 2.78, aytEdebiyat: 3.14, aytTarih1: 3.27, aytCografya1: 3.06, baseScore: 128.96),
    2024: _EACoefficients(tytTurkce: 1.14, tytSosyal: 1.15, tytMat: 1.15, tytFen: 1.23, aytMat: 3.28, aytEdebiyat: 2.83, aytTarih1: 2.38, aytCografya1: 2.54, baseScore: 132.28),
    2025: _EACoefficients(tytTurkce: 1.19, tytSosyal: 1.26, tytMat: 1.38, tytFen: 1.07, aytMat: 2.88, aytEdebiyat: 2.94, aytTarih1: 2.53, aytCografya1: 2.85, baseScore: 129.34),
  };

  static const Map<int, _SOZCoefficients> _sozData = {
    2022: _SOZCoefficients(tytTurkce: 1.15, tytSosyal: 1.27, tytMat: 1.16, tytFen: 1.27, aytEdebiyat: 3.03, aytTarih1: 3.15, aytCografya1: 2.15, aytTarih2: 3.51, aytCografya2: 2.22, aytFelsefe: 3.89, aytDkab: 2.93, baseScore: 127.68),
    2023: _SOZCoefficients(tytTurkce: 1.13, tytSosyal: 1.18, tytMat: 1.18, tytFen: 1.19, aytEdebiyat: 3.03, aytTarih1: 3.16, aytCografya1: 2.96, aytTarih2: 3.07, aytCografya2: 2.99, aytFelsefe: 3.67, aytDkab: 2.81, baseScore: 128.44),
    2024: _SOZCoefficients(tytTurkce: 1.23, tytSosyal: 1.24, tytMat: 1.24, tytFen: 1.33, aytEdebiyat: 3.06, aytTarih1: 2.57, aytCografya1: 2.74, aytTarih2: 3.16, aytCografya2: 2.82, aytFelsefe: 3.85, aytDkab: 3.13, baseScore: 130.36),
    2025: _SOZCoefficients(tytTurkce: 1.13, tytSosyal: 1.19, tytMat: 1.31, tytFen: 1.01, aytEdebiyat: 2.79, aytTarih1: 2.39, aytCografya1: 2.70, aytTarih2: 3.80, aytCografya2: 2.47, aytFelsefe: 3.76, aytDkab: 2.36, baseScore: 129.61),
  };

  static const Map<int, _DILCoefficients> _dilData = {
    2022: _DILCoefficients(tytTurkce: 1.47, tytSosyal: 1.62, tytMat: 1.48, tytFen: 1.62, ydt: 2.62, baseScore: 110.47),
    2023: _DILCoefficients(tytTurkce: 1.49, tytSosyal: 1.56, tytMat: 1.55, tytFen: 1.57, ydt: 2.64, baseScore: 109.86),
    2024: _DILCoefficients(tytTurkce: 1.50, tytSosyal: 1.51, tytMat: 1.50, tytFen: 1.62, ydt: 2.61, baseScore: 110.58),
    2025: _DILCoefficients(tytTurkce: 1.53, tytSosyal: 1.62, tytMat: 1.77, tytFen: 1.37, ydt: 2.60, baseScore: 105.92),
  };

  // ═══════════════════════════════════════════════════════════════
  //  Puan Hesaplama
  // ═══════════════════════════════════════════════════════════════

  /// Verilen girdiye göre ham puanı hesaplar (OBP hariç)
  static double calculateRawScore(ScoreInput input) {
    switch (input.scoreType) {
      case 'TYT':
        return _calculateTYT(input);
      case 'SAY':
        return _calculateSAY(input);
      case 'EA':
        return _calculateEA(input);
      case 'SÖZ':
        return _calculateSOZ(input);
      case 'DİL':
        return _calculateDIL(input);
      default:
        return 0;
    }
  }

  /// Yerleştirme puanı = Ham puan + OBP
  static double calculatePlacementScore(ScoreInput input) {
    final raw = calculateRawScore(input);
    return raw + input.obpContribution;
  }

  // ─── TYT ─────────────────────────────────────────────────────
  static double _calculateTYT(ScoreInput input) {
    final c = _tytData[input.selectedYear] ?? _tytData[2025]!;
    return c.baseScore +
        input.tytTurkceNet * c.turkce +
        input.tytSosyalNet * c.sosyal +
        input.tytMatNet * c.matematik +
        input.tytFenNet * c.fen;
  }

  // ─── SAY ─────────────────────────────────────────────────────
  static double _calculateSAY(ScoreInput input) {
    final c = _sayData[input.selectedYear] ?? _sayData[2025]!;
    return c.baseScore +
        input.tytTurkceNet * c.tytTurkce +
        input.tytSosyalNet * c.tytSosyal +
        input.tytMatNet * c.tytMat +
        input.tytFenNet * c.tytFen +
        input.aytMatNet * c.aytMat +
        input.aytFizikNet * c.aytFizik +
        input.aytKimyaNet * c.aytKimya +
        input.aytBiyoNet * c.aytBiyo;
  }

  // ─── EA ──────────────────────────────────────────────────────
  static double _calculateEA(ScoreInput input) {
    final c = _eaData[input.selectedYear] ?? _eaData[2025]!;
    return c.baseScore +
        input.tytTurkceNet * c.tytTurkce +
        input.tytSosyalNet * c.tytSosyal +
        input.tytMatNet * c.tytMat +
        input.tytFenNet * c.tytFen +
        input.aytMatNet * c.aytMat +
        input.aytEdebiyatNet * c.aytEdebiyat +
        input.aytTarih1Net * c.aytTarih1 +
        input.aytCografya1Net * c.aytCografya1;
  }

  // ─── SÖZ ─────────────────────────────────────────────────────
  static double _calculateSOZ(ScoreInput input) {
    final c = _sozData[input.selectedYear] ?? _sozData[2025]!;
    return c.baseScore +
        input.tytTurkceNet * c.tytTurkce +
        input.tytSosyalNet * c.tytSosyal +
        input.tytMatNet * c.tytMat +
        input.tytFenNet * c.tytFen +
        input.aytEdebiyatNet * c.aytEdebiyat +
        input.aytTarih1Net * c.aytTarih1 +
        input.aytCografya1Net * c.aytCografya1 +
        input.aytTarih2Net * c.aytTarih2 +
        input.aytCografya2Net * c.aytCografya2 +
        input.aytFelsefeNet * c.aytFelsefe +
        input.aytDkabNet * c.aytDkab;
  }

  // ─── DİL ─────────────────────────────────────────────────────
  static double _calculateDIL(ScoreInput input) {
    final c = _dilData[input.selectedYear] ?? _dilData[2025]!;
    return c.baseScore +
        input.tytTurkceNet * c.tytTurkce +
        input.tytSosyalNet * c.tytSosyal +
        input.tytMatNet * c.tytMat +
        input.tytFenNet * c.tytFen +
        input.ydtNet * c.ydt;
  }

  // ═══════════════════════════════════════════════════════════════
  //  Üniversite Eşleştirme
  // ═══════════════════════════════════════════════════════════════

  /// Puan ve bölüm adına göre üniversiteleri eşleştirir.
  /// 
  /// Sonuç: 2 garanti + 3 hedef + 2 hayal = 7 üniversite
  static CalculationResult matchUniversities({
    required ScoreInput input,
    required List<DepartmentModel> allDepartments,
    required List<UniversityModel> allUniversities,
  }) {
    final rawScore = calculateRawScore(input);
    final placementScore = calculatePlacementScore(input);
    final obp = input.obpContribution;

    // 1) Seçilen bölüm adıyla eşleşen ve taban puanı olan bölümleri bul
    final matchingDepts = allDepartments.where((d) {
      final deptName = d.name.toLowerCase().trim();
      final selectedName = input.selectedDepartment.toLowerCase().trim();
      if (deptName != selectedName) return false;

      // Puan türü uyumu kontrolü
      final deptScoreType = d.effectiveScoreType?.toUpperCase();
      if (deptScoreType == null) return true; // bilinmiyorsa dahil et
      if (input.scoreType == 'TYT') return deptScoreType == 'TYT';
      return deptScoreType == input.scoreType;
    }).where((d) {
      final bs = d.effectiveBaseScore;
      return bs != null && bs > 0;
    }).toList();

    // 2) Üniversite lookup map
    final uniMap = {for (final u in allUniversities) u.id: u};

    // 3) Matches oluştur ve puanına göre sırala
    final allMatches = <UniversityMatch>[];
    for (final dept in matchingDepts) {
      final uni = uniMap[dept.universityId];
      if (uni == null) continue;

      final depBaseScore = dept.effectiveBaseScore!;
      final diff = placementScore - depBaseScore;

      MatchCategory category;
      if (diff >= 2) {
        category = MatchCategory.guaranteed;
      } else if (diff >= -3) {
        category = MatchCategory.target;
      } else {
        category = MatchCategory.dream;
      }

      allMatches.add(UniversityMatch(
        department: dept,
        university: uni,
        category: category,
        departmentBaseScore: depBaseScore,
        departmentRanking: dept.effectiveRanking,
        scoreDifference: diff,
      ));
    }

    // 4) Her kategoride sırala ve limitle
    // Garanti: puanı en yakın 2 (en yüksek taban puanlılar)
    final guaranteedAll = allMatches
        .where((m) => m.category == MatchCategory.guaranteed)
        .toList()
      ..sort((a, b) => b.departmentBaseScore.compareTo(a.departmentBaseScore));

    // Hedef: Puanına en yakın 3
    final targetAll = allMatches
        .where((m) => m.category == MatchCategory.target)
        .toList()
      ..sort((a, b) =>
          a.scoreDifference.abs().compareTo(b.scoreDifference.abs()));

    // Hayal: En yakın 2 (en yüksek taban puanlılar — ulaşılabilir hedefler)
    final dreamAll = allMatches
        .where((m) => m.category == MatchCategory.dream)
        .toList()
      ..sort((a, b) => a.scoreDifference.abs().compareTo(b.scoreDifference.abs()));

    return CalculationResult(
      calculatedScore: placementScore,
      rawScore: rawScore,
      obpContribution: obp,
      scoreType: input.scoreType,
      departmentName: input.selectedDepartment,
      guaranteed: guaranteedAll.take(2).toList(),
      target: targetAll.take(3).toList(),
      dream: dreamAll.take(2).toList(),
    );
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
