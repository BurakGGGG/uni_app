import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Firebase Remote Config ile zorunlu güncelleme kontrolü.
///
/// Remote Config anahtarları:
/// - `min_supported_version` : "1.0.0" gibi bir string
/// - `force_update_enabled`  : true/false
/// - `update_message_tr`     : Türkçe güncelleme mesajı
/// - `update_message_en`     : İngilizce güncelleme mesajı
class ForceUpdateService {
  static final ForceUpdateService _instance = ForceUpdateService._();
  factory ForceUpdateService() => _instance;
  ForceUpdateService._();

  bool _initialized = false;
  final _remoteConfig = FirebaseRemoteConfig.instance;

  /// Remote Config anahtarları
  static const _keyMinVersion = 'min_supported_version';
  static const _keyForceUpdateEnabled = 'force_update_enabled';
  static const _keyUpdateMessageTr = 'update_message_tr';
  static const _keyUpdateMessageEn = 'update_message_en';
  static const _keyMaintenanceMode = 'maintenance_mode';
  static const _keyMaintenanceMessageTr = 'maintenance_message_tr';
  static const _keyMaintenanceMessageEn = 'maintenance_message_en';

  /// SDK'yı başlat ve varsayılan değerleri ayarla.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _remoteConfig.setDefaults({
        _keyMinVersion: '1.0.0',
        _keyForceUpdateEnabled: false,
        _keyUpdateMessageTr: 'Uygulamanın yeni bir sürümü mevcut. Devam etmek için lütfen güncelleyin.',
        _keyUpdateMessageEn: 'A new version of the app is available. Please update to continue.',
        _keyMaintenanceMode: false,
        _keyMaintenanceMessageTr: 'Uygulama şu anda bakımdadır. Lütfen daha sonra tekrar deneyin.',
        _keyMaintenanceMessageEn: 'The app is currently under maintenance. Please try again later.',
      });

      // Fetch interval: debug modda 10 saniye, production'da 12 saat
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode
            ? const Duration(seconds: 10)
            : const Duration(hours: 12),
      ));

      // Fetch & activate
      await _remoteConfig.fetchAndActivate();
      debugPrint('[ForceUpdate] Remote Config initialized');
    } catch (e) {
      debugPrint('[ForceUpdate] Init error: $e');
      // Remote Config başarısız olursa uygulama devam eder
    }
  }

  /// Zorunlu güncelleme gerekip gerekmediğini kontrol eder.
  ///
  /// [currentVersion] pubspec.yaml'daki `version` alanından gelir.
  /// Dönen [ForceUpdateStatus] ile dialog gösterilmeli.
  ForceUpdateStatus checkForUpdate(String currentVersion) {
    // Maintenance mode kontrolü
    final isMaintenanceMode = _remoteConfig.getBool(_keyMaintenanceMode);
    if (isMaintenanceMode) {
      return ForceUpdateStatus(
        requiresUpdate: false,
        isMaintenanceMode: true,
        messageTr: _remoteConfig.getString(_keyMaintenanceMessageTr),
        messageEn: _remoteConfig.getString(_keyMaintenanceMessageEn),
      );
    }

    // Force update kontrolü
    final isEnabled = _remoteConfig.getBool(_keyForceUpdateEnabled);
    if (!isEnabled) {
      return ForceUpdateStatus.none();
    }

    final minVersion = _remoteConfig.getString(_keyMinVersion);
    final needsUpdate = _isVersionLower(currentVersion, minVersion);

    if (needsUpdate) {
      return ForceUpdateStatus(
        requiresUpdate: true,
        isMaintenanceMode: false,
        minVersion: minVersion,
        messageTr: _remoteConfig.getString(_keyUpdateMessageTr),
        messageEn: _remoteConfig.getString(_keyUpdateMessageEn),
      );
    }

    return ForceUpdateStatus.none();
  }

  /// [current] versiyonun [minimum]'dan küçük olup olmadığını kontrol eder.
  ///
  /// Semantik sürümleme: "1.2.3" < "1.3.0" → true
  bool _isVersionLower(String current, String minimum) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final minParts = minimum.split('.').map(int.parse).toList();

      // 3 segment'e pad et
      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      while (minParts.length < 3) {
        minParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (currentParts[i] < minParts[i]) return true;
        if (currentParts[i] > minParts[i]) return false;
      }
      return false; // Eşitler → güncelleme gerekmez
    } catch (e) {
      debugPrint('[ForceUpdate] Version parse error: $e');
      return false; // Parse hatası → güncelleme gerektirme
    }
  }

  /// Remote Config'i yeniden fetch eder (arka planda periyodik çağrı için).
  Future<void> refresh() async {
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint('[ForceUpdate] Refresh error: $e');
    }
  }
}

/// Güncelleme kontrolü sonucu.
class ForceUpdateStatus {
  final bool requiresUpdate;
  final bool isMaintenanceMode;
  final String? minVersion;
  final String? messageTr;
  final String? messageEn;

  const ForceUpdateStatus({
    required this.requiresUpdate,
    required this.isMaintenanceMode,
    this.minVersion,
    this.messageTr,
    this.messageEn,
  });

  /// Güncelleme gerektirmeyen durum.
  factory ForceUpdateStatus.none() => const ForceUpdateStatus(
        requiresUpdate: false,
        isMaintenanceMode: false,
      );

  /// Herhangi bir engel var mı?
  bool get isBlocking => requiresUpdate || isMaintenanceMode;

  /// Dil koduna göre doğru mesajı döndürür.
  String message(String languageCode) {
    if (languageCode == 'tr') {
      return messageTr ?? 'Lütfen uygulamayı güncelleyin.';
    }
    return messageEn ?? 'Please update the app.';
  }
}
