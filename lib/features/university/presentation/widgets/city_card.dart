import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/city_browse.dart';
import '../../domain/models/city_model.dart';
import 'city_logo.dart';

enum _CityCardVariant { compact, tile }

class CityCard extends StatelessWidget {
  final CityModel city;
  final VoidCallback onTap;
  final _CityCardVariant _variant;

  const CityCard.compact({
    super.key,
    required this.city,
    required this.onTap,
  }) : _variant = _CityCardVariant.compact;

  const CityCard.tile({
    super.key,
    required this.city,
    required this.onTap,
  }) : _variant = _CityCardVariant.tile;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: switch (_variant) {
        _CityCardVariant.compact => _buildCompact(context),
        _CityCardVariant.tile => _buildTile(context),
      },
    );
  }

  // ─── Compact (Ana sayfa horizontal scroll için) ────────────
  Widget _buildCompact(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLightFor(context)),
        boxShadow: AppColors.softShadowFor(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Left edge accent
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: Container(color: city.brandPrimary),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceFor(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLightFor(context)),
                      ),
                      child: CityLogo(city: city, size: 36, withBackground: false),
                    ),
                    _PlateBadge(plate: city.plateCode, color: city.brandPrimary),
                  ],
                ),
                const Spacer(),
                Text(
                  city.name,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: city.brandPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school_rounded, size: 10, color: city.brandPrimary),
                      const SizedBox(width: 4),
                      Text(
                        '${city.appUniversityCount} üni',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: city.brandPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tile (AllCitiesScreen grid için) ──────────────────────
  //
  // Eski kart plakayı iki kez gösteriyordu: bir rozet olarak, bir de
  // "logo" diye — `CityLogo` zaten plaka kodunu yazan bir daire. Bir tanesi
  // kaldı ve boşalan yere şehri gerçekten ayırt eden şeyler kondu: bölge ve
  // nüfus.
  Widget _buildTile(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final region = regionOf(city);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLightFor(context)),
        boxShadow: AppColors.softShadowFor(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 72,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Marka bandı. Dekoratif daire kendi ClipRect'i içinde —
                // yoksa gövdeye taşıyor.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 52,
                  child: ClipRect(
                    child: DecoratedBox(
                      decoration: BoxDecoration(gradient: city.brandGradient),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -22,
                            top: -30,
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 0,
                  child: _PlateMedal(
                    plate: city.plateCode,
                    color: city.brandPrimary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city.name,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (region != null)
                    Text(
                      regionName(region, loc),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiaryFor(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const Spacer(),
                  Row(
                    children: [
                      Flexible(
                        child: _MetaChip(
                          icon: Icons.school_rounded,
                          label: loc.citiesUniShort('${city.appUniversityCount}'),
                          color: city.brandPrimary,
                          filled: true,
                        ),
                      ),
                      if (city.population != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: _MetaChip(
                            icon: Icons.groups_rounded,
                            label: AppFormatters.compactNumber(city.population),
                            color: AppColors.textSecondaryFor(context),
                            semantics:
                                loc.citiesPopulationLabel(
                                  AppFormatters.integer(city.population),
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Izgaranın satır yüksekliği. `childAspectRatio` yerine bu kullanılıyor:
  /// oran sabitlenirse yazı ölçeği büyüyen cihazlarda kart taşıyor.
  static double tileExtent(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    return 108 + 58 * scale;
  }
}

/// Plakanın tek görünümü — bandın alt kenarına oturan madalya.
class _PlateMedal extends StatelessWidget {
  final String plate;
  final Color color;

  const _PlateMedal({required this.plate, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLightFor(context)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        plate,
        style: AppTextStyles.titleMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final String? semantics;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
    this.filled = false,
    this.semantics,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semantics,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: filled ? 7 : 0, vertical: 4),
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Yardımcı: Plaka kodu chip'i ────────────────────────────
class _PlateBadge extends StatelessWidget {
  final String plate;
  final Color color;

  const _PlateBadge({required this.plate, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        plate,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.5,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
