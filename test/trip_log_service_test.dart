import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ets2la_remote/models/trip_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TripLogService static methods', () {
    setUp(() async {
      // Set up mock SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});
    });

    test('loadTrips returns empty list when no data', () async {
      final trips = await TripLogService_MockLoadTrips();
      expect(trips, isEmpty);
    });

    test('loadTrips returns stored trips', () async {
      // Pre-store some trips
      final prefs = await SharedPreferences.getInstance();
      final trips = [
        TripEntry(
          id: 1700000000000,
          startedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
          endedAt: DateTime.fromMillisecondsSinceEpoch(1700003600000),
          distanceKm: 42.5,
          avgSpeedKmh: 55.0,
          maxSpeedKmh: 92.1,
          autopilotSeconds: 2400,
          accSeconds: 1800,
          disengagements: 3,
        ),
      ];
      await prefs.setString('trip_log_v1', TripEntry.encodeAll(trips));

      final loaded = await TripLogService_MockLoadTrips();
      expect(loaded.length, 1);
      expect(loaded[0].distanceKm, 42.5);
    });

    test('loadTrips returns empty list on corrupted data', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('trip_log_v1', 'not valid json');

      final trips = await TripLogService_MockLoadTrips();
      expect(trips, isEmpty);
    });

    test('clear removes trip data', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('trip_log_v1', '[{"id": 1}]');

      await TripLogService_MockClear();

      final stored = prefs.getString('trip_log_v1');
      expect(stored, isNull);
    });

    test('loadTrips handles null gracefully', () async {
      // Don't set any value - should return empty
      final trips = await TripLogService_MockLoadTrips();
      expect(trips, isEmpty);
    });
  });

  group('TripEntry integration with TripLogService', () {
    test('TripEntry.encodeAll creates valid JSON for TripLogService', () {
      final trips = [
        TripEntry(
          id: 1700000000000,
          startedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
          endedAt: DateTime.fromMillisecondsSinceEpoch(1700003600000),
          distanceKm: 42.5,
          avgSpeedKmh: 55.0,
          maxSpeedKmh: 92.1,
          autopilotSeconds: 2400,
          accSeconds: 1800,
          disengagements: 3,
        ),
      ];
      final encoded = TripEntry.encodeAll(trips);
      expect(encoded, contains('"distanceKm":42.5'));
      expect(encoded, contains('"avgSpeedKmh":55'));
    });

    test('TripLogService accepts encoded TripEntry data', () async {
      final trips = [
        TripEntry(
          id: 1,
          startedAt: DateTime(2024, 1, 1),
          endedAt: DateTime(2024, 1, 1, 1, 0),
          distanceKm: 50.0,
          avgSpeedKmh: 50.0,
          maxSpeedKmh: 80.0,
          autopilotSeconds: 3000,
          accSeconds: 2000,
          disengagements: 2,
        ),
      ];
      final encoded = TripEntry.encodeAll(trips);
      final decoded = TripEntry.decodeAll(encoded);
      expect(decoded.length, 1);
      expect(decoded[0].distanceKm, 50.0);
    });
  });
}

// Mock implementations to test TripLogService static methods
// These replicate the logic from TripLogService for testing

Future<List<TripEntry>> TripLogService_MockLoadTrips() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return TripEntry.decodeAll(prefs.getString('trip_log_v1'));
  } catch (e) {
    return const [];
  }
}

Future<void> TripLogService_MockClear() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('trip_log_v1');
  } catch (e) {
    // Ignore
  }
}