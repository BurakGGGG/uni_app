import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../places/domain/models/place_suggestion_model.dart';
import '../../../places/presentation/providers/place_suggestion_providers.dart';

/// Admin — Mekan Önerileri ekranı.
class AdminSuggestionsScreen extends ConsumerStatefulWidget {
  const AdminSuggestionsScreen({super.key});

  @override
  ConsumerState<AdminSuggestionsScreen> createState() =>
      _AdminSuggestionsScreenState();
}

class _AdminSuggestionsScreenState
    extends ConsumerState<AdminSuggestionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        title: Text(
          'Mekan Önerileri',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: AppColors.surfaceFor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryFor(context),
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            _buildTab('Bekleyen', SuggestionStatus.pending),
            const Tab(text: 'Onaylanan'),
            const Tab(text: 'Reddedilen'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SuggestionList(status: SuggestionStatus.pending, showActions: true),
          _SuggestionList(status: SuggestionStatus.approved, showActions: false),
          _SuggestionList(status: SuggestionStatus.rejected, showActions: false),
        ],
      ),
    );
  }

  Widget _buildTab(String label, SuggestionStatus status) {
    final countAsync = ref.watch(pendingSuggestionCountProvider);
    final count = countAsync.valueOrNull ?? 0;
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestionList extends ConsumerWidget {
  final SuggestionStatus status;
  final bool showActions;

  const _SuggestionList({
    required this.status,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(suggestionsProvider(status));

    return suggestionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorStateWidget(
        message: 'Öneriler yüklenemedi',
        onRetry: () => ref.invalidate(suggestionsProvider(status)),
        compact: true,
      ),
      data: (suggestions) {
        if (suggestions.isEmpty) {
          return Center(
            child: EmptyState(
              icon: Icons.inbox_rounded,
              title: _emptyTitle(status),
              message: _emptyMessage(status),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _SuggestionCard(
              suggestion: suggestions[index],
              showActions: showActions,
            );
          },
        );
      },
    );
  }

  String _emptyTitle(SuggestionStatus s) {
    switch (s) {
      case SuggestionStatus.pending: return 'Bekleyen öneri yok';
      case SuggestionStatus.approved: return 'Onaylanan öneri yok';
      case SuggestionStatus.rejected: return 'Reddedilen öneri yok';
    }
  }

  String _emptyMessage(SuggestionStatus s) {
    switch (s) {
      case SuggestionStatus.pending: return 'Tüm öneriler işlenmiş görünüyor.';
      case SuggestionStatus.approved: return 'Henüz onaylanan bir öneri yok.';
      case SuggestionStatus.rejected: return 'Henüz reddedilen bir öneri yok.';
    }
  }
}

class _SuggestionCard extends ConsumerWidget {
  final PlaceSuggestionModel suggestion;
  final bool showActions;

  const _SuggestionCard({
    required this.suggestion,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = suggestion.type;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightFor(context)),
        boxShadow: AppColors.softShadowFor(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Fotoğraflar ───────────────────────────────────
          if (suggestion.photoUrls.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestion.photoUrls.length,
                  itemBuilder: (context, i) {
                    return AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Image.network(
                        suggestion.photoUrls[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.borderLightFor(context),
                          child: const Icon(Icons.broken_image_rounded, size: 40),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Başlık + Tür ──────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(type.icon, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion.name,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            type.label,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Durum rozeti
                    _StatusBadge(status: suggestion.status),
                  ],
                ),

                // ─── Meta bilgiler ─────────────────────────────
                const SizedBox(height: 12),
                _MetaRow(
                  icon: Icons.school_rounded,
                  text: suggestion.universityName,
                ),
                if (suggestion.address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _MetaRow(
                    icon: Icons.location_on_rounded,
                    text: suggestion.address,
                  ),
                ],
                const SizedBox(height: 6),
                _MetaRow(
                  icon: Icons.person_rounded,
                  text: suggestion.userName,
                ),
                const SizedBox(height: 6),
                _MetaRow(
                  icon: Icons.access_time_rounded,
                  text: _formatDate(suggestion.createdAt),
                ),

                // ─── Açıklama ──────────────────────────────────
                if (suggestion.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundFor(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      suggestion.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryFor(context),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],

                // ─── Admin notu ────────────────────────────────
                if (suggestion.adminNote != null &&
                    suggestion.adminNote!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.note_rounded,
                            size: 16, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            suggestion.adminNote!,
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ─── Aksiyon butonları ─────────────────────────
                if (showActions) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRejectDialog(context, ref),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Reddet'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () => _showApproveDialog(context, ref),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Onayla & Ekle'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context, WidgetRef ref) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Öneriyi Onayla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '"${suggestion.name}" mekanı onaylanacak ve places koleksiyonuna eklenecek.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Admin notu (opsiyonel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final admin = ref.read(authStateProvider).value;
              if (admin == null) return;

              final repo = ref.read(placeSuggestionRepositoryProvider);
              await repo.approveSuggestion(
                suggestionId: suggestion.id,
                adminUserId: admin.uid,
                adminNote: noteController.text.trim().isNotEmpty
                    ? noteController.text.trim()
                    : null,
              );
              // Onaylanan öneriyi mekan olarak ekle
              await repo.convertToPlace(suggestion);
              // Listeyi yenile
              ref.invalidate(suggestionsProvider(SuggestionStatus.pending));
              ref.invalidate(suggestionsProvider(SuggestionStatus.approved));
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Öneriyi Reddet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '"${suggestion.name}" mekanı reddedilecek.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Ret sebebi (opsiyonel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final admin = ref.read(authStateProvider).value;
              if (admin == null) return;

              await ref.read(placeSuggestionRepositoryProvider).rejectSuggestion(
                    suggestionId: suggestion.id,
                    adminUserId: admin.uid,
                    adminNote: noteController.text.trim().isNotEmpty
                        ? noteController.text.trim()
                        : null,
                  );
              ref.invalidate(suggestionsProvider(SuggestionStatus.pending));
              ref.invalidate(suggestionsProvider(SuggestionStatus.rejected));
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final SuggestionStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      SuggestionStatus.pending => (
          AppColors.warning.withValues(alpha: 0.12),
          AppColors.warning,
        ),
      SuggestionStatus.approved => (
          AppColors.success.withValues(alpha: 0.12),
          AppColors.success,
        ),
      SuggestionStatus.rejected => (
          AppColors.error.withValues(alpha: 0.12),
          AppColors.error,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiaryFor(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
