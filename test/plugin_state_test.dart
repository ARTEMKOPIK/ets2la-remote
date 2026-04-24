import 'package:flutter_test/flutter_test.dart';
import 'package:ets2la_remote/models/plugin_state.dart';

void main() {
  group('PluginInfo', () {
    test('fromJson parses valid plugin info', () {
      final info = PluginInfo.fromJson({
        'id': 'plugins.map',
        'name': 'Steering',
        'description': 'Basic steering control',
        'running': true,
        'tags': ['steering', 'essential'],
      });
      expect(info.id, 'plugins.map');
      expect(info.name, 'Steering');
      expect(info.description, 'Basic steering control');
      expect(info.running, true);
      expect(info.tags, ['steering', 'essential']);
    });

    test('fromJson handles missing optional fields with defaults', () {
      final info = PluginInfo.fromJson({
        'id': 'plugins.foo',
        'name': 'Foo',
      });
      expect(info.description, '');
      expect(info.running, false);
      expect(info.tags, isEmpty);
    });

    test('fromJson defaults missing id and name to empty string', () {
      final info = PluginInfo.fromJson({});
      expect(info.id, '');
      expect(info.name, '');
    });

    test('displayName returns known plugin names', () {
      expect(
        PluginInfo.fromJson({'id': 'plugins.map', 'name': 'X'}).displayName,
        'Steering (Map)',
      );
      expect(
        PluginInfo.fromJson({'id': 'plugins.adaptivecruisecontrol', 'name': 'X'})
            .displayName,
        'Adaptive Cruise Control',
      );
      expect(
        PluginInfo.fromJson({'id': 'plugins.collisionavoidance', 'name': 'X'})
            .displayName,
        'Collision Avoidance',
      );
      expect(
        PluginInfo.fromJson({'id': 'plugins.ar', 'name': 'X'}).displayName,
        'AR Overlay',
      );
      expect(
        PluginInfo.fromJson({'id': 'plugins.hud', 'name': 'X'}).displayName,
        'HUD',
      );
      expect(
        PluginInfo.fromJson({'id': 'plugins.tts', 'name': 'X'}).displayName,
        'Voice (TTS)',
      );
      expect(
        PluginInfo.fromJson({'id': 'plugins.eventlistener', 'name': 'X'})
            .displayName,
        'Event Listener',
      );
      expect(
        PluginInfo.fromJson({'id': 'plugins.discordrichpresence', 'name': 'X'})
            .displayName,
        'Discord Status',
      );
      expect(
        PluginInfo.fromJson({'id': 'plugins.visualizationsockets', 'name': 'X'})
            .displayName,
        'Visualization Server',
      );
      expect(
        PluginInfo.fromJson({'id': 'plugins.navigationsockets', 'name': 'X'})
            .displayName,
        'Navigation Server',
      );
    });

    test('displayName falls back to name for unknown plugins', () {
      final info = PluginInfo.fromJson({
        'id': 'plugins.unknown',
        'name': 'Custom Plugin',
      });
      expect(info.displayName, 'Custom Plugin');
    });

    test('iconEmoji returns known emojis', () {
      expect(
        PluginInfo.fromJson({'id': 'plugins.map', 'name': 'X'}).iconEmoji,
        '🛣️',
      );
      expect(
        PluginInfo.fromJson({'id': 'plugins.adaptivecruisecontrol', 'name': 'X'})
            .iconEmoji,
        '🚀',
      );
      expect(
        PluginInfo.fromJson({'id': 'plugins.collisionavoidance', 'name': 'X'})
            .iconEmoji,
        '🛡️',
      );
      expect(
        PluginInfo.fromJson({'id': 'plugins.ar', 'name': 'X'}).iconEmoji,
        '👁️',
      );
      expect(
        PluginInfo.fromJson({'id': 'plugins.hud', 'name': 'X'}).iconEmoji,
        '📊',
      );
      expect(
        PluginInfo.fromJson({'id': 'plugins.tts', 'name': 'X'}).iconEmoji,
        '🔊',
      );
      expect(
        PluginInfo.fromJson({'id': 'plugins.eventlistener', 'name': 'X'})
            .iconEmoji,
        '📡',
      );
      expect(
        PluginInfo.fromJson({'id': 'plugins.discordrichpresence', 'name': 'X'})
            .iconEmoji,
        '💬',
      );
      expect(
        PluginInfo.fromJson({'id': 'plugins.visualizationsockets', 'name': 'X'})
            .iconEmoji,
        '📺',
      );
      expect(
        PluginInfo.fromJson({'id': 'plugins.navigationsockets', 'name': 'X'})
            .iconEmoji,
        '🗺️',
      );
    });

    test('iconEmoji returns default emoji for unknown plugins', () {
      final info = PluginInfo.fromJson({
        'id': 'plugins.something',
        'name': 'X',
      });
      expect(info.iconEmoji, '🔌');
    });

    test('constructor accepts all fields', () {
      const info = PluginInfo(
        id: 'plugins.test',
        name: 'Test Plugin',
        description: 'Test description',
        running: true,
        tags: ['tag1', 'tag2'],
      );
      expect(info.id, 'plugins.test');
      expect(info.name, 'Test Plugin');
      expect(info.description, 'Test description');
      expect(info.running, true);
      expect(info.tags, ['tag1', 'tag2']);
    });
  });
}