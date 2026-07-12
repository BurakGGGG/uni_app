import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SeedDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> uploadSeedData() async {
    // ── 0. Güvenlik Kontrolü ─────────────────────────────────────
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Yetkisiz erişim: Lütfen giriş yapın.');
    }
    // if (token.claims?['admin'] != true) {
    //   throw Exception('Yetkisiz erişim: Sadece adminler seed datası yükleyebilir.');
    // }

    // Şehir ve üniversite kayıtları üretilen JSON asset'lerden okunur
    // (lib/scripts/osym/v2_generate_seed.py çıktısı). Elle liste tutulmaz.
    final citiesJson =
        await rootBundle.loadString('assets/data/cities_seed.json');
    final cities =
        ((json.decode(citiesJson) as Map<String, dynamic>)['cities'] as List)
            .cast<Map<String, dynamic>>();
    final unisJson =
        await rootBundle.loadString('assets/data/universities_seed.json');
    final universities =
        ((json.decode(unisJson) as Map<String, dynamic>)['universities']
                as List)
            .cast<Map<String, dynamic>>();

    debugPrint(
        '📥 ${cities.length} şehir + ${universities.length} üniversite yüklenecek');

    var batch = _firestore.batch();
    var count = 0;

    Future<void> flushIfNeeded() async {
      if (count >= 490) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }

    for (final city in cities) {
      final ref = _firestore.collection('cities').doc(city['id'] as String);
      final data = Map<String, dynamic>.from(city)
        ..removeWhere((k, v) => k.startsWith('_') || v == null);
      batch.set(ref, data, SetOptions(merge: true));
      count++;
      await flushIfNeeded();
    }

    for (final uni in universities) {
      final ref =
          _firestore.collection('universities').doc(uni['id'] as String);
      final data = Map<String, dynamic>.from(uni)
        ..remove('avgRating') // aggregation alanları server-side yönetilir
        ..remove('reviewCount')
        ..remove('categoryRatings')
        ..removeWhere((k, v) => k.startsWith('_') || v == null);
      batch.set(ref, data, SetOptions(merge: true));
      count++;
      await flushIfNeeded();
    }

    if (count > 0) await batch.commit();
    debugPrint('✅ ${cities.length} şehir + ${universities.length} üni seed tamamlandı');

    // NOT: Bölüm verileri gerçek ÖSYM kayıtlarıyla department_scores_migration
    // üzerinden yüklenir. Buradaki eski sentetik bölüm üretimi kaldırıldı —
    // rastgele puanlar gerçek dokümanların üzerine yazıyordu (örn. itu_tip).
  }

  /// Eski tüm yurt kayıtlarını siler ve güncel KYK verilerini yükler.
  /// kykyurtlar.com'dan çekilen verilerle places_seed.json güncellenmiş olmalı.
  Future<void> reseedDorms() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Yetkisiz erişim: Lütfen giriş yapın.');
    }

    // 1. Mevcut dorm dokümanlarını sil
    debugPrint('🗑️ Mevcut yurt kayıtları siliniyor...');
    final dormSnapshot = await _firestore
        .collection('places')
        .where('type', isEqualTo: 'dorm')
        .get();

    if (dormSnapshot.docs.isNotEmpty) {
      var delBatch = _firestore.batch();
      var delCount = 0;
      for (final doc in dormSnapshot.docs) {
        delBatch.delete(doc.reference);
        delCount++;
        if (delCount >= 490) {
          await delBatch.commit();
          delBatch = _firestore.batch();
          delCount = 0;
        }
      }
      if (delCount > 0) await delBatch.commit();
      debugPrint('🗑️ ${dormSnapshot.docs.length} eski yurt silindi');
    }

    // 2. Güncel yurt verilerini JSON'dan oku
    final jsonStr = await rootBundle.loadString('assets/data/places_seed.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final allPlaces = (data['places'] as List).cast<Map<String, dynamic>>();
    final dorms = allPlaces.where((p) => p['type'] == 'dorm').toList();

    debugPrint('📥 ${dorms.length} yeni yurt yüklenecek');

    // 3. Yeni yurtları batch ile yaz
    var batch = _firestore.batch();
    var batchCount = 0;
    for (final dorm in dorms) {
      final dormId = dorm['id'] as String;
      final ref = _firestore.collection('places').doc(dormId);

      final dormData = {
        ...dorm,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      dormData.remove('id');
      dormData.removeWhere((k, v) => v == null);

      batch.set(ref, dormData);
      batchCount++;

      if (batchCount >= 490) {
        await batch.commit();
        batch = _firestore.batch();
        batchCount = 0;
        debugPrint('  📤 $batchCount/${ dorms.length} yüklendi...');
      }
    }
    if (batchCount > 0) await batch.commit();
    debugPrint('✅ ${dorms.length} yurt Firestore\'a yüklendi!');
  }

  // ignore: unused_element
  Future<void> _seedPlaces() async {
    // 1. Asset'ten JSON oku
    final jsonStr = await rootBundle.loadString('assets/data/places_seed.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final places = (data['places'] as List).cast<Map<String, dynamic>>();
    final layouts = (data['campusLayouts'] as Map<String, dynamic>).cast<String, String>();
    
    debugPrint('📥 ${places.length} mekan import edilecek');
    
    // 2. Üniversitelere campusLayout migration
    var b1Batch = _firestore.batch();
    var b1Count = 0;
    for (final entry in layouts.entries) {
      final uniRef = _firestore.collection('universities').doc(entry.key);
      b1Batch.set(uniRef, {'campusLayout': entry.value}, SetOptions(merge: true));
      b1Count++;
      if (b1Count >= 490) {
        await b1Batch.commit();
        b1Batch = _firestore.batch();
        b1Count = 0;
      }
    }
    if (b1Count > 0) await b1Batch.commit();
    debugPrint('✅ Campus layout güncellendi (${layouts.length} üni)');
    
    // 3. Places'i batch ile yaz
    var batch = _firestore.batch();
    var batchCount = 0;
    for (final place in places) {
      final placeId = place['id'] as String;
      final ref = _firestore.collection('places').doc(placeId);
      
      // Timestamp'leri ekle (JSON'da yok)
      final placeData = {
        ...place,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      placeData.remove('id');  // Doc id ayrı, data'da olmayacak
      
      // Null değerleri temizle
      placeData.removeWhere((k, v) => v == null);
      
      // merge: true ile mevcut yorumlar/agg silinmez
      batch.set(ref, placeData, SetOptions(merge: true));
      batchCount++;
      
      if (batchCount >= 490) {
        await batch.commit();
        batch = _firestore.batch();
        batchCount = 0;
      }
    }
    if (batchCount > 0) await batch.commit();
    debugPrint('✅ ${places.length} mekan Firestore\'a yüklendi');
  }

  /// Firebase'deki places koleksiyonundan sadece type == "cafe" olanları siler
  Future<void> deleteCafes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Yetkisiz erişim: Lütfen giriş yapın.');
    }

    // type == 'cafe' olan tüm dokümanları çek
    final snapshot = await _firestore
        .collection('places')
        .where('type', isEqualTo: 'cafe')
        .get();

    if (snapshot.docs.isEmpty) {
      debugPrint('ℹ️ Silinecek kafe bulunamadı.');
      return;
    }

    debugPrint('🗑️ ${snapshot.docs.length} kafe silinecek...');

    var batch = _firestore.batch();
    var batchCount = 0;

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
      batchCount++;

      if (batchCount >= 490) {
        await batch.commit();
        batch = _firestore.batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    debugPrint('✅ ${snapshot.docs.length} kafe Firebase\'den silindi.');
  }
}
