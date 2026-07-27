import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../assistant/domain/robot_scripts.dart';
import '../../../assistant/presentation/widgets/uni_empty_state.dart';
import '../../domain/city_browse.dart';
import '../providers/university_providers.dart';
import '../widgets/city_card.dart';

final _searchProvider = StateProvider.autoDispose<String>((ref) => '');
final _regionProvider = StateProvider.autoDispose<TurkeyRegion?>((ref) => null);
final _sortProvider =
    StateProvider.autoDispose<CitySort>((ref) => CitySort.universities);

/// Tüm şehirler.
///
/// 60 şehri tek ızgarada dökmek yerine iki daraltma yolu var: bölge ve
/// sıralama. İkisi de yeni veri istemiyor — bölge plaka kodundan, sıralama
/// elde olan sayılardan türüyor (bkz. `city_browse.dart`).
class AllCitiesScreen extends ConsumerWidget {
  const AllCitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final citiesAsync = ref.watch(citiesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: citiesAsync.when(
        loading: () => const ListSkeleton(),
        error: (e, _) => ErrorState(
          message: loc.commonError,
          onRetry: () => ref.invalidate(citiesProvider),
        ),
        data: (cities) {
          final query = ref.watch(_searchProvider);
          final region = ref.watch(_regionProvider);
          final sort = ref.watch(_sortProvider);
          final result =
              browseCities(cities, query: query, region: region, sort: sort);
          final filtering = query.trim().isNotEmpty || region != null;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(citiesProvider);
              await ref.read(citiesProvider.future);
            },
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  stretch: true,
                  expandedHeight: 168,
                  // Kapanınca degrade solup arkasındaki renk kalıyor;
                  // arka plan rengi verilirse geri düğmesi beyaz üstünde
                  // beyaz oluyordu.
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  flexibleSpace: _Hero(
                    cityCount: cities.length,
                    universityCount: cities.fold(
                      0,
                      (sum, c) => sum + c.appUniversityCount,
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ControlsDelegate(
                    counts: result.regionCounts,
                    selected: region,
                    sort: sort,
                    onQuery: (v) =>
                        ref.read(_searchProvider.notifier).state = v,
                    onRegion: (v) =>
                        ref.read(_regionProvider.notifier).state = v,
                    onSort: (v) => ref.read(_sortProvider.notifier).state = v,
                  ),
                ),
                if (result.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: UniEmptyState(
                      icon: Icons.location_off_rounded,
                      title: loc.citiesEmptyTitle,
                      script: RobotScripts.emptySearch,
                      action: filtering
                          ? TextButton.icon(
                              onPressed: () {
                                ref.read(_regionProvider.notifier).state = null;
                                ref.read(_searchProvider.notifier).state = '';
                              },
                              icon: const Icon(Icons.filter_alt_off_rounded,
                                  size: 18),
                              label: Text(loc.citiesClearFilters),
                            )
                          : null,
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: _SummaryLine(
                      result: result,
                      sort: sort,
                      filtering: filtering,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    sliver: SliverGrid(
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: Responsive.gridColumns(context),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: CityCard.tileExtent(context),
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final city = result.cities[i];
                          return CityCard.tile(
                            city: city,
                            onTap: () => ctx.push('/city/${city.id}'),
                          )
                              .animate(key: ValueKey(city.id))
                              // Kademeli gecikme başta hoş, 60 kartta
                              // bekleme oluyor — ilk ekranla sınırlı.
                              .fadeIn(
                                duration: 250.ms,
                                delay: (i.clamp(0, 7) * 30).ms,
                              )
                              .slideY(begin: 0.1, duration: 250.ms);
                        },
                        childCount: result.cities.length,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Hero (üstteki banner) ────────────────────────────────────
class _Hero extends StatelessWidget {
  final int cityCount;
  final int universityCount;

  const _Hero({required this.cityCount, required this.universityCount});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final topPadding = MediaQuery.paddingOf(context).top;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Tamamen kapandığında geriye boş bir mor şerit kalıyordu; başlık
        // yalnız o anda araç çubuğuna geçiyor.
        final collapsed =
            constraints.maxHeight <= kToolbarHeight + topPadding + 8;
        return _heroBar(context, loc, collapsed);
      },
    );
  }

  Widget _heroBar(
    BuildContext context,
    AppLocalizations loc,
    bool collapsed,
  ) {
    return FlexibleSpaceBar(
      titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16),
      title: collapsed
          ? Text(
              loc.citiesTitle,
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loc.citiesTitle,
                    style: AppTextStyles.displaySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Sabit bir slogan yerine gerçek kapsam: kaç şehir, kaç
                  // üniversite gezilebiliyor.
                  Text(
                    loc.citiesHeroSubtitle(
                      AppFormatters.integer(cityCount),
                      AppFormatters.integer(universityCount),
                    ),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

// ─── Yapışkan denetimler: arama + sıralama + bölge rozetleri ──
class _ControlsDelegate extends SliverPersistentHeaderDelegate {
  final Map<TurkeyRegion, int> counts;
  final TurkeyRegion? selected;
  final CitySort sort;
  final ValueChanged<String> onQuery;
  final ValueChanged<TurkeyRegion?> onRegion;
  final ValueChanged<CitySort> onSort;

  const _ControlsDelegate({
    required this.counts,
    required this.selected,
    required this.sort,
    required this.onQuery,
    required this.onRegion,
    required this.onSort,
  });

  static const double _extent = 112;

  @override
  double get minExtent => _extent;
  @override
  double get maxExtent => _extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      color: AppColors.backgroundFor(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Expanded(child: _SearchField(onChanged: onQuery)),
                const SizedBox(width: 10),
                _SortButton(sort: sort, onSelected: onSort),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: _RegionStrip(
              counts: counts,
              selected: selected,
              onSelected: onRegion,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // Rozet sayıları aramayla değişiyor: eski çocuğu tutmak seçili bölgeyi
  // ekranda dondurur.
  @override
  bool shouldRebuild(_ControlsDelegate old) =>
      old.selected != selected ||
      old.sort != sort ||
      !_sameCounts(old.counts, counts);

  static bool _sameCounts(Map<TurkeyRegion, int> a, Map<TurkeyRegion, int> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

class _SearchField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _hasText = false;

  void _onSearchChanged(String query) {
    setState(() => _hasText = query.isNotEmpty);
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 200),
      () => widget.onChanged(query),
    );
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() => _hasText = false);
    widget.onChanged('');
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded,
              size: 20, color: AppColors.textTertiaryFor(context)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: loc.citiesSearchHint,
                // Yalnız `border` yetmiyor: tema odaklanınca kendi
                // çerçevesini çiziyor ve kapsayıcının içinde ikinci bir
                // kutu beliriyordu.
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          // Aramayı geri almanın tek yolu klavyeyle silmekti.
          if (_hasText)
            IconButton(
              onPressed: _clear,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.textSecondaryFor(context),
              tooltip: loc.citiesSearchClear,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final CitySort sort;
  final ValueChanged<CitySort> onSelected;

  const _SortButton({required this.sort, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: PopupMenuButton<CitySort>(
        tooltip: loc.citiesSortTitle,
        initialValue: sort,
        position: PopupMenuPosition.under,
        onSelected: onSelected,
        icon: Icon(Icons.sort_rounded,
            size: 20, color: AppColors.textSecondaryFor(context)),
        itemBuilder: (_) => [
          for (final option in CitySort.values)
            PopupMenuItem(
              value: option,
              child: Row(
                children: [
                  Icon(
                    option == sort
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: option == sort
                        ? AppColors.primary
                        : AppColors.textTertiaryFor(context),
                  ),
                  const SizedBox(width: 10),
                  // Menü genişliği sabit; uzun çeviri ya da büyük yazı
                  // ölçeği satırı taşırıyor.
                  Flexible(
                    child: Text(
                      sortName(option, loc),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RegionStrip extends StatelessWidget {
  final Map<TurkeyRegion, int> counts;
  final TurkeyRegion? selected;
  final ValueChanged<TurkeyRegion?> onSelected;

  const _RegionStrip({
    required this.counts,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    // Aramada hiç şehri kalmayan bölge rozeti boş sonuç vaat eder.
    final regions =
        TurkeyRegion.values.where((r) => (counts[r] ?? 0) > 0).toList();

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _RegionChip(
          label: loc.citiesFilterAll,
          selected: selected == null,
          onTap: () => onSelected(null),
        ),
        for (final region in regions) ...[
          const SizedBox(width: 8),
          _RegionChip(
            label: regionName(region, loc),
            count: counts[region],
            selected: selected == region,
            onTap: () => onSelected(selected == region ? null : region),
          ),
        ],
      ],
    );
  }
}

class _RegionChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _RegionChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.textSecondaryFor(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : AppColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.borderLightFor(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.75)
                        : AppColors.textTertiaryFor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Süzgecin ne bıraktığını ve hangi sıralamanın açık olduğunu söyler.
///
/// Sayılar yalnız süzülmüşken yazılıyor: süzgeç yokken başlıktaki satırla
/// birebir aynı cümle olur ve alt alta iki kez okunurdu.
class _SummaryLine extends StatelessWidget {
  final CityBrowseResult result;
  final CitySort sort;
  final bool filtering;

  const _SummaryLine({
    required this.result,
    required this.sort,
    required this.filtering,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: filtering
                ? Text(
                    loc.citiesHeroSubtitle(
                      AppFormatters.integer(result.cities.length),
                      AppFormatters.integer(result.universityCount),
                    ),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondaryFor(context),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          Icon(Icons.sort_rounded,
              size: 14, color: AppColors.textTertiaryFor(context)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              sortName(sort, loc),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiaryFor(context),
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
