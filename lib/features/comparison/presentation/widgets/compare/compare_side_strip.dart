import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/compare_view.dart';
import '../university_logo_box.dart';
import 'compare_theme.dart';

/// Sonucun tepesindeki kompakt taraf şeridi.
///
/// **Sonuç gelince kaybolmuyor** (kullanıcı kararı): eskiden seçici tamamen
/// gidiyordu ve "ya şununla karşılaştırsam" demek için Sıfırla'ya basmak
/// gerekiyordu. Karşılaştırma doğası gereği denemeli bir iş — taraflar
/// hep dokunulabilir kalıyor.
class CompareSideStrip extends StatelessWidget {
  final List<CompareSide> sides;

  /// Bir tarafa dokunulunca — indeksle çağrılır.
  final ValueChanged<int>? onChange;

  /// İki taraflıda ortadaki yer değiştirme düğmesi.
  final VoidCallback? onSwap;

  /// Tarafın görseli. Verilmezse üniversite logosu kutusuna düşer —
  /// şehir karşılaştırmasında plaka rozeti geçiliyor.
  final Widget Function(int index, CompareSide side)? leadingBuilder;

  const CompareSideStrip({
    super.key,
    required this.sides,
    this.onChange,
    this.onSwap,
    this.leadingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < sides.length; i++) ...[
            if (i > 0)
              if (sides.length == 2 && onSwap != null)
                IconButton(
                  onPressed: onSwap,
                  tooltip: loc.cmpSwap,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.swap_horiz_rounded,
                    size: 20,
                    color: AppColors.textTertiaryFor(context),
                  ),
                )
              else
                const SizedBox(width: 4),
            Expanded(
              child: _SideTile(
                side: sides[i],
                color: compareSideColor(i),
                leading: leadingBuilder?.call(i, sides[i]),
                onTap: onChange == null ? null : () => onChange!(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SideTile extends StatelessWidget {
  final CompareSide side;
  final Color color;
  final Widget? leading;
  final VoidCallback? onTap;

  const _SideTile({
    required this.side,
    required this.color,
    this.leading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              leading ??
                  UniversityLogoBox(
                    universityId: side.id,
                    universityName: side.title,
                    accentColor: color,
                    size: 44,
                  ),
              const SizedBox(height: 8),
              Text(
                side.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.2,
                ),
              ),
              if (side.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  side.subtitle!,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiaryFor(context),
                  ),
                ),
              ],
              if (onTap != null) ...[
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).cmpChangeSide,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiaryFor(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
