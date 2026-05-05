import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../../university/domain/models/university_model.dart';
import '../../domain/models/preference_list_model.dart';

class DepartmentPickerSheet {
  static Future<PreferenceItem?> show(BuildContext context) {
    return showModalBottomSheet<PreferenceItem?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => _Body(scrollController: scrollController),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  const _Body({required this.scrollController});

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  UniversityModel? _selectedUni;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 48,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.borderLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (_selectedUni != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  onPressed: () => setState(() {
                    _selectedUni = null;
                    _searchQuery = '';
                    _searchController.clear();
                  }),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                  ),
                ),
              if (_selectedUni != null) const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedUni == null ? 'Üniversite Seç' : 'Bölüm Seç',
                  style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  textAlign: _selectedUni == null ? TextAlign.center : TextAlign.left,
                ),
              ),
              if (_selectedUni == null) const SizedBox(width: 48), // balance back button
            ],
          ),
        ),
        
        // Search (if Uni not selected)
        if (_selectedUni == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AppSearchBar(
              controller: _searchController,
              hintText: 'Üniversite ara...',
              onChanged: (v) => setState(() => _searchQuery = v),
              trailing: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  : null,
            ),
          ),
          
        if (_selectedUni != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surfaceVariant.withValues(alpha: 0.5),
            width: double.infinity,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Image.asset(
                    _selectedUni!.logoAssetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.account_balance_rounded, 
                      color: AppColors.primary, 
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedUni!.name,
                        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_selectedUni!.type} • Kuruluş: ${_selectedUni!.establishedYear}',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const Divider(height: 1),

        // Content
        Expanded(
          child: _selectedUni == null 
              ? _buildUniList()
              : _buildDeptList(_selectedUni!),
        ),
      ],
    );
  }

  Widget _buildUniList() {
    final unisAsync = ref.watch(allUniversitiesProvider);
    
    return unisAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Hata: $e')),
      data: (unis) {
        final filtered = unis.where((u) => u.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        
        if (filtered.isEmpty) {
          return Center(
            child: Text(
              'Sonuç bulunamadı',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.separated(
          controller: widget.scrollController,
          itemCount: filtered.length,
          padding: const EdgeInsets.only(bottom: 24, top: 8),
          separatorBuilder: (context, index) => const Divider(height: 1, indent: 76),
          itemBuilder: (context, index) {
            final uni = filtered[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  uni.logoAssetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.account_balance_rounded, 
                    color: AppColors.primary, 
                    size: 20,
                  ),
                ),
              ),
              title: Text(uni.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
              subtitle: Text(
                '${uni.type} • Kuruluş: ${uni.establishedYear}',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
              onTap: () => setState(() => _selectedUni = uni),
            );
          },
        );
      },
    );
  }

  Widget _buildDeptList(UniversityModel uni) {
    final deptsAsync = ref.watch(departmentsByUniversityProvider(uni.id));
    
    return deptsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Hata: $e')),
      data: (depts) {
        if (depts.isEmpty) {
          return Center(
            child: Text(
              'Bu üniversiteye ait bölüm bulunamadı.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          );
        }
        
        return ListView.separated(
          controller: widget.scrollController,
          itemCount: depts.length,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final dept = depts[index];
            return InkWell(
              onTap: () {
                final item = PreferenceItem(
                  deptId: dept.id,
                  uniId: uni.id,
                  order: 0,
                  deptName: dept.name,
                  uniName: uni.name,
                  uniLogoUrl: uni.logoAssetPath,
                );
                Navigator.pop(context, item);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dept.name,
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dept.faculty,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Badge(text: dept.type, color: AppColors.primary),
                        if (dept.scoreType != null)
                          _Badge(text: dept.scoreType!, color: AppColors.secondary),
                        _Badge(text: dept.language, color: AppColors.accent),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
