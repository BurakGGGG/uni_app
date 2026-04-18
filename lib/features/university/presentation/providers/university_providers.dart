import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/university_repository.dart';
import '../../domain/models/city_model.dart';
import '../../domain/models/university_model.dart';
import '../../domain/models/department_model.dart';

/// Repository provider — singleton, in-memory cache'i korur
final universityRepositoryProvider = Provider<UniversityRepository>((ref) {
  return UniversityRepository();
});

/// Tüm şehirler (keepAlive: navigasyon arası cache korunur)
final citiesProvider = FutureProvider<List<CityModel>>((ref) async {
  ref.keepAlive();
  return ref.read(universityRepositoryProvider).getCities();
});

/// Tüm üniversiteler (keepAlive: ana veri seti)
final allUniversitiesProvider = FutureProvider<List<UniversityModel>>((ref) async {
  ref.keepAlive();
  return ref.read(universityRepositoryProvider).getAllUniversities();
});

/// Şehre göre üniversiteler (cache'den filtreler)
final universitiesByCityProvider = FutureProvider.family<List<UniversityModel>, String>((ref, cityId) async {
  ref.keepAlive();
  return ref.read(universityRepositoryProvider).getUniversitiesByCity(cityId);
});

/// Tek üniversite detayı (cache'den bulur)
final universityDetailProvider = FutureProvider.family<UniversityModel?, String>((ref, uniId) async {
  ref.keepAlive();
  return ref.read(universityRepositoryProvider).getUniversity(uniId);
});

/// Tek şehir detayı (cache'den bulur)
final cityDetailProvider = FutureProvider.family<CityModel?, String>((ref, cityId) async {
  ref.keepAlive();
  return ref.read(universityRepositoryProvider).getCity(cityId);
});

/// Üniversitenin bölümleri (cache'den)
final departmentsByUniversityProvider = FutureProvider.family<List<DepartmentModel>, String>((ref, uniId) async {
  ref.keepAlive();
  return ref.read(universityRepositoryProvider).getDepartmentsByUniversity(uniId);
});

/// Tek bölüm detayı (cache'den bulur)
final departmentDetailProvider = FutureProvider.family<DepartmentModel?, String>((ref, deptId) async {
  ref.keepAlive();
  return ref.read(universityRepositoryProvider).getDepartment(deptId);
});

/// Arama sonuçları
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<UniversityModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) {
    return ref.read(universityRepositoryProvider).getAllUniversities();
  }
  return ref.read(universityRepositoryProvider).searchUniversities(query);
});
