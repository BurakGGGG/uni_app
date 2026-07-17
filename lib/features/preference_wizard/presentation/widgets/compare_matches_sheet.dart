import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../score_calculator/domain/models/match_result.dart';
import '../../domain/match_reason.dart';

/// Seçili 2-3 programı yan yana karşılaştıran bottom sheet.
/// Kartlara uzun basarak seçilir; tüm veriler bellekteki eşleşmelerden gelir.
Future<void> showCompareMatchesSheet(
  BuildContext context,
  List<UniversityMatch> picks,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceFor(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _CompareBody(picks: picks),
  );
}

class _CompareBody extends StatelessWidget {
  final List<UniversityMatch> picks;
  const _CompareBody({required this.picks});

  static const _categoryLabels = {
    MatchCategory.guaranteed: 'Yüksek şans',
    MatchCategory.target: 'Ulaşılabilir',
    MatchCategory.dream: 'Zorlayıcı',
  };

  static const _categoryColors = {
    MatchCategory.guaranteed: AppColors.success,
    MatchCategory.target: AppColors.warning,
    MatchCategory.dream: AppColors.error,
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 4, bottom: 14),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLightFor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Karşılaştır',
              style:
                  AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Table(
                  columnWidths: {
                    0: const FixedColumnWidth(86),
                    for (var i = 0; i < picks.length; i++)
                      i + 1: const FlexColumnWidth(),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      children: [
                        const SizedBox.shrink(),
                        for (final m in picks)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.department.name,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  m.university.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color:
                                        AppColors.textSecondaryFor(context),
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    _row(
                      context,
                      'Durum',
                      [
                        for (final m in picks)
                          _cell(
                            _categoryLabels[m.category]!,
                            color: _categoryColors[m.category],
                            bold: true,
                          ),
                      ],
                    ),
                    _row(
                      context,
                      'Uyum',
                      [
                        for (final m in picks)
                          _cell(
                            m.fitScore != null ? '%${m.fitScore}' : '—',
                            color: _categoryColors[m.category],
                            bold: true,
                          ),
                      ],
                    ),
                    _row(
                      context,
                      'Taban',
                      [
                        for (final m in picks)
                          _cell(m.departmentBaseScore.toStringAsFixed(1)),
                      ],
                    ),
                    _row(
                      context,
                      'Taban sıra',
                      [
                        for (final m in picks)
                          _cell(
                            (m.departmentRanking ?? 0) > 0
                                ? formatRankTr(m.departmentRanking!)
                                : '—',
                          ),
                      ],
                    ),
                    _row(
                      context,
                      'Kontenjan',
                      [
                        for (final m in picks)
                          _cell(_quotaText(m)),
                      ],
                    ),
                    _row(
                      context,
                      'Üniversite',
                      [
                        for (final m in picks) _cell(m.university.type),
                      ],
                    ),
                    _row(
                      context,
                      'Dil',
                      [
                        for (final m in picks) _cell(m.department.language),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _quotaText(UniversityMatch m) {
    final sd = m.department.scoreData;
    if (sd == null || sd.quota <= 0) return '—';
    return '${sd.placedCount}/${sd.quota}';
  }

  TableRow _row(BuildContext context, String label, List<Widget> cells) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderLightFor(context)),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiaryFor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...cells,
      ],
    );
  }

  Widget _cell(String text, {Color? color, bool bold = false}) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Text(
          text,
          style: AppTextStyles.labelMedium.copyWith(
            color: color ?? AppColors.textPrimaryFor(context),
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
