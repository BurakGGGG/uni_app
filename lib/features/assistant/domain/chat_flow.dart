import '../../preference_wizard/domain/match_reason.dart';
import '../../preference_wizard/domain/models/student_score_profile.dart';
import '../../preference_wizard/domain/models/wizard_prefs.dart';
import '../../preference_wizard/domain/similar_programs.dart';
import 'best_programs_intent.dart';
import 'chat_models.dart';
import 'robot_brain.dart';
import 'robot_message.dart';
import 'robot_mood.dart';
import 'robot_scripts.dart';
import 'tercih_nlu.dart';
import 'wizard_intent.dart';

/// Bir kullanıcı girdisinin akış sonucu: yeni taslak + adım, Üni'nin
/// basacağı balonlar, son sorunun çipleri ve controller'dan istenen etki.
class ChatFlowResult {
  final ChatDraft draft;
  final ChatStep step;
  final List<RobotMessage> messages;
  final List<ChatChip> chips;
  final ChatEffect effect;

  const ChatFlowResult({
    required this.draft,
    required this.step,
    this.messages = const [],
    this.chips = const [],
    this.effect = ChatEffect.none,
  });
}

/// Üni ile Sohbet — saf durum makinesi (Flutter yok, Riverpod yok).
///
/// Karar mantığının tamamı burada; UI yalnız [ChatFlowResult]'ı çizer.
/// Serbest yazı ve çipler AYNI yoldan geçer: çipin [ChatChip.sendText]'i
/// varsa kullanıcı balonu olur ve [TercihNlu] ile ayrıştırılır. Dolu gelen
/// alanların adımları atlanır — "İstanbul'da devlet psikoloji, sıralamam
/// 80 bin" tek mesajı üç adımı birden bitirir.
class ChatFlow {
  final TercihNlu nlu;

  /// Plaka → il adı (özet ve onay balonları için).
  final Map<String, String> cityNames;

  const ChatFlow({required this.nlu, required this.cityNames});

  // ── Çipler ──
  //
  // Etiketler dile göre çevrilir; [ChatChip.sendText] HER ZAMAN Türkçe
  // kalır — kullanıcı balonunda etiket görünür ([ChatWizardController]
  // chip.label'ı basar), ayrıştırıcıya giden ise sendText'tir ve
  // [TercihNlu] yalnız Türkçe anlar.

  static bool get _en => RobotScripts.isEn;

  static List<ChatChip> get scoreTypeChips => const [
        ChatChip('SAY', sendText: 'say'),
        ChatChip('EA', sendText: 'ea'),
        ChatChip('SÖZ', sendText: 'söz'),
        ChatChip('DİL', sendText: 'dil'),
        ChatChip('TYT', sendText: 'tyt'),
      ];

  /// Hepsi meslek sözlüğüne dayanır — asset bölüm listesi yüklenmemiş
  /// olsa da çözülür.
  static List<ChatChip> get interestChips => [
        ChatChip(_en ? 'Computer / Software' : 'Bilgisayar / Yazılım',
            sendText: 'yazılım'),
        ChatChip(_en ? 'Medicine / Health' : 'Tıp / Sağlık',
            sendText: 'doktor'),
        ChatChip(_en ? 'Law' : 'Hukuk', sendText: 'avukat'),
        ChatChip(_en ? 'Psychology' : 'Psikoloji', sendText: 'psikolog'),
        ChatChip(_en ? 'Teaching' : 'Öğretmenlik', sendText: 'öğretmen'),
        ChatChip(_en ? 'Engineering' : 'Mühendislik', sendText: 'mühendis'),
        ChatChip(_en ? 'Business / Economics' : 'İşletme / İktisat',
            sendText: 'ekonomist'),
        ChatChip(_en ? 'Media / Communication' : 'İletişim / Medya',
            sendText: 'medya'),
        ChatChip(_en ? "Doesn't matter" : 'Farketmez',
            command: ChatCommand.skip),
      ];

  static List<ChatChip> get constraintChips => [
        const ChatChip('İstanbul', sendText: 'istanbul'),
        const ChatChip('Ankara', sendText: 'ankara'),
        const ChatChip('İzmir', sendText: 'izmir'),
        ChatChip(_en ? 'Public' : 'Devlet', sendText: 'devlet'),
        ChatChip(_en ? 'Foundation' : 'Vakıf', sendText: 'vakıf'),
        ChatChip(_en ? "Doesn't matter" : 'Farketmez',
            command: ChatCommand.skip),
      ];

  static List<ChatChip> get confirmChips => [
        ChatChip(_en ? 'Search 🔍' : 'Ara 🔍', command: ChatCommand.search),
        ChatChip(_en ? 'Start over' : 'Baştan başla',
            command: ChatCommand.restart),
      ];

