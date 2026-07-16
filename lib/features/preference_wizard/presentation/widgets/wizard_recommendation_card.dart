import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../score_calculator/domain/models/match_result.dart';
import '../../../university/domain/models/department_model.dart';
import '../../../university/presentation/widgets/score_badge.dart';
import 'add_to_list_sheet.dart';
import 'feasibility_chip.dart';

/// Tercih robotu öneri kartı — üni logosu/marka, bölüm, taban/sıralama/kontenjan
/// mini-stat, uygunluk rozeti ve "+ Listeye ekle".
class WizardRecommendationCard extends ConsumerWidget {
  final UniversityMatch match;
  const WizardRecommendationCard({super.key, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uni = match.university;
    final dept = match.department;
    final brand = uni.brandColor ?? AppColors.primary;
    final ranking = match.departmentRanking;
    final quota = dept.scoreData?.quota ?? dept.quota;
    final placed = dept.scoreData?.placedCount;
    final scoreType = dept.effectiveScoreType;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariantFor(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  uni.logoAssetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.account_balance_rounded,
                    color: brand,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dept.name,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      uni.name,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondaryFor(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (scoreType != null) ScoreBadge.scoreType(scoreType),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Uygunluk çipi — grup başlığı zaten kategoriyi verdiğinden gate yok.
              FeasibilityChip.forDepartment(dept, enforceGate: false, compact: true),
              const Spacer(),
              FeasibilityMiniStat(
                icon: Icons.trending_up_rounded,
                label: 'Taban',
                value: match.departmentBaseScore.toStringAsFixed(1),
                color: AppColors.primary,
              ),
              if (ranking != null && ranking > 0) ...[
                const SizedBox(width: 10),
                FeasibilityMiniStat(
                  icon: Icons.emoji_events_rounded,
                  label: 'Sıra',
                  value: _formatRank(ranking),
                  color: AppColors.warning,
                ),
              ],
              if (quota != null && quota > 0) ...[
                const SizedBox(width: 10),
                FeasibilityMiniStat(
                  icon: Icons.people_alt_rounded,
                  label: 'Kont.',
                  value: placed != null ? '$placed/$quota' : '$quota',
                  color: AppColors.info,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/department/${dept.id}'),
                  icon: const Icon(Icons.info_outline_rounded, size: 16),
                  label: const Text('Detay'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondaryFor(context),
                    side: BorderSide(color: AppColors.borderLightFor(context)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () =>
                      showAddToListSheet(context, ref, uni, dept),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Listeye ekle'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatRank(int rank) {
    if (rank >= 1000000) return '${(rank / 1000000).toStringAsFixed(1)}M';
    if (rank >= 1000) return '${(rank / 1000).toStringAsFixed(0)}B';
    return '$rank';
  }
}

class FeasibilityMiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const FeasibilityMiniStat({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              value,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryFor(context),
              ),
            ),
          ],
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiaryFor(context),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
