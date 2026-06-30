import 'package:flutter/material.dart';

/// ÜniSeç uygulama renk paleti
/// Tüm renkler merkezi olarak buradan yönetilir.
class AppColors {
  AppColors._();

  // ─── Primary Colors ───────────────────────────────────────────────
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF4A42DB);

  // ─── Secondary Colors ─────────────────────────────────────────────
  static const Color secondary = Color(0xFFFF6584);
  static const Color secondaryLight = Color(0xFFFF8FA5);
  static const Color secondaryDark = Color(0xFFD94564);

  // ─── Accent Colors ────────────────────────────────────────────────
  static const Color accent = Color(0xFF00D9FF);
  static const Color accentLight = Color(0xFF66E8FF);
  static const Color accentDark = Color(0xFF00A8C6);

  // ─── Background Colors ────────────────────────────────────────────
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F1F5);

  // ─── Text Colors ──────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);

  // ─── Border & Divider ─────────────────────────────────────────────
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFE8E8E8);
  static const Color borderLight = Color(0xFFF3F4F6);

  // ─── Status Colors ────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ─── Rating Colors ────────────────────────────────────────────────
  static const Color ratingExcellent = Color(0xFF10B981);
  static const Color ratingGood = Color(0xFF34D399);
  static const Color ratingAverage = Color(0xFFF59E0B);
  static const Color ratingBelowAverage = Color(0xFFF97316);
  static const Color ratingPoor = Color(0xFFEF4444);
  static const Color ratingStar = Color(0xFFFFB800);

  // ─── Category Colors (Üniversite tipleri için) ────────────────────
  static const Color stateUni = Color(0xFF6C63FF);     // Devlet
  static const Color foundationUni = Color(0xFFFF6584); // Vakıf

  // ─── Shimmer Colors ───────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFFE8E8E8);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // ─── Gradients ────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF8B83FF)],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, Color(0xFFFF8FA5)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFF66E8FF)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8F9FF), Color(0xFFFFF5F7)],
  );

  // ─── Shadows ──────────────────────────────────────────────────────
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x146C63FF), // primary alpha ~8%
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0A000000), // black ~4%
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> bottomNavShadow = [
    BoxShadow(
      color: Color(0x0F000000), // black ~6%
      blurRadius: 20,
      offset: Offset(0, -4),
      spreadRadius: 0,
    ),
  ];

  // ─── Subscription Tier Colors ──────────────────────────────────
  static const Color tierFree = Color(0xFF6B7280);     // Gri
  static const Color tierPlus = Color(0xFF6C63FF);     // Mor (primary ile aynı)
  static const Color tierPro = Color(0xFFD4A017);      // Altın

  static const LinearGradient tierPlusGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
  );

  static const LinearGradient tierProGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4A017), Color(0xFFFF8C00)],
  );

  static const Color lockOverlay = Color(0x88000000);

  // ─── Dark Mode Surfaces ────────────────────────────────────────
  /// Ana dark arka plan (Scaffold)
  static const Color darkBackground = Color(0xFF0F0F1A);
  /// Kart / container yüzeyi (dark)
  static const Color darkSurface = Color(0xFF1A1A2E);
  /// Alternatif surface — inputlar, iç içe kartlar (dark)
  static const Color darkSurfaceVariant = Color(0xFF141424);
  /// Elevated surface — modal, bottom sheet (dark)
  static const Color darkSurfaceElevated = Color(0xFF22223F);
  /// İkinci kademe elevated surface — iç kartlar, sekmeler (dark)
  static const Color darkSurface2 = Color(0xFF1F1F36);

  // ─── Dark Mode Overlays (Alpha) ────────────────────────────────
  static Color darkOverlay06 = Colors.white.withValues(alpha: 0.06);
  static Color darkOverlay10 = Colors.white.withValues(alpha: 0.10);
  static Color darkOverlay12 = Colors.white.withValues(alpha: 0.12);
  static Color darkOverlay22 = Colors.white.withValues(alpha: 0.22);
  static Color darkOverlay60 = Colors.white.withValues(alpha: 0.60);

  // ─── Shimmer Dark Variants ────────────────────────────────────
  static const Color shimmerBaseDark = Color(0xFF2A2A40);
  static const Color shimmerHighlightDark = Color(0xFF35355A);

  // ─── Brand Accents ─────────────────────────────────────────────
  static const Color gold = Color(0xFFD4A017);
  static const Color gradientPurple = Color(0xFF8B5CF6);
  static const Color gradientPink = Color(0xFFEC4899);
  static const Color gradientCyan = Color(0xFF06B6D4);

  // ─── AI Summary Gradient ───────────────────────────────────────
  static const LinearGradient aiSummaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold, gradientPurple],
  );

  static List<BoxShadow> aiSummaryShadow = [
    BoxShadow(
      color: gradientPurple.withValues(alpha: 0.25),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  // ─── Comparison Specific ───────────────────────────────────────
  static const Color winnerHighlight = Color(0xFF10B981);
  static const Color loserMuted = Color(0xFFD1D5DB);
  static const Color tieColor = Color(0xFFF59E0B);

  // ═══════════════════════════════════════════════════════════════
  //  Semantic Surface Helpers (Dark/Light Adaptive)
  // ═══════════════════════════════════════════════════════════════

  /// Tema duyarlı surface seçici — kart / container arka planları
  static Color surfaceFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : surface;
  }

  /// Tema duyarlı arka plan seçici — Scaffold / sayfa arka planı
  static Color backgroundFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : background;
  }

  /// Tema duyarlı metin rengi — surface üzerindeki birincil metin
  static Color textOnSurfaceFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.92)
        : textPrimary;
  }

  /// Tema duyarlı divider rengi
  static Color dividerFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : divider;
  }

  /// Tema duyarlı border rengi
  static Color borderFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.12)
        : border;
  }

  /// Tema duyarlı shimmer base rengi — skeleton loading
  static Color shimmerBaseFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? shimmerBaseDark
        : shimmerBase;
  }

  /// Tema duyarlı shimmer highlight rengi — skeleton loading
  static Color shimmerHighlightFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? shimmerHighlightDark
        : shimmerHighlight;
  }

  /// Tema duyarlı birincil metin rengi
  static Color textPrimaryFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.92)
        : textPrimary;
  }

  /// Tema duyarlı ikincil metin rengi
  static Color textSecondaryFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.60)
        : textSecondary;
  }

  /// Tema duyarlı üçüncül metin rengi
  static Color textTertiaryFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.38)
        : textTertiary;
  }

  /// Tema duyarlı surface variant rengi
  static Color surfaceVariantFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurfaceVariant
        : surfaceVariant;
  }

  /// Tema duyarlı border light rengi
  static Color borderLightFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.10)
        : borderLight;
  }

  /// Tema duyarlı kart gölgesi
  static List<BoxShadow> cardShadowFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const [] // Dark mode'da gölge yerine border kullanıyoruz
        : cardShadow;
  }

  /// Tema duyarlı hafif gölge
  static List<BoxShadow> softShadowFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const []
        : softShadow;
  }

  /// Tema duyarlı hero gradient.
  /// Açık temada canlı mor→pembe; karanlık temada bu tonun "gece" hâli:
  /// muddy bordo yerine bütünlüklü, derin indigo→menekşe (beyaz metinle
  /// yüksek kontrast, dark surface'le uyumlu).
  static LinearGradient heroGradientFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1B4B), Color(0xFF3B2F7A)],
          )
        : heroGradient;
  }

  /// Tema duyarlı kart gradient
  static LinearGradient cardGradientFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [darkSurface, darkSurfaceVariant],
          )
        : cardGradient;
  }

  /// Tema duyarlı bottom navigation gölgesi
  static List<BoxShadow> bottomNavShadowFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? [
            const BoxShadow(
              color: Color(0x33000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ]
        : bottomNavShadow;
  }

  /// isDark shorthand helper
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Rating değerine göre renk döndürür (1-5 arası)
  static Color ratingColor(double rating) {
    if (rating >= 4.5) return ratingExcellent;
    if (rating >= 3.5) return ratingGood;
    if (rating >= 2.5) return ratingAverage;
    if (rating >= 1.5) return ratingBelowAverage;
    return ratingPoor;
  }
}
