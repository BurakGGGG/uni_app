import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/snackbar_helper.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../preference_lists/domain/list_overview.dart';
import '../../../../preference_lists/domain/preference_item_builder.dart';
import '../../../../preference_lists/presentation/providers/preference_list_providers.dart';
import '../../../../preference_lists/presentation/widgets/create_list_sheet.dart';
import '../../../../score_calculator/domain/models/match_result.dart';
import '../../../domain/compare_view.dart';
import '../../providers/compare_personal_providers.dart';
import 'compare_theme.dart';

/// Karşılaştırmadan tercih listesine köprü (kullanıcı kararı).
///
/// Karşılaştırma şu ana kadar bir çıkmazdı: okuyup çıkıyordun. Burada
/// puana uyan programlar hazır seçili geliyor, istemediğini çıkarıp
/// gerisini TEK yazımda listeye gönderiyorsun (`addItems`).
class CompareAddToListSheet {
  static Future<void> show(
    BuildContext context, {
    required List<CompareSide> sides,
    required List<CompareEligibility> eligibilities,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => _Body(
          sides: sides,
          eligibilities: eligibilities,
          scrollController: controller,
        ),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  final List<CompareSide> sides;
  final List<CompareEligibility> eligibilities;
  final ScrollController scrollController;

  const _Body({
    required this.sides,
    required this.eligibilities,
    required this.scrollController,
  });

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  /// Çıkarılanlar. Hepsi seçili başlar — öğrenci eleme yapar, tek tek
  /// işaretlemez (tercih yolu akışındaki taslak listenin aynı sözleşmesi).
  final Set<String> _dropped = {};
  String? _listId;
  bool _busy = false;

  List<({int side, UniversityMatch match})> get _all => [
        for (var i = 0; i < widget.eligibilities.length; i++)
          for (final m in widget.eligibilities[i].matches)
            (side: i, match: m),
      ];

  List<({int side, UniversityMatch match})> get _selected =>
      _all.where((e) => !_dropped.contains(e.match.department.id)).toList();

  Future<void> _add(ListOverview target) async {
    final loc = AppLocalizations.of(context);
    final picks = _selected;
    if (picks.isEmpty) return;

    setState(() => _busy = true);
    try {
      final added = await ref.read(preferenceListRepositoryProvider).addItems(
            target.list.id,
            [
              for (final p in picks)
                buildPreferenceItem(p.match.university, p.match.department),
            ],
          );
      if (!mounted) return;
      Navigator.pop(context);
      showAppSnackBar(
        context,
        message: loc.cmpAddedToList('$added', target.list.title),
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppSnackBar(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final overviews = ref.watch(listOverviewsProvider);

    // Hedef liste: kullanıcı seçtiyse o, yoksa ana liste (sabitlenen ya da
    // en dolu) — hub'la aynı kural, iki yüzey farklı listeden konuşmasın.
    final target = overviews.isEmpty
        ? null
        : overviews.firstWhere(
            (o) => o.list.id == _listId,
            orElse: () => overviews.first,
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            loc.cmpAddSheetTitle,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc.cmpAddSheetDesc,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryFor(context),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          if (target == null)
            _NoList(onCreate: () => CreateListSheet.show(context, ref))
          else
            _TargetRow(
              overview: target,
              options: overviews,
              onPick: (id) => setState(() => _listId = id),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                for (var i = 0; i < widget.sides.length; i++) ...[
                  if (widget.eligibilities[i].matches.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 8, 2, 6),
                      child: Text(
                        widget.sides[i].title.toUpperCase(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: compareSideColor(i),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    for (final m in widget.eligibilities[i].matches)
                      _Row(
                        match: m,
                        color: compareSideColor(i),
                        selected: !_dropped.contains(m.department.id),
                        onToggle: () => setState(() {
                          final id = m.department.id;
                          if (!_dropped.remove(id)) _dropped.add(id);
                        }),
                      ),
                  ],
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: target == null || _selected.isEmpty || _busy
                      ? null
                      : () => _add(target),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          loc.cmpAddSelectedCta('${_selected.length}'),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hedef liste satırı — birden çok liste varsa dokununca değişir.
class _TargetRow extends StatelessWidget {
  final ListOverview overview;
  final List<ListOverview> options;
  final ValueChanged<String> onPick;

  const _TargetRow({
    required this.overview,
    required this.options,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final single = options.length < 2;
    return Material(
      color: AppColors.surfaceVariantFor(context).withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: single ? null : () => _pick(context),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.format_list_numbered_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  overview.list.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${overview.filled}/${ListOverview.capacity}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondaryFor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!single) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: AppColors.textTertiaryFor(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _pick(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            for (final option in options)
              ListTile(
                title: Text(option.list.title),
                trailing: Text('${option.filled}/${ListOverview.capacity}'),
                selected: option.list.id == overview.list.id,
                onTap: () {
                  Navigator.pop(sheet);
                  onPick(option.list.id);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final UniversityMatch match;
  final Color color;
  final bool selected;
  final VoidCallback onToggle;

  const _Row({
    required this.match,
    required this.color,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? color : AppColors.textTertiaryFor(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.department.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? null
                          : AppColors.textTertiaryFor(context),
                    ),
                  ),
                  if (match.departmentRanking != null &&
                      match.departmentRanking! > 0)
                    Text(
                      '${match.departmentRanking}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiaryFor(context),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoList extends StatelessWidget {
  final VoidCallback onCreate;
  const _NoList({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantFor(context).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              loc.cmpAddNoList,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
            ),
          ),
          TextButton(
            onPressed: onCreate,
            child: Text(loc.prefListsNewList),
          ),
        ],
      ),
    );
  }
}
