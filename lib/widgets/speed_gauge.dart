import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Converts a km/h reading into the display unit. Defaults to identity
/// (pure km/h). Dashboard / visualization wire this through to
/// `AppSettings.speedFromKmh` so the gauge never has to know the conversion
/// factor, and so adding a new unit in the future is a one-line change.
typedef SpeedFormatter = double Function(double kmh);

double _identitySpeed(double kmh) => kmh;

class SpeedGauge extends StatefulWidget {
  final double speedKmh;
  final double limitKmh;
  final double targetAccKmh;
  final double size;
  final String speedUnit;
  final double maxSpeed;

  /// Optional converter from km/h to the display unit. When omitted the
  /// gauge shows raw km/h, matching the pre-refactor behaviour.
  final SpeedFormatter convertFromKmh;

  const SpeedGauge({
    super.key,
    required this.speedKmh,
    this.limitKmh = 0,
    this.targetAccKmh = 0,
    this.size = 280,
    this.speedUnit = 'km/h',
    this.maxSpeed = 200,
    this.convertFromKmh = _identitySpeed,
  });

  @override
  State<SpeedGauge> createState() => _SpeedGaugeState();
}

class _SpeedGaugeState extends State<SpeedGauge>
    with SingleTickerProviderStateMixin {
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
    final isOver =
        widget.limitKmh > 0 && _displaySpeed > widget.limitKmh * 1.05;
    final hasLimit = widget.limitKmh > 0;
    final hasTarget = widget.targetAccKmh > 0 && widget.targetAccKmh <= 300;
    final convert = widget.convertFromKmh;

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
                      Semantics(
                        label: 'Speed',
                        value:
                            '${convert(_displaySpeed).toStringAsFixed(0)} ${widget.speedUnit}',
                        excludeSemantics: true,
                        child: Text(
                          convert(_displaySpeed).toStringAsFixed(0),
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: widget.size * 0.3,
                            fontWeight: FontWeight.w800,
                            color: isOver
                                ? AppColors.error
                                : AppColors.textPrimary,
                            height: 1,
                          ),
                        ),
                      ),
                      Text(
                        widget.speedUnit,
                        style: TextStyle(
                          fontFamily: 'Roboto',
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
                  label: convert(widget.limitKmh).toStringAsFixed(0),
                  unit: widget.speedUnit,
                  color: isOver ? AppColors.error : AppColors.textSecondary,
                  bgColor:
                      isOver ? AppColors.errorDim : AppColors.surfaceElevated,
                  borderColor: isOver
                      ? AppColors.error.withOpacity(0.4)
                      : AppColors.surfaceBorder,
                ),
              if (hasLimit && hasTarget) const SizedBox(width: 10),
              if (hasTarget)
                _Badge(
                  icon: Icons.navigation_rounded,
                  label: convert(widget.targetAccKmh).toStringAsFixed(0),
                  unit: widget.speedUnit,
                  color: AppColors.orange,
                  bgColor: AppColors.orangeGlow,
                  borderColor: AppColors.orange.withOpacity(0.4),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            unit,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 10,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double speed;
  final double limit;
  final double target;
  final double maxSpeed;
  final bool isOver;

  _ArcPainter({
    required this.speed,
    required this.limit,
    required this.target,
    required this.maxSpeed,
    required this.isOver,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 20;

    const startAngle = pi;
    const sweepAngle = pi;

    // Background arc
    final bgPaint = Paint()
      ..color = AppColors.surfaceElevated
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Speed limit zone (red overlay if over)
    if (limit > 0) {
      final limitAngle = (limit / maxSpeed).clamp(0.0, 1.0) * sweepAngle;
      final overPaint = Paint()
        ..color = isOver ? AppColors.error.withOpacity(0.25) : Colors.transparent
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + limitAngle,
        sweepAngle - limitAngle,
        false,
        overPaint,
      );
    }

    // Progress arc
    final progressRatio = (speed / maxSpeed).clamp(0.0, 1.0);
    final gradient = LinearGradient(
      colors: isOver
          ? [AppColors.error, AppColors.error]
          : [AppColors.orange, AppColors.orange.withOpacity(0.8)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (progressRatio > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * progressRatio,
        false,
        progressPaint,
      );
    }

    // Limit marker
    if (limit > 0) {
      final limitRatio = (limit / maxSpeed).clamp(0.0, 1.0);
      final markerAngle = startAngle + sweepAngle * limitRatio;
      final markerX = center.dx + radius * cos(markerAngle);
      final markerY = center.dy + radius * sin(markerAngle);
      final markerPaint = Paint()
        ..color = AppColors.textSecondary
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(center.dx + (radius - 8) * cos(markerAngle),
            center.dy + (radius - 8) * sin(markerAngle)),
        Offset(markerX, markerY),
        markerPaint,
      );
    }

    // Target ACC marker (orange)
    if (target > 0 && target <= maxSpeed) {
      final targetRatio = (target / maxSpeed).clamp(0.0, 1.0);
      final markerAngle = startAngle + sweepAngle * targetRatio;
      final markerX = center.dx + radius * cos(markerAngle);
      final markerY = center.dy + radius * sin(markerAngle);
      final markerPaint = Paint()
        ..color = AppColors.orange
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(center.dx + (radius - 8) * cos(markerAngle),
            center.dy + (radius - 8) * sin(markerAngle)),
        Offset(markerX, markerY),
        markerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) =>
      oldDelegate.speed != speed ||
      oldDelegate.limit != limit ||
      oldDelegate.target != target ||
      oldDelegate.maxSpeed != maxSpeed ||
      oldDelegate.isOver != isOver;
}
