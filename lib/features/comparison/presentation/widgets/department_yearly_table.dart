import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../university/domain/models/department_model.dart';

/// İki bölümün yıl bazlı puanlarını tablo halinde gösteren kart.
class DepartmentYearlyTable extends StatelessWidget {
  final DepartmentModel deptA;
  final DepartmentModel deptB;
  final String labelA;
  final String labelB;

  const DepartmentYearlyTable({
    super.key,
    required this.deptA,
    required this.deptB,
    required this.labelA,
    required this.labelB,
  });

  Map<int, double> _getScores(DepartmentModel dept) {
    final scores = <int, double>{};
    final sd = dept.scoreData;
    if (sd != null) {
      for (final entry in sd.previousYears.entries) {
        if (entry.value.baseScore > 0) {
          scores[entry.key] = entry.value.baseScore;
        }
      }
      if (sd.baseScore > 0) {
        scores[sd.year] = sd.baseScore;
      }
    }
    if (scores.isEmpty && (dept.baseScore ?? 0) > 0) {
      scores[2025] = dept.baseScore!;
    }
    return scores;
  }

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
    return rankings;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scoresA = _getScores(deptA);
    final scoresB = _getScores(deptB);
    final rankingsA = _getRankings(deptA);
    final rankingsB = _getRankings(deptB);

    final allYears = <int>{...scoresA.keys, ...scoresB.keys}.toList()..sort();

    if (allYears.isEmpty) return const SizedBox.shrink();

    return Container(
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
                child: const Icon(
                  Icons.table_chart_rounded,
                  size: 16,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Yıl Bazlı Karşılaştırma',
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

          // Tablo Header
          _buildHeaderRow(context, isDark),
          const SizedBox(height: 4),

          // Yıl satırları
          ...allYears.map((year) {
            final valA = scoresA[year];
            final valB = scoresB[year];
            final rankA = rankingsA[year];
            final rankB = rankingsB[year];
            return _buildYearRow(
              context,
              isDark,
              year: year,
              scoreA: valA,
              scoreB: valB,
              rankA: rankA,
              rankB: rankB,
              isLast: year == allYears.last,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context, bool isDark) {
    final headerStyle = AppTextStyles.labelSmall.copyWith(
      fontWeight: FontWeight.w900,
      color: isDark ? Colors.white54 : AppColors.textTertiaryFor(context),
      fontSize: 10,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 44, child: Text('Yıl', style: headerStyle)),
          Expanded(
            child: Text(
              labelA,
              textAlign: TextAlign.center,
              style: headerStyle.copyWith(color: AppColors.primary),
            ),
          ),
          Expanded(
            child: Text(
              labelB,
              textAlign: TextAlign.center,
              style: headerStyle.copyWith(color: AppColors.secondary),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              'Fark',
              textAlign: TextAlign.center,
              style: headerStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearRow(
    BuildContext context,
    bool isDark, {
    required int year,
    double? scoreA,
    double? scoreB,
    int? rankA,
    int? rankB,
    required bool isLast,
  }) {
    final delta = (scoreA != null && scoreB != null) ? scoreA - scoreB : null;
    final isPositive = delta != null && delta > 0;
    final isNegative = delta != null && delta < 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.06,
                  ),
                ),
              ),
      ),
      child: Row(
        children: [
          // Yıl
          SizedBox(
            width: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : AppColors.primary).withValues(
                  alpha: 0.08,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$year',
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          ),
          // A puanı
          Expanded(
            child: Column(
              children: [
                Text(
                  scoreA?.toStringAsFixed(2) ?? '-',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
                if (rankA != null)
                  Text(
                    '${_formatRank(rankA)}. sıra',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark
                          ? Colors.white38
                          : AppColors.textTertiaryFor(context),
                      fontSize: 9,
                    ),
                  ),
                if (year == 2025 && rankA == null)
                  Text(
                    'Sıra: Açıklanmadı',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark
                          ? Colors.white38
                          : AppColors.textTertiaryFor(context),
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          // B puanı
          Expanded(
            child: Column(
              children: [
                Text(
                  scoreB?.toStringAsFixed(2) ?? '-',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: AppColors.secondary,
                  ),
                ),
                if (rankB != null)
                  Text(
                    '${_formatRank(rankB)}. sıra',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark
                          ? Colors.white38
                          : AppColors.textTertiaryFor(context),
                      fontSize: 9,
                    ),
                  ),
                if (year == 2025 && rankB == null)
                  Text(
                    'Sıra: Açıklanmadı',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark
                          ? Colors.white38
                          : AppColors.textTertiaryFor(context),
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          // Fark
          SizedBox(
            width: 56,
            child: delta != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (isPositive
                                  ? AppColors.success
                                  : isNegative
                                  ? AppColors.error
                                  : AppColors.textTertiary)
                              .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      delta.abs() < 0.01
                          ? '±0'
                          : '${isPositive ? "+" : ""}${delta.toStringAsFixed(1)}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                        color: isPositive
                            ? AppColors.success
                            : isNegative
                            ? AppColors.error
                            : AppColors.textTertiary,
                      ),
                    ),
                  )
                : const Text('-', textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  static String _formatRank(int rank) {
    if (rank >= 1000000) return '${(rank / 1000000).toStringAsFixed(1)}M';
    if (rank >= 1000) return '${(rank / 1000).toStringAsFixed(0)}B';
    return '$rank';
  }
}
