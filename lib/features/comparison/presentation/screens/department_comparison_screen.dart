import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/presentation/widgets/subscription_gate_widget.dart';
import '../../domain/models/department_comparison.dart';
import '../providers/comparison_providers.dart';
import '../widgets/department_picker_bottom_sheet.dart';
import '../widgets/offline_banner.dart';
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
    final resultAsync =
        pair == null ? const AsyncValue<DepartmentComparisonResult?>.data(null) : ref.watch(departmentComparisonResultProvider(pair));

    return SubscriptionGateWidget(
      requiredTier: SubscriptionTier.plus,
      showBlurPreview: true,
      onLocked: () => context.push('/compare/paywall'),
      child: Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          loc.comparisonDepartment,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textPrimary,
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
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
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
              if (!ref.watch(isOnlineProvider))
                const OfflineBanner(),
              Text(
                'Aynı bölümü farklı üniversitelerde kıyasla',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.65)
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _PickCard(
                      title: a?.department.name ?? loc.selectDepartmentA,
                      pick: _a,
                      accent: AppColors.primary,
                      onTap: () async {
                        final pick =
                            await DepartmentPickerBottomSheet.show(
                          context,
                          departmentNameFilter: _b?.department.name,
                        );
                        if (pick != null) setState(() => _a = pick);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickCard(
                      title: b?.department.name ?? loc.selectDepartmentB,
                      pick: _b,
                      accent: AppColors.secondary,
                      onTap: () async {
                        final pick =
                            await DepartmentPickerBottomSheet.show(
                          context,
                          departmentNameFilter: _a?.department.name,
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
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
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
        return _DepartmentResultView(result: effectiveResult);
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

    final pointsA = _metricPoint(baseA, baseB, higherIsBetter: true) +
        _metricPoint(rankA, rankB, higherIsBetter: false) +
        _metricPoint(fillA, fillB, higherIsBetter: true) +
        _metricPoint(quotaA, quotaB, higherIsBetter: true);
    final pointsB = _metricPoint(baseB, baseA, higherIsBetter: true) +
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
      hasScoreTypeMismatch: scoreTypeA != null &&
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
            child: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'İki taraftan da birer bölüm seçince karşılaştırma sonuçları burada gözükecek.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
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
                color: isDark ? Colors.white70 : AppColors.textSecondary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dept = pick?.department;
    final uni = pick?.university;
    final scoreType = dept?.scoreData?.scoreType ?? dept?.scoreType;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
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
                  if (uni != null)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.3),
                        ),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Image.asset(
                        uni.logoAssetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.school_rounded,
                          size: 14,
                          color: accent,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 9,
                      height: 9,
                      decoration:
                          BoxDecoration(color: accent, shape: BoxShape.circle),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                ],
              ),
              const SizedBox(height: 10),
              if (pick == null) ...[
                Text(
                  'Seçmek için dokun',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Bölüm Seç',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  dept?.name ?? '—',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  uni?.name ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaPill(
                      icon: Icons.timelapse_rounded,
                      label: '${dept?.duration ?? 4} yıl',
                    ),
                    _MetaPill(
                      icon: Icons.language_rounded,
                      label: dept?.language ?? 'Türkçe',
                    ),
                    if (scoreType != null && scoreType.isNotEmpty)
                      _MetaPill(
                        icon: Icons.stacked_bar_chart_rounded,
                        label: scoreType,
                      ),
                  ],
                ),
              ],
            ],
          ),
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
              size: 14, color: isDark ? Colors.white70 : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentResultView extends StatelessWidget {
  final DepartmentComparisonResult result;
  const _DepartmentResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseA = result.deptA.baseScore ?? result.deptA.scoreData?.baseScore ?? 0;
    final baseB = result.deptB.baseScore ?? result.deptB.scoreData?.baseScore ?? 0;
    final rankA = (result.deptA.ranking ?? result.deptA.scoreData?.ranking)?.toDouble() ?? 0;
    final rankB = (result.deptB.ranking ?? result.deptB.scoreData?.ranking)?.toDouble() ?? 0;
    final quotaA = (result.deptA.quota ?? result.deptA.scoreData?.quota)?.toDouble() ?? 0;
    final quotaB = (result.deptB.quota ?? result.deptB.scoreData?.quota)?.toDouble() ?? 0;
    final fillA = result.deptA.scoreData?.fillRate ?? 0;
    final fillB = result.deptB.scoreData?.fillRate ?? 0;

    return Column(
      children: [
        if (result.hasScoreTypeMismatch) ...[
          _MismatchBanner(isDark: isDark),
          const SizedBox(height: 12),
        ],
        _BigCompareCard(
          title: 'Taban Puan',
          leftLabel: 'A',
          rightLabel: 'B',
          leftValue: baseA > 0 ? baseA.toStringAsFixed(2) : '-',
          rightValue: baseB > 0 ? baseB.toStringAsFixed(2) : '-',
          delta: result.baseScoreDelta,
          higherIsBetter: true,
        ),
        const SizedBox(height: 12),
        _BigCompareCard(
          title: 'Sıralama',
          leftLabel: 'A',
          rightLabel: 'B',
          leftValue: rankA > 0 ? _formatRank(rankA.toInt()) : '-',
          rightValue: rankB > 0 ? _formatRank(rankB.toInt()) : '-',
          delta: result.rankingDelta,
          higherIsBetter: true, // delta already computed as B-A where + means A better
          invertDeltaPill: true,
        ),
        const SizedBox(height: 12),
        _BarCompareCard(
          title: 'Kontenjan',
          leftValue: quotaA,
          rightValue: quotaB,
          leftText: quotaA > 0 ? quotaA.toInt().toString() : '-',
          rightText: quotaB > 0 ? quotaB.toInt().toString() : '-',
          delta: result.quotaDelta,
          leftColor: AppColors.primary,
          rightColor: AppColors.secondary,
        ),
        const SizedBox(height: 12),
        _BarCompareCard(
          title: 'Doluluk',
          leftValue: fillA,
          rightValue: fillB,
          leftText: fillA > 0 ? '${(fillA * 100).toStringAsFixed(0)}%' : '-',
          rightText: fillB > 0 ? '${(fillB * 100).toStringAsFixed(0)}%' : '-',
          delta: result.fillRateDelta,
          leftColor: AppColors.primary,
          rightColor: AppColors.secondary,
          isRatio: true,
        ),
        const SizedBox(height: 12),
        _InfoRowCard(deptA: result.deptA, deptB: result.deptB),
      ],
    );
  }

  static String _formatRank(int rank) {
    if (rank >= 1000000) return '${(rank / 1000000).toStringAsFixed(1)}M';
    if (rank >= 1000) return '${(rank / 1000).toStringAsFixed(0)}B';
    return '$rank';
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
                color: isDark ? Colors.white70 : AppColors.textSecondary,
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
  final bool invertDeltaPill;

  const _BigCompareCard({
    required this.title,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftValue,
    required this.rightValue,
    required this.delta,
    required this.higherIsBetter,
    this.invertDeltaPill = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pill = _DeltaPill(delta: delta, higherIsBetter: higherIsBetter, invert: invertDeltaPill);
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
                    color: isDark ? Colors.white : AppColors.textPrimary,
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
                child: _SideValue(label: leftLabel, value: leftValue, color: AppColors.primary),
              ),
              Container(width: 1, height: 44, color: AppColors.borderLight),
              Expanded(
                child: _SideValue(label: rightLabel, value: rightValue, color: AppColors.secondary),
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
  const _SideValue({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
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
    final isGood = isZero ? null : (higherIsBetter ? (effective > 0) : (effective < 0));
    final bg = isGood == null
        ? AppColors.textTertiary.withValues(alpha: 0.10)
        : (isGood ? AppColors.success : AppColors.error).withValues(alpha: 0.12);
    final fg = isGood == null
        ? AppColors.textSecondary
        : (isGood ? AppColors.success : AppColors.error);

    final text = isZero ? '±0' : (effective > 0 ? '+${effective.toStringAsFixed(2)}' : effective.toStringAsFixed(2));

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

class _BarCompareCard extends StatelessWidget {
  final String title;
  final double leftValue;
  final double rightValue;
  final String leftText;
  final String rightText;
  final double delta;
  final Color leftColor;
  final Color rightColor;
  final bool isRatio;

  const _BarCompareCard({
    required this.title,
    required this.leftValue,
    required this.rightValue,
    required this.leftText,
    required this.rightText,
    required this.delta,
    required this.leftColor,
    required this.rightColor,
    this.isRatio = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxV = isRatio ? 1.0 : (leftValue > rightValue ? leftValue : rightValue);
    final leftPct = maxV <= 0 ? 0.0 : (leftValue / maxV).clamp(0.0, 1.0);
    final rightPct = maxV <= 0 ? 0.0 : (rightValue / maxV).clamp(0.0, 1.0);

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
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              _DeltaPill(delta: delta, higherIsBetter: true),
            ],
          ),
          const SizedBox(height: 12),
          _BarSide(
            label: 'A',
            text: leftText,
            color: leftColor,
            pct: leftPct,
          ),
          const SizedBox(height: 10),
          _BarSide(
            label: 'B',
            text: rightText,
            color: rightColor,
            pct: rightPct,
          ),
        ],
      ),
    );
  }
}

class _BarSide extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  final double pct;
  const _BarSide({
    required this.label,
    required this.text,
    required this.color,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 10,
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                width: MediaQuery.of(context).size.width * 0.72 * pct,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRowCard extends StatelessWidget {
  final dynamic deptA;
  final dynamic deptB;
  const _InfoRowCard({required this.deptA, required this.deptB});

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
            'Bilgiler',
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Süre', a: '${deptA.duration} yıl', b: '${deptB.duration} yıl'),
          const SizedBox(height: 8),
          _InfoRow(label: 'Dil', a: deptA.language, b: deptB.language),
          const SizedBox(height: 8),
          _InfoRow(label: 'Tür', a: deptA.type, b: deptB.type),
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
              color: AppColors.textTertiary,
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

