/// Karşılaştırmanın ekrandan bağımsız görünümü.
///
/// Üniversite, bölüm ve şehir karşılaştırmaları üç ayrı veri modelinden
/// gelir ama ekranda AYNI şeyi yapar: iki (ya da üç) tarafı ölçüt ölçüt
/// yan yana koyar. Bu dosya o ortak dili tanımlar — ekranlar veri
/// modellerini değil bunu çizer, böylece bir yeri düzeltince öbürü geride
/// kalmaz.
///
/// **Kazanan ilan edilmez** (kullanıcı kararı): burada "winner" yok,
/// yalnız `leader` (bu satırda kim önde) ve `CompareVerdict` (kim kaç
/// satırda önde) var. 4 yoruma dayanarak bir üniversiteyi kazanan ilan
/// etmek yanıltıcı; karar öğrencinin.
library;

/// Karşılaştırmanın bir tarafı.
class CompareSide {
  final String id;
  final String title;

  /// İkincil satır — üniversitede şehir, bölümde üniversite adı.
  final String? subtitle;

  final String? logoUrl;

  /// Marka rengi (`"#C00000"`). Yoksa ekran kendi paletine düşer.
  final String? brandHex;

  const CompareSide({
    required this.id,
    required this.title,
    this.subtitle,
    this.logoUrl,
    this.brandHex,
  });
}

/// Tek ölçüt: her taraf için bir değer.
///
/// [values] ve [display] taraf sayısıyla aynı uzunlukta olmalı. Değeri
/// olmayan taraf `null` taşır — "0" ile "veri yok" aynı şey değildir ve
/// karıştırılırsa çubuk sıfırda dolu görünür.
class CompareRow {
  final String label;
  final List<double?> values;
  final List<String> display;

  /// Sıralamada küçük değer daha iyiyse false (ÖSYM sırası gibi).
  final bool higherIsBetter;

  /// Satırın altına düşen küçük açıklama ("2025 verisi" gibi).
  final String? hint;

  /// Bu farktan küçük ayrımlar berabere sayılır. Puanlarda 0,05 gibi bir
  /// tolerans şart — 4,38 ile 4,36 arasında "önde" demek gürültüdür.
  final double tieThreshold;

  /// Yarışmayan satır: künye bilgisi (kuruluş yılı, tür, yerleşim). Çubuk
  /// çizilmez, lider seçilmez, fark sayımına girmez. Kuruluş yılında
  /// "eski daha iyi" demek bir değer yargısıdır — ekran onu vermemeli.
  final bool comparable;

  /// Tam tabloda görünür ama "En büyük farklar"a ASLA girmez.
  ///
  /// Başka bir satırın kırılımı ya da hacim ölçüsü olanlar için: lisans ve
  /// önlisans sayısı bölüm sayısının parçası, yorum sayısı da puanın
  /// bağlamı. İşaretlenmezlerse öne çıkanlar aynı bilginin üç türevini
  /// üst üste gösteriyor.
  final bool secondary;

  const CompareRow({
    required this.label,
    required this.values,
    required this.display,
    this.higherIsBetter = true,
    this.hint,
    this.tieThreshold = 0,
    this.comparable = true,
    this.secondary = false,
  }) : assert(values.length == display.length);

  /// En az iki tarafta değer var mı — tek taraflı satır karşılaştırma değil.
  bool get hasData => values.where((v) => v != null).length >= 2;

  /// Bu ölçütte öne çıkan tarafın indeksi. Berabere, veri eksik ya da
  /// yarışmayan satırsa null.
  int? get leader {
    if (!comparable || !hasData) return null;
    int? best;
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) continue;
      if (best == null) {
        best = i;
        continue;
      }
      final current = values[best]!;
      final better = higherIsBetter ? v > current : v < current;
      if (better) best = i;
    }
    if (best == null) return null;

    // Eşiği aşan bir fark var mı? Yoksa berabere.
    final bestValue = values[best]!;
    for (var i = 0; i < values.length; i++) {
      if (i == best) continue;
      final v = values[i];
      if (v == null) continue;
      if ((bestValue - v).abs() > tieThreshold) return best;
    }
    return null;
  }

  /// Farkın büyüklüğü (0–1): en iyi ile en kötü arasındaki oransal ayrım.
  ///
  /// "En büyük farklar" bölümünün sıralaması bunu kullanıyor. **Mutlak
  /// farkla sıralanamaz** — kontenjan (binler) her zaman puanı (0–5)
  /// ezerdi. Yarışmayan ve tek taraflı satırlar 0 döner.
  double get gap {
    if (!comparable || !hasData) return 0;
    final present = values.whereType<double>().map((v) => v.abs()).toList()
      ..sort();
    final hi = present.last;
    if (hi == 0) return 0;
    return (hi - present.first) / hi;
  }

  /// Çubuk ölçeği — en büyük mutlak değer. Hepsi sıfırsa 1 (sıfıra bölme).
  double get scale {
    var max = 0.0;
    for (final v in values) {
      if (v == null) continue;
      final abs = v.abs();
      if (abs > max) max = abs;
    }
    return max == 0 ? 1 : max;
  }

  /// Tarafın çubuk oranı (0–1). Küçük iyiyse ters çevrilir ki uzun çubuk
  /// her zaman "daha iyi" anlamına gelsin.
  double fraction(int index) {
    final v = values[index];
    if (v == null) return 0;
    if (higherIsBetter) return (v.abs() / scale).clamp(0.0, 1.0);
    // Küçük iyi: en iyi (en küçük) değer tam dolu, ötekiler oranla kısa.
    var min = double.infinity;
    for (final other in values) {
      if (other != null && other.abs() < min) min = other.abs();
    }
    if (min == 0 || min == double.infinity) return 0;
    return (min / v.abs()).clamp(0.0, 1.0);
  }
}

