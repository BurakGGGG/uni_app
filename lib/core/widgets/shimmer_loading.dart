import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../constants/app_constants.dart';

/// Shimmer loading efekti — veri yüklenirken kullanılır
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = AppConstants.radiusMd,
  });

  @override
  Widget build(BuildContext context) {
    final base = AppColors.shimmerBaseFor(context);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: AppColors.shimmerHighlightFor(context),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Kart şeklinde shimmer loading
class ShimmerCard extends StatelessWidget {
  final EdgeInsets? margin;

  const ShimmerCard({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    final base = AppColors.shimmerBaseFor(context);
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: AppColors.shimmerHighlightFor(context),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            // İçerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Liste loading — birden fazla ShimmerCard gösterir
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final EdgeInsets? margin;

  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (context, index) => ShimmerCard(margin: margin),
    );
  }
}
