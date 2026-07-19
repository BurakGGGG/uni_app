import '../../score_calculator/domain/models/match_result.dart';
import '../../university/domain/models/department_model.dart';
import 'match_constants.dart';
import 'models/student_score_profile.dart';

/// Bir eşleşmenin "neden bu kategoride" gerekçeleri — deterministik, saf,
/// offline. İlk öğe ana cümledir; kalanlar kısa destek etiketleri.
/// LLM yok: maliyetsiz, anında, test edilebilir.

enum MatchReasonKind {
  /// Ana cümle: sıra/puan marjı.
  primary,

  /// Taban sırası son yılda belirgin sıkılaştı — temkin.
  trendTighten,

  /// Taban sırası son yılda gevşedi — fırsat.
  trendRelax,

  /// Geçen yıl kontenjan boş kaldı.
  emptySeats,

  /// Referans sıra eski bir yıldan.
  staleYear,

  /// Sıra puandan tahmin edildi — gerçek sıra dürtmesi.
  estimatedNudge,
}

class MatchReason {
  final MatchReasonKind kind;
  final String text;
  const MatchReason(this.kind, this.text);
}

/// Binlik ayraçlı Türkçe sayı: 462104 → "462.104".
String formatRankTr(int value) {
  final digits = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return buf.toString();
}

List<MatchReason> buildMatchReasons(
  UniversityMatch match,
  StudentScoreProfile profile,
) {
  final reasons = <MatchReason>[];
  final refRank = match.departmentRanking;
  final basis = match.matchBasis;

  // ── Ana cümle ──
  if ((basis == MatchBasis.rank || basis == MatchBasis.estimatedRank) &&
      refRank != null &&
      refRank > 0) {
    final studentRank = basis == MatchBasis.rank
        ? profile.rank
        : null; // tahmini sıra match'te taşınmaz; oran fit'te zaten katlı
    final year = match.refRankYear;
    final yearLabel = year != null ? '$year\'te' : 'Son yılda';
    final rankLabel = '~${formatRankTr(refRank)}. sırada kapandı';

    if (studentRank != null) {
      final ratio = studentRank / refRank;
      final pct = ((1 - ratio).abs() * 100).round();
      final String margin;
      if (pct <= 2) {
        margin = 'taban sıraya çok yakınsın';
      } else if (ratio < 1) {
        margin = 'sıran %$pct önde';
      } else {
        margin = 'sıran %$pct geride';
      }
      reasons.add(
        MatchReason(MatchReasonKind.primary, '$yearLabel $rankLabel — $margin'),
      );
    } else {
      reasons.add(
        MatchReason(
          MatchReasonKind.primary,
          '$yearLabel $rankLabel — puanından tahmini sırayla eşleştirildi',
        ),
      );
    }
  } else {
    final diff = match.scoreDifference;
    final String margin;
    if (diff.abs() < 0.5) {
      margin = 'puanın tabana çok yakın';
    } else if (diff > 0) {
      margin = 'puanın ${diff.toStringAsFixed(1)} puan üstünde';
    } else {
      margin = 'puanın ${diff.abs().toStringAsFixed(1)} puan altında';
    }
    reasons.add(
      MatchReason(
        MatchReasonKind.primary,
        'Taban ${match.departmentBaseScore.toStringAsFixed(1)} — $margin',
      ),
    );
  }

  // ── Destek etiketleri (motorla aynı sinyaller, aynı eşikler) ──
  final sd = match.department.scoreData;
  final prevRank = match.department.previousRankingForMatching;
  if (refRank != null && refRank > 0 && prevRank != null && prevRank > 0) {
    final trend = refRank / prevRank;
    if (trend < kTrendTightenRatio) {
      reasons.add(const MatchReason(
        MatchReasonKind.trendTighten,
        'Taban sırası hızla sıkılaşıyor',
      ));
    } else if (trend > kTrendRelaxRatio) {
      reasons.add(const MatchReason(
        MatchReasonKind.trendRelax,
        'Taban sırası geçen yıl gevşedi',
      ));
    }
  }

  if (sd != null && sd.quota > 0 && sd.placedCount < sd.quota) {
    final empty = sd.quota - sd.placedCount;
    reasons.add(MatchReason(
      MatchReasonKind.emptySeats,
      'Geçen yıl $empty kontenjan boş kaldı',
    ));
  }

  final year = match.refRankYear;
  if (year != null && sd != null && year < sd.year) {
    reasons.add(MatchReason(
      MatchReasonKind.staleYear,
      'Sıra verisi $year yılından',
    ));
  }

  if (basis == MatchBasis.estimatedRank) {
    reasons.add(const MatchReason(
      MatchReasonKind.estimatedNudge,
      'Gerçek sıranı girersen isabet artar',
    ));
  }

  return reasons;
}
