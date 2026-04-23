import 'package:flutter/material.dart';
import 'package:ets2la_remote/l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../utils/text_scale.dart';

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final String? subtitle;
  final IconData? icon;
  final Color? accentColor;
  final Widget? child;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: child ?? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
              ],
              Text(
                label.toUpperCase(),
                style: TextStyle(fontFamily: 'Roboto', 
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(fontFamily: 'Roboto', 
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit!,
                    style: TextStyle(fontFamily: 'Roboto', 
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(fontFamily: 'Roboto', fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class ThrottleCard extends StatelessWidget {
  final double throttle;
  final double brake;

  const ThrottleCard({super.key, required this.throttle, required this.brake});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.pedals ?? 'PEDALS',
            style: TextStyle(fontFamily: 'Roboto', 
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _PedalBar(label: l10n?.gas ?? 'GAS', value: throttle, color: AppColors.success),
          const SizedBox(height: 8),
          _PedalBar(label: l10n?.brake ?? 'BRAKE', value: brake, color: AppColors.error),
        ],
      ),
    );
  }
}

class _PedalBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _PedalBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 46, // wider to prevent BRAKE wrapping
          child: ClampedTextScale(
            // Largest system font pushes this past the pill; cap it.
            max: 1.1,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '${(value * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontFamily: 'Roboto', fontSize: 10, color: AppColors.textSecondary),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class IndicatorWidget extends StatefulWidget {
  final bool leftActive;
  final bool rightActive;

  const IndicatorWidget({super.key, required this.leftActive, required this.rightActive});

  @override
  State<IndicatorWidget> createState() => _IndicatorWidgetState();
}

class _IndicatorWidgetState extends State<IndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _blink;
  late Animation<double> _blinkAnim;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _blinkAnim = Tween<double>(begin: 0, end: 1).animate(_blink);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final hasLeft = widget.leftActive;
    final hasRight = widget.rightActive;
    
    if (!hasLeft && !hasRight) {
      return const SizedBox.shrink();
    }
    
    // Show BOTH arrows and blink when ANY indicator is active
    // This covers both turn signals and hazard lights
    return AnimatedBuilder(
      animation: _blinkAnim,
      builder: (_, __) {
        final show = _blinkAnim.value > 0.5;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Arrow(direction: 'left', active: hasLeft && show),
            const SizedBox(width: 32),
            _Arrow(direction: 'right', active: hasRight && show),
          ],
        );
      },
    );
  }
}

class _Arrow extends StatelessWidget {
  final String direction;
  final bool active;

  const _Arrow({required this.direction, required this.active});

  @override
  Widget build(BuildContext context) {
    return Icon(
      direction == 'left'
          ? Icons.arrow_back_ios_rounded
          : Icons.arrow_forward_ios_rounded,
      size: 28,
      color: active ? AppColors.warning : AppColors.textMuted.withOpacity(0.3),
    );
  }
}