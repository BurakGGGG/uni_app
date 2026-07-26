import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../domain/compare_view.dart';
import 'compare_row_tile.dart';

/// Ölçüt kümesi — "Sayılarla", "Öğrenci puanları".
///
/// Grup boşsa kart yine çizilir ama satır yerine bir açıklama gösterir:
/// yorum verisi olmayan üniversitelerde bölümün sessizce yok olması,
/// kullanıcıya "böyle bir ölçüt yok" izlenimi veriyordu.
class CompareGroupCard extends StatelessWidget {
  final CompareGroup group;

  const CompareGroupCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final rows = group.present;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.title.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiaryFor(context),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                group.emptyNote ?? '',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryFor(context),
                  height: 1.35,
                ),
              ),
            )
          else
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  color: AppColors.borderLightFor(context).withValues(alpha: 0.6),
                ),
              CompareRowTile(
                row: rows[i],
                delay: Duration(milliseconds: i * 40),
              ),
            ],
        ],
      ),
    );
  }
}
