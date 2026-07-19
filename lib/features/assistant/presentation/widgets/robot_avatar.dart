import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/robot_mood.dart';

/// Üni — ÜniSeç'in animasyonlu robot maskotu. Tamamen kodla çizilir
/// (asset yok), tema renklerine uyar, 18px buton ikonundan 96px hero'ya
/// ölçeklenir.
///
/// Performans kuralı: ekran başına en fazla bir `animated: true` avatar;
/// liste/buton içi kullanımlar `animated: false` vermeli. Erişilebilirlik
/// "animasyonları kaldır" ayarı açıkken controller'lar hiç kurulmaz.
class RobotAvatar extends StatefulWidget {
  final double size;
  final RobotMood mood;
  final bool animated;

  /// Kafa rengi. null → marka gradyanı ([AppColors.primary] →
  /// [AppColors.secondary], mor→pembe); gradient zeminlerde tek düz renk
  /// (örn. [Colors.white]) verilebilir.
  final Color? bodyColor;

  const RobotAvatar({
    super.key,
    this.size = 48,
    this.mood = RobotMood.neutral,
    this.animated = true,
    this.bodyColor,
  });

  @override
  State<RobotAvatar> createState() => _RobotAvatarState();
}

class _RobotAvatarState extends State<RobotAvatar>
    with TickerProviderStateMixin {
  AnimationController? _idle;
  AnimationController? _blink;
  Timer? _blinkTimer;
  final _random = math.Random();
  bool _shouldAnimate = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wanted =
        widget.animated && !MediaQuery.disableAnimationsOf(context);
    if (wanted != _shouldAnimate) {
      _shouldAnimate = wanted;
      _shouldAnimate ? _startAnimations() : _stopAnimations();
    }
  }

  @override
  void didUpdateWidget(covariant RobotAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animated != widget.animated) {
      final wanted =
          widget.animated && !MediaQuery.disableAnimationsOf(context);
      if (wanted != _shouldAnimate) {
        _shouldAnimate = wanted;
        _shouldAnimate ? _startAnimations() : _stopAnimations();
      }
    }
  }

  void _startAnimations() {
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scheduleBlink();
  }

  void _stopAnimations() {
    _blinkTimer?.cancel();
    _blinkTimer = null;
    _idle?.dispose();
    _idle = null;
    _blink?.dispose();
    _blink = null;
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(
      Duration(milliseconds: 2500 + _random.nextInt(2500)),
      () async {
        final blink = _blink;
        if (!mounted || blink == null) return;
        await blink.forward();
        if (!mounted || _blink == null) return;
        await blink.reverse();
        if (mounted && _blink != null) _scheduleBlink();
      },
    );
  }

  @override
  void dispose() {
    _stopAnimations();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final explicit = widget.bodyColor;
    final top = explicit ?? AppColors.primary;
    final bottom = explicit == null
        ? AppColors.secondary
        : Color.lerp(explicit, Colors.black, 0.10)!;

    Widget avatar;
    if (_shouldAnimate) {
      avatar = AnimatedBuilder(
        animation: Listenable.merge([_idle!, _blink!]),
        builder: (_, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: _RobotPainter(
            mood: widget.mood,
            bodyTop: top,
            bodyBottom: bottom,
            bob: _idle!.value,
            blink: 1 - _blink!.value,
          ),
        ),
      );
    } else {
      avatar = CustomPaint(
        size: Size.square(widget.size),
        painter: _RobotPainter(
          mood: widget.mood,
          bodyTop: top,
          bodyBottom: bottom,
          bob: 0,
          blink: 1,
        ),
      );
    }

    avatar = RepaintBoundary(
      child: SizedBox.square(dimension: widget.size, child: avatar),
    );

    if (!_shouldAnimate) return avatar;
    // Mood değişiminde küçük bir "pop": key değişince efekt baştan oynar.
    return avatar
        .animate(key: ValueKey(widget.mood))
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1, 1),
          duration: 260.ms,
          curve: Curves.easeOutBack,
        );
  }
}

