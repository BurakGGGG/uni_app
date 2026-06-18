import 'package:cloud_firestore/cloud_firestore.dart';
import 'place_model.dart';

/// Mekan önerisi durumları
enum SuggestionStatus {
  pending,
  approved,
  rejected;

  String get firestoreValue => name;

  String get label {
    switch (this) {
      case SuggestionStatus.pending:
        return 'Bekliyor';
      case SuggestionStatus.approved:
        return 'Onaylandı';
      case SuggestionStatus.rejected:
        return 'Reddedildi';
    }
  }

  static SuggestionStatus fromString(String? value) {
    switch (value) {
      case 'approved':
        return SuggestionStatus.approved;
      case 'rejected':
        return SuggestionStatus.rejected;
      default:
        return SuggestionStatus.pending;
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
  final double? latitude;
  final double? longitude;
  final String? priceRange;
  final String? openHours;
  final String? phone;
  final List<String> amenities;

  // Durum
  final SuggestionStatus status;
  final String? adminNote;
  final String? reviewedBy;
  final String? placeId;
  final int duplicateRiskCount;

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
    this.latitude,
    this.longitude,
    this.priceRange,
    this.openHours,
    this.phone,
    this.amenities = const [],
    this.status = SuggestionStatus.pending,
    this.adminNote,
    this.reviewedBy,
    this.placeId,
    this.duplicateRiskCount = 0,
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
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      priceRange: map['priceRange'],
      openHours: map['openHours'],
      phone: map['phone'],
      amenities: List<String>.from(map['amenities'] ?? []),
      status: SuggestionStatus.fromString(map['status']),
      adminNote: map['adminNote'],
      reviewedBy: map['reviewedBy'],
      placeId: map['placeId'],
      duplicateRiskCount: (map['duplicateRiskCount'] as num?)?.toInt() ?? 0,
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
      'latitude': latitude,
      'longitude': longitude,
      'priceRange': priceRange,
      'openHours': openHours,
      'phone': phone,
      'amenities': amenities,
      'status': status.firestoreValue,
      if (adminNote != null) 'adminNote': adminNote,
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (placeId != null) 'placeId': placeId,
      'duplicateRiskCount': duplicateRiskCount,
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
    double? latitude,
    double? longitude,
    String? priceRange,
    String? openHours,
    String? phone,
    List<String>? amenities,
    String? placeId,
    int? duplicateRiskCount,
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
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      priceRange: priceRange ?? this.priceRange,
      openHours: openHours ?? this.openHours,
      phone: phone ?? this.phone,
      amenities: amenities ?? this.amenities,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      placeId: placeId ?? this.placeId,
      duplicateRiskCount: duplicateRiskCount ?? this.duplicateRiskCount,
      createdAt: createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  bool get hasLocation => latitude != null && longitude != null;

  List<String> get missingQualityFields {
    final missing = <String>[];
    if (photoUrls.isEmpty) missing.add('Fotoğraf');
    if (address.trim().isEmpty) missing.add('Adres');
    if (!hasLocation) missing.add('Konum');
    if (description.trim().isEmpty) missing.add('Açıklama');
    if ((openHours ?? '').trim().isEmpty) missing.add('Çalışma saati');
    return missing;
  }

  int get completenessScore {
    const total = 5;
    return (((total - missingQualityFields.length) / total) * 100).round();
  }
}

class PlaceDuplicateCandidate {
  final String id;
  final String name;
  final String type;
  final String address;
  final String source;
  final String status;
  final double similarity;
  final double? distanceMeters;

  const PlaceDuplicateCandidate({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.source,
    required this.status,
    required this.similarity,
    this.distanceMeters,
  });

  factory PlaceDuplicateCandidate.fromMap(Map<String, dynamic> map) {
    return PlaceDuplicateCandidate(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? '',
      address: map['address'] as String? ?? '',
      source: map['source'] as String? ?? 'place',
      status: map['status'] as String? ?? 'approved',
      similarity: (map['similarity'] as num?)?.toDouble() ?? 0,
      distanceMeters: (map['distanceMeters'] as num?)?.toDouble(),
    );
  }
}
