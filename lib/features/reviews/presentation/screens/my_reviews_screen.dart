import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/review_model.dart';
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
      body: RefreshIndicator(
        onRefresh: () async {
          invalidateUserProfileAfterReviewChange(ref);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) return _buildEmptyState(context);

            final pendingCount = reviews.where((r) => !r.isApproved).length;

            return Column(
              children: [
                if (pendingCount > 0)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$pendingCount yorumun moderasyon nedeniyle yayınlanmadı. '
                            'Aşağıda işaretlendi.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: reviews.length,
                    itemBuilder: (_, i) {
                      final r = reviews[i];
                      return ReviewCard(
                        review: r,
                        showActions: true,
                        showReportMenu: false,
                        showTargetInfo: true, // YENİ
                        onEdited: () => context.push('/edit-review/${r.id}'),
                        onTap: () {
                          switch (r.type) {
                            case ReviewType.department:
                              context.push('/department/${r.targetId}');
                              break;
                            case ReviewType.place:
                              context.push('/place/${r.targetId}');
                              break;
                            case ReviewType.university:
                              context.push('/university/${r.targetId}');
                              break;
                          }
                        },
                        onDeleted: () async {
                          await ref.read(reviewActionControllerProvider.notifier).deleteReview(r);
                          invalidateUserProfileAfterReviewChange(ref);
                          if (context.mounted) {
                            showAppSnackBar(context, message: 'Yorumunuz başarıyla silindi', isSuccess: true);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Hata: $e')),
        ),
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
