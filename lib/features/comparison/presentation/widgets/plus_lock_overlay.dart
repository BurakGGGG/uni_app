import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Plus/Pro gerektiren alanlar için reusable lock overlay.
/// Not: Tier logic'i Kişi A provider'ına bağlanınca `isLocked` gerçek veriden beslenecek.
class PlusLockOverlay extends StatelessWidget {
  final bool isLocked;
  final String featureName;
  final Widget child;

  const PlusLockOverlay({
    super.key,
    required this.isLocked,
    required this.featureName,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return child;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Opacity(opacity: 0.35, child: child),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.70),
              padding: const EdgeInsets.all(18),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color:
                          (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.tierPlus.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: AppColors.tierPlus,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        featureName,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.textPrimaryFor(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        loc.plusLockSubtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? Colors.white70 : AppColors.textSecondaryFor(context),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => context.push('/compare/paywall'),
                          icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                          label: Text(loc.plusLockButton),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.tierPlus,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

