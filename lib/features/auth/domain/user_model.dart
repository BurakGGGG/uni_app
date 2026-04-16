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
  final int reviewCount;
  final List<String> favorites;
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
    this.reviewCount = 0,
    this.favorites = const [],
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
      reviewCount: map['reviewCount'] ?? 0,
      favorites: List<String>.from(map['favorites'] ?? []),
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
      'reviewCount': reviewCount,
      'favorites': favorites,
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
    int? reviewCount,
    List<String>? favorites,
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
      reviewCount: reviewCount ?? this.reviewCount,
      favorites: favorites ?? this.favorites,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  /// edu.tr email kontrolü
  bool get hasEduEmail => email.toLowerCase().endsWith('.edu.tr');

  /// Kullanıcının baş harfi (avatar için)
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  @override
  String toString() => 'UserModel(uid: $uid, displayName: $displayName, email: $email)';
}

/// Auth durumu
enum AuthStatus {
  authenticated,
  unauthenticated,
  loading,
}
