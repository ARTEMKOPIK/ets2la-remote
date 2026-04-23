import 'package:flutter_test/flutter_test.dart';
import 'package:ets2la_remote/services/reconnect_backoff.dart';

void main() {
  group('ReconnectBackoff', () {
    test('first delay is approximately the initial duration', () {
      final b = ReconnectBackoff(
        initial: const Duration(seconds: 1),
        max: const Duration(seconds: 15),
        jitter: 0.0,
      );
      expect(b.nextDelay(), const Duration(seconds: 1));
    });

    test('doubles on each attempt until capped', () {
      final b = ReconnectBackoff(
        initial: const Duration(seconds: 1),
        max: const Duration(seconds: 15),
        jitter: 0.0,
      );
      expect(b.nextDelay(), const Duration(seconds: 1));
      expect(b.nextDelay(), const Duration(seconds: 2));
      expect(b.nextDelay(), const Duration(seconds: 4));
      expect(b.nextDelay(), const Duration(seconds: 8));
      expect(b.nextDelay(), const Duration(seconds: 15)); // capped
      expect(b.nextDelay(), const Duration(seconds: 15)); // stays capped
    });

    test('reset starts over from initial', () {
      final b = ReconnectBackoff(
        initial: const Duration(seconds: 1),
        max: const Duration(seconds: 15),
        jitter: 0.0,
      );
      b.nextDelay();
      b.nextDelay();
      b.nextDelay();
      b.reset();
      expect(b.nextDelay(), const Duration(seconds: 1));
    });

    test('jitter keeps result within ±jitter fraction of base', () {
      final b = ReconnectBackoff(
        initial: const Duration(seconds: 1),
        max: const Duration(seconds: 15),
        jitter: 0.2,
      );
      for (var i = 0; i < 50; i++) {
        final d = b.nextDelay();
        final base = (1000 * (1 << i)).clamp(0, 15000);
        expect(d.inMilliseconds, greaterThanOrEqualTo((base * 0.8).round() - 1));
        expect(d.inMilliseconds, lessThanOrEqualTo((base * 1.2).round() + 1));
      }
    });
  });
}
