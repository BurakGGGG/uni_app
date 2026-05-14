import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class PlaceDetailSkeleton extends StatelessWidget {
  const PlaceDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBaseFor(context),
      highlightColor: AppColors.shimmerHighlightFor(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.shimmerBaseFor(context),
                borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 80, height: 24,
              decoration: BoxDecoration(
                color: AppColors.shimmerBaseFor(context),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Container(width: double.infinity, height: 28, color: AppColors.shimmerBaseFor(context)),
            const SizedBox(height: 8),
            Container(width: 200, height: 16, color: AppColors.shimmerBaseFor(context)),
            const SizedBox(height: 24),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.shimmerBaseFor(context),
                borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.shimmerBaseFor(context),
                borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
