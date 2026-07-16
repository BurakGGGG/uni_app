import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../score_calculator/presentation/providers/score_calculator_providers.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../data/student_profile_store.dart';
import '../../domain/models/student_score_profile.dart';
import '../../domain/models/wizard_filter.dart';
import '../../domain/preference_match_engine.dart';

/// Store — `sharedPreferencesProvider` main.dart'ta override edilir.
final studentProfileStoreProvider = Provider<StudentProfileStore>((ref) {
  return StudentProfileStore(ref.watch(sharedPreferencesProvider));
});

/// Kalıcı öğrenci puan/sıralama profili (null = henüz kaydedilmemiş).
class StudentScoreProfileNotifier extends StateNotifier<StudentScoreProfile?> {
  StudentScoreProfileNotifier(this._store) : super(_store.read());

  final StudentProfileStore _store;

  Future<void> save(StudentScoreProfile profile) async {
    state = profile;
    await _store.save(profile);
  }

  Future<void> clear() async {
    state = null;
    await _store.clear();
  }
}

final studentScoreProfileProvider =
    StateNotifierProvider<StudentScoreProfileNotifier, StudentScoreProfile?>(
  (ref) => StudentScoreProfileNotifier(ref.watch(studentProfileStoreProvider)),
);

/// Robot sonuç filtreleri (StateProvider — UI'dan güncellenir).
final wizardFilterProvider = StateProvider<WizardFilter>((ref) {
  return const WizardFilter();
});

/// Profil + filtreye göre kategorize eşleştirme sonucu.
/// Profil yoksa null döner (UI giriş ekranını gösterir).
final preferenceMatchResultProvider =
    FutureProvider.autoDispose<PreferenceMatchResult?>((ref) async {
  final profile = ref.watch(studentScoreProfileProvider);
  if (profile == null || profile.scoreType.isEmpty) return null;

  final filter = ref.watch(wizardFilterProvider);
  final allDepts = await ref.watch(allScoredDepartmentsProvider.future);
  final allUnis = await ref.watch(allUniversitiesProvider.future);

  return PreferenceMatchEngine.matchAllPrograms(
    profile: profile,
    allDepartments: allDepts,
    allUniversities: allUnis,
    filter: filter,
  );
});
