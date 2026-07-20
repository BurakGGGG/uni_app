import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../preference_wizard/presentation/feasibility_view.dart';
import '../../../university/domain/models/department_model.dart';
import '../../domain/robot_brain.dart';
import '../robot_action_route.dart';
import 'robot_message_card.dart';

/// Üni'nin bir bölüm hakkındaki kişisel yorumu.
///
/// Kararı [watchFeasibility] verir — yanındaki [FeasibilityChip] ile AYNI
/// kaynak, ikisi çelişemez. Üni yalnız söylemesi gereken durumda konuşur:
///
/// - Puan profili yok → sıralamasını girmeye davet eder (ücretsiz; veri
///   ister, satış yapmaz)
/// - Plus yok → **sessiz**. Kilidi yanındaki çip zaten anlatıyor; Üni'yi
///   satış görevlisine çevirmiyoruz.
/// - Farklı puan türü / sinyal yok → sessiz
/// - Karar hazır → kategoriyi kelimelerle söyler
class UniDepartmentVerdict extends ConsumerWidget {
  final DepartmentModel department;

  const UniDepartmentVerdict({super.key, required this.department});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = watchFeasibility(
      ref,
      scoreType: department.effectiveScoreType,
      baseScore: department.effectiveBaseScore,
      ranking: department.rankingForMatching,
    );

    final message = switch (view) {
      FeasibilityNoProfile() => RobotBrain.departmentNeedsRank,
      FeasibilityVerdict(:final category, :final isEstimated) =>
        RobotBrain.departmentVerdict(category, estimated: isEstimated),
      FeasibilityLocked() || FeasibilityIncomparable() => null,
    };
    if (message == null) return const SizedBox.shrink();

    final route = robotActionRoute(message.action);
    return RobotMessageCard(
      message: message,
      avatarSize: 36,
      // Detay ekranının tek animasyonlu avatarı olmasın diye sabit çizim.
      animatedAvatar: false,
      typewriter: false,
      dense: true,
      onTap: route == null ? null : () => context.push(route),
    );
  }
}
