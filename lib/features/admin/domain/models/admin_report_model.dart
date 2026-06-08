import 'package:cloud_firestore/cloud_firestore.dart';

/// Rapor durumu
enum ReportStatus {
  pending,
  reviewed,
  dismissed,
  actioned;

  String get label {
    switch (this) {
      case ReportStatus.pending:
        return 'Bekliyor';
      case ReportStatus.reviewed:
        return 'İncelendi';
      case ReportStatus.dismissed:
        return 'Reddedildi';
      case ReportStatus.actioned:
        return 'Aksiyon Alındı';
    }
  }

  static ReportStatus fromString(String? value) {
    switch (value) {
      case 'reviewed':
        return ReportStatus.reviewed;
      case 'dismissed':
        return ReportStatus.dismissed;
      case 'actioned':
        return ReportStatus.actioned;
      default:
        return ReportStatus.pending;
    }
  }
}

/// Şikayet nedeni (report_repository.dart'taki ile aynı)
enum AdminReportReason {
  inappropriate,
  spam,
  offensive,
  misleading,
  other;

  String get label {
    switch (this) {
      case AdminReportReason.inappropriate:
        return 'Uygunsuz içerik';
      case AdminReportReason.spam:
        return 'Spam';
      case AdminReportReason.offensive:
        return 'Hakaret / ayrımcılık';
      case AdminReportReason.misleading:
        return 'Yanıltıcı bilgi';
      case AdminReportReason.other:
        return 'Diğer';
    }
  }

  static AdminReportReason fromString(String? value) {
    switch (value) {
      case 'inappropriate':
        return AdminReportReason.inappropriate;
      case 'spam':
        return AdminReportReason.spam;
      case 'offensive':
        return AdminReportReason.offensive;
      case 'misleading':
        return AdminReportReason.misleading;
      default:
        return AdminReportReason.other;
    }
  }
}

/// Admin Rapor Modeli — Firestore `reports` koleksiyonunu temsil eder
class AdminReportModel {
  final String id;
  final String reviewId;
  final String userId;
  final AdminReportReason reason;
  final String? explanation;
  final ReportStatus status;
  final String? adminNote;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  const AdminReportModel({
    required this.id,
    required this.reviewId,
    required this.userId,
    required this.reason,
    this.explanation,
    this.status = ReportStatus.pending,
    this.adminNote,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
  });

  factory AdminReportModel.fromMap(Map<String, dynamic> map, String id) {
    return AdminReportModel(
      id: id,
      reviewId: map['reviewId'] ?? '',
      userId: map['userId'] ?? '',
      reason: AdminReportReason.fromString(map['reason'] as String?),
      explanation: map['explanation'] as String?,
      status: ReportStatus.fromString(map['status'] as String?),
      adminNote: map['adminNote'] as String?,
      reviewedBy: map['reviewedBy'] as String?,
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'userId': userId,
      'reason': reason.name,
      'explanation': explanation,
      'status': status.name,
      'adminNote': adminNote,
      'reviewedBy': reviewedBy,
      'reviewedAt':
          reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AdminReportModel copyWith({
    String? id,
    String? reviewId,
    String? userId,
    AdminReportReason? reason,
    String? explanation,
    ReportStatus? status,
    String? adminNote,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
  }) {
    return AdminReportModel(
      id: id ?? this.id,
      reviewId: reviewId ?? this.reviewId,
      userId: userId ?? this.userId,
      reason: reason ?? this.reason,
      explanation: explanation ?? this.explanation,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
