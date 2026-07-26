import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/compare_view.dart';
import 'compare_group_card.dart';
import 'compare_side_strip.dart';
import 'compare_verdict_card.dart';

/// Üç karşılaştırma ekranının ORTAK iskeleti (kullanıcı kararı).
///
/// Sıra sabit: taraf şeridi → fark özeti → senin için → ölçüt grupları →
/// ek bloklar. Üniversite, bölüm ve şehir aynı sırayı kullanıyor; biri
/// düzeltilince öbürü geride kalmıyor.
///
/// **Sekme yok** (kullanıcı kararı): bir karşılaştırmanın cevabı tek soru
/// — hangisi, neden. Beş sekme o cevabı beş parçaya bölüyordu.
class CompareLayout extends StatelessWidget {
  final ComparisonView view;

  /// Bir tarafı değiştirme; null ise şerit dokunulamaz olur.
  final ValueChanged<int>? onChangeSide;
  final VoidCallback? onSwap;

  /// Şerittteki taraf görseli; verilmezse üniversite logosuna düşer.
  final Widget Function(int index, CompareSide side)? leadingBuilder;

  /// Fark özetinin hemen altındaki kişisel blok ("Senin için").
  final Widget? personal;

  /// Ölçütlerden sonra gelen bloklar — grafik köprüsü, notlar, uyarılar.
  final List<Widget> extras;

  /// Şeridin üstünde duran uyarı (ör. puan türü uyuşmazlığı).
  final Widget? banner;

  final Future<void> Function()? onRefresh;

  const CompareLayout({
    super.key,
    required this.view,
    this.onChangeSide,
    this.onSwap,
    this.leadingBuilder,
    this.personal,
    this.extras = const [],
    this.banner,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final groups = view.groups;
    final hasRows = view.allRows.isNotEmpty;

    final content = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      // Alttaki 40: son kartın ekranın dibine yapışmaması için.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        if (banner != null) ...[banner!, const SizedBox(height: 12)],
        CompareSideStrip(
          sides: view.sides,
          onChange: onChangeSide,
          onSwap: onSwap,
          leadingBuilder: leadingBuilder,
        ),
        const SizedBox(height: 12),
        if (hasRows)
          CompareVerdictCard(view: view)
        else
          _NoRows(message: loc.cmpNoRows),
        if (personal != null) ...[const SizedBox(height: 12), personal!],
        for (var i = 0; i < groups.length; i++) ...[
          const SizedBox(height: 12),
          CompareGroupCard(group: groups[i])
              .animate()
              .fadeIn(delay: Duration(milliseconds: 60 * i), duration: 260.ms)
              .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
        ],
        for (final extra in extras) ...[const SizedBox(height: 12), extra],
      ],
    );

    if (onRefresh == null) return content;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh!,
      child: content,
    );
  }
}

class _NoRows extends StatelessWidget {
  final String message;
  const _NoRows({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondaryFor(context),
          height: 1.4,
        ),
      ),
    );
  }
}
