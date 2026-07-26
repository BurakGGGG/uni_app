import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/robot_scripts.dart';
import '../../domain/uni_flow.dart';
import '../widgets/robot_avatar.dart';
import 'steps/flow_list_steps.dart';
import 'steps/flow_profile_steps.dart';
import 'steps/flow_score_steps.dart';
import 'uni_flow_controller.dart';
import 'uni_flow_step_spec.dart';

/// "Tercih Yolun" — onboarding gibi ekran ekran ilerleyen kurulum akışı.
///
/// Kabuk her adımda AYNI iskeleti çizer: üstte ilerleme, ortada tek soru,
/// altta Üni + tek buton. Adımlar yalnız kendi gövdesini verir
/// ([UniFlowStepSpec]); başlığı, butonu, geçiş animasyonunu buraya bırakır.
/// Akış hissi bu tekrardan doğuyor — her ekran kendi düzenini kursaydı on
/// ayrı sayfa olurdu.
class UniFlowScreen extends ConsumerStatefulWidget {
  /// Tek adım düzenleme için: özet ekranından "şehirlerimi değiştir".
  final UniFlowStep? only;

  /// Akış bitince/kapatılınca çağrılır. Verilmezse geri yığınından çıkılır.
  ///
  /// `/uni` kapısı bunu kullanır: akış oranın İÇİNDE yaşadığı için gidilecek
  /// bir yer yok, yalnız özete dönülür.
  final VoidCallback? onFinished;

  const UniFlowScreen({super.key, this.only, this.onFinished});

  @override
  ConsumerState<UniFlowScreen> createState() => _UniFlowScreenState();
}

class _UniFlowScreenState extends ConsumerState<UniFlowScreen> {
  late final UniFlowArgs _args;
  bool _advancing = false;

  @override
  void initState() {
    super.initState();
    _args = widget.only == null
        ? kUniFlowSetup
        : (mode: UniFlowMode.editOne, only: widget.only);
  }

  UniFlowController get _controller =>
      ref.read(uniFlowControllerProvider(_args).notifier);

  /// Kaydetme başarısızsa ilerlenmez — "devam ettim ama kaydolmadı" sessiz
  /// veri kaybı olurdu.
  Future<void> _advance(UniFlowStepSpec spec, UniFlowState state) async {
    if (_advancing) return;
    setState(() => _advancing = true);
    try {
      await spec.onAdvance?.call();
      if (!mounted) return;
      if (state.isLast || state.mode == UniFlowMode.editOne) {
        _finish();
        return;
      }
      _controller.next();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  void _skip(UniFlowState state) {
    if (state.isLast || state.mode == UniFlowMode.editOne) {
      _finish();
      return;
    }
    _controller.next();
  }

  void _finish() {
    final onFinished = widget.onFinished;
    if (onFinished != null) {
      onFinished();
      return;
    }
    finishUniFlow(context);
  }

  UniFlowStepSpec _specFor(UniFlowStep step) {
    return switch (step) {
      UniFlowStep.start => startStepSpec(context, ref),
      UniFlowStep.tytNets => tytStepSpec(context, ref),
      UniFlowStep.aytNets => aytStepSpec(context, ref),
      UniFlowStep.obp => obpStepSpec(context, ref),
      UniFlowStep.rank => rankStepSpec(context, ref),
      UniFlowStep.score => scoreStepSpec(context, ref),
      UniFlowStep.reveal => revealStepSpec(context, ref),
      UniFlowStep.targetDept => targetDeptStepSpec(context, ref),
      UniFlowStep.interests => interestsStepSpec(context, ref),
      UniFlowStep.cities => citiesStepSpec(context, ref),
      UniFlowStep.buildList => buildListStepSpec(context, ref),
      UniFlowStep.done => doneStepSpec(context, ref),
    };
  }

  @override
  Widget build(BuildContext context) {
    final en = RobotScripts.isEn;
    final state = ref.watch(uniFlowControllerProvider(_args));
    final spec = _specFor(state.current);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: SafeArea(
        child: Column(
          children: [
            _FlowHeader(
              state: state,
              onBack: state.isFirst
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      _controller.back();
                    },
              onClose: _finish,
            ),
            // Sayfa geçişi PageView'la DEĞİL: kaydırılamayan bir PageView'ın
            // fiziksel sayfası akış durumuyla ikinci bir doğruluk kaynağı
            // oluyordu (adım ilerliyor, sayfa yerinde kalıyordu). Ekranda
            // her zaman tek bir adım var; onu değiştirmek yeterli.
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                // Varsayılan yerleşim çocukları ORTALIYOR: kısa adımlarda
                // soru ekranın ortasına düşüp uzun adımlarla aynı ritmi
                // tutmuyordu — üste hizala.
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                // Yön duyarlı: ileri giderken sağdan, geri dönerken soldan.
                // Hafif küçülme fade'e derinlik katıyor — düz solma "sayfa
                // yenilendi" gibi duruyordu.
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(state.forward ? 0.18 : -0.18, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.97, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  ),
                ),
                // Tam yükseklik: `AnimatedSwitcher` çocuklarına gevşek
                // kısıt verir, kaydırma görünümü içeriğine göre büzülürdü.
                child: SizedBox.expand(
                  key: ValueKey(state.current),
                  child: _StepPage(spec: spec),
                ),
              ),
            ),
            _FlowFooter(
              spec: spec,
              state: state,
              busy: _advancing,
              onAdvance: () {
                FocusScope.of(context).unfocus();
                _advance(spec, state);
              },
              onSkip: state.current.skippable ? () => _skip(state) : null,
              defaultLabel: en ? 'Continue' : 'Devam',
              skipLabel: en ? 'Skip' : 'Geç',
            ),
          ],
        ),
      ),
    );
  }
}

