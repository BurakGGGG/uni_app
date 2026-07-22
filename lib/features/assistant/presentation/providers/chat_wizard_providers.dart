import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/city_helper.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/presentation/providers/subscription_providers.dart';
import '../../../preference_wizard/presentation/providers/preference_wizard_providers.dart';
import '../../../score_calculator/domain/models/match_result.dart';
import '../../../score_calculator/presentation/providers/score_calculator_providers.dart';
import '../../data/chat_nlu_service.dart';
import '../../domain/chat_flow.dart';
import '../../domain/chat_models.dart';
import '../../domain/chat_nlu_client.dart';
import '../../domain/robot_message.dart';
import '../../domain/robot_mood.dart';
import '../../domain/robot_scripts.dart';
import '../../domain/tercih_nlu.dart';
import '../../domain/wizard_intent.dart';
import 'assistant_providers.dart';

/// Faz B: kural ayrıştırıcının çözemediği cümleler için sunucu istemcisi.
final chatNluClientProvider = Provider<ChatNluClient>((ref) {
  return ChatNluService();
});

/// Sohbet ekranının tüm durumu — UI yalnız bunu çizer.
class ChatWizardState {
  final List<ChatTurn> turns;
  final List<ChatChip> chips;
  final ChatDraft draft;
  final ChatStep step;

  /// Arama sürerken girdi kilitli.
  final bool busy;

  const ChatWizardState({
    this.turns = const [],
    this.chips = const [],
    this.draft = const ChatDraft(),
    this.step = ChatStep.greeting,
    this.busy = false,
  });

  ChatWizardState copyWith({
    List<ChatTurn>? turns,
    List<ChatChip>? chips,
    ChatDraft? draft,
    ChatStep? step,
    bool? busy,
  }) {
    return ChatWizardState(
      turns: turns ?? this.turns,
      chips: chips ?? this.chips,
      draft: draft ?? this.draft,
      step: step ?? this.step,
      busy: busy ?? this.busy,
    );
  }
}

/// Sohbet orkestrasyonu: kullanıcı girdisini [ChatFlow]'a taşır, sonucu
/// tur listesine döker; aramada profil/prefs/filtreyi kaydedip motoru
/// çalıştırır. Karar mantığı yoktur — hepsi saf akışta (headless testli).
///
/// [sendText]/[tapChip] ekranın işlemesi gereken yönlendirme etkisini
/// döndürür (sonuç ekranı / hesaplayıcı); arama etkisi burada tüketilir.
class ChatWizardController extends StateNotifier<ChatWizardState> {
  ChatWizardController(this._ref) : super(const ChatWizardState()) {
    _flow = ChatFlow(
      nlu: TercihNlu(cityMap: CityHelper.cityMap, deptNames: const {}),
      cityNames: CityHelper.cityMap,
    );
    _begin();
    _upgradeNlu();
  }

  final Ref _ref;
  late ChatFlow _flow;

  void _begin() {
    _applySync(_flow.start(
      profile: _ref.read(studentScoreProfileProvider),
      prefs: _ref.read(wizardPrefsProvider),
    ));
  }

  /// Bölüm adları asset'ten gelince ayrıştırıcı zenginleşir; yüklenene
  /// dek meslek sözlüğü + iller yeter (selamlama zaten parse istemez).
  Future<void> _upgradeNlu() async {
    try {
      final depts = await _ref.read(allScoredDepartmentsProvider.future);
      if (!mounted) return;
      _flow = ChatFlow(
        nlu: TercihNlu(
          cityMap: CityHelper.cityMap,
          deptNames: {for (final d in depts) d.name},
        ),
        cityNames: CityHelper.cityMap,
      );
    } catch (_) {
      // Sözlüksüz de çalışır; sessiz geç.
    }
  }

  Future<ChatEffect> sendText(String text) async {
    final t = text.trim();
    if (t.isEmpty || state.busy) return ChatEffect.none;
    state = state.copyWith(turns: [...state.turns, UserChatTurn(t)]);

    var intent = _flow.nlu.parse(t);
    if (!intent.hasAny) {
      final remote = await _tryRemoteParse(t);
      if (remote != null && remote.hasAny) intent = remote;
    }
    return _apply(
        _flow.handleIntent(intent, draft: state.draft, step: state.step));
  }

