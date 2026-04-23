/// Defensive JSON helpers. ETS2LA's backend has historically sent booleans
/// as `0`/`1` ints on some platforms and sent lists where strings were
/// expected, so we normalise those up front instead of crashing the whole
/// telemetry pipeline.
bool _parseBool(Object? raw, {bool fallback = false}) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  if (raw is String) {
    final lower = raw.toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return fallback;
}

double _parseDouble(Object? raw) {
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw) ?? 0;
  return 0;
}

int _parseInt(Object? raw) {
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw) ?? 0;
  return 0;
}

List<String> _parseStringList(Object? raw) {
  if (raw is List) {
    return raw.whereType<String>().toList(growable: false);
  }
  return const <String>[];
}

class TruckState {
  final double speed;
  final double speedLimit;
  final double cruiseControlSpeed;
  final double targetSpeed;
  final double throttle;
  final double brake;
  final bool indicatingLeft;
  final bool indicatingRight;
  final bool indicatorLeft;
  final bool indicatorRight;
  final String game;
  final int time;

  const TruckState({
    this.speed = 0,
    this.speedLimit = 0,
    this.cruiseControlSpeed = 0,
    this.targetSpeed = 0,
    this.throttle = 0,
    this.brake = 0,
    this.indicatingLeft = false,
    this.indicatingRight = false,
    this.indicatorLeft = false,
    this.indicatorRight = false,
    this.game = 'ETS2',
    this.time = 0,
  });

  factory TruckState.fromJson(Map<String, dynamic> json) {
    return TruckState(
      speed: _parseDouble(json['speed']),
      speedLimit: _parseDouble(json['speed_limit']),
      cruiseControlSpeed: _parseDouble(json['cruise_control']),
      targetSpeed: _parseDouble(json['target_speed']),
      throttle: _parseDouble(json['throttle']),
      brake: _parseDouble(json['brake']),
      indicatingLeft: _parseBool(json['indicating_left']),
      indicatingRight: _parseBool(json['indicating_right']),
      indicatorLeft: _parseBool(json['indicator_left']),
      indicatorRight: _parseBool(json['indicator_right']),
      game: json['game'] is String ? json['game'] as String : 'ETS2',
      time: _parseInt(json['time']),
    );
  }

  // speed from ETS2LA is in m/s, convert to km/h. Negative values clamped to 0.
  double get speedKmh => (speed < 0 ? 0 : speed) * 3.6;
  // speedLimit can be 0 (no limit) but never negative — clamp to 0 for safety
  double get speedLimitKmh => (speedLimit < 0 ? 0 : speedLimit) * 3.6;
  double get targetSpeedKmh => targetSpeed * 3.6;
  bool get isOverSpeedLimit => speedLimit > 0 && speed > speedLimit * 1.05;

  // Use OR of both indicator fields for robustness
  bool get isIndicatingLeft => indicatingLeft || indicatorLeft;
  bool get isIndicatingRight => indicatingRight || indicatorRight;
}

class TruckTransform {
  final double x;
  final double y;
  final double z;
  final double rx;
  final double ry;
  final double rz;

  const TruckTransform({
    this.x = 0, this.y = 0, this.z = 0,
    this.rx = 0, this.ry = 0, this.rz = 0,
  });

  factory TruckTransform.fromJson(Map<String, dynamic> json) {
    return TruckTransform(
      x: _parseDouble(json['x']),
      y: _parseDouble(json['y']),
      z: _parseDouble(json['z']),
      rx: _parseDouble(json['rx']),
      ry: _parseDouble(json['ry']),
      rz: _parseDouble(json['rz']),
    );
  }
}

class AutopilotStatus {
  final List<String> enabled;
  final List<String> disabled;

  const AutopilotStatus({this.enabled = const [], this.disabled = const []});

  bool get steeringEnabled => enabled.contains('Map');
  bool get accEnabled => enabled.contains('AdaptiveCruiseControl');
  bool get collisionEnabled => enabled.contains('CollisionAvoidance');

  factory AutopilotStatus.fromJson(Map<String, dynamic> json) {
    return AutopilotStatus(
      enabled: _parseStringList(json['enabled']),
      disabled: _parseStringList(json['disabled']),
    );
  }
}
