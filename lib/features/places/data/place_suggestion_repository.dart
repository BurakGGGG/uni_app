import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/place_suggestion_model.dart';

/// Mekan önerisi repository — Firestore CRUD + Firebase Storage fotoğraf yükleme.
class PlaceSuggestionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  PlaceSuggestionRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _suggestionsRef =>
      _firestore.collection('place_suggestions');

  // ─── Fotoğraf Yükleme ─────────────────────────────────────────

  /// Fotoğrafları Firebase Storage'a yükler, URL listesi döner.
  Future<List<String>> uploadPhotos({
    required String userId,
    required String suggestionId,
    required List<File> photos,
  }) async {
    final urls = <String>[];

    for (int i = 0; i < photos.length; i++) {
      final file = photos[i];
      final ext = file.path.split('.').last.toLowerCase();
      final mimeExt = ext == 'jpg' ? 'jpeg' : ext;
      final ref = _storage.ref(
        'place_suggestions/$userId/$suggestionId/photo_$i.$ext',
      );

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/$mimeExt'),
      );

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  // ─── Öneri Gönderme ───────────────────────────────────────────

  /// Yeni mekan önerisi oluşturur. Fotoğrafları yükler ve Firestore'a yazar.
  Future<String> submitSuggestion({
    required PlaceSuggestionModel suggestion,
    List<File> photos = const [],
  }) async {
    // 1. Firestore dökümanını oluştur (ID al)
    final docRef = _suggestionsRef.doc();
    final suggestionId = docRef.id;

    // 2. Fotoğrafları yükle
    List<String> photoUrls = [];
    if (photos.isNotEmpty) {
      photoUrls = await uploadPhotos(
        userId: suggestion.userId,
        suggestionId: suggestionId,
        photos: photos,
      );
    }

    // 3. Dökümanı kaydet
    final data = suggestion.copyWith(photoUrls: photoUrls).toMap();
    await docRef.set(data);

    return suggestionId;
  }

  // ─── Admin İşlemleri ──────────────────────────────────────────

  /// Tüm önerileri duruma göre getirir.
  Future<List<PlaceSuggestionModel>> getSuggestions({
    SuggestionStatus? status,
  }) async {
    Query<Map<String, dynamic>> query = _suggestionsRef
        .orderBy('createdAt', descending: true);

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
    required String adminUserId,
    String? adminNote,
  }) async {
    await _suggestionsRef.doc(suggestionId).update({
      'status': SuggestionStatus.approved.firestoreValue,
      'reviewedBy': adminUserId,
      'reviewedAt': FieldValue.serverTimestamp(),
      if (adminNote != null) 'adminNote': adminNote,
    });
  }

  /// Öneriyi reddet — opsiyonel sebep notu ile.
  Future<void> rejectSuggestion({
    required String suggestionId,
    required String adminUserId,
    String? adminNote,
  }) async {
    await _suggestionsRef.doc(suggestionId).update({
      'status': SuggestionStatus.rejected.firestoreValue,
      'reviewedBy': adminUserId,
      'reviewedAt': FieldValue.serverTimestamp(),
      if (adminNote != null) 'adminNote': adminNote,
    });
  }

  /// Onaylanan öneriyi gerçek mekan olarak `places` koleksiyonuna ekler.
  Future<void> convertToPlace(PlaceSuggestionModel suggestion) async {
    await _firestore.collection('places').add({
      'universityId': suggestion.universityId,
      'name': suggestion.name,
      'type': suggestion.type.firestoreValue,
      'description': suggestion.description,
      'imageUrls': suggestion.photoUrls,
      'address': suggestion.address,
      'amenities': <String>[],
      'avgRating': 0.0,
      'reviewCount': 0,
      'categoryRatings': <String, dynamic>{},
      'isPromoted': false,
      'promotionPriority': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ Öneri mekan olarak eklendi: ${suggestion.name}');
  }
}
