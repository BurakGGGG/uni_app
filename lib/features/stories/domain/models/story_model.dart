import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin tarafından paylaşılan hikaye modeli
class StoryModel {
  final String id;
  final String imageUrl;

  /// Ana sayfada bubble'da gösterilecek yuvarlak kapak fotoğrafı URL'i.
  /// Null ise [imageUrl] fallback olarak kullanılır.
  final String? thumbnailUrl;
  final String? title;
  final String authorUid;
  final String authorName;

  /// Story paylaşan kişinin profil fotoğrafı URL'i.
  /// "ÜniSeç" olarak paylaşılmışsa null olur ve uygulama logosu gösterilir.
  final String? authorPhotoUrl;
  final DateTime createdAt;
  final bool isActive;

  const StoryModel({
    required this.id,
    required this.imageUrl,
    this.thumbnailUrl,
    this.title,
    required this.authorUid,
    required this.authorName,
    this.authorPhotoUrl,
    required this.createdAt,
    this.isActive = true,
  });

  /// Bubble'da gösterilecek görsel URL'i (kapak varsa kapak, yoksa story görseli)
  String get displayThumbnailUrl => thumbnailUrl ?? imageUrl;

  /// Firestore'dan veri okuma
  factory StoryModel.fromMap(Map<String, dynamic> map, String id) {
    return StoryModel(
      id: id,
      imageUrl: map['imageUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'],
      title: map['title'],
      authorUid: map['authorUid'] ?? '',
      authorName: map['authorName'] ?? '',
      authorPhotoUrl: map['authorPhotoUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  /// Firestore'a veri yazma
  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'title': title,
      'authorUid': authorUid,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  /// Kopya oluşturma
  StoryModel copyWith({
    String? imageUrl,
    String? thumbnailUrl,
    String? title,
    String? authorUid,
    String? authorName,
    String? authorPhotoUrl,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return StoryModel(
      id: id,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      title: title ?? this.title,
      authorUid: authorUid ?? this.authorUid,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() =>
      'StoryModel(id: $id, title: $title, authorName: $authorName)';
}
