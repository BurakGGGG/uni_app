import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../enums/notification_type.dart';
import '../../../../core/theme/app_colors.dart';

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? expireAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    required this.isRead,
    required this.createdAt,
    this.expireAt,
  });

  String? get routePath => data['route'] as String?;
  String? get reviewId => data['reviewId'] as String?;

  IconData get icon {
    switch (type) {
      case NotificationType.reviewLiked:
        return Icons.favorite_rounded;
      case NotificationType.reviewModerated:
        return Icons.shield_rounded;
      case NotificationType.favoriteNewReview:
        return Icons.fiber_new_rounded;
      case NotificationType.reviewCampaign:
        return Icons.rate_review_rounded;
    }
  }

  Color get accentColor {
    switch (type) {
      case NotificationType.reviewLiked:
        return const Color(0xFFEC4899);
      case NotificationType.reviewModerated:
        return AppColors.success;
      case NotificationType.favoriteNewReview:
        return AppColors.info;
      case NotificationType.reviewCampaign:
        return AppColors.primary;
    }
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      expireAt: expireAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.firestoreValue,
      'title': title,
      'body': body,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt,
      if (expireAt != null) 'expireAt': expireAt,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      userId: map['userId'] ?? '',
      type: NotificationType.fromString(map['type']),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expireAt: (map['expireAt'] as Timestamp?)?.toDate(),
    );
  }
}