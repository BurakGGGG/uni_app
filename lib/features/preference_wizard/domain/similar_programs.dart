import '../../../core/utils/turkish_compare.dart';
import '../../score_calculator/domain/models/match_result.dart';
import 'preference_match_engine.dart';

/// Zorlayıcı bir programa "benzer ama ulaşılabilir" alternatif önerisi.
///
/// İki sinyal: (a) aynı normalize isim — aynı bölümün başka üniversitedeki /
/// burslu varyantı, (b) küratörlü bölüm ailesi — öğrencilerin gerçekte ikame
/// ettiği yakın bölümler. Sonuçlar zaten bellekteki eşleşme listesinden
/// süzülür; ek Firestore okuması yok.

/// Program adını karşılaştırma anahtarına indirger: parantezli ekler atılır
/// ("(İngilizce) (Burslu)"), Türkçe karakterler ASCII'ye katlanır, noktalama
/// boşluğa çevrilir. Örn. "Elektrik-Elektronik Müh. (Burslu)" →
/// "elektrik elektronik muh". Adlar çok tekrar ettiğinden sonuç memoize edilir.
final Map<String, String> _normalizeCache = {};

String normalizeProgramName(String name) =>
    _normalizeCache[name] ??= _normalizeProgramName(name);

String _normalizeProgramName(String name) {
  var s = name.replaceAll(RegExp(r'\([^)]*\)'), ' ');
  // Dart'ta 'İ'.toLowerCase() birleşik nokta (U+0307) üretir — önce elle indir.
  s = s.replaceAll('İ', 'i').replaceAll('I', 'ı');
  s = turkishNormalize(s);
  s = s.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Küratörlü bölüm aileleri (normalize adlarla). Bir ad birden fazla ailede
/// geçebilir (örn. mekatronik) — lookup'ta aileler birleştirilir.
const List<Set<String>> _programFamilies = [
  {
    'bilgisayar muhendisligi',
    'yazilim muhendisligi',
    'bilgisayar bilimleri',
    'bilgisayar bilimi ve muhendisligi',
    'bilisim sistemleri muhendisligi',
    'yapay zeka muhendisligi',
    'yapay zeka ve veri muhendisligi',
    'yonetim bilisim sistemleri',
  },
  {
    'elektrik elektronik muhendisligi',
    'elektrik muhendisligi',
    'elektronik muhendisligi',
    'elektronik ve haberlesme muhendisligi',
    'kontrol ve otomasyon muhendisligi',
    'mekatronik muhendisligi',
  },
  {
    'makine muhendisligi',
    'makina muhendisligi',
    'mekatronik muhendisligi',
    'otomotiv muhendisligi',
    'imalat muhendisligi',
  },
  {
    'endustri muhendisligi',
    'isletme muhendisligi',
    'endustri ve sistem muhendisligi',
    'endustri sistemleri muhendisligi',
  },
  {
    'insaat muhendisligi',
    'cevre muhendisligi',
    'harita muhendisligi',
    'geomatik muhendisligi',
  },
  {
    'tip',
    'dis hekimligi',
    'eczacilik',
  },
  {
    'hemsirelik',
    'ebelik',
  },
  {
    'isletme',
    'iktisat',
    'ekonomi',
    'maliye',
    'ekonometri',
    'calisma ekonomisi ve endustri iliskileri',
    'uluslararasi ticaret',
    'uluslararasi ticaret ve lojistik',
    'uluslararasi ticaret ve finansman',
    'uluslararasi ticaret ve isletmecilik',
  },
  {
    'siyaset bilimi',
    'siyaset bilimi ve kamu yonetimi',
    'siyaset bilimi ve uluslararasi iliskiler',
    'kamu yonetimi',
    'uluslararasi iliskiler',
  },
  {
    'psikoloji',
    'rehberlik ve psikolojik danismanlik',
    'psikolojik danismanlik ve rehberlik',
  },
  {
    'mimarlik',
    'ic mimarlik',
    'ic mimarlik ve cevre tasarimi',
    'sehir ve bolge planlama',
    'peyzaj mimarligi',
  },
  {
    'gazetecilik',
    'halkla iliskiler ve tanitim',
    'halkla iliskiler ve reklamcilik',
    'radyo televizyon ve sinema',
    'yeni medya',
    'yeni medya ve iletisim',
    'iletisim',
    'iletisim bilimleri',
  },
  {
    'matematik',
    'matematik muhendisligi',
    'istatistik',
    'istatistik ve bilgisayar bilimleri',
    'aktuerya bilimleri',
  },
  {
    'kimya muhendisligi',
    'gida muhendisligi',
    'biyomuhendislik',
    'genetik ve biyomuhendislik',
    'kimya',
    'biyokimya',
    'molekuler biyoloji ve genetik',
    'biyoteknoloji',
  },
  {
    'ucak muhendisligi',
    'uzay muhendisligi',
    'ucak ve uzay muhendisligi',
    'havacilik ve uzay muhendisligi',
  },
];

/// normalize ad → aynı ailedeki tüm adlar (çok ailede geçenler birleşik).
final Map<String, Set<String>> _familyLookup = () {
  final map = <String, Set<String>>{};
  for (final family in _programFamilies) {
    for (final name in family) {
      (map[name] ??= <String>{}).addAll(family);
    }
  }
  return map;
}();

/// [source] (tipik olarak zorlayıcı bir eşleşme) için ulaşılabilir + yüksek
/// şanslı kovalardan benzer program önerileri. Aynı program tipiyle (Lisans ↔
/// Lisans) sınırlı, taban puana göre azalan, en fazla [limit] öğe.
List<UniversityMatch> similarReachable(
  UniversityMatch source,
  PreferenceMatchResult result, {
  int limit = 6,
}) {
  final srcName = normalizeProgramName(source.department.name);
  if (srcName.isEmpty) return const [];
  final family = _familyLookup[srcName];

  final picks = <UniversityMatch>[];
  final seen = <String>{source.department.id};

  for (final m in [...result.target, ...result.guaranteed]) {
    if (m.department.type != source.department.type) continue;
    if (!seen.add(m.department.id)) continue;
    final name = normalizeProgramName(m.department.name);
    final sameName = name == srcName;
    final sameFamily = family != null && family.contains(name);
    if (!sameName && !sameFamily) continue;
    picks.add(m);
  }

  picks.sort((a, b) => b.departmentBaseScore.compareTo(a.departmentBaseScore));
  return picks.length > limit ? picks.sublist(0, limit) : picks;
}
