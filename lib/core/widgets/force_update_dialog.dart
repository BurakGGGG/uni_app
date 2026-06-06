import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../services/force_update_service.dart';

/// Zorunlu güncelleme veya bakım modu dialog'u.
///
/// Splash ekranından çağrılır. Kullanıcı kapatamaz (barrierDismissible: false).
class ForceUpdateDialog extends StatelessWidget {
  final ForceUpdateStatus status;
  final String languageCode;

  const ForceUpdateDialog({
    super.key,
    required this.status,
    this.languageCode = 'tr',
  });

  /// Dialog'u göster — BuildContext üzerinden çağrılır.
  static Future<void> show(BuildContext context, ForceUpdateStatus status, {String languageCode = 'tr'}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => ForceUpdateDialog(
        status: status,
        languageCode: languageCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isUpdate = status.requiresUpdate;

    return PopScope(
      canPop: false, // Geri tuşu ile kapatılamaz
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingXxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // İkon
              Semantics(
                label: isUpdate
                    ? (languageCode == 'tr' ? 'Güncelleme simgesi' : 'Update icon')
                    : (languageCode == 'tr' ? 'Bakım simgesi' : 'Maintenance icon'),
                child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isUpdate
                      ? AppColors.primaryGradient
                      : const LinearGradient(
                          colors: [AppColors.warning, Color(0xFFFF8C00)],
                        ),
                ),
                child: Icon(
                  isUpdate
                      ? Icons.system_update_rounded
                      : Icons.construction_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              ),

              const SizedBox(height: AppConstants.spacingLg),

              // Başlık
              Text(
                isUpdate
                    ? (languageCode == 'tr'
                        ? 'Güncelleme Gerekli'
                        : 'Update Required')
                    : (languageCode == 'tr' ? 'Bakım Modu' : 'Maintenance'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryFor(context),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppConstants.spacingMd),

              // Mesaj
              Text(
                status.message(languageCode),
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textSecondaryFor(context),
                ),
                textAlign: TextAlign.center,
              ),

              if (isUpdate && status.minVersion != null) ...[
                const SizedBox(height: AppConstants.spacingSm),
                Text(
                  languageCode == 'tr'
                      ? 'Minimum sürüm: v${status.minVersion}'
                      : 'Minimum version: v${status.minVersion}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiaryFor(context),
                  ),
                ),
              ],

              const SizedBox(height: AppConstants.spacingXxl),

              // Güncelle butonu (sadece update modunda)
              if (isUpdate)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _openStore,
                    icon: const Icon(Icons.download_rounded),
                    label: Text(
                      languageCode == 'tr' ? 'Güncelle' : 'Update',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMd),
                      ),
                    ),
                  ),
                ),

              // Bakım modunda sadece bilgi (buton yok)
              if (status.isMaintenanceMode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacingMd,
                    horizontal: AppConstants.spacingLg,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSm),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 18, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Text(
                        languageCode == 'tr'
                            ? 'Lütfen daha sonra deneyin'
                            : 'Please try again later',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Play Store veya App Store'u aç.
  void _openStore() {
    final Uri storeUrl;
    if (Platform.isAndroid) {
      storeUrl = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.unisec.app',
      );
    } else {
      // iOS App Store URL'si — gerçek ID ile değiştirilmeli
      storeUrl = Uri.parse(
        'https://apps.apple.com/app/unisec/id0000000000',
      );
    }
    launchUrl(storeUrl, mode: LaunchMode.externalApplication);
  }
}
