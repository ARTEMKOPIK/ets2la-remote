/// Compact encoder/decoder for sharing a [ConnectionProfile] via QR.
///
/// Rather than shove the raw `toJson` Map into the QR, we use a URL-style
/// format so a QR scanned in any other app (Android's native camera,
/// Google Lens, third-party) still lands the user on a link that the OS
/// can hand back to ETS2LA Remote via the custom scheme. Only name, host
/// and optional MAC are encoded — id and `favourite` are local-only
/// concerns we regenerate on import.

import '../models/connection_profile.dart';

class ProfileQrCodec {
  static const String scheme = 'ets2la';
  static const String host = 'profile';
  static const int _maxFieldLength = 253;

  /// MAC addresses in the classic AA:BB:CC:DD:EE:FF / AA-BB-…/ aa:bb:… form.
  /// Used to sanity-check incoming QR payloads — a malformed MAC would
  /// otherwise sit on the profile and silently break Wake-on-LAN later.
  static final RegExp _macRegex =
      RegExp(r'^[0-9A-Fa-f]{2}([:\-][0-9A-Fa-f]{2}){5}$');

  /// Build the shareable URI. Example:
  ///   ets2la://profile?name=Home%20PC&host=192.168.1.5&mac=AA:BB:…
  static String encode(ConnectionProfile profile) {
    final params = <String, String>{
      'name': profile.name,
      'host': profile.host,
      if (profile.mac != null && profile.mac!.isNotEmpty) 'mac': profile.mac!,
    };
    final uri = Uri(
      scheme: scheme,
      host: host,
      queryParameters: params,
    );
    return uri.toString();
  }

  /// Parse a shared string back into a [ConnectionProfile]. Returns null
  /// when the input doesn't match our scheme, so the scan screen can
  /// gracefully reject random QR codes (Wi-Fi configs, vCards, …)
  /// instead of crashing.
  static ConnectionProfile? decode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    if (uri.scheme != scheme) return null;
    if (uri.host != host) return null;

    final name = uri.queryParameters['name']?.trim() ?? '';
    final hostValue = uri.queryParameters['host']?.trim() ?? '';
    final mac = uri.queryParameters['mac']?.trim();
    if (name.isEmpty || hostValue.isEmpty) return null;
    if (name.length > _maxFieldLength || hostValue.length > _maxFieldLength) {
      return null;
    }

    // Silently drop a malformed MAC rather than reject the whole QR —
    // the name + host part is still useful and the user can re-enter
    // the MAC by hand if they need Wake-on-LAN.
    final sanitisedMac =
        (mac != null && mac.isNotEmpty && _macRegex.hasMatch(mac)) ? mac : null;

    return ConnectionProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      host: hostValue,
      mac: sanitisedMac,
    );
  }
}
