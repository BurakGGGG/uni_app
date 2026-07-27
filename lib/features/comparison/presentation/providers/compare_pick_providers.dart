/// Seçim ekranının önerileri.
///
/// Seçim ekranı ekranın alt yarısını boş bırakıyordu ve ilk kez giren biri
/// için tek yol koca listeyi açıp aramaktı. Öneriler yeni veri istemiyor —
/// üçü de elde olan koleksiyonlardan türüyor.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/turkish_compare.dart';
import '../../../score_calculator/presentation/providers/score_calculator_providers.dart';
import '../../../university/domain/city_browse.dart';
import '../../../university/domain/models/city_model.dart';
import '../../../university/domain/models/university_model.dart';
import '../../../university/presentation/providers/university_providers.dart';

const int kComparePickSuggestionCount = 8;

/// Popüler üniversiteler — yorum sayısına göre (bkz.
/// `popularUniversitiesProvider`).
final comparePickUniversitiesProvider =
    FutureProvider<List<UniversityModel>>((ref) async {
  final unis = await ref.watch(popularUniversitiesProvider.future);
  return unis.take(kComparePickSuggestionCount).toList();
});

/// Uygulamada en çok üniversitesi olan şehirler.
final comparePickCitiesProvider = FutureProvider<List<CityModel>>((ref) async {
  final cities = await ref.watch(citiesProvider.future);
  return browseCities(cities).cities.take(kComparePickSuggestionCount).toList();
});

/// En çok üniversitede okutulan bölüm adları.
///
/// Bu ekranın işi "aynı bölüm, iki üniversite" olduğu için doğru öneri en
/// popüler bölüm değil, **en çok yerde açılan** bölüm: karşılaştıracak
/// ikinci bir üniversite bulma olasılığı en yüksek olan.
final comparePickDepartmentNamesProvider =
    FutureProvider<List<String>>((ref) async {
  final departments = await ref.watch(allScoredDepartmentsProvider.future);

  final universitiesByName = <String, Set<String>>{};
  for (final dept in departments) {
    final name = dept.name.trim();
    if (name.isEmpty) continue;
    universitiesByName.putIfAbsent(name, () => <String>{}).add(dept.universityId);
  }

  final names = universitiesByName.keys
      // Tek üniversitede açılan bölümün bu ekranda karşılığı yok.
      .where((name) => universitiesByName[name]!.length > 1)
      .toList()
    ..sort((a, b) {
      final byCount = universitiesByName[b]!.length
          .compareTo(universitiesByName[a]!.length);
      return byCount != 0 ? byCount : turkishCompare(a, b);
    });

  return names.take(kComparePickSuggestionCount).toList();
});
