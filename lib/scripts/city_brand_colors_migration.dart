import 'package:cloud_firestore/cloud_firestore.dart';

class CityBrandColorsMigration {
  final _db = FirebaseFirestore.instance;

  // Logo analizinden çıkan k-means dominant renkler.
  static const Map<String, Map<String, dynamic>> brandColors = {
    '34': {'p': '#B96790', 's': '#D790AC', 'o': false}, // İstanbul
    '06': {'p': '#5A38A2', 's': '#7C51BD', 'o': false}, // Ankara
    '35': {'p': '#1DABDE', 's': '#4DC3DF', 'o': false}, // İzmir
    '07': {'p': '#51B59C', 's': '#966BC0', 'o': false}, // Antalya
    '26': {'p': '#154B7D', 's': '#60B7E8', 'o': false}, // Eskişehir
    '16': {'p': '#412466', 's': '#7B5BA8', 'o': false}, // Bursa
    '17': {'p': '#4EBFCE', 's': '#F47BA8', 'o': false}, // Çanakkale
    '58': {'p': '#3773B4', 's': '#82B0DA', 'o': false}, // Sivas
    '61': {'p': '#4C9DC2', 's': '#223E5A', 'o': false}, // Trabzon
    '33': {'p': '#F97E26', 's': '#FFAA75', 'o': false}, // Mersin
    '19': {'p': '#AB5B86', 's': '#361641', 'o': false}, // Çorum
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
    print('✅ 11 şehre yeni brand renkleri yazıldı');
  }
}
