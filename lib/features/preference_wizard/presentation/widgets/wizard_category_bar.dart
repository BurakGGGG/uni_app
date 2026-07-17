import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../score_calculator/domain/models/match_result.dart';
import '../../domain/preference_match_engine.dart';

/// Kategorilere hızlı odaklanma sekmeleri: Yüksek şans / Ulaşılabilir /
/// Zorlayıcı. Seçiliye tekrar dokununca tümü görünür.
class WizardCategoryBar extends StatelessWidget {
  final PreferenceMatchResult result;
  final MatchCategory? focus;
  final ValueChanged<MatchCategory?> onChanged;

  const WizardCategoryBar({
    super.key,
    required this.result,
    required this.focus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, MatchCategory category, Color color) {
      final selected = focus == category;
      final count = result.forCategory(category).length;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(selected ? null : category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? color : Colors.transparent,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: selected
                          ? color
                          : AppColors.textSecondaryFor(context),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$count',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: selected
                          ? color
                          : AppColors.textTertiaryFor(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantFor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Row(
        children: [
          chip('Yüksek şans', MatchCategory.guaranteed, AppColors.success),
          const SizedBox(width: 4),
          chip('Ulaşılabilir', MatchCategory.target, AppColors.warning),
          const SizedBox(width: 4),
          chip('Zorlayıcı', MatchCategory.dream, AppColors.error),
        ],
      ),
    );
  }
}
