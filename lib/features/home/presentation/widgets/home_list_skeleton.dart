import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

/// Home ekranındaki üniversite kartı yükleme skeleton'ı.
class HomeListSkeleton extends StatelessWidget {
  final int itemCount;
  final double height;
  final Axis scrollDirection;

  const HomeListSkeleton({
    super.key,
    this.itemCount = 4,
    this.height = 200,
    this.scrollDirection = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Shimmer.fromColors(
        baseColor: AppColors.shimmerBaseFor(context),
        highlightColor: AppColors.shimmerHighlightFor(context),
        child: ListView.separated(
          scrollDirection: scrollDirection,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: itemCount,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, _) {
            return Container(
              width: Responsive.cardWidth(context),
              decoration: BoxDecoration(
                color: AppColors.shimmerBaseFor(context),
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
        ),
      ),
    );
  }
}
