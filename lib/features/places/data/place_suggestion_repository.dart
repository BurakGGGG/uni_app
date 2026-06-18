import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../domain/models/place_suggestion_model.dart';

/// Mekan önerisi repository — güvenli callable akışı + fotoğraf yükleme.
class PlaceSuggestionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;

  PlaceSuggestionRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  CollectionReference<Map<String, dynamic>> get _suggestionsRef =>
      _firestore.collection('place_suggestions');

  // ─── Fotoğraf Yükleme ─────────────────────────────────────────

  /// Fotoğrafları Firebase Storage'a yükler, URL listesi döner.
  Future<List<String>> uploadPhotos({
    required String userId,
    required String suggestionId,
    required List<File> photos,
  }) async {
    if (photos.length > 5) {
      throw const PlaceSuggestionException(
        'En fazla 5 fotoğraf yükleyebilirsin.',
      );
    }

    final extensions = photos.map(_safePhotoExtension).toList();
    final urls = <String>[];

    for (int i = 0; i < photos.length; i++) {
      final file = photos[i];
      final ext = extensions[i];
      final ref = _storage.ref(
        'place_suggestions/$userId/$suggestionId/photo_$i.$ext',
      );

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: _contentTypeForExtension(ext)),
      );

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  // ─── Öneri Gönderme ───────────────────────────────────────────

  /// Fotoğrafları yükler ve öneriyi App Check zorunlu callable ile gönderir.
  Future<String> submitSuggestion({
    required PlaceSuggestionModel suggestion,
    List<File> photos = const [],
  }) async {
    _validateSuggestion(suggestion, photos);
    final suggestionId = _suggestionsRef.doc().id;

    List<String> photoUrls = [];
    if (photos.isNotEmpty) {
      photoUrls = await uploadPhotos(
        userId: suggestion.userId,
        suggestionId: suggestionId,
        photos: photos,
      );
    }

    try {
      final callable = _functions.httpsCallable(
        'submitPlaceSuggestion',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      await callable.call<Object?>({
        'suggestionId': suggestionId,
        'universityId': suggestion.universityId,
        'name': suggestion.name,
        'type': suggestion.type.firestoreValue,
        'description': suggestion.description,
        'address': suggestion.address,
        'photoUrls': photoUrls,
      });
    } on FirebaseFunctionsException catch (e) {
      throw PlaceSuggestionException(
        e.message ?? 'Mekan önerisi gönderilemedi.',
      );
    }

    return suggestionId;
  }

  // ─── Admin İşlemleri ──────────────────────────────────────────

  /// Tüm önerileri duruma göre getirir.
  Future<List<PlaceSuggestionModel>> getSuggestions({
    SuggestionStatus? status,
  }) async {
    Query<Map<String, dynamic>> query = _suggestionsRef.orderBy(
      'createdAt',
      descending: true,
    );

    if (status != null) {
      query = query.where('status', isEqualTo: status.firestoreValue);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => PlaceSuggestionModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Bekleyen öneri sayısını döner.
  Stream<int> pendingSuggestionCountStream() {
    return _suggestionsRef
        .where('status', isEqualTo: SuggestionStatus.pending.firestoreValue)
        .snapshots()
        .map((snap) => snap.size);
  }

  /// Öneriyi onayla — opsiyonel admin notu ile.
  Future<void> approveSuggestion({
    required String suggestionId,
    String? adminNote,
  }) async {
    await _callAdminAction(
      action: 'approve',
      suggestionId: suggestionId,
      adminNote: adminNote,
    );
  }

  /// Öneriyi reddet — opsiyonel sebep notu ile.
  Future<void> rejectSuggestion({
    required String suggestionId,
    String? adminNote,
  }) async {
    await _callAdminAction(
      action: 'reject',
      suggestionId: suggestionId,
      adminNote: adminNote,
    );
  }

  Future<void> _callAdminAction({
    required String action,
    required String suggestionId,
    String? adminNote,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'performPlaceSuggestionAction',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      await callable.call<Object?>({
        'action': action,
        'suggestionId': suggestionId,
        'adminNote': ?adminNote,
      });
    } on FirebaseFunctionsException catch (e) {
      throw PlaceSuggestionException(e.message ?? 'Mekan önerisi işlenemedi.');
    }
  }

  String _safePhotoExtension(File file) {
    final fileName = file.path.split('/').last.toLowerCase();
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) {
      throw const PlaceSuggestionException(
        'Fotoğraf dosya türü belirlenemedi.',
      );
    }

    final extension = fileName.substring(dotIndex + 1);
    if (extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'png' ||
        extension == 'webp') {
      return extension;
    }
    throw const PlaceSuggestionException(
      'Sadece JPG, PNG veya WebP fotoğraf yükleyebilirsin.',
    );
  }

  void _validateSuggestion(PlaceSuggestionModel suggestion, List<File> photos) {
    final nameLength = suggestion.name.trim().length;
    if (nameLength < 2 || nameLength > 100) {
      throw const PlaceSuggestionException(
        'Mekan adı 2-100 karakter arasında olmalı.',
      );
    }
    if (suggestion.description.trim().length > 500) {
      throw const PlaceSuggestionException(
        'Açıklama en fazla 500 karakter olabilir.',
      );
    }
    if (suggestion.address.trim().length > 300) {
      throw const PlaceSuggestionException(
        'Adres en fazla 300 karakter olabilir.',
      );
    }
    if (photos.length > 5) {
      throw const PlaceSuggestionException(
        'En fazla 5 fotoğraf yükleyebilirsin.',
      );
    }

    for (final photo in photos) {
      _safePhotoExtension(photo);
    }
  }

  String _contentTypeForExtension(String extension) {
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => throw const PlaceSuggestionException(
        'Desteklenmeyen fotoğraf türü.',
      ),
    };
  }
}

class PlaceSuggestionException implements Exception {
  final String message;

  const PlaceSuggestionException(this.message);

  @override
  String toString() => message;
}
