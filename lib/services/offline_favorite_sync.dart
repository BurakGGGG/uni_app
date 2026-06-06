import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/favorites/data/favorites_repository.dart';

/// Çevrimdışı favori senkronizasyon servisi.
///
/// Kullanıcı offline iken favori ekleme/çıkarma işlemlerini
/// yerel kuyruğa kaydeder, internet geldiğinde otomatik olarak
/// Firestore'a senkronize eder.
///
/// Kullanım:
/// ```dart
/// final syncService = OfflineFavoriteSync(prefs, repo);
///
/// // Offline iken
/// await syncService.queueAdd(uid, uniId);
///
/// // Online olunca
/// await syncService.syncPendingActions(uid);
/// ```
class OfflineFavoriteSync {
  static const _queueKey = 'offline_favorites_queue';

  final SharedPreferences _prefs;
  final FavoritesRepository _repository;
  bool _isSyncing = false;

  OfflineFavoriteSync(this._prefs, this._repository);

  // ═══════════════════════════════════════════════════════════════
  //  Kuyruğa Ekleme (Offline İşlemler)
  // ═══════════════════════════════════════════════════════════════

  /// Favori ekleme işlemini kuyruğa ekle.
  Future<void> queueAdd(String uid, String universityId) async {
    await _addToQueue(_PendingAction(
      type: _ActionType.add,
      uid: uid,
      universityId: universityId,
      timestamp: DateTime.now(),
    ));
    debugPrint('[OfflineSync] Queued ADD: $universityId');
  }

  /// Favori çıkarma işlemini kuyruğa ekle.
  Future<void> queueRemove(String uid, String universityId) async {
    // Aynı üniversite için daha önceki bir ADD varsa, ikisini de iptal et
    final queue = _getQueue();
    queue.removeWhere(
      (a) => a.universityId == universityId && a.uid == uid && a.type == _ActionType.add,
    );
    
    // Hâlâ remove kuyruğa eklenmeli (sunucuda ekliyse silinmeli)
    queue.add(_PendingAction(
      type: _ActionType.remove,
      uid: uid,
      universityId: universityId,
      timestamp: DateTime.now(),
    ));

    await _saveQueue(queue);
    debugPrint('[OfflineSync] Queued REMOVE: $universityId');
  }

  // ═══════════════════════════════════════════════════════════════
  //  Senkronizasyon
  // ═══════════════════════════════════════════════════════════════

  /// Bekleyen işlem var mı?
  bool get hasPendingActions => _getQueue().isNotEmpty;

  /// Bekleyen işlem sayısı.
  int get pendingCount => _getQueue().length;

  /// Tüm bekleyen işlemleri senkronize eder.
  ///
  /// Her bir işlem bağımsız try-catch ile sarılır, böylece
  /// birinin başarısız olması diğerlerini engellemez.
  Future<SyncResult> syncPendingActions(String uid) async {
    if (_isSyncing) {
      return SyncResult(synced: 0, failed: 0, message: 'Sync already in progress');
    }
    
    final queue = _getQueue();
    if (queue.isEmpty) {
      return SyncResult(synced: 0, failed: 0, message: 'No pending actions');
    }

    _isSyncing = true;
    int synced = 0;
    int failed = 0;
    final failedActions = <_PendingAction>[];

    debugPrint('[OfflineSync] Syncing ${queue.length} pending actions...');

    for (final action in queue) {
      // Sadece bu kullanıcının işlemleri
      if (action.uid != uid) {
        failedActions.add(action);
        continue;
      }

      try {
        if (action.type == _ActionType.add) {
          await _repository.addFavorite(uid, action.universityId);
        } else {
          await _repository.removeFavorite(uid, action.universityId);
        }
        synced++;
      } catch (e) {
        debugPrint('[OfflineSync] Failed to sync ${action.type.name} ${action.universityId}: $e');
        failed++;
        failedActions.add(action);
      }
    }

    // Başarısız olanları tekrar kuyruğa al
    await _saveQueue(failedActions);
    _isSyncing = false;

    debugPrint('[OfflineSync] Sync complete: $synced synced, $failed failed');
    return SyncResult(synced: synced, failed: failed);
  }

  /// Tüm kuyruğu temizle (kullanıcı çıkışında).
  Future<void> clearQueue() async {
    await _prefs.remove(_queueKey);
    debugPrint('[OfflineSync] Queue cleared');
  }

  // ═══════════════════════════════════════════════════════════════
  //  Kuyruk Yönetimi (SharedPreferences)
  // ═══════════════════════════════════════════════════════════════

  List<_PendingAction> _getQueue() {
    final raw = _prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => _PendingAction.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[OfflineSync] Queue parse error: $e');
      return [];
    }
  }

  Future<void> _saveQueue(List<_PendingAction> queue) async {
    final raw = jsonEncode(queue.map((a) => a.toJson()).toList());
    await _prefs.setString(_queueKey, raw);
  }

  Future<void> _addToQueue(_PendingAction action) async {
    final queue = _getQueue();
    // Aynı üniversite + aynı işlem zaten varsa tekrar ekleme
    final exists = queue.any(
      (a) => a.universityId == action.universityId && 
             a.uid == action.uid && 
             a.type == action.type,
    );
    if (!exists) {
      queue.add(action);
      await _saveQueue(queue);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  Senkronizasyon sonucu
// ═══════════════════════════════════════════════════════════════

class SyncResult {
  final int synced;
  final int failed;
  final String? message;

  const SyncResult({
    required this.synced,
    required this.failed,
    this.message,
  });

  bool get hasFailures => failed > 0;
  bool get isSuccess => synced > 0 && failed == 0;
}

// ═══════════════════════════════════════════════════════════════
//  İşlem türleri ve veri modeli
// ═══════════════════════════════════════════════════════════════

enum _ActionType { add, remove }

class _PendingAction {
  final _ActionType type;
  final String uid;
  final String universityId;
  final DateTime timestamp;

  const _PendingAction({
    required this.type,
    required this.uid,
    required this.universityId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'uid': uid,
        'universityId': universityId,
        'timestamp': timestamp.toIso8601String(),
      };

  factory _PendingAction.fromJson(Map<String, dynamic> json) {
    return _PendingAction(
      type: json['type'] == 'add' ? _ActionType.add : _ActionType.remove,
      uid: json['uid'] as String,
      universityId: json['universityId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
