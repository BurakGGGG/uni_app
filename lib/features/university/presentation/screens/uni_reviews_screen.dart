import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/university_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../reviews/presentation/widgets/review_list.dart';
import '../../../reviews/domain/models/review_model.dart';
import '../../../reviews/presentation/utils/review_submission_guard.dart';

/// Tüm yorumların tam listesi — /university/:uniId/reviews
class UniReviewsScreen extends ConsumerWidget {
  final String universityId;

  const UniReviewsScreen({super.key, required this.universityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uniAsync = ref.watch(universityDetailProvider(universityId));

    return Scaffold(
      appBar: AppBar(title: const Text('Yorumlar')),
      body: uniAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Hata: $e')),
        data: (uni) {
          if (uni == null) {
            return const Center(child: Text('Üniversite bulunamadı'));
          }

          return Builder(
            builder: (context) {
              final children = [
                // Değerlendir butonu
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Consumer(
                    builder: (context, ref, _) {
                      final currentUserAsync = ref.watch(currentUserProvider);
                      return currentUserAsync.when(
                        data: (profile) {
                          final canReview =
                              profile != null &&
                              profile.universityId == universityId &&
                              profile.isVerifiedStudent;

                          return SizedBox(
                            width: double.infinity,
                            child: canReview
                                ? ElevatedButton.icon(
                                    onPressed: () => openWriteReviewIfAllowed(
                                      context: context,
                                      ref: ref,
                                      type: ReviewType.university,
                                      targetId: universityId,
                                      universityId: universityId,
                                    ),
                                    icon: const Icon(
                                      Icons.add_comment_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Bu Üniversiteyi Değerlendir',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppConstants.radiusMd,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          );
                        },
                        loading: () => const SizedBox(height: 48),
                        error: (err, stack) => const SizedBox.shrink(),
                      );
                    },
                  ),
                ),

                // Yorum listesi
                ReviewList(targetId: universityId, type: ReviewType.university),
              ];

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: children.length,
                itemBuilder: (context, index) => children[index],
              );
            },
          );
        },
      ),
    );
  }
}
