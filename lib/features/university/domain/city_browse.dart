/// Şehir listesinin ekrandan bağımsız gezinme mantığı: arama, bölge
/// süzgeci, sıralama ve sayaçlar.
///
/// Ekran 60 şehri düz bir ızgara olarak döküyordu ve tek gruplama ölçütü
/// "uygulamada 3+ üniversitesi var mı" idi — veride bunu geçen yalnız dört
/// şehir olduğu için ayrım pratikte hiçbir işe yaramıyordu. Bölge ve
/// sıralama gerçek birer daraltma yolu; ikisi de yeni alan istemiyor,
/// plaka kodundan ve elde olan sayılardan türüyor.
library;

import '../../../core/utils/turkish_compare.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'models/city_model.dart';

/// Türkiye'nin coğrafi bölgeleri.
enum TurkeyRegion {
  marmara,
  aegean,
  mediterranean,
  centralAnatolia,
  blackSea,
  easternAnatolia,
  southeasternAnatolia,
}

/// Plaka → bölge. 81 ilin tamamı burada; veri setinde şu an 60 şehir var
/// ama tablo eksiksiz ki yeni şehir eklendiğinde kod değişmesin.
const Map<TurkeyRegion, List<String>> _platesByRegion = {
  TurkeyRegion.marmara: [
    '10', '11', '16', '17', '22', '34', '39', '41', '54', '59', '77',
  ],
  TurkeyRegion.aegean: [
    '03', '09', '20', '35', '43', '45', '48', '64',
  ],
  TurkeyRegion.mediterranean: [
    '01', '07', '15', '31', '32', '33', '46', '80',
  ],
  TurkeyRegion.centralAnatolia: [
    '06', '18', '26', '38', '40', '42', '50', '51', '58', '66', '68', '70',
    '71',
  ],
  TurkeyRegion.blackSea: [
    '05', '08', '14', '19', '28', '29', '37', '52', '53', '55', '57', '60',
    '61', '67', '69', '74', '78', '81',
  ],
  TurkeyRegion.easternAnatolia: [
    '04', '12', '13', '23', '24', '25', '30', '36', '44', '49', '62', '65',
    '75', '76',
  ],
  TurkeyRegion.southeasternAnatolia: [
    '02', '21', '27', '47', '56', '63', '72', '73', '79',
  ],
};

final Map<String, TurkeyRegion> _regionByPlate = {
  for (final entry in _platesByRegion.entries)
    for (final plate in entry.value) plate: entry.key,
};

/// Şehrin bölgesi. Plaka iki hâneye tamamlanır — veride "6" da "06" da
/// geçebiliyor.
TurkeyRegion? regionForPlate(String plateCode) {
  final trimmed = plateCode.trim();
  if (trimmed.isEmpty) return null;
  return _regionByPlate[trimmed.padLeft(2, '0')];
}

TurkeyRegion? regionOf(CityModel city) => regionForPlate(city.plateCode);

String regionName(TurkeyRegion region, AppLocalizations loc) =>
    switch (region) {
      TurkeyRegion.marmara => loc.citiesRegionMarmara,
      TurkeyRegion.aegean => loc.citiesRegionAegean,
      TurkeyRegion.mediterranean => loc.citiesRegionMediterranean,
      TurkeyRegion.centralAnatolia => loc.citiesRegionCentral,
      TurkeyRegion.blackSea => loc.citiesRegionBlackSea,
      TurkeyRegion.easternAnatolia => loc.citiesRegionEastern,
      TurkeyRegion.southeasternAnatolia => loc.citiesRegionSoutheastern,
    };

String sortName(CitySort sort, AppLocalizations loc) => switch (sort) {
      CitySort.universities => loc.citiesSortUniversities,
      CitySort.alphabetical => loc.citiesSortAlphabetical,
      CitySort.population => loc.citiesSortPopulation,
    };

/// Sıralama ölçütü.
enum CitySort {
  /// Uygulamadaki üniversite sayısı (çoktan aza) — varsayılan.
  universities,
  alphabetical,

  /// Nüfusu bilinmeyen şehirler sona düşer.
  population,
}

/// Süzülmüş liste + o listeye ait sayaçlar.
class CityBrowseResult {
  final List<CityModel> cities;

  /// Bölge rozetlerinin sayıları. **Bölge süzgeci uygulanmadan** önceki
  /// (yalnız aramayla daraltılmış) küme üzerinden hesaplanır; yoksa seçili
  /// bölge dışındaki her rozet 0 görünür ve rozetler gezinme aracı olmaktan
  /// çıkardı.
  final Map<TurkeyRegion, int> regionCounts;

  const CityBrowseResult({required this.cities, required this.regionCounts});

  bool get isEmpty => cities.isEmpty;

  /// Görünen şehirlerdeki uygulama içi üniversite toplamı.
  int get universityCount =>
      cities.fold(0, (sum, c) => sum + c.appUniversityCount);
}

/// Arama + bölge + sıralama tek geçişte.
CityBrowseResult browseCities(
  List<CityModel> all, {
  String query = '',
  TurkeyRegion? region,
  CitySort sort = CitySort.universities,
}) {
  final searched = all.where((c) => _matches(c, query)).toList();

  final counts = <TurkeyRegion, int>{};
  for (final city in searched) {
    final r = regionOf(city);
    if (r != null) counts[r] = (counts[r] ?? 0) + 1;
  }

  final filtered = region == null
      ? searched
      : searched.where((c) => regionOf(c) == region).toList();

  filtered.sort(_comparator(sort));
  return CityBrowseResult(cities: filtered, regionCounts: counts);
}

bool _matches(CityModel city, String query) {
  final q = query.trim();
  if (q.isEmpty) return true;
  final lower = q.toLowerCase();
  if (city.name.toLowerCase().contains(lower)) return true;
  if (turkishNormalize(city.name.toLowerCase())
      .contains(turkishNormalize(lower))) {
    return true;
  }
  return city.plateCode.contains(q);
}

int Function(CityModel, CityModel) _comparator(CitySort sort) {
  switch (sort) {
    case CitySort.alphabetical:
      return (a, b) => turkishCompare(a.name, b.name);
    case CitySort.population:
      return (a, b) {
        // Nüfusu bilinmeyen şehir "0 nüfuslu" değil; listenin sonuna gider.
        final pa = a.population;
        final pb = b.population;
        if (pa == null && pb == null) return turkishCompare(a.name, b.name);
        if (pa == null) return 1;
        if (pb == null) return -1;
        if (pa != pb) return pb.compareTo(pa);
        return turkishCompare(a.name, b.name);
      };
    case CitySort.universities:
      return (a, b) {
        if (a.appUniversityCount != b.appUniversityCount) {
          return b.appUniversityCount.compareTo(a.appUniversityCount);
        }
        if (a.totalUniversityCount != b.totalUniversityCount) {
          return b.totalUniversityCount.compareTo(a.totalUniversityCount);
        }
        return turkishCompare(a.name, b.name);
      };
  }
}
