/// A finished session summary. Produced by [TripLogService] when a live
/// connection goes down, the app is paused for longer than the idle
/// threshold, or the user manually "ends" a trip.
///
/// Intentionally denormalised — one row per trip, no delta encoding —
/// so the history screen can render thousands of entries without
/// recomputing anything.
library;

import 'dart:convert';

class TripEntry {
  TripEntry({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.distanceKm,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.autopilotSeconds,
    required this.accSeconds,
    required this.disengagements,
  });

  /// Monotonic millisecond id (start time). Used as the `key` in the
  /// history list and as the de-dup key when writing to SharedPreferences.
  final int id;

  final DateTime startedAt;
  final DateTime endedAt;
  final double distanceKm;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final int autopilotSeconds;
  final int accSeconds;
  final int disengagements;

  Duration get duration => endedAt.difference(startedAt);

  /// Fraction of the trip spent with steering autopilot engaged, 0..1.
  double get autopilotFraction {
    final total = duration.inSeconds;
    if (total <= 0) return 0;
    return (autopilotSeconds / total).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.millisecondsSinceEpoch,
        'endedAt': endedAt.millisecondsSinceEpoch,
        'distanceKm': distanceKm,
        'avgSpeedKmh': avgSpeedKmh,
        'maxSpeedKmh': maxSpeedKmh,
        'autopilotSeconds': autopilotSeconds,
        'accSeconds': accSeconds,
        'disengagements': disengagements,
      };

  static TripEntry? fromJson(Map<String, dynamic> json) {
    try {
      return TripEntry(
        id: json['id'] as int,
        startedAt: DateTime.fromMillisecondsSinceEpoch(json['startedAt'] as int),
        endedAt: DateTime.fromMillisecondsSinceEpoch(json['endedAt'] as int),
        distanceKm: (json['distanceKm'] as num).toDouble(),
        avgSpeedKmh: (json['avgSpeedKmh'] as num).toDouble(),
        maxSpeedKmh: (json['maxSpeedKmh'] as num).toDouble(),
        autopilotSeconds: json['autopilotSeconds'] as int,
        accSeconds: json['accSeconds'] as int,
        disengagements: json['disengagements'] as int,
      );
    } catch (_) {
      return null;
    }
  }

  static String encodeAll(List<TripEntry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList());

  static List<TripEntry> decodeAll(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final data = jsonDecode(raw);
      if (data is! List) return const [];
      final out = <TripEntry>[];
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final entry = TripEntry.fromJson(item);
          if (entry != null) out.add(entry);
        }
      }
      return out;
    } catch (_) {
      return const [];
    }
  }
}
