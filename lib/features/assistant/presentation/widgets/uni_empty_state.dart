import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../domain/robot_scripts.dart';
import 'robot_avatar.dart';

/// Üni'nin sesiyle boş durum.
///
/// Çekirdek [EmptyState]'i olduğu gibi kullanır — o widget'ta zaten
/// markalama için bir `illustration` yuvası vardı; Üni asset gerektirmediği
/// için (saf `CustomPainter`) yuva doğrudan doldurulabiliyor.
///
/// Başlık ekrana özgü ve taranabilir kalır (mevcut ARB dizeleri yerinde);
/// Üni yalnız destekleyici satırı devralır — böylece çeviri yükü artmadan
/// çıkmaz sokaklarda tanıdık bir yüz olur.
///
/// Avatar bilinçli olarak `animated: false`: boş durumlar liste içinde de
/// çıkabiliyor ve ekran başına tek animasyonlu avatar kuralı var.
class UniEmptyState extends StatelessWidget {
  /// Avatar çizilemezse geri düşüş (çekirdek widget'ın davranışı).
  final IconData icon;
  final String title;

  /// Üni'nin cümlesi — iki dilli, [RobotScripts]'ten gelir.
  final RobotScript script;

  final Widget? action;
  final bool compact;

  const UniEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.script,
    this.action,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: icon,
      title: title,
      message: script.text,
      action: action,
      compact: compact,
      illustration: RobotAvatar(
        size: compact ? 64 : 80,
        mood: script.mood,
        animated: false,
      ),
    );
  }
}
