import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/assistant/domain/robot_brain.dart';
import 'package:uni_app/features/assistant/domain/robot_scripts.dart';

void main() {
  setUp(() => RobotScripts.languageCode = 'tr');
  tearDown(() => RobotScripts.languageCode = 'tr');

  group('RobotBrain.calcSummary', () {
    test('ilk kayıt → calc.first ailesi, yer tutucular dolu', () {
      final msg = RobotBrain.calcSummary(
        const CalcResultContext(bestType: 'SAY', rankText: '85.600'),
        seed: 1,
      );
      expect(msg.id, startsWith('calc.first.'));
      expect(msg.text, contains('SAY'));
      expect(msg.text, contains('85.600'));
      expect(msg.text, isNot(contains('{')));
    });

    test('net artışı → calc.progress, delta metni geçer', () {
      final msg = RobotBrain.calcSummary(
        const CalcResultContext(
          bestType: 'EA',
          rankText: '42.000',
          netDelta: 12.5,
          deltaText: '+12,5',
        ),
        seed: 1,
      );
      expect(msg.id, startsWith('calc.progress.'));
      expect(msg.text, contains('+12,5'));
    });

    test('net düşüşü → calc.regress', () {
      final msg = RobotBrain.calcSummary(
        const CalcResultContext(
          bestType: 'TYT',
          rankText: '120.000',
          netDelta: -4.0,
          deltaText: '-4,0',
        ),
      );
      expect(msg.id, startsWith('calc.regress.'));
    });

    test('küçük fark → calc.steady (±0.5 bandı)', () {
      final msg = RobotBrain.calcSummary(
        const CalcResultContext(
          bestType: 'SÖZ',
          rankText: '60.000',
          netDelta: 0.25,
          deltaText: '+0,3',
        ),
      );
      expect(msg.id, startsWith('calc.steady.'));
    });

    test('İngilizce dilde EN script ailesi konuşur', () {
      RobotScripts.languageCode = 'en';
      final msg = RobotBrain.calcSummary(
        const CalcResultContext(bestType: 'SAY', rankText: '85,600'),
        seed: 0,
      );
      expect(msg.id, startsWith('calc.first.'));
      expect(msg.text.toLowerCase(), contains('rank'));
      expect(msg.text, isNot(contains('sıra')));
    });

    test('sıra yoksa tire ile düşer, süslü parantez kalmaz', () {
      final msg = RobotBrain.calcSummary(
        const CalcResultContext(bestType: 'DİL'),
      );
      expect(msg.text, contains('—'));
      expect(msg.text, isNot(contains('{rank}')));
    });

    test('sıra modu → calc.rank ailesi, sıra ve puan yer tutucuları dolu', () {
      final msg = RobotBrain.calcSummary(
        const CalcResultContext(
          bestType: 'SAY',
          rankText: '45.000',
          fromRank: true,
          scoreText: '451,1',
        ),
        seed: 0,
      );
      expect(msg.id, startsWith('calc.rank.'));
      expect(msg.text, contains('45.000'));
      expect(msg.text, contains('451,1'));
      expect(msg.text, contains('SAY'));
      expect(msg.text, isNot(contains('{')));
      // Sırayı kullanıcı girdi — "tahminî sıra" dili kullanılmamalı.
      expect(msg.text, isNot(contains('tahminî')));
    });

    test('sıra modu net deltasını yok sayar (ilerleme ailesine düşmez)', () {
      final msg = RobotBrain.calcSummary(
        const CalcResultContext(
          bestType: 'SAY',
          rankText: '45.000',
          netDelta: 12.5,
          deltaText: '+12,5',
          fromRank: true,
          scoreText: '451,1',
        ),
        seed: 1,
      );
      expect(msg.id, startsWith('calc.rank.'));
    });

    test('sıra modu İngilizcede de kendi ailesini konuşur', () {
      RobotScripts.languageCode = 'en';
      final msg = RobotBrain.calcSummary(
        const CalcResultContext(
          bestType: 'SAY',
          rankText: '45,000',
          fromRank: true,
          scoreText: '451.1',
        ),
        seed: 0,
      );
      expect(msg.id, startsWith('calc.rank.'));
      expect(msg.text, contains('45,000'));
      expect(msg.text, isNot(contains('{')));
    });
  });
}
