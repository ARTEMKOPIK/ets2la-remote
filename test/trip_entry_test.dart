import 'package:flutter_test/flutter_test.dart';
import 'package:ets2la_remote/models/trip_entry.dart';

void main() {
  group('TripEntry', () {
    final sample = TripEntry(
      id: 100,
      startedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      endedAt: DateTime.fromMillisecondsSinceEpoch(1700003600000),
      distanceKm: 42.5,
      avgSpeedKmh: 55.0,
      maxSpeedKmh: 92.1,
      autopilotSeconds: 2400,
      accSeconds: 1800,
      disengagements: 3,
    );

    test('duration equals end - start', () {
      expect(sample.duration, const Duration(hours: 1));
    });

    test('autopilotFraction clamps to [0, 1]', () {
      expect(sample.autopilotFraction, closeTo(2400 / 3600, 1e-6));

      final allAutopilot = TripEntry(
        id: 1,
        startedAt: DateTime(2024),
        endedAt: DateTime(2024).add(const Duration(hours: 1)),
        distanceKm: 1,
        avgSpeedKmh: 1,
        maxSpeedKmh: 1,
        autopilotSeconds: 999999,
        accSeconds: 0,
        disengagements: 0,
      );
      expect(allAutopilot.autopilotFraction, 1.0);
    });

    test('encode/decode roundtrip preserves every field', () {
      final encoded = TripEntry.encodeAll([sample]);
      final decoded = TripEntry.decodeAll(encoded);
      expect(decoded.length, 1);
      final r = decoded.first;
      expect(r.id, sample.id);
      expect(r.startedAt, sample.startedAt);
      expect(r.endedAt, sample.endedAt);
      expect(r.distanceKm, sample.distanceKm);
      expect(r.avgSpeedKmh, sample.avgSpeedKmh);
      expect(r.maxSpeedKmh, sample.maxSpeedKmh);
      expect(r.autopilotSeconds, sample.autopilotSeconds);
      expect(r.accSeconds, sample.accSeconds);
      expect(r.disengagements, sample.disengagements);
    });

    test('decodeAll returns empty list on null / garbage / wrong shape', () {
      expect(TripEntry.decodeAll(null), isEmpty);
      expect(TripEntry.decodeAll(''), isEmpty);
      expect(TripEntry.decodeAll('not json'), isEmpty);
      expect(TripEntry.decodeAll('{"not":"a list"}'), isEmpty);
      expect(TripEntry.decodeAll('[1, 2, 3]'), isEmpty);
    });

    test('decodeAll skips individual malformed entries', () {
      final mixed =
          '[{"id": 1}, ${_encodedSingle(sample)}]'; // first entry missing fields
      final decoded = TripEntry.decodeAll(mixed);
      expect(decoded.length, 1);
      expect(decoded.first.id, sample.id);
    });
  });
}

String _encodedSingle(TripEntry e) {
  final m = e.toJson();
  final buf = StringBuffer('{');
  final entries = m.entries.toList();
  for (var i = 0; i < entries.length; i++) {
    final k = entries[i].key;
    final v = entries[i].value;
    buf.write('"$k":');
    if (v is String) {
      buf.write('"$v"');
    } else {
      buf.write('$v');
    }
    if (i < entries.length - 1) buf.write(',');
  }
  buf.write('}');
  return buf.toString();
}
