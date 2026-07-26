import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../score_calculator/presentation/widgets/score_type_card.dart';
import '../../domain/models/practice_exam.dart';
import '../providers/practice_exam_providers.dart';

/// Profildeki "Denemelerim" özet kartı.
///
/// Yalnız giriş yapmış kullanıcıya çizilir — kapıyı çağıran tutar
/// (`profile_screen.dart`), kart auth okumaz.
class PracticeExamSummaryCard extends ConsumerWidget {
  const PracticeExamSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exams = ref.watch(practiceExamsProvider);
    final latest = exams.isEmpty ? null : exams.first;

    return Material(
      color: AppColors.surfaceFor(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        side: BorderSide(color: AppColors.borderLightFor(context)),
      ),
      child: InkWell(
        onTap: () => context.push('/practice-exams'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.assignment_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Denemelerim',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const _StreakChip(),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      color: AppColors.textTertiaryFor(context), size: 20),
                ],
              ),
              const SizedBox(height: 12),
              if (latest == null)
                _empty(context)
              else
                _latest(context, exams, latest),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Text(
      'Netlerini, puanını ya da sıralamanı kaydet; gelişimini buradan takip et.',
      style: AppTextStyles.bodySmall
          .copyWith(color: AppColors.textSecondaryFor(context)),
    );
  }

  Widget _latest(
    BuildContext context,
    List<PracticeExam> exams,
    PracticeExam latest,
  ) {
    final best = latest.best;
    final previous = exams.length > 1 ? exams[1] : null;
    final rankDelta =
        previous != null ? latest.rankProgressOver(previous) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                latest.name,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _formatDate(latest.takenAt),
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textTertiaryFor(context)),
            ),
          ],
        ),
        if (best != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: scoreTypeColor(best.scoreType).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${best.scoreType} '
                  '${best.placementScore.toStringAsFixed(1).replaceAll('.', ',')}'
                  '${best.estimatedRank != null ? ' · ${latest.isRankMode ? '' : '~'}${formatRank(best.estimatedRank!)}. sıra' : ''}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: scoreTypeColor(best.scoreType),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (rankDelta != null && rankDelta != 0) ...[
                const SizedBox(width: 8),
                Icon(
                  rankDelta > 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 16,
                  color: rankDelta > 0 ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    formatRank(rankDelta.abs()),
                    style: AppTextStyles.labelSmall.copyWith(
                      color:
                          rankDelta > 0 ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  static String _formatDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }
}

class _StreakChip extends ConsumerWidget {
  const _StreakChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(examStreakProvider);
    if (streak <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              size: 14, color: AppColors.warning),
          const SizedBox(width: 3),
          Text(
            '$streak hafta',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
