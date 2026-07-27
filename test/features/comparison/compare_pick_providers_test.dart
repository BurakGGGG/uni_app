import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_app/features/comparison/presentation/providers/compare_pick_providers.dart';
import 'package:uni_app/features/score_calculator/presentation/providers/score_calculator_providers.dart';
import 'package:uni_app/features/university/domain/models/city_model.dart';
import 'package:uni_app/features/university/domain/models/department_model.dart';
import 'package:uni_app/features/university/presentation/providers/university_providers.dart';

/// Seçim ekranının önerileri.
///
/// Kilitlenen sözleşme: bölüm önerisi "en popüler" değil **en çok
/// üniversitede açılan** bölümdür — ekranın işi aynı bölümü iki
/// üniversitede karşılaştırmak.
void main() {
  DepartmentModel dept(String uniId, String name) => DepartmentModel(
        id: '$uniId-$name',
        universityId: uniId,
        name: name,
        faculty: '',
        type: 'Lisans',
        language: 'Türkçe',
        baseScore: 400,
      );

  CityModel city(String plate, String name, int app) => CityModel(
        id: plate,
        name: name,
        plateCode: plate,
        photoUrl: '',
        totalUniversityCount: app,
        appUniversityCount: app,
      );

  test('bölüm önerileri kaç üniversitede açıldığına göre sıralanır',
      () async {
    final container = ProviderContainer(
      overrides: [
        allScoredDepartmentsProvider.overrideWith((ref) async => [
              dept('a', 'Hukuk'),
              dept('b', 'Hukuk'),
              dept('c', 'Hukuk'),
              dept('a', 'Bilgisayar Mühendisliği'),
              dept('b', 'Bilgisayar Mühendisliği'),
              // Tek üniversitede açılan bölümün bu ekranda karşılığı yok.
              dept('a', 'Uzay Mühendisliği'),
            ]),
      ],
    );
    addTearDown(container.dispose);

    final names =
        await container.read(comparePickDepartmentNamesProvider.future);

    expect(names, ['Hukuk', 'Bilgisayar Mühendisliği']);
  });

  test('aynı üniversitenin ikinci kaydı sayıyı şişirmez', () async {
    // Aynı bölüm adı bir üniversitede iki programla (İngilizce/Türkçe)
    // geçebiliyor; bu "iki üniversitede var" demek değil.
    final container = ProviderContainer(
      overrides: [
        allScoredDepartmentsProvider.overrideWith((ref) async => [
              dept('a', 'Tıp'),
              DepartmentModel(
                id: 'a-tip-en',
                universityId: 'a',
                name: 'Tıp',
                faculty: '',
                type: 'Lisans',
                language: 'İngilizce',
                baseScore: 480,
              ),
            ]),
      ],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(comparePickDepartmentNamesProvider.future),
      isEmpty,
    );
  });

  test('şehir önerileri üniversite sayısına göre gelir', () async {
    final container = ProviderContainer(
      overrides: [
        citiesProvider.overrideWith((ref) async => [
              city('41', 'Kocaeli', 2),
              city('34', 'İstanbul', 20),
              city('06', 'Ankara', 11),
            ]),
      ],
    );
    addTearDown(container.dispose);

    final cities = await container.read(comparePickCitiesProvider.future);
    expect(cities.map((c) => c.name), ['İstanbul', 'Ankara', 'Kocaeli']);
  });
}
