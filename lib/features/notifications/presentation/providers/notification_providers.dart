import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/notification_repository.dart';
import '../../domain/models/app_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// Kullanıcının tüm bildirimleri (stream)
final myNotificationsProvider =
    StreamProvider<List<AppNotification>>((ref) {
  ref.keepAlive();
  return ref.watch(notificationRepositoryProvider).watchMyNotifications();
});

/// Okunmamış bildirim sayısı (stream)
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  ref.keepAlive();
  return ref.watch(notificationRepositoryProvider).watchUnreadCount();
});
