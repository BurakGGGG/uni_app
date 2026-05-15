import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

/// Standart liste yükleme skeleton'ı.
/// `CircularProgressIndicator` yerine bunu kullan.
///
/// Kullanım:
/// ```dart
/// asyncValue.when(
///   data: ...,
///   loading: () => const ListSkeleton(itemCount: 6),
///   error: ...,
/// )
/// ```
class ListSkeleton extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsets padding;
  final double itemSpacing;

  const ListSkeleton({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 84,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 12),
    this.itemSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = AppColors.shimmerBaseFor(context);
    final highlightColor = AppColors.shimmerHighlightFor(context);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.separated(
        shrinkWrap: true,
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => SizedBox(height: itemSpacing),
        itemBuilder: (_, _) => Container(
          height: itemHeight,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

/// Tek bir kart placeholder'ı.
class CardSkeleton extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const CardSkeleton({
    super.key,
    this.height = 120,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBaseFor(context),
      highlightColor: AppColors.shimmerHighlightFor(context),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: AppColors.shimmerBaseFor(context),
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
