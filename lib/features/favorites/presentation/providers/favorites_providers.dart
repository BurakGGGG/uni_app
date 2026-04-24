import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/favorites_repository.dart';

/// FavoritesRepository sağlayıcısı
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository();
});

/// Kullanıcının favori üniversitelerinin (ID'leri) canlı listesi
final favoritesProvider = StreamProvider<List<String>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.read(favoritesRepositoryProvider).getUserFavoritesStream(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, st) => Stream.value([]),
  );
});

/// Favori ekleme/çıkarma işlemleri için controller
class FavoritesController extends StateNotifier<AsyncValue<void>> {
  final FavoritesRepository _repository;

  FavoritesController(this._repository) : super(const AsyncValue.data(null));

  Future<void> toggleFavorite(String uid, String universityId, bool isCurrentlyFavorite) async {
    state = const AsyncValue.loading();
    try {
      if (isCurrentlyFavorite) {
        await _repository.removeFavorite(uid, universityId);
      } else {
        await _repository.addFavorite(uid, universityId);
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final favoritesControllerProvider = StateNotifierProvider<FavoritesController, AsyncValue<void>>((ref) {
  return FavoritesController(ref.read(favoritesRepositoryProvider));
});
