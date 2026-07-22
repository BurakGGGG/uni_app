/// Üni ile Sohbet — veri modelleri (saf Dart).
///
/// Sohbet turları, çipler ve birikimli taslak ([ChatDraft]) burada;
/// adım kararları [ChatFlow]'da. Taslak, onayda mevcut kalıcı modellere
/// (StudentScoreProfile / WizardPrefs / WizardFilter) köprülenir — motor
/// ve depolama katmanı sohbetten habersizdir.
library;

import '../../preference_wizard/domain/models/student_score_profile.dart';
import '../../preference_wizard/domain/models/wizard_filter.dart';
import '../../preference_wizard/domain/models/wizard_prefs.dart';
import '../../score_calculator/domain/models/match_result.dart';
import 'robot_message.dart';
import 'wizard_intent.dart';

/// Sohbet adımları. Sıra: greeting → scoreInfo → interests → constraints →
/// confirm → done; dolu gelen alanların adımları atlanır.
enum ChatStep { greeting, scoreInfo, interests, constraints, confirm, done }

/// Akışın controller'dan istediği yan etki.
enum ChatEffect {
  none,

  /// Profili kaydet, filtre/prefs uygula, motoru çalıştır, önizlemeyi bas.
  search,

  /// Mevcut sonuç ekranına geç (`/preference-wizard/results`).
  goResults,

  /// Puan hesaplayıcıya köprü (`/score-calculator`).
  goCalculator,

  /// "En iyi X bölümleri" listesine köprü — hedef bölüm, üretilen mesajın
  /// [RobotMessage.actionArg]'ında taşınır.
  goBestPrograms,
}

/// Çip komutları — [ChatChip.sendText] taşımayan çipler akışa komut verir.
enum ChatCommand {
  search,
  restart,
  goResults,
  update,
  skip,
  focusDept,
  allDepts,
  calcScore,
}

/// Üni sorusunun altındaki tıklanabilir mini balon. [sendText] doluysa çip
/// serbest yazıyla AYNI yoldan geçer (kullanıcı balonu olarak düşer ve
/// parse edilir); değilse [command] çalışır.
class ChatChip {
  final String label;
  final String? sendText;
  final ChatCommand? command;

  /// focusDept için motor sorgusu.
  final String? value;

  const ChatChip(this.label, {this.sendText, this.command, this.value})
      : assert(sendText != null || command != null);
}

/// Sohbet geçmişindeki tek satır.
sealed class ChatTurn {
  const ChatTurn();
}

/// Üni balonu (mood dahil — avatar yanında gösterilir).
class UniChatTurn extends ChatTurn {
  final RobotMessage message;
  const UniChatTurn(this.message);
}

/// Kullanıcı balonu (yazılan metin ya da tıklanan çipin etiketi).
class UserChatTurn extends ChatTurn {
  final String text;
  const UserChatTurn(this.text);
}

/// Sohbet içi öneri önizlemesi (ilk 3 eşleşme mini kart).
class PreviewChatTurn extends ChatTurn {
  final List<UniversityMatch> matches;
  const PreviewChatTurn(this.matches);
}

/// Sohbet boyunca biriken taslak. Alanlar [WizardIntent]'ten dolar;
/// `...Done` bayrakları "soruldu ve yanıtlandı/geçildi"yi izler ki dolu
/// gelen adımlar atlansın.
class ChatDraft {
  final String? scoreType;
  final int? rank;
  final double? score;
  final Set<String> cityIds;
  final Set<String> uniTypes;
  final Set<String> languages;
  final Set<String> programTypes;
  final bool? onlyScholarship;
  final List<DeptIntent> depts;
  final Set<String> interestKeys;
  final bool interestsDone;
  final bool constraintsDone;

  /// Birden çok bölümden biri seçildi ya da "Hepsi" dendi.
  final bool focusChosen;

  const ChatDraft({
    this.scoreType,
    this.rank,
    this.score,
    this.cityIds = const {},
    this.uniTypes = const {},
    this.languages = const {},
    this.programTypes = const {},
    this.onlyScholarship,
    this.depts = const [],
    this.interestKeys = const {},
    this.interestsDone = false,
    this.constraintsDone = false,
    this.focusChosen = false,
  });

  /// Dönen kullanıcı: kayıtlı profil + tercihlerden dolu taslak (tüm
  /// adımlar yanıtlanmış sayılır; kullanıcı yalnız değişiklik söyler).
  factory ChatDraft.fromProfile(StudentScoreProfile p, WizardPrefs prefs) {
    return ChatDraft(
      scoreType: p.scoreType.isEmpty ? null : p.scoreType,
      rank: p.hasRank ? p.rank : null,
      score: p.hasScore ? p.placementScore : null,
      cityIds: prefs.cityIds,
      uniTypes: prefs.uniTypes,
      interestKeys: prefs.interestKeys,
      interestsDone: true,
      constraintsDone: true,
      focusChosen: true,
    );
  }

  bool get hasScoreInfo => rank != null || score != null;
  bool get canSearch => scoreType != null && hasScoreInfo;
  bool get needsFocus => depts.length > 1 && !focusChosen;

  /// Motor filtresine yazılacak tek sorgu — birden çok bölümde boş kalır
  /// ("Hepsi" semantiği; kategoriler zaten tümünü gösterir).
  String get filterDeptQuery => depts.length == 1 ? depts.single.query : '';

