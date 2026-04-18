import 'package:cloud_firestore/cloud_firestore.dart';

/// Favori işlemlerini yöneten repository
class FavoritesRepository {
  final FirebaseFirestore _firestore;

  FavoritesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Bir kullanıcının favorilerini stream olarak getir
  Stream<List<String>> getUserFavoritesStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  /// Üniversiteyi favorilere ekle
  Future<void> addFavorite(String uid, String universityId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(universityId)
        .set({
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Üniversiteyi favorilerden çıkar
  Future<void> removeFavorite(String uid, String universityId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(universityId)
        .delete();
  }

  /// Belirli bir üniversitenin favorilerde olup olmadığını bir kerelik kontrol et
  Future<bool> isFavorite(String uid, String universityId) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(universityId)
        .get();
    return doc.exists;
  }
}
