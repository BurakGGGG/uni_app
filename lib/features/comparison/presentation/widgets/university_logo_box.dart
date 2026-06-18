import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Reusable üniversite logosu kutusu.
/// İkili comparison hero section'da kullanılan stille tutarlı.
/// - Beyaz arka plan + padding (logo kırpılmaz, BoxFit.contain)
/// - Rounded square (yuvarlak değil — bazı dik logoların okunabilirliği için)
/// - Opsiyonel winner highlight (renkli border + glow)
/// - Asset bulunamazsa fallback: isim ilk harfi büyük
class UniversityLogoBox extends StatelessWidget {
  final String universityId;
  final String universityName;
  final double size;
  final Color accentColor;
  final bool isWinner;
  // Logo etrafına glow eklemek için (sadece winner durumunda)
  final bool showGlow;

  const UniversityLogoBox({
    super.key,
    required this.universityId,
    required this.universityName,
    required this.accentColor,
    this.size = 64,
    this.isWinner = false,
    this.showGlow = true,
  });

  String get _logoAssetPath => 'assets/logos/$universityId.png';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = size * 0.25; // 64 → 16

    return SizedBox(
      width: size + (isWinner && showGlow ? 12 : 0),
      height: size + (isWinner && showGlow ? 12 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (isWinner && showGlow)
            Container(
              width: size + 12,
              height: size + 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius + 4),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.35),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.95)
                  : Colors.white,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: isWinner
                    ? accentColor
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : AppColors.borderLightFor(context)),
                width: isWinner ? 2.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: EdgeInsets.all(size * 0.13),
            child: Image.asset(
              _logoAssetPath,
              fit: BoxFit.contain,
              semanticLabel: 'Üniversite logosu',
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  universityName.isNotEmpty
                      ? universityName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: size * 0.38,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
