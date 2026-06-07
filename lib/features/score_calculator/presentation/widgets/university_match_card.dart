import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/match_result.dart';

class UniversityMatchCard extends StatelessWidget {
  final UniversityMatch match;

  const UniversityMatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bgColor;

    switch (match.category) {
      case MatchCategory.guaranteed:
        borderColor = const Color(0xFF10B981); // Yeşil
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.05);
        break;
      case MatchCategory.target:
        borderColor = const Color(0xFFF59E0B); // Sarı
        bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.05);
        break;
      case MatchCategory.dream:
        borderColor = const Color(0xFFEF4444); // Kırmızı
        bgColor = const Color(0xFFEF4444).withValues(alpha: 0.05);
        break;
    }

    final isDark = AppColors.isDark(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceFor(context) : bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.push('/department/${match.department.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Logo
                Container(
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLightFor(context)),
                  ),
                  child: Image.asset(
                    match.university.logoAssetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.school, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.university.name,
                        style: AppTextStyles.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 14, color: AppColors.textTertiaryFor(context)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              match.university.cityId, // TODO: city name
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryFor(context)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.account_balance_rounded, size: 14, color: AppColors.textTertiaryFor(context)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              match.university.type,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryFor(context)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Score info
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: borderColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Taban Puan: ${match.departmentBaseScore.toStringAsFixed(2)}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: borderColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (match.departmentRanking != null && match.departmentRanking! > 0) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Sıralama: ${match.departmentRanking}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textTertiaryFor(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Sıralama: Veri yok',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.warning.withValues(alpha: 0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiaryFor(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
