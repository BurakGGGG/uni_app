import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_compress/video_compress.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../data/story_repository.dart';
import '../../domain/models/story_model.dart';

/// StoryRepository provider
final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepository();
});

/// Aktif story'leri tek seferlik okur ve kısa süre cache'ler.
///
/// Not: Adı eski invalidation noktalarıyla uyumluluk için korunuyor.
final storiesStreamProvider = FutureProvider.autoDispose<List<StoryModel>>((
  ref,
) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(() => timer.cancel());

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
  return ref.watch(storiesStreamProvider);
});

/// Tüm story'leri dinler (aktif + arşiv — admin panel için)
final allStoriesStreamProvider = StreamProvider<List<StoryModel>>((ref) {
  return ref.watch(storyRepositoryProvider).getAllStories();
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

/// Story yükleme controller — fotoğraf + video destekli
class StoryUploadController extends StateNotifier<AsyncValue<void>> {
  final StoryRepository _repository;

  StoryUploadController(this._repository) : super(const AsyncValue.data(null));

  /// Yeni fotoğraf story'si yükle
  Future<bool> uploadImageStory({
    required File imageFile,
    required File thumbnailFile,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
    String? title,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Görselleri Storage'a yükle (paralel)
      final results = await Future.wait([
        _repository.uploadStoryImage(imageFile),
        _repository.uploadStoryThumbnail(thumbnailFile),
      ]);
      final imageUrl = results[0];
      final thumbnailUrl = results[1];

      final story = StoryModel(
        id: '',
        imageUrl: imageUrl,
        thumbnailUrl: thumbnailUrl,
        mediaType: 'image',
        title: title,
        authorUid: authorUid,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _repository.addStory(story);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      debugPrint('[StoryUpload] Upload failed: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Yeni video story'si yükle (1080p sıkıştırma)
  Future<bool> uploadVideoStory({
    required File videoFile,
    required File thumbnailFile,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
    String? title,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 1. Video'yu 1080p'ye sıkıştır
      debugPrint('[StoryUpload] Compressing video to 1080p...');
      final compressedInfo = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.Res1920x1080Quality,
        deleteOrigin: false,
        includeAudio: true,
      );

      final compressedFile = compressedInfo?.file;
      if (compressedFile == null) {
        throw Exception('Video sıkıştırma başarısız oldu');
      }

      final videoDurationMs = (compressedInfo!.duration ?? 6000).toInt();

      // 2. Paralel upload: sıkıştırılmış video + kapak
      final results = await Future.wait([
        _repository.uploadStoryVideo(compressedFile),
        _repository.uploadStoryThumbnail(thumbnailFile),
      ]);
      final videoUrl = results[0];
      final thumbnailUrl = results[1];

      // 3. Firestore'a story ekle
      final story = StoryModel(
        id: '',
        imageUrl: thumbnailUrl, // poster image = thumbnail
        thumbnailUrl: thumbnailUrl,
        videoUrl: videoUrl,
        mediaType: 'video',
        mediaDurationMs: videoDurationMs,
        title: title,
        authorUid: authorUid,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _repository.addStory(story);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      debugPrint('[StoryUpload] Video upload failed: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Story arşivle (soft delete)
  Future<void> archiveStory(String storyId) async {
    try {
      await _repository.archiveStory(storyId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Story'yi tekrar aktifleştir
  Future<void> reactivateStory(String storyId) async {
    try {
      await _repository.reactivateStory(storyId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Story'yi kalıcı olarak sil
  Future<void> permanentlyDeleteStory(StoryModel story) async {
    try {
      await _repository.permanentlyDeleteStory(
        story.id,
        imageUrl: story.imageUrl,
        thumbnailUrl: story.thumbnailUrl,
        videoUrl: story.videoUrl,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final storyUploadControllerProvider =
    StateNotifierProvider<StoryUploadController, AsyncValue<void>>((ref) {
      return StoryUploadController(ref.watch(storyRepositoryProvider));
    });
