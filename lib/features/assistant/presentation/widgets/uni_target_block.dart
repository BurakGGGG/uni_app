import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../router/app_router.dart';
import '../../../practice_exams/presentation/providers/practice_exam_providers.dart';
import '../../../preference_wizard/domain/match_reason.dart' show formatRankTr;
import '../../domain/insights/target_roadmap.dart';
import '../../domain/robot_scripts.dart';
import '../providers/uni_panel_providers.dart';

/// Hedef + yol haritası bloğu — "hedefe ≈ 11,5 net, Mat +5 · Fizik +3".
///
/// Uygulamanın hiçbir ekranının söyleyemediği cümle burada: ÖSYM'nin sıra→puan
/// ters tablosu, puan motorunun ders katsayıları ve deneme defterinin zayıflık
/// analizi tek satırda buluşuyor.
///
/// Panelde de Denemelerim ekranında da aynı widget çizilir — iki yerde ayrı
/// hesaplanırsa iki farklı sayı söylenir.
class UniTargetBlock extends ConsumerWidget {
  /// Panelde özet (ilerleme + tek satır plan), Denemelerim'de tam (ders
  /// kırılımı satır satır).
  final bool compact;

  const UniTargetBlock({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roadmap = ref.watch(targetRoadmapProvider);
    final target = ref.watch(examTargetProvider);
    if (roadmap == null || target == null) return const SizedBox.shrink();

    final en = RobotScripts.isEn;
    final progress = ref.watch(targetProgressProvider);

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
              const Icon(Icons.flag_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  en ? 'Your target' : 'Hedefin',
                  style: AppTextStyles.titleSmall
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (compact)
                TextButton(
                  onPressed: () => context.push(AppRoutes.practiceExams),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(en ? 'Detail' : 'Detay'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${target.universityName} · ${target.departmentName}',
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            en
                ? 'Cutoff rank ${formatRankTr(roadmap.targetRank)}'
                : 'Taban ${formatRankTr(roadmap.targetRank)}. sıra',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
          ),
          const SizedBox(height: 12),

          if (progress != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(
                  roadmap.reached ? AppColors.success : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '%${(progress * 100).round()}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (roadmap.reached)
            _Banner(
              color: AppColors.success,
              icon: Icons.check_circle_rounded,
              text: en
                  ? "You're past this target. Time to aim higher."
                  : 'Bu hedefi geçtin. Daha yükseğini koyma vakti.',
            )
          else if (!roadmap.reachable)
            _Banner(
              color: AppColors.warning,
              icon: Icons.warning_amber_rounded,
              text: en
                  ? 'Even maxing out every remaining subject leaves a '
                      '${_num(roadmap.scoreGap)} point gap.'
                  : 'Kalan tüm derslerde tavana çıksan bile '
                      '${_num(roadmap.scoreGap)} puanlık fark kalıyor.',
            )
          else ...[
            Text(
              en
                  ? '≈ ${_num(roadmap.totalNetsNeeded)} more nets'
                  : '≈ ${_num(roadmap.totalNetsNeeded)} net daha',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              en
                  ? '${_num(roadmap.scoreGap)} points to close'
                  : 'Kapatılacak fark: ${_num(roadmap.scoreGap)} puan',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
            ),
            const SizedBox(height: 12),
            if (compact)
              Text(
                roadmap.steps
                    .map((s) =>
                        '${RobotScripts.subjectLabel(s.subject.labelTr)} '
                        '+${_num(s.netsNeeded)}')
                    .join(' · '),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryFor(context),
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              for (final step in roadmap.steps) _StepRow(step: step),
            const SizedBox(height: 8),
            Text(
              en
                  ? 'Chosen for high coefficients and low success rate — the '
                      'points come fastest here.'
                  : 'Katsayısı yüksek, başarı oranın düşük dersler seçildi — '
                      'puan en hızlı buradan gelir.',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiaryFor(context),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _num(double value) {
    final text = value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
    return RobotScripts.isEn ? text : text.replaceAll('.', ',');
  }
}

/// Tek ders satırı: "AYT Matematik  15 → 20 net  (+15,1 puan)".
class _StepRow extends StatelessWidget {
  final RoadmapStep step;
  const _StepRow({required this.step});

  @override
  Widget build(BuildContext context) {
    final en = RobotScripts.isEn;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${UniTargetBlock._num(step.netsNeeded)}',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  RobotScripts.subjectLabel(step.subject.labelTr),
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${UniTargetBlock._num(step.currentNet)} → '
                  '${UniTargetBlock._num(step.targetNet)} '
                  '${en ? 'nets' : 'net'} · '
                  '${en ? 'max' : 'tavan'} '
                  '${UniTargetBlock._num(step.maxNet)}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiaryFor(context),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${UniTargetBlock._num(step.scoreGain)}',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  const _Banner({required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall
                  .copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
