class DepartmentModel {
  final String id;
  final String universityId;
  final String name;
  final String faculty; // Fakülte / Yüksekokul
  final String type; // "Lisans" veya "Önlisans"
  final String language; // "Türkçe" veya "İngilizce"

  DepartmentModel({
    required this.id,
    required this.universityId,
    required this.name,
    required this.faculty,
    required this.type,
    required this.language,
  });

  factory DepartmentModel.fromMap(Map<String, dynamic> map, String id) {
    return DepartmentModel(
      id: id,
      universityId: map['universityId'] ?? '',
      name: map['name'] ?? '',
      faculty: map['faculty'] ?? '',
      type: map['type'] ?? '',
      language: map['language'] ?? 'Türkçe',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'universityId': universityId,
      'name': name,
      'faculty': faculty,
      'type': type,
      'language': language,
    };
  }
}
