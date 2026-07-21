import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../preference_wizard/presentation/feasibility_view.dart';
import '../../../score_calculator/domain/models/match_result.dart';
import '../../../university/domain/models/department_model.dart';
import '../../domain/robot_brain.dart';
import '../../domain/robot_message.dart';
import '../robot_action_route.dart';
import 'robot_message_card.dart';

/// Üni'nin bir üniversite hakkındaki toplu yorumu: "senin sıralamana uyan
/// N bölüm var, M tanesi yüksek şanslı."
///
/// Bölümler zaten ekranda yüklü ([departmentsByUniversityProvider]); burada
/// yalnız sayım yapılır. Kapı [UniDepartmentVerdict] ile aynıdır — Plus
/// yoksa Üni susar, profil yoksa sıralama ister.
class UniUniversityFit extends ConsumerWidget {
  final String universityId;
  final List<DepartmentModel> departments;

  const UniUniversityFit({
    super.key,
    required this.universityId,
    required this.departments,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (departments.isEmpty) return const SizedBox.shrink();

    // Profil/abonelik/tahminci bölümden bağımsız — bir kez okunur.
    // (Bunu döngüye sokmak bölüm sayısı kadar provider araması demekti.)
    final gate = watchFeasibilityContext(ref);
    if (gate is FeasibilityNoProfile) {
      return _card(context, RobotBrain.universityNeedsRank);
    }
    // Plus yoksa hiçbir bölüm için karar veremeyiz — Üni susar.
    if (gate is! FeasibilityReady || gate.locked) {
      return const SizedBox.shrink();
    }

    var matching = 0;
    var high = 0;
    for (final dept in departments) {
      final view = gate.categorize(
        scoreType: dept.effectiveScoreType,
        baseScore: dept.effectiveBaseScore,
        ranking: dept.rankingForMatching,
      );
      if (view is! FeasibilityVerdict) continue;
      // "Zorlayıcı" olanlar uyan sayısına girmez; kullanıcıya gerçekçi
      // bir sayı veriyoruz.
      if (view.category == MatchCategory.guaranteed) {
        matching++;
        high++;
      } else if (view.category == MatchCategory.target) {
        matching++;
      }
    }

    return _card(
      context,
      RobotBrain.universityFitSummary(matching: matching, high: high),
    );
  }

  Widget _card(BuildContext context, RobotMessage message) {
    final route = robotActionRoute(message.action);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: RobotMessageCard(
        message: message,
        avatarSize: 36,
        animatedAvatar: false,
        typewriter: false,
        dense: true,
        onTap: () => context.push(
          route ?? '/university/$universityId/departments',
        ),
      ),
    );
  }
}
