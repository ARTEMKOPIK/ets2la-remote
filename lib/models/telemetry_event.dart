/// One-shot event emitted by [TelemetryProvider] when a watched piece of
/// telemetry crosses a meaningful threshold. Consumers (haptic engine,
/// TTS announcer, toast service) subscribe to [TelemetryProvider.events]
/// and fan each event out to their own side-effect without having to
/// re-derive the transition from raw state.
enum TelemetryEventKind {
  steeringEnabled,
  steeringDisabled,
  accEnabled,
  accDisabled,
  collisionEnabled,
  collisionDisabled,
  overSpeedLimit,
  backUnderSpeedLimit,
}

class TelemetryEvent {
  TelemetryEvent(this.kind, {this.at, this.speedKmh, this.speedLimitKmh});

  final TelemetryEventKind kind;

  /// Timestamp when the transition was observed (defaults to `DateTime.now`).
  final DateTime? at;

  /// Optional context — for speed-related events, the numeric values at
  /// the moment the transition fired. Null for autopilot events.
  final double? speedKmh;
  final double? speedLimitKmh;
}
