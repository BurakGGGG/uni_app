import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../recommendation/presentation/widgets/typewriter_text.dart';

class ComparisonAiSummaryCard extends StatelessWidget {
  final bool loading;
  final bool canUseAi;
  final bool isLimitReached;
  final String summaryText;

  const ComparisonAiSummaryCard({
    super.key,
    required this.loading,
    required this.canUseAi,
    required this.isLimitReached,
    required this.summaryText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blocked = !canUseAi && !loading;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4A017), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
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
            _SkeletonLine(width: double.infinity),
            const SizedBox(height: 8),
            _SkeletonLine(width: double.infinity),
            const SizedBox(height: 8),
            const _SkeletonLine(width: 190),
          ] else if (blocked && isLimitReached) ...[
            Text(
              '5 AI ozetin doldu, yarin tekrar dene.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else if (blocked) ...[
            Text(
              'AI Analizi Pro pakette aktif. Pro’ya gecerek detayli ozeti acabilirsin.',
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
          if (!loading && !blocked) ...[
            const SizedBox(height: 10),
            Text(
              'Pro analizi aktif',
              style: AppTextStyles.labelSmall.copyWith(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;
  const _SkeletonLine({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }
}

