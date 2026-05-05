import '../domain/models/recommendation_answer.dart';
import '../domain/models/recommendation_question.dart';
import '../domain/models/recommendation_result.dart';
import '../domain/department_profiles.dart';
import '../domain/university_strength_matrix.dart';
import '../domain/question_bank.dart';

/// Ağırlık sabitleri (toplam 100)
const _w1Weight = 25.0; // Alan + ders uyumu
const _w2Weight = 20.0; // İlgi + kimlik uyumu
const _w3Weight = 15.0; // Hedef + gelir uyumu
const _w4Weight = 15.0; // Ortam + çalışma uyumu
const _w5Weight = 10.0; // Puan yeterliliği
const _w6Weight = 10.0; // Süre kabulü
const _w7Weight = 5.0;  // Stres uyumu

class RecommendationEngine {
  /// Ana algoritma:
  /// 1. Cevapları tag map'e çevir
  /// 2. Her bölüm için bölüm skoru hesapla (W1-W7)
  /// 3. Her bölüm × üniversite için toplam skor hesapla
  /// 4. Skor ≥ 40 olanları filtrele, sırala, madalya ata
  List<CombinedRecommendation> generateRecommendations(
    Map<String, RecommendationAnswer> answers,
  ) {
    // 1. Cevapları tag map'e çevir
    final userTags = _extractTags(answers);

    // 2. Her bölüm için skor hesapla
    final deptScores = <String, double>{};
    final deptReasons = <String, List<String>>{};

    for (final dept in DepartmentProfiles.all) {
      final result = _calcDeptScore(dept, userTags);
      deptScores[dept.id] = result.score;
      deptReasons[dept.id] = result.reasons;
    }

    // 3. Skoru düşük bölümleri ele (< 40)
    final eligibleDepts = deptScores.entries
        .where((e) => e.value >= 40)
        .toList();

    // 4. Her bölüm × üniversite için toplam skor
    final results = <CombinedRecommendation>[];
    for (final deptEntry in eligibleDepts) {
      final deptId = deptEntry.key;
      final deptScore = deptEntry.value;
      final dept = DepartmentProfiles.all.firstWhere((d) => d.id == deptId);

      for (final uni in UniversityStrengthMatrix.all) {
        final strength = uni.strengths[deptId];
        if (strength == null || strength == 0) continue; // Bu bölüm bu ünide yok

        // Şehir kontrolü
        if (!_matchesCity(uni, userTags)) continue;
        // Tür kontrolü
        if (!_matchesType(uni, userTags)) continue;

        // Toplam skor hesapla
        final totalScore = _calcUniScore(
          deptScore: deptScore,
          strengthScore: strength,
          uni: uni,
          userTags: userTags,
        );

        // Reason'ları birleştir
        final reasons = List<String>.from(deptReasons[deptId] ?? []);
        if (strength >= 4) {
          reasons.add('${uni.universityName}\'da güçlü ${dept.name} bölümü');
        }
        final cityTag = userTags['sehir'];
        if (cityTag != null && cityTag != 'farketmez' && uni.city == cityTag) {
          reasons.add('İstediğin şehirde');
        }

        results.add(CombinedRecommendation(
          departmentId: deptId,
          departmentName: dept.name,
          universityId: uni.universityId,
          universityName: uni.universityName,
          totalScore: totalScore,
          normalizedScore: (totalScore / 1.2).clamp(0, 100), // max 120 → normalize to 100
          medal: MedalType.none, // Sonra atanacak
          reasons: reasons.take(3).toList(),
        ));
      }
    }

    // 5. Sırala
    results.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    // 6. Madalya ata
    for (var i = 0; i < results.length; i++) {
      final medal = switch (i) {
        0 => MedalType.gold,
        1 => MedalType.silver,
        2 => MedalType.bronze,
        _ when i < 8 => MedalType.honorable,
        _ => MedalType.none,
      };
      results[i] = CombinedRecommendation(
        departmentId: results[i].departmentId,
        departmentName: results[i].departmentName,
        universityId: results[i].universityId,
        universityName: results[i].universityName,
        totalScore: results[i].totalScore,
        normalizedScore: results[i].normalizedScore,
        medal: medal,
        reasons: results[i].reasons,
      );
    }

    // İlk 8 sonucu döndür
    return results.take(8).toList();
  }

