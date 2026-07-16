import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../preference_lists/domain/models/preference_list_model.dart';
import '../../../preference_lists/domain/preference_item_builder.dart';
import '../../../preference_lists/presentation/providers/preference_list_providers.dart';
import '../../../university/domain/models/department_model.dart';
import '../../../university/domain/models/university_model.dart';

/// Bir programı kullanıcının tercih listelerinden birine ekleme akışı.
///
/// Giriş yapılmamışsa login'e yönlendirir. Liste yoksa isim sorup yeni liste
/// oluşturur ve öğeyi ekler. Ekleme `preferenceListRepository.addItem` ile
/// yapılır (24 limiti + `deptId` dedup repository'de hazır).
Future<void> showAddToListSheet(
  BuildContext context,
  WidgetRef ref,
  UniversityModel uni,
  DepartmentModel dept,
) async {
  final user = ref.read(authStateProvider).value;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listeye eklemek için giriş yapmalısın')),
    );
    context.push('/login');
    return;
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceFor(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _AddToListBody(uni: uni, dept: dept),
  );
}

class _AddToListBody extends ConsumerWidget {
  final UniversityModel uni;
  final DepartmentModel dept;
  const _AddToListBody({required this.uni, required this.dept});

  Future<void> _addTo(
    BuildContext context,
    WidgetRef ref,
    PreferenceListModel list,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(preferenceListRepositoryProvider)
          .addItem(list.id, buildPreferenceItem(uni, dept));
      if (context.mounted) Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text('“${dept.name}” → ${list.title} listesine eklendi')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _createAndAdd(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: 'Tercih Listem');
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Yeni liste'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(
            hintText: 'Liste adı',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Oluştur ve ekle'),
          ),
        ],
      ),
    );
    if (title == null || title.isEmpty) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final list =
          await ref.read(preferenceListControllerProvider.notifier).create(
                title: title,
              );
      if (list == null) return;
      await ref
          .read(preferenceListRepositoryProvider)
          .addItem(list.id, buildPreferenceItem(uni, dept));
      if (context.mounted) Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text('“$title” listesi oluşturuldu ve eklendi')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(myPreferenceListsProvider);

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
            Text(
              'Listeye ekle',
              style: AppTextStyles.titleLarge
                  .copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
            ),
            const SizedBox(height: 2),
            Text(
              '${dept.name} · ${uni.name}',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textSecondaryFor(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            listsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Listeler yüklenemedi: $e'),
              ),
              data: (lists) {
                return Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final list in lists)
                        _ListTile(
                          list: list,
                          onTap: () => _addTo(context, ref, list),
                        ),
                      _NewListTile(onTap: () => _createAndAdd(context, ref)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  final PreferenceListModel list;
  final VoidCallback onTap;
  const _ListTile({required this.list, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final full = list.items.length >= PreferenceListModel.maxItems;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: full ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.format_list_numbered_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.title,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${list.items.length}/${PreferenceListModel.maxItems} tercih',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: full
                            ? AppColors.error
                            : AppColors.textSecondaryFor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                full ? Icons.block_rounded : Icons.add_rounded,
                color: full
                    ? AppColors.error
                    : AppColors.textTertiaryFor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewListTile extends StatelessWidget {
  final VoidCallback onTap;
  const _NewListTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded,
                    color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Yeni liste oluştur ve ekle',
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