/// Tüm ölçüler size oranı — s(0.5) = genişliğin yarısı.
class _RobotPainter extends CustomPainter {
  final RobotMood mood;

  /// Kafa gradyanının üst/alt rengi (varsayılan marka: mor→pembe).
  final Color bodyTop;
  final Color bodyBottom;

  /// 0-1 süzülme fazı (sinüs döngüsü).
  final double bob;

  /// 1 = gözler açık, 0 = kapalı (kırpma anı).
  final double blink;

  static const Color _screenColor = Color(0xFF2A2A3E);

  const _RobotPainter({
    required this.mood,
    required this.bodyTop,
    required this.bodyBottom,
    required this.bob,
    required this.blink,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    double s(double f) => w * f;

    // Süzülme: tüm gövde hafifçe iner-çıkar.
    canvas.translate(0, math.sin(bob * 2 * math.pi) * s(0.03));

    final darker = Color.lerp(
        Color.lerp(bodyTop, bodyBottom, 0.5)!, Colors.black, 0.22)!;
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [bodyTop, bodyBottom],
      ).createShader(Rect.fromLTWH(0, 0, w, w));
    final borderPaint = Paint()
      ..color = darker.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s(0.02);

    // ── Anten ──
    final headTop = s(0.20);
    final antennaBase = Offset(s(0.5), headTop);
    // Kutlamada anten sağa-sola sallanır (±8°), ucu parlar.
    final wiggle = mood == RobotMood.celebrating
        ? math.sin(bob * 4 * math.pi) * (8 * math.pi / 180)
        : 0.0;
    final antennaTip = Offset(
      s(0.5) + math.sin(wiggle) * s(0.12),
      headTop - math.cos(wiggle) * s(0.12),
    );
    canvas.drawLine(
      antennaBase,
      antennaTip,
      Paint()
        ..color = darker
        ..strokeWidth = s(0.035)
        ..strokeCap = StrokeCap.round,
    );
    if (mood == RobotMood.celebrating) {
      canvas.drawCircle(
        antennaTip,
        s(0.07),
        Paint()
          ..color = AppColors.secondary.withValues(alpha: 0.55)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s(0.04)),
      );
    }
    canvas.drawCircle(
      antennaTip,
      s(0.045),
      Paint()
        ..color =
            mood == RobotMood.celebrating ? AppColors.secondary : darker,
    );

