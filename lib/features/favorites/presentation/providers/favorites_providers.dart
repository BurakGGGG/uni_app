import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/favorites_repository.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../services/offline_favorite_sync.dart';

/// FavoritesRepository sağlayıcısı
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository();
});

/// Offline senkronizasyon servisi
final offlineFavoriteSyncProvider = Provider<OfflineFavoriteSync>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  final repo = ref.read(favoritesRepositoryProvider);
  return OfflineFavoriteSync(prefs, repo);
});

/// Kullanıcının favori üniversitelerinin (ID'leri) canlı listesi
final favoritesProvider = StreamProvider<List<String>>((ref) {
  final authState = ref.watch(authStateProvider);

  // Online olunca bekleyen favori işlemlerini senkronize et
  final isOnline = ref.watch(isOnlineProvider);
  if (isOnline) {
    final sync = ref.read(offlineFavoriteSyncProvider);
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null && sync.hasPendingActions) {
      sync.syncPendingActions(user.uid);
    }
  }

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
  final OfflineFavoriteSync _offlineSync;
  final bool _isOnline;

  FavoritesController(this._repository, this._offlineSync, this._isOnline)
      : super(const AsyncValue.data(null));

  Future<void> toggleFavorite(String uid, String universityId, bool isCurrentlyFavorite) async {
    state = const AsyncValue.loading();
    try {
      if (_isOnline) {
        // Online — doğrudan Firestore'a yaz
        if (isCurrentlyFavorite) {
          await _repository.removeFavorite(uid, universityId);
        } else {
          await _repository.addFavorite(uid, universityId);
        }
      } else {
        // Offline — kuyruğa ekle
        if (isCurrentlyFavorite) {
          await _offlineSync.queueRemove(uid, universityId);
        } else {
          await _offlineSync.queueAdd(uid, universityId);
        }
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final favoritesControllerProvider = StateNotifierProvider<FavoritesController, AsyncValue<void>>((ref) {
  return FavoritesController(
    ref.read(favoritesRepositoryProvider),
    ref.read(offlineFavoriteSyncProvider),
    ref.watch(isOnlineProvider),
  );
});

