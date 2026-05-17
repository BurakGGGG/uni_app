import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/story_providers.dart';
import '../screens/story_viewer_screen.dart';
import 'admin_story_upload_sheet.dart';

/// Instagram story halkası gibi ÜniSeç yazısını saran gradient çerçeve.
///
/// - Görülmemiş story varsa: dönen mor→pembe gradyanlı halka
/// - Tüm story'ler görüldüyse: gri halka
/// - Story yoksa: halka yok
/// - Tap → Story viewer açılır (rootNavigator → bottom nav gizlenir)
/// - Long press (admin) → Story ekleme sheet'i açılır
class StoryRing extends ConsumerStatefulWidget {
  final Widget child;

  const StoryRing({super.key, required this.child});

  @override
  ConsumerState<StoryRing> createState() => _StoryRingState();
}

class _StoryRingState extends ConsumerState<StoryRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _startRotationIfNeeded(bool hasUnseen) {
    if (hasUnseen && !_rotationController.isAnimating) {
      _rotationController.repeat();
      // 5 saniye sonra yavaşça dur
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _rotationController.isAnimating) {
          _rotationController.stop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnseen = ref.watch(hasUnseenStoriesProvider);
    final storiesAsync = ref.watch(activeStoriesProvider);
    final stories = storiesAsync.valueOrNull ?? [];
    final hasStories = stories.isNotEmpty;
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isAdmin = currentUser?.isAdmin ?? false;

    // Debug
    if (storiesAsync.hasError) {
      debugPrint('[StoryRing] Stream error: ${storiesAsync.error}');
    }

    // İlk yüklendiğinde gradyan dönsün
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRotationIfNeeded(hasUnseen);
    });

    return GestureDetector(
      onTap: hasStories
          ? () async {
              await Navigator.of(context, rootNavigator: true).push(
                PageRouteBuilder(
                  opaque: true,
                  barrierColor: Colors.black,
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const StoryViewerScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                  reverseTransitionDuration: const Duration(milliseconds: 200),
                ),
              );
              // Viewer kapandığında state güncellensin
              if (mounted) setState(() {});
            }
          : null,
      onLongPress: isAdmin
          ? () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AdminStoryUploadSheet(),
              );
            }
          : null,
      child: _buildRing(context, hasStories, hasUnseen),
    );
  }

  Widget _buildRing(BuildContext context, bool hasStories, bool hasUnseen) {
    if (!hasStories) {
      // Story yoksa sadece içerik
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: widget.child,
      );
    }

    if (hasUnseen) {
      // Dönen mor→pembe gradyanlı halka
      return StoryAnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: SweepGradient(
                colors: const [
                  Color(0xFF8B5CF6), // Mor
                  Color(0xFFEC4899), // Pembe
                  Color(0xFFFF6584), // Sıcak pembe
                  Color(0xFF8B5CF6), // Mor (tekrar - seamless)
                ],
                stops: const [0.0, 0.33, 0.66, 1.0],
                transform:
                    GradientRotation(_rotationController.value * 2 * pi),
              ),
            ),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: widget.child,
          ),
        ),
      );
    } else {
      // Tümü görülmüş — statik gri halka
      return Container(
        padding: const EdgeInsets.all(3.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.isDark(context)
                ? Colors.white.withValues(alpha: 0.25)
                : const Color(0xFFD1D5DB),
            width: 2.5,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: widget.child,
          ),
        ),
      );
    }
  }
}

/// AnimatedBuilder — AnimatedWidget wrapper
class StoryAnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const StoryAnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
