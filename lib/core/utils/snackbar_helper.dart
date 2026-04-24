import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Uygulama genelinde tutarlı SnackBar göstermek için yardımcı fonksiyon.
/// Tüm SnackBar'lar floating davranışlı, yuvarlak köşeli ve
/// opsiyonel ikon destekli olur.
void showAppSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
  bool isSuccess = false,
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) {
  final Color bgColor;
  final IconData? icon;

  if (isError) {
    bgColor = AppColors.error;
    icon = Icons.error_outline_rounded;
  } else if (isSuccess) {
    bgColor = AppColors.success;
    icon = Icons.check_circle_outline_rounded;
  } else {
    bgColor = AppColors.textPrimary;
    icon = null;
  }

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
        action: action,
      ),
    );
}
