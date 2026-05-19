import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/university_abbreviations.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/presentation/widgets/subscription_gate_widget.dart';
import '../../domain/models/department_comparison.dart';
import '../providers/comparison_providers.dart';
import '../widgets/department_picker_bottom_sheet.dart';
import '../widgets/offline_banner.dart';
import '../widgets/comparison_notes_section.dart';
import '../widgets/comparison_picker_slot.dart';
import '../widgets/university_logo_box.dart';
import '../widgets/department_score_trend_chart.dart';
import '../widgets/department_yearly_table.dart';
import '../widgets/department_winner_card.dart';
import '../../../university/data/university_repository.dart';
import '../../../university/domain/models/department_model.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';

class DepartmentComparisonScreen extends ConsumerStatefulWidget {
  /// Deep-link / geçmişten gelen önceden seçili bölüm ID'leri.
  /// Verilirse initState'te repository'den lookup edilir ve _a/_b set'lenir.
  final String? initialAId;
  final String? initialBId;

  const DepartmentComparisonScreen({
    super.key,
    this.initialAId,
    this.initialBId,
  });

  @override
  ConsumerState<DepartmentComparisonScreen> createState() =>
      _DepartmentComparisonScreenState();
}

class _DepartmentComparisonScreenState
    extends ConsumerState<DepartmentComparisonScreen>
    with TickerProviderStateMixin {
  DepartmentPickResult? _a;
  DepartmentPickResult? _b;

  @override
  void initState() {
    super.initState();
    if (widget.initialAId != null || widget.initialBId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolveInitial());
    }
  }

  Future<void> _resolveInitial() async {
    final repo = UniversityRepository();
    Future<DepartmentPickResult?> lookup(String? id) async {
      if (id == null || id.isEmpty) return null;
      final dept = await repo.getDepartment(id);
      if (dept == null) return null;
      final uni = await repo.getUniversity(dept.universityId);
      if (uni == null) return null;
      return DepartmentPickResult(university: uni, department: dept);
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
        ? ComparisonPair(idA: a.department.id, idB: b.department.id)
        : null;
    final resultAsync = pair == null
        ? const AsyncValue<DepartmentComparisonResult?>.data(null)
        : ref.watch(departmentComparisonResultProvider(pair));

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
            loc.comparisonDepartment,
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
              final da = _a;
              final db = _b;
              if (da != null && db != null) {
                final pair = ComparisonPair(
                  idA: da.department.id,
                  idB: db.department.id,
                );
                ref.invalidate(departmentComparisonResultProvider(pair));
                await ref.read(departmentComparisonResultProvider(pair).future);
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Offline Banner ──────────────────────────────
                  if (!ref.watch(isOnlineProvider)) const OfflineBanner(),
                  // Header — başlık + alt başlık
                  const ComparisonPickerHeader(
                    icon: Icons.menu_book_rounded,
                    title: 'Bölüm Karşılaştır',
                    subtitle:
                        'Aynı bölümü iki farklı üniversitede karşılaştır. '
                        'Taban puan, sıralama ve kontenjan yan yana gelsin.',
                    accentColor: AppColors.primary,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _PickCard(
                          title: loc.selectDepartmentA,
                          pick: _a,
                          accent: AppColors.primary,
                          onTap: () async {
                            final pick = await DepartmentPickerBottomSheet.show(
                              context,
                              departmentNameFilter: _b?.department.name,
                              excludeUniversityId: _b?.university.id,
                            );
                            if (pick != null) setState(() => _a = pick);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      const ComparisonVsBadge(),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PickCard(
                          title: loc.selectDepartmentB,
                          pick: _b,
                          accent: AppColors.secondary,
                          onTap: () async {
                            final pick = await DepartmentPickerBottomSheet.show(
                              context,
                              departmentNameFilter: _a?.department.name,
                              excludeUniversityId: _a?.university.id,
                            );
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
    AsyncValue<DepartmentComparisonResult?> resultAsync,
  ) {
    if (_a == null || _b == null) {
      return _HintCard(isDark: isDark);
    }

    return resultAsync.when(
      loading: () => _ResultSkeleton(isDark: isDark),
      error: (e, _) => _ErrorCard(message: '$e', isDark: isDark),
      data: (result) {
        final da = _a;
        final db = _b;
        final fallback = (da != null && db != null)
            ? _buildFallbackResult(da.department, db.department)
            : null;
        final effectiveResult = result ?? fallback;
        if (effectiveResult == null) {
          return _ErrorCard(message: 'Sonuç bulunamadı.', isDark: isDark);
        }
        return _DepartmentResultView(
          result: effectiveResult,
          uniNameA: da?.university.name ?? '',
          uniNameB: db?.university.name ?? '',
        );
      },
    );
  }

  DepartmentComparisonResult _buildFallbackResult(
    DepartmentModel deptA,
    DepartmentModel deptB,
  ) {
    final baseA = deptA.baseScore ?? deptA.scoreData?.baseScore ?? 0;
    final baseB = deptB.baseScore ?? deptB.scoreData?.baseScore ?? 0;
    final rankA = (deptA.ranking ?? deptA.scoreData?.ranking)?.toDouble() ?? 0;
    final rankB = (deptB.ranking ?? deptB.scoreData?.ranking)?.toDouble() ?? 0;
    final quotaA = (deptA.quota ?? deptA.scoreData?.quota)?.toDouble() ?? 0;
    final quotaB = (deptB.quota ?? deptB.scoreData?.quota)?.toDouble() ?? 0;
    final fillA = _fillRate(
      quota: deptA.scoreData?.quota ?? deptA.quota,
      placed: deptA.scoreData?.placedCount,
    );
    final fillB = _fillRate(
      quota: deptB.scoreData?.quota ?? deptB.quota,
      placed: deptB.scoreData?.placedCount,
    );

    final pointsA =
        _metricPoint(baseA, baseB, higherIsBetter: true) +
        _metricPoint(rankA, rankB, higherIsBetter: false) +
        _metricPoint(fillA, fillB, higherIsBetter: true) +
        _metricPoint(quotaA, quotaB, higherIsBetter: true);
    final pointsB =
        _metricPoint(baseB, baseA, higherIsBetter: true) +
        _metricPoint(rankB, rankA, higherIsBetter: false) +
        _metricPoint(fillB, fillA, higherIsBetter: true) +
        _metricPoint(quotaB, quotaA, higherIsBetter: true);

    String? winnerId;
    if (pointsA > pointsB) {
      winnerId = deptA.id;
    } else if (pointsB > pointsA) {
      winnerId = deptB.id;
    }

    final scoreTypeA = deptA.scoreType ?? deptA.scoreData?.scoreType;
    final scoreTypeB = deptB.scoreType ?? deptB.scoreData?.scoreType;

    return DepartmentComparisonResult(
      deptA: deptA,
      deptB: deptB,
      scoreDeltas: <String, double>{
        'baseScore': baseA - baseB,
        'ranking': rankB - rankA,
        'fillRate': fillA - fillB,
        'quota': quotaA - quotaB,
      },
      winnerId: winnerId,
      hasScoreTypeMismatch:
          scoreTypeA != null &&
          scoreTypeB != null &&
          scoreTypeA.isNotEmpty &&
          scoreTypeB.isNotEmpty &&
          scoreTypeA != scoreTypeB,
    );
  }

  int _metricPoint(double a, double b, {required bool higherIsBetter}) {
    if ((a - b).abs() < 0.0001) return 0;
    if (higherIsBetter) return a > b ? 1 : 0;
    return a < b ? 1 : 0;
  }

  double _fillRate({int? quota, int? placed}) {
    if (quota == null || placed == null || quota <= 0) return 0;
    return placed / quota;
  }
}

class _HintCard extends StatelessWidget {
  final bool isDark;
  const _HintCard({required this.isDark});

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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'İki taraftan da birer bölüm seçince karşılaştırma sonuçları burada gözükecek.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? Colors.white70
                    : AppColors.textSecondaryFor(context),
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
                color: isDark
                    ? Colors.white70
                    : AppColors.textSecondaryFor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickCard extends StatelessWidget {
  final String title;
  final DepartmentPickResult? pick;
  final Color accent;
  final VoidCallback onTap;

  const _PickCard({
    required this.title,
    required this.pick,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = pick;
    if (p == null) {
      return ComparisonPickerSlot(
        isEmpty: true,
        emptyLabel: title,
        emptyIcon: Icons.menu_book_rounded,
        accentColor: accent,
        onTap: onTap,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dept = p.department;
    final uni = p.university;
    final scoreType = dept.scoreData?.scoreType ?? dept.scoreType;

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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            UniversityLogoBox(
              universityId: uni.id,
              universityName: uni.name,
              accentColor: accent,
              size: 52,
            ),
            const SizedBox(height: 8),
            Text(
              dept.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                height: 1.2,
                color: isDark
                    ? Colors.white
                    : AppColors.textPrimaryFor(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              uni.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: accent,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                _MetaPill(
                  icon: Icons.timelapse_rounded,
                  label: '${dept.duration}y',
                ),
                if (scoreType != null && scoreType.isNotEmpty)
                  _MetaPill(
                    icon: Icons.stacked_bar_chart_rounded,
                    label: scoreType,
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
          Icon(
            icon,
            size: 14,
            color: isDark
                ? Colors.white70
                : AppColors.textSecondaryFor(context),
          ),
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

class _DepartmentResultView extends StatelessWidget {
  final DepartmentComparisonResult result;
  final String uniNameA;
  final String uniNameB;
  const _DepartmentResultView({
    required this.result,
    required this.uniNameA,
    required this.uniNameB,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseA =
        result.deptA.baseScore ?? result.deptA.scoreData?.baseScore ?? 0;
    final baseB =
        result.deptB.baseScore ?? result.deptB.scoreData?.baseScore ?? 0;
    final quotaA =
        (result.deptA.quota ?? result.deptA.scoreData?.quota)?.toDouble() ?? 0;
    final quotaB =
        (result.deptB.quota ?? result.deptB.scoreData?.quota)?.toDouble() ?? 0;
    final fillA = result.deptA.scoreData?.fillRate ?? 0;
    final fillB = result.deptB.scoreData?.fillRate ?? 0;

    // Kısa üniversite label'ları (chart legend için)
    final shortA = _shortUniLabel(uniNameA);
    final shortB = _shortUniLabel(uniNameB);

    return Column(
      children: [
        if (result.hasScoreTypeMismatch) ...[
          _MismatchBanner(isDark: isDark),
          const SizedBox(height: 12),
        ],

        // ⭐ Kazanan Özet Kartı
        DepartmentWinnerCard(
          result: result,
          uniNameA: uniNameA,
          uniNameB: uniNameB,
        ),
        const SizedBox(height: 16),

        // Taban Puan
        _BigCompareCard(
          title: 'Taban Puan (2025)',
          leftLabel: shortA,
          rightLabel: shortB,
          leftValue: baseA > 0 ? baseA.toStringAsFixed(2) : '-',
          rightValue: baseB > 0 ? baseB.toStringAsFixed(2) : '-',
          delta: result.baseScoreDelta,
          higherIsBetter: true,
        ),
        const SizedBox(height: 12),

        // 📈 Puan Trend Grafiği
        DepartmentScoreTrendChart(
          deptA: result.deptA,
          deptB: result.deptB,
          labelA: shortA,
          labelB: shortB,
        ),
        const SizedBox(height: 12),

        // Sıralama (ıl bazlı tab)
        _RankingYearCard(
          deptA: result.deptA,
          deptB: result.deptB,
          labelA: shortA,
          labelB: shortB,
        ),
        const SizedBox(height: 12),

        // 📊 Yıl Bazlı Tablo
        DepartmentYearlyTable(
          deptA: result.deptA,
          deptB: result.deptB,
          labelA: shortA,
          labelB: shortB,
        ),
        const SizedBox(height: 12),

        // Kontenjan + Doluluk
        Row(
          children: [
            Expanded(
              child: _CompactMetricCard(
                title: 'Kontenjan',
                icon: Icons.people_rounded,
                labelA: shortA,
                labelB: shortB,
                valueA: quotaA > 0 ? quotaA.toInt().toString() : '-',
                valueB: quotaB > 0 ? quotaB.toInt().toString() : '-',
                delta: result.quotaDelta,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CompactMetricCard(
                title: 'Doluluk',
                icon: Icons.check_circle_rounded,
                labelA: shortA,
                labelB: shortB,
                valueA: fillA > 0
                    ? '${(fillA * 100).toStringAsFixed(0)}%'
                    : '-',
                valueB: fillB > 0
                    ? '${(fillB * 100).toStringAsFixed(0)}%'
                    : '-',
                delta: result.fillRateDelta,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 📋 Detaylı Bilgi Kartı
        _DetailedInfoCard(deptA: result.deptA, deptB: result.deptB),
        const SizedBox(height: 16),

        // Pro — Karşılaştırma Notları
        ComparisonNotesSection(
          comparisonType: 'department',
          entityAId: result.deptA.id,
          entityBId: result.deptB.id,
        ),
      ],
    );
  }

  static String _shortUniLabel(String name) {
    return UniversityAbbreviations.shorten(name);
  }
}

class _MismatchBanner extends StatelessWidget {
  final bool isDark;
  const _MismatchBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Puan türleri farklı görünüyor. Karşılaştırma yanıltıcı olabilir.',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? Colors.white70
                    : AppColors.textSecondaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigCompareCard extends StatelessWidget {
  final String title;
  final String leftLabel;
  final String rightLabel;
  final String leftValue;
  final String rightValue;
  final double delta;
  final bool higherIsBetter;

  const _BigCompareCard({
    required this.title,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftValue,
    required this.rightValue,
    required this.delta,
    this.higherIsBetter = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pill = _DeltaPill(
      delta: delta,
      higherIsBetter: higherIsBetter,
    );
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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? Colors.white
                        : AppColors.textPrimaryFor(context),
                  ),
                ),
              ),
              pill,
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SideValue(
                  label: leftLabel,
                  value: leftValue,
                  color: AppColors.primary,
                ),
              ),
              Container(
                width: 1,
                height: 44,
                color: AppColors.borderLightFor(context),
              ),
              Expanded(
                child: _SideValue(
                  label: rightLabel,
                  value: rightValue,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SideValue extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SideValue({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiaryFor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _DeltaPill extends StatelessWidget {
  final double delta;
  final bool higherIsBetter;
  final bool invert;
  const _DeltaPill({
    required this.delta,
    required this.higherIsBetter,
    this.invert = false,
  });

  @override
  Widget build(BuildContext context) {
    final isZero = delta.abs() < 0.0001;
    final effective = invert ? -delta : delta;
    final isGood = isZero
        ? null
        : (higherIsBetter ? (effective > 0) : (effective < 0));
    final bg = isGood == null
        ? AppColors.textTertiary.withValues(alpha: 0.10)
        : (isGood ? AppColors.success : AppColors.error).withValues(
            alpha: 0.12,
          );
    final fg = isGood == null
        ? AppColors.textSecondary
        : (isGood ? AppColors.success : AppColors.error);

    final text = isZero
        ? '±0'
        : (effective > 0
              ? '+${effective.toStringAsFixed(2)}'
              : effective.toStringAsFixed(2));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }
}

/// Kontenjan / Doluluk gibi metrikleri kompakt gösteren kart.
class _CompactMetricCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String labelA;
  final String labelB;
  final String valueA;
  final String valueB;
  final double delta;
  final bool isDark;

  const _CompactMetricCard({
    required this.title,
    required this.icon,
    required this.labelA,
    required this.labelB,
    required this.valueA,
    required this.valueB,
    required this.delta,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isZero = delta.abs() < 0.001;
    final isPositive = delta > 0;

    return Container(
      padding: const EdgeInsets.all(14),
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
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: isDark
                    ? Colors.white54
                    : AppColors.textTertiaryFor(context),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? Colors.white70
                        : AppColors.textSecondaryFor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    labelA,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    ),
                  ),
                  Text(
                    valueA,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    labelB,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.secondary.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    ),
                  ),
                  Text(
                    valueB,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Delta pill
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:
                    (isZero
                            ? AppColors.textTertiary
                            : isPositive
                            ? AppColors.success
                            : AppColors.error)
                        .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isZero
                    ? '±0'
                    : '${isPositive ? "+" : ""}${delta.toStringAsFixed(1)}',
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  color: isZero
                      ? AppColors.textTertiary
                      : isPositive
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Detaylı bilgi kartı — Fakülte, Dil, Süre, Tür, Puan Türü.
class _DetailedInfoCard extends StatelessWidget {
  final DepartmentModel deptA;
  final DepartmentModel deptB;
  const _DetailedInfoCard({required this.deptA, required this.deptB});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scoreTypeA = deptA.scoreData?.scoreType ?? deptA.scoreType ?? '';
    final scoreTypeB = deptB.scoreData?.scoreType ?? deptB.scoreType ?? '';

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.info.withValues(alpha: 0.18),
                      AppColors.info.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Detaylı Bilgiler',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? Colors.white
                      : AppColors.textPrimaryFor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DetailRow(
            label: 'Fakülte',
            a: deptA.faculty.isNotEmpty ? deptA.faculty : '-',
            b: deptB.faculty.isNotEmpty ? deptB.faculty : '-',
          ),
          _DetailDivider(isDark: isDark),
          _DetailRow(
            label: 'Süre',
            a: '${deptA.duration} yıl',
            b: '${deptB.duration} yıl',
          ),
          _DetailDivider(isDark: isDark),
          _DetailRow(label: 'Dil', a: deptA.language, b: deptB.language),
          _DetailDivider(isDark: isDark),
          _DetailRow(label: 'Tür', a: deptA.type, b: deptB.type),
          if (scoreTypeA.isNotEmpty || scoreTypeB.isNotEmpty) ...[
            _DetailDivider(isDark: isDark),
            _DetailRow(
              label: 'Puan Türü',
              a: scoreTypeA.isNotEmpty ? scoreTypeA : '-',
              b: scoreTypeB.isNotEmpty ? scoreTypeB : '-',
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailDivider extends StatelessWidget {
  final bool isDark;
  const _DetailDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        height: 1,
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String a;
  final String b;
  const _DetailRow({required this.label, required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            a,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              height: 1.3,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isDark
                      ? Colors.white38
                      : AppColors.textTertiaryFor(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            b,
            textAlign: TextAlign.left,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.secondary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

/// Yükleme sırasında gösterilen iskelet animasyonu.
class _ResultSkeleton extends StatelessWidget {
  final bool isDark;
  const _ResultSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i < 3 ? 12 : 0),
          child: _ShimmerBlock(
            height: i == 0 ? 120 : (i == 1 ? 90 : 70),
            isDark: isDark,
          ),
        );
      }),
    );
  }
}

class _ShimmerBlock extends StatefulWidget {
  final double height;
  final bool isDark;
  const _ShimmerBlock({required this.height, required this.isDark});

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final shimmer = _ctrl.value;
        return Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * shimmer, 0),
              end: Alignment(-0.5 + 2.0 * shimmer, 0),
              colors: widget.isDark
                  ? [
                      Colors.white.withValues(alpha: 0.04),
                      Colors.white.withValues(alpha: 0.10),
                      Colors.white.withValues(alpha: 0.04),
                    ]
                  : [
                      Colors.grey.shade200,
                      Colors.grey.shade100,
                      Colors.grey.shade200,
                    ],
            ),
          ),
        );
      },
    );
  }
}

/// Yıl seçmeli sıralama kartı — 2022, 2023, 2024, 2025 butonlarıyla.
class _RankingYearCard extends StatefulWidget {
  final DepartmentModel deptA;
  final DepartmentModel deptB;
  final String labelA;
  final String labelB;

  const _RankingYearCard({
    required this.deptA,
    required this.deptB,
    required this.labelA,
    required this.labelB,
  });

  @override
  State<_RankingYearCard> createState() => _RankingYearCardState();
}

class _RankingYearCardState extends State<_RankingYearCard> {
  int _selectedYear = 2024; // Default 2024 (en son açıklanan)

  Map<int, int> _getRankings(DepartmentModel dept) {
    final rankings = <int, int>{};
    final sd = dept.scoreData;
    if (sd != null) {
      for (final entry in sd.previousYears.entries) {
        if (entry.value.ranking > 0) {
          rankings[entry.key] = entry.value.ranking;
        }
      }
      if (sd.ranking > 0) {
        rankings[sd.year] = sd.ranking;
      }
    }
    if (rankings.isEmpty && (dept.ranking ?? 0) > 0) {
      rankings[2025] = dept.ranking!;
    }
    return rankings;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rankingsA = _getRankings(widget.deptA);
    final rankingsB = _getRankings(widget.deptB);

    // Her zaman 2022-2025 göster
    final years = [2022, 2023, 2024, 2025];

    final rankA = rankingsA[_selectedYear];
    final rankB = rankingsB[_selectedYear];

    // Delta hesapla (düşük sıralama daha iyi)
    double delta = 0;
    if (rankA != null && rankB != null && rankA > 0 && rankB > 0) {
      delta = (rankB - rankA).toDouble();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warning.withValues(alpha: 0.18),
                      AppColors.warning.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.format_list_numbered_rounded,
                    size: 16, color: AppColors.warning),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sıralama',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? Colors.white
                        : AppColors.textPrimaryFor(context),
                  ),
                ),
              ),
              if (delta.abs() > 0)
                _DeltaPill(delta: delta, higherIsBetter: true, invert: true),
            ],
          ),
          const SizedBox(height: 14),

          // Yıl butonları
          Row(
            children: years.map((year) {
              final isSelected = year == _selectedYear;
              final hasData =
                  rankingsA.containsKey(year) || rankingsB.containsKey(year);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: year < 2025 ? 6 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedYear = year),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.warning
                            : (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.06),
                              ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$year',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelSmall.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.white
                                  : hasData
                                      ? (isDark
                                          ? Colors.white70
                                          : AppColors.textSecondaryFor(
                                              context))
                                      : (isDark
                                          ? Colors.white24
                                          : AppColors.textTertiaryFor(
                                              context)),
                            ),
                          ),
                          if (!hasData)
                            Text(
                              'veri yok',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontSize: 7,
                                color: isSelected
                                    ? Colors.white70
                                    : (isDark
                                        ? Colors.white24
                                        : AppColors.textTertiaryFor(context)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Sıralama değerleri
          Row(
            children: [
              Expanded(
                child: _SideValue(
                  label: widget.labelA,
                  value: rankA != null && rankA > 0
                      ? _formatRank(rankA)
                      : 'Veri yok',
                  color: AppColors.primary,
                ),
              ),
              Container(
                width: 1,
                height: 44,
                color: AppColors.borderLightFor(context),
              ),
              Expanded(
                child: _SideValue(
                  label: widget.labelB,
                  value: rankB != null && rankB > 0
                      ? _formatRank(rankB)
                      : 'Veri yok',
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatRank(int rank) {
    // Binlik ayraçlı tam sayı: 4311 → "4.311"
    final str = rank.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return buf.toString();
  }
}
