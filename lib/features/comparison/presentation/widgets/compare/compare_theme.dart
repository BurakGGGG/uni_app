import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Karşılaştırmanın taraf renkleri.
///
/// Marka renkleri KULLANILMIYOR: iki kırmızı logolu üniversite yan yana
/// gelince hangi çubuğun kimin olduğu okunmuyor. Slot rengi sabit —
/// sol her zaman mor, sağ her zaman turkuaz, üçüncü altın.
const List<Color> kCompareSideColors = [
  AppColors.primary,
  AppColors.secondary,
  AppColors.tierPro,
];

Color compareSideColor(int index) =>
    kCompareSideColors[index % kCompareSideColors.length];
