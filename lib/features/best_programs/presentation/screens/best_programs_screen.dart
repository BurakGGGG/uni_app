import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/models/best_programs_query.dart';
import '../../domain/program_category.dart';
import '../providers/best_programs_providers.dart';
import '../widgets/best_program_card.dart';
import '../widgets/best_programs_filter_sheet.dart';

/// "En iyi X bölümleri" — bir bölümün ya da bir alanın tüm programları,
/// 2025 başarı sıralamasına göre sıralı.
///
/// [departmentName] ya da [categoryKey] ile açılır; ikisi de boşsa aktif
/// [bestProgramsQueryProvider] kapsamı kullanılır (Keşfet sekmesinden gelen).
class BestProgramsScreen extends ConsumerStatefulWidget {
  final String? departmentName;
  final String? categoryKey;

  const BestProgramsScreen({super.key, this.departmentName, this.categoryKey});

  @override
  ConsumerState<BestProgramsScreen> createState() => _BestProgramsScreenState();
}

class _BestProgramsScreenState extends ConsumerState<BestProgramsScreen> {
  @override
  void initState() {
    super.initState();
    // Rota parametreleri kapsamı belirler; filtreler korunur.
    if (widget.departmentName != null || widget.categoryKey != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final notifier = ref.read(bestProgramsQueryProvider.notifier);
        notifier.state = notifier.state.copyWith(
          departmentName: widget.departmentName,
          clearDepartment: widget.departmentName == null,
          categoryKey: widget.categoryKey,
          clearCategory: widget.categoryKey == null,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(bestProgramsQueryProvider);
    final programsAsync = ref.watch(bestProgramsProvider(query));

    final title = query.departmentName ??
        (query.categoryKey != null
            ? categoryByKey(query.categoryKey!)?.label
            : null) ??
        'En İyi Bölümler';
    // Tek bölümün listesinde her kartta adı tekrarlamak gürültü.
    final singleDepartment = query.departmentName != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceFor(context),
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: AppTextStyles.titleMedium
                    .copyWith(fontWeight: FontWeight.w800)),
            Text(
              query.sort == BestProgramsSort.rankAsc
                  ? 'Başarı sıralamasına göre'
                  : 'Taban puanına göre',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textSecondaryFor(context)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  tooltip: 'Filtreler',
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: () => BestProgramsFilterSheet.show(context),
                ),
                if (query.activeFilterCount > 0)
                  Positioned(
                    right: 6,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${query.activeFilterCount}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: programsAsync.when(
        loading: () => const ListSkeleton(),
        error: (e, _) => ErrorState(
          message: 'Bölümler yüklenemedi',
          onRetry: () => ref.invalidate(bestProgramsProvider(query)),
        ),
        data: (programs) {
          if (programs.isEmpty) {
            return _empty(context, query);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            // +1 başlık şeridi, +1 dipnot.
            itemCount: programs.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _header(context, programs.length, query);
              }
              if (index == programs.length + 1) return _footnote(context);
              return BestProgramCard(
                program: programs[index - 1],
                showDepartmentName: !singleDepartment,
              );
            },
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, int count, BestProgramsQuery query) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded,
              size: 18, color: AppColors.textSecondaryFor(context)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$count program'
              '${query.onlyEligible ? ' · sadece girebileceklerin' : ''}',
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.textSecondaryFor(context)),
            ),
          ),
        ],
      ),
    );
  }

  /// Veri kapsamı ve vakıf tabanları hakkında dürüstlük notu — liste
  /// "Türkiye'nin en iyileri" gibi okunmamalı.
  Widget _footnote(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '105 üniversite · 2025 yerleştirme verisi. Vakıf programlarında '
        'gösterilen taban genelde burslu kontenjana aittir.',
        style: AppTextStyles.labelSmall
            .copyWith(color: AppColors.textTertiaryFor(context)),
      ),
    );
  }

  Widget _empty(BuildContext context, BestProgramsQuery query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56, color: AppColors.textTertiaryFor(context)),
            const SizedBox(height: 16),
            Text(
              'Bu filtrelerle program kalmadı',
              style: AppTextStyles.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Filtreleri gevşetmeyi dene.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondaryFor(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => BestProgramsFilterSheet.show(context),
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Filtreleri düzenle'),
            ),
          ],
        ),
      ),
    );
  }
}
