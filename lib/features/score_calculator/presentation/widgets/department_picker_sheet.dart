import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../providers/score_calculator_providers.dart';

class DepartmentPickerSheet extends ConsumerStatefulWidget {
  /// Doluysa liste yalnız bu puan türünde okutulan bölümleri gösterir.
  final String scoreType;

  const DepartmentPickerSheet({super.key, this.scoreType = ''});

  static Future<String?> show(BuildContext context, {String scoreType = ''}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DepartmentPickerSheet(scoreType: scoreType),
    );
  }

  @override
  ConsumerState<DepartmentPickerSheet> createState() => _DepartmentPickerSheetState();
}

class _DepartmentPickerSheetState extends ConsumerState<DepartmentPickerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final asyncNames =
        ref.watch(uniqueDepartmentNamesProvider(widget.scoreType));
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.85,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: AppColors.backgroundFor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiaryFor(context).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.scoreType.isEmpty
                      ? 'Bölüm Seç'
                      : 'Bölüm Seç (${widget.scoreType})',
                  style: AppTextStyles.titleLarge,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceFor(context),
                  ),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: AppSearchBar(
              hintText: 'Bölüm ara...',
              onChanged: (val) {
                setState(() => _searchQuery = val.toLowerCase().trim());
              },
            ),
          ),

          // List
          Expanded(
            child: asyncNames.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Text('Bölümler yüklenemedi', style: AppTextStyles.bodyMedium),
              ),
              data: (names) {
                final filtered = names
                    .where((n) => n.toLowerCase().contains(_searchQuery))
                    .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text('Bölüm bulunamadı', style: AppTextStyles.bodyMedium),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final name = filtered[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      title: Text(name, style: AppTextStyles.bodyLarge),
                      onTap: () => Navigator.pop(context, name),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
