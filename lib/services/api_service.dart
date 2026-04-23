import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../models/plugin_state.dart';

class ApiService {
  int _port = 37520; // Default, can be overridden
  int _timeoutSeconds = 5;

  void setPort(int port) => _port = port;

  int get port => _port;

  /// User-configurable request timeout (in seconds). Applied to all HTTP
  /// requests. Clamped to a sensible range to avoid hanging the UI forever.
  void setTimeoutSeconds(int seconds) {
    _timeoutSeconds = seconds.clamp(1, 60);
  }

  int get timeoutSeconds => _timeoutSeconds;
  Duration get _timeout => Duration(seconds: _timeoutSeconds);
  // Ping uses a shorter timeout so the "cannot reach server" feedback is quick.
  Duration get _pingTimeout =>
      Duration(seconds: _timeoutSeconds > 3 ? 3 : _timeoutSeconds);

  String? _host;

  void setHost(String host) => _host = host;

  String get _base => _host != null ? 'http://$_host:$port' : '';

  bool get hasHost => _host != null && _host!.isNotEmpty;

  Future<bool> ping() async {
    if (!hasHost) return false;
    try {
      final res = await http.get(Uri.parse('$_base/')).timeout(_pingTimeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<PluginInfo>> getPlugins() async {
    if (!hasHost) return [];
    try {
      final res = await http
          .get(Uri.parse('$_base/backend/plugins'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // API returns a Map<pluginId, {description, enabled, ...}>
        if (data is Map<String, dynamic>) {
          return data.entries.map((e) {
            final id = e.key;
            final val = e.value as Map<String, dynamic>;
            final desc = val['description'] as Map<String, dynamic>? ?? {};
            return PluginInfo(
              id: id,
              name: (desc['name'] as String?) ?? id,
              description: (desc['description'] as String?) ?? '',
              running: val['enabled'] as bool? ?? false,
              tags: List<String>.from(desc['tags'] ?? []),
            );
          }).toList();
        }
      }
    } catch (e) { debugPrint('ApiService.getPlugins error: $e'); return []; }
    return [];
  }

  /// Enable plugin by its exact description.name (as returned from /backend/plugins)
  Future<bool> enablePluginByName(String name) => enablePlugin(name);

  /// Disable plugin by its exact description.name
  Future<bool> disablePluginByName(String name) => disablePlugin(name);

  Future<bool> enablePlugin(String name) async {
    if (!hasHost) return false;
    try {
      final res = await http
          .get(Uri.parse('$_base/backend/plugins/$name/enable'))
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (e) { debugPrint('ApiService.enablePlugin error: $e'); return false; }
  }

  Future<bool> disablePlugin(String name) async {
    if (!hasHost) return false;
    try {
      final res = await http
          .get(Uri.parse('$_base/backend/plugins/$name/disable'))
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (e) { debugPrint('ApiService.disablePlugin error: $e'); return false; }
  }

  Future<Map<String, dynamic>> getPluginStates() async {
    if (!hasHost) return <String, dynamic>{};
    try {
      final res = await http
          .get(Uri.parse('$_base/backend/plugins/states'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) { debugPrint('ApiService.getPluginStates error: $e'); return <String, dynamic>{}; }
    return <String, dynamic>{};
  }

  Future<dynamic> getTag(String tag) async {
    if (!hasHost) return null;
    try {
      final res = await http
          .get(Uri.parse('$_base/api/tags/$tag'))
          .timeout(_pingTimeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) { debugPrint('ApiService.getTag error: $e'); return null; }
    return null;
  }
}
