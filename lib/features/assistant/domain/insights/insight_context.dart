import '../../../practice_exams/domain/models/exam_target.dart';
import '../../../practice_exams/domain/models/practice_exam.dart';
import '../../../preference_wizard/domain/models/student_score_profile.dart';
import '../tercih_calendar.dart';

/// Bir tercih listesinin motora yetecek kadarı.
///
/// `PreferenceListModel` Firestore'a bağlı (`cloud_firestore` import eder);
/// içgörü motoru saf kalsın diye provider katmanı listeyi burada sayıya
/// indirger. Kategori sayıları `analyzeListHealth()` ile üretilir — eşikler
/// orada tanımlıdır, burada kopyalanmaz.
class ListSnapshot {
  final String listId;
  final String title;
  final int itemCount;

  final int guaranteed;
  final int target;
  final int dream;

  /// Puan türü uyuşmayan ya da taban verisi olmayan öğrenler.
  final int unrated;

  /// Sıradaki ilk yüksek şanslı (yoksa ilk ulaşılabilir) tercihin adı.
  final String? likelyPlacementName;

  /// İlk 5 tercihte en çok geçen şehir ve kaç kez geçtiği — yığılma uyarısı.
  final String? topCityName;
  final int topCityCount;

  const ListSnapshot({
    required this.listId,
    required this.title,
    required this.itemCount,
    this.guaranteed = 0,
    this.target = 0,
    this.dream = 0,
    this.unrated = 0,
    this.likelyPlacementName,
    this.topCityName,
    this.topCityCount = 0,
  });

  int get rated => guaranteed + target + dream;
}

/// Kullanıcının izlediği (favori ya da listesindeki) bir program ve ÖSYM
/// verisinin dikkat çeken tarafı.
class TrackedProgram {
  final String departmentId;
  final String departmentName;
  final String universityName;

  /// Geçen yıla göre taban puan farkı — negatif = taban düşmüş.
  final double? baseScoreDelta;

  /// Yerleşen / kontenjan.
  final double? fillRate;

  const TrackedProgram({
    required this.departmentId,
    required this.departmentName,
    required this.universityName,
    this.baseScoreDelta,
    this.fillRate,
  });
}

/// [InsightEngine]'in tek girdisi — saf veri, hiçbir Flutter/Firestore bağı yok.
///
/// Ağır işleri motor kendi yapar (`trendFor`, `subjectStats`, `weeklyStreak`
/// zaten saf fonksiyonlar); burada yalnız ham kaynaklar durur ki test tek bir
/// nesne kurarak tüm aileleri sınayabilsin.
class InsightContext {
  final DateTime now;
  final TercihPhase phase;

  final StudentScoreProfile? profile;
  final List<PracticeExam> exams;
  final ExamTarget? target;
  final List<ListSnapshot> lists;
  final List<TrackedProgram> tracked;

  /// Puandan kestirilen sıra — profilde GERÇEK sıra varsa null (o zaman
  /// tahmine gerek yok, `profile.rank` okunur). Liste sağlığı bunu zaten
  /// hesaplıyordu; panelin "Puanın" adımı da aynı sayıyı göstersin diye
  /// bağlamda taşınıyor.
  final int? estimatedRank;

  InsightContext({
    required this.now,
    this.profile,
    this.exams = const [],
    this.target,
    this.lists = const [],
    this.tracked = const [],
    this.estimatedRank,
    TercihPhase? phase,
  }) : phase = phase ?? tercihPhaseFor(now);

  bool get hasProfile =>
      profile != null && profile!.scoreType.trim().isNotEmpty;

  /// Gösterilecek sıra: öğrencinin girdiği gerçek sıra, yoksa puandan
  /// kestirilen. İkisi de yoksa null.
  int? get displayRank =>
      (profile?.hasRank ?? false) ? profile!.rank : estimatedRank;

  /// [displayRank] tahminden mi geliyor? Gösterimdeki "≈" işareti buna bağlı —
  /// tahmini sırayı kesin sıra gibi yazmak öğrenciye yalan söylemek olur.
  bool get rankIsEstimated =>
      !(profile?.hasRank ?? false) && estimatedRank != null;

  /// Analizlerin dayandığı puan türü: hedefin türü → profil → defterde en sık.
  /// Hiçbiri yoksa boş string (motor tür gerektiren aileleri atlar).
  String get scoreType {
    final fromTarget = target?.scoreType.trim() ?? '';
    if (fromTarget.isNotEmpty) return fromTarget.toUpperCase();
    final fromProfile = profile?.scoreType.trim() ?? '';
    if (fromProfile.isNotEmpty) return fromProfile.toUpperCase();
    return '';
  }

  /// Silinmemiş denemeler, yeniden eskiye.
  List<PracticeExam> get liveExams {
    final live = [
      for (final e in exams)
        if (!e.deleted) e,
    ]..sort((a, b) => b.takenAt.compareTo(a.takenAt));
    return live;
  }
}
