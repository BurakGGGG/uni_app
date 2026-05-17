import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../monetization/domain/enums/subscription_tier.dart';
import '../../../../monetization/presentation/widgets/subscription_gate_widget.dart';

class ProChartGate extends StatelessWidget {
  final String title;
  final Widget child;

  const ProChartGate({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SubscriptionGateWidget(
      requiredTier: SubscriptionTier.pro,
      showBlurPreview: true,
      onLocked: () => context.push('/compare/paywall'),
      lockedFallback: _ProOverlay(title: title, child: child),
      child: child,
    );
  }
}

class _ProOverlay extends StatelessWidget {
  final String title;
  final Widget child;
  const _ProOverlay({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Opacity(opacity: 0.35, child: child),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.72),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.tierPro, AppColors.primary],
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.textPrimaryFor(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Bu grafik Pro paketinde.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? Colors.white70 : AppColors.textSecondaryFor(context),
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

