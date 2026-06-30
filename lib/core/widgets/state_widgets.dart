import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../../l10n/generated/app_localizations.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData? icon;
  final Widget? illustration;
  final String title;
  final String? description;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    this.icon,
    this.illustration,
    required this.title,
    this.description,
    this.actionText,
    this.onAction,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (illustration != null) 
            illustration!
          else if (icon != null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: AppColors.primary.withValues(alpha: 0.7)),
            ),
          const SizedBox(height: 20),
          Text(title, style: AppTextStyles.titleLarge, textAlign: TextAlign.center),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryFor(context)),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 20),
            action!,
          ] else if (actionText != null && onAction != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionText!),
            ),
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
    );
  }
}

/// Hata durumu widget'ı
class ErrorStateWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final bool compact;

  const ErrorStateWidget({
    super.key,
    this.message,
    this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppConstants.spacingMd : AppConstants.spacingXxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: compact ? 48 : 80,
              height: compact ? 48 : 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: compact ? 24 : 36,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: compact ? AppConstants.spacingMd : AppConstants.spacingXl),
            Text(
              loc.commonError,
              style: compact ? AppTextStyles.titleMedium : AppTextStyles.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              SizedBox(height: compact ? 4 : AppConstants.spacingSm),
              Text(
                message!,
                style: compact 
                  ? AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryFor(context))
                  : AppTextStyles.emptyState,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              SizedBox(height: compact ? AppConstants.spacingMd : AppConstants.spacingXl),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh_rounded, size: compact ? 16 : 20),
                label: Text(loc.retry),
                style: compact ? OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: AppTextStyles.labelMedium,
                ) : null,
              ),
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
    );
  }
}
