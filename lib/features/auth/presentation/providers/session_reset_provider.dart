import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../assistant/presentation/providers/assistant_providers.dart';
import '../../../home/presentation/providers/recent_searches_provider.dart';
import '../../../practice_exams/presentation/providers/practice_exam_providers.dart';
import '../../../preference_lists/presentation/providers/preference_list_providers.dart';
import '../../../preference_wizard/presentation/providers/preference_wizard_providers.dart';
import 'auth_providers.dart';

/// Hesap değişiminde cihazda kalan kullanıcıya özel **yerel** veriyi sıfırlar.
///
/// Puan profili, tercih sinyalleri, deneme defteri + hedef ve Üni'nin hafızası
/// `SharedPreferences`'ta cihaz geneli anahtarlarda durur — uid'e bağlı
/// **değil**. Çıkışta temizlenmezse bir sonraki hesapta görünür; dahası deneme
/// senkronu yereli yeni hesabın Firestore yedeğine PUSH ederek kayıtları
/// karıştırır. Bu dinleyici, oturum bir kullanıcıdan **başka bir kimliğe**
/// (başka uid ya da çıkış) geçtiğinde yereli boşaltır.
///
/// Misafir→giriş geçişini (önceki kimlik yok) bilerek ES GEÇER: misafirken
/// girilen veriler hesaba taşınmalı ([PracticeExamSyncService]). Firestore'a
/// hiç dokunmaz; yalnız yerel durumu sıfırlar. (Firestore'daki listeler zaten
/// uid'e göre süzülüyor; `myPreferenceListsProvider` auth'u izleyip yeniden
/// bağlanır.)
///
/// [UniSecApp] açılışta `ref.watch` ile hayatını başlatır; [LocaleSync] ile
/// aynı desen.
final sessionResetProvider =
    Provider<SessionReset>((ref) => SessionReset(ref));

class SessionReset {
  SessionReset(this._ref) {
    _ref.listen<AsyncValue<User?>>(
      authStateProvider,
      (_, next) => _onAuth(next.valueOrNull?.uid),
      fireImmediately: true,
    );
  }

  final Ref _ref;
  bool _seen = false;
  String? _lastUid;

  void _onAuth(String? uid) {
    if (shouldClear(seen: _seen, lastUid: _lastUid, nextUid: uid)) {
      _clearLocalUserData();
    }
    _seen = true;
    _lastUid = uid;
  }

  /// İlk gözlem asla temizlemez — dönen (giriş yapmış) kullanıcının cihaz-yerel
  /// verisi korunmalı. Sonrasında yalnız kimlik gerçekten **bir kullanıcıdan**
  /// başkasına döndüyse temizler; misafir (null) → giriş geçişi hariç tutulur.
  @visibleForTesting
  static bool shouldClear({
    required bool seen,
    required String? lastUid,
    required String? nextUid,
  }) {
    if (!seen) return false;
    if (nextUid == lastUid) return false;
    return lastUid != null;
  }

  void _clearLocalUserData() {
    // Notifier'lar durumu ANINDA sıfırlar (UI hemen tazelenir); yerel I/O
    // fire-and-forget tamamlanır. Hiçbiri Firestore'a yazmaz.
    _ref.read(studentScoreProfileProvider.notifier).clear();
    _ref.read(wizardPrefsProvider.notifier).reset();
    _ref.read(practiceExamsProvider.notifier).resetLocal();
    _ref.read(examTargetProvider.notifier).resetLocal();
    _ref.read(robotMemoryProvider).clear();
    // Son aramalar cihaz-geneli anahtarda durur; temizlenmezse bir sonraki
    // hesap önceki kullanıcının arama geçmişini görür.
    _ref.read(recentSearchesProvider.notifier).clear();
    // Sabitlenen liste id'si önceki kullanıcının listesine ait — yeni hesapta
    // hiçbir şeye denk gelmez, kalırsa "ana liste" seçimi sessizce şaşar.
    _ref.read(pinnedListProvider.notifier).clear();
  }
}
