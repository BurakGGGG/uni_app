import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/presentation/widgets/subscription_gate_widget.dart';
import '../../../university/data/university_repository.dart';
import '../../../university/domain/models/city_model.dart';
import '../../../university/presentation/widgets/city_logo.dart';
import '../../domain/compare_view_builders.dart';
import '../../domain/models/city_comparison.dart';
import '../providers/comparison_providers.dart';
import '../widgets/city_compar_pie_chart.dart';
import '../widgets/city_picker_bottom_sheet.dart';
import '../widgets/compare/compare_layout.dart';
import '../widgets/comparison_notes_section.dart';
import '../widgets/comparison_picker_slot.dart';
import '../widgets/offline_banner.dart';

/// Şehir karşılaştırma.
///
/// Üniversite ve bölüm ekranlarıyla AYNI iskeleti kullanıyor
/// (`CompareLayout`) — üçü kardeş görünsün diye (kullanıcı kararı).
class CityComparisonScreen extends ConsumerStatefulWidget {
  /// Deep-link / geçmişten gelen önceden seçili şehir ID'leri.
  final String? initialAId;
  final String? initialBId;

  const CityComparisonScreen({
    super.key,
    this.initialAId,
    this.initialBId,
  });

  @override
  ConsumerState<CityComparisonScreen> createState() =>
      _CityComparisonScreenState();
}

class _CityComparisonScreenState extends ConsumerState<CityComparisonScreen> {
  CityModel? _a;
  CityModel? _b;

