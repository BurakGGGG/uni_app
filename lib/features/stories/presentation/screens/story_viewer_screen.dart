import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/story_providers.dart';
import '../../domain/models/story_model.dart';
import '../widgets/story_ring.dart';

/// Tam ekran Story görüntüleyici.
///
/// - Sağ üstte çarpı (X) ile kapatılır
/// - Android geri tuşuyla kapatılır
/// - Sağa/sola dokunarak story'ler arasında gezilir
/// - Üstte doğrusal ilerleme çubuğu
/// - Basılı tutunca ilerleme durur
/// - Kapanışta görülen story'ler işaretlenir
class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({super.key});

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final List<String> _viewedIds = [];
  late AnimationController _progressController;
  bool _isPaused = false;

  static const _storyDuration = Duration(seconds: 6);

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextStory();
        }
      });
  }

  @override
  void dispose() {
    // Güvenlik: dispose'da da kaydet
    if (_viewedIds.isNotEmpty) {
      ref.read(seenStoryIdsProvider.notifier).markAsSeen(_viewedIds);
    }
    _progressController.dispose();
    super.dispose();
  }

  void _startProgress() {
    _progressController.reset();
    _progressController.forward();
  }

  void _pauseProgress() {
    if (!_isPaused) {
      _isPaused = true;
      _progressController.stop();
    }
  }

  void _resumeProgress() {
    if (_isPaused) {
      _isPaused = false;
      _progressController.forward();
    }
  }

  void _nextStory() {
    final stories = ref.read(activeStoriesProvider).valueOrNull ?? [];
    if (_currentIndex < stories.length - 1) {
      setState(() => _currentIndex++);
      _markCurrentViewed(stories);
      _startProgress();
    } else {
      // Son story — kapat
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _startProgress();
    } else {
      // İlk story'deyken sola basınca baştan başla
      _startProgress();
    }
  }

  void _markCurrentViewed(List<StoryModel> stories) {
    if (_currentIndex < stories.length) {
      final id = stories[_currentIndex].id;
      if (!_viewedIds.contains(id)) {
        _viewedIds.add(id);
        // İzlenen story'yi hemen kaydet — griye dönmesi için
        ref.read(seenStoryIdsProvider.notifier).markSingleAsSeen(id);
      }
    }
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

            // İlk açılışta ilk story'yi görüntülenmiş say
            if (_viewedIds.isEmpty) {
              _markCurrentViewed(stories);
              _startProgress();
            }

            // Güvenlik: index sınır dışı kontrolü
            if (_currentIndex >= stories.length) {
              _currentIndex = stories.length - 1;
            }

            final story = stories[_currentIndex];

            return GestureDetector(
              // Sağa/sola dokunma
              onTapUp: (details) {
                final screenWidth = MediaQuery.of(context).size.width;
                if (details.globalPosition.dx < screenWidth / 3) {
                  _previousStory();
                } else {
                  _nextStory();
                }
              },
              // Basılı tutunca durdur
              onLongPressStart: (_) => _pauseProgress(),
              onLongPressEnd: (_) => _resumeProgress(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ─── Story Görseli ──────────────────────────
                  Center(
                    child: CachedNetworkImage(
                      imageUrl: story.imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: Colors.white54,
                          size: 64,
                        ),
                      ),
                    ),
                  ),

                  // ─── Üst Gradyan (bilgi okunabilirliği) ────
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
                          colors: [
                            Colors.black54,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ─── Alt Gradyan (başlık okunabilirliği) ───
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
                            colors: [
                              Colors.black87,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                  // ─── İlerleme Çubukları ────────────────────
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
                              child: StoryAnimatedBuilder(
                                animation: _progressController,
                                builder: (context, child) {
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

                  // ─── Üst Bilgi Satırı ─────────────────────
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 20,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        // Admin avatar
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.heroGradient,
                          ),
                          child: Center(
                            child: Text(
                              story.authorName.isNotEmpty
                                  ? story.authorName[0].toUpperCase()
                                  : 'A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Admin adı + zaman
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
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Kapatma butonu
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
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

                  // ─── Alt Başlık ────────────────────────────
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
                            const Shadow(
                              color: Colors.black45,
                              blurRadius: 8,
                            ),
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
}
