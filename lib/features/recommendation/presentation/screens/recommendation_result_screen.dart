import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/recommendation_result.dart';
import '../providers/recommendation_providers.dart';

class RecommendationResultScreen extends ConsumerWidget {
  const RecommendationResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(recommendationResultProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Önerilerim',
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/recommend'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yeniden başlat',
            onPressed: () => context.go('/recommend'),
          ),
        ],
      ),
      body: result.recommendations.isEmpty
          ? _buildEmpty(context)
          : _buildResults(context, result),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, size: 56, color: AppColors.secondary),
            ),
            const SizedBox(height: 24),
            Text('Önerimiz yok',
                style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Verdiğin cevaplara uygun üniversite bulamadık. Filtreleri gevşeterek tekrar dene.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/recommend'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Yeniden Başla',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, RecommendationResult result) {
    final topThree = result.recommendations.where(
        (r) => r.medal == MedalType.gold || r.medal == MedalType.silver || r.medal == MedalType.bronze).toList();
    final others = result.recommendations.where(
        (r) => r.medal == MedalType.honorable || r.medal == MedalType.none).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6584), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6584).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text('Analiz Sonucu',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                result.summary,
                style: AppTextStyles.bodyLarge.copyWith(color: Colors.white, height: 1.5),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Podium — Top 3
        if (topThree.isNotEmpty) ...[
          Text('🏆 En İyi Eşleşmeler',
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Tercihlerine en uygun 3 öneri',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),

          ...topThree.map((rec) => _MedalCard(rec: rec)),

          const SizedBox(height: 24),
        ],

        // Other recommendations
        if (others.isNotEmpty) ...[
          Text('Diğer Öneriler',
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Senin için uygun olabilecek diğer seçenekler',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),

          ...others.asMap().entries.map((entry) =>
              _OtherCard(rec: entry.value, rank: entry.key + 4)),
        ],

        const SizedBox(height: 16),

        // CTA
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: () => context.go('/recommend'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Yeniden Dene',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

// ── Medal Card (Top 3) ──────────────────────────────────────
class _MedalCard extends StatelessWidget {
  final CombinedRecommendation rec;
  const _MedalCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    final medalData = _getMedalData(rec.medal);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        shadowColor: medalData.color.withValues(alpha: 0.15),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: medalData.color.withValues(alpha: 0.3), width: 1.5),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Medal badge
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: medalData.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: medalData.color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(medalData.emoji,
                            style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Department + University
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rec.departmentName,
                              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(rec.universityName,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    // Score
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: medalData.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '%${rec.normalizedScore.toInt()}',
                        style: TextStyle(
                          color: medalData.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                if (rec.reasons.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  ...rec.reasons.map((reason) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 16, color: medalData.color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(reason,
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary, height: 1.3)),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  _MedalData _getMedalData(MedalType medal) {
    return switch (medal) {
      MedalType.gold => _MedalData(
          emoji: '🥇',
          color: const Color(0xFFD4A017),
          gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
        ),
      MedalType.silver => _MedalData(
          emoji: '🥈',
          color: const Color(0xFF8E8E8E),
          gradient: [const Color(0xFFC0C0C0), const Color(0xFF8E8E8E)],
        ),
      MedalType.bronze => _MedalData(
          emoji: '🥉',
          color: const Color(0xFFCD7F32),
          gradient: [const Color(0xFFCD7F32), const Color(0xFF8B5A2B)],
        ),
      _ => _MedalData(
          emoji: '⭐',
          color: AppColors.primary,
          gradient: [AppColors.primary, AppColors.primary],
        ),
    };
  }
}

class _MedalData {
  final String emoji;
  final Color color;
  final List<Color> gradient;
  _MedalData({required this.emoji, required this.color, required this.gradient});
}

// ── Other Card (4-8) ────────────────────────────────────────
class _OtherCard extends StatelessWidget {
  final CombinedRecommendation rec;
  final int rank;
  const _OtherCard({required this.rec, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        shadowColor: AppColors.textPrimary.withValues(alpha: 0.05),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text('#$rank',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rec.departmentName,
                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(rec.universityName,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '%${rec.normalizedScore.toInt()}',
                    style: const TextStyle(
                        color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