  static List<ChatChip> get doneChips => [
        ChatChip(_en ? 'See all' : 'Tümünü gör',
            command: ChatCommand.goResults),
        ChatChip(_en ? 'New search' : 'Yeni arama',
            command: ChatCommand.restart),
      ];

  static List<ChatChip> get returningChips => [
        ChatChip(_en ? 'Go to results' : 'Sonuçlara geç',
            command: ChatCommand.goResults),
        ChatChip(_en ? 'Update my info' : 'Bilgilerimi güncelle',
            command: ChatCommand.update),
        ChatChip(_en ? 'Start over' : 'Baştan başla',
            command: ChatCommand.restart),
      ];

  // ── Giriş noktaları ──

  /// Sohbeti açar. Profili olan kullanıcı hızlı yol çipleriyle karşılanır;
  /// yeni kullanıcı selamlama + ilk soruyu alır.
  ChatFlowResult start({StudentScoreProfile? profile, WizardPrefs? prefs}) {
    final hasProfile = profile != null && profile.scoreType.isNotEmpty;
    if (hasProfile) {
      final draft =
          ChatDraft.fromProfile(profile, prefs ?? const WizardPrefs());
      final text = RobotScripts.chatHelloBack.text
          .replaceAll('{profile}', _profileSummary(profile));
      return ChatFlowResult(
        draft: draft,
        step: ChatStep.greeting,
        messages: [
          RobotMessage(RobotScripts.chatHelloBack.id, text,
              RobotScripts.chatHelloBack.mood),
        ],
        chips: returningChips,
      );
    }
    final next = _askNext(const ChatDraft());
    return ChatFlowResult(
      draft: const ChatDraft(),
      step: next.step,
      messages: [RobotScripts.chatHelloNew.toMessage(), ...next.messages],
      chips: next.chips,
    );
  }

  /// Serbest yazı (ya da sendText'li çip) — tek ayrıştırma yolu.
  ChatFlowResult handleText(
    String text, {
    required ChatDraft draft,
    required ChatStep step,
  }) {
    final intent = nlu.parse(text);

    // "En iyi tıp bölümleri" tercih taslağı kurmaz — ayrı bir ekrana gider.
    // Taslak ve adım olduğu gibi korunur.
    final best = detectBestProgramsIntent(text, intent);
    if (best != null) {
      return ChatFlowResult(
        draft: draft,
        step: step,
        messages: [
          RobotMessage(
            'chat.bestPrograms.v1',
            best.departmentLabel == null
                ? (_en
                    ? 'Let me open the best programs list — pick a field there.'
                    : 'En iyi bölümler listesini açıyorum, oradan alanı '
                        'seçebilirsin.')
                : (_en
                    ? '${best.departmentLabel}: here are the top universities '
                        'by placement rank.'
                    : '${best.departmentLabel} için en iyi üniversiteleri '
                        'başarı sırasına göre sıraladım.'),
            RobotMood.happy,
            action: RobotAction.openBestPrograms,
            actionArg: best.departmentLabel,
          ),
        ],
        chips: step == ChatStep.done ? doneChips : _askNext(draft).chips,
        effect: ChatEffect.goBestPrograms,
      );
    }

    return handleIntent(intent, draft: draft, step: step);
  }

  /// Hazır intent'le ilerleme — Faz B'de sunucudan gelen (grounding'den
  /// geçmiş) intent de aynı kapıdan girer.
  ChatFlowResult handleIntent(
    WizardIntent intent, {
    required ChatDraft draft,
    required ChatStep step,
  }) {
    if (!intent.hasAny) {
      final pending = _askNext(draft);
      return ChatFlowResult(
        draft: draft,
        step: step,
        messages: [RobotScripts.chatConfused.toMessage()],
        chips: step == ChatStep.done ? doneChips : pending.chips,
      );
    }

    var d = draft.applyIntent(intent);
    final acks = <RobotMessage>[];

    if (intent.scoreType != null) {
      final r = RobotBrain.wizardScoreTypeReaction(intent.scoreType!);
      if (r != null) acks.add(r);
    }
    if (intent.rank != null) {
      final r =
          RobotBrain.wizardRankReaction(intent.rank!, d.scoreType ?? '');
      if (r != null) acks.add(r);
    }
    if (d.score != null && (d.score! < 150 || d.score! > 560)) {
      d = d.withoutScore();
      acks.add(RobotScripts.chatScoreInvalid.toMessage());
    }
    final pieces = _ackPieces(intent);
    if (pieces.isNotEmpty) {
      acks.add(RobotMessage(
        RobotScripts.chatAck.id,
        RobotScripts.chatAck.text
            .replaceAll('{pieces}', pieces.join(', ')),
        RobotScripts.chatAck.mood,
      ));
    }
    if (intent.unresolved.isNotEmpty) {
      acks.add(RobotMessage(
        RobotScripts.chatPartial.id,
        RobotScripts.chatPartial.text
            .replaceAll('{rest}', intent.unresolved),
        RobotScripts.chatPartial.mood,
      ));
    }

    // Sonuçlardan sonra gelen düzeltmeler ("sadece İstanbul olsun")
    // aramayı otomatik tazeler.
    if (step == ChatStep.done && d.canSearch) {
      return ChatFlowResult(
        draft: d,
        step: ChatStep.done,
        messages: acks,
        chips: doneChips,
        effect: ChatEffect.search,
      );
    }

    final next = _askNext(d);
    return ChatFlowResult(
      draft: d,
      step: next.step,
      messages: [...acks, ...next.messages],
      chips: next.chips,
    );
  }

