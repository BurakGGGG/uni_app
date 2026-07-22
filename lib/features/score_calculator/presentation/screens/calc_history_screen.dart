import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/score_calculator_providers.dart';
import '../widgets/score_type_card.dart';
import '../../domain/models/calc_history_entry.dart';

/// Deneme geçmişi: kayıtlı hesaplamalar, denemeler arası ilerleme deltaları,
/// yeniden adlandırma / netleri geri yükleme / silme.
class CalcHistoryScreen extends ConsumerWidget {
  const CalcHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(calcHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        title: const Text('Deneme Geçmişi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              tooltip: 'Tümünü sil',
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () => _confirmClearAll(context, ref),
            ),
        ],
      ),
      body: entries.isEmpty
          ? _EmptyState(onCalculate: () => Navigator.maybePop(context))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                // Liste en yeni başta; "önceki deneme" bir sonraki eleman.
                final previous =
                    index + 1 < entries.length ? entries[index + 1] : null;
                return _HistoryTile(entry: entry, previous: previous);
              },
            ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm geçmişi sil'),
        content:
            const Text('Kayıtlı tüm denemeler silinecek. Emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(calcHistoryProvider.notifier).clear();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends ConsumerWidget {
  final CalcHistoryEntry entry;
  final CalcHistoryEntry? previous;

  const _HistoryTile({required this.entry, this.previous});

  static String _formatDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netDelta = previous != null ? entry.totalNet - previous!.totalNet : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightFor(context)),
        boxShadow: AppColors.softShadowFor(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.label,
                      style: AppTextStyles.titleMedium
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatDate(entry.createdAt)} · ${entry.year} YKS · '
                      'Toplam ${entry.totalNet.toStringAsFixed(2).replaceAll('.', ',')} net',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondaryFor(context)),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    color: AppColors.textSecondaryFor(context)),
                onSelected: (action) => _handleAction(context, ref, action),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'rename',
                    child: Text('Yeniden Adlandır'),
                  ),
                  PopupMenuItem(
                    value: 'restore',
                    child: Text('Netleri Yükle'),
                  ),
                  PopupMenuItem(value: 'delete', child: Text('Sil')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in entry.results)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        scoreTypeColor(r.scoreType).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${r.scoreType} ${r.placementScore.toStringAsFixed(1).replaceAll('.', ',')}'
                    '${r.estimatedRank != null ? ' · ~${formatRank(r.estimatedRank!)}' : ''}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: scoreTypeColor(r.scoreType),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (netDelta != null && netDelta != 0) ...[
            const SizedBox(height: 10),
            _DeltaRow(entry: entry, previous: previous!, netDelta: netDelta),
          ],
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'rename':
        _showRenameDialog(context, ref);
        break;
      case 'restore':
        ref.read(scoreInputProvider.notifier).state = entry.input;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${entry.label} netleri yüklendi')),
        );
        Navigator.maybePop(context); // hesaplama ekranına dön
        break;
      case 'delete':
        ref.read(calcHistoryProvider.notifier).remove(entry.id);
        break;
    }
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: entry.label);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeniden Adlandır'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(hintText: 'Deneme adı'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () {
              final label = controller.text.trim();
              if (label.isNotEmpty) {
                ref.read(calcHistoryProvider.notifier).rename(entry.id, label);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

/// Önceki denemeye göre değişim satırı: toplam net + en iyi türün puanı.
class _DeltaRow extends StatelessWidget {
  final CalcHistoryEntry entry;
  final CalcHistoryEntry previous;
  final double netDelta;

  const _DeltaRow({
    required this.entry,
    required this.previous,
    required this.netDelta,
  });

  @override
  Widget build(BuildContext context) {
    final up = netDelta > 0;
    final color = up ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    // En iyi türün puan farkı (önceki denemede de aynı tür varsa).
    String? scorePart;
    final best = entry.best;
    if (best != null) {
      final prevSame = previous.byType(best.scoreType);
      if (prevSame != null) {
        final diff = best.placementScore - prevSame.placementScore;
        if (diff != 0) {
          scorePart =
              '${best.scoreType} ${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1).replaceAll('.', ',')} puan';
        }
      }
    }

    return Row(
      children: [
        Icon(up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Önceki denemeye göre ${netDelta > 0 ? '+' : ''}'
            '${netDelta.toStringAsFixed(2).replaceAll('.', ',')} net'
            '${scorePart != null ? ' · $scorePart' : ''}',
            style: AppTextStyles.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCalculate;
  const _EmptyState({required this.onCalculate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded,
                size: 64, color: AppColors.textTertiaryFor(context)),
            const SizedBox(height: 16),
            Text(
              'Henüz kayıtlı deneme yok',
              style:
                  AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Her hesaplama otomatik kaydedilir; netlerindeki gelişimi '
              'buradan izlersin.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondaryFor(context)),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCalculate,
              icon: const Icon(Icons.calculate_rounded, size: 18),
              label: const Text('Hesaplamaya Başla'),
            ),
          ],
        ),
      ),
    );
  }
}
