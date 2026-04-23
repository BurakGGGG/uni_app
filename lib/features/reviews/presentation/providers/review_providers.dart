import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/review_repository.dart';
import '../../domain/models/review_model.dart';

/// ReviewRepository sağlayıcısı
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository();
});

/// Bir yoruma ait detayı getiren sağlayıcı
final reviewDetailProvider = FutureProvider.family<ReviewModel?, String>((ref, id) {
  return ref.read(reviewRepositoryProvider).getReview(id);
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

/// Kullanıcının kendi yaptığı yorumları dinleyen sağlayıcı
final userReviewsProvider = StreamProvider.family<List<ReviewModel>, String>((ref, userId) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getUserReviews(userId);
});

// ─── Sprint 3 — Kişi B: Like Sistemi Provider'ları ─────────────────

/// Kullanıcının beğendiği yorumların ID'lerini dinleyen sağlayıcı
/// Firestore path: reviews/{reviewId}/likes/{userId}
final userLikedReviewsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value({});

  return FirebaseFirestore.instance
      .collectionGroup('likes')
      .where(FieldPath.documentId, isEqualTo: user.uid)
      .snapshots()
      .map((snap) {
    // Her like doc'u parent: reviews/{reviewId}/likes/{userId}
    return snap.docs
        .map((d) => d.reference.parent.parent!.id)
        .toSet();
  });
});

/// Optimistic like controller — anında UI güncellemesi, hata olursa rollback
class LikeController extends StateNotifier<Map<String, bool>> {
  LikeController(this._repo) : super({});
  final ReviewRepository _repo;

  Future<void> toggleLike({
    required String reviewId,
    required String userId,
    required bool currentlyLiked,
  }) async {
    // Optimistic update — UI anında değişir
    state = {...state, reviewId: !currentlyLiked};

    try {
      await _repo.likeReview(reviewId, userId);
    } catch (e) {
      // Hata olursa geri al
      state = {...state}..remove(reviewId);
      rethrow;
    }

    // Server stream güncellediğinde pending'i temizle
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        state = {...state}..remove(reviewId);
      }
    });
  }
}

final likeControllerProvider =
    StateNotifierProvider<LikeController, Map<String, bool>>((ref) {
  return LikeController(ref.read(reviewRepositoryProvider));
});

// ─── Sprint 3 — Kişi B: Sort/Filter Provider'ları ──────────────────

/// Yorum sıralama seçenekleri
enum ReviewSort { newest, mostLiked }

/// Mevcut sıralama tercihi
final reviewSortProvider = StateProvider<ReviewSort>((_) => ReviewSort.newest);

/// Sorted reviews için parametre sınıfı (targetId + type)
class SortedReviewsParams {
  final String targetId;
  final ReviewType type;
  const SortedReviewsParams({required this.targetId, required this.type});

  @override
  bool operator ==(Object other) =>
      other is SortedReviewsParams &&
      other.targetId == targetId &&
      other.type == type;

  @override
  int get hashCode => Object.hash(targetId, type);
}

/// Sıralama tercihine göre yorumları dinleyen sağlayıcı
final sortedReviewsProvider =
    StreamProvider.family<List<ReviewModel>, SortedReviewsParams>(
  (ref, params) {
    final sort = ref.watch(reviewSortProvider);
    final repo = ref.read(reviewRepositoryProvider);
    final orderBy = sort == ReviewSort.newest ? 'createdAt' : 'likes';

    if (params.type == ReviewType.university) {
      return repo.getUniversityReviews(params.targetId, orderBy: orderBy);
    } else {
      return repo.getDepartmentReviews(params.targetId, orderBy: orderBy);
    }
  },
);

final userReviewsProvider = StreamProvider.family<List<ReviewModel>, String>((ref, userId) {
  return ref.read(reviewRepositoryProvider).getUserReviews(userId);
});

class ReviewActionController extends StateNotifier<AsyncValue<void>> {
  ReviewActionController(this._repo) : super(const AsyncValue.data(null));
  final ReviewRepository _repo;

  Future<void> deleteReview(ReviewModel review) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteReview(review.id, review.userId, review.imageUrls);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final reviewActionControllerProvider = 
  StateNotifierProvider<ReviewActionController, AsyncValue<void>>((ref) {
    return ReviewActionController(ref.read(reviewRepositoryProvider));
  });
