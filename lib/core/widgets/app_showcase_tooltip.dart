import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:showcaseview/showcaseview.dart';
import '../theme/app_colors.dart';

/// Showcase turu için profesyonel, minimal tooltip widget'ı.
///
/// Özellikler:
/// - Temiz, modern tasarım (balon/ok yok)
/// - Adım göstergesi (1/7)
/// - "Devam etmek için dokun" ipucu
/// - Tooltip'e dokunulduğunda da sonraki adıma geçer
/// - Dark mode uyumlu
class AppShowcaseTooltip extends StatelessWidget {
  const AppShowcaseTooltip({
    super.key,
    required this.title,
    required this.description,
    required this.currentStep,
    required this.totalSteps,
  });

  final String title;
  final String description;
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return GestureDetector(
      onTap: () => ShowcaseView.getNamed('app_tour').next(),
      child: Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.primary.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Üst satır: Adım göstergesi ────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$currentStep/$totalSteps',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const Spacer(),
              // Adım çizgileri
              Row(
                children: List.generate(totalSteps, (i) {
                  final isActive = i < currentStep;
                  return Container(
                    width: isActive ? 16 : 8,
                    height: 3,
                    margin: const EdgeInsets.only(left: 3),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ─── Başlık ────────────────────────────────────────────
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              height: 1.3,
            ),
          ),

          const SizedBox(height: 6),

          // ─── Açıklama ──────────────────────────────────────────
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.65)
                  : const Color(0xFF64748B),
              height: 1.45,
            ),
          ),

          const SizedBox(height: 14),

          // ─── Alt ipucu ─────────────────────────────────────────
          Center(
            child: Text(
              'Devam etmek için dokun',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.25),
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
