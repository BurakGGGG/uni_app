import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../domain/models/story_model.dart';

/// Story CRUD işlemleri
class StoryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  StoryRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _storiesRef =>
      _firestore.collection('stories');

  // ─── Okuma ─────────────────────────────────────────────────────────

  /// Aktif story'leri dinler (yeni→eski, Firestore index uyumlu)
  /// Sıralamayı provider katmanında ters çeviriyoruz (eski→yeni)
  Stream<List<StoryModel>> getActiveStories() {
    return _storiesRef
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
            .toList())
        .handleError((error) {
      debugPrint('[StoryRepository] Stream error: $error');
    });
  }

  /// Aktif story'leri tek seferlik okur (index yoksa fallback)
  Future<List<StoryModel>> getActiveStoriesFallback() async {
    try {
      final snapshot = await _storiesRef
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('[StoryRepository] Fallback query: $e');
      final snapshot = await _storiesRef
          .where('isActive', isEqualTo: true)
          .get();
      final stories = snapshot.docs
          .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
          .toList();
      stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return stories;
    }
  }

  // ─── Yazma (Admin) ────────────────────────────────────────────────

  /// Yeni story ekler
  Future<String> addStory(StoryModel story) async {
    final docRef = await _storiesRef.add(story.toMap());
    return docRef.id;
  }

  /// Story'yi soft-delete yapar
  Future<void> deleteStory(String storyId) async {
    await _storiesRef.doc(storyId).update({'isActive': false});
  }

  /// Story görselini Firebase Storage'a yükler
  Future<String> uploadStoryImage(File imageFile) async {
    final fileName =
        'stories/${DateTime.now().millisecondsSinceEpoch}_${imageFile.uri.pathSegments.last}';
    final ref = _storage.ref().child(fileName);

    final uploadTask = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }
}
