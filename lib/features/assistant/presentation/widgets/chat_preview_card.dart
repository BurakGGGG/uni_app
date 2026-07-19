import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../preference_wizard/domain/match_reason.dart';
import '../../../score_calculator/domain/models/match_result.dart';

/// Sohbet içi kompakt öneri kartı — bölüm, üniversite, şans kategorisi ve
/// uygunluk. Detay/ekleme akışı "Tümünü gör" ile açılan mevcut sonuç
/// ekranındadır; kart bilinçli olarak dokunmasızdır.
class ChatPreviewCard extends StatelessWidget {
  final UniversityMatch match;
  const ChatPreviewCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (match.category) {
      MatchCategory.guaranteed => ('Yüksek şans', AppColors.success),
      MatchCategory.target => ('Ulaşılabilir', AppColors.warning),
      MatchCategory.dream => ('Zorlayıcı', AppColors.error),
    };
    final ranking = match.departmentRanking;
    final fit = match.fitScore;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            match.department.name,
            style:
                AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            match.university.name,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (fit != null)
                Text(
                  '%$fit uygun',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              const Spacer(),
              if (ranking != null && ranking > 0)
                Text(
                  'taban ${formatRankTr(ranking)}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiaryFor(context),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
