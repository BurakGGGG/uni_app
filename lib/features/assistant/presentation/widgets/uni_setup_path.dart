import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../router/app_router.dart';
import '../../domain/insights/uni_insight.dart';
import '../../domain/robot_scripts.dart';
import '../providers/uni_panel_providers.dart';
import 'robot_avatar.dart';

/// "Seni tanımam için 3 şey lazım" — panelin soğuk başlangıç yüzeyi.
///
/// Sıra anlamlıdır: puan olmadan hedef mesafesi, hedef olmadan yol haritası
/// hesaplanamaz. Tamamlanan adım yeşil tik olur, sıradaki adım butonlu kalır,
/// sonrakiler soluk. Üçü de tamamlanınca widget hiç çizilmez.
class UniSetupPath extends ConsumerWidget {
  const UniSetupPath({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(setupPathProvider);
    if (path.complete) return const SizedBox.shrink();

    final steps = <_Step>[
      _Step(
        done: path.hasProfile,
        title: RobotScripts.isEn ? 'Calculate your score' : 'Puanını hesapla',
        route: AppRoutes.scoreCalculator,
      ),
      _Step(
        done: path.hasTarget,
        title: RobotScripts.isEn ? 'Pick a target program' : 'Hedef program seç',
        route: AppRoutes.practiceExams,
      ),
      _Step(
        done: path.hasExam,
        title: RobotScripts.isEn ? 'Add your first exam' : 'İlk denemeni ekle',
        route: AppRoutes.practiceExams,
      ),
    ];
    // Sıradaki adım = ilk tamamlanmamış.
    final nextIndex = steps.indexWhere((s) => !s.done);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const RobotAvatar(size: 30, animated: false),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  RobotScripts.isEn
                      ? "I don't know you yet"
                      : 'Seni henüz tanımıyorum',
                  style: AppTextStyles.titleSmall
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${path.done}/${SetupPath.total}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: path.done / SetupPath.total,
              minHeight: 6,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < steps.length; i++)
            _StepRow(
              step: steps[i],
              isNext: i == nextIndex,
            ),
        ],
      ),
    );
  }
}

class _Step {
  final bool done;
  final String title;
  final String route;
  const _Step({required this.done, required this.title, required this.route});
}

class _StepRow extends StatelessWidget {
  final _Step step;
  final bool isNext;
  const _StepRow({required this.step, required this.isNext});

  @override
  Widget build(BuildContext context) {
    final dim = !step.done && !isNext;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            step.done
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: step.done
                ? AppColors.success
                : (dim
                    ? AppColors.textTertiaryFor(context)
                    : AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              step.title,
              style: AppTextStyles.bodyMedium.copyWith(
                decoration: step.done ? TextDecoration.lineThrough : null,
                color: step.done || dim
                    ? AppColors.textTertiaryFor(context)
                    : null,
                fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (isNext)
            TextButton(
              onPressed: () => context.push(step.route),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Text(RobotScripts.isEn ? 'Start' : 'Başla'),
            ),
        ],
      ),
    );
  }
}
