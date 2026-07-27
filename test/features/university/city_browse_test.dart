import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/university/domain/city_browse.dart';
import 'package:uni_app/features/university/domain/models/city_model.dart';

/// Şehir listesinin gezinme mantığı.
///
/// Kilitlenen sözleşme: bölge plaka kodundan türer (yeni alan yok), rozet
/// sayıları seçili bölgeden etkilenmez ve nüfusu bilinmeyen şehir "0
/// nüfuslu" sayılmaz.
void main() {
  CityModel city(
    String plate,
    String name, {
    int app = 1,
    int total = 1,
    int? population,
  }) =>
      CityModel(
        id: plate,
        name: name,
        plateCode: plate,
        photoUrl: '',
        totalUniversityCount: total,
        appUniversityCount: app,
        population: population,
      );

  group('regionForPlate', () {
    test('bilinen plakalar doğru bölgeye düşer', () {
      expect(regionForPlate('34'), TurkeyRegion.marmara);
      expect(regionForPlate('35'), TurkeyRegion.aegean);
      expect(regionForPlate('06'), TurkeyRegion.centralAnatolia);
      expect(regionForPlate('07'), TurkeyRegion.mediterranean);
      expect(regionForPlate('61'), TurkeyRegion.blackSea);
      expect(regionForPlate('25'), TurkeyRegion.easternAnatolia);
      expect(regionForPlate('27'), TurkeyRegion.southeasternAnatolia);
    });

    test('tek hâneli plaka iki hâneye tamamlanır', () {
      // Veride "06" da "6" da geçebiliyor.
      expect(regionForPlate('6'), regionForPlate('06'));
      expect(regionForPlate(' 1 '), TurkeyRegion.mediterranean);
    });

    test('tanınmayan plaka bölgesizdir', () {
      expect(regionForPlate('99'), isNull);
      expect(regionForPlate(''), isNull);
    });

    test('81 ilin tamamı tam bir kez eşlenir', () {
      // Tablo elle yazıldı; bir il unutulursa ya da iki bölgeye birden
      // yazılırsa rozet sayıları sessizce yanlış olur.
      final seen = <TurkeyRegion, int>{};
      for (var i = 1; i <= 81; i++) {
        final plate = i.toString().padLeft(2, '0');
        final region = regionForPlate(plate);
        expect(region, isNotNull, reason: '$plate bölgesiz kaldı');
        seen[region!] = (seen[region] ?? 0) + 1;
      }
      expect(seen.values.fold(0, (a, b) => a + b), 81);
      expect(seen.keys.length, TurkeyRegion.values.length);
    });
  });

  group('arama', () {
    final all = [
      city('34', 'İstanbul'),
      city('35', 'İzmir'),
      city('06', 'Ankara'),
      city('26', 'Eskişehir'),
    ];

    test('boş sorgu hiçbir şeyi elemez', () {
      expect(browseCities(all).cities.length, 4);
      expect(browseCities(all, query: '   ').cities.length, 4);
    });

    test('Türkçe karakter olmadan da bulunur', () {
      // Klavyeden "eskisehir" yazan da şehri bulmalı.
      final found = browseCities(all, query: 'eskisehir').cities;
      expect(found.single.name, 'Eskişehir');
    });

    test('plaka koduyla aranabilir', () {
      expect(browseCities(all, query: '34').cities.single.name, 'İstanbul');
    });
  });

  group('bölge süzgeci', () {
    final all = [
      city('34', 'İstanbul'),
      city('41', 'Kocaeli'),
      city('35', 'İzmir'),
      city('06', 'Ankara'),
    ];

    test('yalnız o bölgenin şehirleri kalır', () {
      final result = browseCities(all, region: TurkeyRegion.marmara);
      expect(result.cities.map((c) => c.name), ['İstanbul', 'Kocaeli']);
    });

    test('rozet sayıları seçili bölgeden etkilenmez', () {
      // Aksi hâlde bir bölge seçildiği anda diğer rozetler 0 görünür ve
      // rozetler gezinme aracı olmaktan çıkardı.
      final result = browseCities(all, region: TurkeyRegion.marmara);
      expect(result.regionCounts[TurkeyRegion.marmara], 2);
      expect(result.regionCounts[TurkeyRegion.aegean], 1);
      expect(result.regionCounts[TurkeyRegion.centralAnatolia], 1);
    });

    test('rozet sayıları aramayla daralır', () {
      final result = browseCities(all, query: 'İzmir');
      expect(result.regionCounts[TurkeyRegion.aegean], 1);
      expect(result.regionCounts.containsKey(TurkeyRegion.marmara), isFalse);
    });
  });

  group('sıralama', () {
    test('üniversite sayısı çoktan aza', () {
      final result = browseCities([
        city('06', 'Ankara', app: 11),
        city('34', 'İstanbul', app: 20),
        city('35', 'İzmir', app: 7),
      ]);
      expect(result.cities.map((c) => c.name), ['İstanbul', 'Ankara', 'İzmir']);
    });

    test('eşitlikte şehirdeki toplam üniversite, sonra ad', () {
      final result = browseCities([
        city('16', 'Bursa', app: 1, total: 2),
        city('01', 'Adana', app: 1, total: 2),
        city('35', 'İzmir', app: 1, total: 9),
      ]);
      expect(result.cities.map((c) => c.name), ['İzmir', 'Adana', 'Bursa']);
    });

    test('alfabetik sıralama Türkçe harf sırasına uyar', () {
      final result = browseCities(
        [city('34', 'İzmit'), city('26', 'Isparta'), city('01', 'Çorum')],
        sort: CitySort.alphabetical,
      );
      // Türkçede I < İ ve Ç, C'den sonra gelir.
      expect(result.cities.map((c) => c.name), ['Çorum', 'Isparta', 'İzmit']);
    });

    test('nüfusu bilinmeyen şehir sona düşer', () {
      // Bilinmiyor "sıfır" demek değil; listenin başında yer kaplamamalı.
      final result = browseCities(
        [
          city('11', 'Bilecik'),
          city('34', 'İstanbul', population: 15900000),
          city('06', 'Ankara', population: 5800000),
        ],
        sort: CitySort.population,
      );
      expect(
        result.cities.map((c) => c.name),
        ['İstanbul', 'Ankara', 'Bilecik'],
      );
    });
  });

  test('üniversite toplamı yalnız görünen şehirleri sayar', () {
    final result = browseCities(
      [
        city('34', 'İstanbul', app: 20),
        city('41', 'Kocaeli', app: 2),
        city('35', 'İzmir', app: 7),
      ],
      region: TurkeyRegion.marmara,
    );
    expect(result.universityCount, 22);
  });
}
