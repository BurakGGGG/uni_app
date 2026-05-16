import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import 'dorm_room_colors.dart';

/// Kadı Burhaneddin KYK Yurdu oda krokisi (vektörel, CustomPaint)
/// Yukarıdan bakış (top-down) oda planı.
class DormRoomFloorPlan extends StatelessWidget {
  const DormRoomFloorPlan({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.18)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.infoLight,
                  AppColors.surfaceFor(context),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.radiusLg),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.map_rounded, size: 18,
                      color: AppColors.info),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Oda Krokisi',
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.info,
                          )),
                      const SizedBox(height: 2),
                      Text('3 Kişilik KYK Odası • Yukarıdan Görünüm',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textTertiaryFor(context),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Kroki alanı
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 16, 40, 16),
            child: AspectRatio(
              aspectRatio: 0.70, // Biraz daha dikdörtgen (uzun)
              child: CustomPaint(
                painter: _RoomFloorPlanPainter(),
              ),
            ),
          ),

          // Lejant
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _legendItem(DormRoomZoneType.bed.fillColor, DormRoomZoneType.bed.label),
                _legendItem(DormRoomZoneType.bathroom.fillColor, 'Banyo/WC'),
                _legendItem(DormRoomZoneType.wardrobe.fillColor, DormRoomZoneType.wardrobe.label),
                _legendItem(DormRoomZoneType.desk.fillColor, 'Masalar'),
                _legendItem(DormRoomZoneType.common.fillColor, 'K = Komodin'),
              ],
            ),
          ),

          // Bilgi notu
          Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bu kroki yaklaşık olarak hazırlanmıştır. '
                    'Gerçek oda düzeni farklılık gösterebilir. '
                    'Bu yurda yerleşirseniz benzer bir düzende '
                    '3 kişilik odada kalabilirsiniz.',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textPrimaryFor(context),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.black26, width: 0.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textSecondary, fontSize: 10)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// CustomPainter — Vektörel oda krokisi
