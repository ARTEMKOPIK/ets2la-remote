import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Lightweight rolling polyline chart of the last ~60s of a single
/// telemetry series. Intentionally stateless + painter-only so we don't
/// pull in a charting dependency for a single ornament.
class TelemetrySparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double height;
  final double? maxY;
  final double minY;

  const TelemetrySparkline({
    super.key,
    required this.values,
    this.color = AppColors.orange,
    this.height = 56,
    this.maxY,
    this.minY = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          color: color,
          minY: minY,
          maxY: maxY,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double minY;
  final double? maxY;

  _SparklinePainter({
    required this.values,
    required this.color,
    required this.minY,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final computedMax = (maxY ?? values.reduce((a, b) => a > b ? a : b));
    // Always leave headroom so a flat line doesn't touch the top edge.
    final yMax = computedMax < 10 ? 10.0 : computedMax * 1.1;
    final yMin = minY;
    final yRange = (yMax - yMin).abs() < 0.001 ? 1.0 : yMax - yMin;

    final path = Path();
    final fillPath = Path();
    final stepX = size.width / (values.length - 1);

    for (var i = 0; i < values.length; i++) {
      final x = stepX * i;
      final norm = ((values[i] - yMin) / yRange).clamp(0.0, 1.0);
      final y = size.height - norm * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.28),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      !identical(old.values, values) ||
      old.color != color ||
      old.maxY != maxY ||
      old.minY != minY;
}
