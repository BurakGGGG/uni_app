import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/admin_log_model.dart';

class AdminLogsRepository {
  final FirebaseFirestore _firestore;

  AdminLogsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _auditLogsRef =>
      _firestore.collection('adminAuditLogs');

  CollectionReference<Map<String, dynamic>> get _suspiciousLogsRef =>
      _firestore.collection('suspiciousActivityLogs');

  Stream<List<AdminAuditLogModel>> watchAuditLogs({int limit = 100}) {
    return _auditLogsRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AdminAuditLogModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<SuspiciousActivityLogModel>> watchSuspiciousLogs({
    int limit = 100,
  }) {
    return _suspiciousLogsRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => SuspiciousActivityLogModel.fromMap(doc.data(), doc.id),
              )
              .toList(),
        );
  }

  Future<List<AdminAuditLogModel>> getAuditLogsForTarget(
    String targetId, {
    int limit = 50,
  }) async {
    final snap = await _auditLogsRef
        .where('targetId', isEqualTo: targetId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((doc) => AdminAuditLogModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
