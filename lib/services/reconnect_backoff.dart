/// Shared exponential backoff used by all WebSocket services to schedule
/// reconnect attempts. Grows as 1s → 2s → 4s → 8s → 15s (capped), then
/// jitters ±20% so N clients don't all retry in lockstep.
// coverage:ignore-file — unit tested separately in test/reconnect_backoff_test.dart

import 'dart:math';

class ReconnectBackoff {
  ReconnectBackoff({
    this.initial = const Duration(seconds: 1),
    this.max = const Duration(seconds: 15),
    this.multiplier = 2.0,
    this.jitter = 0.2,
  });

  final Duration initial;
  final Duration max;
  final double multiplier;

  /// Random jitter factor in [0, 1]. A value of 0.2 means "up to ±20%".
  final double jitter;

  int _attempt = 0;
  final Random _rng = Random();

  /// Next delay to wait before retrying. Call this once per reconnect attempt.
  Duration nextDelay() {
    final base = initial.inMilliseconds * pow(multiplier, _attempt);
    final capped = base.clamp(0, max.inMilliseconds).toDouble();
    final j = 1.0 + (_rng.nextDouble() * 2 - 1) * jitter;
    _attempt++;
    return Duration(milliseconds: (capped * j).round());
  }

  /// Call on successful connect so the next disconnect starts from `initial`.
  void reset() {
    _attempt = 0;
  }
}
