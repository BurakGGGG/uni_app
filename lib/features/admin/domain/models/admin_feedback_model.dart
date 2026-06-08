import 'package:cloud_firestore/cloud_firestore.dart';

/// Feedback durumu
enum FeedbackStatus {
  newFeedback,
  inProgress,
  resolved;

  String get label {
    switch (this) {
      case FeedbackStatus.newFeedback:
        return 'Yeni';
      case FeedbackStatus.inProgress:
        return 'İnceleniyor';
      case FeedbackStatus.resolved:
        return 'Çözüldü';
    }
  }

  /// Firestore'daki değere çevir
  String get firestoreValue {
    switch (this) {
      case FeedbackStatus.newFeedback:
        return 'new';
      case FeedbackStatus.inProgress:
        return 'in_progress';
      case FeedbackStatus.resolved:
        return 'resolved';
    }
  }

  static FeedbackStatus fromString(String? value) {
    switch (value) {
      case 'in_progress':
        return FeedbackStatus.inProgress;
      case 'resolved':
        return FeedbackStatus.resolved;
      default:
        return FeedbackStatus.newFeedback;
    }
  }
}

/// Feedback türü
enum FeedbackType {
  bug,
  suggestion,
  other;

  String get label {
    switch (this) {
      case FeedbackType.bug:
        return 'Hata';
      case FeedbackType.suggestion:
        return 'Öneri';
      case FeedbackType.other:
        return 'Diğer';
    }
  }

  static FeedbackType fromString(String? value) {
    switch (value) {
      case 'bug':
        return FeedbackType.bug;
      case 'suggestion':
        return FeedbackType.suggestion;
      default:
        return FeedbackType.other;
    }
  }
}

/// Admin Feedback Modeli — Firestore `feedback` koleksiyonunu temsil eder
class AdminFeedbackModel {
  final String id;
  final String? userId;
  final String? userEmail;
  final FeedbackType type;
  final String message;
  final FeedbackStatus status;
  final String? adminNote;
  final String? reviewedBy;
  final String? appVersion;
  final String? platform;
  final DateTime createdAt;

  const AdminFeedbackModel({
    required this.id,
    this.userId,
    this.userEmail,
    required this.type,
    required this.message,
    this.status = FeedbackStatus.newFeedback,
    this.adminNote,
    this.reviewedBy,
    this.appVersion,
    this.platform,
    required this.createdAt,
  });

  factory AdminFeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return AdminFeedbackModel(
      id: id,
      userId: map['userId'] as String?,
      userEmail: map['userEmail'] as String?,
      type: FeedbackType.fromString(map['type'] as String?),
      message: map['message'] ?? '',
      status: FeedbackStatus.fromString(map['status'] as String?),
      adminNote: map['adminNote'] as String?,
      reviewedBy: map['reviewedBy'] as String?,
      appVersion: map['appVersion'] as String?,
      platform: map['platform'] as String?,
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'type': type.name,
      'message': message,
      'status': status.firestoreValue,
      'adminNote': adminNote,
      'reviewedBy': reviewedBy,
      'appVersion': appVersion,
      'platform': platform,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AdminFeedbackModel copyWith({
    String? id,
    String? userId,
    String? userEmail,
    FeedbackType? type,
    String? message,
    FeedbackStatus? status,
    String? adminNote,
    String? reviewedBy,
    String? appVersion,
    String? platform,
    DateTime? createdAt,
  }) {
    return AdminFeedbackModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      type: type ?? this.type,
      message: message ?? this.message,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      appVersion: appVersion ?? this.appVersion,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
