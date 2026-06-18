import 'package:flutter/widgets.dart';

/// Responsive tasarım yardımcıları.
///
/// Breakpoint tanımları:
/// - **compact**  : < 600 dp  (telefon)
/// - **medium**   : 600–839 dp (küçük tablet / yatay telefon)
/// - **expanded** : 840–1199 dp (tablet)
/// - **large**    : ≥ 1200 dp (masaüstü / geniş tablet)
class Responsive {
  Responsive._();

  // ─── Breakpoints ────────────────────────────────────────────────
  static const double compactMax = 599;
  static const double mediumMin = 600;
  static const double mediumMax = 839;
  static const double expandedMin = 840;
  static const double expandedMax = 1199;
  static const double largeMin = 1200;

  // ─── Queries ────────────────────────────────────────────────────

  /// Cihaz genişliğini döner.
  static double width(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) => width(context) <= compactMax;
  static bool isMedium(BuildContext context) {
    final w = width(context);
    return w >= mediumMin && w <= mediumMax;
  }

  static bool isExpanded(BuildContext context) {
    final w = width(context);
    return w >= expandedMin && w <= expandedMax;
  }

  static bool isLarge(BuildContext context) => width(context) >= largeMin;

  /// "Telefon değilse" kontrolü (medium+).
  static bool isTabletOrLarger(BuildContext context) =>
      width(context) >= mediumMin;

  // ─── Grid Hesaplamaları ─────────────────────────────────────────

  /// Grid kolonları: compact=2, medium=3, expanded=4, large=5
  static int gridColumns(BuildContext context) {
    final w = width(context);
    if (w >= largeMin) return 5;
    if (w >= expandedMin) return 4;
    if (w >= mediumMin) return 3;
    return 2;
  }

  /// Galeri kolonları: compact=3, medium=4, expanded=5, large=6
  static int galleryColumns(BuildContext context) {
    final w = width(context);
    if (w >= largeMin) return 6;
    if (w >= expandedMin) return 5;
    if (w >= mediumMin) return 4;
    return 3;
  }

  // ─── Boyutlar ───────────────────────────────────────────────────

  /// Yatay kart genişliği: compact=160, medium+=220
  static double cardWidth(BuildContext context) =>
      isTabletOrLarger(context) ? 220 : 160;

  /// Yatay kart listesinin yüksekliği: compact=200, medium+=240
  static double cardListHeight(BuildContext context) =>
      isTabletOrLarger(context) ? 240 : 200;

  /// Hero banner minimum yüksekliği: compact=160, medium+=220
  static double heroBannerMinHeight(BuildContext context) =>
      isTabletOrLarger(context) ? 220 : 160;

  /// Horizontal padding: compact=16, medium=24, expanded+=32
  static double horizontalPadding(BuildContext context) {
    final w = width(context);
    if (w >= expandedMin) return 32;
    if (w >= mediumMin) return 24;
    return 16;
  }

  /// Sayfa kenar boşluğu EdgeInsets olarak.
  static EdgeInsets pagePadding(BuildContext context) =>
      EdgeInsets.symmetric(horizontal: horizontalPadding(context));

  /// Bottom sheet max width — tablette ortada durması için.
  static double bottomSheetMaxWidth(BuildContext context) =>
      isTabletOrLarger(context) ? 600 : double.infinity;

  /// Dialog/Form max width.
  static double formMaxWidth(BuildContext context) {
    final w = width(context);
    if (w >= largeMin) return 720;
    if (w >= expandedMin) return 640;
    if (w >= mediumMin) return 560;
    return double.infinity;
  }
}
