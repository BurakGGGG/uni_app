import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum PlaceType {
  cafe,
  dorm,
  studyArea,
  library,
  sports;

  String get firestoreValue {
    switch (this) {
      case PlaceType.cafe: return 'cafe';
      case PlaceType.dorm: return 'dorm';
      case PlaceType.studyArea: return 'study_area';
      case PlaceType.library: return 'library';
      case PlaceType.sports: return 'sports';
    }
  }

  String get label {
    switch (this) {
      case PlaceType.cafe: return 'Kafe';
      case PlaceType.dorm: return 'Yurt';
      case PlaceType.studyArea: return 'Çalışma Alanı';
      case PlaceType.library: return 'Kütüphane';
      case PlaceType.sports: return 'Spor Tesisi';
    }
  }

  IconData get icon {
    switch (this) {
      case PlaceType.cafe: return Icons.local_cafe_rounded;
      case PlaceType.dorm: return Icons.bed_rounded;
      case PlaceType.studyArea: return Icons.menu_book_rounded;
      case PlaceType.library: return Icons.local_library_rounded;
      case PlaceType.sports: return Icons.fitness_center_rounded;
    }
  }

  static PlaceType fromString(String? value) {
    switch (value) {
      case 'cafe': return PlaceType.cafe;
      case 'dorm': return PlaceType.dorm;
      case 'study_area': return PlaceType.studyArea;
      case 'library': return PlaceType.library;
      case 'sports': return PlaceType.sports;
      default: return PlaceType.cafe;
    }
  }
}

class PlaceModel {
  final String id;
  final String universityId;
  final String name;
  final PlaceType type;
  final String description;
  final List<String> imageUrls;
  final String address;
  final String? mapUrl;
  final GeoPoint? location;
  final String? priceRange;
  final String? openHours;
  final List<String> amenities;
  
  // Yurt-spesifik
  final String? dormType;
  final String? dormGenderType;
  
  // External rating
  final double? externalRating;
  final String? externalRatingSource;
  
  // Aggregation
  final double avgRating;
  final int reviewCount;
  final Map<String, double> categoryRatings;
  
  // Monetization
  final bool isPromoted;
  final int promotionPriority;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  PlaceModel({
    required this.id,
    required this.universityId,
    required this.name,
    required this.type,
    this.description = '',
    this.imageUrls = const [],
    this.address = '',
    this.mapUrl,
    this.location,
    this.priceRange,
    this.openHours,
    this.amenities = const [],
    this.dormType,
    this.dormGenderType,
    this.externalRating,
    this.externalRatingSource,
    this.avgRating = 0.0,
    this.reviewCount = 0,
    this.categoryRatings = const {},
    this.isPromoted = false,
    this.promotionPriority = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlaceModel.fromMap(Map<String, dynamic> map, String id) {
    return PlaceModel(
      id: id,
      universityId: map['universityId'] ?? '',
      name: map['name'] ?? '',
      type: PlaceType.fromString(map['type']),
      description: map['description'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      address: map['address'] ?? '',
      mapUrl: map['mapUrl'],
      location: map['location'] as GeoPoint?,
      priceRange: map['priceRange'],
      openHours: map['openHours'],
      amenities: List<String>.from(map['amenities'] ?? []),
      dormType: map['dormType'],
      dormGenderType: map['dormGenderType'],
      externalRating: (map['externalRating'] as num?)?.toDouble(),
      externalRatingSource: map['externalRatingSource'],
      avgRating: (map['avgRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      categoryRatings: Map<String, double>.from(
        (map['categoryRatings'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ) ?? {},
      ),
      isPromoted: map['isPromoted'] ?? false,
      promotionPriority: (map['promotionPriority'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'universityId': universityId,
      'name': name,
      'type': type.firestoreValue,
      'description': description,
      'imageUrls': imageUrls,
      'address': address,
      'mapUrl': mapUrl,
      'location': location,
      'priceRange': priceRange,
      'openHours': openHours,
      'amenities': amenities,
      if (dormType != null) 'dormType': dormType,
      if (dormGenderType != null) 'dormGenderType': dormGenderType,
      if (externalRating != null) 'externalRating': externalRating,
      if (externalRatingSource != null) 'externalRatingSource': externalRatingSource,
      'avgRating': avgRating,
      'reviewCount': reviewCount,
      'categoryRatings': categoryRatings,
      'isPromoted': isPromoted,
      'promotionPriority': promotionPriority,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
