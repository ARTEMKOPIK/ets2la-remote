import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../models/plugin_state.dart';

/// Thin HTTP client for the ETS2LA REST endpoint (default port 37520).
///
/// Plugin identifiers and tag keys are treated as opaque strings the user
/// never types themselves, but the backend happily hands us names with
/// spaces, slashes, or Cyrillic characters — so every URL is built with
/// [Uri.http] so path segments are encoded correctly. A previous
/// implementation interpolated the name straight into a string URL and
/// produced invalid requests for anything beyond ASCII identifiers.
class ApiService {
  int _port = 37520;
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

  bool get hasHost => _host != null && _host!.isNotEmpty;

  /// Build an `http://host:port/<segments>` URI that copes with IPv6
  /// literals. `Uri.parse('http://2001:db8::1:37520/')` is ambiguous —
  /// the `Uri` constructor handles bracketing correctly.
  Uri _build(List<String> segments) => Uri(
        scheme: 'http',
        host: _host,
        port: port,
        pathSegments: segments,
      );

  Future<bool> ping() async {
    if (!hasHost) return false;
    try {
      final res = await http.get(_build(const [])).timeout(_pingTimeout);
      return res.statusCode == 200;
    } catch (e, st) {
      debugPrint('ApiService.ping failed: $e\n$st');
      return false;
    }
  }

  Future<List<PluginInfo>> getPlugins() async {
    if (!hasHost) return [];
    try {
      final res = await http
          .get(_build(const ['backend', 'plugins']))
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
              tags: _parseTags(desc['tags']),
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('ApiService.getPlugins error: $e');
      return [];
    }
    return [];
  }

  /// Safely coerce a JSON `tags` value to a `List<String>`. The backend
  /// sometimes omits the field entirely or (rarely) hands us a non-list;
  /// we don't want a malformed payload to crash the whole plugin refresh.
  List<String> _parseTags(Object? raw) {
    if (raw is List) {
      return raw.whereType<String>().toList(growable: false);
    }
    return const <String>[];
  }

  /// Enable plugin by its exact description.name (as returned from /backend/plugins)
  Future<bool> enablePluginByName(String name) => enablePlugin(name);

  /// Disable plugin by its exact description.name
  Future<bool> disablePluginByName(String name) => disablePlugin(name);

  Future<bool> enablePlugin(String name) async {
    if (!hasHost) return false;
    try {
      final res = await http
          .get(_pluginAction(name, 'enable'))
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.enablePlugin error: $e');
      return false;
    }
  }

  Future<bool> disablePlugin(String name) async {
    if (!hasHost) return false;
    try {
      final res = await http
          .get(_pluginAction(name, 'disable'))
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.disablePlugin error: $e');
      return false;
    }
  }

  /// `/backend/plugins/{name}/{action}` with [name] properly percent-encoded.
  Uri _pluginAction(String name, String action) {
    return Uri(
      scheme: 'http',
      host: _host,
      port: port,
      pathSegments: ['backend', 'plugins', name, action],
    );
  }

  Future<Map<String, dynamic>> getPluginStates() async {
    if (!hasHost) return <String, dynamic>{};
    try {
      final res = await http
          .get(_build(const ['backend', 'plugins', 'states']))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiService.getPluginStates error: $e');
      return <String, dynamic>{};
    }
    return <String, dynamic>{};
  }

  Future<dynamic> getTag(String tag) async {
    if (!hasHost) return null;
    try {
      final url = Uri(
        scheme: 'http',
        host: _host,
        port: port,
        pathSegments: ['api', 'tags', tag],
      );
      final res = await http.get(url).timeout(_pingTimeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('ApiService.getTag error: $e');
      return null;
    }
    return null;
  }
}
