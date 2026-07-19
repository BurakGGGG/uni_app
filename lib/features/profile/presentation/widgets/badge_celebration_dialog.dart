import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../assistant/domain/robot_brain.dart';
import '../../../assistant/domain/robot_mood.dart';
import '../../../assistant/presentation/widgets/robot_avatar.dart';
import '../../domain/badge_catalog.dart';
import 'badge_medallion.dart';

/// Yeni rozet kazanıldığında gösterilen kutlama diyaloğu.
class BadgeCelebrationDialog extends StatelessWidget {
  final BadgeDefinition definition;

  const BadgeCelebrationDialog({super.key, required this.definition});

  static Future<void> show(BuildContext context, BadgeDefinition definition) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (ctx) => BadgeCelebrationDialog(definition: definition),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                        blurRadius: 42,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: BadgeMedallion(
                    definition: definition,
                    earned: true,
                    size: 128,
                  ),
                )
                .animate()
                .scale(
                  begin: const Offset(0.4, 0.4),
                  end: const Offset(1, 1),
                  duration: 700.ms,
                  curve: Curves.elasticOut,
                )
                .then(delay: 100.ms)
                .shimmer(duration: 900.ms, color: Colors.white54),
            const SizedBox(height: 20),
            Text(
                  loc.badgeCelebrationTitle,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                )
                .animate()
                .fadeIn(delay: 250.ms, duration: 400.ms)
                .slideY(begin: 0.3, end: 0),
            const SizedBox(height: 8),
            Text(
              definition.label(loc),
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
            const SizedBox(height: 6),
            Text(
              definition.description(loc),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const RobotAvatar(size: 30, mood: RobotMood.celebrating),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    RobotBrain.badgeCheer(definition.id).text,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/badges');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      loc.badgeCelebrationSecondary,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      loc.badgeCelebrationAction,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 550.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
