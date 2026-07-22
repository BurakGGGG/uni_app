import '../../../core/utils/turkish_compare.dart';
import '../../preference_wizard/domain/similar_programs.dart';
import 'chat_nlu_client.dart';
import 'tercih_lexicon.dart';
import 'wizard_intent.dart';

/// Kural tabanlı Türkçe tercih ayrıştırıcısı (saf Dart — ağ yok, Flutter yok).
///
/// Kapalı kümeler üzerinde çalışır: 81 il (+ takma adlar), asset'ten gelen
/// gerçek bölüm adları, meslek sözlüğü, puan türü/kısıt kelimeleri ve
/// sayılar. Ek toleransı kök indirgemeyle sağlanır ("İstanbul'daki",
/// "ankarada", "psikolojiyi"). Anlaşılamayan kalan metin
/// [WizardIntent.unresolved]'a yazılır — kural motoru asla tahmin uydurmaz.
///
/// Sözlükler kurucuda indekslenir; [parse] senkron ve yan etkisizdir.
/// Controller katmanı şehir haritasını `CityHelper.cityMap`'ten, bölüm
/// adlarını `allScoredDepartmentsProvider`'dan enjekte eder.
class TercihNlu {
  /// fold(il adı) → plaka kodu ('istanbul' → '34').
  final Map<String, String> _cityIdByName;

  /// normalize bölüm adı → en kısa gerçek ad ('tip' → 'Tıp').
  final Map<String, String> _deptByNorm;

  /// Bölüm adlarındaki en yüksek kelime sayısı (n-gram tavanı, ≤5).
  final int _maxDeptWords;

  TercihNlu._(this._cityIdByName, this._deptByNorm, this._maxDeptWords);

  factory TercihNlu({
    required Map<String, String> cityMap,
    required Set<String> deptNames,
  }) {
    final cities = <String, String>{
      for (final e in cityMap.entries) _fold(e.value): e.key,
      ...cityAliases,
    };
    final depts = <String, String>{};
    var maxWords = 1;
    for (final name in deptNames) {
      final norm = normalizeProgramName(name);
      if (norm.length < 3) continue;
      final prev = depts[norm];
      if (prev == null || name.length < prev.length) depts[norm] = name;
      final words = ' '.allMatches(norm).length + 1;
      if (words > maxWords) maxWords = words;
    }
    return TercihNlu._(cities, depts, maxWords > 5 ? 5 : maxWords);
  }

  // ── Sayı desenleri ──
  // Sıra önemli: binlik ayraçlı ("80.000", "80,000") → ondalık virgül
  // ("462,5") → ondalık nokta ("462.5") → düz tam sayı.
  static final RegExp _numberRe = RegExp(
      r'\d{1,3}(?:[.,]\d{3})+|\d+,\d+|\d+\.\d{1,2}|\d+');
  static final RegExp _thousandsRe = RegExp(r'^\d{1,3}(?:[.,]\d{3})+$');
  static final RegExp _numTokenRe = RegExp(r'^num(\d+)tok$');
  static final RegExp _binRe = RegExp(r'^bin(ler)?(de|e|i|ce)?$');
  static final RegExp _milyonRe = RegExp(r'^milyon(lar)?(da|a|u)?$');

  /// Klausel ayracı: "İzmir olsun ama İstanbul olmasın".
  static final RegExp _clauseSplitRe =
      RegExp(r'\b(?:ama|fakat|ancak|lakin)\b', caseSensitive: false);

