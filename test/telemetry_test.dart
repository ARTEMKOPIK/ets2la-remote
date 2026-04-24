import 'package:flutter_test/flutter_test.dart';
import 'package:ets2la_remote/models/telemetry.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('NavPosition', () {
    test('fromJson parses position array and bearing', () {
      final pos = NavPosition.fromJson({
        'position': [-122.4194, 37.7749],
        'bearing': 45.0,
        'speedMph': 30.0,
      });
      expect(pos.position.latitude, 37.7749);
      expect(pos.position.longitude, -122.4194);
      expect(pos.bearing, 45.0);
      expect(pos.speedMph, 30.0);
    });

    test('fromJson defaults missing fields to zero', () {
      final pos = NavPosition.fromJson({});
      expect(pos.position.latitude, 0.0);
      expect(pos.position.longitude, 0.0);
      expect(pos.bearing, 0.0);
      expect(pos.speedMph, 0.0);
    });

    test('fromJson handles empty position array', () {
      final pos = NavPosition.fromJson({
        'position': [],
      });
      expect(pos.position.latitude, 0.0);
      expect(pos.position.longitude, 0.0);
    });

    test('fromJson handles single-element position array', () {
      final pos = NavPosition.fromJson({
        'position': [1.0],
      });
      expect(pos.position.latitude, 0.0);
      expect(pos.position.longitude, 1.0);
    });

    test('fromJson parses string numeric values', () {
      final pos = NavPosition.fromJson({
        'position': ['-122.4194', '37.7749'],
        'bearing': '45.0',
        'speedMph': '30.0',
      });
      expect(pos.position.latitude, 37.7749);
      expect(pos.position.longitude, -122.4194);
      expect(pos.bearing, 45.0);
      expect(pos.speedMph, 30.0);
    });

    test('speedKmh converts mph to km/h', () {
      const pos = NavPosition(
        position: LatLng(0, 0),
        speedMph: 60.0,
      );
      expect(pos.speedKmh, closeTo(96.5604, 0.001)); // 60 * 1.60934
    });

    test('constructor accepts all fields', () {
      const pos = NavPosition(
        position: LatLng(37.7749, -122.4194),
        bearing: 90.0,
        speedMph: 45.0,
      );
      expect(pos.position.latitude, 37.7749);
      expect(pos.position.longitude, -122.4194);
      expect(pos.bearing, 90.0);
      expect(pos.speedMph, 45.0);
    });

    test('constructor defaults to zero', () {
      const pos = NavPosition(
        position: LatLng(0, 0),
      );
      expect(pos.bearing, 0.0);
      expect(pos.speedMph, 0.0);
    });
  });

  group('NavRoute', () {
    test('fromJson parses segments into points', () {
      final route = NavRoute.fromJson({
        'id': 'route-1',
        'segments': [
          {
            'lonLats': [
              [-122.4194, 37.7749],
              [-122.4150, 37.7800],
            ],
          },
          {
            'lonLats': [
              [-122.4150, 37.7800],
              [-122.4100, 37.7850],
            ],
          },
        ],
      });
      expect(route.id, 'route-1');
      expect(route.points.length, 4);
      expect(route.points[0].latitude, 37.7749);
      expect(route.points[0].longitude, -122.4194);
    });

    test('fromJson defaults to empty points', () {
      final route = NavRoute.fromJson({});
      expect(route.points, isEmpty);
      expect(route.id, '');
    });

    test('fromJson defaults id to empty string when missing', () {
      final route = NavRoute.fromJson({
        'segments': [],
      });
      expect(route.id, '');
    });

    test('fromJson handles empty segments array', () {
      final route = NavRoute.fromJson({
        'segments': [],
      });
      expect(route.points, isEmpty);
    });

    test('fromJson skips non-map segments', () {
      final route = NavRoute.fromJson({
        'segments': [
          'not a map',
          123,
          null,
        ],
      });
      expect(route.points, isEmpty);
    });

    test('fromJson skips segments without lonLats', () {
      final route = NavRoute.fromJson({
        'segments': [
          {'other': 'data'},
        ],
      });
      expect(route.points, isEmpty);
    });

    test('fromJson skips malformed lonLat pairs', () {
      final route = NavRoute.fromJson({
        'segments': [
          {
            'lonLats': [
              [1.0],
              'invalid',
              null,
              [1.0, 2.0, 3.0],
            ],
          },
        ],
      });
      // Should only parse valid [lon, lat] pairs with 2 elements
      expect(route.points.length, 1);
      expect(route.points[0].latitude, 2.0);
    });

    test('fromJson uses custom id when provided', () {
      final route = NavRoute.fromJson({
        'id': 'custom-route-id',
      });
      expect(route.id, 'custom-route-id');
    });

    test('constructor accepts all fields', () {
      const route = NavRoute(
        id: 'test-route',
        points: [
          LatLng(37.7749, -122.4194),
          LatLng(37.7800, -122.4150),
        ],
      );
      expect(route.id, 'test-route');
      expect(route.points.length, 2);
    });
  });
}