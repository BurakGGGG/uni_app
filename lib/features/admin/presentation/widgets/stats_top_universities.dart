import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/admin_stats_model.dart';

/// En popüler üniversiteler listesi.
class StatsTopUniversities extends StatelessWidget {
  final List<TopUniversityStat> universities;

  const StatsTopUniversities({super.key, required this.universities});

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
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF06B6D4),
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'En Popüler Üniversiteler',
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
          const SizedBox(height: 12),
          if (universities.isEmpty)
            Text(
              'Henüz görüntüleme verisi yok',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiaryFor(context),
              ),
            )
          else
            ...universities.asMap().entries.map((entry) {
              final index = entry.key;
              final uni = entry.value;
              final maxViews = universities.first.viewCount;
              final pct = maxViews > 0 ? uni.viewCount / maxViews : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF06B6D4,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF06B6D4),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            uni.name,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${uni.viewCount}',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textTertiaryFor(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: const Color(
                          0xFF06B6D4,
                        ).withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF06B6D4),
                        ),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