// ─────────────────────────────────────────────────────────────────
class _RoomFloorPlanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Oda padding
    final roomLeft = w * 0.05;
    final roomTop = h * 0.03;
    final roomRight = w * 0.95;
    final roomBottom = h * 0.97;
    final roomW = roomRight - roomLeft;
    final roomH = roomBottom - roomTop;

    // Duvar kalınlığı
    const wallThickness = 6.0;

    // ── Duvarlar ──
    final wallPaint = Paint()
      ..color = AppColors.textPrimary // Duvar rengi tema duyarlı olabilir
      ..style = PaintingStyle.stroke
      ..strokeWidth = wallThickness
      ..strokeJoin = StrokeJoin.round;

    final roomRect = Rect.fromLTRB(roomLeft, roomTop, roomRight, roomBottom);

    // Zemin
    final floorPaint = Paint()..color = AppColors.background;
    canvas.drawRect(roomRect, floorPaint);

    // Duvarları çiz
    canvas.drawRect(roomRect, wallPaint);

    // Yardımcı koordinatlar
    double lx(double frac) => roomLeft + roomW * frac;
    double ly(double frac) => roomTop + roomH * frac;

    // ── KAPI (üst orta-sol) ──
    _drawDoor(canvas, lx(0.28), ly(0), lx(0.46), ly(0), wallThickness);

    // ── PENCERE (alt orta) ──
    _drawWindow(canvas, lx(0.40), ly(1.0), lx(0.60), ly(1.0), wallThickness);

    // ── DOLAP (sol üst) ──
    _drawBox(canvas, lx(0.0), ly(0.0), lx(0.26), ly(0.35),
        DormRoomZoneType.wardrobe.fillColor, DormRoomZoneType.wardrobe.borderColor, DormRoomZoneType.wardrobe.label,
        vertical: true, fontSize: 11);

    // ── MASALAR (sol alt) ──
    _drawBox(canvas, lx(0.0), ly(0.42), lx(0.26), ly(1.0),
        DormRoomZoneType.desk.fillColor, DormRoomZoneType.desk.borderColor, 'Masalar',
        vertical: true, fontSize: 11);

    // ── SANDALYELER ──
    _drawChair(canvas, lx(0.34), ly(0.52));
    _drawChair(canvas, lx(0.34), ly(0.71));
    _drawChair(canvas, lx(0.34), ly(0.90));

    // ── BANYO (sağ üst) ──
    _drawBox(canvas, lx(0.55), ly(0.0), lx(1.0), ly(0.20),
        DormRoomZoneType.bathroom.fillColor, DormRoomZoneType.bathroom.borderColor, 'Banyo', fontSize: 11);

    // ── WC (banyonun altı) ──
    _drawBox(canvas, lx(0.55), ly(0.20), lx(1.0), ly(0.40),
        DormRoomZoneType.bathroom.fillColor, DormRoomZoneType.bathroom.borderColor, 'WC', fontSize: 11);

    // ── YATAK 1 & K1 ──
    _drawBed(canvas, lx(0.52), ly(0.46), lx(0.88), ly(0.56), 'Yatak 1');
    _drawBox(canvas, lx(0.83), ly(0.56), lx(0.98), ly(0.61),
        DormRoomZoneType.common.fillColor, DormRoomZoneType.common.borderColor, 'K1', fontSize: 9);

    // ── YATAK 2 & K2 ──
    _drawBed(canvas, lx(0.52), ly(0.64), lx(0.88), ly(0.74), 'Yatak 2');
    _drawBox(canvas, lx(0.83), ly(0.74), lx(0.98), ly(0.79),
        DormRoomZoneType.common.fillColor, DormRoomZoneType.common.borderColor, 'K2', fontSize: 9);

    // ── YATAK 3 & K3 ──
    _drawBed(canvas, lx(0.52), ly(0.82), lx(0.88), ly(0.92), 'Yatak 3');
    _drawBox(canvas, lx(0.83), ly(0.92), lx(0.98), ly(0.97),
        DormRoomZoneType.common.fillColor, DormRoomZoneType.common.borderColor, 'K3', fontSize: 9);
  }

  void _drawBox(Canvas canvas, double l, double t, double r, double b,
      Color fill, Color stroke, String label,
      {bool vertical = false, double fontSize = 10}) {
    final rect = Rect.fromLTRB(l, t, r, b);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    canvas.drawRRect(rrect, Paint()..color = fill..style = PaintingStyle.fill);
    canvas.drawRRect(
        rrect,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    if (vertical) {
      _drawVerticalLabel(
          canvas, (l + r) / 2, (t + b) / 2, label, fontSize, AppColors.textPrimary);
    } else {
      _drawLabel(canvas, (l + r) / 2, (t + b) / 2, label, fontSize, AppColors.textPrimary);
    }
  }

  void _drawBed(Canvas canvas, double l, double t, double r, double b, String label) {
    final rect = Rect.fromLTRB(l, t, r, b);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    // Yatak gövdesi
    canvas.drawRRect(rrect, Paint()..color = DormRoomZoneType.bed.fillColor);
    canvas.drawRRect(
        rrect,
        Paint()
          ..color = DormRoomZoneType.bed.borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Yastık (Sol tarafta)
    final pillowW = (r - l) * 0.20;
    final pillowH = (b - t) * 0.60;
    final pillowRect = Rect.fromLTRB(
        l + (r - l) * 0.08,
        (t + b) / 2 - pillowH / 2,
        l + pillowW + (r - l) * 0.08,
        (t + b) / 2 + pillowH / 2);

    final pillowRRect = RRect.fromRectAndRadius(pillowRect, const Radius.circular(4));
    canvas.drawRRect(pillowRRect, Paint()..color = AppColors.surface);
    canvas.drawRRect(
        pillowRRect,
        Paint()
          ..color = AppColors.border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);

    // Yatak yazısı
    _drawLabel(
        canvas, (l + r) / 2 + pillowW / 2, (t + b) / 2, label, 10, AppColors.textPrimary);
  }

  void _drawChair(Canvas canvas, double cx, double cy) {
    const chairW = 14.0;
    const chairH = 16.0;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: chairW, height: chairH);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    canvas.drawRRect(rrect, Paint()..color = DormRoomZoneType.desk.fillColor);
    canvas.drawRRect(
        rrect,
        Paint()
          ..color = DormRoomZoneType.desk.borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Sandalye sırtlığı (Sağ tarafta, masaya -sola- baksın diye)
    canvas.drawLine(
        Offset(cx + chairW / 2 - 2, cy - chairH / 2 + 2),
        Offset(cx + chairW / 2 - 2, cy + chairH / 2 - 2),
        Paint()
          ..color = DormRoomZoneType.desk.borderColor
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round);
  }

  void _drawDoor(Canvas canvas, double x1, double y1, double x2, double y2, double thickness) {
    final doorWidth = x2 - x1;
    // Duvarı ört
    canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        Paint()
          ..color = AppColors.background
          ..strokeWidth = thickness + 2.0);

    // Kapı kanadı (içeri doğru açılmış gibi)
    canvas.drawLine(
        Offset(x1, y1),
        Offset(x1 + doorWidth * 0.7, y1 + doorWidth * 0.7),
        Paint()
          ..color = DormRoomZoneType.door.borderColor
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round);
  }

  void _drawWindow(Canvas canvas, double x1, double y1, double x2, double y2, double thickness) {
    // Duvarı ört
    canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        Paint()
          ..color = AppColors.background
          ..strokeWidth = thickness + 2.0);

    // Cam
    canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        Paint()
          ..color = DormRoomZoneType.window.borderColor
          ..strokeWidth = thickness * 0.8
          ..strokeCap = StrokeCap.round);
  }

  void _drawLabel(Canvas canvas, double x, double y, String text, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  void _drawVerticalLabel(Canvas canvas, double x, double y, String text, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(-1.5708); // -π/2
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
