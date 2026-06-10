import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android'de bozulmuş Firebase Auth native depolamasını temizler.
class AuthStorageService {
  static const _channel = MethodChannel('com.unisec.app/auth_storage');

  static Future<int> clearFirebaseAuthStorage() async {
    try {
      final cleared = await _channel.invokeMethod<int>('clearFirebaseAuthStorage');
      if (kDebugMode) {
        debugPrint('[Auth] Native auth storage temizlendi: $cleared dosya');
      }
      return cleared ?? 0;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('[Auth] Native storage temizleme hatası: ${e.message}');
      }
      return 0;
    } on MissingPluginException {
      // iOS / desktop — native temizleme gerekmez
      return 0;
    }
  }
}
