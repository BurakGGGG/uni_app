import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../score_calculator/presentation/providers/score_calculator_providers.dart';
import '../../../score_calculator/presentation/widgets/score_type_card.dart';
import '../../domain/models/practice_exam.dart';
import '../providers/practice_exam_providers.dart';

/// Deneme defterindeki tek satır: tür/yayın/tarih başlığı, tür rozetleri ve
/// bir önceki denemeye göre ilerleme.
class PracticeExamTile extends ConsumerWidget {
  final PracticeExam exam;

  /// Listede bir sonraki (yani daha eski) kayıt — delta referansı.
  final PracticeExam? previous;

  const PracticeExamTile({super.key, required this.exam, this.previous});

  static String formatDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankDelta =
        previous != null ? exam.rankProgressOver(previous!) : null;
    final netDelta = (previous != null && exam.hasNets && previous!.hasNets)
        ? exam.totalNet - previous!.totalNet
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightFor(context)),
        boxShadow: AppColors.softShadowFor(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.name,
                      style: AppTextStyles.titleMedium
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondaryFor(context),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    color: AppColors.textSecondaryFor(context)),
                onSelected: (action) => _handleAction(context, ref, action),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: 'rename', child: Text('Yeniden Adlandır')),
                  PopupMenuItem(value: 'restore', child: Text('Netleri Yükle')),
                  PopupMenuItem(value: 'delete', child: Text('Sil')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _kindChip(context),
              for (final r in exam.results)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scoreTypeColor(r.scoreType).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${r.scoreType} '
                    '${r.placementScore.toStringAsFixed(1).replaceAll('.', ',')}'
                    '${r.estimatedRank != null ? ' · ${exam.isRankMode ? '' : '~'}${formatRank(r.estimatedRank!)}' : ''}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: scoreTypeColor(r.scoreType),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if ((netDelta != null && netDelta != 0) ||
              (rankDelta != null && rankDelta != 0)) ...[
            const SizedBox(height: 10),
            _DeltaRow(
              exam: exam,
              previous: previous!,
              netDelta: netDelta,
              rankDelta: rankDelta,
            ),
          ],
        ],
      ),
    );
  }

  String _subtitle() {
    final parts = <String>[formatDate(exam.takenAt)];
    if (exam.publisher.isNotEmpty) parts.add(exam.publisher);
    if (exam.hasNets) {
      parts.add(
          'Toplam ${exam.totalNet.toStringAsFixed(2).replaceAll('.', ',')} net');
    } else if (exam.isRankMode) {
      parts.add('Sıralama girişi');
    } else {
      parts.add('Puan girişi');
    }
    return parts.join(' · ');
  }

  Widget _kindChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantFor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        exam.kind.labelTr,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textSecondaryFor(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'rename':
        _showRenameDialog(context, ref);
        break;
      case 'restore':
        ref.read(scoreInputProvider.notifier).state = exam.input;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${exam.name} hesaplayıcıya yüklendi')),
        );
        context.push('/score-calculator');
        break;
      case 'delete':
        ref.read(practiceExamsProvider.notifier).remove(exam.id);
        break;
    }
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: exam.name);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeniden Adlandır'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: PracticeExam.maxNameLength,
          decoration: const InputDecoration(hintText: 'Deneme adı'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(practiceExamsProvider.notifier).rename(exam.id, name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

/// Önceki denemeye göre değişim satırı: netli kayıtlarda net + puan farkı,
/// diğerlerinde sıranın kaç basamak ilerlediği.
class _DeltaRow extends StatelessWidget {
  final PracticeExam exam;
  final PracticeExam previous;
  final double? netDelta;
  final int? rankDelta;

  const _DeltaRow({
    required this.exam,
    required this.previous,
    required this.netDelta,
    required this.rankDelta,
  });

  @override
  Widget build(BuildContext context) {
    // Sırada küçülmek iyileşmedir; rankDelta zaten pozitifse ilerleme.
    final up = rankDelta != null && rankDelta != 0
        ? rankDelta! > 0
        : (netDelta ?? 0) > 0;
    final color = up ? AppColors.success : AppColors.error;

    return Row(
      children: [
        Icon(up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _text(),
            style: AppTextStyles.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  String _text() {
    final parts = <String>[];
    if (rankDelta != null && rankDelta != 0) {
      final steps = formatRank(rankDelta!.abs());
      parts.add(rankDelta! > 0 ? '$steps sıra ilerledin' : '$steps sıra geriledin');
    }
    if (netDelta != null && netDelta != 0) {
      parts.add('${netDelta! > 0 ? '+' : ''}'
          '${netDelta!.toStringAsFixed(2).replaceAll('.', ',')} net');
    }
    return 'Önceki denemeye göre ${parts.join(' · ')}';
  }
}
