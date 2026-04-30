// Türkçe karakter sıralama ve normalizasyon yardımcıları.

const _turkishOrder =
    'aAbBcCçÇdDeEfFgGğĞhHıIiİjJkKlLmMnNoOöÖpPrRsSşŞtTuUüÜvVwWxXyYzZ';

/// Türkçe alfabetik sıralama (Ç, İ, Ö, Ş, Ü doğru yerde).
int turkishCompare(String a, String b) {
  final la = a.toLowerCase();
  final lb = b.toLowerCase();
  for (int i = 0; i < la.length && i < lb.length; i++) {
    final ai = _turkishOrder.indexOf(la[i]);
    final bi = _turkishOrder.indexOf(lb[i]);
    if (ai == -1 || bi == -1) {
      final cmp = la[i].compareTo(lb[i]);
      if (cmp != 0) return cmp;
    } else {
      if (ai != bi) return ai - bi;
    }
  }
  return a.length - b.length;
}

/// Türkçe normalize — ıİşŞçÇöÖüÜğĞ → ASCII karşılıkları.
/// "odtü" → "odtu", "İTÜ" → "itu"
String turkishNormalize(String input) {
  return input
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');
}
