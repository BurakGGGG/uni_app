import 'package:cloud_firestore/cloud_firestore.dart';

enum ComparisonHistoryType {
  university,
  department,
  city;

  String get firestoreValue {
    switch (this) {
      case ComparisonHistoryType.university:
        return 'university';
      case ComparisonHistoryType.department:
        return 'department';
      case ComparisonHistoryType.city:
        return 'city';
    }
  }

  static ComparisonHistoryType fromString(String? value) {
    switch (value) {
      case 'department':
        return ComparisonHistoryType.department;
      case 'city':
        return ComparisonHistoryType.city;
      case 'university':
      default:
        return ComparisonHistoryType.university;
    }
  }
}

/// Kullanıcının kaydedilmiş karşılaştırma geçmişindeki tek bir kayıt.
/// `users/{uid}/comparisonHistory/{historyId}` doc'una karşılık gelir.
class ComparisonHistoryEntry {
  final String id;
  final ComparisonHistoryType type;
  final String entityAId;
  final String entityBId;
  final String entityAName;
  final String entityBName;
  final DateTime createdAt;
  // Logo gösterimi için. "http"/"https" ile başlıyorsa network image,
  // "assets/" ile başlıyorsa local asset olarak render edilir. null ise icon.
  final String? entityALogo;
  final String? entityBLogo;

  const ComparisonHistoryEntry({
    required this.id,
    required this.type,
    required this.entityAId,
    required this.entityBId,
    required this.entityAName,
    required this.entityBName,
    required this.createdAt,
    this.entityALogo,
    this.entityBLogo,
  });

  factory ComparisonHistoryEntry.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final ts = data['createdAt'];
    final createdAt = ts is Timestamp
        ? ts.toDate()
        : (DateTime.tryParse(ts?.toString() ?? '') ?? DateTime.now());
    return ComparisonHistoryEntry(
      id: doc.id,
      type: ComparisonHistoryType.fromString(data['type'] as String?),
      entityAId: data['entityAId'] as String? ?? '',
      entityBId: data['entityBId'] as String? ?? '',
      entityAName: data['entityAName'] as String? ?? '',
      entityBName: data['entityBName'] as String? ?? '',
      entityALogo: data['entityALogo'] as String?,
      entityBLogo: data['entityBLogo'] as String?,
      createdAt: createdAt,
    );
  }
}
