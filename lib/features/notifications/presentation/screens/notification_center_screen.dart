import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/notification_providers.dart';
import '../widgets/notification_tile.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(myNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Seçenekler',
            onSelected: (val) async {
              if (val == 'mark_all') {
                await ref.read(notificationRepositoryProvider).markAllAsRead();
              } else if (val == 'delete_all') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Tümünü Sil'),
                    content: const Text('Tüm bildirimleri silmek istediğinize emin misiniz?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(notificationRepositoryProvider).deleteAllNotifications();
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all',
                child: Row(children: [Icon(Icons.done_all_rounded, size: 20), SizedBox(width: 8), Text('Tümünü oku')]),
              ),
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(children: [Icon(Icons.delete_sweep_rounded, size: 20, color: AppColors.error), SizedBox(width: 8), Text('Tümünü sil', style: TextStyle(color: AppColors.error))]),
              ),
            ],
          ),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const ShimmerList(itemCount: 5),
        error: (e, stackTrace) => ErrorStateWidget(message: '$e'),
        data: (notifs) {
          if (notifs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: EmptyStateWidget(
                  icon: Icons.notifications_off_outlined,
                  title: 'Bildirim yok',
                  description:
                      'Yorumlarınız beğenildiğinde veya favori üniversitelerinize yorum geldiğinde buradan haberdar olacaksınız.',
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifs.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderLightFor(context),
              indent: 56,
            ),
            itemBuilder: (context, i) =>
                NotificationTile(notification: notifs[i]),
          );
        },
      ),
    );
  }
}
