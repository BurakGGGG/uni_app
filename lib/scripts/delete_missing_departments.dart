import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Firestore'daki `departments` koleksiyonunda, güncel
/// `assets/data/department_scores.json` listesinde OLMAYAN dokümanları siler.
///
/// Allowlist'e geçtikten sonra (875 doküman), önceki migration'lardan
/// (3500+ kayıt) artakalan dokümanları temizler.
///
/// Güvenlik:
/// - Login gerekli (Firestore rules `isAuthenticated()` zaten zorluyor).
/// - Yorumu olan (reviewCount > 0) dokümanlar silinmez.
///
/// Kullanım: Profil > Debug > "Eksik bölümleri sil"
Future<void> deleteMissingDepartments() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('Yetkisiz erişim: Lütfen giriş yapın.');
  }

  final firestore = FirebaseFirestore.instance;

  // 1. Geçerli deptId'leri JSON'dan al
  final jsonStr =
      await rootBundle.loadString('assets/data/department_scores.json');
  final data = json.decode(jsonStr) as Map<String, dynamic>;
  final scores = (data['scores'] as List).cast<Map<String, dynamic>>();
  final validIds = scores.map((s) => s['deptId'] as String).toSet();
  debugPrint('📥 JSON\'da geçerli ${validIds.length} bölüm var');

  // 2. Firestore'daki tüm bölümleri çek
  final snap = await firestore.collection('departments').get();
  debugPrint('📊 Firestore\'da toplam ${snap.docs.length} bölüm dokümanı var');

  // 3. Orphan tespiti (JSON'da olmayan)
  final toDelete = <DocumentReference>[];
  final keptForReviews = <String>[];

  for (final doc in snap.docs) {
    if (validIds.contains(doc.id)) continue;
    final reviewCount = (doc.data()['reviewCount'] as num?)?.toInt() ?? 0;
    if (reviewCount > 0) {
      keptForReviews.add(doc.id);
      continue;
    }
    toDelete.add(doc.reference);
  }

  debugPrint('🗑️  Silinecek: ${toDelete.length} doküman');
  debugPrint('🛡️  Yorumlu olduğu için korunan: ${keptForReviews.length}');
  for (final id in keptForReviews) {
    debugPrint('   - $id');
  }

  // 4. Batch ile sil
  var batch = firestore.batch();
  var count = 0;
  var batchNum = 0;
  for (final ref in toDelete) {
    batch.delete(ref);
    count++;
    if (count % 400 == 0) {
      await batch.commit();
      batchNum++;
      debugPrint('✅ Batch $batchNum gönderildi (400 doküman)');
      batch = firestore.batch();
    }
  }
  if (toDelete.isNotEmpty && count % 400 != 0) {
    await batch.commit();
    debugPrint('✅ Son batch gönderildi. Toplam silinen: ${toDelete.length}');
  }
}
