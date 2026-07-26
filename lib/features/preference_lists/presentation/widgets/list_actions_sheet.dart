import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/list_overview.dart';
import '../../domain/models/preference_list_model.dart';
import '../providers/preference_list_providers.dart';
import 'list_share_card.dart';
import 'rename_list_sheet.dart';
import 'share_list_sheet.dart';

/// Bir listenin tüm eylemleri tek yerde.
///
/// Hem kahraman kartın "⋯" düğmesi hem kompakt satırlar hem de detay ekranı
/// bunu açar — eylem kümesi üç yerde ayrı ayrı tanımlanırsa biri unutulur.
class ListActionsSheet {
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    ListOverview overview, {
    VoidCallback? onDeleted,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      // Sayfa kapandıktan SONRA çalışan işler (snackbar, ikinci bir sheet)
      // sheet'in kendi context'ini kullanamaz — o eleman artık ölüdür.
      // Ekranın context'i buradan taşınıyor.
      builder: (_) => _Sheet(
        host: context,
        overview: overview,
        onDeleted: onDeleted,
      ),
    );
  }
}

class _Sheet extends ConsumerWidget {
  /// Sheet'i açan ekranın context'i — kapandıktan sonraki işler bunu kullanır.
  final BuildContext host;
  final ListOverview overview;
  final VoidCallback? onDeleted;

  const _Sheet({
    required this.host,
    required this.overview,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = overview.list;
    final loc = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tutamak temadan geliyor (`showDragHandle: true`).
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      list.title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${overview.filled}/${ListOverview.capacity}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondaryFor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            _Tile(
              icon: overview.pinned
                  ? Icons.push_pin_rounded
                  : Icons.push_pin_outlined,
              color: AppColors.primary,
              label: overview.pinned
                  ? loc.prefListUnpinAction
                  : loc.prefListPinAction,
              subtitle: overview.pinned
                  ? loc.prefListUnpinDesc
                  : loc.prefListPinDesc,
              onTap: () async {
                Navigator.pop(context);
                await ref.read(pinnedListProvider.notifier).toggle(list.id);
              },
            ),
            _Tile(
              icon: Icons.link_rounded,
              color: AppColors.info,
              label: loc.prefListShareLink,
              subtitle: loc.prefListActionsShareDesc,
              onTap: () {
                Navigator.pop(context);
                ShareListSheet.show(host, list);
              },
            ),
            _Tile(
              icon: Icons.image_rounded,
              color: AppColors.secondary,
              label: loc.prefListShareImage,
              subtitle: loc.prefListShareImageDesc,
              onTap: () {
                Navigator.pop(context);
                ListShareCard.share(host, overview);
              },
            ),
            _Tile(
              icon: Icons.drive_file_rename_outline_rounded,
              color: AppColors.textSecondaryFor(context),
              label: loc.prefListRenameAction,
              subtitle: loc.prefListRenameDesc,
              onTap: () {
                Navigator.pop(context);
                RenameListSheet.show(host, ref, list);
              },
            ),
            _Tile(
              icon: Icons.copy_all_rounded,
              color: AppColors.textSecondaryFor(context),
              label: loc.prefListDuplicateAction,
              subtitle: loc.prefListDuplicateDesc,
              onTap: () async {
                Navigator.pop(context);
                await _duplicate(host, ref, list);
              },
            ),
            _Tile(
              icon: Icons.delete_outline_rounded,
              color: AppColors.error,
              label: loc.prefListDeleteTitle,
              subtitle: loc.prefListDeleteUndoDesc,
              onTap: () async {
                Navigator.pop(context);
                await deleteListWithUndo(host, ref, list);
                onDeleted?.call();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _duplicate(
    BuildContext context,
    WidgetRef ref,
    PreferenceListModel list,
  ) async {
    try {
      final suffix = AppLocalizations.of(context).prefListCopySuffix;
      await ref.read(preferenceListControllerProvider.notifier).copy(
            list.copyWith(title: copyTitle(list.title, suffix)),
          );
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        message: AppLocalizations.of(context).prefListDuplicated,
        isSuccess: true,
      );
    } catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }
}

/// "Sayısal Planım" → "Sayısal Planım (kopya)".
///
/// Başlık sınırı 80 karakter; uzun adlarda ek sığmazsa taban kırpılır —
/// yoksa depo doğrulaması kopyalamayı reddeder.
@visibleForTesting
String copyTitle(String title, String suffix) {
  const limit = 80;
  final tail = ' ($suffix)';
  final room = limit - tail.length;
  final base = title.length > room ? title.substring(0, room) : title;
  return '$base$tail';
}

/// Listeyi siler ve birkaç saniye "GERİ AL" sunar.
///
/// Onay dialogu yerine geri alma (kullanıcı kararı): silmek tek dokunuş
/// kalır, hata affedilir. Geri alma listeyi AYNI içerikle yeniden kurar —
/// Firestore'da silinen doküman geri gelmez, id ve paylaşım linki değişir.
Future<void> deleteListWithUndo(
  BuildContext context,
  WidgetRef ref,
  PreferenceListModel list,
) async {
  final controller = ref.read(preferenceListControllerProvider.notifier);
  try {
    await controller.delete(list.id);
  } catch (e) {
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      message: e.toString().replaceAll('Exception: ', ''),
      isError: true,
    );
    return;
  }
  if (!context.mounted) return;

  final loc = AppLocalizations.of(context);
  showAppSnackBar(
    context,
    message: loc.prefListDeletedNamed(list.title),
    duration: const Duration(seconds: 6),
    action: SnackBarAction(
      label: loc.prefListUndoAction,
      textColor: Colors.white,
      onPressed: () async {
        try {
          await controller.copy(list);
        } catch (_) {
          // Geri alma başarısızsa sessiz kalma: kullanıcı listenin geri
          // gelmediğini fark etmeli.
          if (context.mounted) {
            showAppSnackBar(
              context,
              message: loc.prefListRestoreFailed,
              isError: true,
            );
          }
        }
      },
    ),
  );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondaryFor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
