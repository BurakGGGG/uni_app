import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../recommendation/presentation/widgets/typewriter_text.dart';

class ComparisonAiSummaryCard extends StatelessWidget {
  final bool loading;
  final bool canUseAi;
  final bool isLimitReached;
  final String summaryText;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool regenerateAllowed;
  final VoidCallback? onRegenerate;

  const ComparisonAiSummaryCard({
    super.key,
    required this.loading,
    required this.canUseAi,
    required this.isLimitReached,
    required this.summaryText,
    this.errorMessage,
    this.onRetry,
    this.regenerateAllowed = false,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blocked = !canUseAi && !loading;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.aiSummaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.aiSummaryShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Analizi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              if (loading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (loading) ...[
            // 5.1 — Shimmer skeleton
            const ShimmerBox(
              height: 14,
              borderRadius: 7,
              baseColor: Color(0x33FFFFFF),
              highlightColor: Color(0x55FFFFFF),
            ),
            const SizedBox(height: 8),
            const ShimmerBox(
              height: 14,
              borderRadius: 7,
              baseColor: Color(0x33FFFFFF),
              highlightColor: Color(0x55FFFFFF),
            ),
            const SizedBox(height: 8),
            const ShimmerBox(
              width: 190,
              height: 14,
              borderRadius: 7,
              baseColor: Color(0x33FFFFFF),
              highlightColor: Color(0x55FFFFFF),
            ),
          ] else if (errorMessage != null) ...[
            // ─── Error State ────────────────────────────────
            Text(
              errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                label: const Text(
                  'Tekrar dene',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ] else if (blocked && isLimitReached) ...[
            // 5.4 — Yazım düzeltmesi
            Text(
              'Günlük AI özet hakkın doldu, yarın tekrar dene.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else if (blocked) ...[
            // 5.4 — Yazım düzeltmesi
            Text(
              'AI Analizi Pro pakette aktif. Pro\'ya geçerek detaylı özeti açabilirsin.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else ...[
            TypewriterText(
              summaryText,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
              perWord: const Duration(milliseconds: 60),
            ),
          ],
          if (!loading && !blocked && summaryText.isNotEmpty && errorMessage == null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Pro analizi aktif',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (regenerateAllowed && onRegenerate != null)
                  TextButton.icon(
                    onPressed: onRegenerate,
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                    label: const Text(
                      'Yeniden üret',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
