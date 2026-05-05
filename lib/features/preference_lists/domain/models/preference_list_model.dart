import 'package:cloud_firestore/cloud_firestore.dart';

class PreferenceListModel {
  final String id;
  final String userId;
  final String userName;          // denormalize (paylaşım için)
  final String? userPhotoUrl;     // denormalize
  final String title;
  final String description;
  final bool isPublic;
  final String shareSlug;         // 5 karakter, tüm sistemde unique
  final int viewCount;
  final List<PreferenceItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  PreferenceListModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.title,
    this.description = '',
    this.isPublic = false,
    required this.shareSlug,
    this.viewCount = 0,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  static const int maxItems = 24;     // ÖSYM tercih limiti
  static const int maxLists = 10;     // Bir kullanıcı max 10 liste

  String get publicUrl => 'https://unisec.app/list/$shareSlug';

  factory PreferenceListModel.fromMap(Map<String, dynamic> m, String id) {
    final items = (m['items'] as List?) ?? [];
    return PreferenceListModel(
      id: id,
      userId: m['userId'] ?? '',
      userName: m['userName'] ?? 'Kullanıcı',
      userPhotoUrl: m['userPhotoUrl'],
      title: m['title'] ?? 'Adsız Liste',
      description: m['description'] ?? '',
      isPublic: m['isPublic'] ?? false,
      shareSlug: m['shareSlug'] ?? '',
      viewCount: m['viewCount'] ?? 0,
      items: items.map((e) => PreferenceItem.fromMap(e as Map<String, dynamic>))
                  .toList(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userName': userName,
    'userPhotoUrl': userPhotoUrl,
    'title': title,
    'description': description,
    'isPublic': isPublic,
    'shareSlug': shareSlug,
    'viewCount': viewCount,
    'items': items.map((e) => e.toMap()).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  PreferenceListModel copyWith({
    String? title,
    String? description,
    bool? isPublic,
    List<PreferenceItem>? items,
    int? viewCount,
  }) {
    return PreferenceListModel(
      id: id,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      shareSlug: shareSlug,
      viewCount: viewCount ?? this.viewCount,
      items: items ?? this.items,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class PreferenceItem {
  final String deptId;
  final String uniId;
  final int order;          // 1-24 arası tercih sırası
  final String? note;       // Kullanıcı notu

  // Denormalize alanlar (paylaşım sırasında kart için)
  final String deptName;
  final String uniName;
  final String? uniLogoUrl;

  const PreferenceItem({
    required this.deptId,
    required this.uniId,
    required this.order,
    this.note,
    required this.deptName,
    required this.uniName,
    this.uniLogoUrl,
  });

  factory PreferenceItem.fromMap(Map<String, dynamic> m) => PreferenceItem(
    deptId: m['deptId'] ?? '',
    uniId: m['uniId'] ?? '',
    order: (m['order'] as num?)?.toInt() ?? 0,
    note: m['note'],
    deptName: m['deptName'] ?? '',
    uniName: m['uniName'] ?? '',
    uniLogoUrl: m['uniLogoUrl'],
  );

  Map<String, dynamic> toMap() => {
    'deptId': deptId,
    'uniId': uniId,
    'order': order,
    if (note != null) 'note': note,
    'deptName': deptName,
    'uniName': uniName,
    if (uniLogoUrl != null) 'uniLogoUrl': uniLogoUrl,
  };

  PreferenceItem copyWith({int? order, String? note}) => PreferenceItem(
    deptId: deptId,
    uniId: uniId,
    order: order ?? this.order,
    note: note ?? this.note,
    deptName: deptName,
    uniName: uniName,
    uniLogoUrl: uniLogoUrl,
  );
}
