import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/story_model.dart';
import '../presentation/providers/story_providers.dart';

/// Story listesi ve medya dosyalarını uygulama açılışında arka planda yükler.
class StoryPrefetchService {
  StoryPrefetchService._();

  static bool _started = false;
  static final Set<String> _prefetchedUrls = {};

  /// Splash sırasında bir kez tetiklenir; navigasyonu bloklamaz.
  static void warmUp(WidgetRef ref) {
    if (_started) return;
    _started = true;
    unawaited(_warmUp(ref));
  }

  static Future<void> _warmUp(WidgetRef ref) async {
    try {
      final stories = await ref.read(storiesStreamProvider.future);
      await prefetchMedia(stories);
    } catch (e) {
      debugPrint('[StoryPrefetch] Warm-up failed: $e');
    }
  }

  /// Thumbnail, fotoğraf ve video URL'lerini disk önbelleğine indirir.
  static Future<void> prefetchMedia(List<StoryModel> stories) async {
    if (stories.isEmpty) return;

    final cache = DefaultCacheManager();
    final urls = <String>{};

    for (final story in stories) {
      final thumbnailUrl = story.displayThumbnailUrl;
      if (thumbnailUrl.isNotEmpty) {
        urls.add(thumbnailUrl);
      }

      if (story.isVideo &&
          story.videoUrl != null &&
          story.videoUrl!.isNotEmpty) {
        urls.add(story.videoUrl!);
      } else if (story.imageUrl.isNotEmpty) {
        urls.add(story.imageUrl);
      }
    }

    await Future.wait(
      urls.map((url) async {
        if (_prefetchedUrls.contains(url)) return;
        _prefetchedUrls.add(url);

        try {
          await cache.downloadFile(url);
        } catch (e) {
          debugPrint('[StoryPrefetch] Failed to cache $url: $e');
        }
      }),
    );
  }
}
