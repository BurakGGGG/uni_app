import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/assistant/domain/robot_brain.dart';
import 'package:uni_app/features/assistant/domain/robot_message.dart';
import 'package:uni_app/features/assistant/domain/robot_mood.dart';
import 'package:uni_app/features/assistant/domain/robot_scripts.dart';
import 'package:uni_app/features/score_calculator/domain/models/match_result.dart';

/// Üni'nin bölüm/üniversite detayındaki kişisel yorumu.
/// Kapı kararı widget'ta; burada YALNIZ metin üretimi sınanır.
void main() {
  tearDown(() => RobotScripts.languageCode = 'tr');

  group('departmentVerdict', () {
    test('kategori başına ayrı id ve mood', () {
      final high = RobotBrain.departmentVerdict(MatchCategory.guaranteed);
      final target = RobotBrain.departmentVerdict(MatchCategory.target);
      final dream = RobotBrain.departmentVerdict(MatchCategory.dream);

      expect(high.id, 'dept.verdict.high');
      expect(target.id, 'dept.verdict.target');
      expect(dream.id, 'dept.verdict.dream');
      expect(high.mood, RobotMood.celebrating);
      expect(dream.mood, RobotMood.thinking);
    });

    // Dürüstlük kuralı: kategori bir tahmindir, garanti değil.
    test('her karar tahmin dili taşır, garanti vermez', () {
      for (final c in MatchCategory.values) {
        final text = RobotBrain.departmentVerdict(c).text.toLowerCase();
        expect(text, isNot(contains('garanti ederim')), reason: '$c');
        expect(text, isNot(contains('kesin')), reason: '$c');
      }
      // "Yüksek şans" en iddialı olan — açıkça garanti veremediğini söyler.
      expect(
        RobotBrain.departmentVerdict(MatchCategory.guaranteed).text,
        contains('garanti veremem'),
      );
    });

    test('tahmini sıralamada Üni bunu saklamaz', () {
      final plain = RobotBrain.departmentVerdict(MatchCategory.target);
      final estimated =
          RobotBrain.departmentVerdict(MatchCategory.target, estimated: true);

      expect(estimated.id, plain.id);
      expect(estimated.text, startsWith(plain.text));
      expect(estimated.text, contains('tahmin'));
      expect(estimated.text.length, greaterThan(plain.text.length));
    });

    test('İngilizce dilde de çalışır, id sabit kalır', () {
      final tr = RobotBrain.departmentVerdict(MatchCategory.guaranteed);
      RobotScripts.languageCode = 'en';
      final en = RobotBrain.departmentVerdict(MatchCategory.guaranteed);

      expect(en.id, tr.id);
      expect(en.text, isNot(tr.text));
      expect(en.text.toLowerCase(), contains("can't guarantee"));
    });
  });

  group('departmentNeedsRank', () {
    test('sihirbaza yönlendirir — bu davet ücretsiz kullanıcıya da gider', () {
      final msg = RobotBrain.departmentNeedsRank;
      expect(msg.id, 'dept.needRank');
      expect(msg.action, RobotAction.openWizard);
    });
  });

  group('universityFitSummary', () {
    test('sayılar metne yerleşir', () {
      final msg = RobotBrain.universityFitSummary(matching: 12, high: 4);
      expect(msg.id, 'uni.fit.summary');
      expect(msg.text, contains('12'));
      expect(msg.text, contains('4'));
      // Yer tutucu kalıntısı kalmamalı.
      expect(msg.text, isNot(contains('{')));
    });

    test('hiç uyan yoksa ayrı mesaj', () {
      final msg = RobotBrain.universityFitSummary(matching: 0, high: 0);
      expect(msg.id, 'uni.fit.none');
      expect(msg.mood, RobotMood.concerned);
    });

    test('özet de tahmin dili taşır', () {
      final msg = RobotBrain.universityFitSummary(matching: 5, high: 1);
      expect(msg.text.toLowerCase(), contains('tahmin'));
    });

    test('İngilizce özet de yer tutucu bırakmaz', () {
      RobotScripts.languageCode = 'en';
      final msg = RobotBrain.universityFitSummary(matching: 7, high: 2);
      expect(msg.text, contains('7'));
      expect(msg.text, isNot(contains('{')));
    });
  });
}
