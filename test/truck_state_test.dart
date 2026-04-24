import 'package:flutter_test/flutter_test.dart';
import 'package:ets2la_remote/models/truck_state.dart';

void main() {
  group('TruckState', () {
    test('fromJson parses standard JSON with all fields', () {
      final state = TruckState.fromJson({
        'speed': 22.5,
        'speed_limit': 30.0,
        'cruise_control': 25.0,
        'target_speed': 25.0,
        'throttle': 0.6,
        'brake': 0.0,
        'indicating_left': true,
        'indicating_right': false,
        'indicator_left': false,
        'indicator_right': false,
        'game': 'ETS2',
        'time': 12345,
      });
      expect(state.speed, 22.5);
      expect(state.speedLimit, 30.0);
      expect(state.cruiseControlSpeed, 25.0);
      expect(state.targetSpeed, 25.0);
      expect(state.throttle, 0.6);
      expect(state.brake, 0.0);
      expect(state.indicatingLeft, true);
      expect(state.indicatingRight, false);
      expect(state.game, 'ETS2');
      expect(state.time, 12345);
    });

    test('fromJson defaults missing fields to zero', () {
      final state = TruckState.fromJson({});
      expect(state.speed, 0.0);
      expect(state.speedLimit, 0.0);
      expect(state.throttle, 0.0);
      expect(state.brake, 0.0);
    });

    test('fromJson parses booleans as true/false', () {
      final state = TruckState.fromJson({
        'indicating_left': true,
        'indicating_right': false,
      });
      expect(state.indicatingLeft, true);
      expect(state.indicatingRight, false);
    });

    test('fromJson parses integers as booleans (0/1)', () {
      final state = TruckState.fromJson({
        'indicating_left': 1,
        'indicating_right': 0,
      });
      expect(state.indicatingLeft, true);
      expect(state.indicatingRight, false);
    });

    test('fromJson parses string booleans', () {
      final state = TruckState.fromJson({
        'indicating_left': 'true',
        'indicating_right': 'false',
      });
      expect(state.indicatingLeft, true);
      expect(state.indicatingRight, false);
    });

    test('fromJson parses string numeric values', () {
      final state = TruckState.fromJson({
        'speed': '22.5',
        'throttle': '0.6',
      });
      expect(state.speed, 22.5);
      expect(state.throttle, 0.6);
    });

    test('speedKmh converts m/s to km/h', () {
      final state = TruckState.fromJson({'speed': 10.0});
      expect(state.speedKmh, 36.0); // 10 * 3.6 = 36
    });

    test('speedKmh clamps negative speed to zero', () {
      final state = TruckState.fromJson({'speed': -5.0});
      expect(state.speedKmh, 0.0);
    });

    test('speedLimitKmh converts and clamps to zero', () {
      final state = TruckState.fromJson({'speed_limit': 30.0});
      expect(state.speedLimitKmh, 108.0); // 30 * 3.6 = 108
    });

    test('speedLimitKmh clamps negative to zero', () {
      final state = TruckState.fromJson({'speed_limit': -10.0});
      expect(state.speedLimitKmh, 0.0);
    });

    test('targetSpeedKmh converts to km/h', () {
      final state = TruckState.fromJson({'target_speed': 25.0});
      expect(state.targetSpeedKmh, 90.0); // 25 * 3.6 = 90
    });

    test('isOverSpeedLimit returns true when over limit', () {
      final state = TruckState.fromJson({
        'speed': 32.0,
        'speed_limit': 30.0,
      });
      expect(state.isOverSpeedLimit, true);
    });

    test('isOverSpeedLimit returns false when under limit', () {
      final state = TruckState.fromJson({
        'speed': 25.0,
        'speed_limit': 30.0,
      });
      expect(state.isOverSpeedLimit, false);
    });

    test('isOverSpeedLimit returns false when no limit', () {
      final state = TruckState.fromJson({
        'speed': 50.0,
        'speed_limit': 0.0,
      });
      expect(state.isOverSpeedLimit, false);
    });

    test('isIndicatingLeft returns OR of both indicator fields', () {
      final state = TruckState.fromJson({
        'indicating_left': true,
        'indicator_left': false,
      });
      expect(state.isIndicatingLeft, true);
    });

    test('isIndicatingLeft uses indicatorLeft when indicatingLeft is false', () {
      final state = TruckState.fromJson({
        'indicating_left': false,
        'indicator_left': true,
      });
      expect(state.isIndicatingLeft, true);
    });

    test('isIndicatingRight returns OR of both indicator fields', () {
      final state = TruckState.fromJson({
        'indicating_right': false,
        'indicator_right': true,
      });
      expect(state.isIndicatingRight, true);
    });

    test('fromJson defaults game to ETS2', () {
      final state = TruckState.fromJson({});
      expect(state.game, 'ETS2');
    });

    test('fromJson accepts custom game string', () {
      final state = TruckState.fromJson({'game': 'ATS'});
      expect(state.game, 'ATS');
    });
  });

  group('TruckTransform', () {
    test('fromJson parses all coordinates', () {
      final transform = TruckTransform.fromJson({
        'x': 1.5,
        'y': 2.5,
        'z': 3.5,
        'rx': 0.1,
        'ry': 0.2,
        'rz': 0.3,
      });
      expect(transform.x, 1.5);
      expect(transform.y, 2.5);
      expect(transform.z, 3.5);
      expect(transform.rx, 0.1);
      expect(transform.ry, 0.2);
      expect(transform.rz, 0.3);
    });

    test('fromJson defaults to zero', () {
      final transform = TruckTransform.fromJson({});
      expect(transform.x, 0.0);
      expect(transform.y, 0.0);
      expect(transform.z, 0.0);
      expect(transform.rx, 0.0);
      expect(transform.ry, 0.0);
      expect(transform.rz, 0.0);
    });

    test('fromJson parses string values', () {
      final transform = TruckTransform.fromJson({
        'x': '1.5',
        'y': '2.5',
      });
      expect(transform.x, 1.5);
      expect(transform.y, 2.5);
    });

    test('constructor accepts all fields', () {
      const transform = TruckTransform(
        x: 1.0,
        y: 2.0,
        z: 3.0,
        rx: 0.5,
        ry: 0.6,
        rz: 0.7,
      );
      expect(transform.x, 1.0);
      expect(transform.y, 2.0);
      expect(transform.z, 3.0);
      expect(transform.rx, 0.5);
      expect(transform.ry, 0.6);
      expect(transform.rz, 0.7);
    });
  });

  group('AutopilotStatus', () {
    test('fromJson parses enabled and disabled lists', () {
      final status = AutopilotStatus.fromJson({
        'enabled': ['Map', 'AdaptiveCruiseControl'],
        'disabled': ['CollisionAvoidance'],
      });
      expect(status.enabled, ['Map', 'AdaptiveCruiseControl']);
      expect(status.disabled, ['CollisionAvoidance']);
    });

    test('fromJson defaults to empty lists', () {
      final status = AutopilotStatus.fromJson({});
      expect(status.enabled, isEmpty);
      expect(status.disabled, isEmpty);
    });

    test('fromJson filters non-string values from lists', () {
      final status = AutopilotStatus.fromJson({
        'enabled': ['Map', 123, 'ACC', null],
      });
      expect(status.enabled, ['Map', 'ACC']);
    });

    test('steeringEnabled returns true when Map in enabled', () {
      final status = AutopilotStatus.fromJson({
        'enabled': ['Map'],
      });
      expect(status.steeringEnabled, true);
    });

    test('steeringEnabled returns false when Map not in enabled', () {
      final status = AutopilotStatus.fromJson({
        'enabled': ['ACC'],
      });
      expect(status.steeringEnabled, false);
    });

    test('accEnabled returns true when AdaptiveCruiseControl in enabled', () {
      final status = AutopilotStatus.fromJson({
        'enabled': ['AdaptiveCruiseControl'],
      });
      expect(status.accEnabled, true);
    });

    test('collisionEnabled returns true when CollisionAvoidance in enabled', () {
      final status = AutopilotStatus.fromJson({
        'enabled': ['CollisionAvoidance'],
      });
      expect(status.collisionEnabled, true);
    });

    test('constructor accepts all fields', () {
      const status = AutopilotStatus(
        enabled: ['Map'],
        disabled: ['ACC'],
      );
      expect(status.enabled, ['Map']);
      expect(status.disabled, ['ACC']);
    });
  });
}