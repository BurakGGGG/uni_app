import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// ÜniSeç logotype/wordmark — marka adının tek görsel kaynağı.
///
/// Varsayılan olarak "Üni⇄eç" biçiminde render edilir: ortadaki swap glyph
/// (compare ikonu = logo) "S" harfinin yerine geçer. Bu, uygulamanın en
/// ayırt edici marka imzasıdır. Splash gibi büyük marka işaretinin ayrıca
/// gösterildiği yerlerde glyph'i tekrarlamamak için [AppWordmark.plain]
/// düz "ÜniSeç" metnini verir.
class AppWordmark extends StatelessWidget {
  const AppWordmark({
    super.key,
    this.fontSize = 28,
    this.color,
    this.fontWeight = FontWeight.w800,
  }) : _showGlyph = true;

  /// Swap glyph'i olmadan düz "ÜniSeç" metni.
  const AppWordmark.plain({
    super.key,
    this.fontSize = 28,
    this.color,
    this.fontWeight = FontWeight.w700,
  }) : _showGlyph = false;

  final double fontSize;
  final Color? color;
  final FontWeight fontWeight;
  final bool _showGlyph;

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? AppColors.primary;
    final style = GoogleFonts.spaceGrotesk(
      color: textColor,
      fontWeight: fontWeight,
      letterSpacing: -fontSize * 0.04,
      fontSize: fontSize,
    );

    if (!_showGlyph) {
      return Semantics(
        label: 'ÜniSeç',
        child: Text('ÜniSeç', style: style),
      );
    }

    final glyphSize = fontSize * 0.86;
    return Semantics(
      label: 'ÜniSeç',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Üni', style: style),
          SizedBox(width: fontSize * 0.1),
          SvgPicture.asset(
            'assets/icons/compare_icon.svg',
            width: glyphSize,
            height: glyphSize,
          ),
          SizedBox(width: fontSize * 0.07),
          Text('eç', style: style),
        ],
      ),
    );
  }
}
