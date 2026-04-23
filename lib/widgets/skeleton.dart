import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

/// Shimmering rectangle for loading states. Animates a soft gradient sweep
/// across the surface so the user has a sense of "something is happening"
/// without a hard CircularProgressIndicator. Respects reduce-motion by
/// falling back to a static dim-coloured rectangle.
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const Skeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pull reduce-motion via Provider's `select` so skeletons don't rebuild
    // on unrelated settings changes (volume unit switches, etc.).
    final rm = context.select<AppSettings, bool>((s) => s.reduceMotion);
    if (rm) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: widget.borderRadius,
        ),
      );
    }
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 2, 0),
              end: Alignment(1 + t * 2, 0),
              colors: const [
                AppColors.surfaceElevated,
                AppColors.surfaceBorder,
                AppColors.surfaceElevated,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Convenience row of three skeleton lines matching a "list tile"
/// silhouette. Handy for recent hosts / profile list placeholders.
class SkeletonListTile extends StatelessWidget {
  final double avatarSize;
  const SkeletonListTile({super.key, this.avatarSize = 32});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Skeleton(
            width: avatarSize,
            height: avatarSize,
            borderRadius: BorderRadius.circular(avatarSize / 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 140, height: 12),
                const SizedBox(height: 8),
                Skeleton(width: 80, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

