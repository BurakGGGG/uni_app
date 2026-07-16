import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/badge_catalog.dart';

/// Tek rozet madalyonu — kazanılmışsa renkli SVG, kazanılmamışsa
/// soluk gri hali (tek asset'ten ColorFilter ile üretilir).
class BadgeMedallion extends StatelessWidget {
  final BadgeDefinition definition;
  final bool earned;
  final double size;

  const BadgeMedallion({
    super.key,
    required this.definition,
    required this.earned,
    this.size = 56,
  });

  /// Doygunluğu sıfırlayan luminance matrisi — figür konturları görünür
  /// kalır (srcIn kullanılamaz: tüm madalyon tek renk daireye dönerdi).
  static const ColorFilter _greyscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final svg = SvgPicture.asset(
      definition.assetPath,
      width: size,
      height: size,
      colorFilter: earned ? null : _greyscale,
    );

    if (earned) return svg;
    return Opacity(opacity: 0.45, child: svg);
  }
}
