import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/compare_view.dart';
import '../university_logo_box.dart';
import 'compare_theme.dart';

/// Sonucun tepesinde YAPIŞIK duran taraf şeridi.
///
/// **Sonuç gelince kaybolmuyor** (kullanıcı kararı): eskiden seçici tamamen
/// gidiyordu ve "ya şununla karşılaştırsam" demek için Sıfırla'ya basmak
/// gerekiyordu. Karşılaştırma doğası gereği denemeli bir iş — taraflar
/// hep dokunulabilir kalıyor.
///
/// **Tek satır, üstte sabit** (kullanıcı kararı): logo-üstte-ad-altta hâli
/// ~110px yer kaplıyor ve kaydırınca kayboluyordu; aşağıdaki sayıların
/// hangisinin kime ait olduğu belirsizleşiyordu. Şimdi ~56px ve renk-isim
/// eşleşmesi hep gözönünde.
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

  /// Yapışık başlığın sabit yüksekliği — `SliverPersistentHeader` ölçüyü
  /// önden bilmek zorunda.
  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      color: AppColors.backgroundFor(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(18),
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
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: Icon(
                      Icons.swap_horiz_rounded,
                      size: 18,
                      color: AppColors.textTertiaryFor(context),
                    ),
                  )
                else
                  const SizedBox(width: 6),
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: [
              leading ??
                  UniversityLogoBox(
                    universityId: side.id,
                    universityName: side.title,
                    accentColor: color,
                    size: 32,
                  ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  side.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.15,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.expand_more_rounded,
                  size: 16,
                  color: AppColors.textTertiaryFor(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
