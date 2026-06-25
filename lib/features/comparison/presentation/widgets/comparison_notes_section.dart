import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptic.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/comparison_note.dart';
import '../providers/comparison_providers.dart';
import 'comparison_note_card.dart';
import 'comparison_note_bottom_sheet.dart';
import 'plus_lock_overlay.dart';

/// Karşılaştırma notları section widget'ı.
/// Plus/Pro kullanıcı: not listesi + "Not Ekle" butonu.
/// Free/misafir kullanıcı: PlusLockOverlay ile kilitli görünüm.
class ComparisonNotesSection extends ConsumerWidget {
  final String comparisonType;
  final String entityAId;
  final String entityBId;

  const ComparisonNotesSection({
    super.key,
    required this.comparisonType,
    required this.entityAId,
    required this.entityBId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canUse = ref.watch(canUseComparisonNotesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final loc = AppLocalizations.of(context);

    return PlusLockOverlay(
      isLocked: !canUse,
      featureName: loc.comparisonProNotesTitle,
      child: _NotesContent(
        comparisonType: comparisonType,
        entityAId: entityAId,
        entityBId: entityBId,
        isDark: isDark,
      ),
    );
  }
}

class _NotesContent extends ConsumerWidget {
  final String comparisonType;
  final String entityAId;
  final String entityBId;
  final bool isDark;

  const _NotesContent({
    required this.comparisonType,
    required this.entityAId,
    required this.entityBId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final notesAsync = ref.watch(comparisonNotesForPairProvider((
      type: comparisonType,
      idA: entityAId,
      idB: entityBId,
    )));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.borderLightFor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.tierPro.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.sticky_note_2_rounded,
                  color: AppColors.tierPro,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                loc.noteMyNotes,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimaryFor(context),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tierPro.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PRO',
                  style: TextStyle(
                    color: AppColors.tierPro,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ─── Content ──────────────────────────────────────
          notesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                loc.noteLoadError,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiaryFor(context),
                ),
              ),
            ),
            data: (notes) => _buildNotesList(context, ref, notes),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(
    BuildContext context,
    WidgetRef ref,
    List<ComparisonNote> notes,
  ) {
    final loc = AppLocalizations.of(context);
    return Column(
      children: [
        if (notes.isEmpty)
          _EmptyNotesState(isDark: isDark)
        else
          ...notes.map((note) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ComparisonNoteCard(
                  note: note,
                  onEdit: () => _editNote(context, ref, note),
                  onDelete: () => _confirmDelete(context, ref, note),
                ),
              )),
        const SizedBox(height: 8),

        // ─── Not Ekle Butonu ──────────────────────────────
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _addNote(context, ref),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(loc.noteAddTitle),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.tierPro,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(
                color: AppColors.tierPro.withValues(alpha: 0.3),
              ),
              textStyle: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final loc = AppLocalizations.of(context);
    final result = await ComparisonNoteBottomSheet.show(context);
    if (result == null) return;

    AppHaptic.noteSaved();
    await ref.read(comparisonNotesRepositoryProvider).addNote(
          comparisonType: comparisonType,
          entityAId: entityAId,
          entityBId: entityBId,
          note: result['note'] as String,
          pros: List<String>.from(result['pros'] as List? ?? []),
          cons: List<String>.from(result['cons'] as List? ?? []),
          rating: result['rating'] as int?,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(loc.noteSavedSnack),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ));
    }
  }

  Future<void> _editNote(
    BuildContext context,
    WidgetRef ref,
    ComparisonNote note,
  ) async {
    final loc = AppLocalizations.of(context);
    final result = await ComparisonNoteBottomSheet.show(
      context,
      existingNote: note,
    );
    if (result == null) return;

    AppHaptic.noteSaved();
    await ref.read(comparisonNotesRepositoryProvider).updateNote(
          noteId: note.id,
          note: result['note'] as String,
          pros: List<String>.from(result['pros'] as List? ?? []),
          cons: List<String>.from(result['cons'] as List? ?? []),
          rating: result['rating'] as int?,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(loc.noteUpdatedSnack),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ComparisonNote note,
  ) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: Icon(
          Icons.delete_outline_rounded,
          color: AppColors.error,
          size: 32,
        ),
        title: Text(
          loc.noteDeleteTitle,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          loc.noteDeleteConfirm,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondaryFor(context),
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              loc.commonCancel,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(loc.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    AppHaptic.noteDeleted();
    await ref.read(comparisonNotesRepositoryProvider).deleteNote(note.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(loc.noteDeletedSnack),
          backgroundColor: AppColors.textSecondaryFor(context),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ));
    }
  }
}

// ─── Empty State ────────────────────────────────────────────────────

class _EmptyNotesState extends StatelessWidget {
  final bool isDark;
  const _EmptyNotesState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Icon(
            Icons.sticky_note_2_outlined,
            size: 32,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            loc.noteEmptyState,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textTertiaryFor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc.noteEmptyStateDesc,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary.withValues(alpha: 0.7),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
