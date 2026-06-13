import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../domain/models/preference_list_model.dart';
import '../../admin/data/analytics_service.dart';
import '../../admin/domain/models/analytics_event.dart';

class PreferenceListRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  static const int _maxTitleLength = 80;
  static const int _maxDescriptionLength = 500;

  PreferenceListRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  CollectionReference<Map<String, dynamic>> get _listsRef =>
      _firestore.collection('preferenceLists');

  /// Slug üretimi: 8 karakterli alfanumerik (çakışma ihtimali çok düşük)
  static String _generateSlug() {
    const chars =
        'abcdefghjkmnpqrstuvwxyz23456789'; // confusing chars çıkarıldı
    final rng = Random.secure();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  /// Unique slug bul (veritabanını sorgulamadan, rastgele 8 karakter)
  Future<String> _findUniqueSlug() async {
    return _generateSlug();
  }

  /// Yeni liste oluştur
  Future<PreferenceListModel> createList({
    required String title,
    String description = '',
    bool isPublic = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Giriş yapmalısınız');
    final safeTitle = _validateTitle(title);
    final safeDescription = _validateDescription(description);
    final author = await _loadCurrentAuthor(user);

    // Limit kontrolü
    final myLists = await _listsRef
        .where('userId', isEqualTo: user.uid)
        .count()
        .get();
    final count = myLists.count ?? 0;
    if (count >= PreferenceListModel.maxLists) {
      throw Exception(
        'En fazla ${PreferenceListModel.maxLists} liste oluşturabilirsiniz.',
      );
    }

    final slug = await _findUniqueSlug();
    final now = DateTime.now();
    final docRef = _listsRef.doc();

    final list = PreferenceListModel(
      id: docRef.id,
      userId: user.uid,
      userName: author.displayName,
      userPhotoUrl: author.photoUrl,
      title: safeTitle,
      description: safeDescription,
      isPublic: isPublic,
      shareSlug: slug,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set({
      'userId': list.userId,
      'userName': list.userName,
      'userPhotoUrl': list.userPhotoUrl,
      'title': list.title,
      'description': list.description,
      'isPublic': list.isPublic,
      'shareSlug': list.shareSlug,
      'viewCount': 0,
      'items': const <Map<String, dynamic>>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    AnalyticsService.instance.trackEvent(AnalyticsEvent.preferenceListCreated);
    return list;
  }

  /// Liste güncelle
  Future<void> updateList(PreferenceListModel list) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != list.userId) {
      throw Exception('Bu listeyi düzenleme yetkiniz yok');
    }
    if (list.items.length > PreferenceListModel.maxItems) {
      throw Exception(
        'Bir listede en fazla ${PreferenceListModel.maxItems} tercih olabilir',
      );
    }
    await _listsRef.doc(list.id).update({
      'title': _validateTitle(list.title),
      'description': _validateDescription(list.description),
      'isPublic': list.isPublic,
      'items': list.items.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Liste sil
  Future<void> deleteList(String listId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Giriş yapmalısınız');
    final doc = await _listsRef.doc(listId).get();
    if (!doc.exists || doc.data()?['userId'] != user.uid) {
      throw Exception('Bu listeyi silme yetkiniz yok');
    }
    await _listsRef.doc(listId).delete();
  }

  /// Kullanıcının listelerini stream olarak izle
  Stream<List<PreferenceListModel>> watchMyLists() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _listsRef
        .where('userId', isEqualTo: user.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => PreferenceListModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  /// Tek liste izle (kendi)
  Stream<PreferenceListModel?> watchList(String listId) {
    return _listsRef.doc(listId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return PreferenceListModel.fromMap(doc.data()!, doc.id);
    });
  }

  /// Slug ile public liste getir + view count artır
  Future<PreferenceListModel?> getPublicListBySlug(String slug) async {
    final query = await _listsRef
        .where('shareSlug', isEqualTo: slug)
        .where('isPublic', isEqualTo: true)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;

    unawaited(_incrementPublicListView(doc.id));

    return PreferenceListModel.fromMap(doc.data(), doc.id);
  }

  /// Liste'ye öğe ekle
  Future<void> addItem(String listId, PreferenceItem item) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Giriş yapmalısınız');
    final list = await _listsRef.doc(listId).get();
    if (!list.exists) throw Exception('Liste bulunamadı');
    final model = PreferenceListModel.fromMap(list.data()!, listId);
    if (model.userId != user.uid) {
      throw Exception('Bu listeyi düzenleme yetkiniz yok');
    }

    if (model.items.length >= PreferenceListModel.maxItems) {
      throw Exception(
        'Listede en fazla ${PreferenceListModel.maxItems} tercih olabilir',
      );
    }
    if (model.items.any((i) => i.deptId == item.deptId)) {
      throw Exception('Bu bölüm zaten listede');
    }

    final newItems = [
      ...model.items,
      item.copyWith(order: model.items.length + 1),
    ];
    await _listsRef.doc(listId).update({
      'items': newItems.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Sırayı yeniden düzenle
  Future<void> reorderItems(
    String listId,
    List<PreferenceItem> orderedItems,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Giriş yapmalısınız');
    if (orderedItems.length > PreferenceListModel.maxItems) {
      throw Exception(
        'Bir listede en fazla ${PreferenceListModel.maxItems} tercih olabilir',
      );
    }

    final list = await _listsRef.doc(listId).get();
    if (!list.exists) throw Exception('Liste bulunamadı');
    final data = list.data();
    if (data?['userId'] != user.uid) {
      throw Exception('Bu listeyi düzenleme yetkiniz yok');
    }

    final reordered = <Map<String, dynamic>>[];
    for (var i = 0; i < orderedItems.length; i++) {
      reordered.add(orderedItems[i].copyWith(order: i + 1).toMap());
    }
    await _listsRef.doc(listId).update({
      'items': reordered,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<_PreferenceListAuthor> _loadCurrentAuthor(User user) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data();
    final rawName = data?['displayName'];
    final rawPhotoUrl = data?['photoUrl'];
    final displayName = rawName is String && rawName.isNotEmpty
        ? rawName
        : 'Öğrenci';
    final photoUrl = rawPhotoUrl is String ? rawPhotoUrl : null;
    return _PreferenceListAuthor(displayName: displayName, photoUrl: photoUrl);
  }

  String _validateTitle(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw Exception('Liste başlığı boş olamaz');
    }
    if (trimmed.length > _maxTitleLength) {
      throw Exception(
        'Liste başlığı en fazla $_maxTitleLength karakter olabilir',
      );
    }
    return trimmed;
  }

  String _validateDescription(String value) {
    final trimmed = value.trim();
    if (trimmed.length > _maxDescriptionLength) {
      throw Exception(
        'Liste açıklaması en fazla $_maxDescriptionLength karakter olabilir',
      );
    }
    return trimmed;
  }

  Future<void> _incrementPublicListView(String listId) async {
    try {
      await _functions.httpsCallable('incrementPreferenceListView').call({
        'listId': listId,
      });
    } catch (_) {
      // Best-effort sayaç: paylaşım ekranı sayaç hatası yüzünden açılmamalı.
    }
  }
}

class _PreferenceListAuthor {
  const _PreferenceListAuthor({
    required this.displayName,
    required this.photoUrl,
  });

  final String displayName;
  final String? photoUrl;
}
