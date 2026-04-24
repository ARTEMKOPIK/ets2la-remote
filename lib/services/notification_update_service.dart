/// Pushes live speed + autopilot state into the persistent foreground
/// notification shown by the Android keep-alive service. The notification
/// itself is created by the native [KeepAliveService]; this service only
/// calls [KeepAliveService.update] at a steady cadence so the title /
/// body reflect the current telemetry.
///
/// We throttle updates to ~1 Hz because:
///   * Android batches NotificationManager updates aggressively anyway —
///     firing at every telemetry frame (30 Hz) just wastes CPU.
///   * The km/h readout in the notification only needs to be roughly
///     accurate; 1 s staleness is invisible to the user.
library;

import 'dart:async';

import '../providers/connection_provider.dart';
import '../providers/telemetry_provider.dart';
import 'keep_alive_service.dart';

class NotificationUpdateService {
  NotificationUpdateService();

  Timer? _timer;
  TelemetryProvider? _telem;
  ConnectionProvider? _conn;

  /// Start pushing periodic updates. Returns a detacher callback; call
  /// it from the consuming widget's `dispose()`.
  void Function() attach({
    required TelemetryProvider telem,
    required ConnectionProvider conn,
  }) {
    _telem = telem;
    _conn = conn;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _push());
    return dispose;
  }

  void _push() {
    final telem = _telem;
    final conn = _conn;
    if (telem == null || conn == null) return;
    if (!conn.isConnected) return;
    final speed = telem.truckState.speedKmh.round();
    final auto = telem.autopilotStatus;
    final bits = <String>[];
    bits.add('$speed km/h');
    if (auto.steeringEnabled) bits.add('AP');
    if (auto.accEnabled) bits.add('ACC');
    final host = conn.currentHost;
    KeepAliveService.instance.update(
      title: host.isEmpty ? 'ETS2LA Remote' : 'ETS2LA · $host',
      body: bits.join(' · '),
    );
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _telem = null;
    _conn = null;
  }
}
