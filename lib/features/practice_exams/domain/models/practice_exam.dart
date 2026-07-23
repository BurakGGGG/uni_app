import '../../../score_calculator/domain/models/multi_score_result.dart';
import '../../../score_calculator/domain/models/score_input.dart';
import '../../../score_calculator/domain/models/yks_subject.dart';

/// Denemenin kapsamı — hangi ders bloklarının girildiğini söyler.
/// Ders bazlı analiz, girilmemiş blokları bu bilgiyle dışlar.
enum PracticeExamKind {
  tyt('TYT'),
  ayt('AYT'),
  genel('Genel'),
  ydt('YDT');

  const PracticeExamKind(this.labelTr);

  final String labelTr;

  /// Bu türde girilmesi beklenen dersler. Ders analizinde kapsam dışı
  /// bölümlerin "0 net" gibi görünüp ortalamayı bozmasını engeller.
  List<YksSubject> get subjects {
    switch (this) {
      case PracticeExamKind.tyt:
        return YksSubject.bySection(YksSection.tyt);
      case PracticeExamKind.ayt:
        return [
          ...YksSubject.bySection(YksSection.aytSay),
          ...YksSubject.bySection(YksSection.aytEaSoz),
          ...YksSubject.bySection(YksSection.aytSoz2),
        ];
      case PracticeExamKind.ydt:
        return YksSubject.bySection(YksSection.ydt);
      case PracticeExamKind.genel:
        return YksSubject.values;
    }
  }

  static PracticeExamKind parse(String? raw) =>
      values.asNameMap()[raw] ?? PracticeExamKind.genel;
}

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

/// Kullanıcının deneme defterindeki tek kayıt.
///
/// Gövde [input] içinde tam saklanır — netler, girilen sıra ya da girilen puan
/// hepsi `ScoreInput`'un alanlarıdır. Bu sayede kayıt hesaplama ekranına geri
/// yüklenebilir ve `entryMode` kaydın "neyle girildiğini" tek başına söyler.
class PracticeExam {
  /// millisSinceEpoch — Firestore doküman kimliğiyle aynı.
  final String id;

  /// Denemenin çözüldüğü gün (kullanıcı seçer; kaydedildiği andan farklı olabilir).
  final DateTime takenAt;
  final DateTime createdAt;

  /// Senkron çakışması bu alanla çözülür: yeni olan kazanır.
  final DateTime updatedAt;

  final String name; // "TYT Deneme 5"
  final String publisher; // "3D Yayınları" — boş olabilir
  final PracticeExamKind kind;
  final int year; // katsayı yılı
  final ScoreInput input;
  final List<TypeScoreSnapshot> results;
  final String note;

  /// Mezar taşı — silme işleminin diğer cihazlara yayılması için.
  final bool deleted;

  static const int maxNameLength = 60;
  static const int maxPublisherLength = 40;
  static const int maxNoteLength = 300;

  const PracticeExam({
    required this.id,
    required this.takenAt,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    this.publisher = '',
    this.kind = PracticeExamKind.genel,
    required this.year,
    required this.input,
    this.results = const [],
    this.note = '',
    this.deleted = false,
  });

  factory PracticeExam.fromOutcome({
    required MultiScoreOutcome outcome,
    required ScoreInput input,
    required String name,
    String publisher = '',
    PracticeExamKind kind = PracticeExamKind.genel,
    DateTime? takenAt,
    String note = '',
  }) {
    final now = DateTime.now();
    return PracticeExam(
      id: now.millisecondsSinceEpoch.toString(),
      takenAt: takenAt ?? now,
      createdAt: now,
      updatedAt: now,
      name: name,
      publisher: publisher,
      kind: kind,
      year: outcome.year,
      input: input,
      results: [
        for (final o in outcome.outcomes) TypeScoreSnapshot.fromOutcome(o),
      ],
      note: note,
    );
  }

  /// `calc_history_v1` kaydını yeni modele taşır. Eski kayıtta deneme tarihi
  /// yoktu — kaydedildiği an deneme tarihi sayılır; yayın ve tür bilinmiyor.
  factory PracticeExam.fromLegacyJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now();
    return PracticeExam(
      id: (json['id'] as String?)?.isNotEmpty == true
          ? json['id'] as String
          : createdAt.millisecondsSinceEpoch.toString(),
      takenAt: createdAt,
      createdAt: createdAt,
      updatedAt: createdAt,
      name: json['label'] as String? ?? 'Deneme',
      kind: PracticeExamKind.genel,
      year: (json['year'] as num?)?.toInt() ?? 2026,
      input: ScoreInput.fromJson(
          json['input'] as Map<String, dynamic>? ?? const {}),
      results: [
        for (final r in (json['results'] as List<dynamic>? ?? const []))
          TypeScoreSnapshot.fromJson(r as Map<String, dynamic>),
      ],
    );
  }

  /// Toplam net — denemeler arası ilerleme göstergesinin temeli.
  double get totalNet => input.totalNet;

  /// Netlerle girilmiş kayıt: ders bazlı analiz yalnız bunlardan beslenir.
  bool get hasNets =>
      input.entryMode == NetEntryMode.correctWrong ||
      input.entryMode == NetEntryMode.directNet;

  /// Sıra girilerek kaydedilen deneme (net yok).
  bool get isRankMode => input.isRankMode;

  /// Bu kayıtla [other] arasındaki sıra ilerlemesi (pozitif = sıra iyileşti).
  /// İki kaydın da aynı türde sırası olması yeter — tahmini sıra da sayılır.
  int? rankProgressOver(PracticeExam other) {
    final mine = best;
    if (mine?.estimatedRank == null) return null;
    final theirs = other.byType(mine!.scoreType);
    if (theirs?.estimatedRank == null) return null;
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

  PracticeExam copyWith({
    DateTime? takenAt,
    DateTime? updatedAt,
    String? name,
    String? publisher,
    PracticeExamKind? kind,
    int? year,
    ScoreInput? input,
    List<TypeScoreSnapshot>? results,
    String? note,
    bool? deleted,
  }) {
    return PracticeExam(
      id: id,
      takenAt: takenAt ?? this.takenAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      name: name ?? this.name,
      publisher: publisher ?? this.publisher,
      kind: kind ?? this.kind,
      year: year ?? this.year,
      input: input ?? this.input,
      results: results ?? this.results,
      note: note ?? this.note,
      deleted: deleted ?? this.deleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'takenAt': takenAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'name': name,
        'publisher': publisher,
        'kind': kind.name,
        'year': year,
        'input': input.toJson(),
        'results': [for (final r in results) r.toJson()],
        'note': note,
        'deleted': deleted,
      };

  factory PracticeExam.fromJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now();
    return PracticeExam(
      id: json['id'] as String? ?? '',
      takenAt:
          DateTime.tryParse(json['takenAt'] as String? ?? '') ?? createdAt,
      createdAt: createdAt,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? createdAt,
      name: json['name'] as String? ?? 'Deneme',
      publisher: json['publisher'] as String? ?? '',
      kind: PracticeExamKind.parse(json['kind'] as String?),
      year: (json['year'] as num?)?.toInt() ?? 2026,
      input: ScoreInput.fromJson(
          json['input'] as Map<String, dynamic>? ?? const {}),
      results: [
        for (final r in (json['results'] as List<dynamic>? ?? const []))
          TypeScoreSnapshot.fromJson(r as Map<String, dynamic>),
      ],
      note: json['note'] as String? ?? '',
      deleted: json['deleted'] as bool? ?? false,
    );
  }
}
