import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../score_calculator/domain/models/match_result.dart';
import '../../../university/domain/models/department_model.dart';
import '../feasibility_view.dart';

/// "Senin puanınla" uygunluk rozeti — app genelinde tek-program kategorisi.
///
/// Öğrenci profili yoksa hiçbir şey göstermez. [enforceGate] true iken (app
/// geneli yerleşimler) Plus altı kullanıcıya kilitli davetkâr çip gösterir;
/// robot sonuç kartlarında kategori zaten grup başlığından belli olduğundan
/// `enforceGate: false` verilerek gerçek çip herkese gösterilir.
class FeasibilityChip extends ConsumerWidget {
  final String? scoreType;
  final double? baseScore;
  final int? ranking; // referans başarı sıralaması (>0 ise kullanılır)
  final bool enforceGate;
  final bool compact;

  const FeasibilityChip({
    super.key,
    required this.scoreType,
    required this.baseScore,
    required this.ranking,
    this.enforceGate = true,
    this.compact = false,
  });

  /// Bir [DepartmentModel]'den rozet (bölüm/üniversite detay ekranları için).
  factory FeasibilityChip.forDepartment(
    DepartmentModel dept, {
    Key? key,
    bool enforceGate = true,
    bool compact = false,
  }) {
    return FeasibilityChip(
      key: key,
      scoreType: dept.effectiveScoreType,
      baseScore: dept.effectiveBaseScore,
      ranking: dept.rankingForMatching,
      enforceGate: enforceGate,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = watchFeasibility(
      ref,
      scoreType: scoreType,
      baseScore: baseScore,
      ranking: ranking,
      enforceGate: enforceGate,
    );

    if (view is! FeasibilityVerdict) {
      // Profil yok / kıyaslanamaz → sessizlik; Plus yok → kilitli çip.
      return view is FeasibilityLocked
          ? _LockedChip(compact: compact)
          : const SizedBox.shrink();
    }
    final verdict = view;

    final style = _styleFor(verdict.category);
    final String tooltip;
    switch (verdict.basis) {
      case MatchBasis.rank:
        tooltip = 'Sıralaman ${verdict.studentRank} · taban sıralama '
            '~${verdict.referenceRank}';
        break;
      case MatchBasis.estimatedRank:
        tooltip = 'Tahmini sıralaman ~${verdict.studentRank} · taban '
            'sıralama ~${verdict.referenceRank}';
        break;
      case MatchBasis.score:
        tooltip = 'Puanın ${verdict.placementScore!.toStringAsFixed(1)} · '
            'taban ${verdict.baseScore!.toStringAsFixed(1)}';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 5,
        ),
        decoration: BoxDecoration(
          color: style.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: style.color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: compact ? 12 : 14, color: style.color),
            const SizedBox(width: 4),
            Text(
              style.label,
              style: (compact
                      ? AppTextStyles.labelSmall
                      : AppTextStyles.labelMedium)
                  .copyWith(color: style.color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  static _ChipStyle _styleFor(MatchCategory category) {
    switch (category) {
      case MatchCategory.guaranteed:
        return const _ChipStyle(
          label: 'Yüksek şans',
          color: AppColors.success,
          icon: Icons.thumb_up_alt_rounded,
        );
      case MatchCategory.target:
        return const _ChipStyle(
          label: 'Ulaşılabilir',
          color: AppColors.warning,
          icon: Icons.adjust_rounded,
        );
      case MatchCategory.dream:
        return const _ChipStyle(
          label: 'Zorlayıcı',
          color: AppColors.error,
          icon: Icons.bolt_rounded,
        );
    }
  }
}

class _ChipStyle {
  final String label;
  final Color color;
  final IconData icon;
  const _ChipStyle({
    required this.label,
    required this.color,
    required this.icon,
  });
}

class _LockedChip extends StatelessWidget {
  final bool compact;
  const _LockedChip({required this.compact});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/compare/paywall'),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 5,
        ),
        decoration: BoxDecoration(
          color: AppColors.tierPlus.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.tierPlus.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded,
                size: compact ? 12 : 14, color: AppColors.tierPlus),
            const SizedBox(width: 4),
            Text(
              'Uygunluk',
              style: (compact
                      ? AppTextStyles.labelSmall
                      : AppTextStyles.labelMedium)
                  .copyWith(
                      color: AppColors.tierPlus, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
