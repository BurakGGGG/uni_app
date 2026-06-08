import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../domain/models/story_model.dart';

/// Story CRUD işlemleri — fotoğraf + video desteği
class StoryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  StoryRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _storiesRef =>
      _firestore.collection('stories');

  // ─── Okuma ─────────────────────────────────────────────────────────

  /// Aktif story'leri tek seferlik okur (index yoksa fallback)
  Future<List<StoryModel>> getActiveStories() async {
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

  /// Eski provider adlarıyla uyumluluk için tutulur.
  Future<List<StoryModel>> getActiveStoriesFallback() => getActiveStories();

  /// Tüm story'leri dinler (aktif + arşiv — admin panel için)
  Stream<List<StoryModel>> getAllStories() {
    return _storiesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
              .toList(),
        )
        .handleError((error) {
          debugPrint('[StoryRepository] All stories stream error: $error');
        });
  }

  // ─── Yazma (Admin) ────────────────────────────────────────────────

  /// Yeni story ekler
  Future<String> addStory(StoryModel story) async {
    final docRef = await _storiesRef.add(story.toMap());
    return docRef.id;
  }

  /// Story'yi soft-delete yapar (arşivle)
  Future<void> archiveStory(String storyId) async {
    await _storiesRef.doc(storyId).update({'isActive': false});
  }

  /// Story'yi tekrar aktifleştir
  Future<void> reactivateStory(String storyId) async {
    await _storiesRef.doc(storyId).update({'isActive': true});
  }

  /// Story'yi kalıcı olarak sil (Firestore doc + Storage dosyaları)
  Future<void> permanentlyDeleteStory(
    String storyId, {
    required String imageUrl,
    String? thumbnailUrl,
    String? videoUrl,
  }) async {
    // 1. Storage dosyalarını sil
    await _deleteStorageFile(imageUrl);
    if (thumbnailUrl != null) await _deleteStorageFile(thumbnailUrl);
    if (videoUrl != null) await _deleteStorageFile(videoUrl);

    // 2. Firestore doc'u sil
    await _storiesRef.doc(storyId).delete();
  }

  Future<void> _deleteStorageFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('[StoryRepository] Storage delete error: $e');
    }
  }

  // ─── Upload ───────────────────────────────────────────────────────

  /// Story görselini Firebase Storage'a yükler (orijinal kalite)
  Future<String> uploadStoryImage(File imageFile) async {
    final ext = imageFile.path.split('.').last.toLowerCase();
    final contentType = _imageContentType(ext);
    final fileName =
        'stories/${DateTime.now().millisecondsSinceEpoch}_${imageFile.uri.pathSegments.last}';
    final ref = _storage.ref().child(fileName);

    final uploadTask = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: contentType),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  /// Story kapak fotoğrafını Firebase Storage'a yükler (yuvarlak kırpılmış)
  Future<String> uploadStoryThumbnail(File thumbnailFile) async {
    final ext = thumbnailFile.path.split('.').last.toLowerCase();
    final contentType = _imageContentType(ext);
    final fileName =
        'stories/thumb_${DateTime.now().millisecondsSinceEpoch}_${thumbnailFile.uri.pathSegments.last}';
    final ref = _storage.ref().child(fileName);

    final uploadTask = await ref.putFile(
      thumbnailFile,
      SettableMetadata(contentType: contentType),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  /// Video dosyasını Firebase Storage'a yükler
  Future<String> uploadStoryVideo(File videoFile) async {
    final ext = videoFile.path.split('.').last.toLowerCase();
    final contentType = ext == 'mov' ? 'video/quicktime' : 'video/$ext';
    final fileName =
        'stories/video_${DateTime.now().millisecondsSinceEpoch}_${videoFile.uri.pathSegments.last}';
    final ref = _storage.ref().child(fileName);

    final uploadTask = await ref.putFile(
      videoFile,
      SettableMetadata(contentType: contentType),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  String _imageContentType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
      case 'heif':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }
}
