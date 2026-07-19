import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/typewriter_text.dart';
import '../../domain/robot_message.dart';

/// Üni'nin konuşma balonu — sola (avatara) bakan kuyruklu yuvarlak kutu.
/// [typewriter] açıkken metin kelime kelime yazılır; metin değişince
/// TypewriterText otomatik baştan başlar (canlı tepkiler bunu kullanır).
class RobotSpeechBubble extends StatelessWidget {
  final RobotMessage message;
  final bool typewriter;

  /// Gradient başlıklar üstünde beyaz-saydam balon stili.
  final bool onDark;
  final bool dense;

  const RobotSpeechBubble({
    super.key,
    required this.message,
    this.typewriter = true,
    this.onDark = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = onDark
        ? Colors.white.withValues(alpha: 0.18)
        : AppColors.surfaceVariantFor(context);
    final textColor =
        onDark ? Colors.white : AppColors.textPrimaryFor(context);
    final style = (dense ? AppTextStyles.labelSmall : AppTextStyles.bodySmall)
        .copyWith(color: textColor, height: 1.4);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: dense ? 8 : 12),
          child: CustomPaint(
            size: const Size(7, 12),
            painter: _TailPainter(color: bubbleColor),
          ),
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 10 : 12,
              vertical: dense ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: typewriter
                ? TypewriterText(message.text, style: style)
                : Text(message.text, style: style),
          ),
        ),
      ],
    );
  }
}

/// Balonun sola bakan küçük kuyruğu.
class _TailPainter extends CustomPainter {
  final Color color;
  const _TailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height * 0.45)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}
