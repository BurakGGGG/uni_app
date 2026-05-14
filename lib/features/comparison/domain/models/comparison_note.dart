import 'package:cloud_firestore/cloud_firestore.dart';

/// Kullanıcının bir karşılaştırma çifti için kaydettiği kişisel not.
/// Firestore path: `users/{uid}/comparisonNotes/{noteId}`
class ComparisonNote {
  final String id;
  final String comparisonType; // 'university' | 'department' | 'city'
  final String entityAId;
  final String entityBId;
  final String note;
  final List<String> pros;
  final List<String> cons;
  final int? rating; // 1-5 — kullanıcının kendi tercih puanı
  final DateTime createdAt;
  final DateTime updatedAt;

  const ComparisonNote({
    required this.id,
    required this.comparisonType,
    required this.entityAId,
    required this.entityBId,
    required this.note,
    this.pros = const [],
    this.cons = const [],
    this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ComparisonNote.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};

    DateTime parseTimestamp(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    }

    return ComparisonNote(
      id: doc.id,
      comparisonType: data['comparisonType'] as String? ?? 'university',
      entityAId: data['entityAId'] as String? ?? '',
      entityBId: data['entityBId'] as String? ?? '',
      note: data['note'] as String? ?? '',
      pros: (data['pros'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      cons: (data['cons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      rating: (data['rating'] as num?)?.toInt(),
      createdAt: parseTimestamp(data['createdAt']),
      updatedAt: parseTimestamp(data['updatedAt']),
    );
  }

  /// Firestore'a yazılacak map.
  Map<String, dynamic> toMap() {
    return {
      'comparisonType': comparisonType,
      'entityAId': entityAId,
      'entityBId': entityBId,
      'note': note,
      if (pros.isNotEmpty) 'pros': pros,
      if (cons.isNotEmpty) 'cons': cons,
      if (rating != null) 'rating': rating,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Güncelleme için sadece değişen alanları döndürür.
  Map<String, dynamic> toUpdateMap() {
    return {
      'note': note,
      'pros': pros,
      'cons': cons,
      if (rating != null) 'rating': rating,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ComparisonNote copyWith({
    String? note,
    List<String>? pros,
    List<String>? cons,
    int? rating,
    bool clearRating = false,
  }) {
    return ComparisonNote(
      id: id,
      comparisonType: comparisonType,
      entityAId: entityAId,
      entityBId: entityBId,
      note: note ?? this.note,
      pros: pros ?? this.pros,
      cons: cons ?? this.cons,
      rating: clearRating ? null : (rating ?? this.rating),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
