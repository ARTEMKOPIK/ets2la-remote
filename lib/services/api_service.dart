import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/plugin_state.dart';

class ApiService {
  static const int port = 37520;

  String? _host;

  void setHost(String host) => _host = host;

  String get _base => 'http://$_host:$port';

  Future<bool> ping() async {
    try {
      final res = await http.get(Uri.parse('$_base/')).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<PluginInfo>> getPlugins() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/backend/plugins'))
          .timeout(const Duration(seconds: 5));
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
    } catch (_) {}
    return [];
  }

  /// Enable plugin by its exact description.name (as returned from /backend/plugins)
  Future<bool> enablePluginByName(String name) => enablePlugin(name);

  /// Disable plugin by its exact description.name
  Future<bool> disablePluginByName(String name) => disablePlugin(name);

  /// Legacy: enable by id — uses folder-based fallback
  Future<bool> enablePluginById(String id) {
    final name = _idToFolderName(id);
    return enablePlugin(name);
  }

  Future<bool> disablePluginById(String id) {
    final name = _idToFolderName(id);
    return disablePlugin(name);
  }

  String _idToFolderName(String id) {
    // Derive the folder name portion: "plugins.adaptivecruisecontrol" -> "AdaptiveCruiseControl"
    const map = {
      'map': 'Map',
      'adaptivecruisecontrol': 'AdaptiveCruiseControl',
      'collisionavoidance': 'CollisionAvoidance',
      'ar': 'AR',
      'hud': 'HUD',
      'tts': 'TTS',
      'eventlistener': 'EventListener',
      'discordrichpresence': 'DiscordRichPresence',
      'visualizationsockets': 'VisualizationSockets',
      'navigationsockets': 'NavigationSockets',
    };
    final raw = id.split('.').last;
    return map[raw] ?? raw;
  }

  Future<bool> enablePlugin(String name) async {
    try {
      final res = await http
          .get(Uri.parse('$_base/backend/plugins/$name/enable'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> disablePlugin(String name) async {
    try {
      final res = await http
          .get(Uri.parse('$_base/backend/plugins/$name/disable'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getPluginStates() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/backend/plugins/states'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }

  Future<dynamic> getTag(String tag) async {
    try {
      final res = await http
          .get(Uri.parse('$_base/api/tags/$tag'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }
}
