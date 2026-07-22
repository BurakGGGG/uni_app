import 'multi_score_result.dart';
import 'score_input.dart';

/// Geçmiş kaydındaki tek türün özet sonucu.
class TypeScoreSnapshot {
  final String scoreType;
  final double rawScore;
  final double placementScore;
  final int? estimatedRank;
  final double? percentile;

  const TypeScoreSnapshot({
    required this.scoreType,
    required this.rawScore,
    required this.placementScore,
    this.estimatedRank,
    this.percentile,
  });

  factory TypeScoreSnapshot.fromOutcome(ScoreTypeOutcome outcome) {
    return TypeScoreSnapshot(
      scoreType: outcome.score.scoreType,
      rawScore: outcome.score.rawScore,
      placementScore: outcome.score.placementScore,
      estimatedRank: outcome.estimatedRank,
      percentile: outcome.percentile,
    );
  }

  Map<String, dynamic> toJson() => {
        'scoreType': scoreType,
        'rawScore': rawScore,
        'placementScore': placementScore,
        if (estimatedRank != null) 'estimatedRank': estimatedRank,
        if (percentile != null) 'percentile': percentile,
      };

  factory TypeScoreSnapshot.fromJson(Map<String, dynamic> json) {
    return TypeScoreSnapshot(
      scoreType: json['scoreType'] as String? ?? '',
      rawScore: (json['rawScore'] as num?)?.toDouble() ?? 0,
      placementScore: (json['placementScore'] as num?)?.toDouble() ?? 0,
      estimatedRank: (json['estimatedRank'] as num?)?.toInt(),
      percentile: (json['percentile'] as num?)?.toDouble(),
    );
  }
}

/// Bir "deneme" kaydı: net anlık görüntüsü + tür sonuçları.
/// Netler [input] içinde tam saklanır, böylece geçmişten geri yüklenebilir.
class CalcHistoryEntry {
  final String id; // millisSinceEpoch
  final DateTime createdAt;
  final String label; // "Deneme 3" — kullanıcı yeniden adlandırabilir
  final int year;
  final ScoreInput input;
  final List<TypeScoreSnapshot> results;

  const CalcHistoryEntry({
    required this.id,
    required this.createdAt,
    required this.label,
    required this.year,
    required this.input,
    required this.results,
  });

  factory CalcHistoryEntry.fromOutcome({
    required MultiScoreOutcome outcome,
    required ScoreInput input,
    required String label,
  }) {
    final now = DateTime.now();
    return CalcHistoryEntry(
      id: now.millisecondsSinceEpoch.toString(),
      createdAt: now,
      label: label,
      year: outcome.year,
      input: input,
      results: [
        for (final o in outcome.outcomes) TypeScoreSnapshot.fromOutcome(o),
      ],
    );
  }

  /// Toplam net — denemeler arası ilerleme göstergesinin temeli.
  double get totalNet => input.totalNet;

  /// Sıra modunda kaydedilen deneme: net yerine başarı sırası girilmiş.
  bool get isRankMode => input.isRankMode;

  /// Bu kayıtla [other] arasındaki sıra ilerlemesi (pozitif = sıra iyileşti).
  /// Yalnız iki kayıt da aynı türde sıra moduysa hesaplanır.
  int? rankProgressOver(CalcHistoryEntry other) {
    if (!isRankMode || !other.isRankMode) return null;
    final mine = results.isEmpty ? null : results.first;
    if (mine == null) return null;
    final theirs = other.byType(mine.scoreType);
    if (mine.estimatedRank == null || theirs?.estimatedRank == null) {
      return null;
    }
    return theirs!.estimatedRank! - mine.estimatedRank!;
  }

  TypeScoreSnapshot? byType(String scoreType) {
    for (final r in results) {
      if (r.scoreType == scoreType) return r;
    }
    return null;
  }

  /// En iyi (en düşük tahmini sıralı) tür; sıra yoksa ilk tür.
  TypeScoreSnapshot? get best {
    if (results.isEmpty) return null;
    TypeScoreSnapshot? withRank;
    for (final r in results) {
      final rank = r.estimatedRank;
      if (rank == null) continue;
      if (withRank == null || rank < withRank.estimatedRank!) withRank = r;
    }
    return withRank ?? results.first;
  }

  CalcHistoryEntry copyWith({String? label}) {
    return CalcHistoryEntry(
      id: id,
      createdAt: createdAt,
      label: label ?? this.label,
      year: year,
      input: input,
      results: results,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'label': label,
        'year': year,
        'input': input.toJson(),
        'results': [for (final r in results) r.toJson()],
      };

  factory CalcHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CalcHistoryEntry(
      id: json['id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      label: json['label'] as String? ?? 'Deneme',
      year: (json['year'] as num?)?.toInt() ?? 2026,
      input: ScoreInput.fromJson(
          json['input'] as Map<String, dynamic>? ?? const {}),
      results: [
        for (final r in (json['results'] as List<dynamic>? ?? const []))
          TypeScoreSnapshot.fromJson(r as Map<String, dynamic>),
      ],
    );
  }
}
