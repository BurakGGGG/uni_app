import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/brand_loader.dart';
import '../providers/score_calculator_providers.dart';
import '../widgets/eligible_programs_preview.dart';
import '../widgets/score_type_card.dart';
import '../widgets/university_match_card.dart';
import '../widgets/year_comparison_table.dart';
import '../../../admin/data/analytics_service.dart';
import '../../../admin/domain/models/analytics_event.dart';
import '../../../assistant/domain/robot_mood.dart';
import '../../../assistant/domain/robot_scripts.dart';
import '../../../assistant/presentation/widgets/robot_avatar.dart';
import '../../../preference_wizard/domain/models/student_score_profile.dart';
import '../../../preference_wizard/presentation/providers/preference_wizard_providers.dart';
import '../../domain/models/multi_score_result.dart';

/// Sonuç ekranı v2: tüm puan türleri + sıra/dilim kartları, hedef bölüm
/// kararı, yıl karşılaştırması ve girebileceğin bölümler önizlemesi.
class ScoreResultScreen extends ConsumerWidget {
  const ScoreResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outcomeAsync = ref.watch(multiScoreOutcomeProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundFor(context),
        body: outcomeAsync.when(
          loading: () => const BrandLoader(),
          error: (e, st) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Hesaplama başarısız', style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: const Text('Geri Dön'),
                ),
              ],
            ),
          ),
          data: (outcome) {
            if (outcome == null || outcome.isEmpty) {
              return Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: const Text('Geri Dön ve Netleri Doldur'),
                ),
              );
            }

            // Analytics: puan hesaplandı (tek seferlik)
            AnalyticsService.instance
                .trackEvent(AnalyticsEvent.scoreCalculated);

            return _ResultBody(outcome: outcome);
          },
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sonuçlardan Çık'),
        content: const Text(
            'Netleri düzenleyip yeniden hesaplayabilir veya ana sayfaya '
            'dönebilirsin.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/');
            },
            child: const Text('Ana Sayfa'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.maybePop(context);
            },
            child: const Text('Netleri Düzenle'),
          ),
        ],
      ),
    );
  }
}

