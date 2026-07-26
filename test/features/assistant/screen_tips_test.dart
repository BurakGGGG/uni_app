import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/assistant/domain/robot_scripts.dart';
import 'package:uni_app/features/assistant/domain/screen_tips.dart';

/// Sekme ipuçları: Üni'nin "burası ne işe yarar, nasıl kullanılır" repliği.
///
/// Kilitlenen sözleşme: ana sayfada susar (orada zaten selamlıyor), her
/// sekmede o sekmenin DURUMUNA göre konuşur, her kimliğin metni iki dilde
/// de tanımlı.
void main() {
  tearDown(() => RobotScripts.languageCode = 'tr');

  group('hangi ekranda ne', () {
    test('ana sayfanın ipucu yok', () {
      expect(uniScreenTip(const ScreenTipContext(path: '/')), isNull);
      expect(screenHasTip('/'), isFalse);
    });

    test('tanınmayan yolda susar', () {
      expect(uniScreenTip(const ScreenTipContext(path: '/score-calculator')),
          isNull);
    });

    test('alt rotalar da sekmeye sayılır', () {
      // `/my-lists/abc` hâlâ Listelerim; ipucu kaybolmamalı.
      final tip = uniScreenTip(
        const ScreenTipContext(path: '/my-lists/abc', signedIn: true),
      );
      expect(tip?.id, 'screen.lists.empty');
    });

    test('keşfet tek ipucu verir', () {
      expect(
        uniScreenTip(const ScreenTipContext(path: '/explore'))?.id,
        'screen.explore',
      );
    });

    test('karşılaştırma tek ipucu verir', () {
      // Sekme bir SEÇİM ekranı; asıl karşılaştırma push edilen rotada açılıyor
      // ve balon oraya çıkmıyor — duruma göre çeşitlenecek bir şey yok.
      expect(
        uniScreenTip(const ScreenTipContext(path: '/compare'))?.id,
        'screen.compare',
      );
    });

    test('karşılaştırma ipucu Plus özelliği pazarlamaz', () {
      RobotScripts.languageCode = 'tr';
      final tr = RobotScripts.screenTip('screen.compare');
      RobotScripts.languageCode = 'en';
      final en = RobotScripts.screenTip('screen.compare');

      // Bölüm ve şehir karşılaştırması Plus'lı; Üni satış yapmaz, kilitli
      // özelliği davet gibi anlatmaz.
      for (final text in [tr.toLowerCase(), en.toLowerCase()]) {
        expect(text.contains('bölüm'), isFalse);
        expect(text.contains('şehir'), isFalse);
        expect(text.contains('department'), isFalse);
        expect(text.contains('city'), isFalse);
      }
    });

    test('listelerim: misafir, boş, yarım ve dolu ayrı ayrı', () {
      String? idFor({bool signedIn = true, int count = 0, bool hasList = true}) =>
          uniScreenTip(
            ScreenTipContext(
              path: '/my-lists',
              signedIn: signedIn,
              listCount: count,
              hasAnyList: hasList,
            ),
          )?.id;

      expect(idFor(signedIn: false), 'screen.lists.guest');
      expect(idFor(hasList: false), 'screen.lists.empty');
      // Liste kurulmuş ama içi boş: yine "kurmaya başla" ipucu.
      expect(idFor(count: 0), 'screen.lists.empty');
      expect(idFor(count: 9), 'screen.lists.partial');
      expect(idFor(count: 24), 'screen.lists.full');
    });

    test('profil oturuma göre değişir', () {
      expect(
        uniScreenTip(const ScreenTipContext(path: '/profile'))?.id,
        'screen.profile.guest',
      );
      expect(
        uniScreenTip(const ScreenTipContext(path: '/profile', signedIn: true))
            ?.id,
        'screen.profile',
      );
    });
  });

  group('metin', () {
    test('yarım listede sayılar yerine oturur', () {
      final tip = uniScreenTip(
        const ScreenTipContext(
          path: '/my-lists',
          signedIn: true,
          hasAnyList: true,
          listCount: 9,
        ),
      )!;

      expect(tip.text, contains('9'));
      expect(tip.text, contains('15'), reason: 'kalan hak: 24 − 9');
      // Doldurulmamış yer tutucu balonda "{count}" olarak görünürdü.
      expect(tip.text, isNot(contains('{')));
    });

    test('her ipucu kimliğinin metni iki dilde de var', () {
      final tr = RobotScripts.screenTipIds.toSet();
      RobotScripts.languageCode = 'en';
      final en = RobotScripts.screenTipIds.toSet();

      expect(en, tr);
      for (final id in en) {
        expect(RobotScripts.screenTip(id).trim(), isNotEmpty);
      }
    });

    test('üretilen tüm kimlikler tabloda tanımlı', () {
      // Motor tabloda olmayan bir id üretirse balon fırlatarak açılmaz.
      final produced = <String>{
        for (final ctx in _allContexts) uniScreenTip(ctx)!.id,
      };

      expect(produced.every(RobotScripts.screenTipIds.contains), isTrue);
      // Tabloda ölü metin de kalmasın.
      expect(RobotScripts.screenTipIds.toSet(), produced);
    });

    test('ipuçlu her önek gerçekten ipucu üretir', () {
      // `screenHasTip` ile `uniScreenTip` ayrı listelere bakarsa balon
      // sessizce hiç konuşmaz.
      for (final path in ['/explore', '/compare', '/my-lists', '/profile']) {
        expect(screenHasTip(path), isTrue, reason: path);
        expect(uniScreenTip(ScreenTipContext(path: path)), isNotNull,
            reason: path);
      }
    });
  });
}

/// Motorun üretebildiği tüm durumlar.
const _allContexts = <ScreenTipContext>[
  ScreenTipContext(path: '/explore'),
  ScreenTipContext(path: '/compare'),
  ScreenTipContext(path: '/my-lists'),
  ScreenTipContext(path: '/my-lists', signedIn: true),
  ScreenTipContext(
    path: '/my-lists',
    signedIn: true,
    hasAnyList: true,
    listCount: 9,
  ),
  ScreenTipContext(
    path: '/my-lists',
    signedIn: true,
    hasAnyList: true,
    listCount: 24,
  ),
  ScreenTipContext(path: '/profile'),
  ScreenTipContext(path: '/profile', signedIn: true),
];
