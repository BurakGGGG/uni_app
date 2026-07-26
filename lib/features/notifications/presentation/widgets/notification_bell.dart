import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/notification_providers.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadNotificationCountProvider);
    final unread = unreadAsync.value ?? 0;

    return GestureDetector(
      onLongPress: () => _showQuickActions(context, ref),
      child: IconButton(
        onPressed: () {
          final user = ref.read(authStateProvider).value;
          if (user == null) {
            // SnackBar bu widget'tan uzun yaşayabilir; aksiyona basıldığında
            // context ölü olabileceği için router'ı şimdiden yakala.
            final router = GoRouter.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Bildirimleri görmek için giriş yapın'),
                // Eylemli SnackBar'ın Flutter varsayılanı kalıcı olmak.
                persist: false,
                action: SnackBarAction(
                  label: 'Giriş Yap',
                  onPressed: () => router.push('/login?from=/notifications'),
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          context.push('/notifications');
        },
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              unread > 0
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_outlined,
              color: AppColors.textPrimaryFor(context),
              size: 24,
            ),
            if (unread > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.surfaceFor(context), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unread > 99 ? '99+' : unread.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
        tooltip: 'Bildirimler',
      ),
    );
  }

  void _showQuickActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.done_all_rounded),
            title: const Text('Tümünü okundu işaretle'),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(notificationRepositoryProvider).markAllAsRead();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Bildirim Ayarları'),
            onTap: () {
              Navigator.pop(context);
              context.push('/notification-settings');
            },
          ),
        ],
      ),
    );
  }
}
