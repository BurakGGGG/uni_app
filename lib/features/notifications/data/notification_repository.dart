import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/models/app_notification.dart';

class NotificationRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore.collection('notifications');

  String? get _currentUserId => _auth.currentUser?.uid;

  /// Kullanıcının bildirimlerini dinle (en yeniden eskiye)
  Stream<List<AppNotification>> watchMyNotifications({int limit = 50}) {
    final uid = _currentUserId;
    if (uid == null) return Stream.value([]);
    return _notificationsRef
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Okunmamış bildirim sayısını dinle
  Stream<int> watchUnreadCount() {
    final uid = _currentUserId;
    if (uid == null) return Stream.value(0);
    return _notificationsRef
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Tek bildirimi okundu olarak işaretle
  Future<void> markAsRead(String notificationId) async {
    await _notificationsRef.doc(notificationId).update({'isRead': true});
  }

  /// Tüm bildirimleri okundu olarak işaretle
  Future<void> markAllAsRead() async {
    final uid = _currentUserId;
    if (uid == null) return;
    final batch = _firestore.batch();
    final unread = await _notificationsRef
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Tek bildirimi sil
  Future<void> deleteNotification(String notificationId) async {
    await _notificationsRef.doc(notificationId).delete();
  }
}
