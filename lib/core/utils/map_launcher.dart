import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

/// Harita uygulaması açmak için platform-agnostik yardımcı.
/// Fallback zinciri: native intent → Google Maps URL → browser.
class MapLauncher {
  MapLauncher._();

  /// Harita uygulamasını aç.
  /// Başarılıysa true, hiçbir uygulama açılamazsa false döner.
  static Future<bool> open({
    String? mapUrl,
    GeoPoint? location,
    String? name,
    String? address,
  }) async {
    // ─── 1. Explicit mapUrl varsa direkt aç ──────────────────────
    if (mapUrl != null && mapUrl.isNotEmpty) {
      final uri = Uri.parse(mapUrl);
      if (await _tryLaunch(uri)) return true;
    }

    // ─── 2. GeoPoint varsa native intent dene ────────────────────
    if (location != null) {
      final lat = location.latitude;
      final lng = location.longitude;
      final label = Uri.encodeComponent(name ?? '');

      // Android: geo: intent
      if (Platform.isAndroid) {
        final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
        if (await _tryLaunch(geoUri)) return true;
      }

      // iOS: Apple Maps
      if (Platform.isIOS) {
        final appleMaps = Uri.parse(
            'https://maps.apple.com/?ll=$lat,$lng&q=$label');
        if (await _tryLaunch(appleMaps)) return true;
      }

      // Google Maps web URL (her iki platform fallback)
      final gmapsUrl = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      if (await _tryLaunch(gmapsUrl)) return true;
    }

    // ─── 3. Text-based arama (son çare) ──────────────────────────
    final query = Uri.encodeComponent(
        '${name ?? ''} ${address ?? ''}'.trim());
    if (query.isNotEmpty) {
      final searchUrl = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$query');
      if (await _tryLaunch(searchUrl)) return true;
    }

    // ─── 4. Hiçbiri çalışmadı ────────────────────────────────────
    return false;
  }

  /// Play Store'daki Google Maps sayfasını aç.
  static Future<bool> openPlayStoreMaps() async {
    final Uri storeUri;
    if (Platform.isIOS) {
      storeUri = Uri.parse(
          'https://apps.apple.com/app/google-maps/id585027354');
    } else {
      storeUri = Uri.parse(
          'https://play.google.com/store/apps/details?id=com.google.android.apps.maps');
    }
    return _tryLaunch(storeUri);
  }

  static Future<bool> _tryLaunch(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (_) {
      // canLaunchUrl bazen exception fırlatabilir
    }
    return false;
  }
}