  WizardIntent parse(String utterance) {
    final clauses = utterance
        .split(_clauseSplitRe)
        .where((c) => c.trim().isNotEmpty)
        .toList();
    if (clauses.isEmpty) return const WizardIntent();

    String? scoreType;
    int? rank;
    double? score;
    bool? onlyScholarship;
    final cityIds = <String>{}, uniTypes = <String>{};
    final languages = <String>{}, programTypes = <String>{};
    final interestKeys = <String>{};
    final depts = <DeptIntent>[];
    final removeCityIds = <String>{}, removeUniTypes = <String>{};
    final removeLanguages = <String>{}, removeProgramTypes = <String>{};
    final removeInterestKeys = <String>{};
    final removeDepts = <DeptIntent>[];
    final unresolved = <String>[];

    void addDeptTo(List<DeptIntent> list, DeptIntent d) {
      if (!list.any((e) => e.query == d.query)) list.add(d);
    }

    for (final clause in clauses) {
      final c = _parseClause(clause);
      if (_isNegatedClause(clause)) {
        // Olumsuz klausel: varlıklar taslaktan ÇIKARILIR. Sayısal alanlar
        // alınmaz ("önlisans olmasın" türetilmiş TYT'yi de taşımasın).
        removeCityIds.addAll(c.cityIds);
        removeUniTypes.addAll(c.uniTypes);
        removeLanguages.addAll(c.languages);
        removeProgramTypes.addAll(c.programTypes);
        removeInterestKeys.addAll(c.interestKeys);
        for (final d in c.depts) {
          addDeptTo(removeDepts, d);
        }
        // "burslu istemiyorum" → şart kalksın.
        if (c.onlyScholarship == true) onlyScholarship = false;
      } else {
        scoreType ??= c.scoreType;
        rank ??= c.rank;
        score ??= c.score;
        cityIds.addAll(c.cityIds);
        uniTypes.addAll(c.uniTypes);
        languages.addAll(c.languages);
        programTypes.addAll(c.programTypes);
        interestKeys.addAll(c.interestKeys);
        for (final d in c.depts) {
          addDeptTo(depts, d);
        }
        onlyScholarship ??= c.onlyScholarship;
      }
      if (c.unresolved.isNotEmpty) unresolved.add(c.unresolved);
    }

    return WizardIntent(
      scoreType: scoreType,
      rank: rank,
      score: score,
      cityIds: cityIds,
      uniTypes: uniTypes,
      languages: languages,
      programTypes: programTypes,
      onlyScholarship: onlyScholarship,
      depts: depts,
      interestKeys: interestKeys,
      unresolved: unresolved.join(' '),
      removeCityIds: removeCityIds,
      removeUniTypes: removeUniTypes,
      removeLanguages: removeLanguages,
      removeProgramTypes: removeProgramTypes,
      removeDepts: removeDepts,
      removeInterestKeys: removeInterestKeys,
    );
  }

  /// Klauselde olumsuzluk var mı ("istemiyorum", "olmasın", "hariç"…).
  /// "İstanbul olmaz mı?" bir ÖNERİDİR — 'mı' takip eden 'olmaz' sayılmaz.
  static bool _isNegatedClause(String clause) {
    final tokens = _fold(clause).split(' ');
    for (var i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      if (t == 'olmaz' &&
          i + 1 < tokens.length &&
          tokens[i + 1].startsWith('mi')) {
        continue;
      }
      if (_isNegationToken(t)) return true;
    }
    return false;
  }

  static bool _isNegationToken(String t) =>
      t.startsWith('istemi') || // istemiyorum, istemiyoruz
      t.startsWith('isteme') || // istemem, istemez, istemeyiz
      t == 'olmasin' ||
      t == 'olmaz' ||
      t == 'haric' ||
      t.startsWith('cikar') || // çıkar, çıkart
      t == 'kaldir' ||
      t == 'sil';

