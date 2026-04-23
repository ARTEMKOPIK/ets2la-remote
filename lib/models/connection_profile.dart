import 'dart:convert';

/// User-named connection target stored in SharedPreferences. Extends
/// the old `recent_hosts` idea with a human-readable label and an
/// optional MAC address (used by Wake-on-LAN; safe to leave empty).
class ConnectionProfile {
  final String id;
  final String name;
  final String host;
  final String? mac;

  const ConnectionProfile({
    required this.id,
    required this.name,
    required this.host,
    this.mac,
  });

  ConnectionProfile copyWith({
    String? name,
    String? host,
    String? mac,
  }) {
    return ConnectionProfile(
      id: id,
      name: name ?? this.name,
      host: host ?? this.host,
      mac: mac ?? this.mac,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        if (mac != null && mac!.isNotEmpty) 'mac': mac,
      };

  static ConnectionProfile? fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final name = json['name'] as String?;
    final host = json['host'] as String?;
    if (id == null || name == null || host == null) return null;
    return ConnectionProfile(
      id: id,
      name: name,
      host: host,
      mac: json['mac'] as String?,
    );
  }

  static String encodeAll(List<ConnectionProfile> list) =>
      jsonEncode(list.map((p) => p.toJson()).toList());

  static List<ConnectionProfile> decodeAll(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final data = jsonDecode(raw);
      if (data is! List) return const [];
      final result = <ConnectionProfile>[];
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final p = ConnectionProfile.fromJson(item);
          if (p != null) result.add(p);
        }
      }
      return result;
    } catch (_) {
      return const [];
    }
  }
}
