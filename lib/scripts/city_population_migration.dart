import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// `cities/{cityId}` dokümanlarına `population` alanını backfill eder.
///
/// Kullanım: debug/admin akışından `CityPopulationMigration().run()`.
class CityPopulationMigration {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CityPopulationMigration({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // Yaklaşık güncel şehir nüfusları (TÜİK ölçeğinde, tam doğruluk şart değil).
  static const Map<String, int> _populationByCityId = {
    '34': 15655924, // İstanbul
    '06': 5807012, // Ankara
    '35': 4493675, // İzmir
    '07': 2696967, // Antalya
    '26': 921630, // Eskişehir
    '16': 3219000, // Bursa
    '17': 570499, // Çanakkale
    '58': 650401, // Sivas
    '61': 822270, // Trabzon
    '33': 1938389, // Mersin
    '19': 528351, // Çorum
  };

  Future<CityPopulationMigrationReport> run() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Yetkisiz erişim: Lütfen giriş yapın.');
    }

    final snapshot = await _db.collection('cities').get();
    var updated = 0;
    var skipped = 0;
    var missingPopulation = 0;

    var batch = _db.batch();
    var batchCount = 0;

    for (final doc in snapshot.docs) {
      final cityId = doc.id;
      final population = _populationByCityId[cityId];
      if (population == null) {
        missingPopulation++;
        continue;
      }

      final current = (doc.data()['population'] as num?)?.toInt();
      if (current == population) {
        skipped++;
        continue;
      }

      batch.set(
        doc.reference,
        {'population': population},
        SetOptions(merge: true),
      );
      batchCount++;
      updated++;

      if (batchCount >= 450) {
        await batch.commit();
        batch = _db.batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    final report = CityPopulationMigrationReport(
      totalCities: snapshot.docs.length,
      updatedCities: updated,
      skippedCities: skipped,
      missingPopulationCities: missingPopulation,
    );
    debugPrint('[CityPopulationMigration] $report');
    return report;
  }
}

class CityPopulationMigrationReport {
  final int totalCities;
  final int updatedCities;
  final int skippedCities;
  final int missingPopulationCities;

  const CityPopulationMigrationReport({
    required this.totalCities,
    required this.updatedCities,
    required this.skippedCities,
    required this.missingPopulationCities,
  });

  @override
  String toString() {
    return 'total=$totalCities, updated=$updatedCities, '
        'skipped=$skippedCities, missingPopulation=$missingPopulationCities';
  }
}
