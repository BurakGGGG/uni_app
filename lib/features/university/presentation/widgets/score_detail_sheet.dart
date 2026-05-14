import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/department_model.dart';
import 'score_badge.dart';
import 'score_trend_chart.dart';

/// Taban puan kartına tıklandığında açılan detaylı puan bottom sheet.
void showScoreDetailSheet(BuildContext context, DepartmentScoreData scoreData, String deptName) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ScoreDetailSheet(scoreData: scoreData, deptName: deptName),
  );
}

class _ScoreDetailSheet extends StatelessWidget {
  final DepartmentScoreData scoreData;
  final String deptName;

  const _ScoreDetailSheet({required this.scoreData, required this.deptName});

  @override
  Widget build(BuildContext context) {
    final years = scoreData.allYearsAscending;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Scrollable content
              Expanded(
                child: Builder(
                  builder: (context) {
                    final children = [
                      // ── Başlık ──
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  deptName,
                                  style: AppTextStyles.headlineMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Taban Puan Detayları',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ScoreBadge.scoreType(scoreData.scoreType),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Ana Puan Kartı ──
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.85),
                              AppColors.secondary.withValues(alpha: 0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppConstants.radiusXl),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${scoreData.year} Yılı',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              scoreData.baseScore.toStringAsFixed(2),
                              style: AppTextStyles.headlineLarge.copyWith(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (scoreData.yearOverYearDelta != null) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    scoreData.yearOverYearDelta! > 0
                                        ? Icons.arrow_upward_rounded
                                        : Icons.arrow_downward_rounded,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${scoreData.yearOverYearDelta! > 0 ? "+" : ""}${scoreData.yearOverYearDelta!.toStringAsFixed(2)} puan (önceki yıla göre)',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            // Üçlü stat satırı
                            Row(
                              children: [
                                _StatPill(
                                  icon: Icons.emoji_events_rounded,
                                  label: 'Sıralama',
                                  value: _formatRank(scoreData.ranking),
                                ),
                                const SizedBox(width: 8),
                                _StatPill(
                                  icon: Icons.people_rounded,
                                  label: 'Kontenjan',
                                  value: scoreData.quota.toString(),
                                ),
                                const SizedBox(width: 8),
                                _StatPill(
                                  icon: Icons.check_circle_rounded,
                                  label: 'Yerleşen',
                                  value: scoreData.placedCount.toString(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Trend Grafiği ──
                      ScoreTrendChart(scoreData: scoreData),

                      const SizedBox(height: 20),

                      // ── Yıl Yıl Karşılaştırma Tablosu ──
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Yıl Bazlı Karşılaştırma',
                                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                            // Tablo başlığı
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                              ),
                              child: Row(
                                children: [
                                  _tableHeader('Yıl', flex: 1),
                                  _tableHeader('Taban Puan', flex: 2),
                                  _tableHeader('Sıralama', flex: 2),
                                  _tableHeader('Değişim', flex: 2),
                                ],
                              ),
                            ),
                            // Tablo satırları
                            ...years.reversed.toList().asMap().entries.map((entry) {
                              final idx = entry.key;
                              final yearEntry = entry.value;
                              final year = yearEntry.key;
                              final data = yearEntry.value;
                              final isCurrentYear = year == scoreData.year;

                              // Bir önceki yıl ile delta
                              double? delta;
                              final prevYear = years.where((e) => e.key == year - 1).firstOrNull;
                              if (prevYear != null) {
                                delta = data.baseScore - prevYear.value.baseScore;
                              }

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isCurrentYear
                                      ? AppColors.primary.withValues(alpha: 0.04)
                                      : Colors.transparent,
                                  border: idx < years.length - 1
                                      ? Border(bottom: BorderSide(color: AppColors.borderLight))
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    // Yıl
                                    Expanded(
                                      flex: 1,
                                      child: Row(
                                        children: [
                                          Text(
                                            year.toString(),
                                            style: AppTextStyles.titleSmall.copyWith(
                                              fontWeight: isCurrentYear ? FontWeight.w700 : FontWeight.w500,
                                              color: isCurrentYear ? AppColors.primary : AppColors.textPrimary,
                                            ),
                                          ),
                                          if (isCurrentYear) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: AppColors.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    // Taban Puan
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        data.baseScore.toStringAsFixed(2),
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    // Sıralama
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        _formatRank(data.ranking),
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                    ),
                                    // Delta
                                    Expanded(
                                      flex: 2,
                                      child: delta != null
                                          ? Row(
                                              children: [
                                                Icon(
                                                  delta > 0
                                                      ? Icons.arrow_upward_rounded
                                                      : delta < 0
                                                          ? Icons.arrow_downward_rounded
                                                          : Icons.remove_rounded,
                                                  size: 14,
                                                  color: delta > 0
                                                      ? AppColors.success
                                                      : delta < 0
                                                          ? AppColors.error
                                                          : AppColors.textTertiary,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${delta > 0 ? "+" : ""}${delta.toStringAsFixed(2)}',
                                                  style: AppTextStyles.labelMedium.copyWith(
                                                    color: delta > 0
                                                        ? AppColors.success
                                                        : delta < 0
                                                            ? AppColors.error
                                                            : AppColors.textTertiary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              '—',
                                              style: AppTextStyles.bodyMedium.copyWith(
                                                color: AppColors.textTertiary,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Doluluk Bilgisi ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.pie_chart_rounded, size: 18, color: AppColors.success),
                                const SizedBox(width: 6),
                                Text(
                                  'Doluluk Oranı',
                                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const Spacer(),
                                Text(
                                  '${(scoreData.fillRate * 100).toStringAsFixed(0)}%',
                                  style: AppTextStyles.headlineMedium.copyWith(
                                    color: scoreData.fillRate >= 1 ? AppColors.success : AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: scoreData.fillRate.clamp(0, 1).toDouble(),
                                minHeight: 8,
                                backgroundColor: AppColors.borderLight,
                                valueColor: AlwaysStoppedAnimation(
                                  scoreData.fillRate >= 1 ? AppColors.success : AppColors.warning,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${scoreData.placedCount} / ${scoreData.quota} kişi yerleşti',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ];

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      itemCount: children.length,
                      itemBuilder: (context, index) => children[index],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tableHeader(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  String _formatRank(int rank) {
    if (rank >= 1000) {
      return '${(rank / 1000).toStringAsFixed(1)}B';
    }
    return rank.toString();
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.titleSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
