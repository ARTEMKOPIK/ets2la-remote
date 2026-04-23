import 'dart:async';
import 'dart:io';

/// Best-effort detection of an active VPN-style interface on the device.
///
/// We don't have access to the framework-level `VpnService` API from plain
/// Dart, so we enumerate the network interfaces and look for names that
/// are conventionally used by VPN software:
///
/// * `tun*`  — generic TUN/TAP devices (OpenVPN, Wireguard on some OEMs)
/// * `ppp*`  — Point-to-Point Protocol (L2TP/PPTP, cellular PPP)
/// * `wg*`   — Wireguard
/// * `utun*` — macOS/iOS userspace tunnels (rare on Android but harmless)
///
/// Interfaces without an IPv4 address are ignored — a tunnel that isn't
/// actually carrying traffic shouldn't trigger the warning banner.
class VpnDetector {
  VpnDetector._();

  static final VpnDetector instance = VpnDetector._();

  static final RegExp _vpnNamePattern =
      RegExp(r'^(tun|ppp|wg|utun)\d*', caseSensitive: false);

  Future<bool> isVpnActive() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        if (_vpnNamePattern.hasMatch(iface.name) && iface.addresses.isNotEmpty) {
          return true;
        }
      }
      return false;
    } on Object {
      // Some Android OEMs deny NetworkInterface.list() on a background
      // isolate or in foreground-service contexts — treat it as "unknown"
      // and don't scare the user with a VPN banner.
      return false;
    }
  }
}
