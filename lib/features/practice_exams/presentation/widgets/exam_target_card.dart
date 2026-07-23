import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../assistant/presentation/providers/uni_panel_providers.dart';
import '../../../assistant/presentation/widgets/robot_avatar.dart';
import '../../../score_calculator/presentation/widgets/department_picker_sheet.dart';
import '../../../score_calculator/presentation/widgets/score_type_card.dart';
import '../../domain/models/exam_target.dart';
import '../../domain/models/practice_exam.dart';
import '../providers/practice_exam_providers.dart';
import 'exam_target_picker_sheet.dart';

/// Hedef program kartı: hedef yoksa belirleme daveti, varsa "ne kadar kaldı".
class ExamTargetCard extends ConsumerWidget {
  final List<PracticeExam> exams;

  const ExamTargetCard({super.key, required this.exams});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(examTargetProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: target == null
          ? _empty(context, ref)
          : _filled(context, ref, target),
    );
  }

  Widget _empty(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flag_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Hedefin',
              style:
                  AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Bir hedef program seç; grafikte hedef çizgin görünsün ve her '
          'denemede ne kadar yaklaştığını gör.',
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondaryFor(context)),
        ),
        const SizedBox(height: 12),
        // Üni'nin kısa yolu: liste zaten kurulmuşsa ilk tercihi hedef
        // yapmak, bölüm adı arayıp üniversite seçtirmekten hızlı.
        _Suggestion(onAccept: (t) =>
            ref.read(examTargetProvider.notifier).setTarget(t)),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _pickTarget(context, ref),
            icon: const Icon(Icons.add_location_alt_rounded, size: 18),
            label: const Text('Hedef Belirle'),
          ),
        ),
      ],
    );
  }

  Widget _filled(BuildContext context, WidgetRef ref, ExamTarget target) {
    final currentRank = _currentRank(target.scoreType);
    final startRank = _startRank(target.scoreType);
    final remaining = target.remainingRank(currentRank);
    final progress =
        target.progress(startRank: startRank, currentRank: currentRank);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flag_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hedefin',
                style: AppTextStyles.titleSmall
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  size: 20, color: AppColors.textSecondaryFor(context)),
              onSelected: (action) {
                if (action == 'change') {
                  _pickTarget(context, ref);
                } else {
                  ref.read(examTargetProvider.notifier).clearTarget();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'change', child: Text('Hedefi Değiştir')),
                PopupMenuItem(value: 'clear', child: Text('Hedefi Kaldır')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${target.universityName} · ${target.departmentName}',
          style:
              AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          [
            if (target.scoreType.isNotEmpty) target.scoreType,
            if (target.targetRank != null)
              '${formatRank(target.targetRank!)}. sıra',
            if (target.targetScore != null)
              '${target.targetScore!.toStringAsFixed(1)} puan',
          ].join(' · '),
          style: AppTextStyles.labelSmall
              .copyWith(color: AppColors.textSecondaryFor(context)),
        ),
        if (remaining != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                remaining <= 0
                    ? Icons.check_circle_rounded
                    : Icons.trending_down_rounded,
                size: 18,
                color: remaining <= 0 ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  remaining <= 0
                      ? 'Son denemende hedefin içindesin 🎉'
                      : '${formatRank(remaining)} sıra kaldı',
                  style: AppTextStyles.labelMedium.copyWith(
                    color:
                        remaining <= 0 ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 12),
          Text(
            currentRank == null
                ? '${target.scoreType} türünde sıralı bir denemen yok — '
                    'ilerlemeyi görmek için o türde bir deneme ekle.'
                : 'Bu hedef için sıra verisi yok.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondaryFor(context)),
          ),
        ],
        if (progress != null) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppColors.surfaceVariantFor(context),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'İlk denemenden bu yana yolun %${(progress * 100).round()}\'ini '
            'katettin.',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textTertiaryFor(context)),
          ),
        ],
      ],
    );
  }

  /// Hedef türündeki en son denemenin sırası.
  int? _currentRank(String scoreType) {
    for (final exam in exams) {
      final snapshot = exam.byType(scoreType);
      if (snapshot?.estimatedRank != null) return snapshot!.estimatedRank;
    }
    return null;
  }

  /// Hedef türündeki ilk (en eski) denemenin sırası — ilerleme referansı.
  int? _startRank(String scoreType) {
    for (final exam in exams.reversed) {
      final snapshot = exam.byType(scoreType);
      if (snapshot?.estimatedRank != null) return snapshot!.estimatedRank;
    }
    return null;
  }

  Future<void> _pickTarget(BuildContext context, WidgetRef ref) async {
    final deptName = await DepartmentPickerSheet.show(context);
    if (deptName == null || !context.mounted) return;
    final target =
        await ExamTargetPickerSheet.show(context, departmentName: deptName);
    if (target == null) return;
    await ref.read(examTargetProvider.notifier).setTarget(target);
  }
}

/// "İlk tercihin hedefin olsun mu?" — öneri yoksa hiç çizilmez.
class _Suggestion extends ConsumerWidget {
  final ValueChanged<ExamTarget> onAccept;
  const _Suggestion({required this.onAccept});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggested = ref.watch(suggestedTargetProvider);
    if (suggested == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const RobotAvatar(size: 22, animated: false),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Listendeki ilk tercihin: '
                    '${suggested.universityName} · ${suggested.departmentName}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryFor(context),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => onAccept(suggested),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Hedefim olsun'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
