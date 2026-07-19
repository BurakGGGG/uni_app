import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/core/utils/city_helper.dart';
import 'package:uni_app/features/assistant/domain/chat_nlu_client.dart';
import 'package:uni_app/features/assistant/domain/tercih_lexicon.dart';
import 'package:uni_app/features/assistant/domain/tercih_nlu.dart';
import 'package:uni_app/features/preference_wizard/domain/similar_programs.dart';

void main() {
  // Gerçek asset adlarının temsili bir alt kümesi — üretimde
  // allScoredDepartmentsProvider'dan gelir.
  final nlu = TercihNlu(
    cityMap: CityHelper.cityMap,
    deptNames: {
      'Bilgisayar Mühendisliği',
      'Psikoloji',
      'Tıp',
      'Hukuk',
      'İşletme',
      'Elektrik-Elektronik Mühendisliği',
      'İngiliz Dili ve Edebiyatı',
      'Diş Hekimliği',
      'Hemşirelik',
      'Mimarlık',
      'İngilizce Öğretmenliği',
      'Türkçe Öğretmenliği',
      'Rehberlik ve Psikolojik Danışmanlık',
      'Tarih',
      'İktisat',
      'Yazılım Mühendisliği',
      'Moleküler Biyoloji ve Genetik',
    },
  );

  group('sayılar — sıralama/puan', () {
    test('"sıralamam 80.000" → rank', () {
      final i = nlu.parse('sıralamam 80.000');
      expect(i.rank, 80000);
      expect(i.score, isNull);
      expect(i.unresolved, isEmpty);
    });

    test('"80 bin" bağlamsız → büyüklükten sıralama', () {
      final i = nlu.parse('80 bin');
      expect(i.rank, 80000);
      expect(i.score, isNull);
    });

    test('"450 aldım" → puan', () {
      final i = nlu.parse('450 aldım');
      expect(i.score, 450);
      expect(i.rank, isNull);
      expect(i.unresolved, isEmpty);
    });

    test('"puanım 462,5" → ondalık puan', () {
      expect(nlu.parse('puanım 462,5').score, 462.5);
    });

    test('"sıralamam 1,5 milyon" → 1.500.000', () {
      final i = nlu.parse('sıralamam 1,5 milyon, ne yapabilirim');
      expect(i.rank, 1500000);
      expect(i.unresolved, isEmpty);
    });

    test('"sıralamam 80 binlerde" → ekli çarpan', () {
      expect(nlu.parse('sıralamam 80 binlerde').rank, 80000);
    });

    test('"puanım 480 sıralamam 12 bin" → iki alan birden', () {
      final i = nlu.parse('puanım 480 sıralamam 12 bin');
      expect(i.score, 480);
      expect(i.rank, 12000);
    });

    test('"%50 burslu" → sayı burs oranıdır, puan değil', () {
      final i = nlu.parse('%50 burslu olsun');
      expect(i.score, isNull);
      expect(i.rank, isNull);
      expect(i.onlyScholarship, isTrue);
    });

    test('"2 yıllık" → süre kalıbı, puan değil', () {
      final i = nlu.parse('2 yıllık bölüm bakıyorum');
      expect(i.score, isNull);
      expect(i.programTypes, {'Önlisans'});
      expect(i.scoreType, 'TYT'); // önlisans TYT ile yerleştirir
    });

    test('"sıralamam 82500" ayraçsız da çalışır', () {
      final i = nlu.parse('sıralamam 82500 samsun ya da ordu');
      expect(i.rank, 82500);
      expect(i.cityIds, {'55', '52'});
    });
  });

  group('puan türü', () {
    test('"sayısaldan 215 bin sıralama" → SAY + rank', () {
      final i = nlu.parse('sayısaldan 215 bin sıralama');
      expect(i.scoreType, 'SAY');
      expect(i.rank, 215000);
    });

    test('"eşit ağırlık 340 puan" → EA + puan', () {
      final i = nlu.parse('eşit ağırlık 340 puan');
      expect(i.scoreType, 'EA');
      expect(i.score, 340);
    });

    test('"ea 120 bin" → kısaltma', () {
      final i = nlu.parse('ea 120 bin');
      expect(i.scoreType, 'EA');
      expect(i.rank, 120000);
    });

    test('"sözelim, Ankara\'da tarih okumak istiyorum" → SÖZ + il + bölüm',
        () {
      final i = nlu.parse("sözelim, Ankara'da tarih okumak istiyorum");
      expect(i.scoreType, 'SÖZ');
      expect(i.cityIds, {'06'});
      expect(i.depts.single.label, 'Tarih');
    });

    test('"dil puanım 400" → DİL', () {
      final i = nlu.parse('dil puanım 400');
      expect(i.scoreType, 'DİL');
      expect(i.score, 400);
    });

    test('"tyt 350 puan önlisans" → TYT + Önlisans', () {
      final i = nlu.parse('tyt 350 puan önlisans');
      expect(i.scoreType, 'TYT');
      expect(i.score, 350);
      expect(i.programTypes, {'Önlisans'});
    });

    test('"İngiliz dili" puan türü DİL sanılmaz', () {
      final i = nlu.parse('İngiliz dili ve edebiyatı okumak istiyorum');
      expect(i.scoreType, isNull);
      expect(i.depts.single.label, 'İngiliz Dili ve Edebiyatı');
      expect(i.languages, isEmpty);
    });
  });

  group('şehirler — ek toleransı ve takma adlar', () {
    test("\"İstanbul'da\" kesme işaretiyle", () {
      expect(nlu.parse("İstanbul'da okumak istiyorum").cityIds, {'34'});
    });

    test('"istanbul veya ankarada" — eksiz + bitişik ekli', () {
      expect(
        nlu.parse('istanbul veya ankarada okumak isterim').cityIds,
        {'34', '06'},
      );
    });

    test('"İzmir\'deki vakıf üniversiteleri" → il + tür', () {
      final i = nlu.parse("İzmir'deki vakıf üniversiteleri");
      expect(i.cityIds, {'35'});
      expect(i.uniTypes, {'Vakıf'});
      expect(i.unresolved, isEmpty);
    });

    test('"urfa da hukuk" → takma ad', () {
      final i = nlu.parse('urfa da hukuk');
      expect(i.cityIds, {'63'});
      expect(i.depts.single.label, 'Hukuk');
    });

    test('"maraşta hemşirelik" → takma ad + ek', () {
      final i = nlu.parse('maraşta hemşirelik');
      expect(i.cityIds, {'46'});
      expect(i.depts.single.label, 'Hemşirelik');
    });

    test("\"Van'da\" kısa il adı", () {
      expect(nlu.parse("Van'da okumak istiyorum").cityIds, {'65'});
    });

    test("\"Muş'ta\" kısa il adı", () {
      final i = nlu.parse("Muş'ta hemşirelik okurum");
      expect(i.cityIds, {'49'});
    });

    test('"bölüm seçemedim" Bolu sanılmaz', () {
      final i = nlu.parse('bölüm seçemedim');
      expect(i.cityIds, isEmpty);
      expect(i.hasAny, isFalse);
      expect(i.unresolved, 'secemedim');
    });
  });

  group('bölüm adları', () {
    test('"bilgisayar mühendisliği istiyorum" → tam ad', () {
      final i = nlu.parse('bilgisayar mühendisliği istiyorum');
      expect(i.depts.single.label, 'Bilgisayar Mühendisliği');
      expect(i.depts.single.query,
          'Bilgisayar Mühendisliği'.toLowerCase());
    });

    test('"psikolojiyi düşünüyorum ama rehberlik ve psikolojik danışmanlık '
        'da olur" → iki bölüm', () {
      final i = nlu.parse('psikolojiyi düşünüyorum ama rehberlik ve '
          'psikolojik danışmanlık da olur');
      expect(i.depts, hasLength(2));
      expect(i.depts.map((d) => d.label),
          contains('Rehberlik ve Psikolojik Danışmanlık'));
      expect(i.depts.map((d) => d.label), contains('Psikoloji'));
    });

    test('"İngilizce Öğretmenliği" dil kısıtı sanılmaz', () {
      final i = nlu.parse('İngilizce Öğretmenliği istiyorum');
      expect(i.depts.single.label, 'İngilizce Öğretmenliği');
      expect(i.languages, isEmpty);
    });

    test('"türkçe öğretmenliği" de dil kısıtı sanılmaz', () {
      final i = nlu.parse('türkçe öğretmenliği düşünüyorum');
      expect(i.depts.single.label, 'Türkçe Öğretmenliği');
      expect(i.languages, isEmpty);
    });

    test('"işletme okumak istiyorum" → İşletme', () {
      expect(nlu.parse('işletme okumak istiyorum').depts.single.label,
          'İşletme');
    });

    test('"tıpta okumak istiyorum" → ekli kısa ad', () {
      expect(
          nlu.parse('tıpta okumak istiyorum').depts.single.label, 'Tıp');
    });
  });

  group('meslek sözlüğü', () {
    test('"doktor olmak istiyorum" → Tıp + sağlık ilgisi', () {
      final i = nlu.parse('doktor olmak istiyorum');
      expect(i.depts.single.query, 'tıp');
      expect(i.interestKeys, contains('saglik'));
      expect(i.unresolved, isEmpty);
    });

    test('"avukat olmak istiyorum" → Hukuk', () {
      final i = nlu.parse('avukat olmak istiyorum');
      expect(i.depts.single.query, 'hukuk');
      expect(i.interestKeys, contains('hukuk'));
    });

    test('"yazılımcı olmak istiyorum" → yalnız yumuşak ilgi', () {
      final i = nlu.parse('yazılımcı olmak istiyorum');
      expect(i.depts, isEmpty);
      expect(i.interestKeys, {'bilgisayar'});
    });

    test('"öğretmen olmak istiyorum" → tüm öğretmenlikleri kapsayan sorgu',
        () {
      final i = nlu.parse('öğretmen olmak istiyorum');
      expect(i.depts.single.query, 'öğretmenliği');
      expect(i.interestKeys, contains('egitim'));
    });

    test('"diş hekimi olmak istiyorum" → iki kelimelik meslek', () {
      final i = nlu.parse('diş hekimi olmak istiyorum');
      expect(i.depts.single.label, 'Diş Hekimliği');
      expect(i.interestKeys, contains('saglik'));
    });
  });

  group('kısıtlar', () {
    test('"ingilizce psikoloji burslu" → dil + bölüm + burs', () {
      final i = nlu.parse('ingilizce psikoloji burslu');
      expect(i.languages, {'İngilizce'});
      expect(i.depts.single.label, 'Psikoloji');
      expect(i.onlyScholarship, isTrue);
    });

    test('"hem devlet hem burslu vakıf olabilir" → iki tür + burs', () {
      final i = nlu.parse('hem devlet hem burslu vakıf olabilir');
      expect(i.uniTypes, {'Devlet', 'Vakıf'});
      expect(i.onlyScholarship, isTrue);
      expect(i.unresolved, isEmpty);
    });

    test('"özel üniversite" → Vakıf', () {
      expect(nlu.parse('özel üniversite olsun').uniTypes, {'Vakıf'});
    });

    test('burs anılmazsa onlyScholarship null kalır', () {
      expect(nlu.parse('devlet istiyorum').onlyScholarship, isNull);
    });
  });

  group('karışık cümleler ve anlaşılamayanlar', () {
    test('tek mesajda dört alan: il + tür + bölüm + sıralama', () {
      final i = nlu.parse("İstanbul'da devlet üniversitesinde psikoloji "
          'istiyorum, sıralamam 80 bin');
      expect(i.cityIds, {'34'});
      expect(i.uniTypes, {'Devlet'});
      expect(i.depts.single.label, 'Psikoloji');
      expect(i.rank, 80000);
      expect(i.unresolved, isEmpty);
    });

    test('selamlaşma hiçbir alan doldurmaz', () {
      final i = nlu.parse('merhaba nasılsın');
      expect(i.hasAny, isFalse);
      expect(i.unresolved, isNotEmpty);
    });

    test('saçma girdi unresolved olarak kalır', () {
      final i = nlu.parse('asdf qwer');
      expect(i.hasAny, isFalse);
      expect(i.unresolved, 'asdf qwer');
    });

    test('boş girdi güvenlidir', () {
      final i = nlu.parse('   ');
      expect(i.hasAny, isFalse);
      expect(i.unresolved, isEmpty);
    });
  });

  group('groundRemote — sunucu çıkarımı kapalı kümelere oturur', () {
    test('geçerli adlar çözülür, uydurmalar sessizce düşer', () {
      final i = nlu.groundRemote(const RemoteParse(
        scoreType: 'SAY',
        rank: 80000,
        cities: ['İstanbul', 'Atlantis'],
        uniTypes: ['Devlet', 'Belediye'],
        depts: ['Psikoloji', 'Simya'],
      ));
      expect(i.scoreType, 'SAY');
      expect(i.rank, 80000);
      expect(i.cityIds, {'34'});
      expect(i.uniTypes, {'Devlet'});
      expect(i.depts.single.label, 'Psikoloji');
      expect(i.unresolved, isEmpty);
    });

    test('geçersiz tür ve sınır dışı sayılar elenir', () {
      final i = nlu.groundRemote(const RemoteParse(
        scoreType: 'XYZ',
        rank: 5000000,
        score: 900,
      ));
      expect(i.scoreType, isNull);
      expect(i.rank, isNull);
      expect(i.score, isNull);
      expect(i.hasAny, isFalse);
    });

    test('meslek adı sunucudan gelse de sözlükten geçer', () {
      final i = nlu.groundRemote(const RemoteParse(depts: ['Öğretmenlik']));
      expect(i.depts.single.query, 'öğretmenliği');
      expect(i.interestKeys, contains('egitim'));
    });
  });

  group('sözlük bütünlüğü', () {
    test('lexicon ilgi anahtarları interestAreas ile eşleşir', () {
      final valid = interestAreas.map((a) => a.key).toSet();
      final all = [
        ...professionLexicon.values,
        ...professionBigrams.values,
      ];
      for (final entry in all) {
        for (final key in entry.interestKeys) {
          expect(valid, contains(key), reason: '${entry.label} → $key');
        }
      }
    });

    test('lexicon bölüm sorguları küçük harftir (motor sözleşmesi)', () {
      for (final entry in [
        ...professionLexicon.values,
        ...professionBigrams.values,
      ]) {
        final q = entry.deptQuery;
        if (q == null) continue;
        expect(q, q.toLowerCase(), reason: entry.label);
      }
    });

    test('puan türü değerleri profil sözleşmesindekilerdir', () {
      const valid = {'TYT', 'SAY', 'EA', 'SÖZ', 'DİL'};
      for (final v in [
        ...scoreTypeExact.values,
        ...scoreTypeStemmed.values,
      ]) {
        expect(valid, contains(v));
      }
    });
  });
}
