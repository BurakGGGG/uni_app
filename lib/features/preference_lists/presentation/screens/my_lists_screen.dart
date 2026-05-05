import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/preference_list_providers.dart';
import '../../domain/models/preference_list_model.dart';
import '../widgets/share_list_sheet.dart';

class MyListsScreen extends ConsumerWidget {
  const MyListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const _UnauthenticatedView();

    final listsAsync = ref.watch(myPreferenceListsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tercih Listelerim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline_rounded),
            tooltip: 'Favorilerim',
            onPressed: () => context.push('/favorites'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yeni Liste'),
      ),
      body: listsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (lists) {
          if (lists.isEmpty) return const _EmptyState();
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: lists.length,
            itemBuilder: (_, i) => _ListCard(
              list: lists[i],
              onTap: () => context.push('/my-lists/${lists[i].id}'),
              onShare: () => ShareListSheet.show(context, lists[i]),
              onDelete: () => _confirmDelete(context, ref, lists[i]),
            ),
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Yeni Liste Oluştur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Liste Adı'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Açıklama (Opsiyonel)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              try {
                final list = await ref.read(preferenceListControllerProvider.notifier).create(
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                );
                if (c.mounted) {
                  Navigator.pop(c);
                  if (list != null) c.push('/my-lists/${list.id}');
                }
              } catch (e) {
                if (c.mounted) {
                  ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text('Hata: $e')));
                }
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, PreferenceListModel list) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Listeyi Sil'),
        content: Text('"${list.title}" listesini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('İptal')),
          TextButton(
            onPressed: () {
              ref.read(preferenceListControllerProvider.notifier).delete(list.id);
              Navigator.pop(c);
            },
            child: const Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final PreferenceListModel list;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _ListCard({required this.list, required this.onTap, required this.onShare, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(list.title, style: AppTextStyles.titleMedium),
        subtitle: Text('${list.items.length} tercih • ${list.isPublic ? "Herkese Açık" : "Gizli"}'),
        onTap: onTap,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.share_rounded), onPressed: onShare),
            IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Henüz bir tercih listesi oluşturmadınız.'),
    );
  }
}

class _UnauthenticatedView extends StatelessWidget {
  const _UnauthenticatedView();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tercih Listelerim')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Listelerinizi görmek için giriş yapmalısınız.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              child: const Text('Giriş Yap'),
            ),
          ],
        ),
      ),
    );
  }
}
