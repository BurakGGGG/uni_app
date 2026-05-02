/// Türkçe küfür/hakaret filtresi.
///
/// Leet-speak varyantlarını ve harf değiştirme oyunlarını yakalar,
/// kelime sınırı kontrolü ile false-positive'leri önler.
class ProfanityFilter {
  ProfanityFilter._();

  // ─── Leet-speak & karakter eşleme tablosu ───────────────────────
  static const _leetMap = {
    'a': r'[a@4àáâãäå]',
    'b': r'[b8]',
    'c': r'[cç¢©]',
    'ç': r'[çc¢©]',
    'd': r'[d]',
    'e': r'[e3€èéêë]',
    'f': r'[f]',
    'g': r'[gğ9]',
    'ğ': r'[ğg9]',
    'h': r'[h#]',
    'i': r'[iı1!|ìíîï]',
    'ı': r'[ıi1!|]',
    'j': r'[j]',
    'k': r'[k]',
    'l': r'[l1|]',
    'm': r'[m]',
    'n': r'[n]',
    'o': r'[oö0òóôõ]',
    'ö': r'[öo0]',
    'p': r'[p]',
    'r': r'[r]',
    's': r'[sş\$5]',
    'ş': r'[şs\$5]',
    't': r'[t7+]',
    'u': r'[uü]',
    'ü': r'[üu]',
    'v': r'[v]',
    'y': r'[y]',
    'z': r'[z2]',
  };

  /// Normalize edilmiş Türkçe küfür/hakaret kelimeleri.
  ///
  /// Bu liste yalnızca filtreleme amacıyla kullanılır ve
  /// küfür/hakaretlerin normalleştirilmiş hallerini içerir.
  static const List<String> _bannedWords = [
    // ─── Yaygın küfürler ──────────────────────────────────────────
    'amcık',
    'amına',
    'amınakoyayım',
    'amk',
    'ananı',
    'ananın',
    'ananızın',
    'angut',
    'aptal',
    'avradını',
    'aşağılık',
    // ─── B ────────────────────────────────────────────────────────
    'beyinsiz',
    'bok',
    'boktan',
    // ─── D ────────────────────────────────────────────────────────
    'dangalak',
    'dalyarak',
    'dingil',
    'döl',
    'dölü',
    'düdük',
    // ─── E ────────────────────────────────────────────────────────
    'embesil',
    'enayi',
    'enik',
    // ─── G ────────────────────────────────────────────────────────
    'gavat',
    'gerizekalı',
    'gerzek',
    'göt',
    'götlek',
    'götünü',
    'götü',
    'götveren',
    // ─── H ────────────────────────────────────────────────────────
    'haysiyetsiz',
    'hayvan',
    'herif',
    'hıyar',
    // ─── İ ────────────────────────────────────────────────────────
    'ibne',
    'irin',
    'itle',
    // ─── K ────────────────────────────────────────────────────────
    'kahpe',
    'kaltak',
    'kevaşe',
    'kıç',
    'kodumun',
    'koduğumun',
    'koyayım',
    // ─── L ────────────────────────────────────────────────────────
    'lan',
    'lavuk',
    // ─── M ────────────────────────────────────────────────────────
    'mal',
    'manyak',
    'memeleri',
    // ─── O ────────────────────────────────────────────────────────
    'orospu',
    'orospuçocuğu',
    'orospunun',
    'oç',
    // ─── P ────────────────────────────────────────────────────────
    'pezevenk',
    'piç',
    'pipi',
    'pislik',
    'puşt',
    // ─── S ────────────────────────────────────────────────────────
    'salak',
    'serefsiz',
    'şerefsiz',
    'sik',
    'sikeyim',
    'sikerim',
    'sikik',
    'sikişmek',
    'sikiş',
    'siktir',
    'siktirin',
    'sürtük',
    // ─── T ────────────────────────────────────────────────────────
    'taşak',
    'taşşak',
    'top',
    'topaç',
    // ─── Y ────────────────────────────────────────────────────────
    'yarak',
    'yarrak',
    'yarram',
    'yavşak',
    // ─── Z ────────────────────────────────────────────────────────
    'zıkkım',
    'züppeli',
  ];

  /// Kelime-sınırı korumalı regex önbelleği.
  ///
  /// Her banned kelime için, leet-speak varyantlarına duyarlı
  /// bir [RegExp] üretir ve önbelleğe alır.
  static final List<RegExp> _patterns = _buildPatterns();

  static List<RegExp> _buildPatterns() {
    return _bannedWords.map((word) {
      final buf = StringBuffer();
      for (final ch in word.split('')) {
        final mapped = _leetMap[ch];
        if (mapped != null) {
          buf.write(mapped);
          // Opsiyonel ayırıcı: "s.i.k" / "s-i-k" / "s i k" gibi yazımları yakala
          buf.write(r'[\s.\-_*]*');
        } else {
          buf.write(RegExp.escape(ch));
          buf.write(r'[\s.\-_*]*');
        }
      }

      // Son opsiyonel ayırıcıyı kaldır (zaten kelimenin sonu)
      var pattern = buf.toString();
      if (pattern.endsWith(r'[\s.\-_*]*')) {
        pattern = pattern.substring(0, pattern.length - r'[\s.\-_*]*'.length);
      }

      // Kelime sınırı: alfanumerik olmayan veya string başı/sonu
      return RegExp(
        r'(?<![a-zA-ZğüşöçıİĞÜŞÖÇ])' + pattern + r'(?![a-zA-ZğüşöçıİĞÜŞÖÇ])',
        caseSensitive: false,
        unicode: true,
      );
    }).toList(growable: false);
  }

  /// Verilen [text] içinde küfür/hakaret bulunup bulunmadığını kontrol eder.
  ///
  /// ```dart
  /// ProfanityFilter.containsProfanity('merhaba');      // false
  /// ProfanityFilter.containsProfanity('s1kt1r');       // true
  /// ProfanityFilter.containsProfanity('sıkıştır');     // false  (false-positive yok)
  /// ```
  static bool containsProfanity(String text) {
    if (text.trim().isEmpty) return false;
    final normalized = _normalize(text);
    return _patterns.any((regex) => regex.hasMatch(normalized));
  }

  /// Küfür/hakaret kelimelerini `***` ile maskeler.
  ///
  /// Küfür yoksa `null` döner (orijinal metni olduğu gibi kullanın).
  /// Küfür varsa maskelenmiş versiyonu döner.
  static String? sanitize(String text) {
    if (text.trim().isEmpty) return null;
    final normalized = _normalize(text);

    var result = text;
    var found = false;

    for (final regex in _patterns) {
      // Normalized metin üzerinde eşleşme bul,
      // orijinal metinde aynı pozisyonda maskele.
      for (final match in regex.allMatches(normalized)) {
        found = true;
        // Orijinal metindeki aynı bölgeyi maskele
        final start = match.start;
        final end = match.end;
        if (start < result.length && end <= result.length) {
          result = result.replaceRange(start, end, '***');
        }
      }
    }

    return found ? result : null;
  }

  /// Metni normalize eder:  küçük harf + Türkçe karakter korumalı.
  static String _normalize(String text) {
    return text.toLowerCase();
  }
}
