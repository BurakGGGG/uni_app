import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/score_calculator_providers.dart';
import '../widgets/university_match_card.dart';


class ScoreResultScreen extends ConsumerWidget {
  const ScoreResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(calculationResultProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        title: const Text('Sonuçlar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: resultAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Hesaplama başarısız', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Ana Sayfaya Dön'),
              ),
            ],
          ),
        ),
        data: (result) {
          if (result == null) {
            return Center(
              child: ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Geri Dön ve Bilgileri Doldur'),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Score Hero
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${result.scoreType} YERLEŞTİRME PUANI',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        result.calculatedScore.toStringAsFixed(3),
                        style: AppTextStyles.displayLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ScoreDetailPill(label: 'Ham: ${result.rawScore.toStringAsFixed(2)}'),
                          const SizedBox(width: 12),
                          _ScoreDetailPill(label: 'OBP: +${result.obpContribution.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                  ),
                ),
                
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
                        'Puanına uygun ${result.totalMatches} üniversite bölümü bulundu. (Sıralamalar bölümlerin kartlarında belirtilmiştir)',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryFor(context)),
                      ),
                      const SizedBox(height: 24),

                      if (result.guaranteed.isNotEmpty) ...[
                        _CategoryHeader(
                          title: '🟢 Rahat Yerleşirsin',
                          color: const Color(0xFF10B981),
                        ),
                        ...result.guaranteed.map((m) => UniversityMatchCard(match: m)),
                        const SizedBox(height: 16),
                      ],

                      if (result.target.isNotEmpty) ...[
                        _CategoryHeader(
                          title: '🟡 Sınırda (Hedef)',
                          color: const Color(0xFFF59E0B),
                        ),
                        ...result.target.map((m) => UniversityMatchCard(match: m)),
                        const SizedBox(height: 16),
                      ],

                      if (result.dream.isNotEmpty) ...[
                        _CategoryHeader(
                          title: '🔴 Zorlayabilir',
                          color: const Color(0xFFEF4444),
                        ),
                        ...result.dream.map((m) => UniversityMatchCard(match: m)),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
