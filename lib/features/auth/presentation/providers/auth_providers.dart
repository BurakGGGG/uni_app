import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../data/auth_repository.dart';
import '../../domain/user_model.dart';
import '../../../../services/analytics_service.dart';

/// AuthRepository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Firebase Auth state stream — giriş/çıkış dinleme
final authStateProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges.asyncMap((user) async {
    if (user != null) {
      await repository.cacheAuthSession(user.uid);
    } else if (kDebugMode) {
      debugPrint('[Auth] authStateChanges → null');
    }
    return user;
  });
});

/// Mevcut kullanıcı profili (Firestore'dan)
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  ref.keepAlive();
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) async {
      if (user == null) {
        // Kullanıcı çıkış yaptı — analytics'i temizle
        await AnalyticsService().clearUserContext();
        return null;
      }
      final profile = await ref
          .read(authRepositoryProvider)
          .getUserProfile(user.uid);
      // Crashlytics & Analytics bağlamını ayarla
      if (profile != null) {
        await AnalyticsService().setUserContext(
          userId: profile.uid,
          tier: 'free', // Tier bilgisi subscription provider'dan gelecek
          isVerifiedStudent: profile.isVerifiedStudent,
        );
      }
      return profile;
    },
    loading: () => null,
    error: (e, st) => null,
  );
});

/// Uygulama dilini kullanıcı dokümanına yansıtır — sunucudan gönderilen
/// Üni hatırlatmaları kullanıcının dilinde yazılsın diye.
///
/// Hem dil değiştiğinde hem oturum açıldığında tetiklenir; yazılan değer
/// hatırlandığı için (`_lastSynced`) rebuild başına tekrar yazılmaz.
/// Yaşamı [UniSecApp] tarafından okunarak başlatılır.
final localeSyncProvider = Provider<LocaleSync>((ref) => LocaleSync(ref));

class LocaleSync {
  final Ref _ref;
  String? _lastSynced;

  LocaleSync(this._ref) {
    _ref.listen<Locale>(
      localeProvider,
      (_, next) => _sync(next.languageCode),
      fireImmediately: true,
    );
    _ref.listen<AsyncValue<UserModel?>>(
      currentUserProvider,
      (_, _) => _sync(_ref.read(localeProvider).languageCode),
      fireImmediately: true,
    );
  }

  void _sync(String locale) {
    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    final key = '${user.uid}_$locale';
    if (_lastSynced == key) return;
    _lastSynced = key;
    if (user.locale == locale) return;

    _ref
        .read(authRepositoryProvider)
        .updateLocale(uid: user.uid, locale: locale);
  }
}

final currentUserAdminProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return false;

  return ref
      .read(authRepositoryProvider)
      .isCurrentUserAdmin(forceRefresh: true);
});

/// Auth işlemleri için controller
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AsyncValue.data(null));

  /// Google ile giriş
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signInWithGoogle();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Email/şifre ile giriş
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repository.signInWithEmail(email: email, password: password);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Email/şifre ile kayıt
  Future<void> registerWithEmail(
    String name,
    String email,
    String password,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _repository.registerWithEmail(
        name: name,
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Şifre sıfırlama
  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      await _repository.resetPassword(email);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Çıkış yap
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Hesabı sil
  Future<void> deleteAccount({String? password}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteAccount(password: password);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// AuthController provider
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
      return AuthController(ref.watch(authRepositoryProvider));
    });
