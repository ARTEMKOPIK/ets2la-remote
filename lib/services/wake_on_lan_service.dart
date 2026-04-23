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
  Future<bool> wake(String mac) async {
    final bytes = parseMac(mac);
    if (bytes == null) return false;
    final packet = _buildPacket(bytes);
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      // Subnet broadcast isn't reachable without knowing the netmask, so
      // we fall back on the limited broadcast address, which Android
      // routes onto the current Wi-Fi link.
      socket.send(packet, InternetAddress('255.255.255.255'), _port);
      return true;
    } catch (e) {
      debugPrint('WakeOnLanService.wake error: $e');
      return false;
    } finally {
      socket?.close();
    }
  }
}
