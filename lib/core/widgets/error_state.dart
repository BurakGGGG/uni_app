import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../l10n/generated/app_localizations.dart';

/// Standart error UI — async error'lar için.
/// Tüm `AsyncValue.error` ve catch bloklarında bunu kullan.
///
/// Kullanım:
/// ```dart
/// asyncValue.when(
///   data: ...,
///   loading: () => const ListSkeleton(),
///   error: (e, _) => ErrorState(
///     message: 'Yorumlar yüklenemedi',
///     onRetry: () => ref.invalidate(reviewsProvider),
///   ),
/// )
/// ```
class ErrorState extends StatelessWidget {
  final String? title;
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  final bool compact;

  const ErrorState({
    super.key,
    this.title,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 16.0 : 32.0;
    final loc = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 56 : 72,
              height: compact ? 56 : 72,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: compact ? 28 : 36,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: compact ? 12 : 16),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: AppTextStyles.errorTitle,
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.errorBody,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(loc.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
