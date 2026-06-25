import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/university_abbreviations.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/department_comparison.dart';

/// Kazanan bölümü gösteren büyük, gösterişli sonuç kartı.
class DepartmentWinnerCard extends StatelessWidget {
  final DepartmentComparisonResult result;
  final String uniNameA;
  final String uniNameB;

  const DepartmentWinnerCard({
    super.key,
    required this.result,
    required this.uniNameA,
    required this.uniNameB,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    final winner = result.winnerId;
    final isDraw = winner == null;
    final isAWinner = winner == result.deptA.id;

    final winnerDept = isAWinner ? result.deptA : result.deptB;
    final winnerUniName = isAWinner ? uniNameA : uniNameB;
    final winnerColor = isAWinner ? AppColors.primary : AppColors.secondary;

    // Kısa etiketler
    final shortA = UniversityAbbreviations.shorten(uniNameA);
    final shortB = UniversityAbbreviations.shorten(uniNameB);

    // Metrik hesaplama
    final metrics = _calculateMetrics(result);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDraw
              ? [
                  (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.06,
                  ),
                  (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.03,
                  ),
                ]
              : [
                  winnerColor.withValues(alpha: isDark ? 0.16 : 0.10),
                  winnerColor.withValues(alpha: isDark ? 0.06 : 0.03),
                ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDraw
              ? (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10)
              : winnerColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: isDraw
            ? null
            : [
                BoxShadow(
                  color: winnerColor.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        children: [
          // Üst: Sonuç ikonu + başlık
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: isDraw
                      ? null
                      : LinearGradient(
                          colors: [
                            winnerColor.withValues(alpha: 0.20),
                            winnerColor.withValues(alpha: 0.08),
                          ],
                        ),
                  color: isDraw
                      ? (isDark ? Colors.white : Colors.black).withValues(
                          alpha: 0.08,
                        )
                      : null,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDraw ? Icons.balance_rounded : Icons.emoji_events_rounded,
                  color: isDraw ? AppColors.textTertiary : winnerColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isDraw ? '${loc.tie}!' : loc.winner,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isDraw
                      ? (isDark
                            ? Colors.white70
                            : AppColors.textSecondaryFor(context))
                      : winnerColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Kazanan bölüm bilgisi
          if (!isDraw) ...[
            Text(
              winnerDept.name,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: isDark
                    ? Colors.white
                    : AppColors.textPrimaryFor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              winnerUniName,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: winnerColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Metrik skorları
          Row(
            children: [
              _MetricBadge(
                icon: Icons.school_rounded,
                label: loc.baseScore,
                winner: metrics['baseScore']!,
                labelA: shortA,
                labelB: shortB,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _MetricBadge(
                icon: Icons.format_list_numbered_rounded,
                label: loc.ranking,
                winner: metrics['ranking']!,
                labelA: shortA,
                labelB: shortB,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _MetricBadge(
                icon: Icons.people_rounded,
                label: loc.quota,
                winner: metrics['quota']!,
                labelA: shortA,
                labelB: shortB,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _MetricBadge(
                icon: Icons.check_circle_rounded,
                label: loc.fillRate,
                winner: metrics['fillRate']!,
                labelA: shortA,
                labelB: shortB,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 0 = berabere, 1 = A kazandı, -1 = B kazandı
  Map<String, int> _calculateMetrics(DepartmentComparisonResult r) {
    final baseA = r.deptA.effectiveBaseScore;
    final baseB = r.deptB.effectiveBaseScore;
    final rankA = r.deptA.effectiveRanking.toDouble();
    final rankB = r.deptB.effectiveRanking.toDouble();
    final quotaA = (r.deptA.quota ?? r.deptA.scoreData?.quota ?? 0).toDouble();
    final quotaB = (r.deptB.quota ?? r.deptB.scoreData?.quota ?? 0).toDouble();
    final fillA = r.deptA.scoreData?.fillRate ?? 0;
    final fillB = r.deptB.scoreData?.fillRate ?? 0;

    int compare(double a, double b, {bool higherIsBetter = true}) {
      if ((a - b).abs() < 0.001) return 0;
      if (higherIsBetter) return a > b ? 1 : -1;
      return a < b ? 1 : -1;
    }

    return {
      'baseScore': compare(baseA, baseB),
      'ranking': (rankA == 0 || rankB == 0)
          ? 0
          : compare(rankA, rankB, higherIsBetter: false),
      'quota': compare(quotaA, quotaB),
      'fillRate': compare(fillA, fillB),
    };
  }
}

class _MetricBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final int winner; // -1, 0, 1
  final String labelA;
  final String labelB;
  final bool isDark;

  const _MetricBadge({
    required this.icon,
    required this.label,
    required this.winner,
    required this.labelA,
    required this.labelB,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData badge;
    if (winner == 1) {
      color = AppColors.primary;
      badge = Icons.arrow_upward_rounded;
    } else if (winner == -1) {
      color = AppColors.secondary;
      badge = Icons.arrow_upward_rounded;
    } else {
      color = AppColors.textTertiary;
      badge = Icons.remove_rounded;
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 9,
                color: isDark
                    ? Colors.white54
                    : AppColors.textTertiaryFor(context),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: winner == 0
                    ? Icon(badge, size: 12, color: color)
                    : Text(
                        winner == 1 ? labelA : labelB,
                        maxLines: 1,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                          color: color,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