  /// Komut çipleri; sendText'li çipler [handleText]'e yönlendirilir.
  ChatFlowResult handleChip(
    ChatChip chip, {
    required ChatDraft draft,
    required ChatStep step,
  }) {
    final send = chip.sendText;
    if (send != null) return handleText(send, draft: draft, step: step);

    switch (chip.command!) {
      case ChatCommand.goResults:
        return ChatFlowResult(
          draft: draft,
          step: ChatStep.done,
          chips: doneChips,
          effect: ChatEffect.goResults,
        );
      case ChatCommand.calcScore:
        // Adım/taslak değişmez; ekran hesaplayıcıya götürür, dönüşte
        // sohbet kaldığı yerden sürer.
        final pending = _askNext(draft);
        return ChatFlowResult(
          draft: draft,
          step: pending.step,
          chips: pending.chips,
          effect: ChatEffect.goCalculator,
        );
      case ChatCommand.restart:
        final next = _askNext(const ChatDraft());
        return ChatFlowResult(
          draft: const ChatDraft(),
          step: next.step,
          messages: [RobotScripts.chatRestart.toMessage(), ...next.messages],
          chips: next.chips,
        );
      case ChatCommand.update:
        // Taze yürüyüş: dolu taslakla _askNext doğrudan onaya atlar ve
        // eski bilgi "güncellenmeden" kullanılmış olurdu. Çipler kümeden
        // eleman ÇIKARAMADIĞINDAN eski şehir/tür seçimleri de taşınmaz —
        // kullanıcı her adımı yeniden, birer dokunuşla yanıtlar.
        final next = _askNext(const ChatDraft());
        return ChatFlowResult(
          draft: const ChatDraft(),
          step: next.step,
          messages: [RobotScripts.chatUpdate.toMessage(), ...next.messages],
          chips: next.chips,
        );
      case ChatCommand.skip:
        var d = draft;
        if (step == ChatStep.interests) d = d.markInterestsDone();
        if (step == ChatStep.constraints) d = d.markConstraintsDone();
        final next = _askNext(d);
        return ChatFlowResult(
          draft: d,
          step: next.step,
          messages: next.messages,
          chips: next.chips,
        );
      case ChatCommand.focusDept:
        final d = draft.chooseFocus(chip.value ?? '');
        final next = _askNext(d);
        return ChatFlowResult(
          draft: d,
          step: next.step,
          messages: next.messages,
          chips: next.chips,
        );
      case ChatCommand.allDepts:
        final d = draft.chooseAllDepts();
        final next = _askNext(d);
        return ChatFlowResult(
          draft: d,
          step: next.step,
          messages: next.messages,
          chips: next.chips,
        );
      case ChatCommand.search:
        if (!draft.canSearch) {
          final next = _askNext(draft);
          return ChatFlowResult(
            draft: draft,
            step: next.step,
            messages: [
              RobotScripts.chatSearchMissing.toMessage(),
              ...next.messages,
            ],
            chips: next.chips,
          );
        }
        return ChatFlowResult(
          draft: draft,
          step: ChatStep.done,
          chips: doneChips,
          effect: ChatEffect.search,
        );
    }
  }

  // ── Sıradaki soru ──

