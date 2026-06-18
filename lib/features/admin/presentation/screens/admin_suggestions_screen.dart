import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/models/admin_log_model.dart';
import '../providers/admin_logs_providers.dart';
import '../widgets/place_suggestion_approval_sheet.dart';
import '../../../places/domain/models/place_suggestion_model.dart';
import '../../../places/domain/models/place_model.dart';
import '../../../places/presentation/providers/place_suggestion_providers.dart';

enum _SuggestionSort { newest, oldest, completeness, duplicateRisk }

/// Admin — Mekan Önerileri ekranı.
class AdminSuggestionsScreen extends ConsumerStatefulWidget {
  const AdminSuggestionsScreen({super.key});

  @override
  ConsumerState<AdminSuggestionsScreen> createState() =>
      _AdminSuggestionsScreenState();
}

class _AdminSuggestionsScreenState extends ConsumerState<AdminSuggestionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  PlaceType? _typeFilter;
  String? _universityFilter;
  bool _duplicatesOnly = false;
  _SuggestionSort _sort = _SuggestionSort.newest;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
      body: Column(
        children: [
          _buildQueueControls(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSuggestionList(SuggestionStatus.pending, true),
                _buildSuggestionList(SuggestionStatus.approved, false),
                _buildSuggestionList(SuggestionStatus.rejected, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionList(SuggestionStatus status, bool showActions) {
    return _SuggestionList(
      status: status,
      showActions: showActions,
      query: _searchController.text,
      typeFilter: _typeFilter,
      universityFilter: _universityFilter,
      duplicatesOnly: _duplicatesOnly,
      sort: _sort,
    );
  }

  Widget _buildQueueControls(BuildContext context) {
    final allSuggestions =
        ref.watch(suggestionsProvider(null)).valueOrNull ?? [];
    final universities =
        allSuggestions
            .map((item) => item.universityName)
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return Container(
      color: AppColors.surfaceFor(context),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Mekan, kullanıcı veya adres ara',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Aramayı temizle',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                PopupMenuButton<String>(
                  tooltip: 'Mekan türü filtresi',
                  onSelected: (value) => setState(() {
                    _typeFilter = value == '__all__'
                        ? null
                        : PlaceType.fromString(value);
                  }),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: '__all__',
                      child: Text('Tüm türler'),
                    ),
                    ...PlaceType.values.map(
                      (type) => PopupMenuItem(
                        value: type.firestoreValue,
                        child: Text(type.label),
                      ),
                    ),
                  ],
                  child: _FilterChip(
                    icon: Icons.category_rounded,
                    label: _typeFilter?.label ?? 'Tür',
                    active: _typeFilter != null,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  tooltip: 'Üniversite filtresi',
                  onSelected: (value) => setState(() {
                    _universityFilter = value == '__all__' ? null : value;
                  }),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: '__all__',
                      child: Text('Tüm üniversiteler'),
                    ),
                    ...universities.map(
                      (name) => PopupMenuItem(value: name, child: Text(name)),
                    ),
                  ],
                  child: _FilterChip(
                    icon: Icons.school_rounded,
                    label: _universityFilter ?? 'Üniversite',
                    active: _universityFilter != null,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () =>
                      setState(() => _duplicatesOnly = !_duplicatesOnly),
                  borderRadius: BorderRadius.circular(8),
                  child: _FilterChip(
                    icon: Icons.content_copy_rounded,
                    label: 'Mükerrer risk',
                    active: _duplicatesOnly,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<_SuggestionSort>(
                  tooltip: 'Sıralama',
                  onSelected: (value) => setState(() => _sort = value),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: _SuggestionSort.newest,
                      child: Text('En yeni'),
                    ),
                    PopupMenuItem(
                      value: _SuggestionSort.oldest,
                      child: Text('En eski'),
                    ),
                    PopupMenuItem(
                      value: _SuggestionSort.completeness,
                      child: Text('En eksik önce'),
                    ),
                    PopupMenuItem(
                      value: _SuggestionSort.duplicateRisk,
                      child: Text('Mükerrer risk önce'),
                    ),
                  ],
                  child: _FilterChip(
                    icon: Icons.sort_rounded,
                    label: _sortLabel(_sort),
                    active: _sort != _SuggestionSort.newest,
                  ),
                ),
              ],
            ),
          ),
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

  String _sortLabel(_SuggestionSort sort) => switch (sort) {
    _SuggestionSort.newest => 'En yeni',
    _SuggestionSort.oldest => 'En eski',
    _SuggestionSort.completeness => 'Eksik önce',
    _SuggestionSort.duplicateRisk => 'Risk önce',
  };
}

