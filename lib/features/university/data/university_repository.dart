import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/city_model.dart';
import '../domain/models/university_model.dart';
import '../domain/models/department_model.dart';

class UniversityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── In-memory Cache ─────────────────────────────────────────────
  List<CityModel>? _citiesCache;
  List<UniversityModel>? _universitiesCache;
  final Map<String, List<DepartmentModel>> _departmentsCache = {};
  DateTime? _lastFetchTime;

  /// Cache geçerli mi? (5 dakika TTL)
  bool get _isCacheValid =>
      _lastFetchTime != null &&
      DateTime.now().difference(_lastFetchTime!) < const Duration(minutes: 5);

  /// Cache'i temizle (pull-to-refresh için)
  void clearCache() {
    _citiesCache = null;
    _universitiesCache = null;
    _departmentsCache.clear();
    _lastFetchTime = null;
  }

  // ─── Şehirler ─────────────────────────────────────────────────

  Future<List<CityModel>> getCities() async {
    if (_citiesCache != null && _isCacheValid) return _citiesCache!;

    final snapshot = await _firestore
        .collection('cities')
        .orderBy('name')
        .get(const GetOptions(source: Source.serverAndCache));
    _citiesCache = snapshot.docs
        .map((doc) => CityModel.fromMap(doc.data(), doc.id))
        .toList();
    _lastFetchTime = DateTime.now();
    return _citiesCache!;
  }

  Future<CityModel?> getCity(String cityId) async {
    // Önce cache'den bak
    if (_citiesCache != null && _isCacheValid) {
      try {
        return _citiesCache!.firstWhere((c) => c.id == cityId);
      } catch (_) {}
    }
    final doc = await _firestore.collection('cities').doc(cityId).get();
    if (!doc.exists || doc.data() == null) return null;
    return CityModel.fromMap(doc.data()!, doc.id);
  }

  // ─── Üniversiteler ────────────────────────────────────────────

  Future<List<UniversityModel>> getAllUniversities() async {
    if (_universitiesCache != null && _isCacheValid) return _universitiesCache!;

    final snapshot = await _firestore
        .collection('universities')
        .orderBy('name')
        .get(const GetOptions(source: Source.serverAndCache));
    _universitiesCache = snapshot.docs
        .map((doc) => UniversityModel.fromMap(doc.data(), doc.id))
        .toList();
    _lastFetchTime = DateTime.now();
    return _universitiesCache!;
  }

  Future<List<UniversityModel>> getUniversitiesByCity(String cityId) async {
    // Önce full cache'den filtrele
    if (_universitiesCache != null && _isCacheValid) {
      final filtered = _universitiesCache!.where((u) => u.cityId == cityId).toList();
      filtered.sort((a, b) => a.name.compareTo(b.name));
      return filtered;
    }

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
    // Önce full cache'den filtrele
    if (_universitiesCache != null && _isCacheValid) {
      final filtered = _universitiesCache!.where((u) => u.type == type).toList();
      filtered.sort((a, b) => a.name.compareTo(b.name));
      return filtered;
    }

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
    // Önce cache'den bak
    if (_universitiesCache != null && _isCacheValid) {
      try {
        return _universitiesCache!.firstWhere((u) => u.id == uniId);
      } catch (_) {}
    }
    final doc = await _firestore.collection('universities').doc(uniId).get();
    if (!doc.exists || doc.data() == null) return null;
    return UniversityModel.fromMap(doc.data()!, doc.id);
  }

  // ─── Bölümler ─────────────────────────────────────────────────

  Future<List<DepartmentModel>> getDepartmentsByUniversity(String uniId) async {
    if (_departmentsCache.containsKey(uniId) && _isCacheValid) {
      return _departmentsCache[uniId]!;
    }

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

    _departmentsCache[uniId] = departments;
    return departments;
  }

  Future<DepartmentModel?> getDepartment(String deptId) async {
    // Önce cache'den bak
    for (final depts in _departmentsCache.values) {
      try {
        return depts.firstWhere((d) => d.id == deptId);
      } catch (_) {}
    }
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
