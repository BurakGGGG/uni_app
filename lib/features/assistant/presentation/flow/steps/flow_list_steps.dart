import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../router/app_router.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../preference_lists/domain/preference_item_builder.dart';
import '../../../../preference_lists/presentation/providers/preference_list_providers.dart';
import '../../../../preference_wizard/domain/preference_match_engine.dart';
import '../../../../preference_wizard/presentation/providers/preference_wizard_providers.dart';
import '../../../../score_calculator/domain/models/match_result.dart';
import '../../../domain/robot_mood.dart';
import '../../../domain/robot_scripts.dart';
import '../uni_flow_step_spec.dart';

/// ÖSYM'nin verdiği tercih hakkı.
const int kListCapacity = 24;

/// Taslağın kategori kotaları.
///
/// Sağlıklı bir tercih listesi tek renk olmaz: üstte zorlayıcı, ortada
/// ulaşılabilir, altta güvenli programlar bulunur. Kotalar bu piramidi
/// kurar; bir kategori yetmezse boşluk diğerlerine dağıtılır.
const int _kDreamSlots = 6;
const int _kTargetSlots = 10;
const int _kGuaranteedSlots = 8;

const List<MatchCategory> _kBands = [
  MatchCategory.dream,
  MatchCategory.target,
  MatchCategory.guaranteed,
];

/// Üni'nin hazırladığı taslak liste — hayal → hedef → garanti sırasıyla.
final uniFlowDraftProvider = Provider.autoDispose<List<UniversityMatch>>((ref) {
  final result = ref.watch(preferenceMatchResultProvider).valueOrNull;
  if (result == null) return const [];
  return buildDraftList(result);
});

/// Taslaktan ÇIKARILANLAR (bölüm id'leri).
///
/// Varsayılan boş: her program seçili gelir. Öğrenci beğenmediğini eler —
/// eskiden tek tek "ekle/geç" diye onaylıyordu ve 24 kararı tek tek vermek
/// akışı öldürüyordu.
final _droppedProvider = StateProvider.autoDispose<Set<String>>((ref) => {});

/// Kotalara göre örülmüş taslak; kota dolmazsa boşluk diğer bantlara geçer.
@visibleForTesting
List<UniversityMatch> buildDraftList(
  PreferenceMatchResult result, {
  int capacity = kListCapacity,
}) {
  const quotas = {
    MatchCategory.dream: _kDreamSlots,
    MatchCategory.target: _kTargetSlots,
    MatchCategory.guaranteed: _kGuaranteedSlots,
  };

  final taken = <MatchCategory, List<UniversityMatch>>{
    for (final band in _kBands)
      band: result.forCategory(band).take(quotas[band]!).toList(),
  };

  var free = capacity - taken.values.fold(0, (sum, l) => sum + l.length);
  while (free > 0) {
    var grew = false;
    for (final band in _kBands) {
      if (free == 0) break;
      final pool = result.forCategory(band);
      if (pool.length <= taken[band]!.length) continue;
      taken[band]!.add(pool[taken[band]!.length]);
      free--;
      grew = true;
    }
    if (!grew) break;
  }

  return [for (final band in _kBands) ...taken[band]!];
}

/// ⑨ Taslak listen — Üni listeyi kurar, öğrenci eler.
UniFlowStepSpec buildListStepSpec(BuildContext context, WidgetRef ref) {
  final en = RobotScripts.isEn;
  final draft = ref.watch(uniFlowDraftProvider);
  final dropped = ref.watch(_droppedProvider);
  final picks =
      draft.where((m) => !dropped.contains(m.department.id)).toList();
  final signedIn = ref.watch(authStateProvider).valueOrNull != null;

  return UniFlowStepSpec(
    title: en ? 'Your draft list' : 'Taslak listen hazır',
    subtitle: draft.isEmpty
        ? null
        : (en
            ? 'I picked ${draft.length} programs across all three bands. '
                'Drop the ones you do not want.'
            : 'Üç bandı da kapsayan ${draft.length} program seçtim. '
                'İstemediğini çıkar, gerisini bir kerede ekleyeyim.'),
    mood: RobotMood.celebrating,
    ctaLabel: picks.isEmpty || !signedIn
        ? (en ? 'Skip for now' : 'Şimdilik geç')
        : (en
            ? 'Add ${picks.length} programs'
            : '${picks.length} tercihi ekle'),
    // Ekleme başarısızsa kabuk ilerlemez ve hatayı gösterir.
    onAdvance: picks.isEmpty || !signedIn ? null : () => _addAll(ref, picks),
    body: const [_BuildListBody()],
  );
}

