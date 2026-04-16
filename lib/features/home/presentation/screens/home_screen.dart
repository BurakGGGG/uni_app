import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/widgets.dart';

/// Ana Sayfa ekranı
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ─── Header ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Merhaba! 👋',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppConstants.appName,
                              style: AppTextStyles.displaySmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        // Bildirim ikonu
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
            ),

            // ─── Arama Çubuğu ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: AppSearchBar(
                  readOnly: true,
                  onTap: () {
                    // TODO: Keşfet sayfasına yönlendir
                  },
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
            ),

            // ─── Hero Banner ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _HeroBanner(),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),
            ),

            // ─── Popüler Üniversiteler ──────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SectionHeader(
                    title: 'Popüler Üniversiteler',
                    actionText: 'Tümünü Gör',
                    padding: EdgeInsets.fromLTRB(20, 20, 12, 4),
                  ),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return _PopularUniCard(index: index);
                      },
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
            ),

            // ─── Şehirler ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SectionHeader(
                    title: 'Şehirler',
                    actionText: 'Tümünü Gör',
                    padding: EdgeInsets.fromLTRB(20, 16, 12, 4),
                  ),
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _sampleCities.length,
                      itemBuilder: (context, index) {
                        return _CityChip(
                          name: _sampleCities[index]['name']!,
                          emoji: _sampleCities[index]['emoji']!,
                          count: _sampleCities[index]['count']!,
                        );
                      },
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
            ),

            // ─── Son Yorumlar ───────────────────────────────────────
            SliverToBoxAdapter(
              child: const SectionHeader(
                title: 'Son Yorumlar',
                actionText: 'Tümünü Gör',
                padding: EdgeInsets.fromLTRB(20, 16, 12, 4),
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _RecentReviewCard(index: index)
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 550 + index * 80), duration: 400.ms)
                      .slideX(begin: 0.05, end: 0);
                },
                childCount: 3,
              ),
            ),

            // Bottom padding
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }
}

// ─── Sample Data ──────────────────────────────────────────────────────
final List<Map<String, String>> _sampleCities = [
  {'name': 'İstanbul', 'emoji': '🌉', 'count': '52'},
  {'name': 'Ankara', 'emoji': '🏛️', 'count': '38'},
  {'name': 'İzmir', 'emoji': '🌊', 'count': '15'},
  {'name': 'Sivas', 'emoji': '🏔️', 'count': '3'},
  {'name': 'Eskişehir', 'emoji': '🎓', 'count': '8'},
  {'name': 'Antalya', 'emoji': '☀️', 'count': '7'},
  {'name': 'Bursa', 'emoji': '🌿', 'count': '12'},
  {'name': 'Trabzon', 'emoji': '⛰️', 'count': '5'},
  {'name': 'Konya', 'emoji': '🕌', 'count': '9'},
  {'name': 'Mersin', 'emoji': '🍊', 'count': '4'},
];

final List<Map<String, String>> _sampleUniversities = [
  {'name': 'ODTÜ', 'city': 'Ankara', 'rating': '4.7', 'reviews': '342'},
  {'name': 'Boğaziçi', 'city': 'İstanbul', 'rating': '4.8', 'reviews': '412'},
  {'name': 'İTÜ', 'city': 'İstanbul', 'rating': '4.5', 'reviews': '287'},
  {'name': 'Hacettepe', 'city': 'Ankara', 'rating': '4.4', 'reviews': '198'},
  {'name': 'Ege Üniversitesi', 'city': 'İzmir', 'rating': '4.3', 'reviews': '156'},
];

// ─── Widget Components ──────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
      ),
      child: Stack(
        children: [
          // Dekoratif daireler
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // İçerik
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingXxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '2026 Tercih Dönemi',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hayalindeki üniversiteyi\nkeşfetmeye başla!',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Keşfet →',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularUniCard extends StatelessWidget {
  final int index;

  const _PopularUniCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final uni = _sampleUniversities[index];
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
    ];

    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İkon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors[index].withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: colors[index],
                    size: 24,
                  ),
                ),
                const Spacer(),
                // Başlık
                Text(
                  uni['name']!,
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  uni['city']!,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 8),
                // Rating
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: AppColors.ratingStar,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      uni['rating']!,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${uni['reviews']})',
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CityChip extends StatelessWidget {
  final String name;
  final String emoji;
  final String count;

  const _CityChip({
    required this.name,
    required this.emoji,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                name,
                style: AppTextStyles.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$count üni',
                style: AppTextStyles.labelSmall.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentReviewCard extends StatelessWidget {
  final int index;

  const _RecentReviewCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final reviews = [
      {
        'user': 'Ayşe K.',
        'uni': 'ODTÜ',
        'dept': 'Bilgisayar Müh.',
        'rating': '4.5',
        'comment': 'Kampüs hayatı harika, kütüphane 7/24 açık. Sosyal aktiviteler çok zengin.',
        'time': '2 saat önce',
      },
      {
        'user': 'Mehmet Y.',
        'uni': 'Boğaziçi',
        'dept': 'İşletme',
        'rating': '4.8',
        'comment': 'Hocalar çok ilgili. İstanbul\'da olmanın avantajlarını sonuna kadar yaşıyorsunuz.',
        'time': '5 saat önce',
      },
      {
        'user': 'Zeynep A.',
        'uni': 'İTÜ',
        'dept': 'Mimarlık',
        'rating': '4.2',
        'comment': 'Atölye imkanları çok iyi. Maçka kampüsünün konumu mükemmel.',
        'time': '1 gün önce',
      },
    ];

    final review = reviews[index];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kullanıcı bilgisi
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  review['user']![0],
                  style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['user']!,
                      style: AppTextStyles.titleSmall,
                    ),
                    Text(
                      '${review['uni']} • ${review['dept']}',
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ),
              // Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.ratingColor(double.parse(review['rating']!))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: AppColors.ratingColor(double.parse(review['rating']!)),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      review['rating']!,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.ratingColor(double.parse(review['rating']!)),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Yorum metni
          Text(
            review['comment']!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Zaman
          Text(
            review['time']!,
            style: AppTextStyles.labelSmall.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