    // ── Kulaklar (yan yuvarlak çıkıntılar) ──
    final earPaint = Paint()..color = darker;
    RRect earRect(Offset c) => RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: s(0.08), height: s(0.20)),
          Radius.circular(s(0.04)),
        );
    canvas.drawRRect(earRect(Offset(s(0.085), s(0.56))), earPaint);
    canvas.drawRRect(earRect(Offset(s(0.915), s(0.56))), earPaint);

    // ── Kafa ──
    final headRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(s(0.11), headTop, s(0.89), s(0.94)),
      Radius.circular(s(0.20)),
    );
    canvas.drawRRect(headRect, bodyPaint);
    canvas.drawRRect(headRect, borderPaint);

    // ── Yüz ekranı — iki temada da okunan koyu lacivert ──
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(s(0.20), s(0.32), s(0.80), s(0.76)),
      Radius.circular(s(0.11)),
    );
    canvas.drawRRect(screenRect, Paint()..color = _screenColor);

    // ── Gözler + ağız + yanaklar ──
    final eyeY = s(0.49);
    final leftEye = Offset(s(0.385), eyeY);
    final rightEye = Offset(s(0.615), eyeY);
    final eyePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = s(0.045)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (mood) {
      case RobotMood.neutral:
        _capsuleEyes(canvas, s, leftEye, rightEye, openness: blink);
        _mouthLine(canvas, s, curve: 0.0);
        break;
      case RobotMood.happy:
        _crescentEyes(canvas, s, leftEye, rightEye, eyePaint);
        _mouthLine(canvas, s, curve: 1.0);
        _cheeks(canvas, s);
        break;
      case RobotMood.celebrating:
        _crescentEyes(canvas, s, leftEye, rightEye, eyePaint);
        _mouthLine(canvas, s, curve: 1.0, wide: true);
        _cheeks(canvas, s);
        break;
      case RobotMood.thinking:
        final shift = Offset(s(0.028), -s(0.028));
        _capsuleEyes(
          canvas,
          s,
          leftEye + shift,
          rightEye + shift,
          openness: blink,
        );
        // Tek kalkık kaş.
        canvas.drawLine(
          rightEye + Offset(-s(0.05), -s(0.14)),
          rightEye + Offset(s(0.05), -s(0.17)),
          eyePaint..strokeWidth = s(0.03),
        );
        // Küçük "o" ağız, hafif sağda.
        canvas.drawCircle(
          Offset(s(0.56), s(0.675)),
          s(0.028),
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = s(0.025),
        );
        break;
      case RobotMood.concerned:
        _capsuleEyes(
          canvas,
          s,
          leftEye,
          rightEye,
          openness: blink,
          scale: 0.75,
        );
        // Endişeli kaşlar: iç uçlar yukarıda.
        final browPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = s(0.03)
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          leftEye + Offset(-s(0.05), -s(0.12)),
          leftEye + Offset(s(0.045), -s(0.15)),
          browPaint,
        );
        canvas.drawLine(
          rightEye + Offset(-s(0.045), -s(0.15)),
          rightEye + Offset(s(0.05), -s(0.12)),
          browPaint,
        );
        _mouthLine(canvas, s, curve: -0.6);
        break;
      case RobotMood.sleeping:
        final linePaint = Paint()
          ..color = Colors.white
          ..strokeWidth = s(0.04)
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          leftEye - Offset(s(0.05), 0),
          leftEye + Offset(s(0.05), 0),
          linePaint,
        );
        canvas.drawLine(
          rightEye - Offset(s(0.05), 0),
          rightEye + Offset(s(0.05), 0),
          linePaint,
        );
        break;
    }
  }

  /// Kapsül gözler; [openness] 0'a inince kırpma çizgisine dönüşür.
  void _capsuleEyes(
    Canvas canvas,
    double Function(double) s,
    Offset left,
    Offset right, {
    required double openness,
    double scale = 1.0,
  }) {
    final h = math.max(s(0.02), s(0.15) * scale * openness);
    final wEye = s(0.095) * scale;
    final paint = Paint()..color = Colors.white;
    for (final c in [left, right]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: wEye, height: h),
          Radius.circular(wEye / 2),
        ),
        paint,
      );
    }
  }

  /// Gülen hilal gözler (∩ biçimi).
  void _crescentEyes(
    Canvas canvas,
    double Function(double) s,
    Offset left,
    Offset right,
    Paint paint,
  ) {
    for (final c in [left, right]) {
      final path = Path()
        ..moveTo(c.dx - s(0.055), c.dy + s(0.02))
        ..quadraticBezierTo(
          c.dx,
          c.dy - s(0.075),
          c.dx + s(0.055),
          c.dy + s(0.02),
        );
      canvas.drawPath(path, paint);
    }
  }

  /// Ağız: [curve] 1 = gülümseme, 0 = düz, negatif = aşağı dönük.
  void _mouthLine(
    Canvas canvas,
    double Function(double) s, {
    required double curve,
    bool wide = false,
  }) {
    final cx = s(0.5);
    final y = s(0.66);
    final half = wide ? s(0.10) : s(0.075);
    final path = Path()
      ..moveTo(cx - half, y)
      ..quadraticBezierTo(cx, y + s(0.06) * curve, cx + half, y);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..strokeWidth = s(0.035)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  /// Pembe yanak noktaları — sevimlilik burada.
  void _cheeks(Canvas canvas, double Function(double) s) {
    final paint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(s(0.29), s(0.60)), s(0.042), paint);
    canvas.drawCircle(Offset(s(0.71), s(0.60)), s(0.042), paint);
  }

  @override
  bool shouldRepaint(_RobotPainter old) =>
      old.mood != mood ||
      old.bodyTop != bodyTop ||
      old.bodyBottom != bodyBottom ||
      old.bob != bob ||
      old.blink != blink;
}
