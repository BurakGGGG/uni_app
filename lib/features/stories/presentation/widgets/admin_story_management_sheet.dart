import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/story_model.dart';
import '../providers/story_providers.dart';

/// Admin kullanıcıların aktif story'lerini görüp silebileceği bottom sheet.
class AdminStoryManagementSheet extends ConsumerWidget {
  const AdminStoryManagementSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(activeStoriesProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderFor(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Başlık
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.view_carousel_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Aktif Story\'ler',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // İçerik
          Flexible(
            child: storiesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'Story\'ler yüklenirken hata oluştu.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ),
              data: (stories) {
                if (stories.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_stories_rounded,
                          size: 48,
                          color: AppColors.textTertiaryFor(context),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Henüz aktif story yok',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.textSecondaryFor(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Yeni story eklemek için geri dönüp\n"Yeni Story Ekle" seçeneğini kullanın.',
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
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: stories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final story = stories[index];
                    return _StoryManagementTile(story: story);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryManagementTile extends ConsumerWidget {
  final StoryModel story;

  const _StoryManagementTile({required this.story});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundFor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: story.imageUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            memCacheWidth: 96,
            memCacheHeight: 96,
            placeholder: (_, _) => Container(
              width: 48,
              height: 48,
              color: AppColors.surfaceVariantFor(context),
            ),
            errorWidget: (_, _, _) => Container(
              width: 48,
              height: 48,
              color: AppColors.surfaceVariantFor(context),
              child: Icon(
                Icons.broken_image_rounded,
                size: 20,
                color: AppColors.textTertiaryFor(context),
              ),
            ),
          ),
        ),
        title: Text(
          story.title ?? 'Başlıksız Story',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          timeago.format(story.createdAt, locale: 'tr'),
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiaryFor(context),
          ),
        ),
        trailing: IconButton(
          onPressed: () => _confirmDelete(context, ref, story),
          icon: Icon(
            Icons.delete_outline_rounded,
            color: AppColors.error.withValues(alpha: 0.7),
            size: 22,
          ),
          tooltip: 'Story\'yi sil',
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, StoryModel story) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Story\'yi Sil'),
        content: Text(
          '"${story.title ?? 'Başlıksız Story'}" silinecek. Emin misiniz?',
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
                  .deleteStory(story.id);
              // Provider'ları invalidate et
              ref.invalidate(storiesStreamProvider);
              ref.invalidate(storiesFallbackProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Story silindi ✓'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text(
              'Sil',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
