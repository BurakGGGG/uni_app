import 'package:cloud_firestore/cloud_firestore.dart';

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
  final int? quota; // Kontenjan

  // ── Sprint 3 — Yorum Sistemi İçin Rating Alanları ──────────────
  final double avgRating;
  final int reviewCount;
  /// Kategori bazlı ortalama puanlar (eğitim kalitesi, hoca, iş imkanı, staj, ders yükü)
  final Map<String, double> categoryRatings;

  // ── Sprint 4.5 — ÖSYM Verileri ──────────────
  final DepartmentScoreData? scoreData;
  final DateTime? lastScoreUpdate;

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
    this.quota,
    this.avgRating = 0.0,
    this.reviewCount = 0,
    this.categoryRatings = const {},
    this.scoreData,
    this.lastScoreUpdate,
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
      quota: map['quota'] as int?,
      avgRating: (map['avgRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      categoryRatings: Map<String, double>.from(
        (map['categoryRatings'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ) ?? {},
      ),
      scoreData: map['scoreData'] != null
          ? DepartmentScoreData.fromMap(map['scoreData'])
          : null,
      lastScoreUpdate: (map['lastScoreUpdate'] as Timestamp?)?.toDate(),
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
      'quota': quota,
      'avgRating': avgRating,
      'reviewCount': reviewCount,
      'categoryRatings': categoryRatings,
      if (scoreData != null) 'scoreData': scoreData!.toMap(),
      if (lastScoreUpdate != null) 'lastScoreUpdate': Timestamp.fromDate(lastScoreUpdate!),
    };
  }
}

// ── YENİ Model ────────────────────────────────────────────
class DepartmentScoreData {
  final int year;
  final String scoreType;       // SAY, EA, SÖZ, DİL, TYT
  final double baseScore;
  final int ranking;
  final int quota;
  final int placedCount;
  final Map<int, YearlyScore> previousYears;

  const DepartmentScoreData({
    required this.year,
    required this.scoreType,
    required this.baseScore,
    required this.ranking,
    required this.quota,
    required this.placedCount,
    this.previousYears = const {},
  });

  /// Doluluk oranı (yerleşen / kontenjan)
  double get fillRate => quota == 0 ? 0 : placedCount / quota;

  /// Tüm yıllar (mevcut + geçmiş) — küçükten büyüğe
  List<MapEntry<int, YearlyScore>> get allYearsAscending {
    final all = <int, YearlyScore>{
      year: YearlyScore(baseScore: baseScore, ranking: ranking),
      ...previousYears,
    };
    final sorted = all.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return sorted;
  }

  /// Geçen yıla göre puan farkı (negatif = düşmüş, pozitif = yükselmiş)
  double? get yearOverYearDelta {
    final prev = previousYears[year - 1];
    if (prev == null) return null;
    return baseScore - prev.baseScore;
  }

  factory DepartmentScoreData.fromMap(Map<String, dynamic> map) {
    final prev = (map['previousYears'] as Map?)?.cast<String, dynamic>() ?? {};
    return DepartmentScoreData(
      year: map['year'] ?? 0,
      scoreType: map['scoreType'] ?? '',
      baseScore: (map['baseScore'] as num?)?.toDouble() ?? 0,
      ranking: (map['ranking'] as num?)?.toInt() ?? 0,
      quota: (map['quota'] as num?)?.toInt() ?? 0,
      placedCount: (map['placedCount'] as num?)?.toInt() ?? 0,
      previousYears: {
        for (final entry in prev.entries)
          int.parse(entry.key): YearlyScore.fromMap(entry.value as Map<String, dynamic>)
      },
    );
  }

  Map<String, dynamic> toMap() => {
    'year': year,
    'scoreType': scoreType,
    'baseScore': baseScore,
    'ranking': ranking,
    'quota': quota,
    'placedCount': placedCount,
    'previousYears': {
      for (final e in previousYears.entries) e.key.toString(): e.value.toMap()
    },
  };
}

class YearlyScore {
  final double baseScore;
  final int ranking;
  const YearlyScore({required this.baseScore, required this.ranking});

  factory YearlyScore.fromMap(Map<String, dynamic> m) => YearlyScore(
        baseScore: (m['baseScore'] as num).toDouble(),
        ranking: (m['ranking'] as num).toInt(),
      );

  Map<String, dynamic> toMap() => {
        'baseScore': baseScore,
        'ranking': ranking,
      };
}

// ── Null-safe score erişimi ─────────────────────────────────
extension DepartmentScoreFallback on DepartmentModel {
  /// baseScore (legacy) veya scoreData.baseScore, hangisi mevcutsa
  double? get effectiveBaseScore => baseScore ?? scoreData?.baseScore;

  /// ranking (legacy) veya scoreData.ranking
  int? get effectiveRanking => ranking ?? scoreData?.ranking;

  /// scoreType (legacy) veya scoreData.scoreType
  String? get effectiveScoreType => scoreType ?? scoreData?.scoreType;
}

