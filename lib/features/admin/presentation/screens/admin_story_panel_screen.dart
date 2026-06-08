import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../stories/domain/models/story_model.dart';
import '../../../stories/presentation/providers/story_providers.dart';
import '../../../stories/presentation/widgets/admin_story_upload_sheet.dart';

/// Admin Story Yönetim Paneli — tam ekran, tablı.
///
/// Tab 1: Aktif story'ler — arşivle veya kalıcı sil
/// Tab 2: Arşiv — geri yükle veya kalıcı sil
class AdminStoryPanelScreen extends ConsumerStatefulWidget {
  const AdminStoryPanelScreen({super.key});

  @override
  ConsumerState<AdminStoryPanelScreen> createState() =>
      _AdminStoryPanelScreenState();
}

class _AdminStoryPanelScreenState extends ConsumerState<AdminStoryPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allStoriesAsync = ref.watch(allStoriesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        title: Text(
          'Story Yönetimi',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: AppColors.surfaceFor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryFor(context),
          labelStyle: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: 'Aktif'),
            Tab(text: 'Arşiv'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yeni Story'),
      ),
      body: allStoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Story\'ler yüklenirken hata oluştu.',
                  style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(allStoriesStreamProvider),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
        data: (allStories) {
          final active =
              allStories.where((s) => s.isActive).toList();
          final archived =
              allStories.where((s) => !s.isActive).toList();

          return Column(
            children: [
              // ─── İstatistik Özeti ─────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceFor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLightFor(context)),
                ),
                child: Row(
                  children: [
                    _StatBadge(
                      label: 'Toplam',
                      count: allStories.length,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 16),
                    _StatBadge(
                      label: 'Aktif',
                      count: active.length,
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 16),
                    _StatBadge(
                      label: 'Arşiv',
                      count: archived.length,
                      color: const Color(0xFFF59E0B),
                    ),
                    const Spacer(),
                    // Video / Fotoğraf dağılımı
                    Row(
                      children: [
                        Icon(Icons.photo_rounded,
                            size: 14,
                            color: AppColors.textTertiaryFor(context)),
                        const SizedBox(width: 4),
                        Text(
                          '${allStories.where((s) => !s.isVideo).length}',
                          style: AppTextStyles.labelSmall,
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.videocam_rounded,
                            size: 14,
                            color: AppColors.textTertiaryFor(context)),
                        const SizedBox(width: 4),
                        Text(
                          '${allStories.where((s) => s.isVideo).length}',
                          style: AppTextStyles.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ─── Tab İçerikleri ───────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _StoryListTab(
                      stories: active,
                      emptyIcon: Icons.auto_stories_rounded,
                      emptyTitle: 'Henüz aktif story yok',
                      emptySubtitle: 'Yeni story eklemek için + butonunu kullanın.',
                      isActiveTab: true,
                    ),
                    _StoryListTab(
                      stories: archived,
                      emptyIcon: Icons.archive_outlined,
                      emptyTitle: 'Arşivde story yok',
                      emptySubtitle: 'Arşivlenen story\'ler burada görünür.',
                      isActiveTab: false,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AdminStoryUploadSheet(),
    );
  }
}

// ─── Story List Tab ──────────────────────────────────────────────────

class _StoryListTab extends ConsumerWidget {
  final List<StoryModel> stories;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final bool isActiveTab;

  const _StoryListTab({
    required this.stories,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.isActiveTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (stories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, size: 56, color: AppColors.textTertiaryFor(context)),
            const SizedBox(height: 12),
            Text(emptyTitle, style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            Text(
              emptySubtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiaryFor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: stories.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final story = stories[index];
        return _StoryTile(
          story: story,
          isActiveTab: isActiveTab,
        );
      },
    );
  }
}

// ─── Story Tile ──────────────────────────────────────────────────────

class _StoryTile extends ConsumerWidget {
  final StoryModel story;
  final bool isActiveTab;

  const _StoryTile({
    required this.story,
    required this.isActiveTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: story.displayThumbnailUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    memCacheWidth: 112,
                    memCacheHeight: 112,
                    placeholder: (_, _) => Container(
                      width: 56,
                      height: 56,
                      color: AppColors.surfaceVariantFor(context),
                    ),
                    errorWidget: (_, _, _) => Container(
                      width: 56,
                      height: 56,
                      color: AppColors.surfaceVariantFor(context),
                      child: Icon(Icons.broken_image_rounded,
                          size: 20, color: AppColors.textTertiaryFor(context)),
                    ),
                  ),
                ),
                // Video badge
                if (story.isVideo)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.videocam_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // İçerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title ?? 'Başlıksız Story',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        story.authorName,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondaryFor(context),
                        ),
                      ),
                      Text(
                        ' • ',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiaryFor(context),
                        ),
                      ),
                      Text(
                        timeago.format(story.createdAt, locale: 'tr'),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiaryFor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Tip rozeti
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: story.isVideo
                              ? const Color(0xFF8B5CF6).withValues(alpha: 0.12)
                              : AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          story.isVideo ? 'Video' : 'Fotoğraf',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: story.isVideo
                                ? const Color(0xFF8B5CF6)
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      if (!isActiveTab) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Arşivde',
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Aksiyonlar
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: AppColors.textSecondaryFor(context),
                size: 20,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (action) =>
                  _handleAction(context, ref, action),
              itemBuilder: (_) => [
                if (isActiveTab)
                  const PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(Icons.archive_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Arşivle'),
                      ],
                    ),
                  )
                else
                  const PopupMenuItem(
                    value: 'reactivate',
                    child: Row(
                      children: [
                        Icon(Icons.unarchive_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Geri Yükle'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 18, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text('Kalıcı Sil',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'archive':
        _confirmArchive(context, ref);
        break;
      case 'reactivate':
        _reactivate(context, ref);
        break;
      case 'delete':
        _confirmPermanentDelete(context, ref);
        break;
    }
  }

  void _confirmArchive(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Story\'yi Arşivle'),
        content: Text(
          '"${story.title ?? 'Başlıksız Story'}" arşivlenecek. '
          'Kullanıcılar artık göremeyecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(storyUploadControllerProvider.notifier)
                  .archiveStory(story.id);
              _invalidateProviders(ref);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Story arşivlendi'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Arşivle'),
          ),
        ],
      ),
    );
  }

  void _reactivate(BuildContext context, WidgetRef ref) async {
    await ref
        .read(storyUploadControllerProvider.notifier)
        .reactivateStory(story.id);
    _invalidateProviders(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Story tekrar aktifleştirildi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmPermanentDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kalıcı Olarak Sil'),
        content: Text(
          '"${story.title ?? 'Başlıksız Story'}" kalıcı olarak silinecek. '
          'Bu işlem geri alınamaz!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(storyUploadControllerProvider.notifier)
                  .permanentlyDeleteStory(story);
              _invalidateProviders(ref);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Story kalıcı olarak silindi'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _invalidateProviders(WidgetRef ref) {
    ref.invalidate(storiesStreamProvider);
    ref.invalidate(storiesFallbackProvider);
    ref.invalidate(allStoriesStreamProvider);
  }
}

// ─── İstatistik Badge ────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiaryFor(context),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
