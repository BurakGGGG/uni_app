import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/brand_loader.dart';
import '../providers/score_calculator_providers.dart';
import '../widgets/university_match_card.dart';
import '../../../admin/data/analytics_service.dart';
import '../../../admin/domain/models/analytics_event.dart';
import '../../../assistant/domain/robot_mood.dart';
import '../../../assistant/presentation/widgets/robot_avatar.dart';
import '../../../preference_wizard/domain/models/student_score_profile.dart';
import '../../../preference_wizard/presentation/providers/preference_wizard_providers.dart';
import '../../domain/models/match_result.dart';


class ScoreResultScreen extends ConsumerWidget {
  const ScoreResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(calculationResultProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundFor(context),
      body: resultAsync.when(
        loading: () => const BrandLoader(),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Hesaplama başarısız', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _showExitDialog(context),
                child: const Text('Ana Sayfaya Dön'),
              ),
            ],
          ),
        ),
        data: (result) {
          if (result == null) {
            return Center(
              child: ElevatedButton(
                onPressed: () => _showExitDialog(context),
                child: const Text('Geri Dön ve Bilgileri Doldur'),
              ),
            );
          }

          // Analytics: puan hesaplandı (tek seferlik)
          AnalyticsService.instance.trackEvent(AnalyticsEvent.scoreCalculated);

          return SingleChildScrollView(
            child: Column(
              children: [
                // Score Hero (Seamless Header)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                            onPressed: () => _showExitDialog(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Sonuçlar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24), // To balance the back button
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${result.scoreType} YERLEŞTİRME PUANI',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        result.calculatedScore.toStringAsFixed(3),
                        style: AppTextStyles.displayLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 52,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 250.ms, duration: 500.ms)
                          .scale(
                            begin: const Offset(0.85, 0.85),
                            end: const Offset(1, 1),
                            curve: Curves.easeOutBack,
                          ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ScoreDetailPill(label: 'Ham Puan\n${result.rawScore.toStringAsFixed(2)}'),
                          const SizedBox(width: 16),
                          _ScoreDetailPill(label: 'OBP Katkısı\n+${result.obpContribution.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.12, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 32),

                // Matches
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics_rounded, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${result.departmentName} Analizi',
                              style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Puanına uygun ${result.totalMatches} üniversite bölümü bulundu.',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryFor(context)),
                      ),
                      const SizedBox(height: 24),

                      if (result.guaranteed.isNotEmpty) ...[
                        _CategoryHeader(
                          title: '🟢 Yüksek şans',
                          color: const Color(0xFF10B981),
                        ),
                        ...result.guaranteed.map((m) => UniversityMatchCard(match: m)),
                        const SizedBox(height: 16),
                      ],

                      if (result.target.isNotEmpty) ...[
                        _CategoryHeader(
                          title: '🟡 Ulaşılabilir',
                          color: const Color(0xFFF59E0B),
                        ),
                        ...result.target.map((m) => UniversityMatchCard(match: m)),
                        const SizedBox(height: 16),
                      ],

                      if (result.dream.isNotEmpty) ...[
                        _CategoryHeader(
                          title: '🔴 Zorlayıcı',
                          color: const Color(0xFFEF4444),
                        ),
                        ...result.dream.map((m) => UniversityMatchCard(match: m)),
                        const SizedBox(height: 16),
                      ],

                      _WizardTransferCta(result: result),
                      const SizedBox(height: 32),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 400.ms)
                    .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ana Sayfaya Dön'),
        content: const Text(
          'Ana sayfaya yönlendirileceksiniz. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, true);
              context.go('/');
            },
            child: Text(
              'Evet, Dön',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WizardTransferCta extends ConsumerWidget {
  final CalculationResult result;
  const _WizardTransferCta({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const RobotAvatar(
                size: 28,
                animated: false,
                mood: RobotMood.happy,
                bodyColor: AppColors.secondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bu puanla tüm bölümleri gör',
                  style: AppTextStyles.titleSmall
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Bu puanla sana neler bulabileceğime bakalım mı? Programları '
            'şans durumuna göre gruplar, listeni kurmana yardım ederim.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryFor(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: () async {
                await ref.read(studentScoreProfileProvider.notifier).save(
                      StudentScoreProfile(
                        scoreType: result.scoreType,
                        placementScore: result.calculatedScore,
                        // Robot giriş ekranıyla aynı: profil yılı = bu yıl.
                        year: DateTime.now().year,
                        updatedAt: DateTime.now(),
                      ),
                    );
                if (context.mounted) {
                  context.push('/preference-wizard/results');
                }
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Tercih robotuna aktar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreDetailPill extends StatelessWidget {
  final String label;
  const _ScoreDetailPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _CategoryHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
