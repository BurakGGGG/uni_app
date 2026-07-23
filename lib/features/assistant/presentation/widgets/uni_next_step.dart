import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/uni_panel_providers.dart';
import '../robot_action_route.dart';
import 'robot_avatar.dart';

/// Kurulum bitene kadar panelin en üstündeki tek iş.
///
/// Önce üç maddelik bir kontrol listesiydi (çubuk + "0/3" + üç satır) ve
/// kullanıcı "ben bile anlamadım" dedi: kart, Üni'nin kendi veri
/// ihtiyaçlarını kullanıcının ödev listesi gibi sunuyordu. Şimdi aynı anda
/// yalnız SIRADAKİ iş görünüyor — tek cümle, tek buton — ve cümle ne
/// yapılacağını değil kullanıcının ne kazanacağını söylüyor.
///
/// Metin motordan geliyor (`setup.*` notu), burada kopyalanmıyor: ana
/// sayfadaki balon da aynı notu gösteriyor, ikisi ayrışamaz.
class UniNextStep extends ConsumerWidget {
  const UniNextStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(nextSetupStepProvider);
    if (step == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RobotAvatar(size: 36, mood: step.mood, animated: false),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    step.title,
                    style: AppTextStyles.titleMedium
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            step.body,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondaryFor(context),
              height: 1.45,
            ),
          ),
          if (step.hasAction) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  final route =
                      robotActionRoute(step.action, arg: step.actionArg);
                  if (route != null) context.push(route);
                },
                child: Text(step.actionLabel ?? ''),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
