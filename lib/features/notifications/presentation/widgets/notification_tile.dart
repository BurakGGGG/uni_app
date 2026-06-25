import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/app_notification.dart';
import '../providers/notification_providers.dart';

class NotificationTile extends ConsumerWidget {
  final AppNotification notification;
  final VoidCallback? onDismissed;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: AppColors.error.withValues(alpha: 0.1),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      onDismissed: (_) async {
        await ref
            .read(notificationRepositoryProvider)
            .deleteNotification(notification.id);
        onDismissed?.call();
      },
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.surfaceFor(context)
              : AppColors.primary.withValues(alpha: 0.04),
          border: notification.isRead
              ? null
              : const Border(
                  left: BorderSide(
                    color: AppColors.primary,
                    width: 3,
                  ),
                ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
          onTap: () async {
            // Read olarak işaretle
            if (!notification.isRead) {
              await ref
                  .read(notificationRepositoryProvider)
                  .markAsRead(notification.id);
            }
            // Route'a git
            final route = notification.routePath;
            if (route != null && context.mounted) {
              context.push(route);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: notification.accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.accentColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryFor(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeago.format(notification.createdAt, locale: 'tr'),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiaryFor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
