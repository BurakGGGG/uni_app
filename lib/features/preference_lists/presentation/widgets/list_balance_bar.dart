import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../assistant/presentation/widgets/robot_avatar.dart';
import '../../../preference_wizard/domain/list_health.dart';
import '../../../score_calculator/domain/models/match_result.dart';
import '../../domain/list_overview.dart';
import '../../domain/models/preference_list_model.dart';

/// Kategori renkleri — uygulamadaki 🟢🟡🔴 dili tek yerden.
Color listBandColor(MatchCategory band) => switch (band) {
      MatchCategory.guaranteed => AppColors.success,
      MatchCategory.target => AppColors.warning,
      MatchCategory.dream => AppColors.error,
    };

String listBandLabel(AppLocalizations loc, MatchCategory band) =>
    switch (band) {
      MatchCategory.guaranteed => loc.prefListBandSafe,
      MatchCategory.target => loc.prefListBandTarget,
      MatchCategory.dream => loc.prefListBandReach,
    };

/// Listenin risk dengesi: tek satırlık renkli şerit + sayılar.
///
/// Doluluk çubuğundan AYRI bir bilgi: doluluk "kaç hakkını kullandın",
/// denge "kullandıklarının ne kadarı gerçekçi". İkisi üst üste konunca
/// liste bir bakışta okunuyor.
class ListBalanceBar extends StatelessWidget {
  final ListHealthReport report;

  /// Kompakt satırlarda etiketler düşer, yalnız şerit kalır.
  final bool showLabels;

  const ListBalanceBar({
    super.key,
    required this.report,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final segments = <(MatchCategory, int)>[
      (MatchCategory.guaranteed, report.guaranteed),
      (MatchCategory.target, report.target),
      (MatchCategory.dream, report.dream),
    ].where((s) => s.$2 > 0).toList();

    if (segments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                for (final (band, count) in segments)
                  Expanded(
                    flex: count,
                    child: Container(
                      margin: const EdgeInsets.only(right: 2),
                      color: listBandColor(band),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (showLabels) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final (band, count) in segments)
                _BandLabel(band: band, count: count),
              if (report.unrated > 0)
                Text(
                  AppLocalizations.of(context).prefListUnrated(report.unrated),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiaryFor(context),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BandLabel extends StatelessWidget {
  final MatchCategory band;
  final int count;

  const _BandLabel({required this.band, required this.count});

  @override
  Widget build(BuildContext context) {
    final color = listBandColor(band);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$count ${listBandLabel(AppLocalizations.of(context), band)}',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondaryFor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Puanı olmayan kullanıcıda dengenin yerine geçen davet.
///
/// Boş bir alan bırakmak yerine Üni'nin asıl işini öneriyor: puan olmadan
/// listenin gerçekçi olup olmadığı söylenemez.
class ListBalanceInvite extends StatelessWidget {
  final VoidCallback onTap;
  const ListBalanceInvite({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const RobotAvatar(size: 26, animated: false),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).prefListBalanceInvite,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Listedeki ilk üniversitelerin logoları — üst üste binmiş yığın.
///
/// Listenin içinde ne olduğunu okumadan gösterir; kart bir anda "canlı"
/// görünür. Logo yoksa üniversitenin baş harfi marka renginde gösterilir.
class ListLogoStack extends StatelessWidget {
  final ListOverview overview;
  final int max;
  final double size;

  const ListLogoStack({
    super.key,
    required this.overview,
    this.max = 5,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    final items = overview.topItems(max);
    if (items.isEmpty) return const SizedBox.shrink();
    final hidden = overview.filled - items.length;
    final overlap = size * 0.32;

    return Row(
      children: [
        SizedBox(
          height: size,
          width: size + (items.length - 1) * (size - overlap),
          child: Stack(
            children: [
              for (var i = items.length - 1; i >= 0; i--)
                Positioned(
                  left: i * (size - overlap),
                  child: _LogoBubble(item: items[i], size: size),
                ),
            ],
          ),
        ),
        if (hidden > 0) ...[
          const SizedBox(width: 8),
          Text(
            '+$hidden',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondaryFor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class _LogoBubble extends StatelessWidget {
  final PreferenceItem item;
  final double size;

  const _LogoBubble({required this.item, required this.size});

  @override
  Widget build(BuildContext context) {
    final brand = _brandColor(item.uniBrandHex) ?? AppColors.primary;
    final logo = item.uniLogoUrl;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surfaceFor(context), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipOval(
        child: logo == null || logo.isEmpty
            ? _initial(brand)
            : Image.asset(
                logo,
                fit: BoxFit.cover,
                // Varlık bulunamazsa (eski kayıt, yol değişmiş) kart
                // kırılmasın — baş harfe düş.
                errorBuilder: (_, _, _) => _initial(brand),
              ),
      ),
    );
  }

  Widget _initial(Color brand) {
    final name = item.uniName.trim();
    final letter = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
    return Container(
      color: brand.withValues(alpha: 0.14),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: AppTextStyles.labelMedium.copyWith(
          color: brand,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// `"#C00000"` → Color. Bozuk/eksik değerde null.
Color? _brandColor(String? hex) {
  if (hex == null) return null;
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length != 6) return null;
  final value = int.tryParse(cleaned, radix: 16);
  return value == null ? null : Color(0xFF000000 | value);
}