  /// Faz B: kurallar çözemedi — Pro kullanıcıda cümle sunucuya gider,
  /// dönen semantik çıkarım yerel kapalı kümelere oturtulur. Rewarded
  /// geçici Pro KASITLI uygulanmaz (sunucu gerçek tier'ı denetler; aynı
  /// gerekçe: robotMessageSourceProvider). Her hata null → "anlayamadım".
  Future<WizardIntent?> _tryRemoteParse(String utterance) async {
    final tier = _ref.read(subscriptionTierProvider).valueOrNull;
    final isPro = tier != null && tier.satisfies(SubscriptionTier.pro);
    if (!isPro) return null;

    state = state.copyWith(busy: true);
    try {
      final remote =
          await _ref.read(chatNluClientProvider).parse(utterance);
      if (remote == null) return null;
      return _flow.nlu.groundRemote(remote);
    } catch (_) {
      return null;
    } finally {
      if (mounted) state = state.copyWith(busy: false);
    }
  }

  /// Kilitli serbest-yazı alanına dokunuş: Üni tatlı bir "yakında"
  /// balonu basar. Üst üste dokunuşta tekrar etmez (spam olmasın).
  void pokeLockedInput() {
    final last = state.turns.isEmpty ? null : state.turns.last;
    if (last is UniChatTurn &&
        last.message.id == RobotScripts.chatComingSoon.id) {
      return;
    }
    state = state.copyWith(turns: [
      ...state.turns,
      UniChatTurn(RobotScripts.chatComingSoon.toMessage()),
    ]);
  }

  Future<ChatEffect> tapChip(ChatChip chip) async {
    if (state.busy) return ChatEffect.none;
    state = state.copyWith(turns: [...state.turns, UserChatTurn(chip.label)]);
    return _apply(_flow.handleChip(chip, draft: state.draft, step: state.step));
  }

  void _applySync(ChatFlowResult r) {
    state = state.copyWith(
      draft: r.draft,
      step: r.step,
      turns: [...state.turns, for (final m in r.messages) UniChatTurn(m)],
      chips: r.chips,
    );
  }

  /// [ChatEffect.goBestPrograms] ile birlikte taşınan hedef bölüm adı —
  /// enum veri taşıyamadığı için son mesajın actionArg'ından okunur.
  String? bestProgramsDept;

  Future<ChatEffect> _apply(ChatFlowResult r) async {
    _applySync(r);
    if (r.effect == ChatEffect.goBestPrograms) {
      bestProgramsDept = r.messages.isEmpty ? null : r.messages.last.actionArg;
    }
    if (r.effect == ChatEffect.search) {
      await _runSearch();
      return ChatEffect.none;
    }
    return r.effect;
  }

  Future<void> _runSearch() async {
    state = state.copyWith(
      busy: true,
      chips: const [],
      turns: [
        ...state.turns,
        UniChatTurn(RobotMessage(
            'chat.searching', kResultsLoadingText, RobotMood.thinking)),
      ],
    );
    // autoDispose zinciri (motor + özet) arama boyunca canlı kalsın.
    final keepAlive = _ref.listen(preferenceMatchResultProvider, (_, _) {});
    try {
      final draft = state.draft;
      final now = DateTime.now();
      await _ref
          .read(studentScoreProfileProvider.notifier)
          .save(draft.buildProfile(now));
      await _ref.read(wizardPrefsProvider.notifier).save(draft.buildPrefs());
      final tier = _ref.read(subscriptionTierProvider).valueOrNull;
      final hasPlus = tier != null && tier.satisfies(SubscriptionTier.plus);
      _ref.read(wizardFilterProvider.notifier).state =
          draft.buildFilter(hasPlus: hasPlus);

      final result = await _ref.read(preferenceMatchResultProvider.future);
      // Sonuç ekranıyla aynı kaynak: Pro'da LLM özeti, herkeste kural.
      final summary = await _ref.read(robotResultsSummaryProvider.future);
      if (!mounted) return;
      final top = result == null
          ? const <UniversityMatch>[]
          : [...result.guaranteed, ...result.target, ...result.dream];
      state = state.copyWith(
        busy: false,
        turns: [
          ...state.turns,
          if (summary != null) UniChatTurn(summary.message),
          if (top.isNotEmpty) PreviewChatTurn(top.take(3).toList()),
        ],
        chips: ChatFlow.doneChips,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        busy: false,
        turns: [
          ...state.turns,
          UniChatTurn(RobotScripts.chatSearchError.toMessage()),
        ],
        chips: ChatFlow.confirmChips,
      );
    } finally {
      keepAlive.close();
    }
  }
}

final chatWizardControllerProvider = StateNotifierProvider.autoDispose<
    ChatWizardController, ChatWizardState>(
  (ref) => ChatWizardController(ref),
);
