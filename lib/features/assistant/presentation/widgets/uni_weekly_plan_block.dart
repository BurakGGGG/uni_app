import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/robot_scripts.dart';
import '../providers/assistant_providers.dart';
import '../providers/uni_panel_providers.dart';
import '../robot_action_route.dart';

/// "Bu hafta" — Üni'nin türettiği 2-3 maddelik görev listesi.
///
/// Görevleri kullanıcı yazmaz: faz, zayıf dersler, hedef mesafesi ve liste
/// durumundan çıkar. İşaretler pazartesi kendiliğinden sıfırlanır
/// (`RobotMemory` hafta anahtarını karşılaştırır), ayrı temizlik yoktur.
class UniWeeklyPlanBlock extends ConsumerWidget {
  const UniWeeklyPlanBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(weeklyPlanProvider);
    if (plan == null) return const SizedBox.shrink();
    final done = ref.watch(donePlanTasksProvider);
    final en = RobotScripts.isEn;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  en ? 'This week' : 'Bu hafta',
                  style: AppTextStyles.titleSmall
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${done.length}/${plan.tasks.length}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textTertiaryFor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final task in plan.tasks)
            _TaskRow(
              title: task.title,
              hint: task.hint,
              done: done.contains(task.id),
              onToggle: () async {
                await ref
                    .read(robotMemoryProvider)
                    .togglePlanTask(plan.weekKey, task.id);
                // İşaretler shared_preferences'ta; provider senkron okuduğu
                // için bağlamı tazelemek gerekiyor.
                ref.invalidate(insightContextProvider);
              },
              onGo: () {
                final route =
                    robotActionRoute(task.action, arg: task.actionArg);
                if (route != null) context.push(route);
              },
            ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final String title;
  final String hint;
  final bool done;
  final VoidCallback onToggle;
  final VoidCallback onGo;

  const _TaskRow({
    required this.title,
    required this.hint,
    required this.done,
    required this.onToggle,
    required this.onGo,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: done ? onToggle : onGo,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kutucuk her zaman işaretler; satırın kalanı görevin ekranına
            // götürür — yanlışlıkla "yaptım" demek kolay olmasın.
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(right: 10, top: 1),
                child: Icon(
                  done
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 20,
                  color: done
                      ? AppColors.success
                      : AppColors.textTertiaryFor(context),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: done ? TextDecoration.lineThrough : null,
                      color:
                          done ? AppColors.textTertiaryFor(context) : null,
                    ),
                  ),
                  if (!done)
                    Text(
                      hint,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiaryFor(context),
                        height: 1.3,
                      ),
                    ),
                ],
              ),
            ),
            if (!done)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textTertiaryFor(context),
              ),
          ],
        ),
      ),
    );
  }
}
