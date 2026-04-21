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
      speed: (json['speed'] as num?)?.toDouble() ?? 0,
      speedLimit: (json['speed_limit'] as num?)?.toDouble() ?? 0,
      cruiseControlSpeed: (json['cruise_control'] as num?)?.toDouble() ?? 0,
      targetSpeed: (json['target_speed'] as num?)?.toDouble() ?? 0,
      throttle: (json['throttle'] as num?)?.toDouble() ?? 0,
      brake: (json['brake'] as num?)?.toDouble() ?? 0,
      indicatingLeft: json['indicating_left'] as bool? ?? false,
      indicatingRight: json['indicating_right'] as bool? ?? false,
      indicatorLeft: json['indicator_left'] as bool? ?? false,
      indicatorRight: json['indicator_right'] as bool? ?? false,
      game: json['game'] as String? ?? 'ETS2',
      time: (json['time'] as num?)?.toInt() ?? 0,
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
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      z: (json['z'] as num?)?.toDouble() ?? 0,
      rx: (json['rx'] as num?)?.toDouble() ?? 0,
      ry: (json['ry'] as num?)?.toDouble() ?? 0,
      rz: (json['rz'] as num?)?.toDouble() ?? 0,
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
      enabled: List<String>.from(json['enabled'] ?? []),
      disabled: List<String>.from(json['disabled'] ?? []),
    );
  }
}
