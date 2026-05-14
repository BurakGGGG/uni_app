import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
  ///
  /// Validation:
  /// - Boş not kabul edilmez
  /// - 500 karakter sınırı uygulanır
  /// - Aynı karşılaştırma + aynı içerik 3 saniye içinde tekrar yazılırsa
  ///   sessizce drop edilir (idempotency, hızlı tap-tap koruması)
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

    // ─── Validation ──────────────────────────────────────────────
    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      debugPrint('[ComparisonNotes] empty note rejected');
      return; // UI zaten engelliyor, ekstra güvenlik
    }
    if (trimmed.length > 500) {
      debugPrint('[ComparisonNotes] note too long: ${trimmed.length}');
      return; // UI zaten engelliyor, ekstra güvenlik
    }

    // ─── Idempotency — aynı karşılaştırma + aynı içerik → tekilleştir
    final idempotencyKey =
        '${entityAId}_${entityBId}_${trimmed.hashCode}';

    // Aynı içerik 3 saniye içinde tekrar yazılırsa skip
    // Not: composite index yoksa sorgu hata verir → sessizce devam et
    try {
      final recent = await ref
          .where('idempotencyKey', isEqualTo: idempotencyKey)
          .where('createdAt',
              isGreaterThan: Timestamp.fromDate(
                  DateTime.now().subtract(const Duration(seconds: 3))))
          .limit(1)
          .get();

      if (recent.docs.isNotEmpty) {
        debugPrint('[ComparisonNotes] duplicate note skipped (idempotency)');
        return; // duplicate, sessizce drop
      }
    } catch (e) {
      // Composite index eksikse sorgu başarısız olur — idempotency'yi atla,
      // not kaydını engelleme
      debugPrint('[ComparisonNotes] idempotency check skipped: $e');
    }

    try {
      await ref.add({
        'comparisonType': comparisonType,
        'entityAId': entityAId,
        'entityBId': entityBId,
        'note': trimmed,
        'pros': pros,
        'cons': cons,
        'rating': rating,
        'idempotencyKey': idempotencyKey,
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
    } catch (e, st) {
      debugPrint('[ComparisonNotes] addNote failed: $e');
      FirebaseCrashlytics.instance.recordError(e, st,
          reason: 'comparison_note_add_failed',
          information: [
            'userId: ${_auth.currentUser?.uid}',
            'noteLen: ${trimmed.length}',
          ]);
      // rethrow kaldırıldı — hata UI'ı kırmasın, Crashlytics'e loglanır
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
