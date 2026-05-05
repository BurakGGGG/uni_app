import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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
  Future<void> _addItem(PreferenceListModel currentList) async {
    final newItem = await DepartmentPickerSheet.show(context);
    if (newItem == null) return;
    
    if (currentList.items.any((i) => i.deptId == newItem.deptId)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu bölüm zaten listede')));
      return;
    }

    try {
      await ref.read(preferenceListRepositoryProvider).addItem(widget.listId, newItem);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(preferenceListProvider(widget.listId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (list) {
          if (list == null) return const Center(child: Text('Liste bulunamadı.'));
          return _buildContent(list);
        },
      ),
    );
  }

  Widget _buildContent(PreferenceListModel list) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Gradient Header ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6584), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.share_rounded, color: Colors.white),
                          onPressed: () => ShareListSheet.show(context, list),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            list.title,
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (list.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              list.description,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Stats chips
                          Row(
                            children: [
                              _HeaderChip(
                                icon: Icons.format_list_bulleted_rounded,
                                label: '${list.items.length} / ${PreferenceListModel.maxItems} tercih',
                              ),
                              const SizedBox(width: 12),
                              _HeaderChip(
                                icon: list.isPublic ? Icons.public_rounded : Icons.lock_rounded,
                                label: list.isPublic ? 'Herkese Açık' : 'Gizli',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Add Button ────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => _addItem(list),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text('Bölüm Seç ve Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ),

        // ── List Items or Empty State ─────────────────────────
        if (list.items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyItems(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            sliver: SliverReorderableList(
              itemCount: list.items.length,
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex--;
                final items = List<PreferenceItem>.from(list.items);
                final item = items.removeAt(oldIndex);
                items.insert(newIndex, item);
                try {
                  await ref.read(preferenceListRepositoryProvider).reorderItems(widget.listId, items);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                  }
                }
              },
              itemBuilder: (context, index) {
                final item = list.items[index];
                return _ItemCard(
                  key: ValueKey(item.deptId),
                  item: item,
                  index: index,
                  onDelete: () async {
                    final items = List<PreferenceItem>.from(list.items)..removeAt(index);
                    await ref.read(preferenceListRepositoryProvider).reorderItems(widget.listId, items);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyItems() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_rounded, size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Listeye Bölüm Ekle',
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Yukarıdaki butona tıklayarak üniversite ve bölüm seçebilirsin.\nTercihlerini sürükleyerek sıralayabilirsin.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header Chip ──────────────────────────────────────────────
class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Individual Item Card ─────────────────────────────────────
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        elevation: 1,
        shadowColor: AppColors.textPrimary.withValues(alpha: 0.06),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              children: [
                // Drag handle
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.drag_handle_rounded, color: AppColors.textTertiary.withValues(alpha: 0.5), size: 22),
                  ),
                ),
                // Order number
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.primary.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: index < 9 ? 16 : 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Department info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.deptName,
                        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.uniName,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Delete button
                IconButton(
                  icon: Icon(Icons.close_rounded, color: AppColors.error.withValues(alpha: 0.7), size: 20),
                  onPressed: onDelete,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.error.withValues(alpha: 0.06),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
