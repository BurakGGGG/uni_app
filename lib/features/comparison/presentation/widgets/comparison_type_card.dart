import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Hub ekranındaki karşılaştırma tipi kartı
/// [icon] İkon verisi, [title] Başlık, [description] Açıklama,
/// [badge] Alt bilgi badge'i, [isLocked] Kilit durumu,
/// [onTap] Tıklama callback'i
class ComparisonTypeCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final Color iconColor;
  final LinearGradient? iconGradient;
  final bool isLocked;
  final bool isSelected;
  final VoidCallback? onTap;

  const ComparisonTypeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    this.iconColor = AppColors.primary,
    this.iconGradient,
    this.isLocked = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<ComparisonTypeCard> createState() => _ComparisonTypeCardState();
}

class _ComparisonTypeCardState extends State<ComparisonTypeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late AnimationController _lockPulseController;
  late Animation<double> _lockPulseAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _lockPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _lockPulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _lockPulseController, curve: Curves.easeInOut),
    );
    _refreshPulse();
  }

  @override
  void didUpdateWidget(covariant ComparisonTypeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLocked != widget.isLocked) {
      _refreshPulse();
    }
  }

  void _refreshPulse() {
    if (widget.isLocked) {
      _lockPulseController.repeat(reverse: true);
    } else {
      _lockPulseController.stop();
      _lockPulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _lockPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _controller.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _controller.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? (_isPressed
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.05))
                : (_isPressed
                    ? AppColors.surfaceVariant
                    : AppColors.surface),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? widget.iconColor.withValues(alpha: 0.42)
                  : _isPressed
                  ? widget.iconColor.withValues(alpha: 0.3)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.border),
              width: widget.isSelected ? 2 : (_isPressed ? 1.5 : 1),
            ),
            boxShadow: _isPressed
                ? []
                : (widget.isSelected
                    ? [
                        BoxShadow(
                          color: widget.iconColor.withValues(alpha: 0.22),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [
                    BoxShadow(
                      color: widget.iconColor.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]),
          ),
          child: Row(
            children: [
              // İkon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: widget.iconGradient ??
                      LinearGradient(
                        colors: [
                          widget.iconColor.withValues(alpha: 0.15),
                          widget.iconColor.withValues(alpha: 0.08),
                        ],
                      ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              // İçerik
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isLocked
                            ? AppColors.tierPlus.withValues(alpha: 0.1)
                            : AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.badge,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: widget.isLocked
                              ? AppColors.tierPlus
                              : AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Kilit / ok ikonu
              if (widget.isLocked)
                AnimatedBuilder(
                  animation: _lockPulseAnim,
                  builder: (context, child) => Transform.scale(
                    scale: _lockPulseAnim.value,
                    child: child,
                  ),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.tierPlus.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: AppColors.tierPlus,
                      size: 18,
                    ),
                  ),
                )
              else
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: widget.iconColor,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
