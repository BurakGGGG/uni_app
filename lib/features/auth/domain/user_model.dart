import 'package:cloud_firestore/cloud_firestore.dart';

/// Kullanıcı veri modeli
class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final bool isVerifiedStudent;
  final String? university;
  final String? universityId;
  final String? department;
  final int? grade;
  final String? bio;
  final String role;
  final int reviewCount;
  // Rozetler: badgeId -> verildiği an. Yalnızca server yazar
  // (award_badges.ts); bu yüzden toMap()'e bilinçli olarak dahil değil.
  final Map<String, DateTime> badges;
  final List<String> fcmTokens;
  final NotificationPreferences notificationPrefs;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.isVerifiedStudent = false,
    this.university,
    this.universityId,
    this.department,
    this.grade,
    this.bio,
    this.role = 'user',
    this.reviewCount = 0,
    this.badges = const {},
    this.fcmTokens = const [],
    this.notificationPrefs = const NotificationPreferences(),
    required this.createdAt,
    required this.lastLoginAt,
  });

  /// Firestore'dan veri okuma
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      isVerifiedStudent: map['isVerifiedStudent'] ?? false,
      university: map['university'],
      universityId: map['universityId'],
      department: map['department'],
      grade: map['grade'],
      bio: map['bio'],
      role: map['role'] ?? 'user',
      reviewCount: map['reviewCount'] ?? 0,
      badges: _parseBadges(map['badges']),
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []),
      notificationPrefs: NotificationPreferences.fromMap(
        map['notificationPrefs'] as Map<String, dynamic>?,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt:
          (map['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestore'a veri yazma
  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'isVerifiedStudent': isVerifiedStudent,
      'university': university,
      'universityId': universityId,
      'department': department,
      'grade': grade,
      'bio': bio,
      'role': role,
      'reviewCount': reviewCount,
      'fcmTokens': fcmTokens,
      'notificationPrefs': notificationPrefs.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
    };
  }

  /// Kopya oluşturma (güncelleme için)
  UserModel copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    bool? isVerifiedStudent,
    String? university,
    String? universityId,
    String? department,
    int? grade,
    String? bio,
    String? role,
    int? reviewCount,
    Map<String, DateTime>? badges,
    List<String>? fcmTokens,
    NotificationPreferences? notificationPrefs,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isVerifiedStudent: isVerifiedStudent ?? this.isVerifiedStudent,
      university: university ?? this.university,
      universityId: universityId ?? this.universityId,
      department: department ?? this.department,
      grade: grade ?? this.grade,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      reviewCount: reviewCount ?? this.reviewCount,
      badges: badges ?? this.badges,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      notificationPrefs: notificationPrefs ?? this.notificationPrefs,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  /// edu.tr email kontrolü
  bool get hasEduEmail => email.toLowerCase().endsWith('.edu.tr');

  static Map<String, DateTime> _parseBadges(dynamic raw) {
    if (raw is! Map) return const {};
    final result = <String, DateTime>{};
    raw.forEach((key, value) {
      if (key is String && value is Timestamp) {
        result[key] = value.toDate();
      }
    });
    return result;
  }

  /// Legacy role alanı. Yetki kontrolü Firebase Auth custom claim üzerinden yapılır.
  @Deprecated(
    'Admin authorization is based on Firebase Auth custom claims. '
    'Use currentUserAdminProvider instead.',
  )
  bool get isAdmin => role == 'admin';

  /// Kullanıcının baş harfi (avatar için)
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, displayName: $displayName, email: $email)';
}

/// Bildirim tercihleri
class NotificationPreferences {
  final bool reviewLikedEnabled;
  final bool reviewModeratedEnabled;
  final bool favoriteNewReviewEnabled;
  final bool reviewCampaignEnabled;

  const NotificationPreferences({
    this.reviewLikedEnabled = true,
    this.reviewModeratedEnabled = true,
    this.favoriteNewReviewEnabled = true,
    this.reviewCampaignEnabled = true,
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const NotificationPreferences();
    return NotificationPreferences(
      reviewLikedEnabled: map['reviewLikedEnabled'] ?? true,
      reviewModeratedEnabled: map['reviewModeratedEnabled'] ?? true,
      favoriteNewReviewEnabled: map['favoriteNewReviewEnabled'] ?? true,
      reviewCampaignEnabled: map['reviewCampaignEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'reviewLikedEnabled': reviewLikedEnabled,
    'reviewModeratedEnabled': reviewModeratedEnabled,
    'favoriteNewReviewEnabled': favoriteNewReviewEnabled,
    'reviewCampaignEnabled': reviewCampaignEnabled,
  };

  NotificationPreferences copyWith({
    bool? reviewLikedEnabled,
    bool? reviewModeratedEnabled,
    bool? favoriteNewReviewEnabled,
    bool? reviewCampaignEnabled,
  }) {
    return NotificationPreferences(
      reviewLikedEnabled: reviewLikedEnabled ?? this.reviewLikedEnabled,
      reviewModeratedEnabled:
          reviewModeratedEnabled ?? this.reviewModeratedEnabled,
      favoriteNewReviewEnabled:
          favoriteNewReviewEnabled ?? this.favoriteNewReviewEnabled,
      reviewCampaignEnabled:
          reviewCampaignEnabled ?? this.reviewCampaignEnabled,
    );
  }
}

/// Auth durumu
enum AuthStatus { authenticated, unauthenticated, loading }
