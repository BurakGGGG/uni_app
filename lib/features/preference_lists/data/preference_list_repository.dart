import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/models/preference_list_model.dart';
import '../../admin/data/analytics_service.dart';
import '../../admin/domain/models/analytics_event.dart';

class PreferenceListRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PreferenceListRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _listsRef =>
      _firestore.collection('preferenceLists');

  /// Slug üretimi: 8 karakterli alfanumerik (çakışma ihtimali çok düşük)
  static String _generateSlug() {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789'; // confusing chars çıkarıldı
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

    // Limit kontrolü
    final myLists = await _listsRef.where('userId', isEqualTo: user.uid)
                                     .count().get();
    final count = myLists.count ?? 0;
    if (count >= PreferenceListModel.maxLists) {
      throw Exception('En fazla ${PreferenceListModel.maxLists} liste oluşturabilirsiniz.');
    }

    final slug = await _findUniqueSlug();
    final now = DateTime.now();
    final docRef = _listsRef.doc();

    final list = PreferenceListModel(
      id: docRef.id,
      userId: user.uid,
      userName: user.displayName ?? 'Öğrenci',
      userPhotoUrl: user.photoURL,
      title: title,
      description: description,
      isPublic: isPublic,
      shareSlug: slug,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(list.toMap());
    AnalyticsService.instance
        .trackEvent(AnalyticsEvent.preferenceListCreated);
    return list;
  }

  /// Liste güncelle
  Future<void> updateList(PreferenceListModel list) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != list.userId) {
      throw Exception('Bu listeyi düzenleme yetkiniz yok');
    }
    if (list.items.length > PreferenceListModel.maxItems) {
      throw Exception('Bir listede en fazla ${PreferenceListModel.maxItems} tercih olabilir');
    }
    await _listsRef.doc(list.id).update(list.toMap());
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
        .map((snap) => snap.docs
            .map((d) => PreferenceListModel.fromMap(d.data(), d.id))
            .toList());
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
    
    // View count artır (best effort, hata olursa sessizce devam et)
    _listsRef.doc(doc.id).update({
      'viewCount': FieldValue.increment(1),
    }).catchError((_) {});

    return PreferenceListModel.fromMap(doc.data(), doc.id);
  }

  /// Liste'ye öğe ekle
  Future<void> addItem(String listId, PreferenceItem item) async {
    final list = await _listsRef.doc(listId).get();
    if (!list.exists) throw Exception('Liste bulunamadı');
    final model = PreferenceListModel.fromMap(list.data()!, listId);

    if (model.items.length >= PreferenceListModel.maxItems) {
      throw Exception('Listede en fazla ${PreferenceListModel.maxItems} tercih olabilir');
    }
    if (model.items.any((i) => i.deptId == item.deptId)) {
      throw Exception('Bu bölüm zaten listede');
    }

    final newItems = [...model.items, item.copyWith(order: model.items.length + 1)];
    await _listsRef.doc(listId).update({
      'items': newItems.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Sırayı yeniden düzenle
  Future<void> reorderItems(String listId, List<PreferenceItem> orderedItems) async {
    final reordered = <Map<String, dynamic>>[];
    for (var i = 0; i < orderedItems.length; i++) {
      reordered.add(orderedItems[i].copyWith(order: i + 1).toMap());
    }
    await _listsRef.doc(listId).update({
      'items': reordered,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
