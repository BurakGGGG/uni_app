import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/comparison_result.dart';

/// Hero Section — İki üniversite logosu ortada VS badge'i ile
/// Büyük puan gösterimi + delta badge
class ComparisonHeroSection extends StatelessWidget {
  final ComparisonResult result;
  const ComparisonHeroSection({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkSurface, const Color(0xFF16213E)]
              : [
                  AppColors.primary.withValues(alpha: 0.04),
                  AppColors.secondary.withValues(alpha: 0.04),
                ],
        ),
      ),
      child: Column(
        children: [
          // ─── Logo + VS + Logo ──────────────────────────────
          Row(
            textDirection: Directionality.of(context),
            children: [
              Expanded(child: _UniLogo(
                uni: result.uniA,
                color: AppColors.primary,
                isWinner: result.overallWinnerId == result.uniA.id,
              )),
              _VsBadge(),
              Expanded(child: _UniLogo(
                uni: result.uniB,
                color: AppColors.secondary,
                isWinner: result.overallWinnerId == result.uniB.id,
              )),
            ],
          ),
          const SizedBox(height: 16),

          // ─── Büyük Skor Strip ──────────────────────────────
          _ScoreStrip(result: result, isDark: isDark),
          const SizedBox(height: 12),

          // ─── Özet text ─────────────────────────────────────
          Text(
            result.summaryText,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),

          // ─── Kategori kazanım sayıları ─────────────────────
          Row(
            textDirection: Directionality.of(context),
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _WinChip(
                label: '${result.categoriesAWins} kategori',
                color: AppColors.primary,
                name: result.uniA.name.split(' ').first,
              ),
              _WinChip(
                label: '${result.categoriesTied} berabere',
                color: AppColors.textTertiary,
                name: '',
              ),
              _WinChip(
                label: '${result.categoriesBWins} kategori',
                color: AppColors.secondary,
                name: result.uniB.name.split(' ').first,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Alt Widget'lar ────────────────────────────────────────────────

class _UniLogo extends StatelessWidget {
  final dynamic uni; // UniversityModel
  final Color color;
  final bool isWinner;

  const _UniLogo({
    required this.uni,
    required this.color,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        SizedBox(
          width: 76,
          height: 76,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Glow efekti
              if (isWinner)
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              // Glow efekti
              Hero(
                tag: 'uni_${uni.id}_compare',
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.95) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isWinner
                            ? color
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : AppColors.borderLight),
                        width: isWinner ? 2.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      uni.logoAssetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => _FallbackLogo(
                        name: uni.name,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
              // Winner badge — sağ alt köşede altın rozet
              if (isWinner)
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          uni.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  final String name;
  final Color color;
  const _FallbackLogo({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0] : '?',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 24,
        ),
      ),
    );
  }
}

class _VsBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        'VS',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 14,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _ScoreStrip extends StatelessWidget {
  final ComparisonResult result;
  final bool isDark;
  const _ScoreStrip({required this.result, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final delta = result.overallScoreDelta;
    final absDelta = delta.abs();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // A skoru
        _BigScore(
          score: result.uniA.avgRating,
          color: AppColors.primary,
          isWinner: result.overallWinnerId == result.uniA.id,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        // Delta badge
        Semantics(
          label: absDelta < 0.05
              ? 'Berabere'
              : delta > 0
                  ? '${result.uniA.name} ${absDelta.toStringAsFixed(1)} puan önde'
                  : '${result.uniB.name} ${absDelta.toStringAsFixed(1)} puan önde',
          child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: absDelta < 0.05
                ? AppColors.textTertiary.withValues(alpha: 0.1)
                : (delta > 0
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.secondary.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            absDelta < 0.05
                ? '='
                : (delta > 0
                    ? '◀ +${absDelta.toStringAsFixed(1)}'
                    : '+${absDelta.toStringAsFixed(1)} ▶'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: absDelta < 0.05
                  ? AppColors.textTertiary
                  : (delta > 0 ? AppColors.primary : AppColors.secondary),
            ),
          ),
        ),
        ),
        const SizedBox(width: 12),
        // B skoru
        _BigScore(
          score: result.uniB.avgRating,
          color: AppColors.secondary,
          isWinner: result.overallWinnerId == result.uniB.id,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _BigScore extends StatelessWidget {
  final double score;
  final Color color;
  final bool isWinner;
  final bool isDark;

  const _BigScore({
    required this.score,
    required this.color,
    required this.isWinner,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isWinner
            ? color.withValues(alpha: 0.12)
            : (isDark
                ? Colors.white.withValues(alpha: 0.04)
                : AppColors.surfaceVariant),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinner ? color.withValues(alpha: 0.4) : Colors.transparent,
          width: isWinner ? 2 : 0,
        ),
      ),
      child: Text(
        score > 0 ? score.toStringAsFixed(1) : '-',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _WinChip extends StatelessWidget {
  final String label;
  final Color color;
  final String name;
  const _WinChip({
    required this.label,
    required this.color,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (name.isNotEmpty)
          Text(name,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              )),
        Text(label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            )),
      ],
    );
  }
}