  WizardIntent _parseClause(String utterance) {
    // 1) Sayı literallerini yakala, yer tutucuya çevir — fold noktalamayı
    //    sildiği için "80.000" önce güvenceye alınmalı.
    final numbers = <double>[];
    var s = utterance.replaceAll('İ', 'i').replaceAll('I', 'ı');
    s = turkishNormalize(s);
    s = s.replaceAllMapped(_numberRe, (m) {
      numbers.add(_numberValue(m[0]!));
      return ' num${numbers.length - 1}tok ';
    });

    // 2) Fold + tokenize.
    s = s.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    final tokens =
        s.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    final used = List<bool>.filled(tokens.length, false);

    String? scoreType;
    int? rank;
    double? score;
    final cityIds = <String>{};
    final uniTypes = <String>{};
    final languages = <String>{};
    final programTypes = <String>{};
    bool? onlyScholarship;
    final depts = <DeptIntent>[];
    final interestKeys = <String>{};

    void addDept(DeptIntent d) {
      if (!depts.any((e) => e.query == d.query)) depts.add(d);
    }

    // ── 3) Sayılar: çarpan + bağlam penceresi ──
    for (var i = 0; i < tokens.length; i++) {
      final numMatch = _numTokenRe.firstMatch(tokens[i]);
      if (numMatch == null) continue;
      used[i] = true;
      var value = numbers[int.parse(numMatch[1]!)];
      final prev = i > 0 ? tokens[i - 1] : '';
      var next = i + 1;

      // "%50 burslu" — sayı burs oranıdır, puan/sıra değil.
      if (prev == 'yuzde' ||
          (next < tokens.length && tokens[next].startsWith('burs'))) {
        continue;
      }
      // "2 yıllık" / "4 yıllık" — süre kalıbı.
      if (next < tokens.length && tokens[next].startsWith('yillik')) {
        used[next] = true;
        if (value == 2) programTypes.add('Önlisans');
        if (value == 4) programTypes.add('Lisans');
        continue;
      }
      if (next < tokens.length && _binRe.hasMatch(tokens[next])) {
        value *= 1000;
        used[next++] = true;
      } else if (next < tokens.length && _milyonRe.hasMatch(tokens[next])) {
        value *= 1000000;
        used[next++] = true;
      }

      var nearRank = false, nearScore = false;
      for (var j = i - 2; j <= next + 1; j++) {
        if (j < 0 || j >= tokens.length || j == i) continue;
        if (_isRankKeyword(tokens[j])) nearRank = true;
        if (_isScoreKeyword(tokens[j])) nearScore = true;
      }
      final fractional = value != value.roundToDouble();
      if (nearRank == nearScore) {
        // İkisi de (ya da hiçbiri): büyüklük sezgisi — YKS yerleştirme
        // puanı 560'ı aşamaz.
        nearScore = fractional || value <= 560;
        nearRank = !nearScore;
      }
      if (nearRank && !fractional && value >= 1 && value <= 4000000) {
        rank ??= value.round();
      } else if (nearScore && value > 0 && value <= 560) {
        score ??= value;
      } else if (!nearScore && !fractional && value > 560 && value <= 4000000) {
        // "puanım 600" gibi çelişkili girdi sıralamaya DEVRİLMEZ —
        // akış yeniden sorar.
        rank ??= value.round();
      }
    }

    // ── 4) Puan türü ──
    for (var i = 0; i < tokens.length; i++) {
      if (used[i]) continue;
      if (tokens[i] == 'esit' &&
          i + 1 < tokens.length &&
          !used[i + 1] &&
          _stems(tokens[i + 1]).contains('agirlik')) {
        scoreType ??= 'EA';
        used[i] = used[i + 1] = true;
        continue;
      }
      final exact = scoreTypeExact[tokens[i]];
      if (exact != null) {
        scoreType ??= exact;
        used[i] = true;
        continue;
      }
      for (final stem in _stems(tokens[i])) {
        final hit = scoreTypeStemmed[stem];
        if (hit != null) {
          scoreType ??= hit;
          used[i] = true;
          break;
        }
      }
    }

    // ── 5) Program türü kalıpları ("ön lisans", "iki yıllık") ──
    for (var i = 0; i + 1 < tokens.length; i++) {
      if (used[i] || used[i + 1]) continue;
      final pair = '${tokens[i]} ${tokens[i + 1]}';
      if (pair == 'on lisans' || pair == 'iki yillik') {
        programTypes.add('Önlisans');
        used[i] = used[i + 1] = true;
      } else if (pair == 'dort yillik') {
        programTypes.add('Lisans');
        used[i] = used[i + 1] = true;
      }
    }

    // ── 6) Bölüm adları — uzun n-gram önce (tam ad > parça) ──
    for (var n = _maxDeptWords; n >= 1; n--) {
      for (var i = 0; i + n <= tokens.length; i++) {
        var free = true;
        for (var j = i; j < i + n; j++) {
          if (used[j]) free = false;
        }
        if (!free) continue;
        final head =
            n == 1 ? '' : '${tokens.sublist(i, i + n - 1).join(' ')} ';
        String? realName;
        for (final last in _stems(tokens[i + n - 1])) {
          realName = _deptByNorm['$head$last'];
          if (realName != null) break;
        }
        if (realName == null) continue;
        for (var j = i; j < i + n; j++) {
          used[j] = true;
        }
        // Motor iki tarafı da toLowerCase'lediğinden ad kendisiyle ve
        // "(İngilizce)" gibi türevleriyle her zaman eşleşir.
        addDept(
            DeptIntent(label: realName, query: realName.toLowerCase()));
      }
    }

    // ── 7) Meslek sözlüğü — bigram önce ──
    void applyEntry(LexiconEntry e) {
      interestKeys.addAll(e.interestKeys);
      final q = e.deptQuery;
      if (q != null) addDept(DeptIntent(label: e.label, query: q));
    }

    for (var i = 0; i + 1 < tokens.length; i++) {
      if (used[i] || used[i + 1]) continue;
      LexiconEntry? entry;
      for (final s1 in _stems(tokens[i])) {
        for (final s2 in _stems(tokens[i + 1])) {
          entry = professionBigrams['$s1 $s2'];
          if (entry != null) break;
        }
        if (entry != null) break;
      }
      if (entry == null) continue;
      applyEntry(entry);
      used[i] = used[i + 1] = true;
    }
    for (var i = 0; i < tokens.length; i++) {
      if (used[i]) continue;
      for (final stem in _stems(tokens[i])) {
        final entry = professionLexicon[stem];
        if (entry != null) {
          applyEntry(entry);
          used[i] = true;
          break;
        }
      }
    }

    // ── 8) Şehirler ──
    for (var i = 0; i < tokens.length; i++) {
      if (used[i]) continue;
      for (final stem in _stems(tokens[i])) {
        final id = _cityIdByName[stem];
        if (id != null) {
          cityIds.add(id);
          used[i] = true;
          break;
        }
      }
    }

    // ── 9) Kısıt kelimeleri ──
    for (var i = 0; i < tokens.length; i++) {
      if (used[i]) continue;
      if (tokens[i].startsWith('burs')) {
        onlyScholarship = true;
        used[i] = true;
        continue;
      }
      for (final stem in _stems(tokens[i])) {
        String? uniType;
        String? language;
        String? programType;
        switch (stem) {
          case 'devlet':
            uniType = 'Devlet';
          case 'vakif':
          case 'ozel':
            uniType = 'Vakıf';
          case 'ingilizce':
            language = 'İngilizce';
          case 'turkce':
            language = 'Türkçe';
          case 'onlisans':
            programType = 'Önlisans';
          case 'lisans':
            programType = 'Lisans';
        }
        if (uniType == null && language == null && programType == null) {
          continue;
        }
        if (uniType != null) uniTypes.add(uniType);
        if (language != null) languages.add(language);
        if (programType != null) programTypes.add(programType);
        used[i] = true;
        break;
      }
    }

    // Önlisans isteyen öğrenci TYT ile yerleşir.
    if (programTypes.contains('Önlisans')) scoreType ??= 'TYT';

    // ── 10) Çözülemeyen kalan ──
    final leftover = <String>[];
    for (var i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      if (used[i] || t.length < 2) continue;
      if (chatStopwords.contains(t)) continue;
      if (_isRankKeyword(t) || _isScoreKeyword(t)) continue;
      if (_isNegationToken(t)) continue;
      if (_binRe.hasMatch(t) || _milyonRe.hasMatch(t) || t == 'yuzde') {
        continue;
      }
      leftover.add(t);
    }

    return WizardIntent(
      scoreType: scoreType,
      rank: rank,
      score: score,
      cityIds: cityIds,
      uniTypes: uniTypes,
      languages: languages,
      programTypes: programTypes,
      onlyScholarship: onlyScholarship,
      depts: depts,
      interestKeys: interestKeys,
      unresolved: leftover.join(' '),
    );
  }

