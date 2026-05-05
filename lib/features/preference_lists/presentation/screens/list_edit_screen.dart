import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/preference_list_providers.dart';
import '../../domain/models/preference_list_model.dart';
import '../widgets/share_list_sheet.dart';

class ListEditScreen extends ConsumerStatefulWidget {
  final String listId;
  const ListEditScreen({super.key, required this.listId});

  @override
  ConsumerState<ListEditScreen> createState() => _ListEditScreenState();
}

class _ListEditScreenState extends ConsumerState<ListEditScreen> {
  Future<void> _addItem(PreferenceListModel currentList) async {
    final newItem = PreferenceItem(
      deptId: 'dummy_${DateTime.now().millisecondsSinceEpoch}',
      uniId: 'dummy_uni',
      order: currentList.items.length + 1,
      deptName: 'Örnek Bölüm ${currentList.items.length + 1}',
      uniName: 'Örnek Üniversite',
    );
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
      appBar: AppBar(
        title: const Text('Liste Düzenle'),
        actions: [
          if (listAsync.value != null)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () => ShareListSheet.show(context, listAsync.value!),
            ),
        ],
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (list) {
          if (list == null) return const Center(child: Text('Liste bulunamadı.'));
          return _buildContent(list);
        },
      ),
    );
  }

  Widget _buildContent(PreferenceListModel list) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(list.title, style: AppTextStyles.headlineMedium),
              if (list.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(list.description, style: AppTextStyles.bodyMedium),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _addItem(list),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Bölüm Ekle (Örnek)'),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: list.items.isEmpty
              ? const Center(child: Text('Listenizde henüz bir tercih yok.'))
              : ReorderableListView.builder(
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
                    return ListTile(
                      key: ValueKey(item.deptId),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text('${index + 1}', style: const TextStyle(color: AppColors.primary)),
                      ),
                      title: Text(item.deptName),
                      subtitle: Text(item.uniName),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                        onPressed: () async {
                           final items = List<PreferenceItem>.from(list.items)..removeAt(index);
                           await ref.read(preferenceListRepositoryProvider).reorderItems(widget.listId, items);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
