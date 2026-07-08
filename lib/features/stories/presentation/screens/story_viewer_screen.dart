import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../../../core/theme/app_text_styles.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/story_providers.dart';
import '../../domain/models/story_model.dart';
import '../../../admin/data/analytics_service.dart';
import '../../../admin/domain/models/analytics_event.dart';
import '../../../monetization/presentation/providers/subscription_providers.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/data/ad_service.dart';

/// Tam ekran Story görüntüleyici — fotoğraf + video destekli.
///
/// - Sağ üstte çarpı (X) ile kapatılır
/// - Sağa/sola dokunarak story'ler arasında gezilir
/// - Üstte doğrusal ilerleme çubuğu
/// - Basılı tutunca ilerleme durur
/// - Video: otomatik oynatılır, sessiz başlar, tap ile ses aç/kapa
/// - Kapanışta görülen story'ler işaretlenir
class StoryViewerScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const StoryViewerScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  final List<String> _viewedIds = [];
  late AnimationController _progressController;
  bool _isPaused = false;
  bool _isMediaLoaded = false;
  bool _isMuted = true;
  int _storiesViewedCount = 0;

  // Video player (null ise image story)
  VideoPlayerController? _videoController;

  static const _imageDuration = Duration(seconds: 6);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _progressController = AnimationController(
      vsync: this,
      duration: _imageDuration,
    )..addStatusListener((status) {
        // Controller dispose sırasında da tetiklenebilir; ref/setState
        // kullanan _nextStory yalnızca widget hayattayken çağrılmalı.
        if (status == AnimationStatus.completed && mounted) {
          _nextStory();
        }
      });

    // Preload interstitial ad for story viewer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final showAds = ref.read(subscriptionTierProvider).valueOrNull == SubscriptionTier.free;
      if (showAds) {
        AdService().preloadInterstitialAd();
      }
    });
  }

  @override
  void dispose() {
    // Not: görülen story'ler _markCurrentViewed içinde anlık olarak
    // kaydedildiği için burada ref kullanmaya gerek yok (dispose sırasında
    // ref erişimi "Cannot use ref after dispose" crash'i üretiyordu).
    _progressController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _startProgress() {
    _progressController.reset();
    if (_isMediaLoaded && !_isPaused) {
      _videoController?.play();
      _progressController.forward();
    }
  }

  void _pauseProgress() {
    if (!_isPaused) {
      _isPaused = true;
      _progressController.stop();
      _videoController?.pause();
    }
  }

  void _resumeProgress() {
    if (_isPaused && _isMediaLoaded) {
      _isPaused = false;
      _videoController?.play();
      _progressController.forward();
    }
  }

  void _nextStory() async {
    if (!mounted) return;
    final stories = ref.read(activeStoriesProvider).valueOrNull ?? [];
    if (_currentIndex < stories.length - 1) {
      final showAds = ref.read(subscriptionTierProvider).valueOrNull == SubscriptionTier.free;
      if (showAds) {
        _storiesViewedCount++;
        if (_storiesViewedCount >= 3) {
          _storiesViewedCount = 0;
          _pauseProgress();
          await AdService().showInterstitialAd();
          // Resume progress if still mounted
          if (mounted && _isPaused) {
            _resumeProgress();
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _currentIndex++;
        _isMediaLoaded = false;
      });
      _markCurrentViewed(stories);
      _initializeMedia(stories[_currentIndex]);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      final stories = ref.read(activeStoriesProvider).valueOrNull ?? [];
      setState(() {
        _currentIndex--;
        _isMediaLoaded = false;
      });
      _initializeMedia(stories[_currentIndex]);
    } else {
      _startProgress();
    }
  }

  void _markCurrentViewed(List<StoryModel> stories) {
    if (_currentIndex < stories.length) {
      final id = stories[_currentIndex].id;
      if (!_viewedIds.contains(id)) {
        _viewedIds.add(id);
        ref.read(seenStoryIdsProvider.notifier).markSingleAsSeen(id);

        // Analytics: story görüntülendi
        AnalyticsService.instance.trackEvent(AnalyticsEvent.storyViewed);
      }
    }
  }

  /// Video story için controller'ı başlat, image story için temizle
  Future<void> _initializeMedia(StoryModel story) async {
    _videoController?.dispose();
    _videoController = null;

    if (story.isVideo && story.videoUrl != null) {
      try {
        // Video dosyasını cache'den al veya indir
        final fileInfo = await DefaultCacheManager().getFileFromCache(story.videoUrl!);
        File videoFile;
        
        if (fileInfo != null) {
          videoFile = fileInfo.file;
        } else {
          // Cache'de yoksa indirir ve kaydeder
          videoFile = await DefaultCacheManager().getSingleFile(story.videoUrl!);
        }

        // İndirme süresince kullanıcı başka story'ye geçtiyse işlemi iptal et
        if (!mounted || _currentIndex != ref.read(activeStoriesProvider).valueOrNull?.indexOf(story)) {
          return;
        }

        final controller = VideoPlayerController.file(videoFile);
        _videoController = controller;

        await controller.initialize();
        if (!mounted) return;

        final videoDuration = controller.value.duration;
        _progressController.duration = videoDuration.inMilliseconds > 0
            ? videoDuration
            : story.mediaDuration;

        controller.setVolume(_isMuted ? 0.0 : 1.0);
        // Fotoğraf story'lerde olduğu gibi süre, medya hazır olunca başlar
        setState(() => _isMediaLoaded = true);
        _startProgress();
      } catch (e) {
        debugPrint('[StoryViewer] Video init/cache error: $e');
        if (!mounted) return;
        // Hata durumunda image gibi davran ki sonsuz yüklemede kalmasın
        setState(() => _isMediaLoaded = true);
        _progressController.duration = _imageDuration;
        _startProgress();
      }
    } else {
      _progressController.duration = _imageDuration;
      // Image yükleme imageBuilder callback'inde yapılır
    }
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _videoController?.setVolume(_isMuted ? 0.0 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final storiesAsync = ref.watch(activeStoriesProvider);

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: storiesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Hata: $e',
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kapat',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          data: (stories) {
            if (stories.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pop();
              });
              return const SizedBox.shrink();
            }

            // İlk açılışta
            if (_viewedIds.isEmpty) {
              _markCurrentViewed(stories);
              _initializeMedia(stories[_currentIndex]);
            }

            if (_currentIndex >= stories.length) {
              _currentIndex = stories.length - 1;
            }

            final story = stories[_currentIndex];

            return GestureDetector(
              onTapUp: (details) {
                final screenWidth = MediaQuery.of(context).size.width;
                if (details.globalPosition.dx < screenWidth / 3) {
                  _previousStory();
                } else {
                  _nextStory();
                }
              },
              onLongPressStart: (_) => _pauseProgress(),
              onLongPressEnd: (_) => _resumeProgress(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ─── Medya İçeriği ──────────────────────────
                  if (story.isVideo)
                    _buildVideoContent(story)
                  else
                    _buildImageContent(story),

                  // ─── Üst Gradyan ────────────────────────────
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 160,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black54, Colors.transparent],
                        ),
                      ),
                    ),
                  ),

                  // ─── Alt Gradyan (başlık varsa) ────────────
                  if (story.title != null && story.title!.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 160,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black87, Colors.transparent],
                          ),
                        ),
                      ),
                    ),

                  // ─── İlerleme Çubukları ─────────────────────
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: List.generate(stories.length, (index) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: index == 0 ? 0 : 2,
                              right: index == stories.length - 1 ? 0 : 2,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: _StoryAnimatedBuilder(
                                animation: _progressController,
                                builder: (context) {
                                  double value;
                                  if (index < _currentIndex) {
                                    value = 1.0;
                                  } else if (index == _currentIndex) {
                                    value = _progressController.value;
                                  } else {
                                    value = 0.0;
                                  }
                                  return LinearProgressIndicator(
                                    value: value,
                                    minHeight: 2.5,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.3),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // ─── Üst Bilgi Satırı ──────────────────────
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 20,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: story.authorPhotoUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: story.authorPhotoUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[800],
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.person,
                                        color: Colors.white, size: 20),
                                  ),
                                )
                              : Container(
                                  color: Colors.white,
                                  child: Transform.scale(
                                    scale: 1.35,
                                    child: Image.asset(
                                      'assets/icons/unisec-icon-ink-192.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 10),
                        // Ad + zaman
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                story.authorName,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                timeago.format(story.createdAt, locale: 'tr'),
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        // Video ise ses butonu
                        if (story.isVideo)
                          Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: IconButton(
                              onPressed: _toggleMute,
                              tooltip: _isMuted ? 'Sesi aç' : 'Sesi kapat',
                              icon: Icon(
                                _isMuted
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        // Kapatma butonu
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Kapat',
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ─── Alt Başlık ─────────────────────────────
                  if (story.title != null && story.title!.isNotEmpty)
                    Positioned(
                      bottom: MediaQuery.of(context).padding.bottom + 32,
                      left: 20,
                      right: 20,
                      child: Text(
                        story.title!,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                          shadows: [
                            const Shadow(color: Colors.black45, blurRadius: 8),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Fotoğraf story'si gösterir
  Widget _buildImageContent(StoryModel story) {
    return Center(
      child: CachedNetworkImage(
        imageUrl: story.imageUrl,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        imageBuilder: (context, imageProvider) {
          if (!_isMediaLoaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isMediaLoaded) {
                setState(() => _isMediaLoaded = true);
                _startProgress();
              }
            });
          }
          return Image(
            image: imageProvider,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          );
        },
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.broken_image_rounded,
              color: Colors.white54, size: 64),
        ),
      ),
    );
  }

  /// Video story'si gösterir
  Widget _buildVideoContent(StoryModel story) {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      );
    }

    final controller = _videoController!;
    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: VideoPlayer(controller),
      ),
    );
  }
}

/// AnimatedBuilder — AnimatedWidget wrapper
class _StoryAnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context) builder;

  const _StoryAnimatedBuilder({
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context);
  }
}
