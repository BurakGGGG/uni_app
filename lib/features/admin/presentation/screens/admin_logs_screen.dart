import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/admin_log_model.dart';
import '../providers/admin_logs_providers.dart';

class AdminLogsScreen extends ConsumerStatefulWidget {
  const AdminLogsScreen({super.key});

  @override
  ConsumerState<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends ConsumerState<AdminLogsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';
  String? _auditActionFilter;
  String? _suspiciousTypeFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auditAsync = ref.watch(adminAuditLogsProvider);
    final suspiciousAsync = ref.watch(suspiciousActivityLogsProvider);
    final auditCount = auditAsync.valueOrNull?.length ?? 0;
    final suspiciousCount = suspiciousAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        title: Text(
          'Güvenlik Logları',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: AppColors.surfaceFor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryFor(context),
          labelStyle: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
          tabs: [
            _CountTab(label: 'Admin Audit', count: auditCount),
            _CountTab(label: 'Şüpheli Aktivite', count: suspiciousCount),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'UID, aksiyon, hedef veya metadata ara',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Temizle',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _searchController.clear,
                      ),
                filled: true,
                fillColor: AppColors.surfaceFor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.borderLightFor(context),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.borderLightFor(context),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                auditAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _ErrorState(message: e.toString()),
                  data: _buildAuditTab,
                ),
                suspiciousAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _ErrorState(message: e.toString()),
                  data: _buildSuspiciousTab,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTab(List<AdminAuditLogModel> logs) {
    final filtered = logs
        .where(
          (log) =>
              _auditActionFilter == null || log.action == _auditActionFilter,
        )
        .where((log) => log.matches(_query))
        .toList();
    final actions = logs.map((log) => log.action).toSet().toList()..sort();

    return _LogListScaffold(
      filters: _FilterBar(
        allLabel: 'Tüm aksiyonlar',
        values: actions,
        selected: _auditActionFilter,
        labelFor: (value) =>
            logs.firstWhere((log) => log.action == value).actionLabel,
        onSelected: (value) => setState(() => _auditActionFilter = value),
      ),
      child: filtered.isEmpty
          ? const _EmptyState(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Audit log bulunamadı',
              subtitle:
                  'Filtreyi temizleyin veya yeni admin aksiyonu bekleyin.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _AuditLogTile(log: filtered[index]);
              },
            ),
    );
  }

  Widget _buildSuspiciousTab(List<SuspiciousActivityLogModel> logs) {
    final filtered = logs
        .where(
          (log) =>
              _suspiciousTypeFilter == null ||
              log.type == _suspiciousTypeFilter,
        )
        .where((log) => log.matches(_query))
        .toList();
    final types = logs.map((log) => log.type).toSet().toList()..sort();

    return _LogListScaffold(
      filters: _FilterBar(
        allLabel: 'Tüm olaylar',
        values: types,
        selected: _suspiciousTypeFilter,
        labelFor: (value) =>
            logs.firstWhere((log) => log.type == value).typeLabel,
        onSelected: (value) => setState(() => _suspiciousTypeFilter = value),
      ),
      child: filtered.isEmpty
          ? const _EmptyState(
              icon: Icons.security_rounded,
              title: 'Şüpheli aktivite bulunamadı',
              subtitle:
                  'Filtreyi temizleyin veya yeni güvenlik olayı bekleyin.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _SuspiciousLogTile(log: filtered[index]);
              },
            ),
    );
  }
}

class _CountTab extends StatelessWidget {
  final String label;
  final int count;

  const _CountTab({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return Tab(text: label);
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogListScaffold extends StatelessWidget {
  final Widget filters;
  final Widget child;

  const _LogListScaffold({required this.filters, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        filters,
        Expanded(child: child),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String allLabel;
  final List<String> values;
  final String? selected;
  final String Function(String value) labelFor;
  final ValueChanged<String?> onSelected;

  const _FilterBar({
    required this.allLabel,
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: values.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final value = index == 0 ? null : values[index - 1];
          final isSelected = selected == value;
          return ChoiceChip(
            label: Text(value == null ? allLabel : labelFor(value)),
            selected: isSelected,
            onSelected: (_) => onSelected(value),
            selectedColor: AppColors.primary.withValues(alpha: 0.16),
            labelStyle: AppTextStyles.labelMedium.copyWith(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondaryFor(context),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            side: BorderSide(color: AppColors.borderLightFor(context)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          );
        },
      ),
    );
  }
}

class _AuditLogTile extends StatelessWidget {
  final AdminAuditLogModel log;

  const _AuditLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final color = log.isDestructive ? AppColors.error : AppColors.info;
    return Material(
      color: AppColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLightFor(context)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LogIcon(icon: Icons.manage_accounts_rounded, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            log.actionLabel,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(log.createdAt),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textTertiaryFor(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MetaPill(label: log.targetLabel, value: log.targetId),
                        _MetaPill(label: 'Admin', value: log.actorUid),
                        if (log.status != null)
                          _MetaPill(label: 'Statü', value: log.status!),
                      ],
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

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceFor(context),
      builder: (context) => _DetailSheet(
        title: log.actionLabel,
        rows: {
          'Log ID': log.id,
          'Admin UID': log.actorUid,
          'Aksiyon': log.action,
          'Hedef': log.targetPath,
          if (log.reportId != null) 'Report ID': log.reportId!,
          if (log.reviewId != null) 'Review ID': log.reviewId!,
          if (log.feedbackId != null) 'Feedback ID': log.feedbackId!,
          if (log.reviewOwnerId != null) 'Review Owner': log.reviewOwnerId!,
          if (log.status != null) 'Statü': log.status!,
          'Admin notu var mı': log.adminNotePresent ? 'Evet' : 'Hayır',
          if (log.photoCount != null) 'Fotoğraf sayısı': '${log.photoCount}',
          'Tarih': _formatDate(log.createdAt),
        },
      ),
    );
  }
}

class _SuspiciousLogTile extends StatelessWidget {
  final SuspiciousActivityLogModel log;

  const _SuspiciousLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final color = switch (log.severity) {
      SuspiciousLogSeverity.high => AppColors.error,
      SuspiciousLogSeverity.warning => AppColors.warning,
      SuspiciousLogSeverity.info => AppColors.info,
    };

    return Material(
      color: AppColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLightFor(context)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LogIcon(icon: Icons.security_rounded, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            log.typeLabel,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(log.createdAt),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textTertiaryFor(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MetaPill(label: 'UID', value: log.uid),
                        _MetaPill(label: 'Kaynak', value: log.source),
                        _MetaPill(label: 'Seviye', value: log.severity.label),
                      ],
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

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceFor(context),
      builder: (context) => _DetailSheet(
        title: log.typeLabel,
        rows: {
          'Log ID': log.id,
          'UID': log.uid,
          'Tip': log.type,
          'Kaynak': log.source,
          'Seviye': log.severity.label,
          ...log.metadata.map(
            (key, value) => MapEntry('metadata.$key', '$value'),
          ),
          'Tarih': _formatDate(log.createdAt),
        },
      ),
    );
  }
}

class _LogIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _LogIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetaPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Text(
        '$label: ${value.isEmpty ? '-' : value}',
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondaryFor(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  final String title;
  final Map<String, String> rows;

  const _DetailSheet({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        shrinkWrap: true,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...rows.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textTertiaryFor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SelectableText(
                    entry.value.isEmpty ? '-' : entry.value,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textOnSurfaceFor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textTertiaryFor(context)),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year} '
      '${two(date.hour)}:${two(date.minute)}';
}
