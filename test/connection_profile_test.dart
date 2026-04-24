import 'package:flutter_test/flutter_test.dart';
import 'package:ets2la_remote/models/connection_profile.dart';

void main() {
  group('ConnectionProfile', () {
    test('toJson produces expected map with required fields', () {
      const profile = ConnectionProfile(
        id: 'test-id',
        name: 'Test PC',
        host: '192.168.1.100',
      );
      final json = profile.toJson();
      expect(json['id'], 'test-id');
      expect(json['name'], 'Test PC');
      expect(json['host'], '192.168.1.100');
      expect(json.containsKey('mac'), false);
      expect(json.containsKey('favourite'), false);
    });

    test('toJson includes optional mac when present', () {
      const profile = ConnectionProfile(
        id: 'id',
        name: 'Name',
        host: '1.2.3.4',
        mac: 'AA:BB:CC:DD:EE:FF',
      );
      final json = profile.toJson();
      expect(json['mac'], 'AA:BB:CC:DD:EE:FF');
    });

    test('toJson omits empty mac', () {
      const profile = ConnectionProfile(
        id: 'id',
        name: 'Name',
        host: '1.2.3.4',
        mac: '',
      );
      final json = profile.toJson();
      expect(json.containsKey('mac'), false);
    });

    test('toJson includes favourite when true', () {
      const profile = ConnectionProfile(
        id: 'id',
        name: 'Name',
        host: '1.2.3.4',
        favourite: true,
      );
      final json = profile.toJson();
      expect(json['favourite'], true);
    });

    test('toJson omits favourite when false', () {
      const profile = ConnectionProfile(
        id: 'id',
        name: 'Name',
        host: '1.2.3.4',
        favourite: false,
      );
      final json = profile.toJson();
      expect(json.containsKey('favourite'), false);
    });

    test('fromJson parses valid profile', () {
      final profile = ConnectionProfile.fromJson({
        'id': 'my-id',
        'name': 'My PC',
        'host': '10.0.0.5',
      });
      expect(profile, isNotNull);
      expect(profile!.id, 'my-id');
      expect(profile.name, 'My PC');
      expect(profile.host, '10.0.0.5');
    });

    test('fromJson handles missing optional fields', () {
      final profile = ConnectionProfile.fromJson({
        'id': 'id',
        'name': 'Name',
        'host': '1.2.3.4',
        'mac': 'aa:bb:cc:dd:ee:ff',
        'favourite': true,
      });
      expect(profile!.mac, 'aa:bb:cc:dd:ee:ff');
      expect(profile.favourite, true);
    });

    test('fromJson defaults favourite to false', () {
      final profile = ConnectionProfile.fromJson({
        'id': 'id',
        'name': 'Name',
        'host': '1.2.3.4',
      });
      expect(profile!.favourite, false);
    });

    test('fromJson returns null when id missing', () {
      final profile = ConnectionProfile.fromJson({
        'name': 'Name',
        'host': '1.2.3.4',
      });
      expect(profile, isNull);
    });

    test('fromJson returns null when name missing', () {
      final profile = ConnectionProfile.fromJson({
        'id': 'id',
        'host': '1.2.3.4',
      });
      expect(profile, isNull);
    });

    test('fromJson returns null when host missing', () {
      final profile = ConnectionProfile.fromJson({
        'id': 'id',
        'name': 'Name',
      });
      expect(profile, isNull);
    });

    test('copyWith creates new profile with modified fields', () {
      const original = ConnectionProfile(
        id: 'id',
        name: 'Original',
        host: '1.2.3.4',
      );
      final modified = original.copyWith(name: 'Modified', favourite: true);
      expect(modified.id, 'id');
      expect(modified.name, 'Modified');
      expect(modified.host, '1.2.3.4');
      expect(modified.favourite, true);
    });

    test('encodeAll serializes list of profiles to JSON string', () {
      const profiles = [
        ConnectionProfile(id: '1', name: 'A', host: '1.2.3.4'),
        ConnectionProfile(id: '2', name: 'B', host: '5.6.7.8'),
      ];
      final encoded = ConnectionProfile.encodeAll(profiles);
      expect(encoded, contains('"id":"1"'));
      expect(encoded, contains('"id":"2"'));
    });

    test('decodeAll parses JSON string to list of profiles', () {
      const profiles = [
        ConnectionProfile(id: '1', name: 'A', host: '1.2.3.4'),
        ConnectionProfile(id: '2', name: 'B', host: '5.6.7.8'),
      ];
      final encoded = ConnectionProfile.encodeAll(profiles);
      final decoded = ConnectionProfile.decodeAll(encoded);
      expect(decoded.length, 2);
      expect(decoded[0].id, '1');
      expect(decoded[1].id, '2');
    });

    test('decodeAll returns empty list for null input', () {
      final decoded = ConnectionProfile.decodeAll(null);
      expect(decoded, isEmpty);
    });

    test('decodeAll returns empty list for empty string', () {
      final decoded = ConnectionProfile.decodeAll('');
      expect(decoded, isEmpty);
    });

    test('decodeAll returns empty list for invalid JSON', () {
      final decoded = ConnectionProfile.decodeAll('not json');
      expect(decoded, isEmpty);
    });

    test('decodeAll returns empty list when data is not a list', () {
      final decoded = ConnectionProfile.decodeAll('{"id": "x"}');
      expect(decoded, isEmpty);
    });

    test('decodeAll skips malformed entries', () {
      final encoded =
          '[{"id": "1", "name": "A", "host": "1.2.3.4"}, {"name": "B", "host": "5.6.7.8"}]';
      // First entry is malformed (missing "id"), second is well-formed
      final decoded = ConnectionProfile.decodeAll(encoded);
      expect(decoded.length, 1);
      expect(decoded[0].name, 'B');
    });
  });
}