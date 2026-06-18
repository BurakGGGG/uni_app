import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class UniInfoStrip extends StatelessWidget {
  final int establishedYear;
  final int departmentCount;
  final int reviewCount;
  final double avgRating;

  const UniInfoStrip({
    super.key,
    required this.establishedYear,
    required this.departmentCount,
    required this.reviewCount,
    required this.avgRating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _kpi(context, '$establishedYear', 'Kuruluş'),
          _divider(context),
          _kpi(context, '$departmentCount', 'Bölüm'),
          _divider(context),
          _kpi(context, '$reviewCount', 'Yorum'),
          _divider(context),
          _kpi(
            context,
            avgRating > 0 ? avgRating.toStringAsFixed(1) : '–',
            'Puan',
            valueColor: avgRating > 0 ? AppColors.ratingStar : null,
          ),
        ],
      ),
    );
  }

  Widget _kpi(BuildContext context, String value, String label, {Color? valueColor}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              color: valueColor ?? AppColors.textPrimaryFor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiaryFor(context),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) => Container(
    width: 1,
    height: 28,
    color: AppColors.borderLightFor(context),
  );
}
