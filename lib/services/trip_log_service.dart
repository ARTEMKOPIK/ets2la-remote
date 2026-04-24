/// Records a rolling session of telemetry and persists finished trips to
/// SharedPreferences. The UI reads the history via [loadTrips].
///
/// The service is intentionally passive — it subscribes to the
/// TelemetryProvider event/state streams when asked, accumulates numbers
/// in memory, and only touches disk when a trip ends (either explicitly
/// via [endTrip] or because telemetry has been idle for more than
/// [_idleFlushThreshold]).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/telemetry_event.dart';
import '../models/trip_entry.dart';
import '../providers/settings_provider.dart';
import '../providers/telemetry_provider.dart';

class TripLogService {
  static const _prefsKey = 'trip_log_v1';
  static const _maxEntries = 50;

  /// If we don't get a telemetry update for this long, we finalise the
  /// current session. Covers both "game stopped" and "phone went to
  /// sleep" without requiring explicit signals from either side.
  static const Duration _idleFlushThreshold = Duration(minutes: 2);

  StreamSubscription<TelemetryEvent>? _eventSub;
  void Function()? _removeListener;
  TelemetryProvider? _provider;
  AppSettings? _settings;

  // Rolling aggregates for the current trip.
  DateTime? _startedAt;
  DateTime? _lastTickAt;
  double _distanceKm = 0;
  double _maxSpeedKmh = 0;
  double _speedSum = 0;
  int _speedSamples = 0;
  int _autopilotSeconds = 0;
  int _accSeconds = 0;
  int _disengagements = 0;

  VoidCallback attach(TelemetryProvider provider, AppSettings settings) {
    _provider = provider;
    _settings = settings;
    _eventSub?.cancel();
    _eventSub = provider.events.listen(_handleEvent);
    provider.addListener(_onTick);
    _removeListener = () => provider.removeListener(_onTick);
    return dispose;
  }

  void _handleEvent(TelemetryEvent event) {
    // Only attribute disengagements to an actually-running trip. Without
    // this guard a user toggling autopilot in a menu (before any movement)
    // would bank a phantom disengagement count that then leaks into the
    // first real trip's total.
    if (_startedAt == null) return;
    switch (event.kind) {
      case TelemetryEventKind.steeringDisabled:
      case TelemetryEventKind.accDisabled:
      case TelemetryEventKind.collisionDisabled:
        _disengagements += 1;
        break;
      default:
        break;
    }
  }

  void _onTick() {
    final provider = _provider;
    final settings = _settings;
    if (provider == null || settings == null) return;
    if (!settings.tripLogEnabled) return;

    final now = DateTime.now();
    final speedKmh = provider.truckState.speedKmh;

    if (_startedAt == null) {
      if (speedKmh <= 1) return; // wait for movement to start a trip
      _resetAggregates(now);
    }

    if (_lastTickAt != null) {
      // Auto-finalise when the stream has gone quiet.
      if (now.difference(_lastTickAt!) > _idleFlushThreshold) {
        unawaited(_flushTrip(endedAt: _lastTickAt!));
        _resetAggregates(now);
      }
    }

    final dtSeconds = _lastTickAt == null
        ? 0
        : now.difference(_lastTickAt!).inMilliseconds / 1000.0;
    if (dtSeconds > 0 && dtSeconds < 10) {
      _distanceKm += (speedKmh / 3600.0) * dtSeconds;
      if (provider.autopilotStatus.steeringEnabled) {
        _autopilotSeconds += dtSeconds.round();
      }
      if (provider.autopilotStatus.accEnabled) {
        _accSeconds += dtSeconds.round();
      }
    }
    if (speedKmh > _maxSpeedKmh) _maxSpeedKmh = speedKmh;
    if (speedKmh > 0.5) {
      _speedSum += speedKmh;
      _speedSamples += 1;
    }
    _lastTickAt = now;
  }

  void _resetAggregates(DateTime start) {
    _startedAt = start;
    _lastTickAt = start;
    _distanceKm = 0;
    _maxSpeedKmh = 0;
    _speedSum = 0;
    _speedSamples = 0;
    _autopilotSeconds = 0;
    _accSeconds = 0;
    _disengagements = 0;
  }

  Future<void> _flushTrip({required DateTime endedAt}) async {
    final start = _startedAt;
    if (start == null) return;
    if (_distanceKm < 0.1) {
      // Drop trivial trips (backend flickered, test drive) — they'd just
      // clutter the history.
      _startedAt = null;
      return;
    }
    final entry = TripEntry(
      id: start.millisecondsSinceEpoch,
      startedAt: start,
      endedAt: endedAt,
      distanceKm: _distanceKm,
      avgSpeedKmh:
          _speedSamples > 0 ? _speedSum / _speedSamples : 0,
      maxSpeedKmh: _maxSpeedKmh,
      autopilotSeconds: _autopilotSeconds,
      accSeconds: _accSeconds,
      disengagements: _disengagements,
    );
    _startedAt = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final all = TripEntry.decodeAll(prefs.getString(_prefsKey));
      all.insert(0, entry);
      if (all.length > _maxEntries) {
        all.removeRange(_maxEntries, all.length);
      }
      await prefs.setString(_prefsKey, TripEntry.encodeAll(all));
    } catch (e) {
      debugPrint('TripLogService flush error: $e');
    }
  }

  /// Read the persisted trip history (newest first).
  static Future<List<TripEntry>> loadTrips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return TripEntry.decodeAll(prefs.getString(_prefsKey));
    } catch (_) {
      return const [];
    }
  }

  /// Drop every saved trip. Used by the "Clear history" button in the
  /// trip log screen.
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {
      // best-effort
    }
  }

  /// Force-end the current in-memory trip (e.g. when the user taps
  /// "End session"). No-op if nothing is accumulating yet.
  Future<void> endTrip() async {
    if (_startedAt == null) return;
    await _flushTrip(endedAt: _lastTickAt ?? DateTime.now());
  }

  void dispose() {
    _eventSub?.cancel();
    _eventSub = null;
    _removeListener?.call();
    _removeListener = null;
    // Persist any work-in-progress trip so the user doesn't lose the
    // last few minutes on app shutdown.
    if (_startedAt != null) {
      unawaited(_flushTrip(endedAt: _lastTickAt ?? DateTime.now()));
    }
    _provider = null;
    _settings = null;
  }
}
