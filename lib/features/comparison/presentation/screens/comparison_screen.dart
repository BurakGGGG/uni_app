import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/models/comparison_result.dart';
import '../providers/comparison_providers.dart';
import '../widgets/comparison_uni_picker.dart';

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
              Text('Karşılaştır', style: AppTextStyles.displaySmall),
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
    if (selection.uniIdA == null || selection.uniIdB == null) {
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
        icon: Icons.compare_arrows_rounded,
        title: 'İki üniversite seç',
        description: 'Yukarıdan iki üniversite seçince karşılaştırma sonuçları burada gözükür.',
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
        Text('Genel', style: AppTextStyles.titleLarge),
        const SizedBox(height: 12),
        _GeneralComparison(result: result),
        const SizedBox(height: 24),
        Text('Kategoriler', style: AppTextStyles.titleLarge),
        const SizedBox(height: 12),
        _CategoryBars(result: result),
      ],
    );
  }
}

class _GeneralComparison extends StatelessWidget {
  final ComparisonResult result;
  const _GeneralComparison({required this.result});

  @override
  Widget build(BuildContext context) {
    // ComparisonResult model'in alanlarına göre satır satır göster:
    // ortalama puan, yorum sayısı, kuruluş yılı, tür (Devlet/Vakıf), yerleşke (campusLayout)
    // Her satırda iki uni'nin değeri yan yana, kazanan vurgulu (yeşil tik / fark yüzdesi)
    return Column(
      children: [
        _ComparisonRow(
          label: 'Ortalama Puan',
          valueA: result.uniA.avgRating.toStringAsFixed(1),
          valueB: result.uniB.avgRating.toStringAsFixed(1),
          winnerIsA: result.uniA.avgRating > result.uniB.avgRating,
          winnerIsB: result.uniB.avgRating > result.uniA.avgRating,
        ),
        _ComparisonRow(
          label: 'Yorum Sayısı',
          valueA: '${result.uniA.reviewCount}',
          valueB: '${result.uniB.reviewCount}',
          winnerIsA: result.uniA.reviewCount > result.uniB.reviewCount,
          winnerIsB: result.uniB.reviewCount > result.uniA.reviewCount,
        ),
        // ... diğer satırlar (foundedYear, type, campusLayout)
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final String valueA;
  final String valueB;
  final bool winnerIsA;
  final bool winnerIsB;

  const _ComparisonRow({
    required this.label,
    required this.valueA,
    required this.valueB,
    required this.winnerIsA,
    required this.winnerIsB,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              valueA,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: winnerIsA ? FontWeight.w700 : FontWeight.w400,
                color: winnerIsA ? AppColors.success : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Center(
              child: Text(label, style: AppTextStyles.bodySmall),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              valueB,
              style: TextStyle(
                fontWeight: winnerIsB ? FontWeight.w700 : FontWeight.w400,
                color: winnerIsB ? AppColors.success : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBars extends StatelessWidget {
  final ComparisonResult result;
  const _CategoryBars({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: result.categoryComparisons.values.map((cat) {
        return _CategoryBarRow(category: cat);
      }).toList(),
    );
  }
}

class _CategoryBarRow extends StatelessWidget {
  final CategoryComparison category;
  const _CategoryBarRow({required this.category});

  @override
  Widget build(BuildContext context) {
    final maxRating = 5.0;
    final ratioA = (category.valueA / maxRating).clamp(0.0, 1.0);
    final ratioB = (category.valueB / maxRating).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(category.categoryName, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _Bar(
                  ratio: ratioA,
                  value: category.valueA,
                  isWinner: category.valueA > category.valueB,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Bar(
                  ratio: ratioB,
                  value: category.valueB,
                  isWinner: category.valueB > category.valueA,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double ratio;
  final double value;
  final bool isWinner;
  const _Bar({required this.ratio, required this.value, required this.isWinner});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.borderLight,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        FractionallySizedBox(
          widthFactor: ratio,
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              color: isWinner ? AppColors.success : AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            value.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ],
    );
  }
}