import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/story_providers.dart';
import '../screens/story_viewer_screen.dart';
import 'admin_story_upload_sheet.dart';

/// Instagram story halkası gibi ÜniSeç yazısını saran gradient çerçeve.
///
/// - Görülmemiş story varsa: mor→pembe gradyanlı halka
/// - Tüm story'ler görüldüyse: gri halka
/// - Story yoksa: halka yok
/// - Tap → Story viewer açılır
/// - Long press (admin) → Story ekleme sheet'i açılır
class StoryRing extends ConsumerWidget {
  final Widget child;

  const StoryRing({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnseen = ref.watch(hasUnseenStoriesProvider);
    final storiesAsync = ref.watch(activeStoriesProvider);
    final stories = storiesAsync.valueOrNull ?? [];
    final hasStories = stories.isNotEmpty;
    final isLoading = storiesAsync.isLoading;
    final hasError = storiesAsync.hasError;
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isAdmin = currentUser?.isAdmin ?? false;

    // Debug: hata varsa logla
    if (hasError) {
      debugPrint('[StoryRing] Stream error: ${storiesAsync.error}');
    }

    return GestureDetector(
      onTap: hasStories
          ? () {
              Navigator.of(context).push(
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
      child: Container(
        decoration: _buildDecoration(hasStories, hasUnseen, isLoading, context),
        padding: hasStories || isLoading ? const EdgeInsets.all(3.5) : null,
        child: Container(
          padding: hasStories || isLoading ? const EdgeInsets.all(3.0) : null,
          decoration: hasStories || isLoading
              ? BoxDecoration(
                  color: AppColors.surfaceFor(context),
                  borderRadius: BorderRadius.circular(14),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: child,
          ),
        ),
      ),
    );
  }

  BoxDecoration? _buildDecoration(
    bool hasStories,
    bool hasUnseen,
    bool isLoading,
    BuildContext context,
  ) {
    if (!hasStories && !isLoading) return null;

    if (hasUnseen) {
      // Mor → Pembe gradyanlı halka
      return BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B5CF6), // Mor
            Color(0xFFEC4899), // Pembe
            Color(0xFFFF6584), // Sıcak pembe
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      );
    } else {
      // Tümü görülmüş veya yükleniyor — gri halka
      return BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.isDark(context)
              ? Colors.white.withValues(alpha: 0.25)
              : const Color(0xFFD1D5DB),
          width: 2.5,
        ),
      );
    }
  }
}
