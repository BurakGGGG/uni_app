import 'package:cloud_firestore/cloud_firestore.dart';

class BrandColorsMigration {
  final _db = FirebaseFirestore.instance;

  static const Map<String, Map<String, dynamic>> brandColors = {
    'odtu':              {'p': '#C00000', 's': '#7A0000', 'o': false},
    'itu':               {'p': '#002757', 's': '#1E4E8C', 'o': false},
    'istanbul_uni':      {'p': '#016E3A', 's': '#FCD622', 'o': false},
    'marmara':           {'p': '#093B6E', 's': '#315883', 'o': false},
    'yildiz_teknik':     {'p': '#252161', 's': '#A28F61', 'o': false},
    'aydin':             {'p': '#1C3281', 's': '#3C4F92', 'o': false},
    'gelisim':           {'p': '#1F284B', 's': '#3B4670', 'o': false},
    'medipol':           {'p': '#1A285B', 's': '#36447A', 'o': false},
    'hacettepe':         {'p': '#EC1B23', 's': '#A50E14', 'o': false},
    'ankara_uni':        {'p': '#0F4E8B', 's': '#E0C47D', 'o': false},
    'gazi':              {'p': '#113971', 's': '#BBE2F9', 'o': false},
    'hacibayram':        {'p': '#EE3039', 's': '#B12029', 'o': false},
    'ege':               {'p': '#242367', 's': '#81CDEC', 'o': false},
    'dokuz_eylul':       {'p': '#0061AA', 's': '#003F70', 'o': false},
    'iyte':              {'p': '#093B6E', 's': '#1A5BA0', 'o': false},
    'izmir_demokrasi':   {'p': '#5E5971', 's': '#3F3B4D', 'o': false},
    'izmir_katipcelebi': {'p': '#AC182D', 's': '#7A0F1F', 'o': false},
    'yasar':             {'p': '#0066B3', 's': '#003B6F', 'o': false},
    'akdeniz':           {'p': '#13294B', 's': '#F07224', 'o': false},
    'alanya':            {'p': '#1C3F7D', 's': '#00ADCC', 'o': false},
    'anadolu':           {'p': '#1A1A1A', 's': '#404040', 'o': false},
    'ogu':               {'p': '#171796', 's': '#49CED4', 'o': false},
    'estu':              {'p': '#B01928', 's': '#7C0F1A', 'o': false},
    'uludag':            {'p': '#14387F', 's': '#63C3D1', 'o': false},
    'btu':               {'p': '#123E6D', 's': '#04B1C9', 'o': false},
    'comu':              {'p': '#241B5A', 's': '#EC1C24', 'o': false},
    'cumhuriyet':        {'p': '#E30613', 's': '#A4040E', 'o': false},
    'sivas_btu':         {'p': '#009FE3', 's': '#E20612', 'o': false},
    'ktu':               {'p': '#003F6B', 's': '#1A5C8E', 'o': false},
    'trabzon_uni':       {'p': '#A41923', 's': '#2A5FAA', 'o': false},
    'mersin_uni':        {'p': '#EE7202', 's': '#1E2855', 'o': false},
    'tarsus':            {'p': '#20416A', 's': '#405B7F', 'o': false},
    'hitit':             {'p': '#EE7522', 's': '#002454', 'o': false},
  };

  Future<void> run() async {
    var batch = _db.batch();
    var count = 0;

    for (final entry in brandColors.entries) {
      final ref = _db.collection('universities').doc(entry.key);
      batch.set(ref, {
        'brandPrimaryHex': entry.value['p'],
        'brandSecondaryHex': entry.value['s'],
        'brandUseDarkOverlay': entry.value['o'],
      }, SetOptions(merge: true));
      count++;

      if (count >= 490) {
        await batch.commit();
        batch = _db.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
    // ignore: avoid_print
    print('✅ ${brandColors.length} üniversiteye marka renkleri yazıldı');
  }
}
