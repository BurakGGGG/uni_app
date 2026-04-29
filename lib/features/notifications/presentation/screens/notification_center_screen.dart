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
    final unreadAsync = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          unreadAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (unread) {
              if (unread == 0) return const SizedBox();
              return TextButton.icon(
                onPressed: () async {
                  await ref
                      .read(notificationRepositoryProvider)
                      .markAllAsRead();
                },
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text('Tümünü oku'),
              );
            },
          ),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const ShimmerList(itemCount: 5),
        error: (e, _) => ErrorStateWidget(message: '$e'),
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
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderLight,
              indent: 56,
            ),
            itemBuilder: (_, i) =>
                NotificationTile(notification: notifs[i]),
          );
        },
      ),
    );
  }
}
