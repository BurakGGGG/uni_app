import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// JSON'daki puanları Firestore'daki bölüm kayıtlarına yükler.
/// Önce mevcut departments koleksiyonunu tamamen siler, sonra sıfırdan yazar.
///
/// Kullanım: Profil > Debug > "Bölüm Puanlarını Yükle (Debug)"
class DepartmentScoresMigration {
  final _db = FirebaseFirestore.instance;

  /// Tüm departments koleksiyonunu silip sıfırdan yükler.
  Future<MigrationReport> run() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Yetkisiz erişim: Lütfen giriş yapın.');
    }

    // ── 1. Mevcut departments'ı sil ──
    debugPrint('🗑️ Mevcut departments siliniyor...');
    final deleteCount = await _deleteAllDepartments();
    debugPrint('✅ $deleteCount eski bölüm silindi');

    // ── 2. JSON'u oku ──
    debugPrint('📂 JSON dosyası okunuyor...');
    final jsonStr = await rootBundle.loadString('assets/data/department_scores.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final scores = (data['scores'] as List).cast<Map<String, dynamic>>();
    debugPrint('📥 ${scores.length} bölüm yüklenecek');

    // ── 3. Batch ile Firestore'a yaz ──
    var batch = _db.batch();
    var batchCount = 0;
    var batchNumber = 1;
    var totalWritten = 0;

    for (var i = 0; i < scores.length; i++) {
      final score = scores[i];
      final deptId = score['deptId'] as String;
      final ref = _db.collection('departments').doc(deptId);

      final scoreData = {
        'year': score['year'],
        'scoreType': score['scoreType'],
        'baseScore': score['baseScore'],
        'ranking': score['ranking'],
        'quota': score['quota'],
        'placedCount': score['placedCount'],
        'previousYears': score['previousYears'] ?? {},
      };

      // Metadata alanları
      final metadata = <String, dynamic>{};
      void putIfNonEmpty(String key, dynamic value) {
        if (value == null) return;
        if (value is String && value.isEmpty) return;
        metadata[key] = value;
      }

      putIfNonEmpty('id', deptId);
      putIfNonEmpty('universityId', score['universityId']);
      putIfNonEmpty('name', score['name']);
      putIfNonEmpty('faculty', score['faculty']);
      putIfNonEmpty('type', score['type']);
      putIfNonEmpty('language', score['language']);
      putIfNonEmpty('duration', score['duration']);
      putIfNonEmpty('description', score['description']);

      // set ile tam yeni doküman oluştur (merge yok, temiz kayıt)
      batch.set(ref, {
        ...metadata,
        'scoreData': scoreData,
        'lastScoreUpdate': FieldValue.serverTimestamp(),
        'baseScore': score['baseScore'],
        'ranking': score['ranking'],
        'quota': score['quota'],
        'scoreType': score['scoreType'],
      });

      batchCount++;
      totalWritten++;

      if (batchCount >= 490) {
        try {
          await batch.commit();
          debugPrint('✅ Batch #$batchNumber gönderildi ($totalWritten/${scores.length})');
        } catch (e) {
          debugPrint('❌ Batch #$batchNumber HATA: $e');
          return MigrationReport(
            total: scores.length,
            successful: totalWritten - batchCount,
            failed: batchCount,
            errorMessage: 'Batch #$batchNumber hata: $e',
          );
        }
        batch = _db.batch();
        batchCount = 0;
        batchNumber++;
      }
    }

    // Son kalan batch
    if (batchCount > 0) {
      try {
        await batch.commit();
        debugPrint('✅ Batch #$batchNumber (son) gönderildi ($totalWritten/${scores.length})');
      } catch (e) {
        debugPrint('❌ Son batch HATA: $e');
        return MigrationReport(
          total: scores.length,
          successful: totalWritten - batchCount,
          failed: batchCount,
          errorMessage: 'Son batch hata: $e',
        );
      }
    }

    final report = MigrationReport(
      total: scores.length,
      successful: totalWritten,
      failed: 0,
    );
    debugPrint('🎉 Migration tamamlandı: $report');
    return report;
  }

  /// departments koleksiyonundaki tüm dokümanları siler
  Future<int> _deleteAllDepartments() async {
    var totalDeleted = 0;

    // Firestore'da büyük koleksiyonları batch ile sil
    while (true) {
      final snapshot = await _db
          .collection('departments')
          .limit(490)
          .get();

      if (snapshot.docs.isEmpty) break;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      totalDeleted += snapshot.docs.length;
      debugPrint('  🗑️ $totalDeleted silindi...');
    }

    return totalDeleted;
  }
}

class MigrationReport {
  final int total;
  final int successful;
  final int failed;
  final String? errorMessage;

  const MigrationReport({
    required this.total,
    required this.successful,
    required this.failed,
    this.errorMessage,
  });

  @override
  String toString() =>
      '$successful/$total güncellendi'
      '${failed > 0 ? ", $failed başarısız" : ""}'
      '${errorMessage != null ? " | $errorMessage" : ""}';
}
