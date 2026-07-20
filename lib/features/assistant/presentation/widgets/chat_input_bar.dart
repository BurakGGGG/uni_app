import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/robot_scripts.dart';

/// Sohbet giriş çubuğu — metin alanı + gönder. Arama sürerken kilitlenir.
/// [hint]/[keyboardType] ile sıralama-puan kutucuğu gibi dar amaçlı
/// varyantlar da bu widget'tan türer.
class ChatInputBar extends StatefulWidget {
  final bool enabled;
  final ValueChanged<String> onSend;
  final String? hint;
  final TextInputType? keyboardType;
  const ChatInputBar({
    super.key,
    required this.enabled,
    required this.onSend,
    this.hint,
    this.keyboardType,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: widget.enabled,
            minLines: 1,
            maxLines: widget.keyboardType == null ? 3 : 1,
            keyboardType: widget.keyboardType,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: widget.hint ?? RobotScripts.inputHint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiaryFor(context),
              ),
              filled: true,
              fillColor: AppColors.surfaceVariantFor(context)
                  .withValues(alpha: 0.7),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide:
                    BorderSide(color: AppColors.borderLightFor(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: widget.enabled ? _send : null,
          icon: const Icon(Icons.send_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
