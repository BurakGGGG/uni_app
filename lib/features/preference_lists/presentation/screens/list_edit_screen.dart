import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../university/presentation/widgets/score_badge.dart';
import '../providers/preference_list_providers.dart';
import '../../domain/models/preference_list_model.dart';
import '../widgets/share_list_sheet.dart';
import '../widgets/department_picker_sheet.dart';

class ListEditScreen extends ConsumerStatefulWidget {
  final String listId;
  const ListEditScreen({super.key, required this.listId});

  @override
  ConsumerState<ListEditScreen> createState() => _ListEditScreenState();
}

class _ListEditScreenState extends ConsumerState<ListEditScreen> {
  List<PreferenceItem>? _draftItems;
  List<PreferenceItem>? _lastSavedItems;
  List<PreferenceItem>? _previousOrderBeforeSort;
  bool _isSaving = false;
  bool _isDeleting = false;

  Future<void> _addItem(PreferenceListModel currentList) async {
    final newItem = await DepartmentPickerSheet.show(context);
    if (newItem == null) return;

    final currentItems = _effectiveItems(currentList);
    if (currentItems.any((i) => i.deptId == newItem.deptId)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bu bölüm zaten listede')));
      }
      return;
    }

    if (currentItems.length >= PreferenceListModel.maxItems) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Listede en fazla ${PreferenceListModel.maxItems} tercih olabilir',
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _draftItems = [
        ...currentItems,
        newItem.copyWith(order: currentItems.length + 1),
      ];
    });
  }

  List<PreferenceItem> _effectiveItems(PreferenceListModel list) =>
      _draftItems ?? list.items;

  void _syncDraftIfNeeded(PreferenceListModel list) {
    final incoming = _normalizedItems(list.items);
    if (_draftItems == null) {
      _draftItems = incoming;
      _lastSavedItems = incoming;
      return;
    }

    if (!_isDirty && !_listEquals(_lastSavedItems, incoming)) {
      _draftItems = incoming;
      _lastSavedItems = incoming;
      _previousOrderBeforeSort = null;
    }
  }

  bool get _isDirty => !_listEquals(_draftItems, _lastSavedItems);

  Future<void> _saveItems() async {
    final items = _draftItems;
    if (items == null || !_isDirty || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(preferenceListRepositoryProvider)
          .reorderItems(widget.listId, items);
      if (!mounted) return;
      setState(() {
        _lastSavedItems = _normalizedItems(items);
        _draftItems = _normalizedItems(items);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tercih listesi kaydedildi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kaydetme hatası: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteList(PreferenceListModel list) async {
    if (_isDeleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Listeyi Sil'),
        content: Text(
          '"${list.title}" listesini silmek istediğine emin misin? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Vazgeç',
              style: TextStyle(color: AppColors.textSecondaryFor(context)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(preferenceListControllerProvider.notifier).delete(list.id);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tercih listesi silindi')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Silme hatası: $e')));
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _sortByRankingAscending(PreferenceListModel list) {
    final current = _effectiveItems(list);
    if (current.length < 2) return;

    // Sıralama (ranking) küçük = daha iyi (1. sıra en iyi). Bu yüzden artan sıralama:
    // ranking'i olmayan veya 0 olan öğeler en sona düşer.
    setState(() {
      _previousOrderBeforeSort = _normalizedItems(current);
      final sorted = [...current]
        ..sort((a, b) {
          final aRank = (a.ranking == null || a.ranking! <= 0)
              ? double.infinity
              : a.ranking!.toDouble();
          final bRank = (b.ranking == null || b.ranking! <= 0)
              ? double.infinity
              : b.ranking!.toDouble();
          final rankCompare = aRank.compareTo(bRank);
          if (rankCompare != 0) return rankCompare;
          return a.order.compareTo(b.order);
        });
      _draftItems = _normalizedItems(sorted);
    });
  }

  void _undoSort() {
    final previous = _previousOrderBeforeSort;
    if (previous == null) return;
    setState(() {
      _draftItems = _normalizedItems(previous);
      _previousOrderBeforeSort = null;
    });
  }

  void _removeAt(int index, PreferenceListModel list) {
    final current = _effectiveItems(list);
    setState(() {
      final updated = [...current]..removeAt(index);
      _draftItems = _normalizedItems(updated);
    });
  }

  List<PreferenceItem> _normalizedItems(List<PreferenceItem> items) {
    return List<PreferenceItem>.generate(
      items.length,
      (index) => items[index].copyWith(order: index + 1),
      growable: false,
    );
  }

  bool _listEquals(List<PreferenceItem>? a, List<PreferenceItem>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_sameItem(a[i], b[i])) return false;
    }
    return true;
  }

  bool _sameItem(PreferenceItem a, PreferenceItem b) {
    return a.deptId == b.deptId &&
        a.uniId == b.uniId &&
        a.order == b.order &&
        a.note == b.note &&
        a.deptName == b.deptName &&
        a.uniName == b.uniName &&
        a.uniLogoUrl == b.uniLogoUrl &&
        a.faculty == b.faculty &&
        a.deptType == b.deptType &&
        a.language == b.language &&
        a.scoreType == b.scoreType &&
        a.baseScore == b.baseScore &&
        a.ranking == b.ranking &&
        a.quota == b.quota &&
        a.placedCount == b.placedCount &&
        a.uniBrandHex == b.uniBrandHex;
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(preferenceListProvider(widget.listId));

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: listAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (list) {
          if (list == null) {
            return const Center(child: Text('Liste bulunamadı.'));
          }
          _syncDraftIfNeeded(list);
          return _buildContent(list);
        },
      ),
    );
  }

  Widget _buildContent(PreferenceListModel list) {
    final items = _effectiveItems(list);
    final isFull = items.length >= PreferenceListModel.maxItems;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimaryFor(context),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.share_rounded,
                      color: AppColors.textPrimaryFor(context),
                    ),
                    onPressed: () => ShareListSheet.show(context, list),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  list.title,
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                if (list.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    list.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondaryFor(context),
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _ListSummaryCard(list: list.copyWith(items: items)),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: _ActionBar(
              canUndo: _previousOrderBeforeSort != null,
              canSort: items.length > 1,
              onSort: () => _sortByRankingAscending(list),
              onUndo: _undoSort,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: _GradientBorderButton(
              onPressed: isFull
                  ? null
                  : () => _addItem(list.copyWith(items: items)),
              height: 50,
              icon: Icons.add_rounded,
              label: isFull
                  ? 'Limit dolu (${PreferenceListModel.maxItems})'
                  : 'Bölüm Ekle',
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isDeleting ? null : () => _deleteList(list),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.28),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text(
                      'Sil',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GradientBorderButton(
                    onPressed: _isDirty && !_isSaving ? _saveItems : null,
                    icon: _isSaving ? null : Icons.save_rounded,
                    label: _isDirty ? 'Kaydet' : 'Kaydedildi',
                    child: _isSaving
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (items.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: _EmptyItems())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            sliver: SliverReorderableList(
              itemCount: items.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                setState(() {
                  final reordered = [...items];
                  final item = reordered.removeAt(oldIndex);
                  reordered.insert(newIndex, item);
                  _draftItems = _normalizedItems(reordered);
                });
              },
              itemBuilder: (context, index) {
                final item = items[index];
                return _ItemCard(
                  key: ValueKey('${item.deptId}_${item.order}'),
                  item: item,
                  index: index,
                  onDelete: () => _removeAt(index, list),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  final bool canSort;
  final bool canUndo;
  final VoidCallback onSort;
  final VoidCallback onUndo;

  const _ActionBar({
    required this.canSort,
    required this.canUndo,
    required this.onSort,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canSort ? onSort : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimaryFor(context),
              side: BorderSide(color: AppColors.borderLightFor(context)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.sort_rounded, size: 18),
            label: const Text(
              'Sıralamaya Göre',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canUndo ? onUndo : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondaryFor(context),
              side: BorderSide(color: AppColors.borderLightFor(context)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.undo_rounded, size: 18),
            label: const Text(
              'Geri Al',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _ListSummaryCard extends StatelessWidget {
  final PreferenceListModel list;
  const _ListSummaryCard({required this.list});

  @override
  Widget build(BuildContext context) {
    final filled = list.items.length;
    const max = PreferenceListModel.maxItems;
    final progress = (filled / max).clamp(0.0, 1.0);

    final stByCount = <String, int>{};
    for (final it in list.items) {
      final st = it.scoreType;
      if (st == null) continue;
      stByCount[st] = (stByCount[st] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightFor(context)),
        boxShadow: AppColors.softShadowFor(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$filled',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ $max tercih',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: list.isPublic
                      ? AppColors.success.withValues(alpha: 0.10)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      list.isPublic ? Icons.public_rounded : Icons.lock_rounded,
                      size: 12,
                      color: list.isPublic
                          ? AppColors.success
                          : AppColors.textTertiaryFor(context),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      list.isPublic ? 'Herkese Açık' : 'Gizli',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: list.isPublic
                            ? AppColors.success
                            : AppColors.textTertiaryFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _GradientProgressBar(progress: progress),
          if (stByCount.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stByCount.entries
                  .map((e) => _ScoreTypeChip(type: e.key, count: e.value))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreTypeChip extends StatelessWidget {
  final String type;
  final int count;
  const _ScoreTypeChip({required this.type, required this.count});

  @override
  Widget build(BuildContext context) {
    final color = _color(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$count $type',
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _color(String type) {
    switch (type) {
      case 'SAY':
        return const Color(0xFF3B82F6);
      case 'EA':
        return const Color(0xFF8B5CF6);
      case 'SOZ':
      case 'SÖZ':
        return const Color(0xFFEC4899);
      case 'DIL':
      case 'DİL':
        return const Color(0xFF10B981);
      case 'TYT':
        return const Color(0xFFF59E0B);
      default:
        return AppColors.primary;
    }
  }
}

class _EmptyItems extends StatelessWidget {
  const _EmptyItems();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Liste boş',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '"Bölüm Ekle" butonuna tıklayarak üniversite ve bölüm seç. '
              'Tercihlerini sürükleyerek veya sıralamaya göre düzenleyebilirsin.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryFor(context),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final PreferenceItem item;
  final int index;
  final VoidCallback onDelete;

  const _ItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final brand = _hexToColor(item.uniBrandHex) ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLightFor(context)),
            boxShadow: AppColors.softShadowFor(context),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: brand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: brand,
                        fontWeight: FontWeight.w800,
                        fontSize: index < 9 ? 18 : 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.deptName,
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.scoreType != null) ...[
                            const SizedBox(width: 6),
                            ScoreBadge.scoreType(item.scoreType!, small: true),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.uniName,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondaryFor(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_hasScoreInfo) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (item.baseScore != null && item.baseScore! > 0)
                              _MiniStat(
                                icon: Icons.trending_up_rounded,
                                color: AppColors.primary,
                                value: item.baseScore!.toStringAsFixed(2),
                              ),
                            if (item.ranking != null && item.ranking! > 0)
                              _MiniStat(
                                icon: Icons.emoji_events_rounded,
                                color: AppColors.warning,
                                value: _formatRank(item.ranking!),
                              ),
                            if (item.quota != null && item.quota! > 0)
                              _MiniStat(
                                icon: Icons.people_alt_rounded,
                                color: AppColors.info,
                                value: item.placedCount != null
                                    ? '${item.placedCount}/${item.quota}'
                                    : '${item.quota}',
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: AppColors.textTertiaryFor(context),
                      size: 22,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.error,
                    size: 18,
                  ),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.error.withValues(alpha: 0.08),
                    minimumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasScoreInfo =>
      (item.baseScore != null && item.baseScore! > 0) ||
      (item.ranking != null && item.ranking! > 0) ||
      (item.quota != null && item.quota! > 0);

  static String _formatRank(int rank) {
    if (rank >= 1000000) return '${(rank / 1000000).toStringAsFixed(1)}M';
    if (rank >= 1000) return '${(rank / 1000).toStringAsFixed(0)}B';
    return '$rank';
  }

  static Color? _hexToColor(String? hex) {
    if (hex == null) return null;
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    final v = int.tryParse(h, radix: 16);
    return v != null ? Color(v) : null;
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gradient Border Button ──────────────────────────────────────
class _GradientBorderButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? label;
  final double? height;
  final Widget? child;

  const _GradientBorderButton({
    this.onPressed,
    this.icon,
    this.label,
    this.height,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final gradient = AppColors.heroGradient;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: height ?? 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: enabled ? gradient : null,
          border: enabled
              ? null
              : Border.all(color: AppColors.borderLightFor(context)),
        ),
        padding: const EdgeInsets.all(1.8),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(10.5),
          ),
          child: Center(
            child: child ??
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            gradient.createShader(bounds),
                        child: Icon(
                          icon,
                          size: 20,
                          color: enabled ? Colors.white : AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (label != null)
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            gradient.createShader(bounds),
                        child: Text(
                          label!,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: enabled
                                ? Colors.white
                                : AppColors.textTertiary,
                          ),
                        ),
                      ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}

// ── Gradient Progress Bar ───────────────────────────────────────
class _GradientProgressBar extends StatelessWidget {
  final double progress;
  const _GradientProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantFor(context),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
