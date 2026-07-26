import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../domain/compare_view.dart';
import 'compare_row_tile.dart';

/// Ölçüt kümesi — "Sayılarla", "Öğrenci puanları".
///
/// **Varsayılan olarak KAPALI** (kullanıcı geri bildirimi: "sürekli aşağı
/// akan ekran"): açılışta yalnız farkı büyük ölçütler görünüyor, tam tablo
/// bir dokunuş uzakta. Kapalıyken bile satır sayısı yazıyor — arkasında ne
/// olduğu belirsiz kalmasın.
///
/// Grup boşsa kart yine çizilir ama satır yerine açıklama gösterir: yorum
/// verisi olmayan üniversitelerde bölümün sessizce yok olması, kullanıcıya
/// "böyle bir ölçüt yok" izlenimi veriyordu.
class CompareGroupCard extends StatefulWidget {
  final CompareGroup group;
  final bool initiallyExpanded;

  const CompareGroupCard({
    super.key,
    required this.group,
    this.initiallyExpanded = false,
  });

  @override
  State<CompareGroupCard> createState() => _CompareGroupCardState();
}

class _CompareGroupCardState extends State<CompareGroupCard> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final rows = widget.group.present;
    final empty = rows.isEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            // Boş grupta açacak bir şey yok; başlık düğme gibi davranmasın.
            onTap: empty ? null : () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.group.title.toUpperCase(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiaryFor(context),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  if (!empty) ...[
                    Text(
                      '${rows.length}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiaryFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 20,
                        color: AppColors.textTertiaryFor(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (empty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Text(
                widget.group.emptyNote ?? '',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryFor(context),
                  height: 1.35,
                ),
              ),
            )
          else
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _open
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < rows.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                color: AppColors.borderLightFor(context)
                                    .withValues(alpha: 0.6),
                              ),
                            CompareRowTile(row: rows[i]),
                          ],
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
        ],
      ),
    );
  }
}
