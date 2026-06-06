import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_constants.dart';

/// Gradient buton — ana aksiyonlar için kullanılır
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final LinearGradient? gradient;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final double height;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradient,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final buttonGradient = gradient ?? AppColors.primaryGradient;

    return Semantics(
      label: text,
      button: true,
      enabled: onPressed != null && !isLoading,
      child: SizedBox(
      height: height,
      width: isExpanded ? double.infinity : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed != null && !isLoading ? buttonGradient : null,
          color: onPressed == null || isLoading ? AppColors.border : null,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          boxShadow: onPressed != null && !isLoading
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            splashColor: Colors.white.withValues(alpha: 0.2),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : Row(
                        mainAxisSize:
                            isExpanded ? MainAxisSize.max : MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: AppColors.textOnPrimary, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Text(text, style: AppTextStyles.button),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}
