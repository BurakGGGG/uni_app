import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/university_abbreviations.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/presentation/widgets/subscription_gate_widget.dart';
import '../../../university/data/university_repository.dart';
import '../../../university/domain/models/department_model.dart';
import '../../domain/compare_view_builders.dart';
import '../../domain/models/department_comparison.dart';
import '../providers/compare_pick_providers.dart';
import '../providers/comparison_providers.dart';
import '../widgets/compare/compare_layout.dart';
import '../widgets/compare/compare_pick_stage.dart';
import '../widgets/comparison_notes_section.dart';
import '../widgets/comparison_picker_slot.dart';
import '../widgets/department_picker_bottom_sheet.dart';
import '../widgets/department_score_trend_chart.dart';
import '../widgets/department_yearly_table.dart';
import '../widgets/offline_banner.dart';
import '../widgets/university_logo_box.dart';

/// Bölüm karşılaştırma — aynı bölüm, iki üniversite.
///
/// Üniversite ve şehir ekranlarıyla AYNI iskeleti kullanıyor
/// (`CompareLayout`), üçü kardeş görünsün diye (kullanıcı kararı).
class DepartmentComparisonScreen extends ConsumerStatefulWidget {
  /// Deep-link / geçmişten gelen önceden seçili bölüm ID'leri.
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
    extends ConsumerState<DepartmentComparisonScreen> {
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

  /// Karşı tarafın bölüm adıyla filtreli seçici — aynı bölümü farklı
  /// üniversitede karşılaştırmak bu ekranın asıl işi.
  Future<void> _pick(int index) async {
    final other = index == 0 ? _b : _a;
    final pick = await DepartmentPickerBottomSheet.show(
      context,
      departmentNameFilter: other?.department.name,
      excludeUniversityId: other?.university.id,
    );
    if (pick == null || !mounted) return;
    setState(() {
      if (index == 0) {
        _a = pick;
      } else {
        _b = pick;
      }
    });
  }

  /// Öneriden gelen bölüm adı seçiciyi hazır süzgeçle açar: aynı bölümü
  /// sunan üniversiteler listelenir, kullanıcı yalnız birini seçer.
  Future<void> _pickNamed(String departmentName) async {
    final index = _a == null ? 0 : 1;
    final other = index == 0 ? _b : _a;
    final pick = await DepartmentPickerBottomSheet.show(
      context,
      departmentNameFilter: departmentName,
      excludeUniversityId: other?.university.id,
    );
    if (pick == null || !mounted) return;
    setState(() {
      if (index == 0) {
        _a = pick;
      } else {
        _b = pick;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
    AsyncValue<DepartmentComparisonResult?> resultAsync,
  ) {
    final loc = AppLocalizations.of(context);
    final a = _a;
    final b = _b;

    if (a == null || b == null) {
      return _PickStage(a: a, b: b, onPick: _pick, onSuggested: _pickNamed);
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
        // Sunucu sonucu yoksa iki bölümün kendi verisinden kurulan yedek —
        // ekran boş kalmasın.
        final effective = result ?? _fallback(a.department, b.department);
        return _Result(
          result: effective,
          uniNameA: a.university.name,
          uniNameB: b.university.name,
          onChangeSide: _pick,
          onRefresh: () async {
            final pair = ComparisonPair(
              idA: a.department.id,
              idB: b.department.id,
            );
            ref.invalidate(departmentComparisonResultProvider(pair));
            await ref.read(departmentComparisonResultProvider(pair).future);
          },
        );
      },
    );
  }

  DepartmentComparisonResult _fallback(
    DepartmentModel deptA,
    DepartmentModel deptB,
  ) {
    final baseA = deptA.baseScore ?? deptA.scoreData?.baseScore ?? 0;
    final baseB = deptB.baseScore ?? deptB.scoreData?.baseScore ?? 0;
    final rankA = (deptA.ranking ?? deptA.scoreData?.ranking)?.toDouble() ?? 0;
    final rankB = (deptB.ranking ?? deptB.scoreData?.ranking)?.toDouble() ?? 0;
    final quotaA = (deptA.quota ?? deptA.scoreData?.quota)?.toDouble() ?? 0;
    final quotaB = (deptB.quota ?? deptB.scoreData?.quota)?.toDouble() ?? 0;
    final fillA = deptA.scoreData?.fillRate ?? 0;
    final fillB = deptB.scoreData?.fillRate ?? 0;

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
      // Kazanan artık hiçbir yerde çizilmiyor; model sözleşmesi gereği
      // alan duruyor ama doldurulmuyor.
      winnerId: null,
      hasScoreTypeMismatch: scoreTypeA != null &&
          scoreTypeB != null &&
          scoreTypeA.isNotEmpty &&
          scoreTypeB.isNotEmpty &&
          scoreTypeA != scoreTypeB,
    );
  }
}

// ─── Sonuç ─────────────────────────────────────────────────────────

class _Result extends StatelessWidget {
  final DepartmentComparisonResult result;
  final String uniNameA;
  final String uniNameB;
  final ValueChanged<int> onChangeSide;
  final Future<void> Function() onRefresh;

  const _Result({
    required this.result,
    required this.uniNameA,
    required this.uniNameB,
    required this.onChangeSide,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final shortA = UniversityAbbreviations.shorten(uniNameA);
    final shortB = UniversityAbbreviations.shorten(uniNameB);

    // Kazanan kartı KALKTI (kullanıcı kararı): biri taban puanda, öteki
    // kontenjanda öndeyken tek bir "kazanan" ilan etmek kararı öğrencinin
    // elinden alıyordu.
    return CompareLayout(
      view: departmentCompareView(
        result,
        loc,
        uniNameA: uniNameA,
        uniNameB: uniNameB,
      ),
      onChangeSide: onChangeSide,
      onRefresh: onRefresh,
      banner: result.hasScoreTypeMismatch ? const _MismatchBanner() : null,
      extras: [
        DepartmentScoreTrendChart(
          deptA: result.deptA,
          deptB: result.deptB,
          labelA: shortA,
          labelB: shortB,
        ),
        DepartmentYearlyTable(
          deptA: result.deptA,
          deptB: result.deptB,
          labelA: shortA,
          labelB: shortB,
        ),
        ComparisonNotesSection(
          comparisonType: 'department',
          entityAId: result.deptA.id,
          entityBId: result.deptB.id,
        ),
      ],
    );
  }
}

/// Puan türleri farklıysa uyarı — taban puanları kıyaslamak anlamsız olur.
class _MismatchBanner extends StatelessWidget {
  const _MismatchBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context).comparisonScoreTypeMismatch,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Seçim aşaması ─────────────────────────────────────────────────

class _PickStage extends ConsumerWidget {
  final DepartmentPickResult? a;
  final DepartmentPickResult? b;
  final ValueChanged<int> onPick;
  final ValueChanged<String> onSuggested;

  const _PickStage({
    required this.a,
    required this.b,
    required this.onPick,
    required this.onSuggested,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final suggestions =
        ref.watch(comparePickDepartmentNamesProvider).valueOrNull;
    // Bir taraf seçiliyken öneriler anlamsız: ikinci taraf zaten aynı
    // bölümle sınırlı, seçici o süzgeçle açılıyor.
    final showSuggestions = a == null && b == null;

    return ComparePickStage(
      lead: loc.comparisonDepartmentHeaderSubtitle,
      filledA: a != null,
      filledB: b != null,
      nextLabel: a == null ? loc.selectDepartmentA : loc.selectDepartmentB,
      slotA: _PickCard(
        title: loc.selectDepartmentA,
        pick: a,
        accent: AppColors.primary,
        onTap: () => onPick(0),
      ),
      slotB: _PickCard(
        title: loc.selectDepartmentB,
        pick: b,
        accent: AppColors.secondary,
        onTap: () => onPick(1),
      ),
      children: [
        if (showSuggestions)
          ComparePickSuggestions(
            title: loc.cmpPickSuggestDepartment,
            items: [
              for (final name in suggestions ?? const <String>[])
                ComparePickSuggestion(
                  label: name,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  onTap: () => onSuggested(name),
                ),
            ],
          ),
      ],
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

    final dept = p.department;
    final uni = p.university;
    final scoreType = dept.scoreData?.scoreType ?? dept.scoreType;

    return ComparisonPickerSlot(
      isEmpty: false,
      emptyLabel: title,
      emptyIcon: Icons.menu_book_rounded,
      accentColor: accent,
      onTap: onTap,
      logo: UniversityLogoBox(
        universityId: uni.id,
        universityName: uni.name,
        accentColor: accent,
        size: 48,
      ),
      title: dept.name,
      subtitle: scoreType == null || scoreType.isEmpty
          ? uni.name
          : '${uni.name} · $scoreType',
    );
  }
}