  /// Sunucu çıkarımını yerel kapalı kümelere oturtur (grounding).
  ///
  /// Ad parçaları ([RemoteParse.cities] / [RemoteParse.depts]) tek tek
  /// [parse]'tan geçirilir: il adı plakaya, bölüm adı sözlük/asset
  /// karşılığına çevrilir. Eşleşmeyen (uydurulmuş) değer sessizce düşer —
  /// filtrelere yalnız yerelde doğrulanmış kimlikler girer. Sayısal
  /// alanlar yerel ayrıştırıcıyla aynı sınırlardan geçer.
  WizardIntent groundRemote(RemoteParse r) {
    final cityIds = <String>{};
    for (final name in r.cities) {
      cityIds.addAll(parse(name).cityIds);
    }
    final depts = <DeptIntent>[];
    final interestKeys = <String>{};
    for (final name in r.depts) {
      final parsed = parse(name);
      for (final d in parsed.depts) {
        if (!depts.any((e) => e.query == d.query)) depts.add(d);
      }
      interestKeys.addAll(parsed.interestKeys);
    }
    const validTypes = {'TYT', 'SAY', 'EA', 'SÖZ', 'DİL'};
    final rank = r.rank;
    final score = r.score;
    return WizardIntent(
      scoreType: validTypes.contains(r.scoreType) ? r.scoreType : null,
      rank: (rank != null && rank >= 1 && rank <= 4000000) ? rank : null,
      score: (score != null && score > 0 && score <= 560) ? score : null,
      cityIds: cityIds,
      uniTypes: r.uniTypes.where({'Devlet', 'Vakıf'}.contains).toSet(),
      languages: r.languages.where({'Türkçe', 'İngilizce'}.contains).toSet(),
      programTypes:
          r.programTypes.where({'Lisans', 'Önlisans'}.contains).toSet(),
      onlyScholarship: r.onlyScholarship,
      depts: depts,
      interestKeys: interestKeys,
    );
  }

