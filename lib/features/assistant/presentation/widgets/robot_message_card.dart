import 'package:flutter/material.dart';

import '../../domain/robot_message.dart';
import 'robot_avatar.dart';
import 'robot_speech_bubble.dart';

/// Avatar + balon hazır kompozisyonu — bağlamsal yüzeylerin (boş liste,
/// sağlık paneli vb.) kullandığı satır. Mood mesajdan gelir.
class RobotMessageCard extends StatelessWidget {
  final RobotMessage message;
  final double avatarSize;
  final bool animatedAvatar;
  final bool typewriter;
  final bool onDark;
  final bool dense;
  final Widget? trailing;
  final VoidCallback? onTap;

  const RobotMessageCard({
    super.key,
    required this.message,
    this.avatarSize = 44,
    this.animatedAvatar = true,
    this.typewriter = true,
    this.onDark = false,
    this.dense = false,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RobotAvatar(
          size: avatarSize,
          mood: message.mood,
          animated: animatedAvatar,
          bodyColor: onDark ? Colors.white : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RobotSpeechBubble(
            message: message,
            typewriter: typewriter,
            onDark: onDark,
            dense: dense,
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
    if (onTap == null) return row;
    return GestureDetector(onTap: onTap, child: row);
  }
}
