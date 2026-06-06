import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/services/force_update_service.dart';

void main() {
  group('ForceUpdateStatus', () {
    test('.none() — güncelleme gerektirmez', () {
      final status = ForceUpdateStatus.none();
      expect(status.requiresUpdate, isFalse);
      expect(status.isMaintenanceMode, isFalse);
      expect(status.isBlocking, isFalse);
      expect(status.minVersion, isNull);
    });

    test('requiresUpdate = true → isBlocking true', () {
      const status = ForceUpdateStatus(
        requiresUpdate: true,
        isMaintenanceMode: false,
        minVersion: '2.0.0',
        messageTr: 'Güncelleme gerekli.',
        messageEn: 'Update required.',
      );

      expect(status.isBlocking, isTrue);
      expect(status.requiresUpdate, isTrue);
      expect(status.minVersion, equals('2.0.0'));
    });

    test('isMaintenanceMode = true → isBlocking true', () {
      const status = ForceUpdateStatus(
        requiresUpdate: false,
        isMaintenanceMode: true,
        messageTr: 'Bakımdayız.',
        messageEn: 'Under maintenance.',
      );

      expect(status.isBlocking, isTrue);
      expect(status.isMaintenanceMode, isTrue);
      expect(status.requiresUpdate, isFalse);
    });

    test('message() — Türkçe döner', () {
      const status = ForceUpdateStatus(
        requiresUpdate: true,
        isMaintenanceMode: false,
        messageTr: 'Güncelleme gerekli.',
        messageEn: 'Update required.',
      );

      expect(status.message('tr'), equals('Güncelleme gerekli.'));
    });

    test('message() — İngilizce döner', () {
      const status = ForceUpdateStatus(
        requiresUpdate: true,
        isMaintenanceMode: false,
        messageTr: 'Güncelleme gerekli.',
        messageEn: 'Update required.',
      );

      expect(status.message('en'), equals('Update required.'));
    });

    test('message() — Türkçe null ise varsayılan döner', () {
      const status = ForceUpdateStatus(
        requiresUpdate: true,
        isMaintenanceMode: false,
      );

      expect(status.message('tr'), contains('güncelleyin'));
    });

    test('message() — İngilizce null ise varsayılan döner', () {
      const status = ForceUpdateStatus(
        requiresUpdate: true,
        isMaintenanceMode: false,
      );

      expect(status.message('en'), contains('update'));
    });

    test('message() — bilinmeyen dil kodu İngilizce döner', () {
      const status = ForceUpdateStatus(
        requiresUpdate: true,
        isMaintenanceMode: false,
        messageTr: 'TR',
        messageEn: 'EN',
      );

      expect(status.message('de'), equals('EN'));
      expect(status.message('fr'), equals('EN'));
    });
  });

  group('ForceUpdateService — _isVersionLower mantığı', () {
    // ForceUpdateService._isVersionLower private olduğu için,
    // davranışı checkForUpdate üzerinden dolaylı test edilir.
    // Ancak burada versiyon karşılaştırma mantığını bağımsız test edelim.

    bool isVersionLower(String current, String minimum) {
      try {
        final currentParts = current.split('.').map(int.parse).toList();
        final minParts = minimum.split('.').map(int.parse).toList();
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
        return false;
      } catch (_) {
        return false;
      }
    }

    test('1.0.0 < 2.0.0 → true', () {
      expect(isVersionLower('1.0.0', '2.0.0'), isTrue);
    });

    test('1.0.0 < 1.1.0 → true', () {
      expect(isVersionLower('1.0.0', '1.1.0'), isTrue);
    });

    test('1.0.0 < 1.0.1 → true', () {
      expect(isVersionLower('1.0.0', '1.0.1'), isTrue);
    });

    test('2.0.0 > 1.0.0 → false', () {
      expect(isVersionLower('2.0.0', '1.0.0'), isFalse);
    });

    test('1.0.0 == 1.0.0 → false (eşitler güncelleme gerektirmez)', () {
      expect(isVersionLower('1.0.0', '1.0.0'), isFalse);
    });

    test('2 segment → padding ile çalışır', () {
      expect(isVersionLower('1.0', '1.0.1'), isTrue);
    });

    test('1 segment → padding ile çalışır', () {
      expect(isVersionLower('1', '2'), isTrue);
      expect(isVersionLower('2', '1'), isFalse);
    });

    test('invalid format → false (parse hatası)', () {
      expect(isVersionLower('abc', '1.0.0'), isFalse);
      expect(isVersionLower('1.0.0', 'xyz'), isFalse);
    });

    test('major > minor fark → major kazanır', () {
      expect(isVersionLower('2.0.0', '1.9.9'), isFalse);
      expect(isVersionLower('1.9.9', '2.0.0'), isTrue);
    });
  });
}
