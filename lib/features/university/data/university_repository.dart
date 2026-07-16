import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/utils/turkish_compare.dart';
import '../domain/models/city_model.dart';
import '../domain/models/university_model.dart';
import '../domain/models/department_model.dart';
import '../../../core/utils/university_abbreviations.dart';

class UniversityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── In-memory Cache ─────────────────────────────────────────────
  List<CityModel>? _citiesCache;
  List<UniversityModel>? _universitiesCache;
  final Map<String, List<DepartmentModel>> _departmentsCache = {};
  List<DepartmentModel>? _allDepartmentsCache;
  DateTime? _lastFetchTime;

  /// Cache geçerli mi? (15 dakika TTL — puan verisi az değişir)
  bool get _isCacheValid =>
      _lastFetchTime != null &&
      DateTime.now().difference(_lastFetchTime!) < const Duration(minutes: 15);

  /// Cache'i temizle (pull-to-refresh için)
  void clearCache() {
    _citiesCache = null;
    _universitiesCache = null;
    _departmentsCache.clear();
    _allDepartmentsCache = null;
    _lastFetchTime = null;
  }

  // ─── Şehirler ─────────────────────────────────────────────────

  Future<List<CityModel>> getCities() async {
    if (_citiesCache != null && _isCacheValid) return _citiesCache!;

    final snapshot = await _firestore
        .collection('cities')
        .get(const GetOptions(source: Source.serverAndCache));
    _citiesCache = snapshot.docs
        .map((doc) => CityModel.fromMap(doc.data(), doc.id))
        .toList();
    _citiesCache!.sort((a, b) => turkishCompare(a.name, b.name));
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
        .get(const GetOptions(source: Source.serverAndCache));
    _universitiesCache = snapshot.docs
        .map((doc) => UniversityModel.fromMap(doc.data(), doc.id))
        .toList();
    _universitiesCache!.sort((a, b) => turkishCompare(a.name, b.name));
    _lastFetchTime = DateTime.now();
    return _universitiesCache!;
  }

  Future<List<UniversityModel>> getUniversitiesByCity(String cityId) async {
    // Önce full cache'den filtrele
    if (_universitiesCache != null && _isCacheValid) {
      final filtered = _universitiesCache!.where((u) => u.cityId == cityId).toList();
      filtered.sort((a, b) => turkishCompare(a.name, b.name));
      return filtered;
    }

    final snapshot = await _firestore
        .collection('universities')
        .where('cityId', isEqualTo: cityId)
        .get();
    final list = snapshot.docs
        .map((doc) => UniversityModel.fromMap(doc.data(), doc.id))
        .toList();
    list.sort((a, b) => turkishCompare(a.name, b.name));
    return list;
  }

  Future<List<UniversityModel>> getUniversitiesByType(String type) async {
    // Önce full cache'den filtrele
    if (_universitiesCache != null && _isCacheValid) {
      final filtered = _universitiesCache!.where((u) => u.type == type).toList();
      filtered.sort((a, b) => turkishCompare(a.name, b.name));
      return filtered;
    }

    final snapshot = await _firestore
        .collection('universities')
        .where('type', isEqualTo: type)
        .get();
    final list = snapshot.docs
        .map((doc) => UniversityModel.fromMap(doc.data(), doc.id))
        .toList();
    list.sort((a, b) => turkishCompare(a.name, b.name));
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

    // Önce server'dan dene, başarısız olursa cache'ten oku (offline destek)
    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _firestore
          .collection('departments')
          .where('universityId', isEqualTo: uniId)
          .get(const GetOptions(source: Source.serverAndCache));
    } catch (_) {
      // Offline fallback — Firestore cache'inden oku
      snapshot = await _firestore
          .collection('departments')
          .where('universityId', isEqualTo: uniId)
          .get(const GetOptions(source: Source.cache));
    }
    
    final departments = snapshot.docs
        .map((doc) => DepartmentModel.fromMap(doc.data(), doc.id))
        .toList();

    // Lisans önce, Önlisans sonra, isimle sırala
    departments.sort((a, b) {
      if (a.type != b.type) {
        return a.type == 'Lisans' ? -1 : 1;
      }
      return turkishCompare(a.name, b.name);
    });

    _departmentsCache[uniId] = departments;
    return departments;
  }

  Future<List<DepartmentModel>> getAllDepartments() async {
    if (_allDepartmentsCache != null && _isCacheValid) {
      return _allDepartmentsCache!;
    }

    // ÖNEMLİ (maliyet): `departments` koleksiyonu migration ile
    // assets/data/department_scores.json'dan birebir yazılır. 7.386 dokümanı
    // toplu çekmek her seferinde 7.386 okuma faturalandırır — bunun yerine
    // sürüm eşleşiyorsa aynı veri asset'ten kurulur (1 okuma: _meta kontrolü).
    // Not: asset'te avgRating/reviewCount yoktur; bu toplu liste yalnızca
    // puan/eşleştirme akışlarında kullanıldığından sorun olmaz. Yorum verisi
    // gereken detay ekranları Firestore'dan okumaya devam eder.
    try {
      if (await _isAssetScoresCurrent()) {
        _allDepartmentsCache = await _loadDepartmentsFromAsset();
        return _allDepartmentsCache!;
      }
    } catch (_) {
      // Asset okunamadı/bozuk — Firestore'a düş.
    }

    // Asset eski (uygulama güncellenmemiş) — Firestore'dan tam çekim.
    final snapshot = await _firestore
        .collection('departments')
        .get(const GetOptions(source: Source.serverAndCache));

    _allDepartmentsCache = snapshot.docs
        .where((doc) => !doc.id.startsWith('_')) // _meta sürüm dokümanını atla
        .map((doc) => DepartmentModel.fromMap(doc.data(), doc.id))
        .toList();

    return _allDepartmentsCache!;
  }

  // ── Asset tabanlı toplu bölüm verisi ──────────────────────────

  static const String _scoresAssetPath = 'assets/data/department_scores.json';
  List<DepartmentModel>? _assetDepartmentsCache;
  String? _assetScoresVersion;

  /// Firestore'daki veri sürümü (`departments/_meta`) asset ile aynı mı?
  ///
  /// `_meta` henüz yoksa ya da okunamazsa (offline dahil) asset güncel kabul
  /// edilir — asset her koşulda çalışan yerel kaynaktır. Sürüm farklıysa
  /// (eski uygulama + yeni migration) detay ekranlarıyla tutarlılık için
  /// Firestore'a düşülür.
  Future<bool> _isAssetScoresCurrent() async {
    String? remoteVersion;
    try {
      final meta = await _firestore
          .collection('departments')
          .doc('_meta')
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 5));
      remoteVersion = meta.data()?['version'] as String?;
    } catch (_) {
      // _meta okunamadı (offline/izin/timeout) — asset güncel kabul edilir.
      return true;
    }
    if (remoteVersion == null) return true;
    // Parse hatası buradan yukarı fırlar → getAllDepartments Firestore'a düşer.
    await _parseScoresAssetIfNeeded();
    return remoteVersion == _assetScoresVersion;
  }

  Future<List<DepartmentModel>> _loadDepartmentsFromAsset() async {
    await _parseScoresAssetIfNeeded();
    return _assetDepartmentsCache!;
  }

  Future<void> _parseScoresAssetIfNeeded() async {
    if (_assetDepartmentsCache != null) return;

    final jsonStr = await rootBundle.loadString(_scoresAssetPath);
    // Büyük JSON'u ana isolate dışında çöz (kare düşürmemek için).
    final data = await compute(_decodeJsonMap, jsonStr);
    _assetScoresVersion = data['version'] as String?;

    final scores = (data['scores'] as List).cast<Map<String, dynamic>>();
    _assetDepartmentsCache = scores.map((s) {
      // Migration'ın Firestore'a yazdığı doküman şekliyle birebir aynı —
      // bkz. lib/scripts/department_scores_migration.dart
      return DepartmentModel.fromMap({
        'universityId': s['universityId'],
        'name': s['name'],
        'faculty': s['faculty'],
        'type': s['type'],
        'language': s['language'],
        'duration': s['duration'],
        'baseScore': s['baseScore'],
        'ranking': s['ranking'],
        'quota': s['quota'],
        'scoreType': s['scoreType'],
        'scoreData': {
          'year': s['year'],
          'scoreType': s['scoreType'],
          'baseScore': s['baseScore'],
          'ranking': s['ranking'],
          'quota': s['quota'],
          'placedCount': s['placedCount'],
          'previousYears': s['previousYears'] ?? {},
        },
      }, s['deptId'] as String);
    }).toList();
  }

  Future<DepartmentModel?> getDepartment(String deptId) async {
    // Önce cache'den bak
    for (final depts in _departmentsCache.values) {
      try {
        return depts.firstWhere((d) => d.id == deptId);
      } catch (_) {}
    }

    // Network'te takılma olursa cache'e düş ve timeout ile hızlı dön.
    try {
      final doc = await _firestore
          .collection('departments')
          .doc(deptId)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 6));
      if (!doc.exists || doc.data() == null) return null;
      return DepartmentModel.fromMap(doc.data()!, doc.id);
    } catch (_) {
      try {
        final cachedDoc = await _firestore
            .collection('departments')
            .doc(deptId)
            .get(const GetOptions(source: Source.cache))
            .timeout(const Duration(seconds: 3));
        if (!cachedDoc.exists || cachedDoc.data() == null) return null;
        return DepartmentModel.fromMap(cachedDoc.data()!, cachedDoc.id);
      } catch (_) {
        return null;
      }
    }
  }

  // ─── Arama ────────────────────────────────────────────────────
  // ~100 üniversite ölçeğinde client-side arama yeterli (tek koleksiyon
  // okuması cache'leniyor); belirgin büyümede sunucu tarafına taşınmalı.

  Future<List<UniversityModel>> searchUniversities(String query) async {
    if (query.trim().isEmpty) return [];
    
    final allUnis = await getAllUniversities();
    final lowerQuery = query.toLowerCase().trim();
    final normalizedQuery = turkishNormalize(lowerQuery);
    
    return allUnis.where((uni) {
      // 1. İsim eşleşmesi
      if (uni.name.toLowerCase().contains(lowerQuery)) return true;
      // 2. Normalize eşleşme (odtu → odtü)
      if (turkishNormalize(uni.name).contains(normalizedQuery)) return true;
      // 3. Alias eşleşmesi (kısaltmalar)
      if (uni.aliases.any((a) {
        final la = a.toLowerCase();
        return la.contains(lowerQuery) ||
               turkishNormalize(la).contains(normalizedQuery);
      })) {
        return true;
      }
      // 4. Sistem kısaltması (UniversityAbbreviations) eşleşmesi
      final shortName = UniversityAbbreviations.shorten(uni.name).toLowerCase();
      if (shortName != uni.name.toLowerCase()) {
        if (shortName.contains(lowerQuery) || turkishNormalize(shortName).contains(normalizedQuery)) {
          return true;
        }
      }
      return false;
    }).toList();
  }
}

/// `compute` ile ayrı isolate'ta çalışır — top-level olmak zorunda.
Map<String, dynamic> _decodeJsonMap(String source) =>
    json.decode(source) as Map<String, dynamic>;