class _SuggestionList extends ConsumerWidget {
  final SuggestionStatus status;
  final bool showActions;
  final String query;
  final PlaceType? typeFilter;
  final String? universityFilter;
  final bool duplicatesOnly;
  final _SuggestionSort sort;

  const _SuggestionList({
    required this.status,
    required this.showActions,
    required this.query,
    required this.typeFilter,
    required this.universityFilter,
    required this.duplicatesOnly,
    required this.sort,
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
        final filtered = suggestions.where((suggestion) {
          final normalizedQuery = query.trim().toLowerCase();
          final matchesQuery =
              normalizedQuery.isEmpty ||
              suggestion.name.toLowerCase().contains(normalizedQuery) ||
              suggestion.userName.toLowerCase().contains(normalizedQuery) ||
              suggestion.address.toLowerCase().contains(normalizedQuery) ||
              suggestion.universityName.toLowerCase().contains(normalizedQuery);
          return matchesQuery &&
              (typeFilter == null || suggestion.type == typeFilter) &&
              (universityFilter == null ||
                  suggestion.universityName == universityFilter) &&
              (!duplicatesOnly || suggestion.duplicateRiskCount > 0);
        }).toList();
        switch (sort) {
          case _SuggestionSort.newest:
            filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          case _SuggestionSort.oldest:
            filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          case _SuggestionSort.completeness:
            filtered.sort(
              (a, b) => a.completenessScore.compareTo(b.completenessScore),
            );
          case _SuggestionSort.duplicateRisk:
            filtered.sort(
              (a, b) => b.duplicateRiskCount.compareTo(a.duplicateRiskCount),
            );
        }

        if (filtered.isEmpty) {
          return Center(
            child: EmptyState(
              icon: Icons.inbox_rounded,
              title: suggestions.isEmpty
                  ? _emptyTitle(status)
                  : 'Filtreye uygun öneri yok',
              message: suggestions.isEmpty
                  ? _emptyMessage(status)
                  : 'Arama veya filtreleri değiştirerek tekrar dene.',
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _SuggestionCard(
              suggestion: filtered[index],
              showActions: showActions,
            );
          },
        );
      },
    );
  }

  String _emptyTitle(SuggestionStatus s) {
    switch (s) {
      case SuggestionStatus.pending:
        return 'Bekleyen öneri yok';
      case SuggestionStatus.approved:
        return 'Onaylanan öneri yok';
      case SuggestionStatus.rejected:
        return 'Reddedilen öneri yok';
    }
  }

  String _emptyMessage(SuggestionStatus s) {
    switch (s) {
      case SuggestionStatus.pending:
        return 'Tüm öneriler işlenmiş görünüyor.';
      case SuggestionStatus.approved:
        return 'Henüz onaylanan bir öneri yok.';
      case SuggestionStatus.rejected:
        return 'Henüz reddedilen bir öneri yok.';
    }
  }
}

class _SuggestionCard extends ConsumerWidget {
  final PlaceSuggestionModel suggestion;
  final bool showActions;

