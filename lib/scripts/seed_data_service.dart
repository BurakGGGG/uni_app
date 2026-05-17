import 'dart:math';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
    // ── 0. Güvenlik Kontrolü ─────────────────────────────────────
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Yetkisiz erişim: Lütfen giriş yapın.');
    }
    final token = await user.getIdTokenResult();
    // if (token.claims?['admin'] != true) {
    //   throw Exception('Yetkisiz erişim: Sadece adminler seed datası yükleyebilir.');
    // }

    // Firestore batch max 500 yazma destekler, bu yüzden
    // şehirler + üniversiteler ayrı, bölümler ayrı batch'te yazılacak.

    // ── 1. Şehirler + Üniversiteler Batch ─────────────────────────
    final batch1 = _firestore.batch();

    final cities = [
      {'id': '34', 'name': 'İstanbul', 'plateCode': '34', 'photoUrl': 'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=800', 'totalUniversityCount': 61, 'appUniversityCount': 6, 'brandPrimaryHex': '#B96790', 'brandSecondaryHex': '#D790AC', 'brandUseDarkOverlay': false},
      {'id': '06', 'name': 'Ankara', 'plateCode': '06', 'photoUrl': 'https://images.unsplash.com/photo-1587974928442-77dc3e0dba72?w=800', 'totalUniversityCount': 21, 'appUniversityCount': 5, 'brandPrimaryHex': '#5A38A2', 'brandSecondaryHex': '#7C51BD', 'brandUseDarkOverlay': false},
      {'id': '35', 'name': 'İzmir', 'plateCode': '35', 'photoUrl': 'https://images.unsplash.com/photo-1580227184285-06ec1da6b9c9?w=800', 'totalUniversityCount': 10, 'appUniversityCount': 4, 'brandPrimaryHex': '#1DABDE', 'brandSecondaryHex': '#4DC3DF', 'brandUseDarkOverlay': false},
      {'id': '07', 'name': 'Antalya', 'plateCode': '07', 'photoUrl': 'https://images.unsplash.com/photo-1542051812871-7575088c5589?w=800', 'totalUniversityCount': 5, 'appUniversityCount': 2, 'brandPrimaryHex': '#51B59C', 'brandSecondaryHex': '#966BC0', 'brandUseDarkOverlay': false},
      {'id': '26', 'name': 'Eskişehir', 'plateCode': '26', 'photoUrl': 'https://images.unsplash.com/photo-1622542730304-4df15a9ab350?w=800', 'totalUniversityCount': 3, 'appUniversityCount': 3, 'brandPrimaryHex': '#154B7D', 'brandSecondaryHex': '#60B7E8', 'brandUseDarkOverlay': false},
      {'id': '16', 'name': 'Bursa', 'plateCode': '16', 'photoUrl': 'https://images.unsplash.com/photo-1596482811342-63dbb480749d?w=800', 'totalUniversityCount': 3, 'appUniversityCount': 2, 'brandPrimaryHex': '#412466', 'brandSecondaryHex': '#7B5BA8', 'brandUseDarkOverlay': false},
      {'id': '17', 'name': 'Çanakkale', 'plateCode': '17', 'photoUrl': 'https://images.unsplash.com/photo-1600862024765-b778749a0ce6?w=800', 'totalUniversityCount': 1, 'appUniversityCount': 1, 'brandPrimaryHex': '#4EBFCE', 'brandSecondaryHex': '#F47BA8', 'brandUseDarkOverlay': false},
      {'id': '58', 'name': 'Sivas', 'plateCode': '58', 'photoUrl': 'https://images.unsplash.com/photo-1610486001097-42f02cb8f344?w=800', 'totalUniversityCount': 2, 'appUniversityCount': 2, 'brandPrimaryHex': '#3773B4', 'brandSecondaryHex': '#82B0DA', 'brandUseDarkOverlay': false},
      {'id': '61', 'name': 'Trabzon', 'plateCode': '61', 'photoUrl': 'https://images.unsplash.com/photo-1602781489020-f1c50b69165b?w=800', 'totalUniversityCount': 3, 'appUniversityCount': 2, 'brandPrimaryHex': '#4C9DC2', 'brandSecondaryHex': '#223E5A', 'brandUseDarkOverlay': false},
      {'id': '33', 'name': 'Mersin', 'plateCode': '33', 'photoUrl': 'https://images.unsplash.com/photo-1602336306028-2615cb38d01d?w=800', 'totalUniversityCount': 4, 'appUniversityCount': 2, 'brandPrimaryHex': '#F97E26', 'brandSecondaryHex': '#FFAA75', 'brandUseDarkOverlay': false},
      {'id': '19', 'name': 'Çorum', 'plateCode': '19', 'photoUrl': 'https://images.unsplash.com/photo-1635224747018-23ada6b1ab02?w=800', 'totalUniversityCount': 2, 'appUniversityCount': 1, 'brandPrimaryHex': '#AB5B86', 'brandSecondaryHex': '#361641', 'brandUseDarkOverlay': false},
      {'id': '38', 'name': 'Kayseri', 'plateCode': '38', 'photoUrl': 'https://images.unsplash.com/photo-1596395371609-b6b66804561f?w=800', 'totalUniversityCount': 3, 'appUniversityCount': 1, 'brandPrimaryHex': '#2D4B7A', 'brandSecondaryHex': '#6082B6', 'brandUseDarkOverlay': false},
      {'id': '44', 'name': 'Malatya', 'plateCode': '44', 'photoUrl': 'https://images.unsplash.com/photo-1628080061386-8a0a9965b394?w=800', 'totalUniversityCount': 2, 'appUniversityCount': 1, 'brandPrimaryHex': '#C84B31', 'brandSecondaryHex': '#ECDBBA', 'brandUseDarkOverlay': false},
      {'id': '55', 'name': 'Samsun', 'plateCode': '55', 'photoUrl': 'https://images.unsplash.com/photo-1606192131238-d6bbfbc49d8a?w=800', 'totalUniversityCount': 2, 'appUniversityCount': 1, 'brandPrimaryHex': '#1DABDE', 'brandSecondaryHex': '#4DC3DF', 'brandUseDarkOverlay': false},
      {'id': '42', 'name': 'Konya', 'plateCode': '42', 'photoUrl': 'https://images.unsplash.com/photo-1598048145816-368297b41e3d?w=800', 'totalUniversityCount': 4, 'appUniversityCount': 1, 'brandPrimaryHex': '#51B59C', 'brandSecondaryHex': '#966BC0', 'brandUseDarkOverlay': false},
      {'id': '43', 'name': 'Kütahya', 'plateCode': '43', 'photoUrl': 'https://images.unsplash.com/photo-1596482811342-63dbb480749d?w=800', 'totalUniversityCount': 2, 'appUniversityCount': 1, 'brandPrimaryHex': '#154B7D', 'brandSecondaryHex': '#60B7E8', 'brandUseDarkOverlay': false},
      {'id': '41', 'name': 'Kocaeli', 'plateCode': '41', 'photoUrl': 'https://images.unsplash.com/photo-1587974928442-77dc3e0dba72?w=800', 'totalUniversityCount': 2, 'appUniversityCount': 1, 'brandPrimaryHex': '#412466', 'brandSecondaryHex': '#7B5BA8', 'brandUseDarkOverlay': false},
      {'id': '54', 'name': 'Sakarya', 'plateCode': '54', 'photoUrl': 'https://images.unsplash.com/photo-1580227184285-06ec1da6b9c9?w=800', 'totalUniversityCount': 2, 'appUniversityCount': 1, 'brandPrimaryHex': '#5A38A2', 'brandSecondaryHex': '#7C51BD', 'brandUseDarkOverlay': false},
      {'id': '14', 'name': 'Bolu', 'plateCode': '14', 'photoUrl': 'https://images.unsplash.com/photo-1542051812871-7575088c5589?w=800', 'totalUniversityCount': 1, 'appUniversityCount': 1, 'brandPrimaryHex': '#3773B4', 'brandSecondaryHex': '#82B0DA', 'brandUseDarkOverlay': false},
      {'id': '67', 'name': 'Zonguldak', 'plateCode': '67', 'photoUrl': 'https://images.unsplash.com/photo-1622542730304-4df15a9ab350?w=800', 'totalUniversityCount': 1, 'appUniversityCount': 1, 'brandPrimaryHex': '#4EBFCE', 'brandSecondaryHex': '#F47BA8', 'brandUseDarkOverlay': false},
      {'id': '65', 'name': 'Van', 'plateCode': '65', 'photoUrl': 'https://images.unsplash.com/photo-1600862024765-b778749a0ce6?w=800', 'totalUniversityCount': 1, 'appUniversityCount': 1, 'brandPrimaryHex': '#B96790', 'brandSecondaryHex': '#D790AC', 'brandUseDarkOverlay': false},
      {'id': '25', 'name': 'Erzurum', 'plateCode': '25', 'photoUrl': 'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=800', 'totalUniversityCount': 2, 'appUniversityCount': 1, 'brandPrimaryHex': '#4C9DC2', 'brandSecondaryHex': '#223E5A', 'brandUseDarkOverlay': false},
      {'id': '27', 'name': 'Gaziantep', 'plateCode': '27', 'photoUrl': 'https://images.unsplash.com/photo-1610486001097-42f02cb8f344?w=800', 'totalUniversityCount': 4, 'appUniversityCount': 1, 'brandPrimaryHex': '#F97E26', 'brandSecondaryHex': '#FFAA75', 'brandUseDarkOverlay': false},
      {'id': '01', 'name': 'Adana', 'plateCode': '01', 'photoUrl': 'https://images.unsplash.com/photo-1602781489020-f1c50b69165b?w=800', 'totalUniversityCount': 2, 'appUniversityCount': 1, 'brandPrimaryHex': '#AB5B86', 'brandSecondaryHex': '#361641', 'brandUseDarkOverlay': false},
      {'id': '20', 'name': 'Denizli', 'plateCode': '20', 'photoUrl': 'https://images.unsplash.com/photo-1602336306028-2615cb38d01d?w=800', 'totalUniversityCount': 1, 'appUniversityCount': 1, 'brandPrimaryHex': '#1DABDE', 'brandSecondaryHex': '#4DC3DF', 'brandUseDarkOverlay': false},
      {'id': '46', 'name': 'Kahramanmaraş', 'plateCode': '46', 'photoUrl': 'https://images.unsplash.com/photo-1635224747018-23ada6b1ab02?w=800', 'totalUniversityCount': 2, 'appUniversityCount': 1, 'brandPrimaryHex': '#51B59C', 'brandSecondaryHex': '#966BC0', 'brandUseDarkOverlay': false},
      {'id': '45', 'name': 'Manisa', 'plateCode': '45', 'photoUrl': 'https://images.unsplash.com/photo-1596395371609-b6b66804561f?w=800', 'totalUniversityCount': 1, 'appUniversityCount': 1, 'brandPrimaryHex': '#154B7D', 'brandSecondaryHex': '#60B7E8', 'brandUseDarkOverlay': false},
      {'id': '32', 'name': 'Isparta', 'plateCode': '32', 'photoUrl': 'https://images.unsplash.com/photo-1628080061386-8a0a9965b394?w=800', 'totalUniversityCount': 2, 'appUniversityCount': 1, 'brandPrimaryHex': '#412466', 'brandSecondaryHex': '#7B5BA8', 'brandUseDarkOverlay': false},
      {'id': '78', 'name': 'Karabük', 'plateCode': '78', 'photoUrl': 'https://images.unsplash.com/photo-1606192131238-d6bbfbc49d8a?w=800', 'totalUniversityCount': 1, 'appUniversityCount': 1, 'brandPrimaryHex': '#5A38A2', 'brandSecondaryHex': '#7C51BD', 'brandUseDarkOverlay': false},
      {'id': '60', 'name': 'Tokat', 'plateCode': '60', 'photoUrl': 'https://images.unsplash.com/photo-1598048145816-368297b41e3d?w=800', 'totalUniversityCount': 1, 'appUniversityCount': 1, 'brandPrimaryHex': '#3773B4', 'brandSecondaryHex': '#82B0DA', 'brandUseDarkOverlay': false},
    ];

    for (var city in cities) {
      final ref = _firestore.collection('cities').doc(city['id'] as String);
      batch1.set(ref, city, SetOptions(merge: true));
    }

    final universities = [
      {'id': 'itu', 'cityId': '34', 'name': 'İstanbul Teknik Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Teknik alanda öncü eğitim kurumu.', 'establishedYear': 1773, 'website': 'itu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['İTÜ', 'Istanbul Teknik'], 'brandPrimaryHex': '#1A237E', 'brandSecondaryHex': '#283593'},
      {'id': 'istanbul_uni', 'cityId': '34', 'name': 'İstanbul Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Tarihi kampüsüyle ünlü devlet üniversitesi.', 'establishedYear': 1453, 'website': 'istanbul.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'distributed', 'aliases': ['İÜ'], 'brandPrimaryHex': '#1B5E20', 'brandSecondaryHex': '#2E7D32'},
      {'id': 'yildiz_teknik', 'cityId': '34', 'name': 'Yıldız Teknik Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Köklü bir teknik üniversite.', 'establishedYear': 1911, 'website': 'yildiz.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['YTÜ', 'Yıldız'], 'brandPrimaryHex': '#FFB300', 'brandSecondaryHex': '#0D47A1'},
      {'id': 'odtu', 'cityId': '06', 'name': 'Orta Doğu Teknik Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Büyük orman kampüsüyle efsanevi üniversite.', 'establishedYear': 1956, 'website': 'metu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['ODTÜ', 'METU', 'Orta Doğu'], 'brandPrimaryHex': '#D32F2F', 'brandSecondaryHex': '#EF5350'},
      {'id': 'hacettepe', 'cityId': '06', 'name': 'Hacettepe Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Tıp ve sağlık bilimlerinde lider.', 'establishedYear': 1967, 'website': 'hacettepe.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'distributed', 'aliases': ['HÜ', 'Hacettepe'], 'brandPrimaryHex': '#D32F2F', 'brandSecondaryHex': '#EF5350'},
      {'id': 'ankara_uni', 'cityId': '06', 'name': 'Ankara Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Cumhuriyetin ilk üniversitesi.', 'establishedYear': 1946, 'website': 'ankara.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'distributed', 'aliases': ['AÜ'], 'brandPrimaryHex': '#0D47A1', 'brandSecondaryHex': '#FFB300'},
      {'id': 'gazi', 'cityId': '06', 'name': 'Gazi Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Özellikle eğitim fakültesiyle ünlü.', 'establishedYear': 1926, 'website': 'gazi.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'block', 'aliases': ['GÜ', 'Gazi'], 'brandPrimaryHex': '#0D47A1', 'brandSecondaryHex': '#4DD0E1'},
      {'id': 'ege', 'cityId': '35', 'name': 'Ege Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Ege bölgesinin en köklü kurumu.', 'establishedYear': 1955, 'website': 'ege.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['EÜ', 'Ege'], 'brandPrimaryHex': '#0D47A1', 'brandSecondaryHex': '#1976D2'},
      {'id': 'dokuz_eylul', 'cityId': '35', 'name': 'Dokuz Eylül Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Geniş öğrenci kapasitesiyle büyük devlet üniversitesi.', 'establishedYear': 1982, 'website': 'deu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'distributed', 'aliases': ['DEÜ', 'Dokuz Eylül'], 'brandPrimaryHex': '#1A237E', 'brandSecondaryHex': '#303F9F'},
      {'id': 'akdeniz', 'cityId': '07', 'name': 'Akdeniz Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Turizm ve tıp alanlarında güçlü.', 'establishedYear': 1982, 'website': 'akdeniz.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['AKÜ', 'Akdeniz'], 'brandPrimaryHex': '#E65100', 'brandSecondaryHex': '#FF6D00'},
      {'id': 'alanya', 'cityId': '07', 'name': 'Alanya Alaaddin Keykubat Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Alanya\'da gelişmekte olan devlet üniversitesi.', 'establishedYear': 2015, 'website': 'alanya.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['ALKÜ', 'Alanya'], 'brandPrimaryHex': '#0277BD', 'brandSecondaryHex': '#039BE5'},
      {'id': 'anadolu', 'cityId': '26', 'name': 'Anadolu Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Büyük kampüsü ve açıköğretimiyle ünlü.', 'establishedYear': 1958, 'website': 'anadolu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['AÖF', 'Anadolu'], 'brandPrimaryHex': '#212121', 'brandSecondaryHex': '#424242'},
      {'id': 'ogu', 'cityId': '26', 'name': 'Eskişehir Osmangazi Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Eskişehir\'in köklü teknik ve sağlık üniversitesi.', 'establishedYear': 1993, 'website': 'ogu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['ESOGÜ', 'Osmangazi'], 'brandPrimaryHex': '#00ACC1', 'brandSecondaryHex': '#0D47A1'},
      {'id': 'estu', 'cityId': '26', 'name': 'Eskişehir Teknik Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Eski Anadolu Üni. havacılık ve mühendislik bilimlerinden ayrılan.', 'establishedYear': 2018, 'website': 'eskisehir.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['ESTÜ'], 'brandPrimaryHex': '#800000', 'brandSecondaryHex': '#500000'},
      {'id': 'uludag', 'cityId': '16', 'name': 'Bursa Uludağ Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Marmara bölgesinin büyük araştırma üniversitesi.', 'establishedYear': 1975, 'website': 'uludag.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['BUÜ', 'Uludağ'], 'brandPrimaryHex': '#00ACC1', 'brandSecondaryHex': '#0D47A1'},
      {'id': 'btu', 'cityId': '16', 'name': 'Bursa Teknik Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Yenilikçi teknik üniversite.', 'establishedYear': 2010, 'website': 'btu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'block', 'aliases': ['BTÜ'], 'brandPrimaryHex': '#0D47A1', 'brandSecondaryHex': '#1976D2'},
      {'id': 'comu', 'cityId': '17', 'name': 'Çanakkale Onsekiz Mart Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Boğaza nazır muhteşem kampüsüyle.', 'establishedYear': 1992, 'website': 'comu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['ÇOMÜ', '18 Mart'], 'brandPrimaryHex': '#D32F2F', 'brandSecondaryHex': '#212121'},
      {'id': 'cumhuriyet', 'cityId': '58', 'name': 'Sivas Cumhuriyet Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Büyük ve köklü devlet üniversitesi.', 'establishedYear': 1974, 'website': 'cumhuriyet.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['SCÜ', 'Cumhuriyet'], 'brandPrimaryHex': '#D32F2F', 'brandSecondaryHex': '#B71C1C'},
      {'id': 'sivas_btu', 'cityId': '58', 'name': 'Sivas Bilim ve Teknoloji Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Savunma sanayii ve teknoloji odaklı.', 'establishedYear': 2018, 'website': 'sivas.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'block', 'aliases': ['SBTÜ'], 'brandPrimaryHex': '#1A237E', 'brandSecondaryHex': '#283593'},
      {'id': 'ktu', 'cityId': '61', 'name': 'Karadeniz Teknik Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Karadeniz bölgesinin teknik altyapısı güçlü üniversitesi.', 'establishedYear': 1955, 'website': 'ktu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['KTÜ', 'Karadeniz Teknik'], 'brandPrimaryHex': '#1A237E', 'brandSecondaryHex': '#1565C0'},
      {'id': 'trabzon_uni', 'cityId': '61', 'name': 'Trabzon Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'KTÜ bünyesinden ayrılıp kurulan devlet üniversitesi.', 'establishedYear': 2018, 'website': 'trabzon.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['TRÜ'], 'brandPrimaryHex': '#004D40', 'brandSecondaryHex': '#00695C'},
      {'id': 'mersin_uni', 'cityId': '33', 'name': 'Mersin Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Akdeniz sahilinde büyük kampüslü devlet üniversitesi.', 'establishedYear': 1992, 'website': 'mersin.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['MEÜ'], 'brandPrimaryHex': '#E65100', 'brandSecondaryHex': '#FF8F00'},
      {'id': 'tarsus', 'cityId': '33', 'name': 'Tarsus Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Gelişen yeni devlet üniversitesi.', 'establishedYear': 2018, 'website': 'tarsus.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'distributed', 'aliases': ['TÜ'], 'brandPrimaryHex': '#1A237E', 'brandSecondaryHex': '#1976D2'},
      {'id': 'marmara', 'cityId': '34', 'name': 'Marmara Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Geniş lisans yelpazesi ve sosyal hayatıyla ünlü.', 'establishedYear': 1883, 'website': 'marmara.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['MÜ', 'Marmara'], 'brandPrimaryHex': '#0D47A1', 'brandSecondaryHex': '#1565C0'},
      {'id': 'hacibayram', 'cityId': '06', 'name': 'Ankara Hacı Bayram Veli Üniversitesi', 'type': 'Devlet', 'hasCampus': false, 'logoUrl': '', 'photoUrl': '', 'description': 'Gazi Üni\'den ayrılan, sosyal bilimler odaklı.', 'establishedYear': 2018, 'website': 'hbv.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'block', 'aliases': ['HBV', 'Hacı Bayram'], 'brandPrimaryHex': '#212121', 'brandSecondaryHex': '#D32F2F'},
      {'id': 'izmir_demokrasi', 'cityId': '35', 'name': 'İzmir Demokrasi Üniversitesi', 'type': 'Devlet', 'hasCampus': false, 'logoUrl': '', 'photoUrl': '', 'description': 'Karabağlar\'da blok yerleşkeli devlet üniversitesi.', 'establishedYear': 2016, 'website': 'idu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'block', 'aliases': ['İDÜ'], 'brandPrimaryHex': '#795548', 'brandSecondaryHex': '#C62828'},
      {'id': 'izmir_katipcelebi', 'cityId': '35', 'name': 'İzmir Katip Çelebi Üniversitesi', 'type': 'Devlet', 'hasCampus': false, 'logoUrl': '', 'photoUrl': '', 'description': 'Çiğli\'de dağınık kampüslü, tıp ağırlıklı.', 'establishedYear': 2010, 'website': 'ikcu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'distributed', 'aliases': ['İKÇÜ', 'Katip Çelebi'], 'brandPrimaryHex': '#B71C1C', 'brandSecondaryHex': '#880E4F'},
      {'id': 'aydin', 'cityId': '34', 'name': 'İstanbul Aydın Üniversitesi', 'type': 'Vakıf', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Florya kampüsü ile İstanbul\'un büyük vakıf üniversitelerinden.', 'establishedYear': 2003, 'website': 'aydin.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['İAÜ', 'Aydın'], 'brandPrimaryHex': '#0D47A1', 'brandSecondaryHex': '#1565C0'},
      {'id': 'gelisim', 'cityId': '34', 'name': 'İstanbul Gelişim Üniversitesi', 'type': 'Vakıf', 'hasCampus': false, 'logoUrl': '', 'photoUrl': '', 'description': 'Avcılar bölgesinde blok yerleşkeli vakıf üniversitesi.', 'establishedYear': 2008, 'website': 'gelisim.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'block', 'aliases': ['İGÜ', 'Gelişim'], 'brandPrimaryHex': '#1A237E', 'brandSecondaryHex': '#283593'},
      {'id': 'medipol', 'cityId': '34', 'name': 'İstanbul Medipol Üniversitesi', 'type': 'Vakıf', 'hasCampus': false, 'logoUrl': '', 'photoUrl': '', 'description': 'Sağlık bilimleri ve tıp odaklı vakıf üniversitesi.', 'establishedYear': 2009, 'website': 'medipol.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'block', 'aliases': ['Medipol'], 'brandPrimaryHex': '#1A237E', 'brandSecondaryHex': '#757575'},
      {'id': 'hitit', 'cityId': '19', 'name': 'Hitit Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Çorum\'un köklü devlet üniversitesi, kuzey kampüs alanı.', 'establishedYear': 2006, 'website': 'hitit.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['HÜ', 'Hitit'], 'brandPrimaryHex': '#FF8F00', 'brandSecondaryHex': '#1A237E'},
      {'id': 'erciyes', 'cityId': '38', 'name': 'Erciyes Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Kayseri\'nin köklü devlet üniversitesi.', 'establishedYear': 1978, 'website': 'erciyes.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['ERÜ'], 'brandPrimaryHex': '#1A3C8F', 'brandSecondaryHex': '#C41E3A'},
      {'id': 'inonu', 'cityId': '44', 'name': 'İnönü Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Malatya\'nın büyük devlet üniversitesi.', 'establishedYear': 1975, 'website': 'inonu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['İnönü'], 'brandPrimaryHex': '#F5A623', 'brandSecondaryHex': '#C88B18'},
      {'id': 'omu', 'cityId': '55', 'name': 'Ondokuz Mayıs Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Samsun\'un köklü devlet üniversitesi.', 'establishedYear': 1975, 'website': 'omu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['OMÜ'], 'brandPrimaryHex': '#3B5998', 'brandSecondaryHex': '#C0392B'},
      {'id': 'selcuk', 'cityId': '42', 'name': 'Selçuk Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Konya\'nın köklü devlet üniversitesi.', 'establishedYear': 1975, 'website': 'selcuk.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['SÜ'], 'brandPrimaryHex': '#D4A817', 'brandSecondaryHex': '#8B7312'},
      {'id': 'dpu', 'cityId': '43', 'name': 'Kütahya Dumlupınar Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Kütahya\'da büyük kampüslü devlet üniversitesi.', 'establishedYear': 1992, 'website': 'dpu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['DPÜ'], 'brandPrimaryHex': '#3D348B', 'brandSecondaryHex': '#6A5ACD'},
      {'id': 'kocaeli', 'cityId': '41', 'name': 'Kocaeli Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Kocaeli\'nin köklü devlet üniversitesi.', 'establishedYear': 1992, 'website': 'kocaeli.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['KOÜ'], 'brandPrimaryHex': '#1B9E5F', 'brandSecondaryHex': '#2C3E50'},
      {'id': 'sakarya', 'cityId': '54', 'name': 'Sakarya Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Sakarya\'nın büyük devlet üniversitesi.', 'establishedYear': 1992, 'website': 'sakarya.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['SAÜ'], 'brandPrimaryHex': '#1A3478', 'brandSecondaryHex': '#2C5AA0'},
      {'id': 'ibu', 'cityId': '14', 'name': 'Bolu Abant İzzet Baysal Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Bolu\'da doğa ile iç içe kampüslü devlet üniversitesi.', 'establishedYear': 1992, 'website': 'ibu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['AİBÜ', 'BAİBÜ'], 'brandPrimaryHex': '#1B7A3D', 'brandSecondaryHex': '#2E4C8A'},
      {'id': 'beun', 'cityId': '67', 'name': 'Zonguldak Bülent Ecevit Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Zonguldak\'ın köklü devlet üniversitesi.', 'establishedYear': 1992, 'website': 'beun.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['BEÜN'], 'brandPrimaryHex': '#D32F2F', 'brandSecondaryHex': '#B71C1C'},
      {'id': 'yyu', 'cityId': '65', 'name': 'Van Yüzüncü Yıl Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Van\'ın büyük kampüslü devlet üniversitesi.', 'establishedYear': 1982, 'website': 'yyu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['YYÜ'], 'brandPrimaryHex': '#1A5276', 'brandSecondaryHex': '#5DADE2'},
      {'id': 'atauni', 'cityId': '25', 'name': 'Atatürk Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Erzurum\'da kurulan köklü ve büyük devlet üniversitesi.', 'establishedYear': 1957, 'website': 'atauni.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['ATAÜNİ'], 'brandPrimaryHex': '#2E3A6E', 'brandSecondaryHex': '#C9A94E'},
      {'id': 'gantep', 'cityId': '27', 'name': 'Gaziantep Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Gaziantep\'in köklü devlet üniversitesi.', 'establishedYear': 1987, 'website': 'gantep.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['GAÜN'], 'brandPrimaryHex': '#1A2D5A', 'brandSecondaryHex': '#C0392B'},
      {'id': 'cu', 'cityId': '01', 'name': 'Çukurova Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Adana\'nın köklü ve büyük kampüslü devlet üniversitesi.', 'establishedYear': 1973, 'website': 'cu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['ÇÜ'], 'brandPrimaryHex': '#1E7B2C', 'brandSecondaryHex': '#0E5C1E'},
      {'id': 'pau', 'cityId': '20', 'name': 'Pamukkale Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Denizli\'nin büyük kampüslü devlet üniversitesi.', 'establishedYear': 1992, 'website': 'pau.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['PAÜ'], 'brandPrimaryHex': '#1A4C7A', 'brandSecondaryHex': '#4A90D9'},
      {'id': 'ksu', 'cityId': '46', 'name': 'Kahramanmaraş Sütçü İmam Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Kahramanmaraş\'ın köklü devlet üniversitesi.', 'establishedYear': 1992, 'website': 'ksu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['KSÜ'], 'brandPrimaryHex': '#343278', 'brandSecondaryHex': '#C0392B'},
      {'id': 'cbu', 'cityId': '45', 'name': 'Manisa Celâl Bayar Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Manisa\'nın büyük devlet üniversitesi.', 'establishedYear': 1992, 'website': 'cbu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['MCBÜ'], 'brandPrimaryHex': '#1A3478', 'brandSecondaryHex': '#4DC4E0'},
      {'id': 'sdu', 'cityId': '32', 'name': 'Süleyman Demirel Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Isparta\'nın köklü devlet üniversitesi.', 'establishedYear': 1992, 'website': 'sdu.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['SDÜ'], 'brandPrimaryHex': '#D42B2B', 'brandSecondaryHex': '#8B1A1A'},
      {'id': 'karabuk', 'cityId': '78', 'name': 'Karabük Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Karabük\'ün gelişen devlet üniversitesi.', 'establishedYear': 2007, 'website': 'karabuk.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['KBÜ'], 'brandPrimaryHex': '#3B6FA0', 'brandSecondaryHex': '#C0392B'},
      {'id': 'gop', 'cityId': '60', 'name': 'Tokat Gaziosmanpaşa Üniversitesi', 'type': 'Devlet', 'hasCampus': true, 'logoUrl': '', 'photoUrl': '', 'description': 'Tokat\'ın köklü devlet üniversitesi.', 'establishedYear': 1992, 'website': 'gop.edu.tr', 'avgRating': 0.0, 'reviewCount': 0, 'categoryRatings': <String, double>{}, 'campusLayout': 'campus', 'aliases': ['TOGÜ'], 'brandPrimaryHex': '#008B8B', 'brandSecondaryHex': '#4A1558'},
    ];

    for (var uni in universities) {
      final ref = _firestore.collection('universities').doc(uni['id'] as String);
      final uniData = Map<String, dynamic>.from(uni);
      uniData.remove('avgRating');
      uniData.remove('reviewCount');
      uniData.remove('categoryRatings');
      batch1.set(ref, uniData, SetOptions(merge: true));
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
        }, SetOptions(merge: true));

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

    // Mekan verileri (places_seed.json) henüz olmadığı için yoruma alındı.
    // await _seedPlaces();
  }

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
}
