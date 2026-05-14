import 'package:flutter/material.dart';
import '../../../../core/widgets/shimmer_box.dart';

/// Karşılaştırma sonucu yüklenirken gösterilecek skeleton
class ComparisonResultSkeleton extends StatelessWidget {
  const ComparisonResultSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero section skeleton
          Row(
            children: [
              const Expanded(child: ShimmerBox(height: 120, borderRadius: 16)),
              const SizedBox(width: 12),
              const ShimmerBox(width: 48, height: 48, borderRadius: 24),
              const SizedBox(width: 12),
              const Expanded(child: ShimmerBox(height: 120, borderRadius: 16)),
            ],
          ),
          const SizedBox(height: 16),

          // AI summary skeleton
          const ShimmerBox(height: 140, borderRadius: 18),
          const SizedBox(height: 16),

          // Stats row skeleton
          Row(
            children: List.generate(
              3,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  child: const ShimmerBox(height: 80, borderRadius: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Categories skeleton
          ...List.generate(
            5,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerBox(height: 56, borderRadius: 12),
            ),
          ),
        ],
      ),
    );
  }
}
