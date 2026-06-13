import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/admin_stats_model.dart';

/// Türev oranları gösteren bölüm.
class StatsRatioSection extends StatelessWidget {
  final AdminDerivedStats derived;

  const StatsRatioSection({super.key, required this.derived});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.percent_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Etkileşim Oranları',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondaryFor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columnCount = constraints.maxWidth >= 340 ? 2 : 1;
              final spacing = 10.0;
              final itemWidth =
                  (constraints.maxWidth - spacing * (columnCount - 1)) /
                  columnCount;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _RatioTile(
                    width: itemWidth,
                    label: 'Ort. beğeni/yorum',
                    value: derived.avgLikesPerReview.toStringAsFixed(1),
                    color: const Color(0xFFEF4444),
                  ),
                  _RatioTile(
                    width: itemWidth,
                    label: 'Karşılaştırma/kişi',
                    value: derived.comparisonsPerUser.toStringAsFixed(1),
                    color: const Color(0xFF6366F1),
                  ),
                  _RatioTile(
                    width: itemWidth,
                    label: 'Story gör./story',
                    value: derived.storyViewsPerStory.toStringAsFixed(0),
                    color: const Color(0xFF10B981),
                  ),
                  _RatioTile(
                    width: itemWidth,
                    label: 'Giriş oranı',
                    value:
                        '${derived.loginEngagementPercent.toStringAsFixed(0)}%',
                    color: const Color(0xFF3B82F6),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RatioTile extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final Color color;

  const _RatioTile({
    required this.width,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 10,
                color: AppColors.textSecondaryFor(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
