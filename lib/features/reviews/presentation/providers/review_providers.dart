import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/review_repository.dart';
import '../../domain/models/review_model.dart';

/// ReviewRepository sağlayıcısı
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository();
});

/// Bir üniversiteye ait yorumları dinleyen sağlayıcı
final universityReviewsProvider = StreamProvider.family<List<ReviewModel>, String>((ref, universityId) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getUniversityReviews(universityId);
});

/// Bir bölüme ait yorumları dinleyen sağlayıcı
final departmentReviewsProvider = StreamProvider.family<List<ReviewModel>, String>((ref, departmentId) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getDepartmentReviews(departmentId);
});

/// Ana sayfada gösterilecek son yorumları dinleyen sağlayıcı
final recentReviewsProvider = StreamProvider<List<ReviewModel>>((ref) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getRecentReviews(limit: 5);
});
