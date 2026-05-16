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
    '38': {'p': '#2D4B7A', 's': '#6082B6', 'o': false}, // Kayseri
    '44': {'p': '#C84B31', 's': '#ECDBBA', 'o': false}, // Malatya
    '55': {'p': '#1DABDE', 's': '#4DC3DF', 'o': false}, // Samsun
    '42': {'p': '#51B59C', 's': '#966BC0', 'o': false}, // Konya
    '43': {'p': '#154B7D', 's': '#60B7E8', 'o': false}, // Kütahya
    '41': {'p': '#412466', 's': '#7B5BA8', 'o': false}, // Kocaeli
    '54': {'p': '#5A38A2', 's': '#7C51BD', 'o': false}, // Sakarya
    '14': {'p': '#3773B4', 's': '#82B0DA', 'o': false}, // Bolu
    '67': {'p': '#4EBFCE', 's': '#F47BA8', 'o': false}, // Zonguldak
    '65': {'p': '#B96790', 's': '#D790AC', 'o': false}, // Van
    '25': {'p': '#4C9DC2', 's': '#223E5A', 'o': false}, // Erzurum
    '27': {'p': '#F97E26', 's': '#FFAA75', 'o': false}, // Gaziantep
    '01': {'p': '#AB5B86', 's': '#361641', 'o': false}, // Adana
    '20': {'p': '#1DABDE', 's': '#4DC3DF', 'o': false}, // Denizli
    '46': {'p': '#51B59C', 's': '#966BC0', 'o': false}, // Kahramanmaraş
    '45': {'p': '#154B7D', 's': '#60B7E8', 'o': false}, // Manisa
    '32': {'p': '#412466', 's': '#7B5BA8', 'o': false}, // Isparta
    '78': {'p': '#5A38A2', 's': '#7C51BD', 'o': false}, // Karabük
    '60': {'p': '#3773B4', 's': '#82B0DA', 'o': false}, // Tokat
  };

  // ── Üniversite düzeyinde brand renkleri (logo'dan çıkarılan) ──
  static const Map<String, Map<String, dynamic>> universityBrandColors = {
    // ── İstanbul ──
    'itu':               {'p': '#1A237E', 's': '#283593', 'o': false},
    'istanbul_uni':      {'p': '#1B5E20', 's': '#2E7D32', 'o': false},
    'yildiz_teknik':     {'p': '#FFB300', 's': '#0D47A1', 'o': false},
    'marmara':           {'p': '#0D47A1', 's': '#1565C0', 'o': false},
    'aydin':             {'p': '#1A237E', 's': '#283593', 'o': false},
    'gelisim':           {'p': '#1A237E', 's': '#757575', 'o': false},
    'medipol':           {'p': '#B71C1C', 's': '#D32F2F', 'o': false},
    // ── Ankara ──
    'odtu':              {'p': '#D32F2F', 's': '#EF5350', 'o': false},
    'hacettepe':         {'p': '#D32F2F', 's': '#EF5350', 'o': false},
    'ankara_uni':        {'p': '#0D47A1', 's': '#FFB300', 'o': false},
    'gazi':              {'p': '#0D47A1', 's': '#4DD0E1', 'o': false},
    'hacibayram':        {'p': '#212121', 's': '#D32F2F', 'o': false},
    // ── İzmir ──
    'ege':               {'p': '#0D47A1', 's': '#1976D2', 'o': false},
    'dokuz_eylul':       {'p': '#1A237E', 's': '#303F9F', 'o': false},
    'izmir_demokrasi':   {'p': '#795548', 's': '#C62828', 'o': false},
    'izmir_katipcelebi': {'p': '#B71C1C', 's': '#880E4F', 'o': false},
    // ── Antalya ──
    'akdeniz':           {'p': '#E65100', 's': '#FF6D00', 'o': false},
    'alanya':            {'p': '#0277BD', 's': '#039BE5', 'o': false},
    // ── Eskişehir ──
    'anadolu':           {'p': '#212121', 's': '#424242', 'o': false},
    'ogu':               {'p': '#00ACC1', 's': '#0D47A1', 'o': false},
    'estu':              {'p': '#800000', 's': '#500000', 'o': false},
    // ── Bursa ──
    'uludag':            {'p': '#00ACC1', 's': '#0D47A1', 'o': false},
    'btu':               {'p': '#0D47A1', 's': '#1976D2', 'o': false},
    // ── Çanakkale ──
    'comu':              {'p': '#D32F2F', 's': '#212121', 'o': false},
    // ── Sivas ──
    'cumhuriyet':        {'p': '#D32F2F', 's': '#B71C1C', 'o': false},
    'sivas_btu':         {'p': '#1A237E', 's': '#283593', 'o': false},
    // ── Trabzon ──
    'ktu':               {'p': '#1A237E', 's': '#1565C0', 'o': false},
    'trabzon_uni':       {'p': '#004D40', 's': '#00695C', 'o': false},
    // ── Mersin ──
    'mersin_uni':        {'p': '#E65100', 's': '#FF8F00', 'o': false},
    'tarsus':            {'p': '#1A237E', 's': '#1976D2', 'o': false},
    // ── Çorum ──
    'hitit':             {'p': '#FF8F00', 's': '#1A237E', 'o': false},
    
    // ── 19 Yeni Üniversite ──
    'erciyes': {'p': '#1A3C8F', 's': '#C41E3A', 'o': false}, // Mavi + Kırmızı
    'inonu':   {'p': '#F5A623', 's': '#C88B18', 'o': false}, // Altın sarısı
    'omu':     {'p': '#3B5998', 's': '#C0392B', 'o': false}, // Mavi + Kırmızı
    'selcuk':  {'p': '#D4A817', 's': '#8B7312', 'o': false}, // Altın kartal
    'dpu':     {'p': '#3D348B', 's': '#6A5ACD', 'o': false}, // Mor/Lacivert
    'kocaeli': {'p': '#1B9E5F', 's': '#2C3E50', 'o': false}, // Yeşil + Lacivert
    'sakarya': {'p': '#1A3478', 's': '#2C5AA0', 'o': false}, // Lacivert
    'ibu':     {'p': '#1B7A3D', 's': '#2E4C8A', 'o': false}, // Yeşil + Lacivert
    'beun':    {'p': '#D32F2F', 's': '#B71C1C', 'o': false},
    'yyu':     {'p': '#1A5276', 's': '#5DADE2', 'o': false}, // Koyu mavi + Açık mavi
    'atauni':  {'p': '#2E3A6E', 's': '#C9A94E', 'o': false}, // Lacivert + Altın
    'gantep':  {'p': '#1A2D5A', 's': '#C0392B', 'o': false}, // Lacivert + Kırmızı
    'cu':      {'p': '#1E7B2C', 's': '#0E5C1E', 'o': false}, // Yeşil tonları
    'pau':     {'p': '#1A4C7A', 's': '#4A90D9', 'o': false}, // İki ton mavi
    'ksu':     {'p': '#343278', 's': '#C0392B', 'o': false}, // Mor + Kırmızı
    'cbu':     {'p': '#1A3478', 's': '#4DC4E0', 'o': false}, // Lacivert + Açık mavi
    'sdu':     {'p': '#D42B2B', 's': '#8B1A1A', 'o': false}, // Kırmızı tonları
    'karabuk': {'p': '#3B6FA0', 's': '#C0392B', 'o': false}, // Mavi + Kırmızı
    'gop':     {'p': '#008B8B', 's': '#4A1558', 'o': false}, // Teal + Mor
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
    print('✅ ${brandColors.length} şehre yeni brand renkleri yazıldı');
  }

  /// 19 yeni üniversiteye brand gradient renklerini yazar.
  Future<void> runUniversityBrandColors() async {
    final batch = _db.batch();
    for (final entry in universityBrandColors.entries) {
      final ref = _db.collection('universities').doc(entry.key);
      batch.set(ref, {
        'brandPrimaryHex': entry.value['p'],
        'brandSecondaryHex': entry.value['s'],
        'brandUseDarkOverlay': entry.value['o'],
      }, SetOptions(merge: true));
    }
    await batch.commit();
    // ignore: avoid_print
    print('✅ ${universityBrandColors.length} üniversiteye brand renkleri yazıldı');
  }
}