/// Ölçüt kümesi — "Sayılarla", "Öğrenci puanları" gibi.
class CompareGroup {
  final String title;
  final List<CompareRow> rows;

  /// Grup boşken gösterilecek açıklama (ör. "Henüz yorum yok").
  final String? emptyNote;

  const CompareGroup({
    required this.title,
    required this.rows,
    this.emptyNote,
  });

  /// Yalnız karşılaştırılabilir satırlar — tek taraflı veri ekranda
  /// yanıltıcı bir çubuk çizerdi.
  List<CompareRow> get present => rows.where((r) => r.hasData).toList();

  bool get isEmpty => present.isEmpty;
}

/// Fark özeti: kim kaç ölçütte önde.
///
/// Kasten "kazanan" değil. Ekranda "İTÜ 5 ölçütte, ODTÜ 3 ölçütte önde"
/// diye okunur; kupa yok.
class CompareVerdict {
  /// Taraf başına önde olunan ölçüt sayısı.
  final List<int> leads;
  final int tied;

  const CompareVerdict({required this.leads, required this.tied});

  int get compared => leads.fold(0, (a, b) => a + b) + tied;

  bool get hasData => compared > 0;

  /// Belirgin biçimde önde olan taraf — Üni'nin cümlesini seçmek için.
  /// İki katı kadar öndeyse ve en az iki ölçüt farkı varsa dolu döner.
  /// **Bu bir kazanan ilanı değildir**, yalnız hangi metnin yazılacağını
  /// belirler.
  int? get clearLead {
    if (leads.length < 2) return null;
    final sorted = List.generate(leads.length, (i) => i)
      ..sort((a, b) => leads[b].compareTo(leads[a]));
    final top = sorted[0];
    final second = sorted[1];
    if (leads[top] - leads[second] < 2) return null;
    return top;
  }
}

/// Bir karşılaştırmanın tamamı.
class ComparisonView {
  final List<CompareSide> sides;
  final List<CompareGroup> groups;

  const ComparisonView({required this.sides, required this.groups});

  List<CompareRow> get allRows => [
        for (final g in groups) ...g.present,
      ];

  CompareVerdict get verdict {
    final leads = List<int>.filled(sides.length, 0);
    var tied = 0;
    for (final row in allRows) {
      if (!row.comparable) continue;
      final leader = row.leader;
      if (leader == null) {
        tied++;
      } else {
        leads[leader]++;
      }
    }
    return CompareVerdict(leads: leads, tied: tied);
  }

  /// Ekranın açılışta gösterdiği ölçütler: her gruptan farkı en büyük
  /// [perGroup] satır.
  ///
  /// Karşılaştırmanın değeri FARKTA; 18 satırın çoğunda iki taraf zaten
  /// birbirine yakın ve ekranın büyük kısmı "fark yok" demek için
  /// harcanıyordu (kullanıcı geri bildirimi: "sürekli aşağı akan ekran").
  /// Gruptan pay ayrılıyor çünkü tek havuzda binlerle ölçülen satırlar
  /// (kontenjan, bölüm sayısı) 0–5 ölçeğindeki puanları listeden atardı.
  List<CompareRow> highlights({int perGroup = 3}) {
    final out = <CompareRow>[];
    for (final group in groups) {
      final ranked = group.present
          .where((r) => !r.secondary && r.gap > 0)
          .toList()
        ..sort((a, b) => b.gap.compareTo(a.gap));
      out.addAll(ranked.take(perGroup));
    }
    return out;
  }

  /// Bir tarafın en belirgin üstünlüğü — Üni'nin "kampüs önemliyse A"
  /// cümlesi buradan besleniyor. Fark oranı en büyük satırı seçer;
  /// mutlak farkla seçilseydi ölçek büyük olan satır (kontenjan gibi)
  /// her zaman kazanırdı.
  CompareRow? strongestFor(int index) {
    CompareRow? best;
    var bestRatio = 0.0;
    for (final row in allRows) {
      if (!row.comparable || row.leader != index) continue;
      final own = row.values[index];
      if (own == null || own == 0) continue;
      var rival = 0.0;
      for (var i = 0; i < row.values.length; i++) {
        if (i == index) continue;
        final v = row.values[i];
        if (v != null && v.abs() > rival) rival = v.abs();
      }
      if (rival == 0) continue;
      final ratio = (own.abs() - rival).abs() / rival;
      if (ratio > bestRatio) {
        bestRatio = ratio;
        best = row;
      }
    }
    return best;
  }
}
