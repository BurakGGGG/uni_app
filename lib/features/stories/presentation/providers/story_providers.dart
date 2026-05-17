import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../data/story_repository.dart';
import '../../domain/models/story_model.dart';

/// StoryRepository provider
final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepository();
});

/// Aktif story'leri dinleyen stream provider
final storiesStreamProvider = StreamProvider<List<StoryModel>>((ref) {
  return ref.watch(storyRepositoryProvider).getActiveStories();
});

/// Stream hata verirse (index hazır değilse) fallback
final storiesFallbackProvider = FutureProvider<List<StoryModel>>((ref) {
  return ref.watch(storyRepositoryProvider).getActiveStoriesFallback();
});

/// Aktif story listesini döndüren birleşik provider
/// Stream başarılıysa onu, değilse fallback'i kullanır
/// Liste eski→yeni sıradadır (Instagram gibi)
final activeStoriesProvider = Provider<AsyncValue<List<StoryModel>>>((ref) {
  final stream = ref.watch(storiesStreamProvider);

  // Stream data varsa onu kullan
  if (stream.hasValue) {
    // Firestore yeni→eski verir, ters çevirip eski→yeni yap
    final reversed = stream.value!.reversed.toList();
    return AsyncValue.data(reversed);
  }

  // Stream hata verdiyse fallback'e bak
  if (stream.hasError) {
    final fallback = ref.watch(storiesFallbackProvider);
    if (fallback.hasValue) {
      final reversed = fallback.value!.reversed.toList();
      return AsyncValue.data(reversed);
    }
    return fallback;
  }

  // Hâlâ yükleniyor
  return const AsyncValue.loading();
});

/// Görüntülenmiş story ID'lerini yöneten provider
const _seenStoriesKey = 'seen_story_ids';

class SeenStoryIdsNotifier extends StateNotifier<Set<String>> {
  final SharedPreferences _prefs;

  SeenStoryIdsNotifier(this._prefs) : super({}) {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    final ids = _prefs.getStringList(_seenStoriesKey) ?? [];
    state = ids.toSet();
  }

  /// Story'leri görüntülenmiş olarak işaretle
  Future<void> markAsSeen(List<String> storyIds) async {
    final newState = {...state, ...storyIds};
    state = newState;
    await _prefs.setStringList(_seenStoriesKey, newState.toList());
  }

  /// Tek bir story'yi görüntülenmiş olarak işaretle
  Future<void> markSingleAsSeen(String storyId) async {
    final newState = {...state, storyId};
    state = newState;
    await _prefs.setStringList(_seenStoriesKey, newState.toList());
  }

  /// Tüm geçmişi temizle (debug için)
  Future<void> clearAll() async {
    state = {};
    await _prefs.remove(_seenStoriesKey);
  }
}

final seenStoryIdsProvider =
    StateNotifierProvider<SeenStoryIdsNotifier, Set<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SeenStoryIdsNotifier(prefs);
});

/// Görülmemiş story var mı? (gradyan mı gri mi belirler)
final hasUnseenStoriesProvider = Provider<bool>((ref) {
  final storiesAsync = ref.watch(activeStoriesProvider);
  final seenIds = ref.watch(seenStoryIdsProvider);

  return storiesAsync.when(
    data: (stories) {
      if (stories.isEmpty) return false;
      // En az bir story görülmemişse true
      return stories.any((story) => !seenIds.contains(story.id));
    },
    loading: () => false,
    error: (e, st) => false,
  );
});

/// Story yükleme controller
class StoryUploadController extends StateNotifier<AsyncValue<void>> {
  final StoryRepository _repository;

  StoryUploadController(this._repository)
      : super(const AsyncValue.data(null));

  /// Yeni story yükle
  Future<bool> uploadStory({
    required File imageFile,
    required String authorUid,
    required String authorName,
    String? title,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 1. Görseli Storage'a yükle
      final imageUrl = await _repository.uploadStoryImage(imageFile);

      // 2. Firestore'a story ekle
      final story = StoryModel(
        id: '', // Firestore otomatik oluşturacak
        imageUrl: imageUrl,
        title: title,
        authorUid: authorUid,
        authorName: authorName,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _repository.addStory(story);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Story sil (soft delete)
  Future<void> deleteStory(String storyId) async {
    try {
      await _repository.deleteStory(storyId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final storyUploadControllerProvider =
    StateNotifierProvider<StoryUploadController, AsyncValue<void>>((ref) {
  return StoryUploadController(ref.watch(storyRepositoryProvider));
});
