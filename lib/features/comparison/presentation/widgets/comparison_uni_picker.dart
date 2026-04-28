import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../providers/comparison_providers.dart';

class ComparisonUniPicker extends ConsumerWidget {
  const ComparisonUniPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(comparisonSelectionProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _UniSlot(
            uniId: selection.uniIdA,
            label: 'A',
            color: AppColors.primary,
            onTap: () => _showPicker(context, ref, selection, isA: true),
          )),
          const SizedBox(width: 12),
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('VS', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11,
            )),
          ),
          const SizedBox(width: 12),
          Expanded(child: _UniSlot(
            uniId: selection.uniIdB,
            label: 'B',
            color: AppColors.secondary,
            onTap: () => _showPicker(context, ref, selection, isA: false),
          )),
        ],
      ),
    );
  }

  void _showPicker(
    BuildContext context,
    WidgetRef ref,
    ComparisonSelection selection, {
    required bool isA,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) {
          final uniListAsync = ref.watch(allUniversitiesProvider);
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    isA ? 'A için üniversite seç' : 'B için üniversite seç',
                    style: AppTextStyles.titleMedium,
                  ),
                ),
                Expanded(
                  child: uniListAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (unis) => ListView.builder(
                      controller: controller,
                      itemCount: unis.length,
                      itemBuilder: (_, i) {
                        final uni = unis[i];
                        final otherId = isA ? selection.uniIdB : selection.uniIdA;
                        final disabled = uni.id == otherId;
                        return ListTile(
                          enabled: !disabled,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: Text(uni.name[0],
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              )),
                          ),
                          title: Text(uni.name),
                          subtitle: Text('${uni.type} • ${uni.campusLayout.label}'),
                          trailing: disabled ? const Icon(Icons.block, size: 16) : null,
                          onTap: () {
                            Navigator.pop(context);
                            final notifier = ref.read(comparisonSelectionProvider.notifier);
                            isA ? notifier.selectA(uni.id) : notifier.selectB(uni.id);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UniSlot extends ConsumerWidget {
  final String? uniId;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _UniSlot({
    required this.uniId,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (uniId == null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: color, size: 32),
              const SizedBox(height: 8),
              Text('Üni $label seç', style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 13,
              )),
            ],
          ),
        ),
      );
    }

    final uniAsync = ref.watch(universityDetailProvider(uniId!));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: uniAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (_, __) => const Icon(Icons.error_outline),
          data: (uni) {
            if (uni == null) return const SizedBox();
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: uni.logoUrl.isNotEmpty
                    ? ClipOval(child: CachedNetworkImage(
                        imageUrl: uni.logoUrl,
                        width: 48, height: 48, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Text(
                          uni.name[0],
                          style: TextStyle(color: color, fontWeight: FontWeight.w700),
                        ),
                      ))
                    : Text(uni.name[0], style: TextStyle(
                        color: color, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                Text(
                  uni.name,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