  /// Cevaplardan tüm tag'leri çıkar: {'alan': 'bio', 'puan': 'iyi', ...}
  Map<String, String> _extractTags(Map<String, RecommendationAnswer> answers) {
    final tags = <String, String>{};
    final multiTags = <String, List<String>>{}; // çoklu seçimler için

    for (final question in QuestionBank.questions) {
      final answer = answers[question.id];
      if (answer == null) continue;

      for (final optionId in answer.selectedOptionIds) {
        final option = question.options.firstWhere(
          (o) => o.id == optionId,
          orElse: () => question.options.first,
        );
        for (final entry in option.tags.entries) {
          if (question.type == QuestionType.multiSelect) {
            multiTags.putIfAbsent(entry.key, () => []).add(entry.value);
          } else {
            tags[entry.key] = entry.value;
          }
        }
      }
    }

    // Multi-select tag'leri de ekle (ilk değeri ana tag olarak)
    for (final entry in multiTags.entries) {
      if (!tags.containsKey(entry.key)) {
        tags[entry.key] = entry.value.first;
      }
      // Tüm multi değerleri de ayrı key'le sakla
      for (var i = 0; i < entry.value.length; i++) {
        tags['${entry.key}_$i'] = entry.value[i];
      }
    }

    return tags;
  }

  /// Bölüm skoru hesapla (0-100)
  _DeptScoreResult _calcDeptScore(DepartmentProfile dept, Map<String, String> userTags) {
    var totalScore = 0.0;
    final reasons = <String>[];

    // W1: Alan + Ders uyumu (25 puan)
    final w1 = _matchRules(dept.w1Rules, userTags);
    totalScore += _w1Weight * w1;
    if (w1 >= 0.8) reasons.add('Alan tercihin uyumlu');

    // W2: İlgi + Kimlik uyumu (20 puan)
    final w2 = _matchRules(dept.w2Rules, userTags);
    totalScore += _w2Weight * w2;
    if (w2 >= 0.8) reasons.add('İlgi alanın bu bölümle örtüşüyor');

    // W3: Hedef + Gelir uyumu (15 puan)
    final w3 = _matchRules(dept.w3Rules, userTags);
    totalScore += _w3Weight * w3;
    if (w3 >= 0.8) reasons.add('Kariyer hedefine uygun');

    // W4: Ortam + Çalışma uyumu (15 puan)
    final w4 = _matchRules(dept.w4Rules, userTags);
    totalScore += _w4Weight * w4;
    if (w4 >= 0.8) reasons.add('Çalışma ortamı tercihine uygun');

    // W5: Puan yeterliliği (10 puan)
    final w5 = _matchRules(dept.w5Rules, userTags);
    totalScore += _w5Weight * w5;

    // W6: Süre kabulü (10 puan)
    final w6 = _matchRules(dept.w6Rules, userTags);
    totalScore += _w6Weight * w6;

    // W7: Stres uyumu (5 puan)
    final w7 = _matchRules(dept.w7Rules, userTags);
    totalScore += _w7Weight * w7;
    if (w7 >= 0.8 && dept.id == 'tip') reasons.add('Stres toleransın yüksek');

    return _DeptScoreResult(score: totalScore, reasons: reasons);
  }

