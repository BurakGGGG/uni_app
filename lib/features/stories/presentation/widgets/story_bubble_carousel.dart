import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/story_model.dart';
import '../providers/story_providers.dart';
import '../screens/story_viewer_screen.dart';

/// Instagram tarzı yatay kaydırılabilir story bubble carousel.
///
/// - Story yoksa tamamen gizlenir ([SizedBox.shrink])
/// - Görülmemiş story → mor-pembe gradient ring
/// - Görülmüş story → gri ring
/// - Tap → Story anında "seen" işaretlenir, [StoryViewerScreen] açılır
class StoryBubbleCarousel extends ConsumerWidget {
  const StoryBubbleCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(activeStoriesProvider);
    final seenIds = ref.watch(seenStoryIdsProvider);

    return storiesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (stories) {
        if (stories.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 108,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              final isSeen = seenIds.contains(story.id);

              return _StoryBubble(
                story: story,
                isSeen: isSeen,
                onTap: () {
                  // Anında "seen" işaretle — geri dönünce ring gri olsun
                  ref
                      .read(seenStoryIdsProvider.notifier)
                      .markSingleAsSeen(story.id);

                  Navigator.of(context, rootNavigator: true).push(
                    PageRouteBuilder(
                      opaque: true,
                      barrierColor: Colors.black,
                      pageBuilder:
                          (context, animation, secondaryAnimation) =>
                              StoryViewerScreen(initialIndex: index),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 300),
                      reverseTransitionDuration:
                          const Duration(milliseconds: 200),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

/// Tek bir story bubble — daire thumbnail + altında etiket.
class _StoryBubble extends StatelessWidget {
  final StoryModel story;
  final bool isSeen;
  final VoidCallback onTap;

  const _StoryBubble({
    required this.story,
    required this.isSeen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Gradient/Gri Ring + Avatar ───────────────────
            _buildRingAvatar(context),
            const SizedBox(height: 6),
            // ─── Etiket ──────────────────────────────────────
            Text(
              story.title ?? 'Duyuru',
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 11,
                color: AppColors.textSecondaryFor(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRingAvatar(BuildContext context) {
    const double outerSize = 76;
    const double ringWidth = 3.0;
    const double innerPadding = 2.5;
    const double avatarSize = outerSize - (ringWidth + innerPadding) * 2;

    if (isSeen) {
      // ─── Görülmüş: Gri border ──────────────────────────
      return Container(
        width: outerSize,
        height: outerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.isDark(context)
                ? Colors.white.withValues(alpha: 0.2)
                : const Color(0xFFD1D5DB),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(innerPadding),
          child: _buildAvatar(avatarSize),
        ),
      );
    }

    // ─── Görülmemiş: Gradient ring ──────────────────────
    return Container(
      width: outerSize,
      height: outerSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            Color(0xFF8B5CF6), // Mor
            Color(0xFFEC4899), // Pembe
            Color(0xFFFF6584), // Sıcak pembe
            Color(0xFF8B5CF6), // Mor (seamless)
          ],
          stops: [0.0, 0.33, 0.66, 1.0],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(ringWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceFor(context),
        ),
        child: Padding(
          padding: const EdgeInsets.all(innerPadding - 0.5),
          child: _buildAvatar(avatarSize),
        ),
      ),
    );
  }

  Widget _buildAvatar(double size) {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: story.displayThumbnailUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: 160,
        memCacheHeight: 160,
        placeholder: (context, url) => Container(
          color: AppColors.surfaceVariantFor(context),
          child: Center(
            child: Icon(
              Icons.auto_stories_rounded,
              size: 22,
              color: AppColors.textTertiaryFor(context),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppColors.surfaceVariantFor(context),
          child: Center(
            child: Icon(
              Icons.broken_image_rounded,
              size: 22,
              color: AppColors.textTertiaryFor(context),
            ),
          ),
        ),
      ),
    );
  }
}