/// Seçilenleri tek yazımda listeye basar.
///
/// "Hangi listeye?" diye SORMAZ: en dolu liste hedeftir, hiç liste yoksa bir
/// tane kurulur. Akışın ortasında liste seçtirmek yolu kesiyordu.
Future<void> _addAll(WidgetRef ref, List<UniversityMatch> picks) async {
  final en = RobotScripts.isEn;
  final repo = ref.read(preferenceListRepositoryProvider);
  final lists = ref.read(myPreferenceListsProvider).valueOrNull ?? const [];
  final target = lists.isEmpty
      ? await ref
          .read(preferenceListControllerProvider.notifier)
          .create(title: en ? 'My list' : 'Tercih Listem')
      : lists.reduce((a, b) => b.items.length > a.items.length ? b : a);
  if (target == null) {
    throw Exception(en ? 'List could not be created' : 'Liste oluşturulamadı');
  }
  await repo.addItems(
    target.id,
    [for (final m in picks) buildPreferenceItem(m.university, m.department)],
  );
}

/// ⑩ Kapanış.
UniFlowStepSpec doneStepSpec(BuildContext context, WidgetRef ref) {
  final en = RobotScripts.isEn;
  final profile = ref.watch(studentScoreProfileProvider);
  final prefs = ref.watch(wizardPrefsProvider);
  final listCount = _mainListCount(ref);

  return UniFlowStepSpec(
    title: en ? "You're all set" : 'Hazırsın',
    subtitle: en
        ? 'I will keep watching your list from here on.'
        : 'Bundan sonra listeni ben takip ederim.',
    mood: RobotMood.celebrating,
    ctaLabel: en ? 'Finish' : 'Bitir',
    body: [
      if (profile != null)
        _DoneRow(
          icon: Icons.calculate_rounded,
          label: en ? 'Your score' : 'Puanın',
          value: '${profile.scoreType} '
              '${profile.placementScore.toStringAsFixed(1)}',
        ),
      if (prefs.interestKeys.isNotEmpty)
        _DoneRow(
          icon: Icons.interests_rounded,
          label: en ? 'Interests' : 'İlgi alanların',
          value: '${prefs.interestKeys.length}',
        ),
      if (prefs.cityIds.isNotEmpty)
        _DoneRow(
          icon: Icons.location_city_rounded,
          label: en ? 'Cities' : 'Şehirlerin',
          value: '${prefs.cityIds.length}',
        ),
      _DoneRow(
        icon: Icons.list_alt_rounded,
        label: en ? 'Your list' : 'Tercih listen',
        value: '$listCount / $kListCapacity',
      ),
    ],
  );
}

int _mainListCount(WidgetRef ref) {
  final lists = ref.watch(myPreferenceListsProvider).valueOrNull ?? const [];
  if (lists.isEmpty) return 0;
  return lists.map((l) => l.items.length).reduce((a, b) => a > b ? a : b);
}

// ─── Taslak gövdesi ────────────────────────────────────────────

class _BuildListBody extends ConsumerWidget {
  const _BuildListBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final en = RobotScripts.isEn;

    if (ref.watch(authStateProvider).valueOrNull == null) {
      return _Note(
        text: en
            ? 'Sign in to build a preference list — your score is already saved.'
            : 'Tercih listesi kurmak için giriş yapman gerek; puanın zaten '
                'kayıtlı.',
      );
    }

    final resultAsync = ref.watch(preferenceMatchResultProvider);
    return resultAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => _Note(
        text: en
            ? 'I could not reach the program data right now.'
            : 'Program verisine şu an ulaşamadım.',
      ),
      data: (result) {
        final draft = ref.watch(uniFlowDraftProvider);
        if (result == null || draft.isEmpty) {
          return _Note(
            text: en
                ? 'No matching program yet.'
                : 'Şimdilik eşleşen program yok.',
          );
        }

        final dropped = ref.watch(_droppedProvider);
        final kept =
            draft.where((m) => !dropped.contains(m.department.id)).toList();
        final allDropped = kept.isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SlotMeter(draft: draft, dropped: dropped),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => ref.read(_droppedProvider.notifier).state =
                    allDropped
                        ? <String>{}
                        : draft.map((m) => m.department.id).toSet(),
                icon: Icon(
                  allDropped
                      ? Icons.done_all_rounded
                      : Icons.remove_done_rounded,
                  size: 18,
                ),
                label: Text(
                  allDropped
                      ? (en ? 'Select all' : 'Tümünü seç')
                      : (en ? 'Clear all' : 'Tümünü çıkar'),
                ),
              ),
            ),
            for (final band in _kBands)
              if (draft.any((m) => m.category == band)) ...[
                _BandHeader(
                  band: band,
                  count: draft.where((m) => m.category == band).length,
                ),
                for (final m in draft.where((m) => m.category == band))
                  _DraftRow(
                    match: m,
                    selected: !dropped.contains(m.department.id),
                    onToggle: () => _toggle(ref, m.department.id),
                  ),
              ],
          ],
        );
      },
    );
  }

  void _toggle(WidgetRef ref, String deptId) {
    final next = {...ref.read(_droppedProvider)};
    if (!next.remove(deptId)) next.add(deptId);
    ref.read(_droppedProvider.notifier).state = next;
  }
}

