import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

/// Tekli shimmer kutusu — skeleton yükleme efekti
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: baseColor ??
          (isDark ? AppColors.darkOverlay10 : AppColors.shimmerBase),
      highlightColor: highlightColor ??
          (isDark ? AppColors.darkOverlay22 : AppColors.shimmerHighlight),
      period: const Duration(milliseconds: 1400),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Çoklu shimmer satırlardan oluşan bir blok
class ShimmerLines extends StatelessWidget {
  final int lines;
  final double lineHeight;
  final double spacing;
  final List<double>? widthPercentages;

  const ShimmerLines({
    super.key,
    this.lines = 3,
    this.lineHeight = 14,
    this.spacing = 8,
    this.widthPercentages,
  });

  @override
  Widget build(BuildContext context) {
    final widths = widthPercentages ?? List.filled(lines, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i == lines - 1 ? 0 : spacing),
          child: FractionallySizedBox(
            widthFactor: widths[i < widths.length ? i : widths.length - 1],
            child: ShimmerBox(height: lineHeight, borderRadius: lineHeight / 2),
          ),
        );
      }),
    );
  }
}
