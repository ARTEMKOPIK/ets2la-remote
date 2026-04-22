import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SpeedGauge extends StatefulWidget {
  final double speedKmh;
  final double limitKmh;
  final double targetAccKmh;
  final double size;
  final String speedUnit;
  final double maxSpeed;

  const SpeedGauge({
    super.key,
    required this.speedKmh,
    this.limitKmh = 0,
    this.targetAccKmh = 0,
    this.size = 280,
    this.speedUnit = 'km/h',
    this.maxSpeed = 200,
  });

  @override
  State<SpeedGauge> createState() => _SpeedGaugeState();
}

class _SpeedGaugeState extends State<SpeedGauge> with SingleTickerProviderStateMixin {
  double _displaySpeed = 0;
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _displaySpeed = widget.speedKmh;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _animation = AlwaysStoppedAnimation(_displaySpeed);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SpeedGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speedKmh != widget.speedKmh) {
      _animateTo(widget.speedKmh);
    }
  }

  void _animateTo(double target) {
    _animController.reset();
    _animation = Tween<double>(
      begin: _displaySpeed,
      end: target,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.linear,
    ))
      ..addListener(() {
        if (mounted) {
          setState(() {
            _displaySpeed = _animation.value;
          });
        }
      });
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isOver = widget.limitKmh > 0 && _displaySpeed > widget.limitKmh * 1.05;
    final hasLimit = widget.limitKmh > 0;
    final hasTarget = widget.targetAccKmh > 0 && widget.targetAccKmh <= 300;

    return SizedBox(
      width: widget.size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size * 0.52,
            child: CustomPaint(
              painter: _ArcPainter(
                speed: _displaySpeed.clamp(0, widget.maxSpeed),
                limit: widget.limitKmh,
                target: widget.targetAccKmh,
                maxSpeed: widget.maxSpeed,
                isOver: isOver,
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: widget.size * 0.14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.speedUnit == 'mph'
                            ? (_displaySpeed * 0.621371).toStringAsFixed(0)
                            : _displaySpeed.toStringAsFixed(0),
                        style: TextStyle(fontFamily: 'Roboto', 
                          fontSize: widget.size * 0.3,
                          fontWeight: FontWeight.w800,
                          color: isOver ? AppColors.error : AppColors.textPrimary,
                          height: 1,
                        ),
                      ),
                      Text(
                        widget.speedUnit,
                        style: TextStyle(fontFamily: 'Roboto', 
                          fontSize: widget.size * 0.075,
                          color: AppColors.textSecondary,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasLimit)
                _Badge(
                  icon: Icons.do_not_disturb_on_rounded,
                  label: widget.speedUnit == 'mph'
                      ? (widget.limitKmh * 0.621371).toStringAsFixed(0)
                      : widget.limitKmh.toStringAsFixed(0),
                  unit: widget.speedUnit,
                  color: isOver ? AppColors.error : AppColors.textSecondary,
                  bgColor: isOver ? AppColors.errorDim : AppColors.surfaceElevated,
                  borderColor: isOver
                      ? AppColors.error.withOpacity(0.4)
                      : AppColors.surfaceBorder,
                ),
              if (hasLimit && hasTarget) const SizedBox(width: 10),
              if (hasTarget)
                _Badge(
                  icon: Icons.navigation_rounded,
                  label: widget.speedUnit == 'mph'
                      ? (widget.targetAccKmh * 0.621371).toStringAsFixed(0)
                      : widget.targetAccKmh.toStringAsFixed(0),
                  unit: widget.speedUnit,
                  color: AppColors.orange,
                  bgColor: AppColors.orangeGlow,
                  borderColor: AppColors.orange.withOpacity(0.3),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String unit;
  final Color color;
  final Color bgColor;
  final Color borderColor;

  const _Badge({
    required this.icon,
    required this.label,
    required this.unit,
    required this.color,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            '$label ',
            style: TextStyle(fontFamily: 'Roboto', 
              fontSize: 14, fontWeight: FontWeight.w700, color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(fontFamily: 'Roboto', 
              fontSize: 11, color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Arc painter ─────────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  final double speed;
  final double limit;
  final double target;
  final double maxSpeed;
  final bool isOver;

  const _ArcPainter({
    required this.speed,
    required this.limit,
    required this.target,
    required this.maxSpeed,
    required this.isOver,
  });

  static const double _startDeg = 210;
  static const double _sweepDeg = 120;

  double _deg(double fraction) =>
      _startDeg + _sweepDeg * fraction.clamp(0, 1);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.88;
    final radius = size.width * 0.43;
    final trackW = size.width * 0.04;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    final startRad = _startDeg * pi / 180;
    final sweepRad = _sweepDeg * pi / 180;

    // Background track
    _arc(canvas, rect, startRad, sweepRad,
        color: AppColors.gaugeTrack, width: trackW);

    // Speed progress
    final fraction = (speed / maxSpeed).clamp(0.0, 1.0);
    if (fraction > 0) {
      if (isOver) {
        final gradPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = trackW
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: startRad,
            endAngle: startRad + sweepRad * fraction,
            colors: const [AppColors.orange, AppColors.error],
          ).createShader(rect);
        canvas.drawArc(rect, startRad, sweepRad * fraction, false, gradPaint);
      } else {
        _arc(canvas, rect, startRad, sweepRad * fraction,
            color: AppColors.orange, width: trackW,
            glow: true, glowColor: AppColors.orange);
      }
    }

    // Limit marker
    if (limit > 0) {
      final lf = (limit / maxSpeed).clamp(0.0, 1.0);
      final la = _deg(lf) * pi / 180;
      _tick(canvas, cx, cy, radius, la,
          color: AppColors.error, innerFrac: 0.85, outerFrac: 1.1, width: 3);
    }

    // ACC target marker
    if (target > 0 && target <= 300) {
      final tf = (target / maxSpeed).clamp(0.0, 1.0);
      final ta = _deg(tf) * pi / 180;
      _tick(canvas, cx, cy, radius, ta,
          color: AppColors.orange, innerFrac: 0.88, outerFrac: 1.08, width: 2.5);
    }

    // Tick marks
    for (int i = 0; i <= 20; i++) {
      final frac = i / 20.0;
      final angle = _deg(frac) * pi / 180;
      final major = i % 4 == 0;
      _tick(canvas, cx, cy, radius, angle,
          color: major
              ? AppColors.textSecondary.withOpacity(0.5)
              : AppColors.textMuted.withOpacity(0.25),
          innerFrac: major ? 0.80 : 0.86,
          outerFrac: 0.93,
          width: major ? 2 : 1);
    }

    // Speed labels
    final labelPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i <= 2; i++) {
      final frac = i / 2.0;
      final angle = _deg(frac) * pi / 180;
      final labelR = radius * 0.68;
      final lx = cx + labelR * cos(angle);
      final ly = cy + labelR * sin(angle);
      final speedVal = (maxSpeed * frac).round();
      labelPainter.text = TextSpan(
        text: '$speedVal',
        style: TextStyle(fontFamily: 'Roboto', 
          fontSize: size.width * 0.04,
          color: AppColors.textMuted.withOpacity(0.4),
          fontWeight: FontWeight.w500,
        ),
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(lx - labelPainter.width / 2, ly - labelPainter.height / 2),
      );
    }
  }

  void _arc(
    Canvas canvas,
    Rect rect,
    double start,
    double sweep, {
    required Color color,
    required double width,
    bool glow = false,
    Color? glowColor,
  }) {
    if (glow && glowColor != null) {
      canvas.drawArc(
        rect,
        start, sweep, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 2.5
          ..strokeCap = StrokeCap.round
          ..color = glowColor.withOpacity(0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawArc(
      rect, start, sweep, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  void _tick(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    double angle, {
    required Color color,
    required double innerFrac,
    required double outerFrac,
    required double width,
  }) {
    canvas.drawLine(
      Offset(cx + radius * innerFrac * cos(angle),
          cy + radius * innerFrac * sin(angle)),
      Offset(cx + radius * outerFrac * cos(angle),
          cy + radius * outerFrac * sin(angle)),
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.speed != speed ||
      old.limit != limit ||
      old.target != target ||
      old.isOver != isOver;
}