  @override
  void initState() {
    super.initState();
    if (widget.initialAId != null || widget.initialBId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolveInitial());
    }
  }

  Future<void> _resolveInitial() async {
    final repo = UniversityRepository();
    Future<CityModel?> lookup(String? id) async {
      if (id == null || id.isEmpty) return null;
      return repo.getCity(id);
    }

    final results = await Future.wait([
      lookup(widget.initialAId),
      lookup(widget.initialBId),
    ]);
    if (!mounted) return;
    setState(() {
      if (results[0] != null) _a = results[0];
      if (results[1] != null) _b = results[1];
    });
  }

  Future<void> _pick(int index) async {
    final city = await CityPickerBottomSheet.show(context);
    if (city == null || !mounted) return;
    setState(() {
      if (index == 0) {
        _a = city;
      } else {
        _b = city;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final a = _a;
    final b = _b;
    final pair = (a != null && b != null)
        ? ComparisonPair(idA: a.id, idB: b.id)
        : null;
    final resultAsync = pair == null
        ? const AsyncValue<CityComparisonResult?>.data(null)
        : ref.watch(cityComparisonResultProvider(pair));

    return SubscriptionGateWidget(
      requiredTier: SubscriptionTier.plus,
      showBlurPreview: true,
      onLocked: () => context.push('/compare/paywall'),
      child: Scaffold(
        backgroundColor: AppColors.backgroundFor(context),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            loc.comparisonCity,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            if (a != null || b != null)
              IconButton(
                tooltip: loc.reset,
                onPressed: () => setState(() {
                  _a = null;
                  _b = null;
                }),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                color: AppColors.error,
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (!ref.watch(isOnlineProvider)) const OfflineBanner(),
              Expanded(child: _body(context, resultAsync)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AsyncValue<CityComparisonResult?> resultAsync,
  ) {
    final loc = AppLocalizations.of(context);
    final a = _a;
    final b = _b;

    if (a == null || b == null) {
      return _PickStage(
        a: a,
        b: b,
        onPick: _pick,
      );
    }

    return resultAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(loc.errorGeneral('$e'), textAlign: TextAlign.center),
        ),
      ),
      data: (result) {
        // Sunucu sonucu yoksa şehir modelinin kendi sayılarına düşülüyor —
        // ekran boş kalmasın, en azından üniversite sayısı karşılaştırılsın.
        final effective = result ?? _fallback(a, b);
        final view = cityCompareView(effective, loc);

        return CompareLayout(
          view: view,
          onChangeSide: _pick,
          leadingBuilder: (index, side) => CityLogo(
            city: index == 0 ? a : b,
            size: 44,
          ),
          onRefresh: () async {
            final pair = ComparisonPair(idA: a.id, idB: b.id);
            ref.invalidate(cityComparisonResultProvider(pair));
            await ref.read(cityComparisonResultProvider(pair).future);
          },
          extras: [
            _DistributionCard(result: effective),
            ComparisonNotesSection(
              comparisonType: 'city',
              entityAId: a.id,
              entityBId: b.id,
            ),
          ],
        );
      },
    );
  }

  CityComparisonResult _fallback(CityModel cityA, CityModel cityB) {
    final countA = cityA.appUniversityCount;
    final countB = cityB.appUniversityCount;
    String? winnerId;
    if (countA > countB) {
      winnerId = cityA.id;
    } else if (countB > countA) {
      winnerId = cityB.id;
    }

    return CityComparisonResult(
      cityA: cityA,
      cityB: cityB,
      universityCountA: countA,
      universityCountB: countB,
      stateUniversityCountA: 0,
      stateUniversityCountB: 0,
      foundationUniversityCountA: 0,
      foundationUniversityCountB: 0,
      avgRatingA: 0,
      avgRatingB: 0,
      avgReviewCountA: 0,
      avgReviewCountB: 0,
      populationA: cityA.population,
      populationB: cityB.population,
      winnerId: winnerId,
    );
  }
}

/// Seçim aşaması — iki şehir seçilene kadar.
class _PickStage extends StatelessWidget {
  final CityModel? a;
  final CityModel? b;
  final ValueChanged<int> onPick;

  const _PickStage({required this.a, required this.b, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ComparisonPickerHeader(
            icon: Icons.location_city_rounded,
            title: loc.comparisonCityHeaderTitle,
            subtitle: loc.comparisonCityHeaderSubtitle,
            accentColor: AppColors.primary,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _CityPickCard(
                  title: loc.selectCityA,
                  city: a,
                  accent: AppColors.primary,
                  onTap: () => onPick(0),
                ),
              ),
              const SizedBox(width: 10),
              const ComparisonVsBadge(),
              const SizedBox(width: 10),
              Expanded(
                child: _CityPickCard(
                  title: loc.selectCityB,
                  city: b,
                  accent: AppColors.secondary,
                  onTap: () => onPick(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borderLightFor(context)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_city_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    loc.comparisonCityHint,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryFor(context),
                      height: 1.35,
                    ),
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

class _CityPickCard extends StatelessWidget {
  final String title;
  final CityModel? city;
  final Color accent;
  final VoidCallback onTap;

  const _CityPickCard({
    required this.title,
    required this.city,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final c = city;
    if (c == null) {
      return ComparisonPickerSlot(
        isEmpty: true,
        emptyLabel: title,
        emptyIcon: Icons.location_city_rounded,
        accentColor: accent,
        onTap: onTap,
      );
    }
    return ComparisonPickerSlot(
      isEmpty: false,
      emptyLabel: title,
      emptyIcon: Icons.location_city_rounded,
      accentColor: accent,
      onTap: onTap,
      logo: CityLogo(city: c, size: 44),
      title: c.name,
      subtitle: loc.cmpCityPlate(c.plateCode),
    );
  }
}

/// Devlet / vakıf dağılımı — iki şehir yan yana.
///
/// Pasta grafiği tek şehirlik; karşılaştırmada ikisi birlikte anlam
/// taşıdığı için tek kartta eşleniyor.
class _DistributionCard extends StatelessWidget {
  final CityComparisonResult result;
  const _DistributionCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.comparisonStateFoundationDistribution.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiaryFor(context),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Pie(
                  name: result.cityA.name,
                  stateCount: result.stateUniversityCountA,
                  foundationCount: result.foundationUniversityCountA,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Pie(
                  name: result.cityB.name,
                  stateCount: result.stateUniversityCountB,
                  foundationCount: result.foundationUniversityCountB,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pie extends StatelessWidget {
  final String name;
  final int stateCount;
  final int foundationCount;

  const _Pie({
    required this.name,
    required this.stateCount,
    required this.foundationCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondaryFor(context),
          ),
        ),
        const SizedBox(height: 8),
        CityComparPieChart(
          stateCount: stateCount,
          foundationCount: foundationCount,
        ),
      ],
    );
  }
}
