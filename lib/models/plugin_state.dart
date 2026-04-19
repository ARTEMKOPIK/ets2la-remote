class PluginInfo {
  final String id;
  final String name;
  final String description;
  final bool running;
  final List<String> tags;

  const PluginInfo({
    required this.id,
    required this.name,
    this.description = '',
    this.running = false,
    this.tags = const [],
  });

  factory PluginInfo.fromJson(Map<String, dynamic> json) {
    return PluginInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      running: json['running'] as bool? ?? false,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  String get displayName {
    switch (id) {
      case 'plugins.map': return 'Steering (Map)';
      case 'plugins.adaptivecruisecontrol': return 'Adaptive Cruise Control';
      case 'plugins.collisionavoidance': return 'Collision Avoidance';
      case 'plugins.ar': return 'AR Overlay';
      case 'plugins.hud': return 'HUD';
      case 'plugins.tts': return 'Voice (TTS)';
      case 'plugins.eventlistener': return 'Event Listener';
      case 'plugins.discordrichpresence': return 'Discord Status';
      case 'plugins.visualizationsockets': return 'Visualization Server';
      case 'plugins.navigationsockets': return 'Navigation Server';
      default: return name;
    }
  }

  String get iconEmoji {
    switch (id) {
      case 'plugins.map': return '🛣️';
      case 'plugins.adaptivecruisecontrol': return '🚀';
      case 'plugins.collisionavoidance': return '🛡️';
      case 'plugins.ar': return '👁️';
      case 'plugins.hud': return '📊';
      case 'plugins.tts': return '🔊';
      case 'plugins.eventlistener': return '📡';
      case 'plugins.discordrichpresence': return '💬';
      case 'plugins.visualizationsockets': return '📺';
      case 'plugins.navigationsockets': return '🗺️';
      default: return '🔌';
    }
  }
}
