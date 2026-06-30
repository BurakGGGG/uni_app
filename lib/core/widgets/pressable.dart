import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tıklanabilir kartlar/öğeler için ortak basma (press) animasyonu.
///
/// Basıldığında içeriği hafifçe küçültür (scale), bırakıldığında geri
/// döndürür ve [onTap]'ı tetikler. Scroll başladığında veya jest iptal
/// olduğunda otomatik geri döner (onTapCancel) — yatay/dikey listelerde
/// güvenle kullanılabilir.
///
/// `city_card` / `place_card` gibi çıplak `GestureDetector` + scale
/// kalıplarının tek kaynağıdır. (Ripple isteyen InkWell tabanlı kartlarda
/// InkWell kendi geri bildirimini verdiği için bu sarmalayıcı gerekmez.)
///
/// Kullanım:
/// ```dart
/// Pressable(
///   onTap: () => context.push('/...'),
///   child: MyCard(),
/// )
/// ```
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Basılıyken uygulanan ölçek (1.0 = değişiklik yok).
  final double pressedScale;
  final Duration duration;

  /// Tıklamada hafif haptic geri bildirim ver.
  final bool enableHaptic;
  final HitTestBehavior behavior;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.duration = const Duration(milliseconds: 120),
    this.enableHaptic = false,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: widget.pressedScale,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  bool get _interactive => widget.onTap != null || widget.onLongPress != null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (_interactive) _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) => _controller.reverse();

  void _handleTapCancel() => _controller.reverse();

  void _handleTap() {
    if (widget.enableHaptic) HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _interactive ? _handleTapDown : null,
      onTapUp: _interactive ? _handleTapUp : null,
      onTapCancel: _interactive ? _handleTapCancel : null,
      onTap: widget.onTap == null ? null : _handleTap,
      onLongPress: widget.onLongPress,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
