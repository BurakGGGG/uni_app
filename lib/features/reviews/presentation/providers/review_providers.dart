import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/review_repository.dart';
import '../../data/report_repository.dart';
import '../../domain/models/review_model.dart';

/// ReviewRepository sağlayıcısı
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository();
});

/// ReportRepository sağlayıcısı
final reportRepositoryProvider = Provider<ReportRepository>((_) {
  return ReportRepository();
});

/// Bir yoruma ait detayı getiren sağlayıcı
final reviewDetailProvider = FutureProvider.family<ReviewModel?, String>((ref, id) {
  return ref.read(reviewRepositoryProvider).getReview(id);
});

/// Bir üniversiteye ait yorumları dinleyen sağlayıcı
final universityReviewsProvider = StreamProvider.family<List<ReviewModel>, String>((ref, universityId) {
  ref.keepAlive();
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
  ref.keepAlive();
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
/// Firestore path: users/{userId}/likedReviews/{reviewId}
final userLikedReviewsProvider = StreamProvider<Set<String>>((ref) {
  ref.keepAlive(); // Tab değişiminde stream kapanmasın

  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value({});

  // Denormalize: tek user'ın subcollection'ı — collectionGroup'tan çok daha hızlı
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('likedReviews')
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.id).toSet());
});

/// Pending like durumu — desired final state'i saklar
class _PendingLike {
  final bool desiredLiked;
  _PendingLike({required this.desiredLiked});
}

/// Optimistic like controller — reconcile pattern ile flicker yok
class LikeController extends StateNotifier<Map<String, _PendingLike>> {
  LikeController(this._repo) : super({});
  final ReviewRepository _repo;

  Future<void> toggleLike({
    required String reviewId,
    required String userId,
    required bool currentlyLiked,
  }) async {
    // Zaten pending varsa, tıklamayı yoksay (debounce)
    if (state.containsKey(reviewId)) return;

    // Pending state ekle — desired final state'i sakla
    state = {...state, reviewId: _PendingLike(desiredLiked: !currentlyLiked)};

    try {
      await _repo.likeReview(reviewId, userId);
    } catch (e) {
      // Hata: pending'i kaldır, kullanıcı eski state'e döner
      state = Map.from(state)..remove(reviewId);
      rethrow;
    }
  }

  /// Server stream'den gelen güncel durumu pending state ile karşılaştır.
  /// Eğer pending desired ile eşleşiyorsa, pending'i temizle.
  void reconcile(Set<String> serverLikedIds) {
    if (state.isEmpty) return;

    final newState = <String, _PendingLike>{};
    for (final entry in state.entries) {
      final actuallyLiked = serverLikedIds.contains(entry.key);
      // Server reality matches desired? → pending bitti
      if (actuallyLiked == entry.value.desiredLiked) continue;
      newState[entry.key] = entry.value;
    }
    if (newState.length != state.length) {
      state = newState;
    }
  }
}

final likeControllerProvider =
    StateNotifierProvider<LikeController, Map<String, _PendingLike>>((ref) {
  final controller = LikeController(ref.read(reviewRepositoryProvider));

  // Server stream her güncellendiğinde reconcile et
  ref.listen<AsyncValue<Set<String>>>(userLikedReviewsProvider, (prev, next) {
    next.whenData((ids) => controller.reconcile(ids));
  });

  return controller;
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
    } else if (params.type == ReviewType.place) {
      return repo.getPlaceReviews(params.targetId, orderBy: orderBy);
    } else {
      // department ve place aynı targetId bazlı sorguyu kullanır
      return repo.getDepartmentReviews(params.targetId, orderBy: orderBy);
    }
  },
);

// ─── Sprint 4 — Place Yorumları Provider ────────────────────────────

/// Bir mekana ait yorumları dinleyen sağlayıcı
final placeReviewsProvider = StreamProvider.family<List<ReviewModel>, String>((ref, placeId) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getPlaceReviews(placeId);
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

/// Yorum ekleme/silme sonrası kullanıcı profili cache'ini temizler ve provider'ı invalidate eder.
/// Bu sayede reviewCount UI'da anında güncellenir.
void invalidateUserProfileAfterReviewChange(WidgetRef ref) {
  ref.read(authRepositoryProvider).clearCache();
  ref.invalidate(currentUserProvider);
}
// ─── Sprint 3 Fix — Bug 3: Tüm Yorumlar Filtre State ───────────────

class AllReviewsFilterState {
  final String? universityId;
  final ReviewType? reviewType;
  final ReviewSort sort;

  const AllReviewsFilterState({
    this.universityId,
    this.reviewType,
    this.sort = ReviewSort.newest,
  });

  AllReviewsFilterState copyWith({
    String? universityId,
    bool clearUniversityId = false,
    ReviewType? reviewType,
    bool clearReviewType = false,
    ReviewSort? sort,
  }) {
    return AllReviewsFilterState(
      universityId: clearUniversityId ? null : (universityId ?? this.universityId),
      reviewType: clearReviewType ? null : (reviewType ?? this.reviewType),
      sort: sort ?? this.sort,
    );
  }

  int get activeFilterCount =>
      (universityId != null ? 1 : 0) + (reviewType != null ? 1 : 0);

  bool get hasFilters => universityId != null || reviewType != null;
}

class AllReviewsFilterNotifier extends Notifier<AllReviewsFilterState> {
  @override
  AllReviewsFilterState build() => const AllReviewsFilterState();

  void setUniversity(String? id) {
    state = state.copyWith(
      universityId: id,
      clearUniversityId: id == null,
    );
  }

  void setReviewType(ReviewType? type) {
    state = state.copyWith(
      reviewType: type,
      clearReviewType: type == null,
    );
  }

  void setSort(ReviewSort sort) {
    state = state.copyWith(sort: sort);
  }

  void clearAll() {
    state = const AllReviewsFilterState();
  }
}

final allReviewsFilterProvider =
    NotifierProvider<AllReviewsFilterNotifier, AllReviewsFilterState>(
  AllReviewsFilterNotifier.new,
);

/// Filtreli tüm yorumlar stream'i
final allFilteredReviewsProvider = StreamProvider<List<ReviewModel>>((ref) {
  ref.keepAlive();
  final filter = ref.watch(allReviewsFilterProvider);
  final repo = ref.read(reviewRepositoryProvider);
  return repo.getAllReviews(
    universityId: filter.universityId,
    reviewType: filter.reviewType,
    orderBy: filter.sort == ReviewSort.newest ? 'createdAt' : 'likes',
    limit: 50,
  );
});
