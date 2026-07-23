import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../router/app_router.dart';
import '../../../preference_wizard/domain/match_reason.dart' show formatRankTr;
import '../../domain/robot_scripts.dart';
import '../providers/uni_panel_providers.dart';

/// Gelişim özeti — panelin "nerede duruyorum" bloğu.
///
/// Denemelerim ekranı bunun detayını (grafik, ders paneli, defter) zaten
/// gösteriyor; burada üç sayı ve bir cümle var, gerisi için "detay" der.
class UniProgressBlock extends ConsumerWidget {
  const UniProgressBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(progressSummaryProvider);
    if (summary == null) return const SizedBox.shrink();

    final en = RobotScripts.isEn;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  en ? 'Your progress' : 'Gelişimin',
                  style: AppTextStyles.titleSmall
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.practiceExams),
                style:
                    TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: Text(en ? 'Detail' : 'Detay'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Stat(
                label: en ? 'Exams' : 'Deneme',
                value: '${summary.examCount}',
              ),
              _Stat(
                label: en ? 'Streak' : 'Seri',
                value: en
                    ? '${summary.streak} wk'
                    : '${summary.streak} hafta',
              ),
              if (summary.latestRank != null)
                _Stat(
                  label: en ? 'Latest rank' : 'Son sıra',
                  value: formatRankTr(summary.latestRank!),
                ),
            ],
          ),
          if (summary.rankGain != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  summary.rankGain! > 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 16,
                  color: summary.rankGain! > 0
                      ? AppColors.success
                      : AppColors.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    summary.rankGain! > 0
                        ? (en
                            ? 'Up ${formatRankTr(summary.rankGain!)} places '
                                'since your first exam'
                            : 'İlk denemenden bu yana '
                                '${formatRankTr(summary.rankGain!)} basamak '
                                'iyileşme')
                        : (en
                            ? 'Down ${formatRankTr(-summary.rankGain!)} places '
                                'since your first exam'
                            : 'İlk denemenden bu yana '
                                '${formatRankTr(-summary.rankGain!)} basamak '
                                'geriye'),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryFor(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (summary.strongest != null && summary.weakest != null) ...[
            const SizedBox(height: 12),
            Text(
              en
                  ? 'Strongest: ${RobotScripts.subjectLabel(summary.strongest!.subject.labelTr)}'
                      ' · Weakest: ${RobotScripts.subjectLabel(summary.weakest!.subject.labelTr)}'
                  : 'En güçlü: ${RobotScripts.subjectLabel(summary.strongest!.subject.labelTr)}'
                      ' · En zayıf: ${RobotScripts.subjectLabel(summary.weakest!.subject.labelTr)}',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textTertiaryFor(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.titleMedium
                .copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiaryFor(context),
            ),
          ),
        ],
      ),
    );
  }
}
