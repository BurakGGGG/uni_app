class CityModel {
  final String id;
  final String name;
  final String plateCode;
  final String photoUrl;
  final int totalUniversityCount; // Şehirdeki toplam üniversite sayısı
  final int appUniversityCount; // Uygulamamızda ekli olan üniversite sayısı

  CityModel({
    required this.id,
    required this.name,
    required this.plateCode,
    required this.photoUrl,
    required this.totalUniversityCount,
    required this.appUniversityCount,
  });

  factory CityModel.fromMap(Map<String, dynamic> map, String id) {
    return CityModel(
      id: id,
      name: map['name'] ?? '',
      plateCode: map['plateCode'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      totalUniversityCount: map['totalUniversityCount'] ?? 0,
      appUniversityCount: map['appUniversityCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'plateCode': plateCode,
      'photoUrl': photoUrl,
      'totalUniversityCount': totalUniversityCount,
      'appUniversityCount': appUniversityCount,
    };
  }
}
