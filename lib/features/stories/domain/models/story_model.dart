import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin tarafından paylaşılan hikaye modeli
class StoryModel {
  final String id;
  final String imageUrl;
  final String? title;
  final String authorUid;
  final String authorName;
  final DateTime createdAt;
  final bool isActive;

  const StoryModel({
    required this.id,
    required this.imageUrl,
    this.title,
    required this.authorUid,
    required this.authorName,
    required this.createdAt,
    this.isActive = true,
  });

  /// Firestore'dan veri okuma
  factory StoryModel.fromMap(Map<String, dynamic> map, String id) {
    return StoryModel(
      id: id,
      imageUrl: map['imageUrl'] ?? '',
      title: map['title'],
      authorUid: map['authorUid'] ?? '',
      authorName: map['authorName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  /// Firestore'a veri yazma
  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'authorUid': authorUid,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  /// Kopya oluşturma
  StoryModel copyWith({
    String? imageUrl,
    String? title,
    String? authorUid,
    String? authorName,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return StoryModel(
      id: id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      authorUid: authorUid ?? this.authorUid,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() =>
      'StoryModel(id: $id, title: $title, authorName: $authorName)';
}
