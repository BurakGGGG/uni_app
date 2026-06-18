import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/user_model.dart';
import '../../notifications/data/fcm_service.dart';
import '../../../services/auth_storage_service.dart';
import '../../../services/revenuecat_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../admin/data/analytics_service.dart';
import '../../admin/domain/models/analytics_event.dart';

/// Auth işlemlerini yöneten repository
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final GoogleSignIn _googleSignIn;

  // In-memory cache
  UserModel? _cachedUser;
  DateTime? _lastCacheTime;
  static const _cacheTtl = Duration(minutes: 2);

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
       _googleSignIn =
           googleSignIn ??
           GoogleSignIn(serverClientId: AppConstants.googleWebClientId);

  /// Auth state stream — giriş/çıkış dinleme
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Mevcut Firebase kullanıcısı
  User? get currentUser => _auth.currentUser;

  bool get currentUserUsesPasswordProvider {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((info) => info.providerId == 'password');
  }

  Future<bool> isCurrentUserAdmin({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final token = await user.getIdTokenResult(forceRefresh);
    return token.claims?['admin'] == true;
  }

  /// SharedPreferences'a son giriş yapan kullanıcıyı yazar.
  Future<void> cacheAuthSession(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.persistedAuthUidKey, uid);
  }

  /// Çıkışta veya oturum geçersiz olduğunda önbelleği temizler.
  Future<void> clearAuthSessionCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.persistedAuthUidKey);
  }

  /// Soğuk başlangıçta kayıtlı oturumun diskten yüklenmesini bekler.
  ///
  /// Stream'in ilk `null` değerine güvenilmez; [currentUser] periyodik kontrol
  /// edilir. Daha önce giriş yapılmışsa bekleme süresi uzatılır.
  Future<User?> waitForRestoredUser({
    SharedPreferences? prefs,
    Duration pollInterval = const Duration(milliseconds: 100),
  }) async {
    prefs ??= await SharedPreferences.getInstance();
    final cachedUid = prefs.getString(AppConstants.persistedAuthUidKey);
    final maxWait = cachedUid != null
        ? const Duration(seconds: 4)
        : const Duration(seconds: 1);

    if (kDebugMode) {
      debugPrint(
        '[Auth] Oturum geri yükleniyor... cachedUid=$cachedUid maxWait=${maxWait.inSeconds}s',
      );
    }

    final deadline = DateTime.now().add(maxWait);
    while (DateTime.now().isBefore(deadline)) {
      final user = _auth.currentUser;
      if (user != null) {
        await cacheAuthSession(user.uid);
        if (kDebugMode) {
          debugPrint('[Auth] Oturum geri yüklendi: ${user.uid}');
        }
        return user;
      }
      await Future.delayed(pollInterval);
    }

    // Google hesabı varsa sessiz yeniden giriş dene (e-posta kullanıcıları için no-op)
    final silentUser = await _trySilentGoogleReauth();
    if (silentUser != null) {
      await cacheAuthSession(silentUser.uid);
      if (kDebugMode) {
        debugPrint('[Auth] Google sessiz giriş başarılı: ${silentUser.uid}');
      }
      return silentUser;
    }

    // cachedUid var ama Firebase null → bozuk şifreli native depolama (bilinen SDK sorunu)
    if (cachedUid != null && _auth.currentUser == null) {
      if (kDebugMode) {
        debugPrint('[Auth] Bozuk native oturum algılandı, temizleniyor...');
      }
      await AuthStorageService.clearFirebaseAuthStorage();
      await clearAuthSessionCache();
    } else if (kDebugMode) {
      debugPrint(
        '[Auth] Oturum geri yüklenemedi. currentUser=null cachedUid=$cachedUid',
      );
    }
    return _auth.currentUser;
  }

  /// Firebase persistence bozulduğunda Google hesabından sessiz yeniden giriş dene.
  Future<User?> _trySilentGoogleReauth() async {
    try {
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'silent_google_reauth_failed',
        fatal: false,
      );
      return null;
    }
  }

  // ─── Google ile Giriş ──────────────────────────────────────────

  Future<UserModel?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Kullanıcı iptal etti

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return null;

      final userModel = await _createOrUpdateUser(user);

      // Analytics: login event
      AnalyticsService.instance.trackEvent(AnalyticsEvent.login);

      // RevenueCat kullanıcı eşlemesini güncelle.
      unawaited(RevenueCatService().login(user.uid));

      await cacheAuthSession(user.uid);

      // FCM token kaydet
      unawaited(FCMService().registerToken().catchError((_) {}));

      return userModel;
    } on FirebaseAuthException catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'signInWithGoogle_auth_error',
        fatal: false,
      );
      throw _handleAuthError(e);
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'signInWithGoogle_unknown_error',
        fatal: false,
      );
      final activeUser = _auth.currentUser;
      if (activeUser != null) {
        await cacheAuthSession(activeUser.uid);
        return UserModel(
          uid: activeUser.uid,
          displayName: activeUser.displayName ?? '',
          email: activeUser.email ?? '',
          photoUrl: activeUser.photoURL,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
      }
      await signOut();
      throw 'Giriş yapılamadı. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.';
    }
  }

  // ─── Email/Şifre ile Kayıt ────────────────────────────────────

  Future<UserModel?> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return null;

      // Display name güncelle
      await user.updateDisplayName(name);

      // edu.tr ise doğrulama maili gönder
      if (email.toLowerCase().endsWith('.edu.tr')) {
        await user.sendEmailVerification();
      }

      final userModel = await _createOrUpdateUser(user, displayName: name);

      // Analytics: login event (yeni kayıt da bir giriş sayılır)
      AnalyticsService.instance.trackEvent(AnalyticsEvent.login);

      // RevenueCat kullanıcı eşlemesini güncelle.
      unawaited(RevenueCatService().login(user.uid));

      await cacheAuthSession(user.uid);

      return userModel;
    } on FirebaseAuthException catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'registerWithEmail_auth_error',
        information: ['email: $email'],
        fatal: false,
      );
      throw _handleAuthError(e);
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'registerWithEmail_unknown_error',
        information: ['email: $email'],
        fatal: false,
      );
      // Eğer profil veritabanına yazılamazsa, Auth tarafında oluşan hesabı sil ki
      // kullanıcı tekrar kayıt olmaya çalıştığında email-already-in-use hatası almasın.
      try {
        await _auth.currentUser?.delete();
      } catch (_) {}

      await signOut();
      throw 'Kayıt yapılamadı. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.';
    }
  }

  // ─── Email/Şifre ile Giriş ───────────────────────────────────

  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return null;

      final userModel = await _createOrUpdateUser(user);

      // Analytics: login event
      AnalyticsService.instance.trackEvent(AnalyticsEvent.login);

      // RevenueCat kullanıcı eşlemesini güncelle.
      unawaited(RevenueCatService().login(user.uid));

      await cacheAuthSession(user.uid);

      // Token'ı diske yazmayı zorla — persistence sorunlarını önler
      await user.getIdToken(true);

      // FCM token kaydet — başarısız olsa bile oturumu kapatma
      unawaited(FCMService().registerToken().catchError((_) {}));

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'signInWithEmail_post_auth_error',
        fatal: false,
      );
      final activeUser = _auth.currentUser;
      if (activeUser != null) {
        await cacheAuthSession(activeUser.uid);
        return UserModel(
          uid: activeUser.uid,
          displayName: activeUser.displayName ?? '',
          email: activeUser.email ?? '',
          photoUrl: activeUser.photoURL,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
      }
      throw 'Giriş yapılamadı. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.';
    }
  }

  // ─── Şifre Sıfırlama ─────────────────────────────────────────

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ─── Çıkış Yap ───────────────────────────────────────────────

  Future<void> signOut() async {
    // Token unregister'ı fire-and-forget — login'e geçişi yavaşlatma
    unawaited(FCMService().unregisterToken().catchError((_) {}));
    // RevenueCat'ten logOut: eski entitlement'ların yeni kullanıcıya taşmaması için.
    unawaited(RevenueCatService().logout());

    _cachedUser = null;
    _lastCacheTime = null;
    await clearAuthSessionCache();
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  // ─── Hesabı Sil ───────────────────────────────────────────────

  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Oturum açık değil.';

    try {
      final uid = user.uid;
      await _reauthenticateForAccountDeletion(user, password: password);
      await user.getIdToken(true);

      // FCM kaydını mümkünse callable öncesinde kaldır. Sunucu tarafı temizliği
      // bu işlem başarısız olsa bile users/{uid} alt koleksiyonunu silecektir.
      await FCMService().unregisterToken().catchError((_) {});

      final callable = _functions.httpsCallable(
        'deleteUserAccount',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 9)),
      );
      await callable.call<void>({'confirmation': 'DELETE'});

      _cachedUser = null;
      _lastCacheTime = null;
      await _clearLocalAccountData(uid);
      await RevenueCatService().logout();
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } on FirebaseFunctionsException catch (e) {
      switch (e.code) {
        case 'failed-precondition':
          throw 'Güvenlik nedeniyle hesabınızı silmek için yeniden giriş yapmalısınız.';
        case 'unauthenticated':
          throw 'Oturumunuz sona ermiş. Lütfen yeniden giriş yapın.';
        case 'invalid-argument':
          throw 'Hesap silme onayı geçersiz.';
        default:
          throw e.message ??
              'Hesap şu anda silinemedi. Lütfen daha sonra tekrar deneyin.';
      }
    } catch (e) {
      if (e is String) rethrow;
      throw 'Hesap şu anda silinemedi. Lütfen daha sonra tekrar deneyin.';
    }
  }

  Future<void> _reauthenticateForAccountDeletion(
    User user, {
    String? password,
  }) async {
    final providers = user.providerData.map((info) => info.providerId).toSet();

    if (providers.contains('password')) {
      final email = user.email;
      if (email == null || password == null || password.isEmpty) {
        throw 'Hesabınızı silmek için mevcut şifrenizi girin.';
      }
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return;
    }

    if (providers.contains(GoogleAuthProvider.PROVIDER_ID)) {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Google doğrulaması iptal edildi.';
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(credential);
      return;
    }

    await user.reload();
  }

  Future<void> _clearLocalAccountData(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.persistedAuthUidKey);
    await prefs.remove('offline_favorites_queue');

    final draftPrefix = 'place_suggestion_draft_v1_${uid}_';
    final draftKeys = prefs
        .getKeys()
        .where((key) => key.startsWith(draftPrefix))
        .toList(growable: false);
    for (final key in draftKeys) {
      await prefs.remove(key);
    }
  }

  // ─── Kullanıcı Profili Çekme ──────────────────────────────────

  Future<UserModel?> getUserProfile(
    String uid, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cachedUser != null &&
        _cachedUser!.uid == uid &&
        _lastCacheTime != null) {
      if (DateTime.now().difference(_lastCacheTime!) < _cacheTtl) {
        return _cachedUser;
      }
    }

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;

    _cachedUser = UserModel.fromMap(doc.data()!, uid);
    _lastCacheTime = DateTime.now();
    return _cachedUser;
  }

  void clearCache() {
    _cachedUser = null;
    _lastCacheTime = null;
  }

  // ─── Public Profil (başka kullanıcının profili) ─────────────────

  /// Başka bir kullanıcının herkese açık profil bilgilerini getirir.
  Future<UserModel?> getPublicProfile(String uid) async {
    final doc = await _firestore.collection('publicProfiles').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      final data = Map<String, dynamic>.from(doc.data()!);
      data['email'] = '';
      data['role'] = 'user';
      data['fcmTokens'] = <String>[];
      data['lastLoginAt'] = data['createdAt'];
      return UserModel.fromMap(data, uid);
    }

    if (_auth.currentUser?.uid != uid) return null;

    final privateDoc = await _firestore.collection('users').doc(uid).get();
    if (!privateDoc.exists || privateDoc.data() == null) return null;

    final data = Map<String, dynamic>.from(privateDoc.data()!);
    data['email'] = '';
    data['role'] = 'user';
    data['fcmTokens'] = <String>[];
    return UserModel.fromMap(data, uid);
  }

  // ─── edu.tr Doğrulama Kontrolü ────────────────────────────────

  Future<bool> reloadAndCheckVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // 1. Firebase Auth kullanıcı nesnesini sunucudan yenile
    await user.reload();

    // 2. Token'ı zorla yenile — emailVerified claim'i ancak böyle güncellenir
    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null) return false;
    await refreshedUser.getIdToken(true);

    if (refreshedUser.emailVerified &&
        refreshedUser.email != null &&
        refreshedUser.email!.toLowerCase().endsWith('.edu.tr')) {
      await _functions.httpsCallable('verifyStudentUniversity').call();
      clearCache(); // Cache'i temizle ki güncel veriyi çeksin
      return true;
    }
    return false;
  }

  // ─── Doğrulama Maili Tekrar Gönder ────────────────────────────

  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // ─── Profil Güncelleme ─────────────────────────────────────────

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? department,
    int? grade,
    String? bio,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (department != null) updates['department'] = department;
    if (grade != null) updates['grade'] = grade;
    if (bio != null) updates['bio'] = bio;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);

      // Firebase Auth display name de güncelle
      if (displayName != null) {
        await _auth.currentUser?.updateDisplayName(displayName);
      }
      clearCache();
    }
  }

  // ─── Profil Fotoğrafı Yükleme ─────────────────────────────────

  Future<String> uploadProfilePhoto(String uid, File imageFile) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_photos')
        .child('$uid.jpg');

    // Fotoğrafı yükle
    await ref.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));

    // URL al
    final downloadUrl = await ref.getDownloadURL();

    // Firestore ve Auth'da güncelle
    await _firestore.collection('users').doc(uid).update({
      'photoUrl': downloadUrl,
    });
    await _auth.currentUser?.updatePhotoURL(downloadUrl);
    clearCache();

    return downloadUrl;
  }

  // ─── Yardımcı: Kullanıcı Oluştur/Güncelle ────────────────────

  Future<UserModel> _createOrUpdateUser(
    User user, {
    String? displayName,
  }) async {
    final userRef = _firestore.collection('users').doc(user.uid);

    // Firestore bağlantı sorunlarına karşı retry
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final doc = await userRef.get();

        if (doc.exists) {
          return UserModel.fromMap(doc.data()!, user.uid);
        } else {
          // Yeni kullanıcı oluştur
          final email = user.email ?? '';

          final newUser = UserModel(
            uid: user.uid,
            displayName: displayName ?? user.displayName ?? '',
            email: email,
            photoUrl: user.photoURL,
            isVerifiedStudent: false,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );

          await userRef.set({
            'displayName': newUser.displayName,
            'email': newUser.email,
            'photoUrl': newUser.photoUrl,
            'isVerifiedStudent': false,
            'university': null,
            'universityId': null,
            'department': null,
            'grade': null,
            'bio': null,
            'role': 'user',
            'reviewCount': 0,
            'notificationPrefs': newUser.notificationPrefs.toMap(),
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
          });

          // Analytics: yeni kullanıcı kaydı
          AnalyticsService.instance.trackEvent(AnalyticsEvent.newUser);

          return newUser;
        }
      } catch (e) {
        if (attempt == 1) rethrow; // Son denemede hatayı fırlat
        await Future.delayed(const Duration(seconds: 1)); // 1 sn bekle
      }
    }

    // Fallback — buraya hiç düşmemeli
    throw Exception('Firestore bağlantı hatası');
  }

  // ─── Hata Yönetimi ────────────────────────────────────────────

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Şifre hatalı. Lütfen tekrar deneyin.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanılıyor.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter olmalı.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'too-many-requests':
        return 'Çok fazla deneme yaptınız. Lütfen biraz bekleyin.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin.';
      case 'account-exists-with-different-credential':
        return 'Bu e-posta farklı bir giriş yöntemiyle kayıtlı.';
      default:
        return 'Bir hata oluştu: ${e.message}';
    }
  }
}
