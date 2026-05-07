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

  /// Rating değerine göre renk döndürür (1-5 arası)
  static Color ratingColor(double rating) {
    if (rating >= 4.5) return ratingExcellent;
    if (rating >= 3.5) return ratingGood;
    if (rating >= 2.5) return ratingAverage;
    if (rating >= 1.5) return ratingBelowAverage;
    return ratingPoor;
  }
}