  ChatDraft applyIntent(WizardIntent i) {
    final mergedDepts = [...depts];
    for (final d in i.depts) {
      if (!mergedDepts.any((e) => e.query == d.query)) mergedDepts.add(d);
    }
    // Olumsuzlamalar ("istanbulu istemiyorum") eklemelerden SONRA silinir —
    // aynı mesajda hem ekleyip hem çıkaran çelişkide çıkarma kazanır.
    mergedDepts
        .removeWhere((d) => i.removeDepts.any((r) => r.query == d.query));
    return _copy(
      scoreType: i.scoreType ?? scoreType,
      rank: i.rank ?? rank,
      score: i.score ?? score,
      cityIds: {...cityIds, ...i.cityIds}..removeAll(i.removeCityIds),
      uniTypes: {...uniTypes, ...i.uniTypes}..removeAll(i.removeUniTypes),
      languages: {...languages, ...i.languages}
        ..removeAll(i.removeLanguages),
      programTypes: {...programTypes, ...i.programTypes}
        ..removeAll(i.removeProgramTypes),
      onlyScholarship: i.onlyScholarship ?? onlyScholarship,
      depts: mergedDepts,
      interestKeys: {...interestKeys, ...i.interestKeys}
        ..removeAll(i.removeInterestKeys),
      interestsDone: interestsDone ||
          i.depts.isNotEmpty ||
          i.interestKeys.isNotEmpty ||
          i.removeDepts.isNotEmpty ||
          i.removeInterestKeys.isNotEmpty,
      constraintsDone: constraintsDone ||
          i.cityIds.isNotEmpty ||
          i.uniTypes.isNotEmpty ||
          i.languages.isNotEmpty ||
          i.programTypes.isNotEmpty ||
          i.onlyScholarship != null ||
          i.removeCityIds.isNotEmpty ||
          i.removeUniTypes.isNotEmpty ||
          i.removeLanguages.isNotEmpty ||
          i.removeProgramTypes.isNotEmpty,
      // Yeni bölüm eklendiyse odak sorusu yeniden anlamlı olabilir; yalnız
      // liste tekrar 1'i aşarsa sorulur (needsFocus bakar).
      focusChosen: focusChosen && i.depts.isEmpty,
    );
  }

  ChatDraft markInterestsDone() => _copy(interestsDone: true);
  ChatDraft markConstraintsDone() => _copy(constraintsDone: true);

  /// Odak seçimi: yalnız seçilen bölüm kalır.
  ChatDraft chooseFocus(String query) {
    final chosen = depts.where((d) => d.query == query).toList();
    return _copy(
      depts: chosen.isEmpty ? depts : [chosen.first],
      focusChosen: true,
    );
  }

  ChatDraft chooseAllDepts() => _copy(focusChosen: true);

  /// Geçersiz puanı sil (akış yeniden sorar).
  ChatDraft withoutScore() {
    return ChatDraft(
      scoreType: scoreType,
      rank: rank,
      cityIds: cityIds,
      uniTypes: uniTypes,
      languages: languages,
      programTypes: programTypes,
      onlyScholarship: onlyScholarship,
      depts: depts,
      interestKeys: interestKeys,
      interestsDone: interestsDone,
      constraintsDone: constraintsDone,
      focusChosen: focusChosen,
    );
  }

  // ── Kalıcı modellere köprüler ──

  /// Mevcut hızlı-giriş davranışıyla aynı: yalnız sıralamayla girişte
  /// placementScore 0 kalır.
  StudentScoreProfile buildProfile(DateTime now) {
    assert(canSearch);
    return StudentScoreProfile(
      scoreType: scoreType!,
      placementScore: score ?? 0,
      rank: rank,
      year: now.year,
      updatedAt: now,
    );
  }

  /// Yumuşak sinyaller — ücretsiz katman dahil herkese uygulanır
  /// (eski giriş formunun yazdığı alanların aynısı).
  WizardPrefs buildPrefs() {
    return WizardPrefs(
      cityIds: cityIds,
      uniTypes: uniTypes,
      interestKeys: interestKeys,
    );
  }

  /// Sert filtreler. Filtre sheet'i Plus'a kilitli olduğundan ücretsiz
  /// katmanda yalnız deptQuery yazılır (sonuç ekranındaki arama kutusu
  /// zaten ücretsiz); şehir/tür sinyali prefs'ten boost olarak gelir.
  WizardFilter buildFilter({required bool hasPlus}) {
    if (!hasPlus) return WizardFilter(deptQuery: filterDeptQuery);
    return WizardFilter(
      cityIds: cityIds,
      uniTypes: uniTypes,
      languages: languages,
      programTypes: programTypes,
      onlyScholarship: onlyScholarship ?? false,
      deptQuery: filterDeptQuery,
    );
  }

  ChatDraft _copy({
    String? scoreType,
    int? rank,
    double? score,
    Set<String>? cityIds,
    Set<String>? uniTypes,
    Set<String>? languages,
    Set<String>? programTypes,
    bool? onlyScholarship,
    List<DeptIntent>? depts,
    Set<String>? interestKeys,
    bool? interestsDone,
    bool? constraintsDone,
    bool? focusChosen,
  }) {
    return ChatDraft(
      scoreType: scoreType ?? this.scoreType,
      rank: rank ?? this.rank,
      score: score ?? this.score,
      cityIds: cityIds ?? this.cityIds,
      uniTypes: uniTypes ?? this.uniTypes,
      languages: languages ?? this.languages,
      programTypes: programTypes ?? this.programTypes,
      onlyScholarship: onlyScholarship ?? this.onlyScholarship,
      depts: depts ?? this.depts,
      interestKeys: interestKeys ?? this.interestKeys,
      interestsDone: interestsDone ?? this.interestsDone,
      constraintsDone: constraintsDone ?? this.constraintsDone,
      focusChosen: focusChosen ?? this.focusChosen,
    );
  }
}
