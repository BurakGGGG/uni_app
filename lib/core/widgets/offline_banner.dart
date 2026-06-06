import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/connectivity_provider.dart';
import '../theme/app_colors.dart';

/// İnternet bağlantısı olmadığında ekranın üstünde kalıcı bir banner gösterir.
///
/// [AppShell]'in body'si içine sarılır. Bağlantı geri geldiğinde
/// otomatik olarak kaybolur (animasyonlu).
class OfflineBanner extends ConsumerWidget {
  final Widget child;

  const OfflineBanner({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final isDark = AppColors.isDark(context);

    return Column(
      children: [
        // Banner — sadece offline iken göster
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isOnline
              ? const SizedBox.shrink()
              : Semantics(
                  liveRegion: true,
                  label: _getOfflineText(context),
                  child: Material(
                  color: isDark
                      ? const Color(0xFF2D1B00)
                      : AppColors.warningLight,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 18,
                            color: isDark
                                ? AppColors.warning
                                : const Color(0xFFB45309),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _getOfflineText(context),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.warning
                                    : const Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                  ),
                ),
                ),

        // Asıl içerik
        Expanded(child: child),
      ],
    );
  }

  String _getOfflineText(BuildContext context) {
    try {
      return Localizations.localeOf(context).languageCode == 'tr'
          ? 'İnternet bağlantısı yok. Çevrimdışı veriler gösteriliyor.'
          : 'No internet connection. Showing offline data.';
    } catch (_) {
      return 'No internet connection.';
    }
  }
}

