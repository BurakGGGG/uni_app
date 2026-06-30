import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_constants.dart';

/// Gradient buton — ana aksiyonlar için kullanılır
class GradientButton extends StatefulWidget {
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
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final buttonGradient = widget.gradient ?? AppColors.primaryGradient;
    final enabled = widget.onPressed != null && !widget.isLoading;

    return Semantics(
      label: widget.text,
      button: true,
      enabled: enabled,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: SizedBox(
      height: widget.height,
      width: widget.isExpanded ? double.infinity : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? buttonGradient : null,
          color: enabled ? null : AppColors.border,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          boxShadow: enabled
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
            onTap: widget.isLoading ? null : widget.onPressed,
            onHighlightChanged: enabled
                ? (v) => setState(() => _pressed = v)
                : null,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            splashColor: Colors.white.withValues(alpha: 0.2),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : Row(
                        mainAxisSize: widget.isExpanded
                            ? MainAxisSize.max
                            : MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon,
                                color: AppColors.textOnPrimary, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Text(widget.text, style: AppTextStyles.button),
                        ],
                      ),
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
