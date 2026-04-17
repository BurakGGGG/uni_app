class UniversityModel {
  final String id;
  final String cityId; // Şehrin plaka kodu veya ID'si
  final String name;
  final String type; // "Devlet" veya "Vakıf"
  final bool hasCampus; // Kampüslü mü?
  final String logoUrl;
  final String photoUrl;
  final String description;
  final int establishedYear;
  final String website;

  UniversityModel({
    required this.id,
    required this.cityId,
    required this.name,
    required this.type,
    required this.hasCampus,
    required this.logoUrl,
    required this.photoUrl,
    required this.description,
    required this.establishedYear,
    required this.website,
  });

  factory UniversityModel.fromMap(Map<String, dynamic> map, String id) {
    return UniversityModel(
      id: id,
      cityId: map['cityId'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      hasCampus: map['hasCampus'] ?? true,
      logoUrl: map['logoUrl'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      description: map['description'] ?? '',
      establishedYear: map['establishedYear'] ?? 0,
      website: map['website'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cityId': cityId,
      'name': name,
      'type': type,
      'hasCampus': hasCampus,
      'logoUrl': logoUrl,
      'photoUrl': photoUrl,
      'description': description,
      'establishedYear': establishedYear,
      'website': website,
    };
  }
}