  /// Kural setinden en yüksek eşleşme katsayısını bul
  double _matchRules(Map<String, double> rules, Map<String, String> userTags) {
    var bestMatch = 0.0;

    for (final rule in rules.entries) {
      final parts = rule.key.split(':');
      if (parts.length != 2) continue;
      final tagKey = parts[0];
      final tagValue = parts[1];
      final coefficient = rule.value;

      // Ana tag kontrolü
      if (userTags[tagKey] == tagValue) {
        if (coefficient > bestMatch) bestMatch = coefficient;
      }

      // Multi-select tag kontrolü (sehir_0, sehir_1, oncelik_0, oncelik_1)
      for (var i = 0; i < 5; i++) {
        final multiKey = '${tagKey}_$i';
        if (userTags[multiKey] == tagValue) {
          if (coefficient > bestMatch) bestMatch = coefficient;
        }
      }
    }

    return bestMatch;
  }

  /// Üniversite toplam skoru:
  /// deptScore × 0.60 + güçSkoru × 8 + şehirBonus + tipBonus + dilBonus
  double _calcUniScore({
    required double deptScore,
    required int strengthScore,
    required UniStrength uni,
    required Map<String, String> userTags,
  }) {
    var total = deptScore * 0.60;
    total += strengthScore * 8; // max 40

    // Şehir bonusu (+10)
    final sehir = userTags['sehir'];
    if (sehir != null && sehir != 'farketmez') {
      // Ana tag veya multi tag kontrolü
      bool match = uni.city == sehir;
      if (!match) {
        for (var i = 0; i < 5; i++) {
          if (userTags['sehir_$i'] == uni.city) {
            match = true;
            break;
          }
        }
      }
      if (match) total += 10;
    }

    // Tip bonusu (+5)
    final tip = userTags['tip'];
    if (tip != null) {
      if (tip == 'farketmez') {
        total += 5;
      } else if (tip == 'devlet' && uni.type == 'devlet') {
        total += 5;
      } else if (tip == 'devlet_oncelikli' && uni.type == 'devlet') {
        total += 5;
      } else if (tip == 'burslu_vakif') {
        total += 3; // Her tür biraz bonus
      }
    }

    // Dil bonusu (+5) — şimdilik sadece İngilizce tercih edenlere teknik üniler bonus
    final dil = userTags['dil'];
    if (dil == 'tam_ing' || dil == 'mio') {
      // ITU, ODTU gibi İngilizce programları olan ünilere bonus
      if (['itu', 'odtu', 'hacettepe', 'ytu'].contains(uni.universityId)) {
        total += 5;
      }
    } else if (dil == 'farketmez') {
      total += 2;
    }

    return total;
  }

  /// Şehir filtresi
  bool _matchesCity(UniStrength uni, Map<String, String> userTags) {
    final sehir = userTags['sehir'];
    if (sehir == null || sehir == 'farketmez') return true;

    // Ana tag
    if (uni.city == sehir) return true;

    // Multi-select taglerden herhangi biri eşleşiyor mu?
    for (var i = 0; i < 5; i++) {
      final multi = userTags['sehir_$i'];
      if (multi == null) break;
      if (multi == 'farketmez') return true;
      if (uni.city == multi) return true;
    }

    return false;
  }

  /// Tür filtresi
  bool _matchesType(UniStrength uni, Map<String, String> userTags) {
    final tip = userTags['tip'];
    if (tip == null || tip == 'farketmez' || tip == 'burslu_vakif') return true;
    if (tip == 'devlet' && uni.type != 'devlet') return false;
    if (tip == 'devlet_oncelikli' && uni.type != 'devlet') return false;
    return true;
  }

  /// Özet metni oluştur
  String generateSummary(List<CombinedRecommendation> results) {
    if (results.isEmpty) {
      return 'Verdiğin cevaplara uygun üniversite bulamadık. Filtreleri gevşeterek tekrar dene.';
    }

    final top = results.first;
    return '${top.universityName} – ${top.departmentName} bölümü '
        'tercihlerinle %${top.normalizedScore.toInt()} oranında uyumlu.';
  }
}

class _DeptScoreResult {
  final double score;
  final List<String> reasons;
  _DeptScoreResult({required this.score, required this.reasons});
}
