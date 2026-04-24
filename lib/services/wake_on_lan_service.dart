import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;

/// Sends a Wake-on-LAN magic packet to a given MAC address so a sleeping
/// PC on the LAN can be woken before we try to connect. Intentionally
/// fire-and-forget: the caller waits a couple of seconds and then
/// attempts the usual ping/WS handshake.
class WakeOnLanService {
  WakeOnLanService._();
  static final WakeOnLanService instance = WakeOnLanService._();

  /// WOL uses UDP port 9 (Discard) with broadcast; 7 (Echo) is also common.
  static const int _port = 9;

  /// Parse `AA:BB:CC:11:22:33` or `aa-bb-cc-11-22-33` or `aabbcc112233`
  /// into six bytes. Returns null if the input isn't a valid MAC.
  static Uint8List? parseMac(String mac) {
    final cleaned = mac.replaceAll(RegExp(r'[:\-\s]'), '').toLowerCase();
    if (cleaned.length != 12) return null;
    if (!RegExp(r'^[0-9a-f]{12}$').hasMatch(cleaned)) return null;
    final out = Uint8List(6);
    for (var i = 0; i < 6; i++) {
      out[i] = int.parse(cleaned.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  /// True when [mac] can be parsed. Convenience for form validators.
  static bool isValidMac(String mac) => parseMac(mac) != null;

  /// Build the 102-byte magic packet: six 0xFF bytes followed by the MAC
  /// repeated 16 times.
  static Uint8List _buildPacket(Uint8List mac) {
    final packet = Uint8List(6 + 16 * 6);
    for (var i = 0; i < 6; i++) {
      packet[i] = 0xFF;
    }
    for (var i = 0; i < 16; i++) {
      packet.setRange(6 + i * 6, 6 + (i + 1) * 6, mac);
    }
    return packet;
  }

  /// Send a magic packet. Swallows network errors and returns false so a
  /// failed broadcast doesn't block the subsequent connect attempt.
  ///
  /// Sends to both the limited broadcast address (255.255.255.255) and
  /// every IPv4 interface's directed broadcast derived from `x.y.z.255`.
  /// Routers regularly drop limited-broadcast frames on Wi-Fi, so the
  /// per-interface directed broadcasts are what actually reaches most
  /// sleeping PCs in practice.
  Future<bool> wake(String mac) async {
    final bytes = parseMac(mac);
    if (bytes == null) return false;
    final packet = _buildPacket(bytes);
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      final targets = <String>{'255.255.255.255'};
      for (final addr in await _localBroadcastAddresses()) {
        targets.add(addr);
      }
      var anySent = false;
      for (final target in targets) {
        try {
          socket.send(packet, InternetAddress(target), _port);
          anySent = true;
        } catch (e) {
          debugPrint('WakeOnLanService.wake $target error: $e');
        }
      }
      return anySent;
    } catch (e) {
      debugPrint('WakeOnLanService.wake error: $e');
      return false;
    } finally {
      socket?.close();
    }
  }

  /// Enumerate IPv4 interfaces and derive a `/24` directed broadcast for
  /// each (`a.b.c.x` → `a.b.c.255`). This is a pragmatic heuristic: for
  /// the overwhelmingly common home-network case where the phone lives in
  /// the same `/24` as the PC, directed broadcast is what actually wakes
  /// it. Loopback is skipped.
  Future<List<String>> _localBroadcastAddresses() async {
    try {
      final ifaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );
      final out = <String>[];
      for (final iface in ifaces) {
        for (final addr in iface.addresses) {
          final parts = addr.address.split('.');
          if (parts.length != 4) continue;
          out.add('${parts[0]}.${parts[1]}.${parts[2]}.255');
        }
      }
      return out;
    } catch (e) {
      debugPrint('WakeOnLanService interface enumeration failed: $e');
      return const [];
    }
  }
}