  const _SuggestionCard({required this.suggestion, required this.showActions});

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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
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
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.borderLightFor(context),
                          child: const Icon(
                            Icons.broken_image_rounded,
                            size: 40,
                          ),
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
                      child: Icon(
                        type.icon,
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
                _MetaRow(icon: Icons.person_rounded, text: suggestion.userName),
                const SizedBox(height: 6),
                _MetaRow(
                  icon: Icons.access_time_rounded,
                  text: _formatDate(suggestion.createdAt),
                ),
                if (suggestion.hasLocation) ...[
                  const SizedBox(height: 6),
                  _MetaRow(
                    icon: Icons.map_rounded,
                    text:
                        '${suggestion.latitude!.toStringAsFixed(5)}, '
                        '${suggestion.longitude!.toStringAsFixed(5)}',
                  ),
                ],
                if ((suggestion.openHours ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _MetaRow(
                    icon: Icons.schedule_rounded,
                    text: suggestion.openHours!,
                  ),
                ],
                if ((suggestion.phone ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _MetaRow(icon: Icons.phone_rounded, text: suggestion.phone!),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      icon: Icons.fact_check_rounded,
                      text: 'Tamlık %${suggestion.completenessScore}',
                      color: suggestion.completenessScore >= 80
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    if (suggestion.duplicateRiskCount > 0)
                      _InfoPill(
                        icon: Icons.content_copy_rounded,
                        text: '${suggestion.duplicateRiskCount} benzer kayıt',
                        color: AppColors.error,
                      ),
                    if (suggestion.priceRange != null)
                      _InfoPill(
                        icon: Icons.payments_rounded,
                        text: suggestion.priceRange!,
                        color: AppColors.primary,
                      ),
                  ],
                ),
                if (suggestion.missingQualityFields.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Eksik: ${suggestion.missingQualityFields.join(', ')}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ],
                if (suggestion.amenities.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    suggestion.amenities.join(' • '),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondaryFor(context),
                    ),
                  ),
                ],

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
                        const Icon(
                          Icons.note_rounded,
                          size: 16,
                          color: AppColors.warning,
                        ),
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (suggestion.duplicateRiskCount > 0)
                      TextButton.icon(
                        onPressed: () => _showDuplicates(context, ref),
                        icon: const Icon(Icons.content_copy_rounded, size: 18),
                        label: const Text('Benzerler'),
                      ),
                    TextButton.icon(
                      onPressed: () => _showHistory(context, ref),
                      icon: const Icon(Icons.history_rounded, size: 18),
                      label: const Text('Geçmiş'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showApproveDialog(BuildContext context, WidgetRef ref) async {
    final result = await PlaceSuggestionApprovalSheet.show(context, suggestion);
    if (result == null || !context.mounted) return;

    try {
      final repo = ref.read(placeSuggestionRepositoryProvider);
      await repo.approveSuggestion(
        suggestionId: suggestion.id,
        adminNote: result.adminNote,
        approvedPlace: result.approvedPlace,
      );
      ref.invalidate(suggestionsProvider(SuggestionStatus.pending));
      ref.invalidate(suggestionsProvider(SuggestionStatus.approved));
      ref.invalidate(suggestionsProvider(null));
      if (!context.mounted) return;
      _showActionMessage(context, 'Mekan önerisi onaylandı.');
    } catch (error) {
      if (!context.mounted) return;
      _showActionMessage(
        context,
        'Mekan önerisi onaylanamadı: $error',
        isError: true,
      );
    }
  }

  Future<void> _showHistory(BuildContext context, WidgetRef ref) async {
    try {
      final logs = await ref
          .read(adminLogsRepositoryProvider)
          .getAuditLogsForTarget(suggestion.id);
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) =>
            _SuggestionHistorySheet(logs: logs, suggestion: suggestion),
      );
    } catch (error) {
      if (!context.mounted) return;
      _showActionMessage(
        context,
        'İşlem geçmişi yüklenemedi: $error',
        isError: true,
      );
    }
  }

