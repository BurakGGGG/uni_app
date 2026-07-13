import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/user_model.dart';
import '../../data/fcm_service.dart';

class NotificationPreferencesNotifier 
    extends StateNotifier<AsyncValue<NotificationPreferences>> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  
  NotificationPreferencesNotifier({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        super(const AsyncValue.loading()) {
    _load();
  }
  
  Future<void> _load() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      state = AsyncValue.data(const NotificationPreferences());
      return;
    }
    
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final prefsMap = doc.data()?['notificationPrefs'] as Map<String, dynamic>?;
      state = AsyncValue.data(NotificationPreferences.fromMap(prefsMap));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> toggle(String key, bool value) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    final current = state.value ?? const NotificationPreferences();
    
    // Optimistic update
    NotificationPreferences updated;
    switch (key) {
      case 'reviewLikedEnabled':
        updated = current.copyWith(reviewLikedEnabled: value);
        break;
      case 'reviewModeratedEnabled':
        updated = current.copyWith(reviewModeratedEnabled: value);
        break;
      case 'favoriteNewReviewEnabled':
        updated = current.copyWith(favoriteNewReviewEnabled: value);
        break;
      case 'reviewCampaignEnabled':
        updated = current.copyWith(reviewCampaignEnabled: value);
        break;
      default:
        return;
    }
    
    state = AsyncValue.data(updated);
    
    try {
      // Firestore'a yaz
      await _firestore.collection('users').doc(uid).set({
        'notificationPrefs': updated.toMap(),
      }, SetOptions(merge: true));
      
      // Topic subscriptions: favoriteNewReviewEnabled değiştiyse
      if (key == 'favoriteNewReviewEnabled') {
        await _resubscribeAllFavorites(uid, subscribe: value);
      }
    } catch (e) {
      // Revert
      state = AsyncValue.data(current);
      rethrow;
    }
  }
  
  Future<void> _resubscribeAllFavorites(String userId, {required bool subscribe}) async {
    // Kullanıcının tüm favorilerini al
    final favs = await _firestore.collection('users')
        .doc(userId)
        .collection('favorites')
        .get();
    
    for (final doc in favs.docs) {
      final uniId = doc.id;
      
      if (subscribe) {
        await FCMService().subscribeToTopic('uni_$uniId');
      } else {
        await FCMService().unsubscribeFromTopic('uni_$uniId');
      }
    }
  }
}

final notificationPreferencesProvider = StateNotifierProvider<
    NotificationPreferencesNotifier,
    AsyncValue<NotificationPreferences>>(
  (ref) => NotificationPreferencesNotifier(),
);
