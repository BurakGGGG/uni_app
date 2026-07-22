import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/score_calculator_providers.dart';
import 'university_match_card.dart';

/// "Girebileceğin bölümler" önizlemesi: kategori sayaçları + uygunluğu en
/// yüksek 5 program. Tam liste tercih robotunda.
class EligibleProgramsPreview extends ConsumerWidget {
  final String scoreType;
  final VoidCallback onSeeAll;

  const EligibleProgramsPreview({
    super.key,
    required this.scoreType,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(eligibleProgramsProvider(scoreType));

    return resultAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (result) {
        if (result == null || result.total == 0) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLightFor(context)),
            ),
            child: Text(
              'Bu türde eşleşen program bulunamadı.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondaryFor(context)),
            ),
          );
        }

        // Uygunluğu en yüksek 5 program (fit yoksa kategori sırası korunur).
        final top = [
          ...result.guaranteed,
          ...result.target,
          ...result.dream,
        ]..sort((a, b) => (b.fitScore ?? -1).compareTo(a.fitScore ?? -1));
        final preview = top.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CountPill(
                  emoji: '🟢',
                  label: 'Yüksek şans',
                  count: result.guaranteed.length,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                _CountPill(
                  emoji: '🟡',
                  label: 'Ulaşılabilir',
                  count: result.target.length,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 8),
                _CountPill(
                  emoji: '🔴',
                  label: 'Zorlayıcı',
                  count: result.dream.length,
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...preview.map((m) => UniversityMatchCard(match: m)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: onSeeAll,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                    'Tercih robotunda tümünü gör (${result.total} program)'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '2025 taban puan ve başarı sıralamalarına göre; 2026 '
              'yerleştirmeleri farklılık gösterebilir.',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textTertiaryFor(context)),
            ),
          ],
        );
      },
    );
  }
}

class _CountPill extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;
  final Color color;

  const _CountPill({
    required this.emoji,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text('$emoji $count',
                style: AppTextStyles.titleSmall
                    .copyWith(fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
