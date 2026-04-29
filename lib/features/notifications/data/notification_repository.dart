import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/models/app_notification.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  
  NotificationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;
  
  CollectionReference<Map<String, dynamic>> get _notifsRef =>
      _firestore.collection('notifications');
  
  Stream<List<AppNotification>> watchMyNotifications({int limit = 50}) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    
    return _notifsRef
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotification.fromMap(d.data(), d.id))
            .toList());
  }
  
  Stream<int> watchUnreadCount() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);
    
    return _notifsRef
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.size);
  }
  
  Future<void> markAsRead(String notifId) async {
    await _notifsRef.doc(notifId).update({'isRead': true});
  }
  
  Future<void> markAllAsRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    final snap = await _notifsRef
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .limit(100)
        .get();
    
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
  
  Future<void> deleteNotification(String notifId) async {
    await _notifsRef.doc(notifId).delete();
  }
}
