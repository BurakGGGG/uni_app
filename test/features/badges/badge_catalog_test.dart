import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/profile/domain/badge_catalog.dart';

/// Sunucudaki functions/src/badges/catalog.ts ile senkron tutulması gereken
/// rozet id listesi. Bu iki liste el yazması; herhangi biri değişirse bu
/// test kırılır ve karşı tarafın güncellenmesi hatırlatılır.
const _expectedBadgeIds = <String>{
  'first_review',
  'detailed_reviewer',
  'prolific_reviewer',
  'review_legend',
  'helpful',
  'community_hero',
  'like_magnet',
  'collector',
  'master_collector',
  'explorer',
  'wanderer',
  'cartographer',
  'city_traveler',
  'analyst',
  'strategist',
  'ambassador',
  'super_ambassador',
  'streak_starter',
  'streak_keeper',
  'streak_master',
  'loyal_member',
  'veteran',
  'profile_complete',
  'verified_scholar',
  'early_adopter',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('badgeCatalog', () {
    test('id kümesi server catalog.ts ile aynı', () {
      final ids = badgeCatalog.map((b) => b.id).toSet();
      expect(ids, _expectedBadgeIds);
      expect(
        badgeCatalog.length,
        _expectedBadgeIds.length,
        reason: 'Yinelenen id olmamalı',
      );
    });

    test('eşikli rozetlerde target var, özel rozetlerde yok', () {
      for (final def in badgeCatalog) {
        if (def.metric == BadgeMetric.none) {
          expect(def.target, isNull, reason: '${def.id} boolean kriter');
          expect(def.tier, 0, reason: '${def.id} özel rozet');
        } else {
          expect(
            def.target,
            isNotNull,
            reason: '${def.id} ilerleme çubuğu için target gerekir',
          );
          expect(def.target! > 0, isTrue);
        }
      }
    });

    test('her rozet için SVG asseti mevcut', () async {
      for (final def in badgeCatalog) {
        final data = await rootBundle.loadString(def.assetPath);
        expect(
          data.contains('<svg'),
          isTrue,
          reason: '${def.assetPath} geçerli SVG olmalı',
        );
      }
    });
  });

  group('BadgeProgress', () {
    BadgeDefinition reviewerTier(int target) => badgeCatalog.firstWhere(
          (b) => b.metric == BadgeMetric.reviews && b.target == target,
        );

    test('kazanılmış rozet fraction 1 döner', () {
      final p = BadgeProgress(
        definition: reviewerTier(3),
        earnedAt: DateTime(2026, 1, 1),
        current: 2,
      );
      expect(p.earned, isTrue);
      expect(p.fraction, 1.0);
    });

    test('kazanılmamış rozet ilerlemesi orantılı ve 0..1 sınırlı', () {
      final p = BadgeProgress(
        definition: reviewerTier(10),
        current: 4,
      );
      expect(p.earned, isFalse);
      expect(p.fraction, closeTo(0.4, 1e-9));

      final over = BadgeProgress(definition: reviewerTier(10), current: 999);
      expect(over.fraction, 1.0);
    });

    test('boolean kriter kazanılmadan fraction 0', () {
      final special = badgeCatalog.firstWhere(
        (b) => b.metric == BadgeMetric.none,
      );
      final p = BadgeProgress(definition: special, current: 0);
      expect(p.fraction, 0.0);
    });
  });
}
