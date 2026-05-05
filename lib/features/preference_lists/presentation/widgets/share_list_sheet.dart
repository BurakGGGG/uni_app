import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/preference_list_model.dart';
import '../providers/preference_list_providers.dart';

class ShareListSheet {
  static Future<void> show(BuildContext context, PreferenceListModel list) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _Content(list: list),
    );
  }
}

class _Content extends ConsumerWidget {
  final PreferenceListModel list;
  const _Content({required this.list});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Listeyi Paylaş', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),

          // Public/Private toggle
          SwitchListTile(
            title: const Text('Herkese açık'),
            subtitle: const Text('Linke sahip herkes görebilir'),
            value: list.isPublic,
            onChanged: (v) async {
              await ref.read(preferenceListControllerProvider.notifier)
                       .update(list.copyWith(isPublic: v));
            },
          ),

          if (list.isPublic) ...[
            const SizedBox(height: 16),
            // Link kart
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(list.publicUrl,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: list.publicUrl));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bağlantı kopyalandı')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Paylaşım butonları
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Share.share(
                      '"${list.title}" tercih listemi paylaştım — ${list.publicUrl}',
                    ),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Paylaş'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Text(
              '${list.viewCount} görüntülenme',
              style: AppTextStyles.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}
