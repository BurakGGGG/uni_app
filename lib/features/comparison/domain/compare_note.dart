import '../../assistant/domain/robot_scripts.dart';
import 'compare_view.dart';

/// Üni'nin karşılaştırma cümlesi.
///
/// Her karşılaştırmada TEK cümle konuşur (kullanıcı kararı) ve **kural
/// tabanlıdır** — mevcut yapay zekâ özeti Pro kilitli ve yorum yoksa boş
/// kalıyordu; bu her zaman dolu ve ücretsiz.
///
/// Kural: cümle asla "şunu seç" demez. Ekranın kendisi kazanan ilan
/// etmiyor; Üni de etmez, yalnız farkın nerede olduğunu söyler.
class CompareNote {
  final String id;
  final Map<String, String> values;

  const CompareNote(this.id, {this.values = const {}});

  String get text {
    var out = RobotScripts.compareNote(id);
    values.forEach((key, value) => out = out.replaceAll('{$key}', value));
    return out;
  }
}

/// Görünümden cümleyi seçer. Saf fonksiyon — testi ekransız yazılır.
CompareNote compareNoteFor(ComparisonView view) {
  final verdict = view.verdict;
  if (!verdict.hasData || view.sides.length < 2) {
    return const CompareNote('compare.none');
  }

  final names = view.sides.map(_shortName).toList();

  // Bir taraf ölçütlerin belirgin çoğunluğunda önde.
  final lead = verdict.clearLead;
  if (lead != null) {
    return CompareNote('compare.leads', values: {
      'name': names[lead],
      'count': '${verdict.leads[lead]}',
      'total': '${verdict.compared}',
    });
  }

  // Yakın: ikisi de kendi alanında önde mi? Öyleyse "neye göre" cümlesi
  // kuru bir "yakınlar"dan çok daha işe yarar.
  if (view.sides.length == 2) {
    final rowA = view.strongestFor(0);
    final rowB = view.strongestFor(1);
    if (rowA != null && rowB != null) {
      return CompareNote('compare.split', values: {
        'a': names[0],
        'b': names[1],
        'rowA': rowA.label.toLowerCase(),
        'rowB': rowB.label.toLowerCase(),
      });
    }
  }

  return CompareNote('compare.close', values: {
    'a': names[0],
    'b': names[1],
  });
}

/// "İstanbul Teknik Üniversitesi" → "İstanbul Teknik". Tam ad cümlenin
/// içinde satırı taşırıyor; ilk iki kelime tanınmaya yetiyor.
String _shortName(CompareSide side) {
  final parts = side.title.split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.length <= 2) return side.title;
  return parts.take(2).join(' ');
}
