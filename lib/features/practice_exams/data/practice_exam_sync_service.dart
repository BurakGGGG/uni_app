import 'package:flutter/foundation.dart';

import '../domain/models/exam_target.dart';
import '../domain/models/practice_exam.dart';
import 'practice_exam_repository.dart';
import 'practice_exam_store.dart';

/// Yerel defter ile hesap yedeğini birleştirir.
///
/// Yön: yerel **her zaman** UI'ın kaynağıdır; senkron onu zenginleştirir.
/// Misafirken girilen denemeler giriş anında bu birleştirmeyle hesaba taşınır —
/// ayrı bir "migrasyon" yolu yoktur.
class PracticeExamSyncService {
  PracticeExamSyncService({
    required PracticeExamStore store,
    required PracticeExamRepository repository,
  })  : _store = store,
        _repository = repository;

  final PracticeExamStore _store;
  final PracticeExamRepository _repository;

  /// Aynı kayıt iki tarafta da varsa `updatedAt` yenisi kazanır. Yalnız bir
  /// tarafta olan kayıt olduğu gibi alınır (mezar taşları da kayıt sayılır —
  /// silmenin yayılması bunu gerektirir).
  @visibleForTesting
  static List<PracticeExam> merge(
    List<PracticeExam> local,
    List<PracticeExam> remote,
  ) {
    final byId = <String, PracticeExam>{};
    for (final exam in local) {
      if (exam.id.isEmpty) continue;
      byId[exam.id] = exam;
    }
    for (final exam in remote) {
      if (exam.id.isEmpty) continue;
      final mine = byId[exam.id];
      if (mine == null || exam.updatedAt.isAfter(mine.updatedAt)) {
        byId[exam.id] = exam;
      }
    }
    return byId.values.toList();
  }

  /// Uzağa gönderilmesi gereken kayıtlar: uzakta hiç yok ya da yereldeki daha yeni.
  @visibleForTesting
  static List<PracticeExam> toPush(
    List<PracticeExam> local,
    List<PracticeExam> remote,
  ) {
    final remoteById = {
      for (final exam in remote)
        if (exam.id.isNotEmpty) exam.id: exam,
    };
    return [
      for (final exam in local)
        if (exam.id.isNotEmpty &&
            (remoteById[exam.id] == null ||
                exam.updatedAt.isAfter(remoteById[exam.id]!.updatedAt)))
          exam,
    ];
  }

  /// Tam senkron turu. Misafirse hiçbir şey yapmaz.
  /// Birleştirilmiş (silinmemiş) listeyi döner; giriş yapılmamışsa yereli.
  Future<List<PracticeExam>> sync() async {
    if (!_repository.isSignedIn) return _store.read();

    final local = _store.readIncludingDeleted();
    final remote = await _repository.pullAll();

    final merged = merge(local, remote);
    await _store.save(merged);
    await _repository.upsertAll(toPush(local, remote));

    await _syncTarget();

    return _store.read();
  }

  /// Hedef tek dokümanda; yerel hedef varsa o yayınlanır, yoksa uzaktaki alınır.
  Future<void> _syncTarget() async {
    final local = _store.readTarget();
    final remote = await _repository.pullTarget();
    if (local == null && remote != null) {
      await _store.saveTarget(remote);
      return;
    }
    if (local != null && (remote == null || local.setAt.isAfter(remote.setAt))) {
      await _repository.pushTarget(local);
      return;
    }
    if (remote != null && local != null && remote.setAt.isAfter(local.setAt)) {
      await _store.saveTarget(remote);
    }
  }

  ExamTarget? get localTarget => _store.readTarget();
}