/// Üstte: geri, ilerleme çubuğu, çıkış.
class _FlowHeader extends StatelessWidget {
  final UniFlowState state;
  final VoidCallback? onBack;
  final VoidCallback onClose;

  const _FlowHeader({
    required this.state,
    required this.onBack,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final single = state.steps.length == 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: RobotScripts.isEn ? 'Back' : 'Geri',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: onBack,
          ),
          Expanded(
            child: single
                ? const SizedBox.shrink()
                : TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: state.progress),
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOut,
                    builder: (_, value, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceVariantFor(context),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
          ),
          IconButton(
            tooltip: RobotScripts.isEn ? 'Close' : 'Kapat',
            icon: const Icon(Icons.close_rounded),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// Tek adımın gövdesi: soru + açıklama + içerik. Her açılışta aynı giriş
/// animasyonu — ekranlar arasında ritim kurar.
class _StepPage extends StatelessWidget {
  final UniFlowStepSpec spec;
  const _StepPage({required this.spec});

  /// Gövde parçaları arasındaki gecikme. Uzun ekranlarda (AYT'nin on dört
  /// satırı) kademe [_kStaggerCap]'te durur — son satırın saniyelerce
  /// beklemesi akış değil gecikme hissi verirdi.
  static const Duration _kStagger = Duration(milliseconds: 55);
  static const int _kStaggerCap = 6;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        // Gövde parçaları tam genişlik ister (kartlar, çip sarmalları);
        // başlık zaten sola yaslı akar.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            spec.title,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          )
              .animate()
              .fadeIn(duration: 280.ms)
              .slideY(begin: 0.16, end: 0, curve: Curves.easeOutCubic),
          if (spec.subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              spec.subtitle!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryFor(context),
                height: 1.4,
              ),
            )
                .animate()
                .fadeIn(delay: 70.ms, duration: 280.ms)
                .slideY(begin: 0.14, end: 0, curve: Curves.easeOutCubic),
          ],
          const SizedBox(height: 20),
          for (var i = 0; i < spec.body.length; i++)
            spec.body[i]
                .animate(
                  delay: _kStagger *
                          (i > _kStaggerCap ? _kStaggerCap : i) +
                      120.ms,
                )
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

/// Altta: Üni + tek eylem. Buton yeri on ekran boyunca hiç oynamaz.
class _FlowFooter extends StatelessWidget {
  final UniFlowStepSpec spec;
  final UniFlowState state;
  final bool busy;
  final VoidCallback onAdvance;
  final VoidCallback? onSkip;
  final String defaultLabel;
  final String skipLabel;

  const _FlowFooter({
    required this.spec,
    required this.state,
    required this.busy,
    required this.onAdvance,
    required this.onSkip,
    required this.defaultLabel,
    required this.skipLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundFor(context),
        border: Border(
          top: BorderSide(color: AppColors.borderLightFor(context)),
        ),
      ),
      child: Row(
        children: [
          // Ekranın tek animasyonlu avatarı; adıma göre yüz değiştirir.
          RobotAvatar(size: 40, mood: spec.mood),
          const SizedBox(width: 12),
          if (onSkip != null) ...[
            TextButton(
              onPressed: busy ? null : onSkip,
              child: Text(skipLabel),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: spec.canAdvance && !busy ? onAdvance : null,
                // Buton yazısı adım içinde de değişiyor ("24 tercihi ekle" →
                // "19 tercihi ekle"); sıçrayarak değil eriyerek değişsin.
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          spec.ctaLabel ?? defaultLabel,
                          key: ValueKey(spec.ctaLabel ?? defaultLabel),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
