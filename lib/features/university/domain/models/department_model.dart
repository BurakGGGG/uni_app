class DepartmentModel {
  final String id;
  final String universityId;
  final String name;
  final String faculty; // Fakülte / Yüksekokul
  final String type; // "Lisans" veya "Önlisans"
  final String language; // "Türkçe" veya "İngilizce"
  final double? baseScore; // ÖSYM taban puanı
  final int? ranking; // Sıralama
  final String? scoreType; // SAY, EA, SÖZ, DİL, TYT
  final int duration; // Yıl (2 veya 4+)

  DepartmentModel({
    required this.id,
    required this.universityId,
    required this.name,
    required this.faculty,
    required this.type,
    required this.language,
    this.baseScore,
    this.ranking,
    this.scoreType,
    this.duration = 4,
  });

  factory DepartmentModel.fromMap(Map<String, dynamic> map, String id) {
    return DepartmentModel(
      id: id,
      universityId: map['universityId'] ?? '',
      name: map['name'] ?? '',
      faculty: map['faculty'] ?? '',
      type: map['type'] ?? '',
      language: map['language'] ?? 'Türkçe',
      baseScore: (map['baseScore'] as num?)?.toDouble(),
      ranking: map['ranking'] as int?,
      scoreType: map['scoreType'] as String?,
      duration: map['duration'] ?? (map['type'] == 'Önlisans' ? 2 : 4),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'universityId': universityId,
      'name': name,
      'faculty': faculty,
      'type': type,
      'language': language,
      'baseScore': baseScore,
      'ranking': ranking,
      'scoreType': scoreType,
      'duration': duration,
    };
  }
}
