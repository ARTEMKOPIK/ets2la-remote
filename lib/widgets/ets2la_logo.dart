import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Ets2laLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const Ets2laLogo({super.key, this.size = 80, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: _LogoPainter(),
        ),
        if (showText) ...[
          const SizedBox(height: 10),
          Text(
            'ETS2LA',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: size * 0.28,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          Text(
            'Remote',
            style: TextStyle(
              color: AppColors.orange,
              fontSize: size * 0.14,
              fontWeight: FontWeight.w500,
              letterSpacing: 4,
            ),
          ),
        ],
      ],
    );
  }
}

class _LogoPainter extends CustomPainter {
  Size? _cachedSize;
  late Paint _hexPaint;
  late Paint _orangePaint;
  late Paint _dashPaint;

  void _initPaints(Size size) {
    if (_cachedSize == size) return;
    _cachedSize = size;
    _hexPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeJoin = StrokeJoin.round;
    _orangePaint = Paint()
      ..color = AppColors.orange
      ..style = PaintingStyle.fill;
    _dashPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _initPaints(size);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.44;

    final hexPath = Path();
    for (int i = 0; i < 6; i++) {
      // Start at top-left flat-top hexagon
      final angle = (pi / 180) * (60 * i - 30);
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        hexPath.moveTo(x, y);
      } else {
        hexPath.lineTo(x, y);
      }
    }
    hexPath.close();
    canvas.drawPath(hexPath, _hexPaint);

    // --- 2. Clip to hexagon interior for road art ---
    canvas.save();
    final clipPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 180) * (60 * i - 30);
      final x = cx + (r - size.width * 0.03) * cos(angle);
      final y = cy + (r - size.width * 0.03) * sin(angle);
      if (i == 0) {
        clipPath.moveTo(x, y);
      } else {
        clipPath.lineTo(x, y);
      }
    }
    clipPath.close();
    canvas.clipPath(clipPath);

    // Vanishing point (top center inside hex)
    final vpX = cx;
    final vpY = cy - r * 0.35;

    // Bottom-left and bottom-right road base points
    final bottomLeft = Offset(cx - r * 0.72, cy + r * 0.88);
    final bottomRight = Offset(cx + r * 0.72, cy + r * 0.88);
    // Inner points near vanishing point
    final innerLeft = Offset(vpX - r * 0.08, vpY + r * 0.05);
    final innerRight = Offset(vpX + r * 0.08, vpY + r * 0.05);

    // --- 3. Left orange stripe ---
    final leftStripe = Path()
      ..moveTo(bottomLeft.dx, bottomLeft.dy)
      ..lineTo(cx - r * 0.15, cy + r * 0.88)
      ..lineTo(innerLeft.dx, innerLeft.dy)
      ..lineTo(innerLeft.dx - r * 0.06, innerLeft.dy)
      ..close();
    canvas.drawPath(leftStripe, _orangePaint);

    // --- 4. Right orange stripe ---
    final rightStripe = Path()
      ..moveTo(cx + r * 0.15, cy + r * 0.88)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(innerRight.dx + r * 0.06, innerRight.dy)
      ..lineTo(innerRight.dx, innerRight.dy)
      ..close();
    canvas.drawPath(rightStripe, _orangePaint);

    // --- 5. Dashed center lines ---
    // Draw 4 dashes perspective-shrinking
    const dashSegments = 4;
    for (int i = 0; i < dashSegments; i++) {
      final t0 = 0.15 + i * 0.18;
      final t1 = t0 + 0.09;
      final x0 = cx + (vpX - cx) * t0;
      final y0 = (cy + r * 0.88) + (vpY - (cy + r * 0.88)) * t0;
      final x1 = cx + (vpX - cx) * t1;
      final y1 = (cy + r * 0.88) + (vpY - (cy + r * 0.88)) * t1;
      canvas.drawLine(Offset(x0, y0), Offset(x1, y1), _dashPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Small compact version for AppBar
class Ets2laLogoSmall extends StatelessWidget {
  final double size;
  const Ets2laLogoSmall({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(size: Size(size, size), painter: _LogoPainter()),
        const SizedBox(width: 8),
        Text(
          'ETS2LA',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: size * 0.55,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
