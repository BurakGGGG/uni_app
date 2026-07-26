import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/practice_exam_repository.dart';
import '../../data/practice_exam_store.dart';
import '../../data/practice_exam_sync_service.dart';
import '../../domain/models/exam_target.dart';
import '../../domain/models/practice_exam.dart';
import '../../domain/practice_exam_analytics.dart';

/// Store — `sharedPreferencesProvider` main.dart'ta override edilir.
final practiceExamStoreProvider = Provider<PracticeExamStore>((ref) {
  return PracticeExamStore(ref.watch(sharedPreferencesProvider));
});

final practiceExamRepositoryProvider = Provider<PracticeExamRepository>((ref) {
  return PracticeExamRepository();
});

final practiceExamSyncServiceProvider =
    Provider<PracticeExamSyncService>((ref) {
  return PracticeExamSyncService(
    store: ref.watch(practiceExamStoreProvider),
    repository: ref.watch(practiceExamRepositoryProvider),
  );
});

/// Deneme defteri. Yazmalar önce yerele düşer (anlık UI), ardından
/// fire-and-forget hesap yedeğine gider.
class PracticeExamNotifier extends StateNotifier<List<PracticeExam>> {
  PracticeExamNotifier(this._store, this._repository)
      : super(_store.read()) {
    _migrate();
  }

  final PracticeExamStore _store;
  final PracticeExamRepository _repository;

  Future<void> _migrate() async {
    final moved = await _store.migrateFromLegacy();
    if (moved > 0) {
      state = _store.read();
      debugPrint('[PracticeExams] $moved eski kayıt taşındı');
    }
  }

  Future<void> add(PracticeExam exam) async {
    state = _store.readIncludingDeleted();
    await _persist([exam, ...state]);
    unawaited(_repository.upsert(exam));
  }

  Future<void> update(PracticeExam exam) async {
    final touched = exam.copyWith(updatedAt: DateTime.now());
    await _persist([
      for (final e in _store.readIncludingDeleted())
        if (e.id == touched.id) touched else e,
    ]);
    unawaited(_repository.upsert(touched));
  }

  Future<void> rename(String id, String name) async {
    final exam = _byId(id);
    if (exam == null) return;
    await update(exam.copyWith(name: name));
  }

  /// Silme mezar taşı bırakır; senkron bunu diğer cihazlara taşır.
  Future<void> remove(String id) async {
    final exam = _byId(id);
    if (exam == null) return;
    final tombstone = exam.copyWith(deleted: true, updatedAt: DateTime.now());
    await _persist([
      for (final e in _store.readIncludingDeleted())
        if (e.id == id) tombstone else e,
    ]);
    unawaited(_repository.upsert(tombstone));
  }

  Future<void> clear() async {
    final all = _store.readIncludingDeleted();
    final now = DateTime.now();
    final tombstones = [
      for (final e in all)
        if (e.deleted) e else e.copyWith(deleted: true, updatedAt: now),
    ];
    await _persist(tombstones);
    unawaited(_repository.upsertAll(tombstones));
  }

  /// Oturum değişiminde yereli boşaltır. [clear]'dan farkı: kayıtları SİLMEZ,
  /// yalnız cihazdan düşürür — Firestore'a mezar taşı YAZMAZ, uzak yedek
  /// olduğu gibi kalır. Böylece bir sonraki hesap, önceki kullanıcının
  /// denemelerini ne görür ne de (senkronun push'uyla) kendi yedeğine karıştırır.
  Future<void> resetLocal() async {
    await _store.clearLocalSession();
    state = const [];
  }

  /// Giriş sonrası / açılışta çağrılır: yerel ve uzak defteri birleştirir.
  Future<void> sync(PracticeExamSyncService service) async {
    final merged = await service.sync();
    state = merged;
  }

  PracticeExam? _byId(String id) {
    for (final e in _store.readIncludingDeleted()) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<void> _persist(List<PracticeExam> all) async {
    await _store.save(all);
    state = _store.read();
  }
}

final practiceExamsProvider =
    StateNotifierProvider<PracticeExamNotifier, List<PracticeExam>>((ref) {
  return PracticeExamNotifier(
    ref.watch(practiceExamStoreProvider),
    ref.watch(practiceExamRepositoryProvider),
  );
});

/// Hedef program. Yerel yazılır, giriş yapılmışsa hesaba da yansır.
class ExamTargetNotifier extends StateNotifier<ExamTarget?> {
  ExamTargetNotifier(this._store, this._repository) : super(_store.readTarget());

  final PracticeExamStore _store;
  final PracticeExamRepository _repository;

  Future<void> setTarget(ExamTarget target) async {
    state = target;
    await _store.saveTarget(target);
    unawaited(_repository.pushTarget(target));
  }

  Future<void> clearTarget() async {
    state = null;
    await _store.clearTarget();
    unawaited(_repository.pushTarget(null));
  }

  /// Oturum değişiminde yerel hedefi düşürür — Firestore'a dokunmaz.
  /// (Yerel depo `clearLocalSession` ile birlikte zaten temizleniyor; bu
  /// yalnız bellekteki durumu sıfırlar.)
  void resetLocal() => state = null;

  void adopt(ExamTarget? target) => state = target;
}

final examTargetProvider =
    StateNotifierProvider<ExamTargetNotifier, ExamTarget?>((ref) {
  return ExamTargetNotifier(
    ref.watch(practiceExamStoreProvider),
    ref.watch(practiceExamRepositoryProvider),
  );
});

/// Giriş yapıldığında bir kez senkron turu döner. Ekranlar bunu `watch`
/// etmek zorunda değil — `PracticeExamsScreen` tetiklemesi yeter.
final practiceExamSyncProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return;
  final service = ref.read(practiceExamSyncServiceProvider);
  await ref.read(practiceExamsProvider.notifier).sync(service);
  ref.read(examTargetProvider.notifier).adopt(service.localTarget);
});

/// Haftalık deneme serisi — profil kartı ve denemeler ekranı paylaşır.
final examStreakProvider = Provider<int>((ref) {
  return weeklyStreak(ref.watch(practiceExamsProvider));
});

/// Defterde en çok kullanılan puan türü; grafik varsayılanı.
final dominantScoreTypeProvider = Provider<String?>((ref) {
  return dominantScoreType(ref.watch(practiceExamsProvider));
});

/// Daha önce girilen yayın adları — kaydetme sayfasında öneri olarak sunulur.
final knownPublishersProvider = Provider<List<String>>((ref) {
  final seen = <String>{};
  for (final exam in ref.watch(practiceExamsProvider)) {
    final name = exam.publisher.trim();
    if (name.isNotEmpty) seen.add(name);
  }
  return seen.toList()..sort();
});
