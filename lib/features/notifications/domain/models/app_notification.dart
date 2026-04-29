import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Bildirim türleri
enum NotificationType {
  reviewLiked,
  reviewApproved,
  reviewRejected,
  newReview,
  system,
}

/// Uygulama içi bildirim modeli
class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? targetRoute; // örn. '/university/abc123'
  final Map<String, dynamic> data;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    required this.createdAt,
    this.targetRoute,
    this.data = const {},
  });

  /// Firestore'dan parse
  factory AppNotification.fromMap(Map<String, dynamic> map, String docId) {
    return AppNotification(
      id: docId,
      userId: map['userId'] as String? ?? '',
      type: _parseType(map['type'] as String?),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      isRead: map['isRead'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate() as DateTime
          : DateTime.now(),
      targetRoute: map['targetRoute'] as String?,
      data: Map<String, dynamic>.from(map['data'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'body': body,
      'isRead': isRead,
      'createdAt': createdAt,
      'targetRoute': targetRoute,
      'data': data,
    };
  }

  /// Navigasyon yolu
  String? get routePath => targetRoute;

  /// Tipe göre ikon
  IconData get icon {
    switch (type) {
      case NotificationType.reviewLiked:
        return Icons.favorite_rounded;
      case NotificationType.reviewApproved:
        return Icons.check_circle_rounded;
      case NotificationType.reviewRejected:
        return Icons.cancel_rounded;
      case NotificationType.newReview:
        return Icons.rate_review_rounded;
      case NotificationType.system:
        return Icons.info_rounded;
    }
  }

  /// Tipe göre vurgu rengi
  Color get accentColor {
    switch (type) {
      case NotificationType.reviewLiked:
        return const Color(0xFFEF4444);
      case NotificationType.reviewApproved:
        return AppColors.success;
      case NotificationType.reviewRejected:
        return AppColors.error;
      case NotificationType.newReview:
        return AppColors.primary;
      case NotificationType.system:
        return AppColors.info;
    }
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      targetRoute: targetRoute,
      data: data,
    );
  }

  static NotificationType _parseType(String? raw) {
    if (raw == null) return NotificationType.system;
    return NotificationType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => NotificationType.system,
    );
  }
}
