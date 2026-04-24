/// Probe individual ETS2LA ports to find out exactly which one is being
/// blocked by a firewall or misconfigured in ETS2LA. Used by both:
///
///   * [SmartLanScan] — to attach per-port green/red dots to each
///     mDNS-discovered host on the Connect screen.
///   * [ConnectionDoctorScreen] — to walk the user through a single
///     host's ports sequentially after a failed connect.
///
/// The probe is a plain TCP connect with a short timeout. We don't
/// actually speak HTTP or WebSocket — a successful TCP handshake proves
/// the port is reachable and something is listening, which is all we
/// need to distinguish "firewall blocked" from "ETS2LA not running".

import 'dart:async';
import 'dart:io';

enum ProbeResult { unknown, reachable, blocked }

class PortReport {
  PortReport({
    required this.port,
    required this.result,
    this.elapsed,
    this.error,
  });
  final int port;
  final ProbeResult result;
  final Duration? elapsed;
  final String? error;
}

class PortProbeService {
  static const Duration _timeout = Duration(milliseconds: 1500);

  /// Try to open a TCP connection to [host]:[port]. Returns a
  /// [PortReport] with `reachable` on handshake success, `blocked`
  /// on timeout or socket error.
  static Future<PortReport> probe(String host, int port) async {
    final started = DateTime.now();
    // Defensive trim: the doctor screen passes raw TextField input and
    // a stray trailing space turns a valid `192.168.1.5 ` into a host
    // lookup failure. Socket.connect itself doesn't trim.
    final target = host.trim();
    if (target.isEmpty) {
      return PortReport(
        port: port,
        result: ProbeResult.blocked,
        elapsed: Duration.zero,
        error: 'empty host',
      );
    }
    try {
      final socket = await Socket.connect(target, port, timeout: _timeout);
      final elapsed = DateTime.now().difference(started);
      socket.destroy();
      return PortReport(
        port: port,
        result: ProbeResult.reachable,
        elapsed: elapsed,
      );
    } on SocketException catch (e) {
      return PortReport(
        port: port,
        result: ProbeResult.blocked,
        elapsed: DateTime.now().difference(started),
        error: e.message,
      );
    } on TimeoutException {
      return PortReport(
        port: port,
        result: ProbeResult.blocked,
        elapsed: DateTime.now().difference(started),
        error: 'timeout',
      );
    } catch (e) {
      // Unexpected errors (OSError variants on some Androids, async
      // argument errors from odd host strings) must not leak out —
      // this probe runs as part of a larger scan loop that would
      // abort entirely on a bubbled-up exception.
      return PortReport(
        port: port,
        result: ProbeResult.blocked,
        elapsed: DateTime.now().difference(started),
        error: e.toString(),
      );
    }
  }

  /// Probe every port in [ports] in parallel. Use this for the
  /// "smart LAN-scan" card list where the user wants a quick at-a-glance
  /// dot-matrix — serial probes would multiply the latency by N.
  static Future<List<PortReport>> probeAllParallel(
    String host,
    List<int> ports,
  ) {
    return Future.wait([for (final p in ports) probe(host, p)]);
  }
}
