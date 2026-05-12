import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../domain/models/comparison_note.dart';

/// Kullanıcı başına en fazla bu kadar not tutulur.
/// Aşıldığında en eski notlar otomatik silinir (FIFO).
const int kComparisonNotesMaxSize = 50;

class ComparisonNotesRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ComparisonNotesRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>? _refForCurrentUser() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('comparisonNotes');
  }

  /// Yeni not ekle. Misafir kullanıcıda sessizce no-op döner.
  Future<void> addNote({
    required String comparisonType,
    required String entityAId,
    required String entityBId,
    required String note,
    List<String> pros = const [],
    List<String> cons = const [],
    int? rating,
  }) async {
    final ref = _refForCurrentUser();
    if (ref == null) return;

    try {
      await ref.add({
        'comparisonType': comparisonType,
        'entityAId': entityAId,
        'entityBId': entityBId,
        'note': note,
        'pros': pros,
        'cons': cons,
        'rating': rating,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Max boyut aşıldıysa en eskileri sil (FIFO)
      final all = await ref.orderBy('createdAt', descending: true).get();
      if (all.docs.length > kComparisonNotesMaxSize) {
        for (var i = kComparisonNotesMaxSize; i < all.docs.length; i++) {
          await all.docs[i].reference.delete();
        }
      }
    } catch (e) {
      debugPrint('[ComparisonNotes] addNote failed: $e');
    }
  }

  /// Mevcut notu güncelle.
  Future<void> updateNote({
    required String noteId,
    required String note,
    List<String> pros = const [],
    List<String> cons = const [],
    int? rating,
  }) async {
    final ref = _refForCurrentUser();
    if (ref == null) return;

    try {
      await ref.doc(noteId).update({
        'note': note,
        'pros': pros,
        'cons': cons,
        'rating': ?rating,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[ComparisonNotes] updateNote failed: $e');
    }
  }

  /// Tek bir notu sil.
  Future<void> deleteNote(String noteId) async {
    final ref = _refForCurrentUser();
    if (ref == null) return;
    await ref.doc(noteId).delete();
  }

  /// Belirli bir karşılaştırma çifti için notları dinle (real-time).
  /// Çift sırasız eşleştirilir (A-B == B-A).
  Stream<List<ComparisonNote>> watchNotesForPair({
    required String comparisonType,
    required String entityAId,
    required String entityBId,
  }) {
    final ref = _refForCurrentUser();
    if (ref == null) return Stream.value(const []);

    // Tüm notları çek, client-side filtrele (max 50 not — composite index gereksiz).
    return ref
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map(ComparisonNote.fromDoc)
            .where((n) =>
                n.comparisonType == comparisonType &&
                ((n.entityAId == entityAId && n.entityBId == entityBId) ||
                 (n.entityAId == entityBId && n.entityBId == entityAId)))
            .toList());
  }

  /// Tüm notları dinle (real-time). Hub screen'de kullanılabilir.
  Stream<List<ComparisonNote>> watchAllNotes({int limit = 50}) {
    final ref = _refForCurrentUser();
    if (ref == null) return Stream.value(const []);
    return ref
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(ComparisonNote.fromDoc).toList());
  }
}
