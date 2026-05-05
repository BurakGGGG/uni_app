import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/preference_list_providers.dart';
import '../../domain/models/preference_list_model.dart';

class SharedListScreen extends ConsumerWidget {
  final String shareSlug;
  const SharedListScreen({super.key, required this.shareSlug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(publicListBySlugProvider(shareSlug));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paylaşılan Liste'),
        actions: [
          if (ref.watch(authStateProvider).value == null)
            TextButton(
              onPressed: () => context.push('/login'),
              child: const Text('Giriş Yap'),
            ),
        ],
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (list) {
          if (list == null) {
            return const Center(
              child: Text(
                'Liste bulunamadı.\nBu liste silinmiş veya gizli olarak işaretlenmiş olabilir.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return _buildListView(context, list);
        },
      ),
    );
  }

  Widget _buildListView(BuildContext context, PreferenceListModel list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(list.title, style: AppTextStyles.headlineMedium),
              if (list.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(list.description, style: AppTextStyles.bodyMedium),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: list.userPhotoUrl != null ? NetworkImage(list.userPhotoUrl!) : null,
                    child: list.userPhotoUrl == null ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 8),
                  Text(list.userName, style: AppTextStyles.titleSmall),
                ],
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: list.items.length,
            itemBuilder: (context, index) {
              final item = list.items[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text('${index + 1}', style: const TextStyle(color: AppColors.primary)),
                ),
                title: Text(item.deptName),
                subtitle: Text(item.uniName),
              );
            },
          ),
        ),
      ],
    );
  }
}