class _ResultBody extends ConsumerWidget {
  final MultiScoreOutcome outcome;
  const _ResultBody({required this.outcome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final best = outcome.best;
    final selectedType = ref.watch(resultSelectedTypeProvider) ??
        best?.score.scoreType ??
        outcome.outcomes.first.score.scoreType;
    final verdictAsync = ref.watch(targetDepartmentVerdictProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Hero ───────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 16, 24, 28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white),
                      onPressed: () => Navigator.maybePop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Sonuçların',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${outcome.year} YKS SONUÇLARIN',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (best != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    best.score.placementScore.toStringAsFixed(3),
                    style: AppTextStyles.displayLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 48,
                    ),
                  ).animate().fadeIn(delay: 250.ms, duration: 500.ms).scale(
                        begin: const Offset(0.85, 0.85),
                        end: const Offset(1, 1),
                        curve: Curves.easeOutBack,
                      ),
                  const SizedBox(height: 6),
                  Text(
                    'En güçlü türün: ${best.score.scoreType}'
                    '${best.estimatedRank != null ? ' · ~${formatRank(best.estimatedRank!)}. sıra' : ''}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: -0.12, end: 0, curve: Curves.easeOut),

          const SizedBox(height: 24),

          // ─── Puan kartları ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(context, Icons.calculate_rounded, 'Puanların'),
                const SizedBox(height: 12),
                for (final o in outcome.outcomes)
                  ScoreTypeCard(
                    outcome: o,
                    isBest: outcome.outcomes.length > 1 && o == best,
                  ),
              ],
            ),
          ).animate().fadeIn(delay: 120.ms, duration: 400.ms),

          // ─── Hedef bölüm kararı ─────────────────────────────
          verdictAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (verdict) {
              if (verdict == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(context, Icons.flag_rounded,
                        'Hedefin: ${verdict.departmentName}'),
                    const SizedBox(height: 8),
                    Text(
                      '${verdict.total} programdan 🟢${verdict.guaranteed} · '
                      '🟡${verdict.target} · 🔴${verdict.dream}. '
                      'Sana en uygun görünen:',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondaryFor(context)),
                    ),
                    const SizedBox(height: 12),
                    UniversityMatchCard(match: verdict.best),
                  ],
                ),
              );
            },
          ),

          // ─── Tür seçici (karşılaştırma + bölümler) ──────────
          if (outcome.outcomes.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final o in outcome.outcomes)
                    ChoiceChip(
                      label: Text(
                        o.score.scoreType,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: selectedType == o.score.scoreType
                              ? Colors.white
                              : scoreTypeColor(o.score.scoreType),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      selected: selectedType == o.score.scoreType,
                      selectedColor: scoreTypeColor(o.score.scoreType),
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onSelected: (_) => ref
                          .read(resultSelectedTypeProvider.notifier)
                          .state = o.score.scoreType,
                    ),
                ],
              ),
            ),

          // ─── Yıl karşılaştırması ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(context, Icons.timeline_rounded,
                    'Yıllara Göre ($selectedType)'),
                const SizedBox(height: 8),
                Text(
                  'Aynı netlerle geçmiş yılların katsayı ve dağılımları.',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryFor(context)),
                ),
                const SizedBox(height: 12),
                YearComparisonTable(scoreType: selectedType),
              ],
            ),
          ).animate().fadeIn(delay: 180.ms, duration: 400.ms),

          // ─── Girebileceğin bölümler ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(context, Icons.school_rounded,
                    'Girebileceğin Bölümler ($selectedType)'),
                const SizedBox(height: 12),
                EligibleProgramsPreview(
                  scoreType: selectedType,
                  onSeeAll: () =>
                      _transferToWizard(context, ref, preferType: selectedType),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 240.ms, duration: 400.ms),

          // ─── Tercih robotu CTA ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            child: _WizardTransferCta(
              outcome: outcome,
              onTransfer: () => _transferToWizard(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.headlineSmall
                .copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// Tercih robotuna aktarım: tek tür → doğrudan; birden çok tür → seçim
  /// sheet'i (en güçlü tür önseçili). Tahmini sıra profile YAZILMAZ —
  /// robot kendi tahminini yapar (belirsizlik düzeltmesi korunur).
  Future<void> _transferToWizard(
    BuildContext context,
    WidgetRef ref, {
    String? preferType,
  }) async {
    String? chosen;
    if (outcome.outcomes.length == 1) {
      chosen = outcome.outcomes.first.score.scoreType;
    } else if (preferType != null) {
      chosen = preferType;
    } else {
      chosen = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: AppColors.surfaceFor(context),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => _TypePickerSheet(outcome: outcome),
      );
      if (chosen == null) return;
    }

    final typeOutcome = outcome.byType(chosen);
    if (typeOutcome == null) return;

    await ref.read(studentScoreProfileProvider.notifier).save(
          StudentScoreProfile(
            scoreType: chosen,
            placementScore: typeOutcome.score.placementScore,
            // Robot giriş ekranıyla aynı: profil yılı = bu yıl.
            year: DateTime.now().year,
            updatedAt: DateTime.now(),
          ),
        );
    if (context.mounted) {
      context.push('/preference-wizard/results');
    }
  }
}

/// Tür seçim sheet'i: tür + puan + tahmini sıra listesi, en güçlü önseçili.
class _TypePickerSheet extends StatelessWidget {
  final MultiScoreOutcome outcome;
  const _TypePickerSheet({required this.outcome});

  @override
  Widget build(BuildContext context) {
    final best = outcome.best;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hangi puan türünle devam edelim?',
              style: AppTextStyles.titleMedium
                  .copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Tercih robotu bu türe göre program önerir.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondaryFor(context)),
            ),
            const SizedBox(height: 16),
            for (final o in outcome.outcomes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => Navigator.pop(context, o.score.scoreType),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: o == best
                          ? scoreTypeColor(o.score.scoreType)
                              .withValues(alpha: 0.08)
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: o == best
                            ? scoreTypeColor(o.score.scoreType)
                                .withValues(alpha: 0.5)
                            : AppColors.borderLightFor(context),
                        width: o == best ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: scoreTypeColor(o.score.scoreType)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            o.score.scoreType,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: scoreTypeColor(o.score.scoreType),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            o.score.placementScore.toStringAsFixed(2) +
                                (o.estimatedRank != null
                                    ? ' · ~${formatRank(o.estimatedRank!)}. sıra'
                                    : ''),
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (o == best)
                          const Icon(Icons.star_rounded,
                              color: AppColors.gold, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WizardTransferCta extends StatelessWidget {
  final MultiScoreOutcome outcome;
  final VoidCallback onTransfer;

  const _WizardTransferCta({required this.outcome, required this.onTransfer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const RobotAvatar(
                size: 28,
                animated: false,
                mood: RobotMood.happy,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bu puanla tercih listeni kuralım',
                  style: AppTextStyles.titleSmall
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Puanını tercih robotuna aktarayım; programları şans durumuna '
            'göre gruplar, listeni kurmana yardım ederim.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryFor(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: onTransfer,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(RobotScripts.transferLabel),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
