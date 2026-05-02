import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/user_model.dart';
import '../../notifications/data/fcm_service.dart';

/// Auth işlemlerini yöneten repository
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  // In-memory cache
  UserModel? _cachedUser;
  DateTime? _lastCacheTime;
  static const _cacheTtl = Duration(minutes: 2);

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Auth state stream — giriş/çıkış dinleme
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Mevcut Firebase kullanıcısı
  User? get currentUser => _auth.currentUser;

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

      // FCM token kaydet
      await FCMService().registerToken();

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      // Eğer profil kaydedilemezse auth'tan çık ki inconsistent state olmasın
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

      return await _createOrUpdateUser(user, displayName: name);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
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

      // FCM token kaydet
      await FCMService().registerToken();

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      await signOut();
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
    // FCM token sil
    try {
      await FCMService().unregisterToken();
    } catch (_) {
      // Token silme başarısız olsa bile çıkışı engelleme
    }

    _cachedUser = null;
    _lastCacheTime = null;
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // ─── Kullanıcı Profili Çekme ──────────────────────────────────

  Future<UserModel?> getUserProfile(String uid, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedUser != null && _cachedUser!.uid == uid && _lastCacheTime != null) {
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
      // Firestore'u güncelle ki UserModel.isVerifiedStudent senkronize olsun
      await _firestore.collection('users').doc(refreshedUser.uid).update({
        'isVerifiedStudent': true,
      });
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
    String? university,
    String? universityId,
    String? department,
    int? grade,
    String? bio,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (university != null) updates['university'] = university;
    if (universityId != null) updates['universityId'] = universityId;
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
    await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

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
          // Mevcut kullanıcı — lastLoginAt güncelle
          await userRef.update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
          return UserModel.fromMap(doc.data()!, user.uid);
        } else {
          // Yeni kullanıcı oluştur
          final isEdu = (user.email ?? '').toLowerCase().endsWith('.edu.tr');
          final newUser = UserModel(
            uid: user.uid,
            displayName: displayName ?? user.displayName ?? '',
            email: user.email ?? '',
            photoUrl: user.photoURL,
            isVerifiedStudent: isEdu && user.emailVerified,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );

          await userRef.set(newUser.toMap());
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
