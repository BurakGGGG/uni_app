import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/review_providers.dart';
import '../widgets/review_card.dart';

class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Yorumlarım')),
        body: _buildUnauthenticatedState(context),
      );
    }
    
    final reviewsAsync = ref.watch(userReviewsProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Yorumlarım')),
      body: reviewsAsync.when(
        data: (reviews) {
          if (reviews.isEmpty) return _buildEmptyState(context);
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: reviews.length,
            itemBuilder: (_, i) {
              final r = reviews[i];
              return ReviewCard(
                review: r,
                showActions: true,
                showReportMenu: false,
                onEdited: () => context.push('/edit-review/${r.id}'),
                onDeleted: () async {
                  await ref.read(reviewActionControllerProvider.notifier).deleteReview(r);
                  ref.invalidate(currentUserProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Yorumunuz silindi')),
                    );
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('Henüz bir yorum yapmadınız.', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Okuduğunuz veya incelediğiniz bölümleri\ndeğerlendirerek diğer öğrencilere yardımcı olun.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Üniversiteleri Keşfet'),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthenticatedState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('Giriş Yapmanız Gerekiyor', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Yorumlarınızı görebilmek için\nlütfen giriş yapın.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.push('/login'),
            child: const Text('Giriş Yap'),
          ),
        ],
      ),
    );
  }
}