/// 24 tercih hakkı, 24 kutucuk. Dolu kutular kategorinin renginde; çıkarılan
/// program boş kutuya döner — "listemin kaçı doldu" tek bakışta görünsün.
class _SlotMeter extends StatelessWidget {
  final List<UniversityMatch> draft;
  final Set<String> dropped;

  const _SlotMeter({required this.draft, required this.dropped});

  @override
  Widget build(BuildContext context) {
    final en = RobotScripts.isEn;
    final kept = draft.where((m) => !dropped.contains(m.department.id));
    final counts = <MatchCategory, int>{
      for (final band in _kBands)
        band: kept.where((m) => m.category == band).length,
    };
    final total = counts.values.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantFor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  en ? 'Your list' : 'Tercih listen',
                  style: AppTextStyles.titleSmall
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '$total / $kListCapacity',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (var i = 0; i < kListCapacity; i++)
                _Slot(color: i < total ? _slotColor(counts, i) : null),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            en
                ? '${counts[MatchCategory.dream]} reach · '
                    '${counts[MatchCategory.target]} match · '
                    '${counts[MatchCategory.guaranteed]} safe'
                : '${counts[MatchCategory.dream]} zorlayıcı · '
                    '${counts[MatchCategory.target]} ulaşılabilir · '
                    '${counts[MatchCategory.guaranteed]} yüksek şans',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
          ),
        ],
      ),
    );
  }

  /// i. kutunun rengi: kutular bant sırasına göre boyanır.
  Color _slotColor(Map<MatchCategory, int> counts, int i) {
    var seen = 0;
    for (final band in _kBands) {
      seen += counts[band]!;
      if (i < seen) return _bandColor(band);
    }
    return AppColors.primary;
  }
}

class _Slot extends StatelessWidget {
  final Color? color;
  const _Slot({required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color ?? AppColors.borderLightFor(context),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _BandHeader extends StatelessWidget {
  final MatchCategory band;
  final int count;

  const _BandHeader({required this.band, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _bandColor(band),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _bandLabel(band).toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: _bandColor(band),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '· $count',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textTertiaryFor(context)),
          ),
        ],
      ),
    );
  }
}

/// Taslaktaki tek satır — dokununca listeden çıkar/geri gelir.
class _DraftRow extends StatelessWidget {
  final UniversityMatch match;
  final bool selected;
  final VoidCallback onToggle;

  const _DraftRow({
    required this.match,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final color = _bandColor(match.category);
    final rank = match.departmentRanking;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.surfaceFor(context)
            : AppColors.surfaceVariantFor(context),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            // Çıkarılan satır kaybolmaz, SÖNER: fikrini değiştirirsen yerini
            // aramak zorunda kalma.
            opacity: selected ? 1 : 0.45,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? color.withValues(alpha: 0.35)
                      : AppColors.borderLightFor(context),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.university.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rank == null
                              ? match.department.name
                              : '${match.department.name} · '
                                  '${_compactRank(rank)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondaryFor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    size: 24,
                    color: selected
                        ? color
                        : AppColors.textTertiaryFor(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Ortak ─────────────────────────────────────────────────────

Color _bandColor(MatchCategory band) => switch (band) {
      MatchCategory.guaranteed => AppColors.success,
      MatchCategory.target => AppColors.warning,
      MatchCategory.dream => AppColors.error,
    };

String _bandLabel(MatchCategory band) {
  final en = RobotScripts.isEn;
  return switch (band) {
    MatchCategory.guaranteed => en ? 'Safe' : 'Yüksek şans',
    MatchCategory.target => en ? 'Match' : 'Ulaşılabilir',
    MatchCategory.dream => en ? 'Reach' : 'Zorlayıcı',
  };
}

/// Satıra sığan sıra: 85600 → "85B", 1240000 → "1,2M".
String _compactRank(int rank) {
  if (rank >= 1000000) {
    return '${(rank / 1000000).toStringAsFixed(1).replaceAll('.', ',')}M sıra';
  }
  if (rank >= 1000) return '${(rank / 1000).round()}B sıra';
  return '$rank. sıra';
}

class _Note extends StatelessWidget {
  final String text;
  const _Note({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantFor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondaryFor(context),
          height: 1.4,
        ),
      ),
    );
  }
}

class _DoneRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DoneRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.titleSmall
                .copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// Akış bitince gidilecek yer — özet ekranı.
void finishUniFlow(BuildContext context) {
  if (Navigator.canPop(context)) {
    Navigator.pop(context);
    return;
  }
  context.go(AppRoutes.uniPanel);
}
