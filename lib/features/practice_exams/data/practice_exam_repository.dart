import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../domain/models/exam_target.dart';
import '../domain/models/practice_exam.dart';

/// Deneme defterinin hesap yedeği: `users/{uid}/practiceExams`.
///
/// `ComparisonHistoryRepository` deseni: misafirde sessiz no-op, tüm hatalar
/// yutulup loglanır — yedekleme başarısız olsa bile yerel defter çalışmaya
/// devam eder.
class PracticeExamRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PracticeExamRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  bool get isSignedIn => _auth.currentUser != null;

  CollectionReference<Map<String, dynamic>>? _examsRef() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('practiceExams');
  }

  DocumentReference<Map<String, dynamic>>? _targetRef() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('practiceExamMeta')
        .doc('target');
  }

  /// Uzaktaki tüm kayıtlar (mezar taşları dahil). Misafirde boş liste.
  Future<List<PracticeExam>> pullAll() async {
    final ref = _examsRef();
    if (ref == null) return const [];
    try {
      final snap = await ref.get();
      return [
        for (final doc in snap.docs) PracticeExam.fromJson(doc.data()),
      ];
    } catch (e) {
      debugPrint('[PracticeExams] pull failed: $e');
      return const [];
    }
  }

  Future<void> upsert(PracticeExam exam) async {
    final ref = _examsRef();
    if (ref == null) return;
    try {
      await ref.doc(exam.id).set(exam.toJson());
    } catch (e) {
      debugPrint('[PracticeExams] upsert failed: $e');
    }
  }

  Future<void> upsertAll(List<PracticeExam> exams) async {
    final ref = _examsRef();
    if (ref == null || exams.isEmpty) return;
    try {
      final batch = _firestore.batch();
      for (final exam in exams) {
        batch.set(ref.doc(exam.id), exam.toJson());
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[PracticeExams] batch upsert failed: $e');
    }
  }

  /// Silme mezar taşı olarak yayılır — kayıt uzaktan tamamen kaldırılmaz,
  /// yoksa diğer cihaz onu "yeni kayıt" sanıp geri yükler.
  Future<void> markDeleted(PracticeExam exam) async {
    await upsert(exam.copyWith(deleted: true, updatedAt: DateTime.now()));
  }

  Future<ExamTarget?> pullTarget() async {
    final ref = _targetRef();
    if (ref == null) return null;
    try {
      final snap = await ref.get();
      final data = snap.data();
      if (data == null || data.isEmpty) return null;
      return ExamTarget.fromJson(data);
    } catch (e) {
      debugPrint('[PracticeExams] target pull failed: $e');
      return null;
    }
  }

  Future<void> pushTarget(ExamTarget? target) async {
    final ref = _targetRef();
    if (ref == null) return;
    try {
      if (target == null) {
        await ref.delete();
      } else {
        await ref.set(target.toJson());
      }
    } catch (e) {
      debugPrint('[PracticeExams] target push failed: $e');
    }
  }
}
