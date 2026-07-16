import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/badge_catalog.dart';
import 'badge_medallion.dart';

/// Rozet detayı — büyük madalyon, açıklama, ilerleme çubuğu, kazanım tarihi.
class BadgeDetailSheet extends StatelessWidget {
  final BadgeProgress progress;

  const BadgeDetailSheet({super.key, required this.progress});

  static Future<void> show(BuildContext context, BadgeProgress progress) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BadgeDetailSheet(progress: progress),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final definition = progress.definition;
    final earned = progress.earned;
    final target = definition.target;

    return SafeArea(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BadgeMedallion(definition: definition, earned: earned, size: 112),
            const SizedBox(height: 16),
            Text(
              definition.label(loc),
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              definition.description(loc),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (earned)
              _EarnedInfo(earnedAt: progress.earnedAt!)
            else if (target != null)
              _ProgressInfo(
                current: progress.current,
                target: target,
                fraction: progress.fraction,
              )
            else
              _LockedChip(label: loc.badgeLockedLabel),
          ],
        ),
      ),
    );
  }
}

class _EarnedInfo extends StatelessWidget {
  final DateTime earnedAt;

  const _EarnedInfo({required this.earnedAt});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMMMMd(locale).format(earnedAt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 6),
          Text(
            loc.badgeEarnedOn(date),
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressInfo extends StatelessWidget {
  final int current;
  final int target;
  final double fraction;

  const _ProgressInfo({
    required this.current,
    required this.target,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          loc.badgeProgressLabel(current.clamp(0, target), target),
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondaryFor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LockedChip extends StatelessWidget {
  final String label;

  const _LockedChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.textTertiaryFor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
