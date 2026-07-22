import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../assistant/domain/robot_brain.dart';
import '../../../assistant/presentation/widgets/robot_message_card.dart';
import '../../domain/models/calc_history_entry.dart';
import '../../domain/models/multi_score_result.dart';
import '../providers/score_calculator_providers.dart';
import 'score_type_card.dart';

/// Üni'nin hesaplama sonucuna kişisel yorumu: en güçlü tür + tahmini sıra,
/// önceki denemeye göre net değişimi (geçmişten okunur).
class UniCalcComment extends ConsumerWidget {
  final MultiScoreOutcome outcome;

  const UniCalcComment({super.key, required this.outcome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final best = outcome.best;
    if (best == null) return const SizedBox.shrink();

    final input = ref.watch(scoreInputProvider);
    final history = ref.watch(calcHistoryProvider);

    // Geçmişteki "bu hesaplamanın kendisi"ni atla; ilk farklı kayıt önceki
    // denemedir (otomatik kayıt aynı girdiyi çoğaltmaz ama sıralamada öndedir).
    final currentJson = jsonEncode(input.toJson());
    CalcHistoryEntry? previous;
    for (final entry in history) {
      if (jsonEncode(entry.input.toJson()) != currentJson) {
        previous = entry;
        break;
      }
    }

    // Sıra modunda net yoktur; ilerleme dili yerine sıra dili kullanılır.
    final netDelta = (previous != null && !input.isRankMode)
        ? input.totalNet - previous.totalNet
        : null;
    String? deltaText;
    if (netDelta != null) {
      deltaText = '${netDelta >= 0 ? '+' : ''}'
          '${netDelta.toStringAsFixed(1).replaceAll('.', ',')}';
    }

    final message = RobotBrain.calcSummary(CalcResultContext(
      bestType: best.score.scoreType,
      rankText:
          best.estimatedRank != null ? formatRank(best.estimatedRank!) : null,
      netDelta: netDelta,
      deltaText: deltaText,
      fromRank: input.isRankMode,
      scoreText:
          best.score.placementScore.toStringAsFixed(1).replaceAll('.', ','),
    ));

    return RobotMessageCard(
      message: message,
      avatarSize: 36,
      // Sonuç ekranının tek animasyonlu avatarı hero'da; burada sabit çizim.
      animatedAvatar: false,
      typewriter: false,
      dense: true,
    );
  }
}
