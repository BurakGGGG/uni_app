import 'package:cloud_firestore/cloud_firestore.dart';

/// Yorum türü
enum ReviewType {
  university, // Üniversite yorumu
  department, // Bölüm yorumu
  place,      // Mekan/kampüs yorumu
}

/// Yorum modeli — Sprint 3'ün bel kemiği
class ReviewModel {
  final String id;
  final ReviewType type;
  final String targetId;       // Yorumun bağlı olduğu üniversite veya bölüm ID'si
  final String universityId;   // Bölüm yorumlarında üniversiteyi de bilmek için
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String? userUniversity; // Yorumcunun üniversitesi
  final double rating;          // 1.0 - 5.0
  final Map<String, double> categoryRatings; // Kategori bazlı puanlar
  final String comment;
  final List<String> pros;      // Artılar
  final List<String> cons;      // Eksiler
  final List<String> imageUrls; // Yorum fotoğrafları
  final int likes;
  final bool isAnonymous;
  final bool isApproved;        // Moderasyon durumu
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewModel({
    required this.id,
    required this.type,
    required this.targetId,
    required this.universityId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.userUniversity,
    required this.rating,
    this.categoryRatings = const {},
    required this.comment,
    this.pros = const [],
    this.cons = const [],
    this.imageUrls = const [],
    this.likes = 0,
    this.isAnonymous = false,
    this.isApproved = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      type: ReviewType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReviewType.university,
      ),
      targetId: map['targetId'] ?? '',
      universityId: map['universityId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonim',
      userPhotoUrl: map['userPhotoUrl'] as String?,
      userUniversity: map['userUniversity'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      categoryRatings: Map<String, double>.from(
        (map['categoryRatings'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ) ?? {},
      ),
      comment: map['comment'] ?? '',
      pros: List<String>.from(map['pros'] ?? []),
      cons: List<String>.from(map['cons'] ?? []),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      likes: (map['likes'] as num?)?.toInt() ?? 0,
      isAnonymous: map['isAnonymous'] ?? false,
      isApproved: map['isApproved'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'targetId': targetId,
      'universityId': universityId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'userUniversity': userUniversity,
      'rating': rating,
      'categoryRatings': categoryRatings,
      'comment': comment,
      'pros': pros,
      'cons': cons,
      'imageUrls': imageUrls,
      'likes': likes,
      'isAnonymous': isAnonymous,
      'isApproved': isApproved,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ReviewModel copyWith({
    String? id,
    ReviewType? type,
    String? targetId,
    String? universityId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? userUniversity,
    double? rating,
    Map<String, double>? categoryRatings,
    String? comment,
    List<String>? pros,
    List<String>? cons,
    List<String>? imageUrls,
    int? likes,
    bool? isAnonymous,
    bool? isApproved,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      universityId: universityId ?? this.universityId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      userUniversity: userUniversity ?? this.userUniversity,
      rating: rating ?? this.rating,
      categoryRatings: categoryRatings ?? this.categoryRatings,
      comment: comment ?? this.comment,
      pros: pros ?? this.pros,
      cons: cons ?? this.cons,
      imageUrls: imageUrls ?? this.imageUrls,
      likes: likes ?? this.likes,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
