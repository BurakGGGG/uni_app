import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Karşılaştırma öncesi boş durum gösterici.
/// Lottie dosyası yoksa fallbackIcon ile animasyonlu gösterim yapar.
class ComparisonEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData fallbackIcon;
  final VoidCallback? onTap;
  final String? ctaLabel;

  const ComparisonEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.fallbackIcon = Icons.compare_arrows_rounded,
    this.onTap,
    this.ctaLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animasyonlu ikon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.10),
                    AppColors.secondary.withValues(alpha: 0.10),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                fallbackIcon,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.45),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.08, 1.08),
                  duration: 1800.ms,
                  curve: Curves.easeInOut,
                )
                .shimmer(
                  duration: 2400.ms,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            // CTA Button (opsiyonel)
            if (ctaLabel != null && onTap != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(ctaLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
