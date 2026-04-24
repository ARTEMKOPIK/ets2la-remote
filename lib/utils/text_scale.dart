/// Utilities for clamping the global [MediaQuery.textScaler] on screens
/// where overly-large system fonts break the layout (AUTOPILOT / GAS /
/// BRAKE labels, gauge center text, etc.).
///
/// Android's "Largest" accessibility setting pushes `textScaler` up to
/// `2.0x`, which is valuable on scrollable screens but actively harmful
/// on the Dashboard, where labels live in fixed-size pill boxes and
/// overflow painfully. [ClampedTextScale] caps the scale without ignoring
/// it — the user still gets meaningfully larger text, just not to the
/// point where controls become unusable.

import 'package:flutter/widgets.dart';

class ClampedTextScale extends StatelessWidget {
  final Widget child;
  final double max;
  final double min;

  const ClampedTextScale({
    super.key,
    required this.child,
    this.min = 0.85,
    this.max = 1.25,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final scaler = mq.textScaler.clamp(
      minScaleFactor: min,
      maxScaleFactor: max,
    );
    return MediaQuery(
      data: mq.copyWith(textScaler: scaler),
      child: child,
    );
  }
}