  ChatFlowResult _askNext(ChatDraft d) {
    if (d.scoreType == null) {
      return ChatFlowResult(
        draft: d,
        step: ChatStep.scoreInfo,
        messages: [RobotScripts.chatAskScoreType.toMessage()],
        chips: scoreTypeChips,
      );
    }
    if (!d.hasScoreInfo) {
      return ChatFlowResult(
        draft: d,
        step: ChatStep.scoreInfo,
        messages: [RobotScripts.chatAskRank.toMessage()],
        chips: [
          ChatChip(
              _en
                  ? "I don't know my score, calculate it from my answers"
                  : 'Puanımı bilmiyorum, netlerden hesapla',
              command: ChatCommand.calcScore),
        ],
      );
    }
    if (!d.interestsDone) {
      return ChatFlowResult(
        draft: d,
        step: ChatStep.interests,
        messages: [RobotScripts.chatAskInterests.toMessage()],
        chips: interestChips,
      );
    }
    if (!d.constraintsDone) {
      return ChatFlowResult(
        draft: d,
        step: ChatStep.constraints,
        messages: [RobotScripts.chatAskConstraints.toMessage()],
        chips: constraintChips,
      );
    }
    if (d.needsFocus) {
      return ChatFlowResult(
        draft: d,
        step: ChatStep.confirm,
        messages: [RobotScripts.chatFocus.toMessage()],
        chips: [
          for (final dept in d.depts)
            ChatChip(dept.label,
                command: ChatCommand.focusDept, value: dept.query),
          ChatChip(_en ? 'All of them' : 'Hepsi',
              command: ChatCommand.allDepts),
        ],
      );
    }
    final text = RobotScripts.chatConfirm.text
        .replaceAll('{summary}', _summary(d));
    return ChatFlowResult(
      draft: d,
      step: ChatStep.confirm,
      messages: [
        RobotMessage(RobotScripts.chatConfirm.id, text,
            RobotScripts.chatConfirm.mood),
      ],
      chips: confirmChips,
    );
  }

  // ── Metin yardımcıları ──

  String _profileSummary(StudentScoreProfile p) {
    final parts = <String>[p.scoreType];
    if (p.hasRank) {
      parts.add('${formatRankTr(p.rank!)} ${RobotScripts.phraseRank}');
    } else if (p.hasScore) {
      parts.add('${_fmtScore(p.placementScore)} ${RobotScripts.phraseScore}');
    }
    return parts.join(' · ');
  }

  String _summary(ChatDraft d) {
    final parts = <String>[];
    if (d.scoreType != null) parts.add(d.scoreType!);
    if (d.rank != null) {
      parts.add('${formatRankTr(d.rank!)} ${RobotScripts.phraseRank}');
    } else if (d.score != null) {
      parts.add('${_fmtScore(d.score!)} ${RobotScripts.phraseScore}');
    }
    parts.addAll(d.cityIds.map((id) => cityNames[id] ?? id));
    parts.addAll(d.uniTypes.map(RobotScripts.filterLabel));
    parts.addAll(d.languages.map(RobotScripts.filterLabel));
    parts.addAll(d.programTypes.map(RobotScripts.filterLabel));
    if (d.onlyScholarship == true) parts.add(RobotScripts.phraseScholarship);
    if (d.depts.isNotEmpty) {
      parts.addAll(d.depts.map((e) => e.label));
    } else {
      parts.addAll(_interestLabels(d.interestKeys));
    }
    return parts.join(' · ');
  }

  /// Sıralama/puan dışındaki yeni yakalananların onay listesi.
  List<String> _ackPieces(WizardIntent i) {
    String out(String label) => '$label ${RobotScripts.phraseExcluded}';
    return [
      ...i.cityIds.map((id) => cityNames[id] ?? id),
      ...i.uniTypes.map(RobotScripts.filterLabel),
      ...i.languages.map(RobotScripts.filterLabel),
      ...i.programTypes.map(RobotScripts.filterLabel),
      if (i.onlyScholarship == true) RobotScripts.phraseScholarship,
      ...i.depts.map((d) => d.label),
      ..._interestLabels(i.interestKeys),
      // Olumsuzlamalar da onaylanır — kullanıcı çıkarıldığını görmeli.
      ...i.removeCityIds.map((id) => out(cityNames[id] ?? id)),
      ...i.removeUniTypes.map((t) => out(RobotScripts.filterLabel(t))),
      ...i.removeLanguages.map((l) => out(RobotScripts.filterLabel(l))),
      ...i.removeProgramTypes.map((p) => out(RobotScripts.filterLabel(p))),
      ...i.removeDepts.map((d) => out(d.label)),
      ..._interestLabels(i.removeInterestKeys).map(out),
    ];
  }

  List<String> _interestLabels(Set<String> keys) {
    return [
      for (final area in interestAreas)
        if (keys.contains(area.key))
          RobotScripts.interestLabel(area.key, area.label),
    ];
  }

  static String _fmtScore(double score) {
    final text = score % 1 == 0
        ? score.toStringAsFixed(0)
        : score.toStringAsFixed(1);
    return text.replaceAll('.', ',');
  }
}
