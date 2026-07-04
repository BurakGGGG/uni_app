import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/notification_repository.dart';
import '../../domain/models/app_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// Kullanıcının bildirimleri — auth durumuna bağlıdır; login/logout'ta
/// stream doğru uid ile yeniden kurulur.
final myNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  ref.keepAlive();
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(const <AppNotification>[]);
      return ref.watch(notificationRepositoryProvider).watchMyNotifications();
    },
    loading: () => Stream.value(const <AppNotification>[]),
    error: (_, _) => Stream.value(const <AppNotification>[]),
  );
});

/// Okunmamış bildirim sayısı — auth durumuna bağlıdır.
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  ref.keepAlive();
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(0);
      return ref.watch(notificationRepositoryProvider).watchUnreadCount();
    },
    loading: () => Stream.value(0),
    error: (_, _) => Stream.value(0),
  );
});
