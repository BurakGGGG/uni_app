import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../score_calculator/domain/models/match_result.dart';
import '../../../university/domain/models/department_model.dart';
import '../../../university/presentation/widgets/score_badge.dart';
import '../../domain/match_reason.dart';
import '../../domain/similar_programs.dart';
import '../providers/preference_wizard_providers.dart';
import 'add_to_list_sheet.dart';
import 'feasibility_chip.dart';
import 'similar_programs_sheet.dart';

/// Tercih robotu öneri kartı — üni logosu/marka, bölüm, taban/sıralama/kontenjan
/// mini-stat, uygunluk rozeti, fit skoru, gerekçe ve "+ Listeye ekle".
/// [onLongPress] verilirse uzun basış karşılaştırma seçimini değiştirir;
/// [selected] kart çerçevesini vurgular.
class WizardRecommendationCard extends ConsumerWidget {
  final UniversityMatch match;
  final bool selected;
  final VoidCallback? onLongPress;
  const WizardRecommendationCard({
    super.key,
    required this.match,
    this.selected = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uni = match.university;
    final dept = match.department;
    final brand = uni.brandColor ?? AppColors.primary;
    final ranking = match.departmentRanking;
    final quota = dept.scoreData?.quota ?? dept.quota;
    final placed = dept.scoreData?.placedCount;
    final scoreType = dept.effectiveScoreType;
    final desc = dept.description?.trim() ?? '';
    final isScholarship = desc.contains('Burslu');
    // "(Burslu)" çip olarak gösterildiğinden metinden çıkar.
    final descText = desc.replaceAll('(Burslu)', '').trim();
    // Trend/boş kontenjan artık gerekçe satırında — çift gösterim yok.
    final profile = ref.watch(studentScoreProfileProvider);
    final reasons =
        profile == null ? const <MatchReason>[] : buildMatchReasons(match, profile);
    final categoryColor = _categoryColor(match.category);
    // Referans sıra eski yıldansa mini-stat etiketi yılı söyler.
    final staleYear = match.refRankYear != null &&
            dept.scoreData != null &&
            match.refRankYear! < dept.scoreData!.year
        ? match.refRankYear
        : null;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.borderLightFor(context),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariantFor(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  uni.logoAssetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.account_balance_rounded,
                    color: brand,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dept.name,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      uni.name,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondaryFor(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isScholarship || descText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (isScholarship)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.warning.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      AppColors.warning.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                'Burslu',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          if (descText.isNotEmpty)
                            Flexible(
                              child: Text(
                                descText,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textTertiaryFor(context),
                                  fontSize: 10.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (scoreType != null) ScoreBadge.scoreType(scoreType),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Uygunluk çipi — grup başlığı zaten kategoriyi verdiğinden gate yok.
              FeasibilityChip.forDepartment(dept, enforceGate: false, compact: true),
              if (match.fitScore != null) ...[
                const SizedBox(width: 6),
                _FitMeter(fit: match.fitScore!, color: categoryColor),
              ],
              const Spacer(),
              FeasibilityMiniStat(
                icon: Icons.trending_up_rounded,
                label: 'Taban',
                value: match.departmentBaseScore.toStringAsFixed(1),
                color: AppColors.primary,
              ),
              if (ranking != null && ranking > 0) ...[
                const SizedBox(width: 10),
                FeasibilityMiniStat(
                  icon: Icons.emoji_events_rounded,
                  label: staleYear != null ? '$staleYear sırası' : 'Sıra',
                  value: _formatRank(ranking),
                  color: staleYear != null
                      ? AppColors.textTertiaryFor(context)
                      : AppColors.warning,
                ),
              ],
              if (quota != null && quota > 0) ...[
                const SizedBox(width: 10),
                FeasibilityMiniStat(
                  icon: Icons.people_alt_rounded,
                  label: 'Kont.',
                  value: placed != null ? '$placed/$quota' : '$quota',
                  color: AppColors.info,
                ),
              ],
            ],
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ReasonLine(reasons: reasons, color: categoryColor),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/department/${dept.id}'),
                  icon: const Icon(Icons.info_outline_rounded, size: 16),
                  label: const Text('Detay'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondaryFor(context),
                    side: BorderSide(color: AppColors.borderLightFor(context)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () =>
                      showAddToListSheet(context, ref, uni, dept),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Listeye ekle'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (match.category == MatchCategory.dream)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _showSimilar(context, ref),
                icon: const Icon(Icons.alt_route_rounded, size: 15),
                label: const Text('Benzer ama ulaşılabilir programlar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: AppTextStyles.labelSmall
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }

  /// Alternatifler dokunuşta hesaplanır — her kart build'inde tüm eşleşme
  /// listesini taramamak için.
  void _showSimilar(BuildContext context, WidgetRef ref) {
    final result = ref.read(preferenceMatchResultProvider).valueOrNull;
    final picks =
        result == null ? const <UniversityMatch>[] : similarReachable(match, result);
    if (picks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu programa yakın ulaşılabilir alternatif bulunamadı'),
        ),
      );
      return;
    }
    showSimilarProgramsSheet(context, match, picks);
  }

  static String _formatRank(int rank) {
    if (rank >= 1000000) return '${(rank / 1000000).toStringAsFixed(1)}M';
    if (rank >= 1000) return '${(rank / 1000).toStringAsFixed(0)}B';
    return '$rank';
  }

  static Color _categoryColor(MatchCategory category) {
    switch (category) {
      case MatchCategory.guaranteed:
        return AppColors.success;
      case MatchCategory.target:
        return AppColors.warning;
      case MatchCategory.dream:
        return AppColors.error;
    }
  }
}

/// Kompakt uygunluk göstergesi: mini halka + "%73 uyum".
class _FitMeter extends StatelessWidget {
  final int fit;
  final Color color;
  const _FitMeter({required this.fit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Uygunluk skoru — sıralama marjı, taban trendi ve doluluk '
          'sinyallerinden hesaplanır',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              value: fit / 100,
              strokeWidth: 2.5,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '%$fit uyum',
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tek satırlık "neden bu öneri" gerekçesi: ana cümle + kısa etiketler.
class _ReasonLine extends StatelessWidget {
  final List<MatchReason> reasons;
  final Color color;
  const _ReasonLine({required this.reasons, required this.color});

  @override
  Widget build(BuildContext context) {
    // Kartta dürtme etiketi gösterilmez — başlıktaki banner zaten söylüyor.
    final visible = reasons
        .where((r) => r.kind != MatchReasonKind.estimatedNudge)
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    final text = visible.map((r) => r.text).join(' · ');

    return Tooltip(
      message: text,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.5),
            child: Icon(Icons.auto_awesome_rounded, size: 12, color: color),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondaryFor(context),
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeasibilityMiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const FeasibilityMiniStat({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              value,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryFor(context),
              ),
            ),
          ],
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiaryFor(context),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
