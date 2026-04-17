import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/city_model.dart';
import '../domain/models/university_model.dart';
import '../domain/models/department_model.dart';

class UniversityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Şehirler ─────────────────────────────────────────────────

  Future<List<CityModel>> getCities() async {
    final snapshot = await _firestore
        .collection('cities')
        .orderBy('name')
        .get();
    return snapshot.docs
        .map((doc) => CityModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<CityModel?> getCity(String cityId) async {
    final doc = await _firestore.collection('cities').doc(cityId).get();
    if (!doc.exists || doc.data() == null) return null;
    return CityModel.fromMap(doc.data()!, doc.id);
  }

  // ─── Üniversiteler ────────────────────────────────────────────

  Future<List<UniversityModel>> getAllUniversities() async {
    final snapshot = await _firestore
        .collection('universities')
        .orderBy('name')
        .get();
    return snapshot.docs
        .map((doc) => UniversityModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<UniversityModel>> getUniversitiesByCity(String cityId) async {
    final snapshot = await _firestore
        .collection('universities')
        .where('cityId', isEqualTo: cityId)
        .get();
    final list = snapshot.docs
        .map((doc) => UniversityModel.fromMap(doc.data(), doc.id))
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<List<UniversityModel>> getUniversitiesByType(String type) async {
    final snapshot = await _firestore
        .collection('universities')
        .where('type', isEqualTo: type)
        .get();
    final list = snapshot.docs
        .map((doc) => UniversityModel.fromMap(doc.data(), doc.id))
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<UniversityModel?> getUniversity(String uniId) async {
    final doc = await _firestore.collection('universities').doc(uniId).get();
    if (!doc.exists || doc.data() == null) return null;
    return UniversityModel.fromMap(doc.data()!, doc.id);
  }

  // ─── Bölümler ─────────────────────────────────────────────────

  Future<List<DepartmentModel>> getDepartmentsByUniversity(String uniId) async {
    final snapshot = await _firestore
        .collection('departments')
        .where('universityId', isEqualTo: uniId)
        .get();
    
    final departments = snapshot.docs
        .map((doc) => DepartmentModel.fromMap(doc.data(), doc.id))
        .toList();

    // Lisans önce, Önlisans sonra, isimle sırala
    departments.sort((a, b) {
      if (a.type != b.type) {
        return a.type == 'Lisans' ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });

    return departments;
  }

  Future<DepartmentModel?> getDepartment(String deptId) async {
    final doc = await _firestore.collection('departments').doc(deptId).get();
    if (!doc.exists || doc.data() == null) return null;
    return DepartmentModel.fromMap(doc.data()!, doc.id);
  }

  // ─── Arama ────────────────────────────────────────────────────
  // 30 üniversite olduğu için client-side arama yeterli

  Future<List<UniversityModel>> searchUniversities(String query) async {
    if (query.trim().isEmpty) return [];
    
    final allUnis = await getAllUniversities();
    final lowerQuery = query.toLowerCase();
    
    return allUnis.where((uni) {
      return uni.name.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
