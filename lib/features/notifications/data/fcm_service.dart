import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Background message handler — top-level fonksiyon olmalı
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background'da çalışır. Burada heavy iş yapma — sadece log.
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class FCMService {
  static final FCMService _instance = FCMService._();
  factory FCMService() => _instance;
  FCMService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotif = FlutterLocalNotificationsPlugin();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  bool _initialized = false;

  /// On-tap callback — main.dart'ta GoRouter ile bind edilir
  void Function(Map<String, dynamic> data)? onNotificationTap;

  Future<void> init() async {
    try {
      if (_initialized) return;
      _initialized = true;

      // 1. Background handler register
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 2. Local notifications init (foreground gösterimi için)
      await _initLocalNotifications();

      // 3. Permission iste
      await requestPermission();

      // 4. Foreground listener
      _foregroundSub = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );

      // 5. Token refresh listener
      _tokenRefreshSub = _messaging.onTokenRefresh.listen(
        _saveTokenToFirestore,
      );

      // 6. Notification tap (background → foreground) listener
      _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(
        _handleMessageOpenedApp,
      );

      // 7. Eğer uygulama notification ile cold-start ediliyorsa
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      // 8. Zaten giriş yapmış kullanıcı varsa token'ı kaydet
      if (_auth.currentUser != null) {
        registerToken();
      }

      debugPrint('[FCM] Service initialized');
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'fcm_init_error',
        fatal: false,
      );
      rethrow;
    }
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@drawable/ic_notification');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false, // FCM ile zaten istiyoruz
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const init = InitializationSettings(android: android, iOS: ios);

    await _localNotif.initialize(
      init,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          onNotificationTap?.call({'route': details.payload});
        }
      },
    );

    // Android için kanal oluştur
    const channel = AndroidNotificationChannel(
      'default_channel_id',
      'Genel Bildirimler',
      description: 'ÜniSeç bildirimleri',
      importance: Importance.high,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android 13+ için POST_NOTIFICATIONS izni
      final status = await Permission.notification.request();
      return status.isGranted;
    }

    // iOS
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> registerToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // getToken() cihazda Play Services yoksa ya da geçici olarak ağ/servis
      // erişilemezse atar (java.io.IOException: SERVICE_NOT_AVAILABLE). Bu
      // kritik değil — token bir sonraki açılışta yeniden denenir; çökmemeli.
      final token = await _messaging.getToken();
      if (token == null) return;

      await _saveTokenToFirestore(token);
    } catch (e) {
      debugPrint('[FCM] registerToken atlandı: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(_tokenDocId(token))
          .set({
            'token': token,
            'platform': defaultTargetPlatform.name,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      debugPrint('[FCM] Token saved: ${token.substring(0, 20)}...');
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'fcm_saveTokenToFirestore_error',
        fatal: false,
      );
      rethrow;
    }
  }

  /// Logout sırasında çağrılır
  Future<void> unregisterToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('fcmTokens')
        .doc(_tokenDocId(token))
        .delete();

    await _messaging.deleteToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('[FCM] Subscribed to: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('[FCM] Unsubscribed from: $topic');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    // Foreground'da OS bildirimi göstermez — local_notifications ile gösteriyoruz
    _localNotif.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel_id',
          'Genel Bildirimler',
          channelDescription: 'ÜniSeç bildirimleri',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['route'] as String?,
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.messageId}');
    onNotificationTap?.call(message.data);
  }

  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _tokenRefreshSub?.cancel();
    await _onMessageOpenedSub?.cancel();
  }

  String _tokenDocId(String token) {
    return base64Url.encode(utf8.encode(token));
  }
}
