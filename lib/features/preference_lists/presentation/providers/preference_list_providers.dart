import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../preference_wizard/domain/list_health.dart';
import '../../../preference_wizard/presentation/providers/preference_wizard_providers.dart';
import '../../data/preference_list_repository.dart';
import '../../domain/list_overview.dart';
import '../../domain/models/preference_list_model.dart';

final preferenceListRepositoryProvider = Provider<PreferenceListRepository>((ref) {
  return PreferenceListRepository();
});

/// Kullanıcının tüm listeleri.
///
/// `authStateProvider` izlenir ki hesap değişiminde stream yeni uid'e yeniden
/// bağlansın — `watchMyLists()` `currentUser`'ı abonelik anında okur, izlenmezse
/// keepAlive abonelik eski hesabın sorgusuna takılı kalır (çıkışta boş/erişim
/// hatası, yeni hesapta liste görünmez).
final myPreferenceListsProvider = StreamProvider<List<PreferenceListModel>>((ref) {
  ref.keepAlive();
  ref.watch(authStateProvider);
  return ref.watch(preferenceListRepositoryProvider).watchMyLists();
});

/// Tek liste detay
final preferenceListProvider = StreamProvider.family<PreferenceListModel?, String>((ref, listId) {
  return ref.watch(preferenceListRepositoryProvider).watchList(listId);
});

/// Public liste (paylaşım slug ile)
final publicListBySlugProvider = FutureProvider.family<PreferenceListModel?, String>((ref, slug) {
  return ref.watch(preferenceListRepositoryProvider).getPublicListBySlug(slug);
});

/// Aksiyonlar için controller
class PreferenceListController extends StateNotifier<AsyncValue<void>> {
  PreferenceListController(this._repo) : super(const AsyncValue.data(null));
  final PreferenceListRepository _repo;

  Future<PreferenceListModel?> create({
    required String title,
    String description = '',
    bool isPublic = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.createList(
        title: title,
        description: description,
        isPublic: isPublic,
      );
      state = const AsyncValue.data(null);
      return list;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Paylaşılan listeyi kullanıcının kendi hesabına kopyalar (orijinal değişmez).
  Future<PreferenceListModel> copy(PreferenceListModel source) async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.copyList(source);
      state = const AsyncValue.data(null);
      return list;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> update(PreferenceListModel list) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateList(list);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> delete(String listId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteList(listId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final preferenceListControllerProvider =
    StateNotifierProvider<PreferenceListController, AsyncValue<void>>(
  (ref) => PreferenceListController(ref.read(preferenceListRepositoryProvider)),
);

// ─── Sabitlenen liste ──────────────────────────────────────────

/// Hub'ın "ANA LİSTEN" kartında hangi listenin duracağı.
///
/// **Cihaz-yerel** (kullanıcı kararı): "hangisi benim ana listem" kişisel ve
/// anlık bir tercih. Firestore'a yazmak `firestore.rules`'daki alan beyaz
/// listesini genişletip deploy etmeyi gerektirirdi; o deploy Play sürümünü
/// bekliyor ve o zamana dek sabitleme "izin yok" hatası alırdı.
class PinnedListNotifier extends StateNotifier<String?> {
  static const String storageKey = 'pref_list_pinned_v1';

  final SharedPreferences _prefs;

  PinnedListNotifier(this._prefs) : super(_prefs.getString(storageKey));

  /// Aynı listeye ikinci kez basmak sabitlemeyi kaldırır.
  Future<void> toggle(String listId) async {
    if (state == listId) {
      state = null;
      await _prefs.remove(storageKey);
      return;
    }
    state = listId;
    await _prefs.setString(storageKey, listId);
  }

  /// Hesap değişiminde çağrılır: kayıtlı id önceki kullanıcının listesine
  /// ait, yeni hesapta hiçbir şeye denk gelmez.
  Future<void> clear() async {
    state = null;
    await _prefs.remove(storageKey);
  }
}

final pinnedListProvider = StateNotifierProvider<PinnedListNotifier, String?>(
  (ref) => PinnedListNotifier(ref.watch(sharedPreferencesProvider)),
);

/// Hub'ın çizdiği liste: her liste + dengesi, ana liste başta.
///
/// Denge burada bir kez hesaplanır; kahraman kart, kompakt satırlar ve
/// paylaşım görseli aynı sayıları kullanır.
final listOverviewsProvider = Provider<List<ListOverview>>((ref) {
  final lists = ref.watch(myPreferenceListsProvider).valueOrNull ?? const [];
  if (lists.isEmpty) return const [];

  final profile = ref.watch(studentScoreProfileProvider);
  final pinned = ref.watch(pinnedListProvider);

  // Sırasız (yalnız puanlı) profilde tahmini sırayla — `ListHealthPanel` ve
  // motor ile aynı yol; üç yüzey aynı kategoriyi söylesin.
  final estimator = ref.watch(rankEstimatorProvider).valueOrNull;
  final estimatedRank = profile == null || profile.hasRank || !profile.hasScore
      ? null
      : estimator?.estimateRank(profile.placementScore, profile.scoreType);

  return hubOrder([
    for (final list in lists)
      ListOverview(
        list: list,
        pinned: list.id == pinned,
        health: profile == null
            ? null
            : analyzeListHealth(
                list.items,
                profile,
                estimatedStudentRank: estimatedRank,
              ),
      ),
  ]);
});
