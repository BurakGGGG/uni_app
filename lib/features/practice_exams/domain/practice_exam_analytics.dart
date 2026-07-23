import '../../score_calculator/domain/models/yks_subject.dart';
import 'models/practice_exam.dart';

/// Gelişim grafiğinin tek noktası.
class ExamTrendPoint {
  final String examId;
  final String name;
  final DateTime takenAt;

  /// Yerleştirme puanı — sıra girilen kayıtlarda ters tablodan türetilmiştir.
  final double? placementScore;
  final int? rank;
  final double totalNet;

  /// Netler girilmemiş kayıt (yalnız puan/sıra) — net serisinde atlanır.
  final bool hasNets;

  const ExamTrendPoint({
    required this.examId,
    required this.name,
    required this.takenAt,
    this.placementScore,
    this.rank,
    required this.totalNet,
    required this.hasNets,
  });
}

/// Tek dersin son denemelerdeki durumu.
class SubjectStat {
  final YksSubject subject;

  /// Son penceredeki ortalama net.
  final double avgNet;

  /// En son denemedeki net.
  final double lastNet;

  /// Bir önceki pencereye göre ortalama farkı; referans yoksa null.
  final double? delta;

  /// 0..1 — `avgNet / maxQuestions`. Dersler arası karşılaştırma bununla yapılır,
  /// yoksa 40 soruluk Türkçe her zaman 13 soruluk Kimya'yı ezerdi.
  final double successRate;

  /// Ortalamaya giren deneme sayısı.
  final int sampleSize;

  const SubjectStat({
    required this.subject,
    required this.avgNet,
    required this.lastNet,
    required this.delta,
    required this.successRate,
    required this.sampleSize,
  });
}

/// [scoreType] için deneme serisi, eskiden yeniye.
///
/// Türü bu kayıtta hesaplanmamış denemeler atlanır — grafik yalnız
/// karşılaştırılabilir noktaları çizer.
List<ExamTrendPoint> trendFor(List<PracticeExam> exams, String scoreType) {
  final wanted = scoreType.trim().toUpperCase();
  final points = <ExamTrendPoint>[];
  for (final exam in exams) {
    if (exam.deleted) continue;
    final snapshot = wanted.isEmpty ? exam.best : exam.byType(wanted);
    if (snapshot == null) continue;
    points.add(ExamTrendPoint(
      examId: exam.id,
      name: exam.name,
      takenAt: exam.takenAt,
      placementScore: snapshot.placementScore > 0 ? snapshot.placementScore : null,
      rank: snapshot.estimatedRank,
      totalNet: exam.totalNet,
      hasNets: exam.hasNets,
    ));
  }
  points.sort((a, b) => a.takenAt.compareTo(b.takenAt));
  return points;
}

/// Ders bazında güçlü/zayıf analizi.
///
/// Yalnız net gövdeli kayıtlar sayılır. Bir ders ancak **denemenin kapsamına
/// giriyorsa** ortalamaya katılır: TYT denemesinde AYT dersleri "0 net" değil,
/// "girilmemiş"tir — aksi hâlde her TYT denemesi AYT ortalamasını çökertirdi.
/// Sonuç `successRate` azalan sıralı döner (baştakiler güçlü, sondakiler zayıf).
List<SubjectStat> subjectStats(
  List<PracticeExam> exams, {
  int window = 5,
}) {
  final netExams = [
    for (final e in exams)
      if (!e.deleted && e.hasNets) e,
  ]..sort((a, b) => b.takenAt.compareTo(a.takenAt)); // yeniden eskiye

  if (netExams.isEmpty) return const [];

  final recent = netExams.take(window).toList();
  final previous = netExams.skip(window).take(window).toList();

  final stats = <SubjectStat>[];
  for (final subject in YksSubject.values) {
    final samples = _netsOf(recent, subject);
    if (samples.isEmpty) continue;

    final avg = samples.reduce((a, b) => a + b) / samples.length;
    final prior = _netsOf(previous, subject);
    final priorAvg = prior.isEmpty
        ? null
        : prior.reduce((a, b) => a + b) / prior.length;

    stats.add(SubjectStat(
      subject: subject,
      avgNet: avg,
      lastNet: samples.first,
      delta: priorAvg == null ? null : avg - priorAvg,
      successRate: (avg / subject.maxQuestions).clamp(0.0, 1.0),
      sampleSize: samples.length,
    ));
  }

  stats.sort((a, b) => b.successRate.compareTo(a.successRate));
  return stats;
}

/// Kapsamına giren denemelerdeki netler, yeniden eskiye.
List<double> _netsOf(List<PracticeExam> exams, YksSubject subject) {
  return [
    for (final exam in exams)
      if (exam.kind.subjects.contains(subject)) exam.input.netOf(subject),
  ];
}

/// Kesintisiz haftalık deneme serisi.
///
/// Bu hafta henüz deneme girilmediyse sayım geçen haftadan başlar — hafta
/// ortasında seri kırık görünmesin. Boş bir hafta seriyi bitirir.
int weeklyStreak(List<PracticeExam> exams, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final weeks = <DateTime>{};
  for (final exam in exams) {
    if (exam.deleted) continue;
    weeks.add(_weekStart(exam.takenAt));
  }
  if (weeks.isEmpty) return 0;

  var cursor = _weekStart(reference);
  if (!weeks.contains(cursor)) {
    // Bu hafta henüz girilmemiş olabilir; seriyi geçen haftadan say.
    cursor = cursor.subtract(const Duration(days: 7));
  }

  var streak = 0;
  while (weeks.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 7));
  }
  return streak;
}

/// Haftanın pazartesi 00:00'ı (yerel saat).
DateTime _weekStart(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

/// Defterde en sık görülen puan türü — grafik ve özet kartının varsayılanı.
/// Eşitlikte en son denemenin türü kazanır.
String? dominantScoreType(List<PracticeExam> exams) {
  final counts = <String, int>{};
  String? latest;
  DateTime? latestAt;
  for (final exam in exams) {
    if (exam.deleted) continue;
    for (final r in exam.results) {
      if (r.scoreType.isEmpty) continue;
      counts[r.scoreType] = (counts[r.scoreType] ?? 0) + 1;
    }
    final best = exam.best?.scoreType;
    if (best != null && (latestAt == null || exam.takenAt.isAfter(latestAt))) {
      latest = best;
      latestAt = exam.takenAt;
    }
  }
  if (counts.isEmpty) return null;

  var topCount = 0;
  final leaders = <String>[];
  counts.forEach((type, count) {
    if (count > topCount) {
      topCount = count;
      leaders
        ..clear()
        ..add(type);
    } else if (count == topCount) {
      leaders.add(type);
    }
  });
  if (leaders.length == 1) return leaders.first;
  if (latest != null && leaders.contains(latest)) return latest;
  return leaders.first;
}

/// Defterdeki tüm puan türleri (grafik tür çipleri için), sık kullanılan başta.
List<String> scoreTypesIn(List<PracticeExam> exams) {
  final counts = <String, int>{};
  for (final exam in exams) {
    if (exam.deleted) continue;
    for (final r in exam.results) {
      if (r.scoreType.isEmpty) continue;
      counts[r.scoreType] = (counts[r.scoreType] ?? 0) + 1;
    }
  }
  final types = counts.keys.toList();
  types.sort((a, b) => counts[b]!.compareTo(counts[a]!));
  return types;
}
