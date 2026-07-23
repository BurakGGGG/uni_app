import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/practice_exam_analytics.dart';
import '../providers/practice_exam_providers.dart';
import '../widgets/exam_target_card.dart';
import '../widgets/practice_exam_tile.dart';
import '../widgets/practice_exam_trend_chart.dart';
import '../widgets/subject_strength_panel.dart';

/// "Denemelerim" — deneme defteri, gelişim grafiği, ders analizi ve hedef.
class PracticeExamsScreen extends ConsumerStatefulWidget {
  const PracticeExamsScreen({super.key});

  @override
  ConsumerState<PracticeExamsScreen> createState() =>
      _PracticeExamsScreenState();
}

class _PracticeExamsScreenState extends ConsumerState<PracticeExamsScreen> {
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    // Giriş yapılmışsa hesap yedeğiyle birleştir (misafirde no-op).
    ref.watch(practiceExamSyncProvider);

    final exams = ref.watch(practiceExamsProvider);
    final types = scoreTypesIn(exams);
    final activeType =
        _selectedType ?? ref.watch(dominantScoreTypeProvider) ?? '';

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        title: const Text('Denemelerim'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (exams.isNotEmpty)
            IconButton(
              tooltip: 'Tümünü sil',
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _confirmClearAll,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/score-calculator'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Deneme Ekle'),
      ),
      body: exams.isEmpty
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _SummaryStrip(examCount: exams.length),
                const SizedBox(height: 16),
                if (types.length > 1) ...[
                  _typeChips(types, activeType),
                  const SizedBox(height: 12),
                ],
                PracticeExamTrendChart(
                  points: trendFor(exams, activeType),
                  scoreType: activeType,
                  target: ref.watch(examTargetProvider),
                ),
                const SizedBox(height: 16),
                ExamTargetCard(exams: exams),
                const SizedBox(height: 16),
                SubjectStrengthPanel(
                  stats: subjectStats(exams),
                  hasNetExams: exams.any((e) => e.hasNets),
                ),
                const SizedBox(height: 24),
                Text(
                  'Denemelerin (${exams.length})',
                  style: AppTextStyles.titleMedium
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < exams.length; i++)
                  PracticeExamTile(
                    exam: exams[i],
                    // Liste yeniden eskiye; "önceki deneme" bir sonraki eleman.
                    previous: i + 1 < exams.length ? exams[i + 1] : null,
                  ),
                _SyncNote(signedIn: ref.watch(authStateProvider).valueOrNull != null),
              ],
            ),
    );
  }

  Widget _typeChips(List<String> types, String active) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final type in types)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(type),
                selected: active == type,
                showCheckmark: false,
                onSelected: (_) => setState(() => _selectedType = type),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm denemeleri sil'),
        content: const Text(
            'Kayıtlı tüm denemelerin silinecek. Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(practiceExamsProvider.notifier).clear();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

/// Toplam deneme + haftalık seri şeridi.
class _SummaryStrip extends ConsumerWidget {
  final int examCount;

  const _SummaryStrip({required this.examCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(examStreakProvider);

    return Row(
      children: [
        Expanded(
          child: _stat(context, Icons.assignment_turned_in_rounded,
              '$examCount', 'deneme'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _stat(
            context,
            Icons.local_fire_department_rounded,
            '$streak',
            streak == 1 ? 'hafta seri' : 'hafta seri',
            color: streak > 0 ? AppColors.warning : null,
          ),
        ),
      ],
    );
  }

  Widget _stat(
    BuildContext context,
    IconData icon,
    String value,
    String label, {
    Color? color,
  }) {
    final tint = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: tint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.titleLarge
                      .copyWith(fontWeight: FontWeight.w800, color: tint),
                ),
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncNote extends StatelessWidget {
  final bool signedIn;

  const _SyncNote({required this.signedIn});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            signedIn ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            size: 16,
            color: AppColors.textTertiaryFor(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              signedIn
                  ? 'Denemelerin hesabına yedekleniyor; yalnız sen görebilirsin.'
                  : 'Denemelerin bu cihazda saklanıyor. Giriş yaparsan '
                      'hesabına yedeklenir.',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textTertiaryFor(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_rounded,
                size: 64, color: AppColors.textTertiaryFor(context)),
            const SizedBox(height: 16),
            Text(
              'Henüz kayıtlı deneme yok',
              style: AppTextStyles.titleMedium
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Netlerini, puanını ya da sıralamanı gir; hesapladıktan sonra '
              '"Denemelerime Kaydet" ile buraya ekle. Gelişimini grafikte '
              'takip et.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondaryFor(context)),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.push('/score-calculator'),
              icon: const Icon(Icons.calculate_rounded, size: 18),
              label: const Text('İlk Denemeni Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}
