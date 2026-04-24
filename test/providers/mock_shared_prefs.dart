import 'package:flutter_test/flutter_test.dart';

/// Map-backed SharedPreferences mock for use in provider unit tests.
///
/// Usage:
///   SharedPreferences.setMockInitialValues({'key': 'value'});
///   // then in setUp:
///   provider._prefs = await SharedPreferences.getInstance();
///
/// For more granular control, use [MockSharedPreferences] directly.
class MockSharedPreferences {
  final Map<String, Object?> _store;

  MockSharedPreferences([Map<String, Object?>? initial])
      : _store = Map.from(initial ?? {});

  // ── bool ────────────────────────────────────────────────────────────────
  bool? getBool(String key) => _store[key] as bool?;
  Future<void> setBool(String key, bool value) async {
    _store[key] = value;
  }

  // ── int ─────────────────────────────────────────────────────────────────
  int? getInt(String key) => _store[key] as int?;
  Future<void> setInt(String key, int value) async {
    _store[key] = value;
  }

  // ── String ───────────────────────────────────────────────────────────────
  String? getString(String key) => _store[key] as String?;
  Future<void> setString(String key, String value) async {
    _store[key] = value;
  }

  // ── List<String> ──────────────────────────────────────────────────────────
  List<String>? getStringList(String key) {
    final raw = _store[key];
    if (raw == null) return null;
    if (raw is List) return raw.cast<String>();
    return null;
  }

  Future<void> setStringList(String key, List<String> value) async {
    _store[key] = value;
  }

  // ── misc ─────────────────────────────────────────────────────────────────
  Future<void> remove(String key) async {
    _store.remove(key);
  }

  Future<void> clear() async {
    _store.clear();
  }
}