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
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _Content(initialList: list),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  final PreferenceListModel initialList;
  const _Content({required this.initialList});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Liste güncellendiğinde switch vb. UI anında tepki versin diye
    // güncel listeyi provider üzerinden dinliyoruz.
    final listsAsync = ref.watch(myPreferenceListsProvider);
    final currentList = listsAsync.value?.firstWhere(
      (l) => l.id == initialList.id,
      orElse: () => initialList,
    ) ?? initialList;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Listeyi Paylaş', style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          // Public/Private toggle
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SwitchListTile(
              title: const Text('Herkese açık', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Linke sahip herkes görebilir'),
              value: currentList.isPublic,
              activeTrackColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onChanged: (v) async {
                await ref.read(preferenceListControllerProvider.notifier)
                         .update(currentList.copyWith(isPublic: v));
              },
            ),
          ),

          if (currentList.isPublic) ...[
            const SizedBox(height: 20),
            // Link kart
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      currentList.publicUrl,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: currentList.publicUrl));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bağlantı kopyalandı')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Paylaşım butonları
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () => Share.share(
                  '"${currentList.title}" tercih listemi paylaştım — ${currentList.publicUrl}',
                ),
                icon: const Icon(Icons.share_rounded),
                label: const Text('Bağlantıyı Gönder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              '${currentList.viewCount} görüntülenme',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Listeniz şu anda gizli. Paylaşım bağlantısını alabilmek için listeyi herkese açık hale getirmelisiniz.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
