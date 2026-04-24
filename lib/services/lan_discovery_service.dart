/// LAN discovery of ETS2LA backends via mDNS.
///
/// ETS2LA advertises itself as `ETS2LA._http._tcp.local` on port 37520 (see
/// `ETS2LA/Networking/Servers/discovery.py` in the upstream project), so a
/// single PTR → SRV → A resolution is enough to find every instance on the
/// LAN.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:multicast_dns/multicast_dns.dart';

class DiscoveredHost {
  DiscoveredHost({
    required this.instance,
    required this.host,
    required this.address,
    required this.port,
  });

  /// mDNS instance name, e.g. "ETS2LA".
  final String instance;

  /// Advertised hostname, e.g. "ets2la.local".
  final String host;

  /// Resolved IPv4 address.
  final String address;

  final int port;

  @override
  bool operator ==(Object other) =>
      other is DiscoveredHost &&
      other.address == address &&
      other.port == port;

  @override
  int get hashCode => Object.hash(address, port);
}

class LanDiscoveryService {
  LanDiscoveryService({MDnsClient? client}) : _client = client ?? MDnsClient();

  static const String serviceType = '_http._tcp.local';
  static const String instancePrefix = 'ETS2LA';

  static const MethodChannel _multicastLock =
      MethodChannel('ets2la_remote/multicast_lock');

  final MDnsClient _client;
  bool _started = false;

  Future<void> _start() async {
    if (_started) return;
    try {
      await _multicastLock.invokeMethod<void>('acquire');
    } on MissingPluginException {
      // Non-Android or native channel not wired — mDNS may still work, fall through.
    } on PlatformException {
      // Ignore; best effort.
    }
    await _client.start();
    _started = true;
  }

  Future<void> stop() async {
    if (!_started) return;
    _client.stop();
    _started = false;
    try {
      await _multicastLock.invokeMethod<void>('release');
    } on MissingPluginException {
      // ignore — non-Android platform or native channel unavailable
    } on PlatformException {
      // ignore — best effort, mDNS may still work without the lock
    }
  }

  /// Scan the LAN for ETS2LA instances for up to [timeout]. Returns the
  /// de-duplicated list of hosts found.
  Future<List<DiscoveredHost>> scan({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    await _start();
    final seen = <String, DiscoveredHost>{};
    try {
      final ptrStream = _client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(serviceType),
        timeout: timeout,
      );
      await for (final ptr in ptrStream) {
        if (!ptr.domainName.startsWith(instancePrefix)) continue;
        await for (final srv in _client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
          timeout: timeout,
        )) {
          await for (final ip in _client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target),
            timeout: timeout,
          )) {
            if (ip.address.type != InternetAddressType.IPv4) continue;
            final host = DiscoveredHost(
              instance: _stripSuffix(ptr.domainName),
              host: srv.target,
              address: ip.address.address,
              port: srv.port,
            );
            seen['${host.address}:${host.port}'] = host;
          }
        }
      }
    } on SocketException {
      // mDNS socket may fail on restricted networks; return whatever we have.
    } finally {
      await stop();
    }
    return seen.values.toList(growable: false);
  }

  static String _stripSuffix(String name) {
    const suffix = '.$serviceType';
    if (name.endsWith(suffix)) return name.substring(0, name.length - suffix.length);
    if (name.endsWith('$suffix.')) return name.substring(0, name.length - suffix.length - 1);
    return name;
  }
}
