import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/assistant/domain/robot_brain.dart';
import 'package:uni_app/features/assistant/domain/robot_mood.dart';
import 'package:uni_app/features/assistant/domain/robot_scripts.dart';
import 'package:uni_app/features/assistant/domain/tercih_calendar.dart';
import 'package:uni_app/features/preference_wizard/domain/list_health.dart';

void main() {
  group('pick', () {
    test('aynı seed her zaman aynı varyantı verir', () {
      final a = RobotBrain.pick(RobotScripts.emptyList, seed: 7);
      final b = RobotBrain.pick(RobotScripts.emptyList, seed: 7);
      expect(a.id, b.id);
    });

    test('excludeId asla geri dönmez (birden çok varyantta)', () {
      final excluded = RobotScripts.emptyList.first.id;
      for (var seed = 0; seed < 10; seed++) {
        final picked = RobotBrain.pick(
          RobotScripts.emptyList,
          seed: seed,
          excludeId: excluded,
        );
        expect(picked.id, isNot(excluded));
      }
    });

    test('tek varyantlı slotta excludeId yok sayılır', () {
      final only = RobotScripts.resultsSafe.first;
      final picked = RobotBrain.pick(
        RobotScripts.resultsSafe,
        seed: 3,
        excludeId: only.id,
      );
      expect(picked.id, only.id);
    });
  });

  group('homeGreeting', () {
    HomeContext ctx({
      required bool hasProfile,
      String? firstName,
      DateTime? now,
    }) =>
        HomeContext(
          now: now ?? DateTime(2026, 7, 19, 9),
          hasProfile: hasProfile,
          firstName: firstName,
        );

    test('tercih dönemi + profil → profile ailesi', () {
      final msg = RobotBrain.homeGreeting(ctx(hasProfile: true), seed: 0);
      expect(msg.id, startsWith('home.tercih.profile'));
    });

    test('tercih dönemi + profilsiz → tanışma ailesi, adıyla', () {
      final msg = RobotBrain.homeGreeting(
        ctx(hasProfile: false, firstName: 'Zeynep'),
        seed: 0,
      );
      expect(msg.id, startsWith('home.tercih.new'));
      expect(msg.text, contains('Zeynep'));
      expect(msg.text, contains(kRobotName));
    });

    test('sabah selamı Günaydın içerir', () {
      final msg = RobotBrain.homeGreeting(ctx(hasProfile: true), seed: 1);
      expect(msg.text, startsWith('Günaydın'));
    });

    test('sezon dışında offSeason ailesi', () {
      final msg = RobotBrain.homeGreeting(
        ctx(hasProfile: true, now: DateTime(2026, 12, 1, 14)),
        seed: 0,
      );
      expect(msg.id, startsWith('home.offSeason'));
    });
  });

  group('wizardWelcome', () {
    test('ilk ziyaret uzun tanışma', () {
      final msg = RobotBrain.wizardWelcome(
        hasProfile: false,
        firstVisit: true,
      );
      expect(msg.id, 'wizard.first.v1');
      expect(msg.text, contains(kRobotName));
    });

    test('profilli dönüş', () {
      final msg = RobotBrain.wizardWelcome(
        hasProfile: true,
        firstVisit: false,
        seed: 0,
      );
      expect(msg.id, startsWith('wizard.profile'));
    });
  });

  group('wizardRankReaction', () {
    test('bantlara göre şablon ve mood', () {
      expect(RobotBrain.wizardRankReaction(5000, 'SAY')!.id,
          'wizard.rank.top');
      expect(RobotBrain.wizardRankReaction(5000, 'SAY')!.mood,
          RobotMood.celebrating);
      expect(RobotBrain.wizardRankReaction(45000, 'SAY')!.id,
          'wizard.rank.strong');
      expect(RobotBrain.wizardRankReaction(120000, 'EA')!.id,
          'wizard.rank.mid');
      expect(RobotBrain.wizardRankReaction(300000, 'EA')!.id,
          'wizard.rank.wide');
      expect(RobotBrain.wizardRankReaction(900000, 'TYT')!.id,
          'wizard.rank.far');
    });

    test('Türkçe binlik ayraçlı yazım', () {
      expect(
        RobotBrain.wizardRankReaction(45000, 'SAY')!.text,
        contains('45.000'),
      );
    });

    test('geçersiz sırada null', () {
      expect(RobotBrain.wizardRankReaction(0, 'SAY'), isNull);
      expect(RobotBrain.wizardRankReaction(-5, 'SAY'), isNull);
    });
  });

  group('wizardScoreTypeReaction', () {
    test('bilinen türlere tepki, bilinmeyene null', () {
      for (final t in ['SAY', 'EA', 'SÖZ', 'DİL', 'TYT']) {
        expect(RobotBrain.wizardScoreTypeReaction(t), isNotNull,
            reason: t);
      }
      expect(RobotBrain.wizardScoreTypeReaction('XYZ'), isNull);
    });
  });

  group('resultsSummary', () {
    test('dengeli dağılım → kutlama', () {
      final msg = RobotBrain.resultsSummary(
        const ResultsContext(guaranteed: 4, target: 8, dream: 3),
        seed: 0,
      );
      expect(msg.id, startsWith('results.balanced'));
      expect(msg.mood, RobotMood.celebrating);
      expect(msg.text, contains('15'));
    });

    test('güvensiz + zorlayıcı ağırlıklı → endişe', () {
      final msg = RobotBrain.resultsSummary(
        const ResultsContext(guaranteed: 0, target: 2, dream: 10),
        seed: 0,
      );
      expect(msg.id, startsWith('results.risky'));
      expect(msg.mood, RobotMood.concerned);
    });

    test('hep güvenli → hedef ekleme önerisi', () {
      final msg = RobotBrain.resultsSummary(
        const ResultsContext(guaranteed: 5, target: 3, dream: 0),
        seed: 0,
      );
      expect(msg.id, startsWith('results.safe'));
    });

    test('boş sonuç → teselli', () {
      final msg = RobotBrain.resultsSummary(
        const ResultsContext(guaranteed: 0, target: 0, dream: 0),
        seed: 0,
      );
      expect(msg.id, startsWith('results.empty'));
      expect(msg.mood, RobotMood.concerned);
    });

    test('her özet dürüstlük içerir ("tahmin")', () {
      const contexts = [
        ResultsContext(guaranteed: 4, target: 8, dream: 3),
        ResultsContext(guaranteed: 0, target: 2, dream: 10),
        ResultsContext(guaranteed: 5, target: 3, dream: 0),
        ResultsContext(guaranteed: 0, target: 0, dream: 0),
      ];
      for (final ctx in contexts) {
        for (var seed = 0; seed < 3; seed++) {
          final msg = RobotBrain.resultsSummary(ctx, seed: seed);
          expect(msg.text.toLowerCase(), contains('tahmin'),
              reason: msg.id);
        }
      }
    });

    test('tahmini sırayla girişte ek dürüstlük cümlesi', () {
      final msg = RobotBrain.resultsSummary(
        const ResultsContext(
          guaranteed: 4,
          target: 8,
          dream: 3,
          usedEstimatedRank: true,
        ),
        seed: 0,
      );
      expect(msg.text, contains('puanından tahmin ettim'));
    });
  });

  group('listHealthComment', () {
    ListHealthReport report({
      int guaranteed = 0,
      int target = 0,
      int dream = 0,
      int unrated = 0,
    }) =>
        ListHealthReport(
          guaranteed: guaranteed,
          target: target,
          dream: dream,
          unrated: unrated,
          notes: const [],
        );

    test('güvenli tercih yok → endişe', () {
      final msg = RobotBrain.listHealthComment(
        report(target: 2, dream: 3),
        seed: 0,
      );
      expect(msg.id, startsWith('health.noGuaranteed'));
      expect(msg.mood, RobotMood.concerned);
    });

    test('yarıdan fazlası zorlayıcı → endişe', () {
      final msg = RobotBrain.listHealthComment(
        report(guaranteed: 1, target: 1, dream: 3),
        seed: 0,
      );
      expect(msg.id, startsWith('health.tooRisky'));
    });

    test('hep güvenli → hedef önerisi', () {
      final msg = RobotBrain.listHealthComment(
        report(guaranteed: 3),
        seed: 0,
      );
      expect(msg.id, startsWith('health.tooSafe'));
    });

    test('dengeli → mutlu', () {
      final msg = RobotBrain.listHealthComment(
        report(guaranteed: 2, target: 3, dream: 1),
        seed: 0,
      );
      expect(msg.id, startsWith('health.balanced'));
      expect(msg.mood, RobotMood.happy);
    });

    test('karşılaştırılamayan liste → düşünme', () {
      final msg = RobotBrain.listHealthComment(
        report(unrated: 4),
        seed: 0,
      );
      expect(msg.id, startsWith('health.unrated'));
      expect(msg.mood, RobotMood.thinking);
    });
  });

  group('badgeCheer', () {
    test('id rozete bağlanır, mood kutlama', () {
      final msg = RobotBrain.badgeCheer('streak_7', seed: 0);
      expect(msg.id, contains('streak_7'));
      expect(msg.mood, RobotMood.celebrating);
    });
  });

  group('tipOfDay', () {
    test('seed değişince ipucu döner, excludeId atlanır', () {
      final a = RobotBrain.tipOfDay(TercihPhase.tercihPeriod, seed: 0);
      final b = RobotBrain.tipOfDay(
        TercihPhase.tercihPeriod,
        seed: 0,
        excludeId: a.id,
      );
      expect(b.id, isNot(a.id));
    });
  });
}
