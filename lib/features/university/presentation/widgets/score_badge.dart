import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

enum ScoreBadgeVariant {
  scoreType,    // SAY/EA/SÖZ/DİL/TYT
  baseScore,    // 547.32
  ranking,      // 856
  quota,        // 120/120
  delta,        // ↗ +7.14
}

class ScoreBadge extends StatelessWidget {
  final ScoreBadgeVariant variant;
  final String value;
  final IconData? icon;
  final Color? customColor;
  final bool small;

  const ScoreBadge({
    super.key,
    required this.variant,
    required this.value,
    this.icon,
    this.customColor,
    this.small = false,
  });

  factory ScoreBadge.scoreType(String type, {bool small = false}) {
    return ScoreBadge(
      variant: ScoreBadgeVariant.scoreType,
      value: type,
      customColor: _scoreTypeColor(type),
      small: small,
    );
  }

  factory ScoreBadge.baseScore(double score, {bool small = false}) {
    return ScoreBadge(
      variant: ScoreBadgeVariant.baseScore,
      value: score.toStringAsFixed(2),
      icon: Icons.trending_up_rounded,
      customColor: AppColors.primary,
      small: small,
    );
  }

  factory ScoreBadge.ranking(int rank, {bool small = false}) {
    final formatted = rank > 999 ? '${(rank / 1000).toStringAsFixed(1)}B' : rank.toString();
    return ScoreBadge(
      variant: ScoreBadgeVariant.ranking,
      value: formatted,
      icon: Icons.emoji_events_rounded,
      customColor: AppColors.warning,
      small: small,
    );
  }

  factory ScoreBadge.quota(int placed, int quota, {bool small = false}) {
    return ScoreBadge(
      variant: ScoreBadgeVariant.quota,
      value: '$placed/$quota',
      icon: Icons.people_rounded,
      customColor: placed == quota ? AppColors.success : AppColors.info,
      small: small,
    );
  }

  factory ScoreBadge.delta(double delta, {bool small = false}) {
    final isUp = delta > 0;
    final color = isUp ? AppColors.success : AppColors.error;
    return ScoreBadge(
      variant: ScoreBadgeVariant.delta,
      value: '${isUp ? "+" : ""}${delta.toStringAsFixed(2)}',
      icon: isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
      customColor: color,
      small: small,
    );
  }

  static Color _scoreTypeColor(String type) {
    switch (type) {
      case 'SAYISAL': return const Color(0xFF3B82F6);
      case 'SAY': return const Color(0xFF3B82F6);
      case 'EŞİT AĞIRLIK': return const Color(0xFF8B5CF6);
      case 'EA':  return const Color(0xFF8B5CF6);
      case 'SÖZEL': return const Color(0xFFEC4899);
      case 'SÖZ': return const Color(0xFFEC4899);
      case 'DİL': return const Color(0xFF10B981);
      case 'TYT': return const Color(0xFFF59E0B);
      default:    return AppColors.primary;
    }
  }

  /// Puan türü kısa label'ını döner (SAYISAL → SAY, EŞİT AĞIRLIK → EA vs.)
  static String shortLabel(String type) {
    switch (type) {
      case 'SAYISAL': return 'SAY';
      case 'EŞİT AĞIRLIK': return 'EA';
      case 'SÖZEL': return 'SÖZ';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = customColor ?? AppColors.primary;
    final padH = small ? 6.0 : 8.0;
    final padV = small ? 3.0 : 4.0;
    final iconSize = small ? 12.0 : 14.0;
    final fontSize = small ? 10.0 : 11.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(small ? 6 : 8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: color),
            SizedBox(width: small ? 3 : 4),
          ],
          Text(
            variant == ScoreBadgeVariant.scoreType ? shortLabel(value) : value,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
