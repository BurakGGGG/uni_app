import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';

/// Üniversite detay sayfası için tam sayfa shimmer skeleton.
/// Ana body yüklenirken gösterilir.
class UniversityDetailSkeleton extends StatelessWidget {
  const UniversityDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = AppColors.shimmerBaseFor(context);
    final highlightColor = AppColors.shimmerHighlightFor(context);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero banner skeleton
            Container(
              height: 280,
              width: double.infinity,
              color: baseColor,
            ),

            // Info strip skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  4,
                  (_) => Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: baseColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 48,
                        height: 10,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action buttons skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 48,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Section title skeleton (Bölümler)
            _SectionTitleSkeleton(baseColor: baseColor),

            // Department list items skeleton
            ...List.generate(
              3,
              (_) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Section title skeleton (Yorumlar)
            _SectionTitleSkeleton(baseColor: baseColor),

            // Review cards skeleton
            ...List.generate(
              2,
              (_) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  height: 130,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

/// Bölümler preview section için shimmer skeleton.
class DepartmentsSkeleton extends StatelessWidget {
  final int itemCount;
  const DepartmentsSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    final baseColor = AppColors.shimmerBaseFor(context);
    final highlightColor = AppColors.shimmerHighlightFor(context);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: List.generate(
          itemCount,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 52,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

/// Yorum preview section için shimmer skeleton.
class ReviewsSkeleton extends StatelessWidget {
  final int itemCount;
  const ReviewsSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    final baseColor = AppColors.shimmerBaseFor(context);
    final highlightColor = AppColors.shimmerHighlightFor(context);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: List.generate(
          itemCount,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 130,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mekan section için shimmer skeleton.
class PlacesSkeleton extends StatelessWidget {
  final int itemCount;
  const PlacesSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    final baseColor = AppColors.shimmerBaseFor(context);
    final highlightColor = AppColors.shimmerHighlightFor(context);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: List.generate(
          itemCount,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 72,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Yardımcı ─────────────────────────────────────────────────────
class _SectionTitleSkeleton extends StatelessWidget {
  final Color baseColor;
  const _SectionTitleSkeleton({required this.baseColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            height: 16,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 200,
            height: 10,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
