import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/recommendation_answer.dart';
import '../../domain/models/recommendation_question.dart';
import '../../domain/question_bank.dart';
import '../providers/recommendation_providers.dart';

class RecommendationChatScreen extends ConsumerStatefulWidget {
  const RecommendationChatScreen({super.key});

  @override
  ConsumerState<RecommendationChatScreen> createState() =>
      _RecommendationChatScreenState();
}

class _RecommendationChatScreenState
    extends ConsumerState<RecommendationChatScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _selectedIds = [];
  // Slider için ayrı state — varsayılan: orta nokta (3 = 40.000 sıralama)
  double _sliderValue = 3;
  bool _sliderTouched = false;
  // RangeSlider için ayrı state
  RangeValues _rangeValue = const RangeValues(2, 4);
  bool _rangeTouched = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = ref.watch(currentQuestionProvider);
    final progress = ref.watch(recommendationProgressProvider);
    final questionIdx = ref.watch(currentQuestionIndexProvider);

    if (question == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pushReplacement('/recommend/result');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (questionIdx > 0) {
          ref.read(currentQuestionIndexProvider.notifier).state--;
          setState(() => _selectedIds.clear());
          _animController.forward(from: 0);
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/recommend');
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Soru ${questionIdx + 1} / ${QuestionBank.questions.length}',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (questionIdx > 0) {
                ref.read(currentQuestionIndexProvider.notifier).state--;
                setState(() => _selectedIds.clear());
                _animController.forward(from: 0);
              } else {
                context.go('/recommend');
              }
            },
          ),
        ),
        body: Column(
          children: [
            // Progress bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(3),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        width: constraints.maxWidth * progress,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6584), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Question content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question bubble
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                            bottomLeft: Radius.circular(4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textPrimary.withValues(
                                alpha: 0.05,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF6584),
                                        Color(0xFF8B5CF6),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    question.question,
                                    style: AppTextStyles.titleLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (question.hint != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                question.hint!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      if (question.type == QuestionType.multiSelect) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '💡 En fazla ${question.maxSelections} tane seçebilirsin',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      if (question.type == QuestionType.rangeSlider &&
                          question.slider != null)
                        _RankingRangeSlider(
                          config: question.slider!,
                          value: _rangeValue,
                          touched: _rangeTouched,
                          onChanged: (v) {
                            setState(() {
                              _rangeValue = v;
                              _rangeTouched = true;
                            });
                          },
                        )
                      else if (question.type == QuestionType.slider &&
                          question.slider != null)
                        _RankingSlider(
                          config: question.slider!,
                          value: _sliderValue,
                          touched: _sliderTouched,
                          onChanged: (v) {
                            setState(() {
                              _sliderValue = v;
                              _sliderTouched = true;
                            });
                          },
                        )
                      else
                        // Options
                        ...question.options.map(
                          (opt) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _OptionTile(
                              option: opt,
                              isSelected: _selectedIds.contains(opt.id),
                              isMulti:
                                  question.type == QuestionType.multiSelect,
                              onTap: () {
                                setState(() {
                                  if (question.type ==
                                      QuestionType.singleSelect) {
                                    _selectedIds
                                      ..clear()
                                      ..add(opt.id);
                                  } else {
                                    if (_selectedIds.contains(opt.id)) {
                                      _selectedIds.remove(opt.id);
                                    } else if (_selectedIds.length <
                                        question.maxSelections) {
                                      _selectedIds.add(opt.id);
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom action
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _canProceed(question) ? _onNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.borderLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          questionIdx == QuestionBank.questions.length - 1
                              ? 'Tamamla'
                              : 'Devam Et',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          questionIdx == QuestionBank.questions.length - 1
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed(RecommendationQuestion question) {
    if (question.isOptional) return true;
    if (question.type == QuestionType.slider ||
        question.type == QuestionType.rangeSlider) {
      return true;
    }
    return _selectedIds.isNotEmpty;
  }

  void _onNext() {
    final question = ref.read(currentQuestionProvider)!;
    final answers = {...ref.read(recommendationAnswersProvider)};

    final selectedIds = <String>[];
    if (question.type == QuestionType.rangeSlider && question.slider != null) {
      // 'range_<minIdx>_<maxIdx>' formatı. Engine bunu min/max snap'e çevirir.
      final minIdx = _rangeValue.start.round();
      final maxIdx = _rangeValue.end.round();
      selectedIds.add('range_${minIdx}_$maxIdx');
    } else if (question.type == QuestionType.slider && question.slider != null) {
      final snapIndex = _sliderValue.round();
      selectedIds.add('snap_$snapIndex');
    } else {
      selectedIds.addAll(_selectedIds);
    }

    answers[question.id] = RecommendationAnswer(
      questionId: question.id,
      selectedOptionIds: selectedIds,
    );
    ref.read(recommendationAnswersProvider.notifier).state = answers;
    ref.read(currentQuestionIndexProvider.notifier).state++;
    setState(() {
      _selectedIds.clear();
      _sliderValue = 3;
      _sliderTouched = false;
      _rangeValue = const RangeValues(2, 4);
      _rangeTouched = false;
    });
    _animController.forward(from: 0);
  }
}

// ─── Ranking Range Slider ──────────────────────────────────────
class _RankingRangeSlider extends StatelessWidget {
  final SliderConfig config;
  final RangeValues value;
  final bool touched;
  final ValueChanged<RangeValues> onChanged;

  const _RankingRangeSlider({
    required this.config,
    required this.value,
    required this.touched,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final maxIndex = (config.snaps.length - 1).toDouble();
    final start = value.start.clamp(0.0, maxIndex);
    final end = value.end.clamp(start, maxIndex);
    final startSnap = config.snaps[start.round()];
    final endSnap = config.snaps[end.round()];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Tahmini sıralama aralığı',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                startSnap.label,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                endSnap.label,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.borderLight,
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 12,
              ),
              rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
              overlayColor: AppColors.primary.withValues(alpha: 0.12),
              trackHeight: 6,
              rangeTickMarkShape: const RoundRangeSliderTickMarkShape(
                tickMarkRadius: 3,
              ),
              activeTickMarkColor: Colors.white,
              inactiveTickMarkColor:
                  AppColors.textTertiary.withValues(alpha: 0.4),
              thumbColor: AppColors.primary,
            ),
            child: RangeSlider(
              values: RangeValues(start, end),
              min: 0,
              max: maxIndex,
              divisions: config.snaps.length - 1,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                config.snaps.first.label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                config.snaps.last.label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  touched
                      ? 'İki taraftan da ayarlayabilirsin'
                      : 'İki taraftaki tutamacı kaydırarak aralığı belirle',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ranking Slider ────────────────────────────────────────────
class _RankingSlider extends StatelessWidget {
  final SliderConfig config;
  final double value;
  final bool touched;
  final ValueChanged<double> onChanged;

  const _RankingSlider({
    required this.config,
    required this.value,
    required this.touched,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final maxIndex = (config.snaps.length - 1).toDouble();
    final clamped = value.clamp(0, maxIndex).toDouble();
    final currentSnap = config.snaps[clamped.round()];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Tahmini sıralama',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currentSnap.label,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.borderLight,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.12),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
              tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 3),
              activeTickMarkColor: Colors.white,
              inactiveTickMarkColor: AppColors.textTertiary.withValues(alpha: 0.4),
            ),
            child: Slider(
              value: clamped,
              min: 0,
              max: maxIndex,
              divisions: config.snaps.length - 1,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                config.snaps.first.label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                config.snaps.last.label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          if (!touched) ...[
            const SizedBox(height: 12),
            Text(
              'Sürükleyerek sıralamanı seç',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final QuestionOption option;
  final bool isSelected;
  final bool isMulti;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.isSelected,
    required this.isMulti,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.borderLight,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (option.icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      option.icon,
                      size: 20,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        option.label,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      if (option.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          option.subtitle!,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: isMulti
                      ? BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textTertiary,
                            width: 2,
                          ),
                        )
                      : BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textTertiary,
                            width: 2,
                          ),
                        ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
