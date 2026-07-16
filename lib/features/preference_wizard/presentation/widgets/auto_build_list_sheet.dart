import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../admin/data/analytics_service.dart';
import '../../../admin/domain/models/analytics_event.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../preference_lists/domain/models/preference_list_model.dart';
import '../../../preference_lists/domain/preference_item_builder.dart';
import '../../../preference_lists/presentation/providers/preference_list_providers.dart';
import '../../../score_calculator/domain/models/match_result.dart';
import '../../domain/preference_match_engine.dart';

/// Plus özelliği — profil + filtrelere göre dengeli 24'lük tercih listesi üretir.
///
/// Kompozisyon hedefi: ~5 garanti · ~12 hedef · ~7 riskli. Eksik kalan kova
/// diğerlerinden tamamlanır. Öğeler taban puanına göre azalan sıralanır
/// (yüksek/riskli üstte, garanti altta — klasik tercih stratejisi) ve tek
/// yazımda `reorderItems` ile kaydedilir.
Future<void> showAutoBuildListSheet(
  BuildContext context,
  WidgetRef ref,
  PreferenceMatchResult result,
) async {
  final user = ref.read(authStateProvider).value;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Liste oluşturmak için giriş yapmalısın')),
    );
    context.push('/login');
    return;
  }

  final picks = _buildBalanced(result);
  if (picks.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Önce eşleşen program bulunmalı')),
    );
    return;
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceFor(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _AutoBuildBody(picks: picks),
  );
}

List<UniversityMatch> _buildBalanced(PreferenceMatchResult result) {
  const total = PreferenceListModel.maxItems; // 24
  final picks = <UniversityMatch>[];
  final seen = <String>{};

  void addFrom(List<UniversityMatch> src, int n) {
    var added = 0;
    for (final m in src) {
      if (picks.length >= total || added >= n) break;
      if (!seen.add(m.department.id)) continue;
      picks.add(m);
      added++;
    }
  }

  addFrom(result.guaranteed, 5);
  addFrom(result.target, 12);
  addFrom(result.dream, 7);

  // Eksik kaldıysa öncelik sırasıyla doldur.
  if (picks.length < total) addFrom(result.target, total);
  if (picks.length < total) addFrom(result.guaranteed, total);
  if (picks.length < total) addFrom(result.dream, total);

  // Taban puanına göre azalan (yüksek/riskli üstte).
  picks.sort((a, b) => b.departmentBaseScore.compareTo(a.departmentBaseScore));
  return picks;
}

class _AutoBuildBody extends ConsumerStatefulWidget {
  final List<UniversityMatch> picks;
  const _AutoBuildBody({required this.picks});

  @override
  ConsumerState<_AutoBuildBody> createState() => _AutoBuildBodyState();
}

class _AutoBuildBodyState extends ConsumerState<_AutoBuildBody> {
  bool _busy = false;

  int _count(MatchCategory c) =>
      widget.picks.where((m) => m.category == c).length;

  Future<void> _create() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final list = await ref
          .read(preferenceListControllerProvider.notifier)
          .create(title: 'Robot Tercih Listem');
      if (list == null) {
        setState(() => _busy = false);
        return;
      }
      final items = <PreferenceItem>[
        for (var i = 0; i < widget.picks.length; i++)
          buildPreferenceItem(
            widget.picks[i].university,
            widget.picks[i].department,
            order: i + 1,
          ),
      ];
      await ref
          .read(preferenceListRepositoryProvider)
          .reorderItems(list.id, items);
      AnalyticsService.instance
          .trackEvent(AnalyticsEvent.preferenceAutoListCreated);
      if (!mounted) return;
      Navigator.pop(context);
      context.push('/my-lists/${list.id}');
    } catch (e) {
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 4, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLightFor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.tierPlus.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: AppColors.tierPlus, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Dengeli ${widget.picks.length}\'lük liste',
                    style: AppTextStyles.titleLarge
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _CompChip(
                  label: 'Garanti',
                  count: _count(MatchCategory.guaranteed),
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _CompChip(
                  label: 'Hedef',
                  count: _count(MatchCategory.target),
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                _CompChip(
                  label: 'Riskli',
                  count: _count(MatchCategory.dream),
                  color: AppColors.error,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Programlar taban puanına göre sıralanır — yüksek/riskli tercihler '
              'üstte, garantiler altta. Oluşturduktan sonra listeyi düzenleyebilirsin.',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondaryFor(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _busy ? null : _create,
                icon: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.4),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_busy ? 'Oluşturuluyor…' : 'Listeyi oluştur'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _CompChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: AppTextStyles.titleLarge
                  .copyWith(color: color, fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
