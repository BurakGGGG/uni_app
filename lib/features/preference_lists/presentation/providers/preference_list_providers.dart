import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/preference_list_repository.dart';
import '../../domain/models/preference_list_model.dart';

final preferenceListRepositoryProvider = Provider<PreferenceListRepository>((ref) {
  return PreferenceListRepository();
});

/// Kullanıcının tüm listeleri
final myPreferenceListsProvider = StreamProvider<List<PreferenceListModel>>((ref) {
  ref.keepAlive();
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
