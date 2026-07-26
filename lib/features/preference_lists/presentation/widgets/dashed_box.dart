import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Kesikli çerçeve — "burada henüz bir şey yok, ekleyebilirsin" dili.
class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: AppColors.primary.withValues(alpha: 0.45),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  const _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );
    final path = Path()..addRRect(rect);

    const dash = 7.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
