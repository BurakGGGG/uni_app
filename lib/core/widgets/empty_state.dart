import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Standart empty state UI — boş listeler için.
///
/// Kullanım:
/// ```dart
/// items.isEmpty
///   ? EmptyState(
///       icon: Icons.favorite_border_rounded,
///       title: 'Favori yok',
///       message: 'Beğendiğin üniversiteleri buradan takip edebilirsin.',
///       action: TextButton(...),
///     )
///   : ListView(...)
/// ```
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final bool compact;

  /// Opsiyonel markalı görsel (illüstrasyon/Lottie). Verilirse [icon] daireli
  /// gösterimi yerine bu widget çizilir. Asset pipeline hazır olduğunda boş
  /// durumlar buradan markalanır; verilmezse mevcut ikon davranışı korunur.
  final Widget? illustration;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.compact = false,
    this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = compact ? 16.0 : 32.0;
    return Semantics(
      label: message != null ? '$title. $message' : title,
      child: Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null)
              illustration!
            else
              Container(
                width: compact ? 64 : 80,
                height: compact ? 64 : 80,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: compact ? 32 : 40,
                  color: AppColors.textTertiaryFor(context),
                ),
              ),
            SizedBox(height: compact ? 12 : 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.emptyTitle,
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.emptyBody,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        )
            .animate()
            .fadeIn(duration: 220.ms)
            .scale(
              begin: const Offset(0.96, 0.96),
              curve: Curves.easeOut,
              duration: 220.ms,
            ),
      ),
    ),
    );
  }
}
