import 'package:cloud_firestore/cloud_firestore.dart';

enum SuspiciousLogSeverity {
  info,
  warning,
  high;

  String get label => switch (this) {
    SuspiciousLogSeverity.info => 'Bilgi',
    SuspiciousLogSeverity.warning => 'Uyarı',
    SuspiciousLogSeverity.high => 'Yüksek',
  };
}

class AdminAuditLogModel {
  final String id;
  final String actorUid;
  final String action;
  final String targetCollection;
  final String targetId;
  final String targetPath;
  final String? reportId;
  final String? reviewId;
  final String? feedbackId;
  final String? reviewOwnerId;
  final String? status;
  final bool adminNotePresent;
  final int? photoCount;
  final List<String> changedFields;
  final Map<String, dynamic> approvedSnapshot;
  final DateTime createdAt;

  const AdminAuditLogModel({
    required this.id,
    required this.actorUid,
    required this.action,
    required this.targetCollection,
    required this.targetId,
    required this.targetPath,
    this.reportId,
    this.reviewId,
    this.feedbackId,
    this.reviewOwnerId,
    this.status,
    this.adminNotePresent = false,
    this.photoCount,
    this.changedFields = const [],
    this.approvedSnapshot = const {},
    required this.createdAt,
  });

  factory AdminAuditLogModel.fromMap(Map<String, dynamic> map, String id) {
    final targetCollection = _stringValue(map['targetCollection']);
    final targetId = _stringValue(map['targetId']);
    return AdminAuditLogModel(
      id: id,
      actorUid: _stringValue(map['actorUid']),
      action: _stringValue(map['action']),
      targetCollection: targetCollection,
      targetId: targetId,
      targetPath:
          _stringValue(map['targetPath']) //
              .ifEmpty('$targetCollection/$targetId'),
      reportId: _nullableString(map['reportId']),
      reviewId: _nullableString(map['reviewId']),
      feedbackId: _nullableString(map['feedbackId']),
      reviewOwnerId: _nullableString(map['reviewOwnerId']),
      status: _nullableString(map['status']),
      adminNotePresent: map['adminNotePresent'] == true,
      photoCount: _nullableInt(map['photoCount']),
      changedFields: List<String>.from(
        map['changedFields'] as List? ?? const [],
      ),
      approvedSnapshot: _mapValue(map['approvedSnapshot']),
      createdAt: _dateValue(map['createdAt']),
    );
  }

  String get actionLabel => switch (action) {
    'report_status_updated' => 'Rapor durumu güncellendi',
    'review_hidden' => 'Yorum gizlendi',
    'review_unhidden' => 'Yorum geri açıldı',
    'review_deleted' => 'Yorum silindi',
    'feedback_status_updated' => 'Feedback durumu güncellendi',
    'feedback_deleted' => 'Feedback silindi',
    'place_suggestion_approved' => 'Mekan önerisi onaylandı',
    'place_suggestion_rejected' => 'Mekan önerisi reddedildi',
    _ => action.ifEmpty('Bilinmeyen aksiyon'),
  };

  String get targetLabel => switch (targetCollection) {
    'reports' => 'Rapor',
    'reviews' => 'Yorum',
    'feedback' => 'Feedback',
    'place_suggestions' => 'Mekan önerisi',
    _ => targetCollection.ifEmpty('Hedef'),
  };

  bool get isDestructive =>
      action == 'review_deleted' || action == 'feedback_deleted';

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      actorUid,
      action,
      actionLabel,
      targetCollection,
      targetId,
      targetPath,
      reportId,
      reviewId,
      feedbackId,
      reviewOwnerId,
      status,
    ].whereType<String>().any((value) => value.toLowerCase().contains(q));
  }
}

class SuspiciousActivityLogModel {
  final String id;
  final String uid;
  final String type;
  final String source;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const SuspiciousActivityLogModel({
    required this.id,
    required this.uid,
    required this.type,
    required this.source,
    required this.metadata,
    required this.createdAt,
  });

  factory SuspiciousActivityLogModel.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    return SuspiciousActivityLogModel(
      id: id,
      uid: _stringValue(map['uid']),
      type: _stringValue(map['type']),
      source: _stringValue(map['source']),
      metadata: _mapValue(map['metadata']),
      createdAt: _dateValue(map['createdAt']),
    );
  }

  SuspiciousLogSeverity get severity {
    if (type.contains('rate_limited')) return SuspiciousLogSeverity.warning;
    if (type.contains('duplicate') || type.contains('failed')) {
      return SuspiciousLogSeverity.high;
    }
    return SuspiciousLogSeverity.info;
  }

  String get typeLabel => switch (type) {
    'report_rate_limited' => 'Report rate limit',
    'feedback_rate_limited' => 'Feedback rate limit',
    'place_suggestion_rate_limited' => 'Mekan önerisi rate limit',
    'place_duplicate_check_rate_limited' => 'Benzer mekan kontrolü rate limit',
    'duplicate_report_attempt' => 'Tekrarlı report denemesi',
    'failed_admin_callable_access' => 'Başarısız admin callable erişimi',
    _ => type.ifEmpty('Bilinmeyen olay'),
  };

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      uid,
      type,
      typeLabel,
      source,
      ...metadata.entries.map((e) => '${e.key}:${e.value}'),
    ].any((value) => value.toLowerCase().contains(q));
  }
}

DateTime _dateValue(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.now();
}

String _stringValue(Object? value) {
  if (value is String) return value;
  return '';
}

String? _nullableString(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value;
  return null;
}

int? _nullableInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

Map<String, dynamic> _mapValue(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const {};
}

extension _StringFallback on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
