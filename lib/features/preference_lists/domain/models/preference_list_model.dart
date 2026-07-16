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

  /// Paylaşım linki — Firebase Hosting domain'i (hosting/public'te sunulur).
  /// unisec.app satın alınıp Hosting'e bağlanınca burası güncellenebilir;
  /// web.app linkleri çalışmaya devam eder.
  static const String shareBaseUrl = 'https://unisec-e36e1.web.app';

  String get publicUrl => '$shareBaseUrl/list/$shareSlug';

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
  final String? faculty;
  final String? deptType;     // Lisans / Önlisans
  final String? language;     // Türkçe / İngilizce
  final String? scoreType;    // SAY / EA / SÖZ / DİL / TYT
  final double? baseScore;    // 2024 taban
  final int? ranking;         // 2024 sıralama
  final int? quota;
  final int? placedCount;
  final String? uniBrandHex;  // Kart accent rengi için

  const PreferenceItem({
    required this.deptId,
    required this.uniId,
    required this.order,
    this.note,
    required this.deptName,
    required this.uniName,
    this.uniLogoUrl,
    this.faculty,
    this.deptType,
    this.language,
    this.scoreType,
    this.baseScore,
    this.ranking,
    this.quota,
    this.placedCount,
    this.uniBrandHex,
  });

  factory PreferenceItem.fromMap(Map<String, dynamic> m) => PreferenceItem(
        deptId: m['deptId'] ?? '',
        uniId: m['uniId'] ?? '',
        order: (m['order'] as num?)?.toInt() ?? 0,
        note: m['note'],
        deptName: m['deptName'] ?? '',
        uniName: m['uniName'] ?? '',
        uniLogoUrl: m['uniLogoUrl'],
        faculty: m['faculty'] as String?,
        deptType: m['deptType'] as String?,
        language: m['language'] as String?,
        scoreType: m['scoreType'] as String?,
        baseScore: (m['baseScore'] as num?)?.toDouble(),
        ranking: (m['ranking'] as num?)?.toInt(),
        quota: (m['quota'] as num?)?.toInt(),
        placedCount: (m['placedCount'] as num?)?.toInt(),
        uniBrandHex: m['uniBrandHex'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'deptId': deptId,
        'uniId': uniId,
        'order': order,
        if (note != null) 'note': note,
        'deptName': deptName,
        'uniName': uniName,
        if (uniLogoUrl != null) 'uniLogoUrl': uniLogoUrl,
        if (faculty != null) 'faculty': faculty,
        if (deptType != null) 'deptType': deptType,
        if (language != null) 'language': language,
        if (scoreType != null) 'scoreType': scoreType,
        if (baseScore != null) 'baseScore': baseScore,
        if (ranking != null) 'ranking': ranking,
        if (quota != null) 'quota': quota,
        if (placedCount != null) 'placedCount': placedCount,
        if (uniBrandHex != null) 'uniBrandHex': uniBrandHex,
      };

  PreferenceItem copyWith({int? order, String? note}) => PreferenceItem(
        deptId: deptId,
        uniId: uniId,
        order: order ?? this.order,
        note: note ?? this.note,
        deptName: deptName,
        uniName: uniName,
        uniLogoUrl: uniLogoUrl,
        faculty: faculty,
        deptType: deptType,
        language: language,
        scoreType: scoreType,
        baseScore: baseScore,
        ranking: ranking,
        quota: quota,
        placedCount: placedCount,
        uniBrandHex: uniBrandHex,
      );
}
