import 'package:cloud_firestore/cloud_firestore.dart';

class CityBrandColorsMigration {
  final _db = FirebaseFirestore.instance;

  static const Map<String, Map<String, dynamic>> brandColors = {
    '34': {'p': '#1B3A6B', 's': '#C9A84C', 'o': false}, // İstanbul
    '06': {'p': '#B5271A', 's': '#7A0E08', 'o': false}, // Ankara
    '35': {'p': '#007BAC', 's': '#00547A', 'o': false}, // İzmir
    '07': {'p': '#E07020', 's': '#A84E10', 'o': false}, // Antalya
    '26': {'p': '#5B3D8C', 's': '#3A245E', 'o': false}, // Eskişehir
    '16': {'p': '#1E7A3E', 's': '#0F4E26', 'o': false}, // Bursa
    '17': {'p': '#2C3D6F', 's': '#8B1A1A', 'o': false}, // Çanakkale
    '58': {'p': '#8B1A1A', 's': '#C8902A', 'o': false}, // Sivas
    '61': {'p': '#0D5C36', 's': '#1565C0', 'o': false}, // Trabzon
    '33': {'p': '#D94F12', 's': '#006B6B', 'o': false}, // Mersin
    '19': {'p': '#7B4F23', 's': '#C8A050', 'o': false}, // Çorum
  };

  Future<void> run() async {
    final batch = _db.batch();
    for (final entry in brandColors.entries) {
      final ref = _db.collection('cities').doc(entry.key);
      batch.set(ref, {
        'brandPrimaryHex': entry.value['p'],
        'brandSecondaryHex': entry.value['s'],
        'brandUseDarkOverlay': entry.value['o'],
      }, SetOptions(merge: true));
    }
    await batch.commit();
    // ignore: avoid_print
    print('✅ 11 şehre brand renkleri yazıldı');
  }
}
