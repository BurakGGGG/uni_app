import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/notification_preferences_provider.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  bool _systemPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSystemPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSystemPermission();
    }
  }

  Future<void> _checkSystemPermission() async {
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() => _systemPermissionGranted = status.isGranted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bildirim Ayarları')),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(message: '$e'),
        data: (prefs) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_systemPermissionGranted) _buildSystemPermissionWarning(),
              const SizedBox(height: 8),
              _buildSectionTitle('Bildirim Tipleri'),
              _SettingTile(
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFEC4899),
                title: 'Yorumun beğenildi',
                subtitle: 'Bir başkası yorumunu beğendiğinde bildirim al',
                value: prefs.reviewLikedEnabled,
                onChanged: (v) => ref
                    .read(notificationPreferencesProvider.notifier)
                    .toggle('reviewLikedEnabled', v),
              ),
              _SettingTile(
                icon: Icons.shield_rounded,
                iconColor: AppColors.success,
                title: 'Yorum moderasyon sonucu',
                subtitle:
                    'Yorumun onaylandığında veya reddedildiğinde bilgilendir',
                value: prefs.reviewModeratedEnabled,
                onChanged: (v) => ref
                    .read(notificationPreferencesProvider.notifier)
                    .toggle('reviewModeratedEnabled', v),
              ),
              _SettingTile(
                icon: Icons.fiber_new_rounded,
                iconColor: AppColors.info,
                title: 'Favori üniversiteme yeni yorum',
                subtitle:
                    'Favorindeki bir üniversite hakkında yeni yorum gelirse haberdar et',
                value: prefs.favoriteNewReviewEnabled,
                onChanged: (v) => ref
                    .read(notificationPreferencesProvider.notifier)
                    .toggle('favoriteNewReviewEnabled', v),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Bilgi'),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'ÜniSeç bildirimleri sadece etkileşim ve bilgilendirme amaçlıdır. Reklam veya pazarlama bildirimi göndermiyoruz.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemPermissionWarning() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'Sistem bildirimleri kapalı',
                style: AppTextStyles.titleSmall
                    .copyWith(color: AppColors.warning),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Cihazınızın bildirimleri kapalı. Aşağıdaki ayarları aktif etseniz bile push bildirim gelmez.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () =>
                openAppSettings().then((_) => _checkSystemPermission()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sistem ayarlarını aç'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondaryFor(context),
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile(
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(title, style: AppTextStyles.titleSmall),
          subtitle: Text(
            subtitle,
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryFor(context)),
          ),
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
      ),
    );
  }
}
