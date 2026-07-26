import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/compare_view.dart';
import 'compare_group_card.dart';
import 'compare_highlights_card.dart';
import 'compare_more_section.dart';
import 'compare_side_strip.dart';
import 'compare_verdict_card.dart';

/// Üç karşılaştırma ekranının ORTAK iskeleti (kullanıcı kararı).
///
/// Sıra sabit: yapışık taraf şeridi → fark özeti → senin için → en büyük
/// farklar → (kapalı) tam ölçüt tabloları → (kapalı) daha fazlası.
/// Üniversite, bölüm ve şehir aynı sırayı kullanıyor.
///
/// **Sekme yok** (kullanıcı kararı): bir karşılaştırmanın cevabı tek soru
/// — hangisi, neden. Beş sekme o cevabı beş parçaya bölüyordu.
///
/// **Ekran kısa** (kullanıcı geri bildirimi, ikinci tur): sekmeler kalkınca
/// her şey tek uzun kaydırma olmuştu. Açılışta yalnız farkı büyük ölçütler
/// duruyor; tam tablolar ve ek bloklar kapalı geliyor.
class CompareLayout extends StatelessWidget {
  final ComparisonView view;

  /// Bir tarafı değiştirme; null ise şerit dokunulamaz olur.
  final ValueChanged<int>? onChangeSide;
  final VoidCallback? onSwap;

  /// Şerittteki taraf görseli; verilmezse üniversite logosuna düşer.
  final Widget Function(int index, CompareSide side)? leadingBuilder;

  /// Fark özetinin hemen altındaki kişisel blok ("Senin için").
  final Widget? personal;

  /// "Daha fazlası" altında toplanan bloklar — grafik köprüsü, Pro özet,
  /// notlar.
  final List<Widget> extras;

  /// Şeridin altında duran uyarı (ör. puan türü uyuşmazlığı).
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
    final hasRows = view.allRows.isNotEmpty;
    final highlights = view.highlights();

    final content = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Şerit yapışık (kullanıcı kararı): kaydırınca kaybolunca
        // aşağıdaki sayıların hangisinin kime ait olduğu belirsizleşiyordu.
        SliverPersistentHeader(
          pinned: true,
          delegate: _StripHeader(
            child: CompareSideStrip(
              sides: view.sides,
              onChange: onChangeSide,
              onSwap: onSwap,
              leadingBuilder: leadingBuilder,
            ),
          ),
        ),
        SliverPadding(
          // Alttaki 40: son kartın ekranın dibine yapışmaması için.
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          sliver: SliverList.list(
            children: [
              if (banner != null) ...[banner!, const SizedBox(height: 12)],
              if (hasRows)
                CompareVerdictCard(view: view)
              else
                _NoRows(message: loc.cmpNoRows),
              if (personal != null) ...[const SizedBox(height: 12), personal!],
              if (highlights.isNotEmpty) ...[
                const SizedBox(height: 12),
                CompareHighlightsCard(rows: highlights)
                    .animate()
                    .fadeIn(duration: 260.ms)
                    .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
              ],
              for (final group in view.groups) ...[
                const SizedBox(height: 12),
                CompareGroupCard(group: group),
              ],
              if (extras.isNotEmpty) ...[
                const SizedBox(height: 12),
                CompareMoreSection(children: extras),
              ],
            ],
          ),
        ),
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

/// Sabit yükseklikli yapışık başlık — şeridin kendi boyu `height`'ta.
class _StripHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _StripHeader({required this.child});

  @override
  double get minExtent => CompareSideStrip.height;

  @override
  double get maxExtent => CompareSideStrip.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      child;

  @override
  bool shouldRebuild(_StripHeader oldDelegate) => oldDelegate.child != child;
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
