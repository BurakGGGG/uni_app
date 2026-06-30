import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/preference_list_model.dart';
import '../providers/preference_list_providers.dart';
import '../../../admin/data/analytics_service.dart';
import '../../../admin/domain/models/analytics_event.dart';

class ShareListSheet {
  static Future<void> show(BuildContext context, PreferenceListModel list) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceFor(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _Content(initialList: list),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  final PreferenceListModel initialList;
  const _Content({required this.initialList});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final listsAsync = ref.watch(myPreferenceListsProvider);
    final currentList =
        listsAsync.value?.firstWhere(
          (l) => l.id == initialList.id,
          orElse: () => initialList,
        ) ??
        initialList;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
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

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.share_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.prefListShareTitle,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      currentList.title,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondaryFor(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Public/Private toggle
          Material(
            color: AppColors.surfaceVariantFor(context).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                loc.prefListPublicTitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                loc.prefListPublicShareSubtitle,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
              value: currentList.isPublic,
              activeTrackColor: AppColors.primary,
              onChanged: (v) async {
                try {
                  await ref
                      .read(preferenceListControllerProvider.notifier)
                      .update(currentList.copyWith(isPublic: v));
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      SnackBar(content: Text(loc.errorGeneral(e.toString()))),
                    );
                  }
                }
              },
            ),
          ),

          if (currentList.isPublic) ...[
            const SizedBox(height: 16),
            // Link card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.link_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      currentList.publicUrl,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.copy_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: currentList.publicUrl),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(loc.prefListLinkCopied),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Share button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () => _shareList(context, currentList),
                icon: const Icon(Icons.ios_share_rounded, size: 20),
                label: Text(
                  loc.prefListShareLinkButton,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.remove_red_eye_rounded,
                  size: 14,
                  color: AppColors.textTertiaryFor(context),
                ),
                const SizedBox(width: 5),
                Text(
                  loc.prefListViewCount(currentList.viewCount),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiaryFor(context),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariantFor(context).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.textTertiaryFor(context),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loc.prefListPrivateNotice,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryFor(context),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _shareList(BuildContext context, PreferenceListModel list) {
    final loc = AppLocalizations.of(context);
    final preview = list.items
        .take(3)
        .map((it) {
          final order = it.order > 0 ? it.order : (list.items.indexOf(it) + 1);
          return '$order. ${it.deptName} — ${it.uniName}';
        })
        .join('\n');
    final extra = list.items.length > 3
        ? '\n${loc.prefListShareTextExtra(list.items.length - 3)}'
        : '';
    final text =
        '${loc.prefListShareTextHeader(list.title)}\n\n'
        '$preview$extra\n\n'
        '${list.publicUrl}';
    AnalyticsService.instance.trackEvent(AnalyticsEvent.preferenceListShared);
    Share.share(text, subject: list.title);
  }
}
