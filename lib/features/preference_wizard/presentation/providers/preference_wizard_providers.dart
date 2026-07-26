import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../score_calculator/presentation/providers/score_calculator_providers.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../data/student_profile_store.dart';
import '../../domain/models/student_score_profile.dart';
import '../../domain/models/wizard_filter.dart';
import '../../domain/models/wizard_prefs.dart';
import '../../domain/preference_match_engine.dart';
import '../../domain/rank_estimator.dart';

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

/// Kalıcı yumuşak tercih sinyalleri (şehir/tip/ilgi) — girişteki opsiyonel
/// "Tercihlerin" bölümünden. Sert filtre değildir; sıralamada öne çeker.
class WizardPrefsNotifier extends StateNotifier<WizardPrefs> {
  WizardPrefsNotifier(this._store) : super(_store.readWizardPrefs());

  final StudentProfileStore _store;

  Future<void> save(WizardPrefs prefs) async {
    state = prefs;
    await _store.saveWizardPrefs(prefs);
  }

  /// Oturum değişiminde yumuşak tercih sinyallerini (şehir/tip/ilgi) sıfırlar —
  /// önceki kullanıcının şehri yeni hesabın sıralamasını öne çekmesin.
  Future<void> reset() async {
    state = const WizardPrefs();
    await _store.clearWizardPrefs();
  }
}

final wizardPrefsProvider =
    StateNotifierProvider<WizardPrefsNotifier, WizardPrefs>(
  (ref) => WizardPrefsNotifier(ref.watch(studentProfileStoreProvider)),
);

/// Puan → tahmini sıra eğrisi. Toplu bölüm verisinden bir kez kurulur
/// (keepAlive) — puanla giren öğrencinin sırası buradan tahmin edilir ve
/// eşleştirme sıra-bazlı (birincil yol) yapılır.
final rankEstimatorProvider = FutureProvider<RankEstimator>((ref) async {
  final allDepts = await ref.watch(allScoredDepartmentsProvider.future);
  return RankEstimator.fromDepartments(allDepts);
});

/// Yıl bazlı puan → sıra eğrileri (2022–2025). Puan hesaplamanın yıl
/// karşılaştırması ve resmî ÖSYM tablosu olmayan durumlar için yedek.
final multiYearRankEstimatorProvider =
    FutureProvider<MultiYearRankEstimator>((ref) async {
  final allDepts = await ref.watch(allScoredDepartmentsProvider.future);
  return MultiYearRankEstimator.fromDepartments(allDepts);
});

/// Profil + filtreye göre kategorize eşleştirme sonucu.
/// Profil yoksa null döner (UI giriş ekranını gösterir).
final preferenceMatchResultProvider =
    FutureProvider.autoDispose<PreferenceMatchResult?>((ref) async {
  final profile = ref.watch(studentScoreProfileProvider);
  if (profile == null || profile.scoreType.isEmpty) return null;

  final filter = ref.watch(wizardFilterProvider);
  final prefs = ref.watch(wizardPrefsProvider);
  final allDepts = await ref.watch(allScoredDepartmentsProvider.future);
  final allUnis = await ref.watch(allUniversitiesProvider.future);
  final estimator = await ref.watch(rankEstimatorProvider.future);

  return PreferenceMatchEngine.matchAllPrograms(
    profile: profile,
    allDepartments: allDepts,
    allUniversities: allUnis,
    filter: filter,
    estimator: estimator,
    prefs: prefs,
  );
});
