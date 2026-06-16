import 'package:cloud_firestore/cloud_firestore.dart';
import 'place_model.dart';

/// Mekan önerisi durumları
enum SuggestionStatus {
  pending,   // Bekliyor
  approved,  // Onaylandı
  rejected;  // Reddedildi

  String get firestoreValue => name;

  String get label {
    switch (this) {
      case SuggestionStatus.pending: return 'Bekliyor';
      case SuggestionStatus.approved: return 'Onaylandı';
      case SuggestionStatus.rejected: return 'Reddedildi';
    }
  }

  static SuggestionStatus fromString(String? value) {
    switch (value) {
      case 'approved': return SuggestionStatus.approved;
      case 'rejected': return SuggestionStatus.rejected;
      default: return SuggestionStatus.pending;
    }
  }
}

/// Kullanıcıların önerdiği mekan modeli.
class PlaceSuggestionModel {
  final String id;
  final String universityId;
  final String universityName;
  final String userId;
  final String userName;
  
  // Mekan bilgileri
  final String name;
  final PlaceType type;
  final String description;
  final String address;
  final List<String> photoUrls;
  
  // Durum
  final SuggestionStatus status;
  final String? adminNote;
  final String? reviewedBy;
  
  final DateTime createdAt;
  final DateTime? reviewedAt;

  PlaceSuggestionModel({
    required this.id,
    required this.universityId,
    required this.universityName,
    required this.userId,
    required this.userName,
    required this.name,
    required this.type,
    this.description = '',
    this.address = '',
    this.photoUrls = const [],
    this.status = SuggestionStatus.pending,
    this.adminNote,
    this.reviewedBy,
    required this.createdAt,
    this.reviewedAt,
  });

  factory PlaceSuggestionModel.fromMap(Map<String, dynamic> map, String id) {
    return PlaceSuggestionModel(
      id: id,
      universityId: map['universityId'] ?? '',
      universityName: map['universityName'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      name: map['name'] ?? '',
      type: PlaceType.fromString(map['type']),
      description: map['description'] ?? '',
      address: map['address'] ?? '',
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      status: SuggestionStatus.fromString(map['status']),
      adminNote: map['adminNote'],
      reviewedBy: map['reviewedBy'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'universityId': universityId,
      'universityName': universityName,
      'userId': userId,
      'userName': userName,
      'name': name,
      'type': type.firestoreValue,
      'description': description,
      'address': address,
      'photoUrls': photoUrls,
      'status': status.firestoreValue,
      if (adminNote != null) 'adminNote': adminNote,
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
    };
  }

  PlaceSuggestionModel copyWith({
    SuggestionStatus? status,
    String? adminNote,
    String? reviewedBy,
    DateTime? reviewedAt,
    List<String>? photoUrls,
  }) {
    return PlaceSuggestionModel(
      id: id,
      universityId: universityId,
      universityName: universityName,
      userId: userId,
      userName: userName,
      name: name,
      type: type,
      description: description,
      address: address,
      photoUrls: photoUrls ?? this.photoUrls,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      createdAt: createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}
