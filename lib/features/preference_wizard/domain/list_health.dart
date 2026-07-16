import '../../preference_lists/domain/models/preference_list_model.dart';
import '../../score_calculator/domain/models/match_result.dart';
import 'models/student_score_profile.dart';
import 'preference_match_engine.dart';

/// Tercih listesi sağlık analizi — motorla aynı kategorileme mantığını
/// denormalize [PreferenceItem] alanları üzerinde çalıştırır (0 Firestore
/// okuması). UI'dan bağımsız, saf fonksiyon: test edilebilir.

enum ListHealthSeverity { ok, info, warning }

class ListHealthNote {
  final ListHealthSeverity severity;
  final String text;
  const ListHealthNote(this.severity, this.text);
}

class ListHealthReport {
  final int guaranteed;
  final int target;
  final int dream;

  /// Puan türü uyuşmayan ya da taban/sıralama verisi olmayan item sayısı.
  final int unrated;
  final List<ListHealthNote> notes;

  /// Sıradaki ilk yüksek şanslı (yoksa ilk ulaşılabilir) tercih — kaba
  /// "en olası yerleşme" tahmini. Hiçbiri yoksa null.
  final PreferenceItem? likelyPlacement;
  final MatchCategory? likelyCategory;

  const ListHealthReport({
    required this.guaranteed,
    required this.target,
    required this.dream,
    required this.unrated,
    required this.notes,
    this.likelyPlacement,
    this.likelyCategory,
  });

  int get rated => guaranteed + target + dream;
}

/// Tek bir liste öğesini profile göre kategorize eder; kıyaslanamıyorsa null.
/// Öncelik motorla aynı: sıralama → taban puan.
MatchCategory? categorizeListItem(
  PreferenceItem item,
  StudentScoreProfile profile,
) {
  final st = item.scoreType?.toUpperCase();
  if (st == null || st != profile.scoreType.toUpperCase()) return null;

  final itemRank = item.ranking;
  if (profile.hasRank && itemRank != null && itemRank > 0) {
    return categorizeByRank(profile.rank!, itemRank);
  }
  final base = item.baseScore;
  if (profile.hasScore && base != null && base > 0) {
    return categorizeByScore(profile.placementScore, base);
  }
  return null;
}

ListHealthReport analyzeListHealth(
  List<PreferenceItem> items,
  StudentScoreProfile profile,
) {
  final sorted = [...items]..sort((a, b) => a.order.compareTo(b.order));

  var guaranteed = 0;
  var target = 0;
  var dream = 0;
  var unrated = 0;
  PreferenceItem? firstGuaranteed;
  PreferenceItem? firstTarget;

  for (final item in sorted) {
    switch (categorizeListItem(item, profile)) {
      case MatchCategory.guaranteed:
        guaranteed++;
        firstGuaranteed ??= item;
        break;
      case MatchCategory.target:
        target++;
        firstTarget ??= item;
        break;
      case MatchCategory.dream:
        dream++;
        break;
      case null:
        unrated++;
        break;
    }
  }

  final rated = guaranteed + target + dream;
  final notes = <ListHealthNote>[];

  if (rated == 0) {
    notes.add(const ListHealthNote(
      ListHealthSeverity.info,
      'Listedeki programlar puan türünle karşılaştırılamadı.',
    ));
  } else {
    if (sorted.length >= 5 && guaranteed == 0) {
      notes.add(const ListHealthNote(
        ListHealthSeverity.warning,
        'Listende yüksek şanslı tercih yok — sıralaman beklenenden düşük '
        'gelirse açıkta kalabilirsin. Sona 3-4 güvenli program eklemeni '
        'öneririz.',
      ));
    }
    if (dream * 2 > rated) {
      notes.add(const ListHealthNote(
        ListHealthSeverity.warning,
        'Listenin yarısından fazlası zorlayıcı — dengeyi gözden geçir.',
      ));
    }
    if (guaranteed == rated && rated >= 3) {
      notes.add(const ListHealthNote(
        ListHealthSeverity.info,
        'Listen çok güvenli görünüyor — üst sıralara birkaç hedef program '
        'ekleyerek şansını artırabilirsin.',
      ));
    }
    if (notes.isEmpty) {
      notes.add(const ListHealthNote(
        ListHealthSeverity.ok,
        'Dağılım dengeli görünüyor.',
      ));
    }
  }

  final likely = firstGuaranteed ?? firstTarget;
  return ListHealthReport(
    guaranteed: guaranteed,
    target: target,
    dream: dream,
    unrated: unrated,
    notes: notes,
    likelyPlacement: likely,
    likelyCategory: likely == null
        ? null
        : (firstGuaranteed != null
            ? MatchCategory.guaranteed
            : MatchCategory.target),
  );
}
