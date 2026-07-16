import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_constants.dart';

/// Buton vurgu seviyesi.
enum _GButtonVariant {
  /// Gradient dolgulu ana aksiyon (varsayılan).
  gradient,

  /// Tonal — primary düşük-alfa dolgu, primary metin (orta vurgu).
  secondary,

  /// Çerçeveli — şeffaf dolgu, primary kenarlık ve metin.
  outline,

  /// Sadece primary renkli metin.
  text,
}

/// Markalı buton ailesi.
///
/// - `GradientButton(...)` — gradient dolgulu ana aksiyon.
/// - `GradientButton.secondary(...)` — tonal, orta vurgulu.
/// - `GradientButton.outline(...)` — çerçeveli ikincil.
/// - `GradientButton.text(...)` — metin butonu.
///
/// Tüm varyantlar aynı basış animasyonunu, yükleme durumunu ve `Semantics`
/// davranışını paylaşır; böylece ikincil aksiyonlar da raw Material yerine
/// marka diline bağlı kalır.
class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final LinearGradient? gradient;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final double height;
  final _GButtonVariant _variant;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradient,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
    this.height = 52,
  }) : _variant = _GButtonVariant.gradient;

  /// Tonal (orta vurgulu) buton — primary düşük-alfa dolgu, primary metin.
  const GradientButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
    this.height = 52,
  })  : gradient = null,
        _variant = _GButtonVariant.secondary;

  /// Çerçeveli ikincil buton — şeffaf dolgu, primary kenarlık ve metin.
  const GradientButton.outline({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
    this.height = 52,
  })  : gradient = null,
        _variant = _GButtonVariant.outline;

  /// Metin butonu — sadece primary renkli metin.
  const GradientButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.height = 48,
  })  : gradient = null,
        _variant = _GButtonVariant.text;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  bool get _isGradient => widget._variant == _GButtonVariant.gradient;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final buttonGradient = widget.gradient ?? AppColors.primaryGradient;
    final radius = BorderRadius.circular(AppConstants.radiusMd);

    // ─── Varyanta göre renk/dolgu/kenarlık ──────────────────────
    final Color contentColor = _isGradient
        ? (enabled ? AppColors.textOnPrimary : AppColors.textTertiaryFor(context))
        : (enabled ? AppColors.primary : AppColors.textTertiaryFor(context));

    Gradient? fillGradient;
    Color? fillColor;
    Border? border;
    List<BoxShadow>? shadow;
    Color splashColor;

    switch (widget._variant) {
      case _GButtonVariant.gradient:
        fillGradient = enabled ? buttonGradient : null;
        fillColor = enabled ? null : AppColors.borderFor(context);
        shadow = enabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null;
        splashColor = Colors.white.withValues(alpha: 0.2);
      case _GButtonVariant.secondary:
        fillColor = AppColors.primary.withValues(alpha: enabled ? 0.12 : 0.05);
        splashColor = AppColors.primary.withValues(alpha: 0.12);
      case _GButtonVariant.outline:
        fillColor = Colors.transparent;
        border = Border.all(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.borderFor(context),
          width: 1.5,
        );
        splashColor = AppColors.primary.withValues(alpha: 0.1);
      case _GButtonVariant.text:
        fillColor = Colors.transparent;
        splashColor = AppColors.primary.withValues(alpha: 0.1);
    }

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
              gradient: fillGradient,
              color: fillColor,
              border: border,
              borderRadius: radius,
              boxShadow: shadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : widget.onPressed,
                onHighlightChanged: enabled
                    ? (v) => setState(() => _pressed = v)
                    : null,
                borderRadius: radius,
                splashColor: splashColor,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget._variant == _GButtonVariant.text
                        ? 12
                        : 24,
                  ),
                  child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: contentColor,
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
                                    color: contentColor, size: 20),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                widget.text,
                                style: AppTextStyles.button
                                    .copyWith(color: contentColor),
                              ),
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
