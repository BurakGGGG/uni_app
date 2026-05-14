import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/recommendation_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';

class RecommendationIntroScreen extends ConsumerWidget {
  const RecommendationIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Animated Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6584), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6584).withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                loc.recommendIntroTitle,
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                loc.recommendIntroSubtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              // Features chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _FeatureChip(icon: Icons.speed_rounded, label: loc.recommendIntroDuration),
                  _FeatureChip(
                    icon: Icons.emoji_events_rounded,
                    label: loc.recommendIntroMedals,
                  ),
                  _FeatureChip(icon: Icons.school_rounded, label: loc.recommendIntroSuggestions),
                ],
              ),
              const SizedBox(height: 24),
              // Beta uyarısı
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.science_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.recommendIntroBetaTitle,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            loc.recommendIntroBetaDesc,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              // Start button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Reset state
                    ref.read(currentQuestionIndexProvider.notifier).state = 0;
                    ref.read(recommendationAnswersProvider.notifier).state = {};
                    context.go('/recommend/chat');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6584), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rocket_launch_rounded, size: 22),
                          SizedBox(width: 10),
                          Text(
                            loc.recommendIntroStart,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                loc.recommendIntroDurationNote,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
