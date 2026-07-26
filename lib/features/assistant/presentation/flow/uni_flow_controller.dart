import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../score_calculator/domain/models/score_input.dart';
import '../../../score_calculator/presentation/providers/score_calculator_providers.dart';
import '../../domain/uni_flow.dart';

/// Akışın anlık durumu — hangi adımdayız, yol kaç adım.
class UniFlowState {
  final List<UniFlowStep> steps;
  final int index;
  final UniFlowMode mode;

  /// Son hareket ileri miydi? Geçiş animasyonunun yönünü belirler — geri
  /// giderken ekranın soldan gelmesi "geri döndüm" hissini veriyor.
  final bool forward;

  const UniFlowState({
    required this.steps,
    required this.index,
    required this.mode,
    this.forward = true,
  });

  UniFlowStep get current => steps[index];
  bool get isFirst => index == 0;
  bool get isLast => index == steps.length - 1;

  /// 0–1 arası; ilerleme çubuğu.
  double get progress => (index + 1) / steps.length;

  UniFlowState copyWith({
    List<UniFlowStep>? steps,
    int? index,
    bool? forward,
  }) {
    return UniFlowState(
      steps: steps ?? this.steps,
      index: index ?? this.index,
      mode: mode,
      forward: forward ?? this.forward,
    );
  }
}

/// Adımlar arasında gezinme.
///
/// Veri TUTMAZ — her adım kendi cevabını zaten var olan kalıcı katmana yazar
/// ([scoreInputProvider], `studentScoreProfileProvider`, `wizardPrefsProvider`,
/// tercih listesi). Burada yalnızca "sırada ne var" bilgisi yaşar; bu yüzden
/// Riverpod'a ihtiyacı olmadan test edilebilir.
class UniFlowController extends StateNotifier<UniFlowState> {
  UniFlowController({
    required NetEntryMode entryMode,
    UniFlowMode mode = UniFlowMode.setup,
    UniFlowStep? only,
  }) : super(
          UniFlowState(
            steps: uniFlowSteps(entryMode: entryMode, mode: mode, only: only),
            index: 0,
            mode: mode,
          ),
        );

  /// Giriş yolu değişince kalan adımlar yeniden türetilir: sıralamayla gelen
  /// üç net ekranını görmemeli. Yalnız ilk adımda anlamlı — yol seçimi orada
  /// yapılır, sonrasında değişirse ilerleme indeksi anlamını yitirirdi.
  void syncEntryMode(NetEntryMode entryMode) {
    if (state.mode == UniFlowMode.editOne || !state.isFirst) return;
    final next = uniFlowSteps(entryMode: entryMode, mode: state.mode);
    if (_sameSteps(next, state.steps)) return;
    state = state.copyWith(steps: next);
  }

  void next() {
    if (state.isLast) return;
    state = state.copyWith(index: state.index + 1, forward: true);
  }

  void back() {
    if (state.isFirst) return;
    state = state.copyWith(index: state.index - 1, forward: false);
  }

  /// Doğrudan bir adıma atlar; adım bu yolda yoksa hiçbir şey yapmaz.
  void jumpTo(UniFlowStep step) {
    final i = state.steps.indexOf(step);
    if (i < 0) return;
    state = state.copyWith(index: i, forward: i >= state.index);
  }

  static bool _sameSteps(List<UniFlowStep> a, List<UniFlowStep> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Akışın açılış ayarı. Kayıt (record) olduğu için değer eşitliği taşır —
/// aynı ayarla iki kez istenirse aynı controller döner.
typedef UniFlowArgs = ({UniFlowMode mode, UniFlowStep? only});

const UniFlowArgs kUniFlowSetup = (mode: UniFlowMode.setup, only: null);

final uniFlowControllerProvider = StateNotifierProvider.autoDispose
    .family<UniFlowController, UniFlowState, UniFlowArgs>((ref, args) {
  final controller = UniFlowController(
    entryMode: ref.read(scoreInputProvider).entryMode,
    mode: args.mode,
    only: args.only,
  );
  ref.listen<ScoreInput>(scoreInputProvider, (prev, next) {
    if (prev?.entryMode != next.entryMode) controller.syncEntryMode(next.entryMode);
  });
  return controller;
});
