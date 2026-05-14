import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/university_providers.dart';
import '../../../reviews/presentation/widgets/category_ratings_chart.dart';

import '../../../../core/widgets/widgets.dart';

class UniRatingsScreen extends ConsumerWidget {
  final String universityId;

  const UniRatingsScreen({super.key, required this.universityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uniAsync = ref.watch(universityDetailProvider(universityId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori Puanları'),
      ),
      body: uniAsync.when(
        loading: () => const ListSkeleton(itemCount: 4),
        error: (e, st) => ErrorState(
          title: 'Bilgiler yüklenemedi',
          message: 'Lütfen internet bağlantını kontrol et.',
          onRetry: () => ref.invalidate(universityDetailProvider(universityId)),
        ),
        data: (uni) {
          if (uni == null) return const Center(child: Text('Üniversite bulunamadı'));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Detaylı Puanlama Grafiği',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 16),
              CategoryRatingsChart(
                ratings: uni.categoryRatings,
                reviewCount: uni.reviewCount,
              ),
              const SizedBox(height: 32),
              // İleride buraya başka grafikler ve puanlamalar eklenebilir.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Puanlamalar onaylanmış öğrenci değerlendirmeleri baz alınarak hesaplanmaktadır. İlerleyen güncellemelerde daha detaylı grafikler eklenecektir.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
