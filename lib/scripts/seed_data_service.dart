import 'package:cloud_firestore/cloud_firestore.dart';

class SeedDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> uploadSeedData() async {
    final batch = _firestore.batch();

    // 1. Şehirler
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
      batch.set(ref, city);
    }

    // 2. Üniversiteler (25 Devlet, 5 Vakıf = Toplam 30)
    final universities = [
      // İstanbul (4 Devlet, 3 Vakıf)
      {'id': 'bogazici', 'cityId': '34', 'name': 'Boğaziçi Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Türkiye\'nin en köklü devlet üniversitelerinden biri.', 'establishedYear': 1863, 'website': 'boun.edu.tr'},
      {'id': 'itu', 'cityId': '34', 'name': 'İstanbul Teknik Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Teknik alanda öncü eğitim kurumu.', 'establishedYear': 1773, 'website': 'itu.edu.tr'},
      {'id': 'istanbul_uni', 'cityId': '34', 'name': 'İstanbul Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Tarihi kampüsüyle ünlü devlet üniversitesi.', 'establishedYear': 1453, 'website': 'istanbul.edu.tr'},
      {'id': 'yildiz_teknik', 'cityId': '34', 'name': 'Yıldız Teknik Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Köklü bir teknik üniversite.', 'establishedYear': 1911, 'website': 'yildiz.edu.tr'},
      {'id': 'koc', 'cityId': '34', 'name': 'Koç Üniversitesi', 'type': 'Vakıf', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Türkiye\'nin önde gelen vakıf üniversitesi.', 'establishedYear': 1993, 'website': 'ku.edu.tr'},
      {'id': 'sabanci', 'cityId': '34', 'name': 'Sabancı Üniversitesi', 'type': 'Vakıf', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Disiplinlerarası eğitime önem veren vakıf üniversitesi.', 'establishedYear': 1994, 'website': 'sabanciuniv.edu'},
      {'id': 'bilgi', 'cityId': '34', 'name': 'İstanbul Bilgi Üniversitesi', 'type': 'Vakıf', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Şehir merkezinde modern vakıf üniversitesi.', 'establishedYear': 1996, 'website': 'bilgi.edu.tr'},

      // Ankara (4 Devlet, 1 Vakıf)
      {'id': 'odtu', 'cityId': '06', 'name': 'Orta Doğu Teknik Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Büyük orman kampüsüyle efsanevi üniversite.', 'establishedYear': 1956, 'website': 'metu.edu.tr'},
      {'id': 'hacettepe', 'cityId': '06', 'name': 'Hacettepe Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Tıp ve sağlık bilimlerinde lider.', 'establishedYear': 1967, 'website': 'hacettepe.edu.tr'},
      {'id': 'ankara_uni', 'cityId': '06', 'name': 'Ankara Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Cumhuriyetin ilk üniversitesi.', 'establishedYear': 1946, 'website': 'ankara.edu.tr'},
      {'id': 'gazi', 'cityId': '06', 'name': 'Gazi Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Özellikle eğitim fakültesiyle ünlü.', 'establishedYear': 1926, 'website': 'gazi.edu.tr'},
      {'id': 'bilkent', 'cityId': '06', 'name': 'İhsan Doğramacı Bilkent Üniversitesi', 'type': 'Vakıf', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Türkiye\'nin ilk vakıf üniversitesi.', 'establishedYear': 1984, 'website': 'bilkent.edu.tr'},

      // İzmir (3 Devlet, 1 Vakıf)
      {'id': 'ege', 'cityId': '35', 'name': 'Ege Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Ege bölgesinin en köklü kurumu.', 'establishedYear': 1955, 'website': 'ege.edu.tr'},
      {'id': 'dokuz_eylul', 'cityId': '35', 'name': 'Dokuz Eylül Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Geniş öğrenci kapasitesiyle büyük devlet üniversitesi.', 'establishedYear': 1982, 'website': 'deu.edu.tr'},
      {'id': 'iyte', 'cityId': '35', 'name': 'İzmir Yüksek Teknoloji Enstitüsü', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Urla\'da teknoloji odaklı araştırma üniversitesi.', 'establishedYear': 1992, 'website': 'iyte.edu.tr'},
      {'id': 'yasar', 'cityId': '35', 'name': 'Yaşar Üniversitesi', 'type': 'Vakıf', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'İzmir\'in önde gelen vakıf üniversitesi.', 'establishedYear': 2001, 'website': 'yasar.edu.tr'},

      // Antalya (2 Devlet)
      {'id': 'akdeniz', 'cityId': '07', 'name': 'Akdeniz Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Turizm ve tıp alanlarında güçlü.', 'establishedYear': 1982, 'website': 'akdeniz.edu.tr'},
      {'id': 'alanya', 'cityId': '07', 'name': 'Alanya Alaaddin Keykubat Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Alanya\'da gelişmekte olan devlet üniversitesi.', 'establishedYear': 2015, 'website': 'alanya.edu.tr'},

      // Eskişehir (3 Devlet)
      {'id': 'anadolu', 'cityId': '26', 'name': 'Anadolu Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Büyük kampüsü ve açıköğretimiyle ünlü.', 'establishedYear': 1958, 'website': 'anadolu.edu.tr'},
      {'id': 'ogu', 'cityId': '26', 'name': 'Eskişehir Osmangazi Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Eskişehir\'in köklü teknik ve sağlık üniversitesi.', 'establishedYear': 1993, 'website': 'ogu.edu.tr'},
      {'id': 'estu', 'cityId': '26', 'name': 'Eskişehir Teknik Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Eski Anadolu Üni. havacılık ve mühendislik bilimlerinden ayrılan.', 'establishedYear': 2018, 'website': 'eskisehir.edu.tr'},

      // Bursa (2 Devlet)
      {'id': 'uludag', 'cityId': '16', 'name': 'Bursa Uludağ Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Marmara bölgesinin büyük araştırma üniversitesi.', 'establishedYear': 1975, 'website': 'uludag.edu.tr'},
      {'id': 'btu', 'cityId': '16', 'name': 'Bursa Teknik Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Yenilikçi teknik üniversite.', 'establishedYear': 2010, 'website': 'btu.edu.tr'},

      // Çanakkale (1 Devlet)
      {'id': 'comu', 'cityId': '17', 'name': 'Çanakkale Onsekiz Mart Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Boğaza nazır muhteşem kampüsüyle.', 'establishedYear': 1992, 'website': 'comu.edu.tr'},

      // Sivas (2 Devlet)
      {'id': 'cumhuriyet', 'cityId': '58', 'name': 'Sivas Cumhuriyet Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Büyük ve köklü devlet üniversitesi.', 'establishedYear': 1974, 'website': 'cumhuriyet.edu.tr'},
      {'id': 'sivas_btu', 'cityId': '58', 'name': 'Sivas Bilim ve Teknoloji Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Savunma sanayii ve teknoloji odaklı.', 'establishedYear': 2018, 'website': 'sivas.edu.tr'},

      // Trabzon (2 Devlet)
      {'id': 'ktu', 'cityId': '61', 'name': 'Karadeniz Teknik Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Karadeniz bölgesinin teknik altyapısı güçlü üniversitesi.', 'establishedYear': 1955, 'website': 'ktu.edu.tr'},
      {'id': 'trabzon_uni', 'cityId': '61', 'name': 'Trabzon Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'KTÜ bünyesinden ayrılıp kurulan devlet üniversitesi.', 'establishedYear': 2018, 'website': 'trabzon.edu.tr'},

      // Mersin (2 Devlet)
      {'id': 'mersin_uni', 'cityId': '33', 'name': 'Mersin Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Akdeniz sahilinde büyük kampüslü devlet üniversitesi.', 'establishedYear': 1992, 'website': 'mersin.edu.tr'},
      {'id': 'tarsus', 'cityId': '33', 'name': 'Tarsus Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Gelişen yeni devlet üniversitesi.', 'establishedYear': 2018, 'website': 'tarsus.edu.tr'},
    ];

    for (var uni in universities) {
      final ref = _firestore.collection('universities').doc(uni['id'] as String);
      batch.set(ref, uni);
    }

    // 3. Bölümler (Her üniversiteye 10 bölüm eklenecek, Toplam 300 kayıt)
    final departmentTemplates = [
      {'name': 'Tıp', 'faculty': 'Tıp Fakültesi', 'type': 'Lisans', 'language': 'Türkçe'},
      {'name': 'Hukuk', 'faculty': 'Hukuk Fakültesi', 'type': 'Lisans', 'language': 'Türkçe'},
      {'name': 'Diş Hekimliği', 'faculty': 'Diş Hekimliği Fakültesi', 'type': 'Lisans', 'language': 'Türkçe'},
      {'name': 'Veterinerlik', 'faculty': 'Veteriner Fakültesi', 'type': 'Lisans', 'language': 'Türkçe'},
      {'name': 'Bilgisayar Mühendisliği', 'faculty': 'Mühendislik Fakültesi', 'type': 'Lisans', 'language': 'İngilizce'},
      {'name': 'Elektrik-Elektronik Mühendisliği', 'faculty': 'Mühendislik Fakültesi', 'type': 'Lisans', 'language': 'İngilizce'},
      {'name': 'Yazılım Mühendisliği', 'faculty': 'Mühendislik Fakültesi', 'type': 'Lisans', 'language': 'Türkçe'},
      {'name': 'Gastronomi ve Mutfak Sanatları', 'faculty': 'Turizm Fakültesi', 'type': 'Lisans', 'language': 'Türkçe'},
      {'name': 'Bilgisayar Programcılığı', 'faculty': 'Meslek Yüksekokulu', 'type': 'Önlisans', 'language': 'Türkçe'},
      {'name': 'İlk ve Acil Yardım (Paramedik)', 'faculty': 'Sağlık Hizmetleri MYO', 'type': 'Önlisans', 'language': 'Türkçe'},
    ];

    for (var uni in universities) {
      final uniId = uni['id'] as String;
      
      for (var deptTemplate in departmentTemplates) {
        // ID olarak uniId_departmentName formatında benzersiz bir ID oluşturuyoruz.
        // Boşlukları ve Türkçe karakterleri temizlemek daha iyi olabilir ama
        // Firestore ID olarak string kabul ettiği için basitçe _ ekliyoruz.
        final slugName = deptTemplate['name']!.toLowerCase().replaceAll(' ', '_').replaceAll('ç', 'c').replaceAll('ş', 's').replaceAll('ı', 'i').replaceAll('ğ', 'g').replaceAll('ü', 'u').replaceAll('ö', 'o').replaceAll('(', '').replaceAll(')', '');
        final deptId = '${uniId}_$slugName';

        final ref = _firestore.collection('departments').doc(deptId);
        
        batch.set(ref, {
          'id': deptId,
          'universityId': uniId,
          'name': deptTemplate['name'],
          'faculty': deptTemplate['faculty'],
          'type': deptTemplate['type'],
          'language': deptTemplate['language'],
        });
      }
    }

    // Toplu yazmayı çalıştır
    await batch.commit();
  }
}
