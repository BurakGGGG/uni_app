import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../assistant/presentation/widgets/robot_avatar.dart';
import '../../../preference_wizard/presentation/providers/preference_wizard_providers.dart';
import '../providers/preference_list_providers.dart';
import 'sheet_form_field.dart';

/// Yeni tercih listesi kurma sheet'i.
///
/// Ekranın tek işi bir AD almak; gerisi opsiyonel. Bu yüzden ad alanı
/// büyük ve odaklı, açıklama ile görünürlük altta sessiz duruyor.
class CreateListSheet {
  static Future<void> show(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _Body(parentRef: ref),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  final WidgetRef parentRef;
  const _Body({required this.parentRef});

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isPublic = false;
  bool _busy = false;
  String? _err;

  static const int _titleMax = 60;

  @override
  void initState() {
    super.initState();
    // Buton yalnız ad girilince açılır; her tuşta yeniden çizmek gerekiyor.
    _titleCtrl.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_onTitleChanged);
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    setState(() {
      if (_err != null) _err = null;
    });
  }

  bool get _canCreate => _titleCtrl.text.trim().isNotEmpty && !_busy;

  void _useIdea(String name) {
    _titleCtrl
      ..text = name
      ..selection = TextSelection.collapsed(offset: name.length);
  }

  /// Hazır adlar. Puan türü biliniyorsa ilk öneri kişiselleşir ("SAY Planım")
  /// — boş bir metin kutusuna bakan öğrencinin ilk engeli ad bulmak.
  List<String> _ideas(AppLocalizations loc) {
    final type = ref.read(studentScoreProfileProvider)?.scoreType;
    return [
      if (type != null && type.isNotEmpty)
        loc.prefListNameIdeaTyped(type)
      else
        loc.prefListNameIdeaMain,
      loc.prefListNameIdeaBackup,
      loc.prefListNameIdeaDream,
    ];
  }

  Future<void> _create() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      final list = await widget.parentRef
          .read(preferenceListControllerProvider.notifier)
          .create(
            title: title,
            description: _descCtrl.text.trim(),
            isPublic: _isPublic,
          );
      if (!mounted) return;
      Navigator.pop(context);
      if (list != null) {
        context.push('/my-lists/${list.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _err = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final length = _titleCtrl.text.characters.length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tutamak çizilmiyor: `bottomSheetTheme.showDragHandle` açık,
            // elle bir tane daha koyulursa üst üste İKİ çubuk görünüyor.
            const SizedBox(height: 8),

            // Üni açar: tercih listesi yüzeylerinin hepsi onun ağzından
            // konuşuyor, kuruluş anı da öyle olsun.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RobotAvatar(size: 40, animated: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.prefListCreateTitle,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loc.prefListCreateSubtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryFor(context),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            SheetFormField(
              controller: _titleCtrl,
              label: loc.prefListTitleLabel,
              hintText: loc.prefListTitleHint,
              autofocus: true,
              maxLength: _titleMax,
              emphasized: true,
              textCapitalization: TextCapitalization.sentences,
              // Sayaç yalnız sınıra yaklaşınca: sürekli görünürse gürültü.
              counter: length > _titleMax - 15 ? '$length/$_titleMax' : null,
            ),
            const SizedBox(height: 12),

            _IdeaRow(
              label: loc.prefListNameIdeasLabel,
              ideas: _ideas(loc),
              selected: _titleCtrl.text.trim(),
              onPick: _useIdea,
            ),
            const SizedBox(height: 18),

            SheetFormField(
              controller: _descCtrl,
              label: loc.prefListDescriptionLabel,
              hintText: loc.prefListDescriptionHint,
              maxLength: 140,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            _PublicRow(
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
            ),

            if (_err != null) ...[
              const SizedBox(height: 14),
              _ErrorBox(message: _err!),
            ],

            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _canCreate ? _create : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        loc.prefListCreateButton,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tek dokunuşla ad dolduran öneri çipleri.
class _IdeaRow extends StatelessWidget {
  final String label;
  final List<String> ideas;
  final String selected;
  final ValueChanged<String> onPick;

  const _IdeaRow({
    required this.label,
    required this.ideas,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiaryFor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final idea in ideas) ...[
                  _IdeaChip(
                    text: idea,
                    active: idea == selected,
                    onTap: () => onPick(idea),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IdeaChip extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;

  const _IdeaChip({
    required this.text,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? AppColors.primary
          : AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          child: Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: active ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Görünürlük satırı — kurulum anında ikincil bilgi, bu yüzden sessiz.
class _PublicRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PublicRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Material(
      color: AppColors.surfaceVariantFor(context).withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Icon(
                value ? Icons.public_rounded : Icons.lock_outline_rounded,
                size: 20,
                color: value
                    ? AppColors.primary
                    : AppColors.textTertiaryFor(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.prefListPublicTitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      loc.prefListPublicCreateSubtitle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondaryFor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
