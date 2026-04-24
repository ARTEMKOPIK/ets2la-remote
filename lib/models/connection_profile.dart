import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

/// User-named connection target stored in SharedPreferences. Extends
/// the old `recent_hosts` idea with a human-readable label and an
/// optional MAC address (used by Wake-on-LAN; safe to leave empty).
class ConnectionProfile {
  final String id;
  final String name;
  final String host;
  final String? mac;

  /// User-marked favourite. When `autoConnect` is enabled the favourite
  /// profile is tried first (falling back to the most recent host if no
  /// profile is starred). Only one profile should be favourite at a
  /// time — the provider enforces this on write.
  final bool favourite;

  const ConnectionProfile({
    required this.id,
    required this.name,
    required this.host,
    this.mac,
    this.favourite = false,
  });

  ConnectionProfile copyWith({
    String? name,
    String? host,
    String? mac,
    bool? favourite,
  }) {
    return ConnectionProfile(
      id: id,
      name: name ?? this.name,
      host: host ?? this.host,
      mac: mac ?? this.mac,
      favourite: favourite ?? this.favourite,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        if (mac != null && mac!.isNotEmpty) 'mac': mac,
        if (favourite) 'favourite': true,
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
      favourite: (json['favourite'] as bool?) ?? false,
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
    } catch (e, st) {
      debugPrint('ConnectionProfile.decodeAll failed: $e');
      return const [];
    }
  }
}
