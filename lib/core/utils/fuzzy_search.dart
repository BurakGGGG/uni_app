// Bulanık (fuzzy) arama yardımcıları — "bunu mu demek istedin?" önerileri için.
//
// Yazım hatası içeren bir sorgu hiçbir sonuç döndürmediğinde, en yakın adayları
// düzenleme mesafesine (Levenshtein) göre bulmak için kullanılır.

import 'turkish_compare.dart';

/// İki dizgi arasındaki Levenshtein düzenleme mesafesi (ekle/sil/değiştir).
int levenshteinDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  var prev = List<int>.generate(b.length + 1, (i) => i);
  var curr = List<int>.filled(b.length + 1, 0);

  for (var i = 0; i < a.length; i++) {
    curr[0] = i + 1;
    for (var j = 0; j < b.length; j++) {
      final cost = a[i] == b[j] ? 0 : 1;
      final del = prev[j + 1] + 1;
      final ins = curr[j] + 1;
      final sub = prev[j] + cost;
      curr[j + 1] = del < ins
          ? (del < sub ? del : sub)
          : (ins < sub ? ins : sub);
    }
    final tmp = prev;
    prev = curr;
    curr = tmp;
  }
  return prev[b.length];
}

/// Bir sorgunun aday metinlere benzerlik skoru — düşük = daha yakın.
///
/// Türkçe normalize edilmiş sorguyu her adayın tamamı, önek'i ve tek tek
/// kelimelerine karşı en küçük düzenleme mesafesiyle karşılaştırır. Böylece
/// "boğaz" → "boğaziçi" gibi önek eşleşmeleri de yakalanır.
int fuzzyDistance(String query, Iterable<String> candidates) {
  final q = turkishNormalize(query.trim());
  if (q.isEmpty) return 1 << 30;

  var best = 1 << 30;
  for (final raw in candidates) {
    final c = turkishNormalize(raw.trim());
    if (c.isEmpty) continue;
    best = _min(best, _bestAgainst(q, c));
    if (best == 0) break;
    for (final word in c.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      best = _min(best, _bestAgainst(q, word));
      if (best == 0) break;
    }
    if (best == 0) break;
  }
  return best;
}

/// Sorgu uzunluğuna göre kabul edilebilir maksimum mesafe.
/// Kısa sorgularda 1, orta 2, uzun 3 karakterlik hataya izin verir.
bool isFuzzyMatch(int distance, int queryLength) {
  final threshold = queryLength <= 4
      ? 1
      : queryLength <= 7
          ? 2
          : 3;
  return distance <= threshold;
}

int _bestAgainst(String q, String c) {
  var d = levenshteinDistance(q, c);
  // Önek mesafesi: aday sorgudan uzunsa, adayın baş kısmıyla da karşılaştır.
  if (c.length > q.length) {
    d = _min(d, levenshteinDistance(q, c.substring(0, q.length)));
  }
  return d;
}

int _min(int a, int b) => a < b ? a : b;
