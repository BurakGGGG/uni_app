import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/models/comparison_result.dart';
import '../providers/comparison_providers.dart';
import '../widgets/comparison_uni_picker.dart';
import '../widgets/comparison_header.dart';
import '../widgets/comparison_category_row.dart';
import '../widgets/comparison_stats_table.dart';
import '../widgets/comparison_share_card.dart';
import '../widgets/comparison_radar_chart.dart';

class ComparisonScreen extends ConsumerWidget {
  const ComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(comparisonSelectionProvider);
    final resultAsync = ref.watch(comparisonResultProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Karşılaştır', style: AppTextStyles.displaySmall),
                  ),
                  if (selection.uniIdA != null || selection.uniIdB != null)
                    TextButton.icon(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Sıfırla'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        backgroundColor: AppColors.error.withValues(alpha: 0.08),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => ref.read(comparisonSelectionProvider.notifier).reset(),
                    ),
                  if (selection.bothSelected) ...[
                    IconButton(
                      icon: const Icon(Icons.swap_horiz_rounded),
                      tooltip: 'Yer Değiştir',
                      onPressed: () =>
                          ref.read(comparisonSelectionProvider.notifier).swap(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.ios_share_rounded),
                      tooltip: 'Paylaş',
                      onPressed: () async {
                        final result = resultAsync.valueOrNull;
                        if (result != null) {
                          await ComparisonShareCard.shareCard(context, result);
                        }
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Üniversiteleri yan yana kıyasla',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 24),
              const ComparisonUniPicker(),
              const SizedBox(height: 24),
              _buildBody(context, selection, resultAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ComparisonSelection selection,
    AsyncValue<ComparisonResult?> resultAsync,
  ) {
    if (!selection.bothSelected) {
      return const _EmptyState();
    }

    return resultAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Center(child: Text('Hata: $e')),
      data: (result) {
        if (result == null) return const _EmptyState();
        return _ResultView(result: result);
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: EmptyStateWidget(
        illustration: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          child: SvgPicture.asset(
            'assets/icons/compare_icon.svg',
            width: 56,
            height: 56,
          ),
        ),
        title: 'İki üniversite seç',
        description:
            'Yukarıdan iki üniversite seçince karşılaştırma sonuçları burada gözükür.',
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final ComparisonResult result;
  const _ResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ComparisonHeader(result: result),
        const SizedBox(height: 24),
        _SectionTitle('Kategori Puanları'),
        ...result.categoryComparisons.values.map(
          (c) => ComparisonCategoryRow(
            comparison: c,
            uniAId: result.uniA.id,
            uniBId: result.uniB.id,
          ),
        ),
        const SizedBox(height: 24),
        _SectionTitle('Genel Görünüm'),
        ComparisonRadarChart(result: result),
        const SizedBox(height: 24),
        _SectionTitle('Genel İstatistikler'),
        ComparisonStatsTable(result: result),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Text(title,
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}