  Future<void> _showDuplicates(BuildContext context, WidgetRef ref) async {
    try {
      final candidates = await ref
          .read(placeSuggestionRepositoryProvider)
          .checkDuplicates(
            universityId: suggestion.universityId,
            name: suggestion.name,
            type: suggestion.type,
            latitude: suggestion.latitude,
            longitude: suggestion.longitude,
            excludeSuggestionId: suggestion.id,
          );
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => SafeArea(
          child: candidates.isEmpty
              ? const Padding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Text('Benzer mekan kaydı bulunamadı.'),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: candidates.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, index) {
                    final candidate = candidates[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        candidate.source == 'place'
                            ? Icons.place_rounded
                            : Icons.pending_actions_rounded,
                        color: AppColors.warning,
                      ),
                      title: Text(candidate.name),
                      subtitle: Text(
                        [
                          if (candidate.address.isNotEmpty) candidate.address,
                          if (candidate.distanceMeters != null)
                            '${candidate.distanceMeters!.round()} m',
                          candidate.source == 'place'
                              ? 'Kayıtlı mekan'
                              : 'Bekleyen öneri',
                        ].join(' • '),
                      ),
                    );
                  },
                ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      _showActionMessage(
        context,
        'Benzer mekanlar yüklenemedi: $error',
        isError: true,
      );
    }
  }

  Future<void> _showRejectDialog(BuildContext context, WidgetRef ref) async {
    final noteController = TextEditingController();

    final adminNote = await showDialog<String>(
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
            onPressed: () => Navigator.pop(ctx, noteController.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
    noteController.dispose();
    if (adminNote == null || !context.mounted) return;

    try {
      await ref
          .read(placeSuggestionRepositoryProvider)
          .rejectSuggestion(
            suggestionId: suggestion.id,
            adminNote: adminNote.isEmpty ? null : adminNote,
          );
      ref.invalidate(suggestionsProvider(SuggestionStatus.pending));
      ref.invalidate(suggestionsProvider(SuggestionStatus.rejected));
      ref.invalidate(suggestionsProvider(null));
      if (!context.mounted) return;
      _showActionMessage(context, 'Mekan önerisi reddedildi.');
    } catch (error) {
      if (!context.mounted) return;
      _showActionMessage(
        context,
        'Mekan önerisi reddedilemedi: $error',
        isError: true,
      );
    }
  }

  void _showActionMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
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

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.backgroundFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? AppColors.primary : AppColors.borderLightFor(context),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: active
                ? AppColors.primary
                : AppColors.textSecondaryFor(context),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: active
                    ? AppColors.primary
                    : AppColors.textPrimaryFor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionHistorySheet extends StatelessWidget {
  final List<AdminAuditLogModel> logs;
  final PlaceSuggestionModel suggestion;

  const _SuggestionHistorySheet({required this.logs, required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final itemCount = logs.length + 1;

    return SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const Divider(height: 24),
        itemBuilder: (context, index) {
          if (index == logs.length) {
            return _HistoryEntry(
              icon: Icons.send_rounded,
              title: 'Öneri gönderildi',
              detail: suggestion.userName,
              date: suggestion.createdAt,
            );
          }
          final log = logs[index];
          return _HistoryEntry(
            icon: Icons.admin_panel_settings_rounded,
            title: log.actionLabel,
            detail: [
              'Admin: ${log.actorUid}',
              if (log.changedFields.isNotEmpty)
                'Değişen: ${log.changedFields.join(', ')}',
            ].join('\n'),
            date: log.createdAt,
          );
        },
      ),
    );
  }

  static String _formatHistoryDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

class _HistoryEntry extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final DateTime date;

  const _HistoryEntry({
    required this.icon,
    required this.title,
    required this.detail,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(detail, style: AppTextStyles.labelSmall),
              const SizedBox(height: 4),
              Text(
                _SuggestionHistorySheet._formatHistoryDate(date),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiaryFor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
