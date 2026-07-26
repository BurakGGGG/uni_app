import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/compare_view.dart';
import 'compare_row_tile.dart';

/// Açılışta görünen tek ölçüt bloğu: farkın en büyük olduğu satırlar.
///
/// Kullanıcı geri bildirimi: *"sürekli aşağı akan ekranı bilemedim."*
/// 13–18 ölçüt satırının çoğunda iki taraf zaten yakındı; ekranın büyük
/// kısmı "fark yok" demek için harcanıyordu. Karşılaştırmanın cevabı
/// farkta — o yüzden varsayılan görünüm bu, tam tablolar altta kapalı
/// duruyor.
class CompareHighlightsCard extends StatelessWidget {
  final List<CompareRow> rows;

  const CompareHighlightsCard({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLightFor(context)),
        boxShadow: AppColors.softShadowFor(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).cmpHighlightsTitle.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: AppColors.borderLightFor(context).withValues(alpha: 0.6),
              ),
            CompareRowTile(
              row: rows[i],
              delay: Duration(milliseconds: i * 50),
            ),
          ],
        ],
      ),
    );
  }
}
