import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeedDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _random = Random();

  /// ±range aralığında rastgele sapma üretir
  double _randomize(double base, double range) {
    return base + (_random.nextDouble() * range * 2) - range;
  }

  int _randomizeInt(int base, int range) {
    return base + _random.nextInt(range * 2) - range;
  }

  Future<void> uploadSeedData() async {
    // Firestore batch max 500 yazma destekler, bu yüzden
    // şehirler + üniversiteler ayrı, bölümler ayrı batch'te yazılacak.

    // ── 1. Şehirler + Üniversiteler Batch ─────────────────────────
    final batch1 = _firestore.batch();

    final cities = [
      {'id': '34', 'name': 'İstanbul', 'plateCode': '34', 'photoUrl': 'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=800', 'totalUniversityCount': 61, 'appUniversityCount': 7},
      {'id': '06', 'name': 'Ankara', 'plateCode': '06', 'photoUrl': 'https://images.unsplash.com/photo-1587974928442-77dc3e0dba72?w=800', 'totalUniversityCount': 21, 'appUniversityCount': 5},
      {'id': '35', 'name': 'İzmir', 'plateCode': '35', 'photoUrl': 'https://images.unsplash.com/photo-1580227184285-06ec1da6b9c9?w=800', 'totalUniversityCount': 10, 'appUniversityCount': 4},
      {'id': '07', 'name': 'Antalya', 'plateCode': '07', 'photoUrl': 'https://images.unsplash.com/photo-1542051812871-7575088c5589?w=800', 'totalUniversityCount': 5, 'appUniversityCount': 2},
      {'id': '26', 'name': 'Eskişehir', 'plateCode': '26', 'photoUrl': 'https://images.unsplash.com/photo-1622542730304-4df15a9ab350?w=800', 'totalUniversityCount': 3, 'appUniversityCount': 3},
      {'id': '16', 'name': 'Bursa', 'plateCode': '16', 'photoUrl': 'https://images.unsplash.com/photo-1596482811342-63dbb480749d?w=800', 'totalUniversityCount': 3, 'appUniversityCount': 2},
      {'id': '17', 'name': 'Çanakkale', 'plateCode': '17', 'photoUrl': 'https://images.unsplash.com/photo-1600862024765-b778749a0ce6?w=800', 'totalUniversityCount': 1, 'appUniversityCount': 1},
      {'id': '58', 'name': 'Sivas', 'plateCode': '58', 'photoUrl': 'https://images.unsplash.com/photo-1610486001097-42f02cb8f344?w=800', 'totalUniversityCount': 2, 'appUniversityCount': 2},
      {'id': '61', 'name': 'Trabzon', 'plateCode': '61', 'photoUrl': 'https://images.unsplash.com/photo-1602781489020-f1c50b69165b?w=800', 'totalUniversityCount': 3, 'appUniversityCount': 2},
      {'id': '33', 'name': 'Mersin', 'plateCode': '33', 'photoUrl': 'https://images.unsplash.com/photo-1602336306028-2615cb38d01d?w=800', 'totalUniversityCount': 4, 'appUniversityCount': 2},
    ];

    for (var city in cities) {
      final ref = _firestore.collection('cities').doc(city['id'] as String);
      batch1.set(ref, city);
    }

    final universities = [
      {'id': 'bogazici', 'cityId': '34', 'name': 'Boğaziçi Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Türkiye\'nin en köklü devlet üniversitelerinden biri.', 'establishedYear': 1863, 'website': 'boun.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'itu', 'cityId': '34', 'name': 'İstanbul Teknik Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Teknik alanda öncü eğitim kurumu.', 'establishedYear': 1773, 'website': 'itu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'istanbul_uni', 'cityId': '34', 'name': 'İstanbul Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Tarihi kampüsüyle ünlü devlet üniversitesi.', 'establishedYear': 1453, 'website': 'istanbul.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'yildiz_teknik', 'cityId': '34', 'name': 'Yıldız Teknik Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Köklü bir teknik üniversite.', 'establishedYear': 1911, 'website': 'yildiz.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'koc', 'cityId': '34', 'name': 'Koç Üniversitesi', 'type': 'Vakıf', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Türkiye\'nin önde gelen vakıf üniversitesi.', 'establishedYear': 1993, 'website': 'ku.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'sabanci', 'cityId': '34', 'name': 'Sabancı Üniversitesi', 'type': 'Vakıf', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Disiplinlerarası eğitime önem veren vakıf üniversitesi.', 'establishedYear': 1994, 'website': 'sabanciuniv.edu', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'bilgi', 'cityId': '34', 'name': 'İstanbul Bilgi Üniversitesi', 'type': 'Vakıf', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Şehir merkezinde modern vakıf üniversitesi.', 'establishedYear': 1996, 'website': 'bilgi.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'odtu', 'cityId': '06', 'name': 'Orta Doğu Teknik Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Büyük orman kampüsüyle efsanevi üniversite.', 'establishedYear': 1956, 'website': 'metu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'hacettepe', 'cityId': '06', 'name': 'Hacettepe Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Tıp ve sağlık bilimlerinde lider.', 'establishedYear': 1967, 'website': 'hacettepe.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'ankara_uni', 'cityId': '06', 'name': 'Ankara Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Cumhuriyetin ilk üniversitesi.', 'establishedYear': 1946, 'website': 'ankara.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'gazi', 'cityId': '06', 'name': 'Gazi Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Özellikle eğitim fakültesiyle ünlü.', 'establishedYear': 1926, 'website': 'gazi.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'bilkent', 'cityId': '06', 'name': 'İhsan Doğramacı Bilkent Üniversitesi', 'type': 'Vakıf', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Türkiye\'nin ilk vakıf üniversitesi.', 'establishedYear': 1984, 'website': 'bilkent.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'ege', 'cityId': '35', 'name': 'Ege Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Ege bölgesinin en köklü kurumu.', 'establishedYear': 1955, 'website': 'ege.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'dokuz_eylul', 'cityId': '35', 'name': 'Dokuz Eylül Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Geniş öğrenci kapasitesiyle büyük devlet üniversitesi.', 'establishedYear': 1982, 'website': 'deu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'iyte', 'cityId': '35', 'name': 'İzmir Yüksek Teknoloji Enstitüsü', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Urla\'da teknoloji odaklı araştırma üniversitesi.', 'establishedYear': 1992, 'website': 'iyte.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'yasar', 'cityId': '35', 'name': 'Yaşar Üniversitesi', 'type': 'Vakıf', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'İzmir\'in önde gelen vakıf üniversitesi.', 'establishedYear': 2001, 'website': 'yasar.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'akdeniz', 'cityId': '07', 'name': 'Akdeniz Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Turizm ve tıp alanlarında güçlü.', 'establishedYear': 1982, 'website': 'akdeniz.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'alanya', 'cityId': '07', 'name': 'Alanya Alaaddin Keykubat Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Alanya\'da gelişmekte olan devlet üniversitesi.', 'establishedYear': 2015, 'website': 'alanya.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'anadolu', 'cityId': '26', 'name': 'Anadolu Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Büyük kampüsü ve açıköğretimiyle ünlü.', 'establishedYear': 1958, 'website': 'anadolu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'ogu', 'cityId': '26', 'name': 'Eskişehir Osmangazi Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Eskişehir\'in köklü teknik ve sağlık üniversitesi.', 'establishedYear': 1993, 'website': 'ogu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'estu', 'cityId': '26', 'name': 'Eskişehir Teknik Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Eski Anadolu Üni. havacılık ve mühendislik bilimlerinden ayrılan.', 'establishedYear': 2018, 'website': 'eskisehir.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'uludag', 'cityId': '16', 'name': 'Bursa Uludağ Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Marmara bölgesinin büyük araştırma üniversitesi.', 'establishedYear': 1975, 'website': 'uludag.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'btu', 'cityId': '16', 'name': 'Bursa Teknik Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Yenilikçi teknik üniversite.', 'establishedYear': 2010, 'website': 'btu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'comu', 'cityId': '17', 'name': 'Çanakkale Onsekiz Mart Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Boğaza nazır muhteşem kampüsüyle.', 'establishedYear': 1992, 'website': 'comu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'cumhuriyet', 'cityId': '58', 'name': 'Sivas Cumhuriyet Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Büyük ve köklü devlet üniversitesi.', 'establishedYear': 1974, 'website': 'cumhuriyet.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'sivas_btu', 'cityId': '58', 'name': 'Sivas Bilim ve Teknoloji Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Savunma sanayii ve teknoloji odaklı.', 'establishedYear': 2018, 'website': 'sivas.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'ktu', 'cityId': '61', 'name': 'Karadeniz Teknik Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Karadeniz bölgesinin teknik altyapısı güçlü üniversitesi.', 'establishedYear': 1955, 'website': 'ktu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'trabzon_uni', 'cityId': '61', 'name': 'Trabzon Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'KTÜ bünyesinden ayrılıp kurulan devlet üniversitesi.', 'establishedYear': 2018, 'website': 'trabzon.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'mersin_uni', 'cityId': '33', 'name': 'Mersin Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Akdeniz sahilinde büyük kampüslü devlet üniversitesi.', 'establishedYear': 1992, 'website': 'mersin.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
      {'id': 'tarsus', 'cityId': '33', 'name': 'Tarsus Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Gelişen yeni devlet üniversitesi.', 'establishedYear': 2018, 'website': 'tarsus.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}},
    ];

    for (var uni in universities) {
      final ref = _firestore.collection('universities').doc(uni['id'] as String);
      batch1.set(ref, uni);
    }

    await batch1.commit();

    // ── 2. Bölümler (30 üni × 10 bölüm = 300 kayıt) ──────────────
    final departmentTemplates = [
      {'name': 'Tıp', 'faculty': 'Tıp Fakültesi', 'type': 'Lisans', 'language': 'Türkçe', 'baseScore': 512.4, 'ranking': 15000, 'scoreType': 'SAY', 'duration': 6, 'quota': 120},
      {'name': 'Hukuk', 'faculty': 'Hukuk Fakültesi', 'type': 'Lisans', 'language': 'Türkçe', 'baseScore': 430.5, 'ranking': 35000, 'scoreType': 'EA', 'duration': 4, 'quota': 150},
      {'name': 'Diş Hekimliği', 'faculty': 'Diş Hekimliği Fakültesi', 'type': 'Lisans', 'language': 'Türkçe', 'baseScore': 475.2, 'ranking': 25000, 'scoreType': 'SAY', 'duration': 5, 'quota': 80},
      {'name': 'Veterinerlik', 'faculty': 'Veteriner Fakültesi', 'type': 'Lisans', 'language': 'Türkçe', 'baseScore': 380.1, 'ranking': 120000, 'scoreType': 'SAY', 'duration': 5, 'quota': 90},
      {'name': 'Bilgisayar Mühendisliği', 'faculty': 'Mühendislik Fakültesi', 'type': 'Lisans', 'language': 'İngilizce', 'baseScore': 490.8, 'ranking': 20000, 'scoreType': 'SAY', 'duration': 4, 'quota': 100},
      {'name': 'Elektrik-Elektronik Mühendisliği', 'faculty': 'Mühendislik Fakültesi', 'type': 'Lisans', 'language': 'İngilizce', 'baseScore': 460.3, 'ranking': 45000, 'scoreType': 'SAY', 'duration': 4, 'quota': 90},
      {'name': 'Yazılım Mühendisliği', 'faculty': 'Mühendislik Fakültesi', 'type': 'Lisans', 'language': 'Türkçe', 'baseScore': 455.0, 'ranking': 50000, 'scoreType': 'SAY', 'duration': 4, 'quota': 80},
      {'name': 'Gastronomi ve Mutfak Sanatları', 'faculty': 'Turizm Fakültesi', 'type': 'Lisans', 'language': 'Türkçe', 'baseScore': 395.6, 'ranking': 80000, 'scoreType': 'SÖZ', 'duration': 4, 'quota': 60},
      {'name': 'Bilgisayar Programcılığı', 'faculty': 'Meslek Yüksekokulu', 'type': 'Önlisans', 'language': 'Türkçe', 'baseScore': 320.4, 'ranking': 400000, 'scoreType': 'TYT', 'duration': 2, 'quota': 70},
      {'name': 'İlk ve Acil Yardım (Paramedik)', 'faculty': 'Sağlık Hizmetleri MYO', 'type': 'Önlisans', 'language': 'Türkçe', 'baseScore': 345.8, 'ranking': 350000, 'scoreType': 'TYT', 'duration': 2, 'quota': 65},
    ];

    var batchCount = 0;
    var currentBatch = _firestore.batch();

    for (var uni in universities) {
      final uniId = uni['id'] as String;

      for (var deptTemplate in departmentTemplates) {
        final slugName = deptTemplate['name'].toString().toLowerCase()
            .replaceAll(' ', '_').replaceAll('ç', 'c').replaceAll('ş', 's')
            .replaceAll('ı', 'i').replaceAll('ğ', 'g').replaceAll('ü', 'u')
            .replaceAll('ö', 'o').replaceAll('(', '').replaceAll(')', '');
        final deptId = '${uniId}_$slugName';
        final ref = _firestore.collection('departments').doc(deptId);

        // Her üniversite için puanları ±20, sıralamayı ±5000, kontenjanı ±15 randomize et
        final baseScore = _randomize((deptTemplate['baseScore'] as num).toDouble(), 20);
        final ranking = _randomizeInt(deptTemplate['ranking'] as int, 5000).clamp(1000, 900000);
        final quota = _randomizeInt(deptTemplate['quota'] as int, 15).clamp(20, 300);

        currentBatch.set(ref, {
          'id': deptId,
          'universityId': uniId,
          'name': deptTemplate['name'],
          'faculty': deptTemplate['faculty'],
          'type': deptTemplate['type'],
          'language': deptTemplate['language'],
          'baseScore': double.parse(baseScore.toStringAsFixed(1)),
          'ranking': ranking,
          'scoreType': deptTemplate['scoreType'],
          'duration': deptTemplate['duration'],
          'quota': quota,
          'avgRating': 0.0,
          'reviewCount': 0,
          'categoryRatings': <String, double>{},
        });

        batchCount++;
        if (batchCount >= 490) {
          await currentBatch.commit();
          currentBatch = _firestore.batch();
          batchCount = 0;
        }
      }
    }

    if (batchCount > 0) {
      await currentBatch.commit();
    }
  }
}