  /// [_fold]'un dışa açık hali — aynı katlama kuralını kullanması gereken
  /// diğer saf ayrıştırıcılar için (ör. üstünlük sorusu tespiti).
  static String fold(String input) => _fold(input);

  /// Türkçe küçük harf + aksan katlama + noktalama temizliği.
  /// Dart'ta 'İ'.toLowerCase() birleşik nokta ürettiğinden İ/I elle iner
  /// (normalizeProgramName ile aynı sıra).
  static String _fold(String input) {
    var s = input.replaceAll('İ', 'i').replaceAll('I', 'ı');
    s = turkishNormalize(s);
    return s
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static double _numberValue(String literal) {
    if (_thousandsRe.hasMatch(literal)) {
      return double.parse(literal.replaceAll(RegExp(r'[.,]'), ''));
    }
    return double.parse(literal.replaceAll(',', '.'));
  }

  /// Token + olası kökleri (en fazla iki ek soyulur, kök ≥3 harf).
  /// Uydurma kökler zararsızdır: tüm aramalar kapalı küme üyeliğidir.
  static Set<String> _stems(String token) {
    final out = <String>{token};
    var frontier = <String>{token};
    for (var depth = 0; depth < 2 && frontier.isNotEmpty; depth++) {
      final next = <String>{};
      for (final t in frontier) {
        for (final suffix in kSuffixes) {
          if (t.length - suffix.length >= 3 && t.endsWith(suffix)) {
            final stem = t.substring(0, t.length - suffix.length);
            if (out.add(stem)) next.add(stem);
          }
        }
      }
      frontier = next;
    }
    return out;
  }

  static bool _isRankKeyword(String t) =>
      t == 'sira' ||
      t == 'siram' ||
      t == 'derece' ||
      t == 'derecem' ||
      t.startsWith('sirala') ||
      t.startsWith('basari');

  static bool _isScoreKeyword(String t) =>
      t == 'net' || t == 'netim' || t == 'netlerim' || t == 'aldim' ||
      t.startsWith('puan');
}
