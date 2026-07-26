import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/assistant/domain/robot_scripts.dart';
import 'package:uni_app/features/comparison/domain/compare_note.dart';
import 'package:uni_app/features/comparison/domain/compare_view.dart';

/// Üni'nin karşılaştırma cümlesi.
///
/// Kilitlenen sözleşme: kural tabanlı, her zaman dolu, iki dilli ve
/// **asla "şunu seç" demez** — ekran kazanan ilan etmiyorken Üni de etmez.
void main() {
  tearDown(() => RobotScripts.languageCode = 'tr');

  CompareRow row(String label, List<double?> values) => CompareRow(
        label: label,
        values: values,
        display: values.map((v) => v?.toString() ?? '—').toList(),
      );

  ComparisonView view(List<CompareRow> rows) => ComparisonView(
        sides: const [
          CompareSide(id: 'a', title: 'İstanbul Teknik Üniversitesi'),
          CompareSide(id: 'b', title: 'Orta Doğu Teknik Üniversitesi'),
        ],
        groups: [CompareGroup(title: 'g', rows: rows)],
      );

  test('veri yoksa özür diler, uydurmaz', () {
    expect(compareNoteFor(view(const [])).id, 'compare.none');
  });

  test('bir taraf belirgin öndeyse onu söyler ama karar dayatmaz', () {
    final note = compareNoteFor(view([
      row('Bölüm', [120, 90]),
      row('Kontenjan', [5000, 3000]),
      row('Puan', [4.5, 4.0]),
    ]));

    expect(note.id, 'compare.leads');
    expect(note.values['count'], '3');
    expect(note.values['total'], '3');
    // Uzun ad cümleyi taşırıyor; iki kelime tanınmaya yetiyor.
    expect(note.values['name'], 'İstanbul Teknik');
  });

  test('her taraf kendi alanında öndeyse "neye göre" cümlesi kurar', () {
    final note = compareNoteFor(view([
      row('Kampüs', [4.6, 3.0]),
      row('Sosyal hayat', [2.0, 4.5]),
    ]));

    expect(note.id, 'compare.split');
    expect(note.values['rowA'], 'kampüs');
    expect(note.values['rowB'], 'sosyal hayat');
  });

  test('metin yer tutucuları doldurulur', () {
    final text = compareNoteFor(view([
      row('Kampüs', [4.6, 3.0]),
      row('Sosyal hayat', [2.0, 4.5]),
    ])).text;

    expect(text.contains('{'), isFalse, reason: 'doldurulmamış yer tutucu');
    expect(text, contains('İstanbul Teknik'));
    expect(text, contains('kampüs'));
  });

  test('cümle asla emir vermez', () {
    for (final id in RobotScripts.compareNoteIds) {
      final tr = RobotScripts.compareNote(id).toLowerCase();
      expect(tr.contains('seçmelisin'), isFalse, reason: id);
      expect(tr.contains('tercih et'), isFalse, reason: id);
    }
  });

  test('id kümesi iki dilde birebir aynı ve hiçbiri boş değil', () {
    RobotScripts.languageCode = 'tr';
    final tr = RobotScripts.compareNoteIds.toSet();
    RobotScripts.languageCode = 'en';
    final en = RobotScripts.compareNoteIds.toSet();

    expect(en, tr);
    for (final id in en) {
      expect(RobotScripts.compareNote(id).trim(), isNotEmpty);
    }
  });

  test('İngilizce de aynı yer tutucuları taşır', () {
    RobotScripts.languageCode = 'en';
    final note = compareNoteFor(view([
      row('Campus', [4.6, 3.0]),
      row('Social life', [2.0, 4.5]),
    ]));

    expect(note.id, 'compare.split');
    expect(note.text.contains('{'), isFalse);
    expect(note.text, contains('campus'));
  });
}
