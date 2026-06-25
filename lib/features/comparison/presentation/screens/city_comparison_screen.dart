import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/presentation/widgets/subscription_gate_widget.dart';
import '../../../university/domain/models/city_model.dart';
import '../../../university/presentation/widgets/city_logo.dart';
import '../../domain/models/city_comparison.dart';
import '../providers/comparison_providers.dart';
import '../widgets/city_compar_pie_chart.dart';
import '../widgets/city_picker_bottom_sheet.dart';
import '../widgets/offline_banner.dart';
import '../widgets/comparison_picker_slot.dart';
import '../widgets/comparison_notes_section.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../university/data/university_repository.dart';

class CityComparisonScreen extends ConsumerStatefulWidget {
  /// Deep-link / geçmişten gelen önceden seçili şehir ID'leri.
  /// Verilirse initState'te repository'den lookup edilir ve _a/_b set'lenir.
  final String? initialAId;
  final String? initialBId;

  const CityComparisonScreen({
    super.key,
    this.initialAId,
    this.initialBId,
  });

  @override
  ConsumerState<CityComparisonScreen> createState() => _CityComparisonScreenState();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            color: isDark ? Colors.white : AppColors.textPrimaryFor(context),
          ),
        ),
        actions: [
          if (_a != null || _b != null)
            TextButton.icon(
              onPressed: () => setState(() {
                _a = null;
                _b = null;
              }),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(loc.reset),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            final ca = _a;
            final cb = _b;
            if (ca != null && cb != null) {
              final pair = ComparisonPair(idA: ca.id, idB: cb.id);
              ref.invalidate(cityComparisonResultProvider(pair));
              await ref.read(cityComparisonResultProvider(pair).future);
            }
          },
          child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Offline Banner ──────────────────────────────
              if (!ref.watch(isOnlineProvider))
                const OfflineBanner(),
              // Header — başlık + alt başlık
              ComparisonPickerHeader(
                icon: Icons.location_city_rounded,
                title: loc.comparisonCityHeaderTitle,
                subtitle: loc.comparisonCityHeaderSubtitle,
                accentColor: AppColors.primary,
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _CityPickCard(
                      title: loc.selectCityA,
                      city: _a,
                      accent: AppColors.primary,
                      onTap: () async {
                        final pick = await CityPickerBottomSheet.show(context);
                        if (pick != null) setState(() => _a = pick);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  const ComparisonVsBadge(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CityPickCard(
                      title: loc.selectCityB,
                      city: _b,
                      accent: AppColors.secondary,
                      onTap: () async {
                        final pick = await CityPickerBottomSheet.show(context);
                        if (pick != null) setState(() => _b = pick);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _buildResultArea(context, isDark, resultAsync),
              ),
            ],
          ),
        ),
        ),
      ),
      ),
    );
  }

  Widget _buildResultArea(
    BuildContext context,
    bool isDark,
    AsyncValue<CityComparisonResult?> resultAsync,
  ) {
    if (_a == null || _b == null) {
      return _HintCard(isDark: isDark);
    }

    return resultAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _ErrorCard(message: '$e', isDark: isDark),
      data: (result) {
        final ca = _a;
        final cb = _b;
        final fallback = (ca != null && cb != null)
            ? _buildFallbackResult(ca, cb)
            : null;
        final effectiveResult = result ?? fallback;
        if (effectiveResult == null) {
          return _ErrorCard(
            message: AppLocalizations.of(context).comparisonResultNotFound,
            isDark: isDark,
          );
        }
        return _CityResultView(result: effectiveResult);
      },
    );
  }

  CityComparisonResult _buildFallbackResult(CityModel cityA, CityModel cityB) {
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

class _HintCard extends StatelessWidget {
  final bool isDark;
  const _HintCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_city_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              loc.comparisonCityHint,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondaryFor(context),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final bool isDark;
  const _ErrorCard({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondaryFor(context),
              ),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: isDark ? 0.14 : 0.08),
              isDark ? AppColors.darkSurface : AppColors.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.15),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CityLogo(city: c, size: 56, withBackground: true),
            const SizedBox(height: 10),
            Text(
              c.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                height: 1.2,
                color: isDark ? Colors.white : AppColors.textPrimaryFor(context),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                _MetaPill(
                  icon: Icons.confirmation_number_rounded,
                  label: c.plateCode,
                ),
                _MetaPill(
                  icon: Icons.school_rounded,
                  label: '${c.appUniversityCount}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14, color: isDark ? Colors.white70 : AppColors.textSecondaryFor(context)),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimaryFor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _CityResultView extends StatelessWidget {
  final CityComparisonResult result;
  const _CityResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Column(
      children: [
        // ─── Üniversite Sayısı ──────────────────────────
        _CompareBarCard(
          title: loc.comparisonUniversityCount,
          labelA: result.cityA.name,
          labelB: result.cityB.name,
          valueA: result.universityCountA.toDouble(),
          valueB: result.universityCountB.toDouble(),
          textA: '${result.universityCountA}',
          textB: '${result.universityCountB}',
        ),
        const SizedBox(height: 12),

        // ─── Devlet / Vakıf Dağılımı ─────────────────
        _Card(
          title: loc.comparisonStateFoundationDistribution,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(result.cityA.name,
                        style: AppTextStyles.labelSmall.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        )),
                    const SizedBox(height: 8),
                    CityComparPieChart(
                      stateCount: result.stateUniversityCountA,
                      foundationCount: result.foundationUniversityCountA,
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 100,
                color: AppColors.borderLightFor(context),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(result.cityB.name,
                        style: AppTextStyles.labelSmall.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondary,
                        )),
                    const SizedBox(height: 8),
                    CityComparPieChart(
                      stateCount: result.stateUniversityCountB,
                      foundationCount: result.foundationUniversityCountB,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ─── Nüfus ─────────────────────────────────
        if ((result.populationA ?? 0) > 0 || (result.populationB ?? 0) > 0)
          _CompareBarCard(
            title: loc.comparisonPopulation,
            labelA: result.cityA.name,
            labelB: result.cityB.name,
            valueA: (result.populationA ?? 0).toDouble(),
            valueB: (result.populationB ?? 0).toDouble(),
            textA: _formatPopulation(result.populationA ?? 0),
            textB: _formatPopulation(result.populationB ?? 0),
          ),
        if ((result.populationA ?? 0) > 0 || (result.populationB ?? 0) > 0)
          const SizedBox(height: 12),

        // ─── Şehir Özellikleri ────────────────────────
        _Card(
          title: loc.comparisonCityFeatures,
          child: Column(
            children: [
              _InfoRow(
                label: loc.comparisonPlate,
                a: result.cityA.plateCode,
                b: result.cityB.plateCode,
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: loc.comparisonTotalUniversities,
                a: result.cityA.totalUniversityCount.toString(),
                b: result.cityB.totalUniversityCount.toString(),
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: loc.comparisonInUniSec,
                a: result.cityA.appUniversityCount.toString(),
                b: result.cityB.appUniversityCount.toString(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Pro — Karşılaştırma Notları
        ComparisonNotesSection(
          comparisonType: 'city',
          entityAId: result.cityA.id,
          entityBId: result.cityB.id,
        ),
      ],
    );
  }

  static String _formatPopulation(int pop) {
    if (pop >= 1000000) return '${(pop / 1000000).toStringAsFixed(1)}M';
    if (pop >= 1000) return '${(pop / 1000).toStringAsFixed(0)}B';
    return '$pop';
  }
}

class _CompareBarCard extends StatelessWidget {
  final String title;
  final String labelA;
  final String labelB;
  final double valueA;
  final double valueB;
  final String textA;
  final String textB;

  const _CompareBarCard({
    required this.title,
    required this.labelA,
    required this.labelB,
    required this.valueA,
    required this.valueB,
    required this.textA,
    required this.textB,
  });

  @override
  Widget build(BuildContext context) {
    // isDark not needed here
    final maxV = (valueA > valueB ? valueA : valueB).clamp(1.0, double.infinity);
    final pctA = (valueA / maxV).clamp(0.0, 1.0);
    final pctB = (valueB / maxV).clamp(0.0, 1.0);

    return _Card(
      title: title,
      child: Column(
        children: [
          _BarRow(
            label: labelA,
            value: textA,
            pct: pctA,
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          _BarRow(
            label: labelB,
            value: textB,
            pct: pctB,
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final String value;
  final double pct;
  final Color color;
  const _BarRow({
    required this.label,
    required this.value,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              value,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 10,
            backgroundColor: color.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}



class _InfoRow extends StatelessWidget {
  final String label;
  final String a;
  final String b;
  const _InfoRow({required this.label, required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            a,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiaryFor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            b,
            textAlign: TextAlign.left,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.secondary,
            ),
          ),
        ),
      ],
    );
  }
}
