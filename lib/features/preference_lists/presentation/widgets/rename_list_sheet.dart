import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/preference_list_model.dart';
import '../providers/preference_list_providers.dart';
import 'sheet_form_field.dart';

/// Liste adı ve açıklamasını düzenler.
///
/// İkisi de `firestore.rules`'daki güncelleme beyaz listesinde zaten var
/// (`title`, `description`) — yeni bir kural/deploy gerekmiyor.
class RenameListSheet {
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    PreferenceListModel list,
  ) {
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
        child: _Body(list: list),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  final PreferenceListModel list;
  const _Body({required this.list});

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.list.title);
    _description = TextEditingController(text: widget.list.description);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(preferenceListControllerProvider.notifier).update(
            widget.list.copyWith(
              title: title,
              description: _description.text.trim(),
            ),
          );
      if (!mounted) return;
      final message = AppLocalizations.of(context).prefListUpdated;
      Navigator.pop(context);
      showAppSnackBar(context, message: message, isSuccess: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tutamak temadan geliyor (`showDragHandle: true`); elle bir tane
          // daha koyulursa iki çubuk üst üste görünüyor.
          const SizedBox(height: 8),
          Text(
            loc.prefListRenameTitle,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          SheetFormField(
            controller: _title,
            label: loc.prefListTitleLabel,
            hintText: loc.prefListTitleHint,
            autofocus: true,
            maxLength: 80,
            emphasized: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 14),
          SheetFormField(
            controller: _description,
            label: loc.prefListDescriptionLabel,
            hintText: loc.prefListDescriptionHint,
            maxLength: 200,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      loc.commonSave,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
