import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/badge_definitions.dart';

/// Rozet çipleri — kazanılanlar renkli, kazanılmayanlar gri "kilitli"
/// (motivasyon için hepsi görünür). Çipe dokununca açıklama tooltip'i.
class BadgesRow extends StatelessWidget {
  final Map<String, DateTime> earnedBadges;

  /// true ise sadece kazanılmış rozetler gösterilir (ör. başkasının profili).
  final bool earnedOnly;

  const BadgesRow({
    super.key,
    required this.earnedBadges,
    this.earnedOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final visible = earnedOnly
        ? badgeDefinitions
              .where((b) => earnedBadges.containsKey(b.id))
              .toList()
        : badgeDefinitions;

    if (visible.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: visible.map((badge) {
        final earned = earnedBadges.containsKey(badge.id);
        final color = earned ? badge.color : AppColors.textTertiaryFor(context);

        return Tooltip(
          message: badge.description(loc),
          triggerMode: TooltipTriggerMode.tap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: earned ? 0.12 : 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  earned ? badge.icon : Icons.lock_outline_rounded,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 5),
                Text(
                  badge.label(loc),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: earned
                        ? AppColors.textPrimaryFor(context)
                        : AppColors.textTertiaryFor(context),
                    fontWeight: earned ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
