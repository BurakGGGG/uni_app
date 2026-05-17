import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/university_providers.dart';
import '../../../reviews/presentation/widgets/review_list.dart';
import '../../../reviews/domain/models/review_model.dart';
import '../../../reviews/presentation/widgets/category_ratings_chart.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/score_badge.dart';
import '../widgets/score_trend_chart.dart';
import '../widgets/score_detail_sheet.dart';

class DepartmentDetailScreen extends ConsumerWidget {
  final String departmentId;

  const DepartmentDetailScreen({super.key, required this.departmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptAsync = ref.watch(departmentDetailProvider(departmentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bölüm Detayı'),
      ),
      body: deptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Hata: $e')),
        data: (dept) {
          if (dept == null) {
            return const Center(child: Text('Bölüm bulunamadı'));
          }

          // Üniversite bilgisini de çek
          final uniAsync = ref.watch(universityDetailProvider(dept.universityId));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Bölüm Başlığı ────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.85),
                        AppColors.secondary.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppConstants.radiusXl),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          dept.type == 'Lisans' ? Icons.school_rounded : Icons.auto_stories_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        dept.name,
                        style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dept.faculty,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Üniversite adı
                      uniAsync.when(
                        data: (uni) => GestureDetector(
                          onTap: () => context.push('/university/${dept.universityId}'),
                          child: Row(
                            children: [
                              const Icon(Icons.location_city_rounded, color: Colors.white70, size: 16),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  uni?.name ?? '',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white54,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, st) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),

                const SizedBox(height: 24),

                // ─── Bilgi Kartları ─────────────────────────────────
                Row(
                  children: [
                    _InfoTile(
                      icon: Icons.access_time_rounded,
                      label: 'Süre',
                      value: '${dept.duration} Yıl',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    _InfoTile(
                      icon: Icons.translate_rounded,
                      label: 'Dil',
                      value: dept.language,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 12),
                    _InfoTile(
                      icon: Icons.category_rounded,
                      label: 'Tür',
                      value: dept.type,
                      color: AppColors.secondary,
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: 16),

                // ─── Taban Puan Kartı ─────────────────────────────
                if (dept.scoreData != null) ...[
                  // Ana puan kartı — tıklanınca detay açılıyor
                  GestureDetector(
                    onTap: () => showScoreDetailSheet(context, dept.scoreData!, dept.name),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceFor(context),
                        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                        border: Border.all(color: AppColors.borderLightFor(context)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.trending_up_rounded, color: AppColors.warning, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('${dept.scoreData!.year} Taban Puanı', style: AppTextStyles.labelMedium),
                                    const SizedBox(width: 6),
                                    Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.textTertiaryFor(context)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      dept.scoreData!.baseScore.toStringAsFixed(2),
                                      style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary),
                                    ),
                                    if (dept.scoreData!.yearOverYearDelta != null) ...[
                                      const SizedBox(width: 8),
                                      ScoreBadge.delta(dept.scoreData!.yearOverYearDelta!, small: true),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ScoreBadge.scoreType(dept.scoreData!.scoreType),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                  const SizedBox(height: 12),

                  // Detay grid'i — 4 kart
                  Row(
                    children: [
                      _ScoreInfoTile(
                        label: 'Başarı Sırası',
                        value: dept.scoreData!.ranking > 0
                            ? dept.scoreData!.ranking.toString()
                            : '—',
                        icon: Icons.emoji_events_rounded,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      _ScoreInfoTile(
                        label: 'Kontenjan',
                        value: '${dept.scoreData!.placedCount}/${dept.scoreData!.quota}',
                        icon: Icons.people_rounded,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 8),
                      _ScoreInfoTile(
                        label: 'Doluluk',
                        value: '${(dept.scoreData!.fillRate * 100).toStringAsFixed(0)}%',
                        icon: Icons.pie_chart_rounded,
                        color: AppColors.success,
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                  const SizedBox(height: 16),

                  // Trend grafiği
                  ScoreTrendChart(scoreData: dept.scoreData!)
                      .animate().fadeIn(delay: 500.ms, duration: 400.ms),
                ] else if (dept.baseScore != null) ...[
                  // Fallback: eski veri yapısı
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceFor(context),
                      borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                      border: Border.all(color: AppColors.borderLightFor(context)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.trending_up_rounded, color: AppColors.warning, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Taban Puanı', style: AppTextStyles.labelMedium),
                              const SizedBox(height: 2),
                              Text(
                                dept.baseScore!.toStringAsFixed(2),
                                style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        if (dept.scoreType != null)
                          ScoreBadge.scoreType(dept.scoreType!),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                ],

                const SizedBox(height: 24),

                // ─── Kategori Puanları ──────────────────────────────
                CategoryRatingsChart(
                  ratings: dept.categoryRatings,
                  reviewCount: dept.reviewCount,
                ),

                const SizedBox(height: 24),

                // ─── Yorumlar Başlığı + Değerlendir Butonu ─────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.rate_review_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        Text('Yorumlar', style: AppTextStyles.headlineMedium),
                      ],
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final currentUserAsync = ref.watch(currentUserProvider);
                        return currentUserAsync.when(
                          data: (profile) {
                            final canReview = profile != null &&
                                profile.universityId == dept.universityId &&
                                profile.isVerifiedStudent;

                            if (!canReview) {
                              return TextButton.icon(
                                onPressed: () => _showReviewInfoSheet(
                                  context,
                                  profile: profile,
                                  isOwnUniversity: profile?.universityId == dept.universityId,
                                ),
                                icon: const Icon(Icons.add_comment_rounded, size: 18),
                                label: const Text('Değerlendir'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textTertiaryFor(context),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                                    side: BorderSide(color: AppColors.borderLightFor(context)),
                                  ),
                                ),
                              );
                            }

                            return TextButton.icon(
                              onPressed: () => context.push(
                                '/write-review/department/$departmentId?uni=${dept.universityId}',
                              ),
                              icon: const Icon(Icons.add_comment_rounded, size: 18),
                              label: const Text('Değerlendir'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                                ),
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (err, stack) => const SizedBox.shrink(),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ─── Yorum Listesi ───────────────────────────────
                ReviewList(
                  targetId: departmentId,
                  type: ReviewType.department,
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(color: AppColors.borderLightFor(context)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.titleSmall),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _ScoreInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ScoreInfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(color: AppColors.borderLightFor(context)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value, style: AppTextStyles.titleSmall.copyWith(fontSize: 13)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.labelSmall.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ─── Değerlendir Bilgi Bottom Sheet (Department) ─────────────────────
void _showReviewInfoSheet(
  BuildContext context, {
  required dynamic profile,
  required bool isOwnUniversity,
}) {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  if (profile == null) {
    icon = Icons.login_rounded;
    iconColor = AppColors.primary;
    title = 'Giriş Yapın';
    description = 'Yorum yazabilmek için önce hesabınıza giriş yapmanız gerekiyor.';
    buttonText = 'Giriş Yap';
    onButtonPressed = () {
      Navigator.pop(context);
      GoRouter.of(context).push('/login');
    };
  } else if (!(profile.isVerifiedStudent as bool)) {
    icon = Icons.verified_user_rounded;
    iconColor = AppColors.warning;
    title = 'Doğrulama Gerekli';
    description = 'Yorum yazabilmek için edu.tr uzantılı e-posta adresinizle doğrulama yapmanız gerekiyor.';
    buttonText = null;
    onButtonPressed = null;
  } else if (!isOwnUniversity) {
    icon = Icons.school_rounded;
    iconColor = AppColors.info;
    title = 'Farklı Üniversite';
    description = 'Sadece kendi üniversitenin bölümlerine yorum yapabilirsin.';
    buttonText = null;
    onButtonPressed = null;
  } else {
    icon = Icons.info_outline_rounded;
    iconColor = AppColors.textTertiary;
    title = 'Yorum Yazılamıyor';
    description = 'Şu anda bu bölüme yorum yazma yetkiniz bulunmuyor.';
    buttonText = null;
    onButtonPressed = null;
  }

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryFor(context),
                height: 1.5,
              ),
            ),
            if (buttonText != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    ),
                  ),
                  child: Text(buttonText),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
