import '../domain/models/recommendation_answer.dart';
import '../domain/models/recommendation_question.dart';
import '../domain/models/recommendation_result.dart';
import '../domain/department_profiles.dart';
import '../domain/university_strength_matrix.dart';
import '../domain/question_bank.dart';

// v2 Ağırlık sabitleri (toplam 100)
const _w1Weight = 25.0; // Alan + ders uyumu
const _w2Weight = 20.0; // İlgi + kimlik uyumu
const _w3Weight = 15.0; // Hedef + gelir uyumu
const _w4Weight = 15.0; // Ortam + çalışma uyumu
const _w5Weight = 10.0; // Puan yeterliliği (puanUyumu fonksiyonu)
const _w6Weight = 10.0; // Süre kabulü
const _w7Weight = 5.0;  // Stres uyumu

class RecommendationEngine {
  /// v2 Ana algoritma:
  /// 1. Cevapları tag map'e çevir
  /// 2. Puan türü hard filter uygula
  /// 3. Her bölüm için bölüm skoru hesapla (W1-W7)
  /// 4. Her bölüm × üniversite için toplam skor hesapla
  /// 5. Skor ≥ 40 olanları filtrele, sırala, madalya ata
  List<CombinedRecommendation> generateRecommendations(
    Map<String, RecommendationAnswer> answers,
  ) {
    // 1. Cevapları tag map'e çevir
    final userTags = _extractTags(answers);

    // Kullanıcının sıralama tahmini
    final userRanking = int.tryParse(userTags['siralama'] ?? '') ?? 0;
    final userPuanTuru = userTags['puanTuru'] ?? 'belirsiz';

    // 2-3. Her bölüm için skor hesapla (puan türü hard filter dahil)
    final deptScores = <String, double>{};
    final deptReasons = <String, List<String>>{};

    for (final dept in DepartmentProfiles.all) {
      // ── HARD FILTER: Puan türü eşleşmeli ──
      if (userPuanTuru != 'belirsiz') {
        if (dept.scoreType != userPuanTuru) continue;
      }

      // ── HARD FILTER: TYT seçmediyse önlisans önerme ──
      if (dept.type == 'Önlisans' && userPuanTuru != 'tyt' && userPuanTuru != 'belirsiz') {
        continue;
      }

      // ── HARD FILTER: Puan yeterliliği ──
      if (userRanking > 0) {
        final maxAllowed = (dept.maxRanking * 1.2).toInt();
        if (userRanking > maxAllowed) continue;
      }

      final result = _calcDeptScore(dept, userTags, userRanking);
      deptScores[dept.id] = result.score;
      deptReasons[dept.id] = result.reasons;
    }

    // Skoru düşük bölümleri ele (< 40)
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
        if (strength == null || strength == 0) continue;

        // Şehir kontrolü
        if (!_matchesCity(uni, userTags)) continue;
        // Tür kontrolü
        if (!_matchesType(uni, userTags)) continue;

        // Üniversite-bölüm sıralama W5 hesabı
        final uniRanking = uni.rankings[deptId] ?? 0;
        double w5Score = 1.0;
        if (userRanking > 0 && uniRanking > 0) {
          w5Score = _puanUyumu(userRanking, uniRanking);
          if (w5Score == 0.0) continue; // Puan hiç yetmiyor, atla
        }

        // v2 formül: deptScore × 0.55 + güçSkoru × 7 + bonuslar
        final totalScore = _calcUniScore(
          deptScore: deptScore,
          strengthScore: strength,
          w5Score: w5Score,
          uni: uni,
          userTags: userTags,
        );

        // Reason'ları oluştur
        final reasons = List<String>.from(deptReasons[deptId] ?? []);
        if (strength >= 4) {
          reasons.add('${uni.universityName} bu bölümde güçlü');
        }
        if (w5Score >= 0.8 && userRanking > 0) {
          reasons.add('Tahmini puanınla girebilirsin');
        } else if (w5Score >= 0.4 && userRanking > 0) {
          reasons.add('Puanın sınırda, riskli ama mümkün');
        }
        if (_cityMatches(uni, userTags)) {
          reasons.add('Tercih ettiğin şehirde');
        }

        results.add(CombinedRecommendation(
          departmentId: deptId,
          departmentName: dept.name,
          universityId: uni.universityId,
          universityName: uni.universityName,
          totalScore: totalScore,
          normalizedScore: totalScore.clamp(0, 100),
          medal: MedalType.none,
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

    return results.take(8).toList();
  }

  // ─── Puan Uyumu (v2 formül) ─────────────────────────────────
  // Kullanıcının tahmini sırası ile üniversitenin sırası arasındaki oran
  double _puanUyumu(int kullaniciSira, int uniSira) {
    if (uniSira == 0) return 1.0;
    final oran = kullaniciSira / uniSira;
    if (oran <= 0.8) return 1.0;   // rahat girer
    if (oran <= 1.0) return 0.8;   // sınırda
    if (oran <= 1.2) return 0.4;   // riskli ama mümkün
    return 0.0;                     // puan yetmez
  }

  // ─── Tag çıkarma ────────────────────────────────────────────
  Map<String, String> _extractTags(Map<String, RecommendationAnswer> answers) {
    final tags = <String, String>{};
    final multiTags = <String, List<String>>{};

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

    // Multi-select tag'leri
    for (final entry in multiTags.entries) {
      if (!tags.containsKey(entry.key)) {
        tags[entry.key] = entry.value.first;
      }
      for (var i = 0; i < entry.value.length; i++) {
        tags['${entry.key}_$i'] = entry.value[i];
      }
    }

    return tags;
  }

  // ─── Bölüm skoru (W1-W7) ───────────────────────────────────
  _DeptScoreResult _calcDeptScore(
    DepartmentProfile dept,
    Map<String, String> userTags,
    int userRanking,
  ) {
    var totalScore = 0.0;
    final reasons = <String>[];

    // W1: Alan + Ders (25)
    final w1 = _matchRules(dept.w1Rules, userTags);
    totalScore += _w1Weight * w1;
    if (w1 >= 0.8) reasons.add('Alan tercihin uyumlu');

    // W2: İlgi + Kimlik (20)
    final w2 = _matchRules(dept.w2Rules, userTags);
    totalScore += _w2Weight * w2;
    if (w2 >= 0.8) reasons.add('İlgi alanın bu bölümle örtüşüyor');

    // W3: Hedef + Gelir (15)
    final w3 = _matchRules(dept.w3Rules, userTags);
    totalScore += _w3Weight * w3;
    if (w3 >= 0.8) reasons.add('Kariyer hedefine uygun');

    // W4: Ortam + Çalışma (15)
    final w4 = _matchRules(dept.w4Rules, userTags);
    totalScore += _w4Weight * w4;
    if (w4 >= 0.8) reasons.add('Çalışma ortamı tercihine uygun');

    // W5: Puan uyumu (10) — genel bölüm seviyesinde
    double w5 = 1.0;
    if (userRanking > 0) {
      // Bölümün maxRanking'e göre genel kontrol
      final oran = userRanking / dept.maxRanking;
      if (oran <= 0.5) {
        w5 = 1.0;
      } else if (oran <= 1.0) {
        w5 = 0.7;
      } else if (oran <= 1.2) {
        w5 = 0.3;
      } else {
        w5 = 0.0;
      }
    }
    totalScore += _w5Weight * w5;

    // W6: Süre (10)
    final w6 = _matchRules(dept.w6Rules, userTags);
    totalScore += _w6Weight * w6;

    // W7: Stres (5)
    final w7 = _matchRules(dept.w7Rules, userTags);
    totalScore += _w7Weight * w7;
    if (w7 >= 0.8 && (dept.id == 'tip' || dept.id == 'acil_yardim')) {
      reasons.add('Stres toleransın uygun');
    }

    return _DeptScoreResult(score: totalScore, reasons: reasons);
  }

  // ─── Kural eşleşme ─────────────────────────────────────────
  double _matchRules(Map<String, double> rules, Map<String, String> userTags) {
    var bestMatch = 0.0;

    for (final rule in rules.entries) {
      final parts = rule.key.split(':');
      if (parts.length != 2) continue;
      final tagKey = parts[0];
      final tagValue = parts[1];
      final coefficient = rule.value;

      if (userTags[tagKey] == tagValue) {
        if (coefficient > bestMatch) bestMatch = coefficient;
      }

      // Multi-select tag kontrolü
      for (var i = 0; i < 5; i++) {
        if (userTags['${tagKey}_$i'] == tagValue) {
          if (coefficient > bestMatch) bestMatch = coefficient;
        }
      }
    }

    return bestMatch;
  }

  // ─── v2 Üniversite skoru ────────────────────────────────────
  // deptScore × 0.55 + güçSkoru × 7 + şehir(5) + tip(3) + dil(2)
  // max = 55 + 35 + 5 + 3 + 2 = 100
  double _calcUniScore({
    required double deptScore,
    required int strengthScore,
    required double w5Score,
    required UniStrengthEntry uni,
    required Map<String, String> userTags,
  }) {
    // Bölüm uyumu × 0.55 (max 55)
    var total = deptScore * 0.55;

    // Güç katkısı (max 35)
    total += strengthScore * 7.0;

    // W5 puan uyumu (bu üniversite seviyesinde) — toplam skoru çarpan olarak etkiler
    // w5Score 0.0 ise engine zaten bu üniversiteyi atlamış oluyor
    total *= (0.6 + w5Score * 0.4); // w5=1.0 → ×1.0, w5=0.4 → ×0.76

    // Şehir bonusu (+5)
    if (_cityMatches(uni, userTags)) total += 5;

    // Tip bonusu (+3)
    final tip = userTags['tip'];
    if (tip == 'farketmez') {
      total += 3;
    } else if (tip == 'devlet' && uni.type == 'devlet') {
      total += 3;
    } else if (tip == 'devlet_oncelikli' && uni.type == 'devlet') {
      total += 3;
    } else if (tip == 'burslu_vakif') {
      total += 2;
    }

    // Dil bonusu (+2)
    final dil = userTags['dil'];
    if (dil == 'tam_ing' || dil == 'mio') {
      if (['odtu', 'hacettepe', 'yildiz_teknik', 'itu'].contains(uni.universityId)) {
        total += 2;
      }
    } else if (dil == 'farketmez') {
      total += 1;
    }

    return total;
  }

  // ─── Şehir kontrolü ────────────────────────────────────────
  bool _matchesCity(UniStrengthEntry uni, Map<String, String> userTags) {
    final sehir = userTags['sehir'];
    if (sehir == null || sehir == 'farketmez') return true;
    if (uni.city == sehir) return true;
    for (var i = 0; i < 5; i++) {
      final multi = userTags['sehir_$i'];
      if (multi == null) break;
      if (multi == 'farketmez') return true;
      if (uni.city == multi) return true;
    }
    return false;
  }

  bool _cityMatches(UniStrengthEntry uni, Map<String, String> userTags) {
    final sehir = userTags['sehir'];
    if (sehir != null && sehir != 'farketmez' && uni.city == sehir) return true;
    for (var i = 0; i < 5; i++) {
      final multi = userTags['sehir_$i'];
      if (multi == null) break;
      if (multi != 'farketmez' && uni.city == multi) return true;
    }
    return false;
  }

  // ─── Tür kontrolü ──────────────────────────────────────────
  bool _matchesType(UniStrengthEntry uni, Map<String, String> userTags) {
    final tip = userTags['tip'];
    if (tip == null || tip == 'farketmez' || tip == 'burslu_vakif') return true;
    if (tip == 'devlet' && uni.type != 'devlet') return false;
    if (tip == 'devlet_oncelikli' && uni.type != 'devlet') return false;
    return true;
  }

  // ─── Özet ───────────────────────────────────────────────────
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
