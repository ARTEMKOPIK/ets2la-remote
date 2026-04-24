import 'package:flutter_test/flutter_test.dart';
import 'package:ets2la_remote/models/connection_profile.dart';
import 'package:ets2la_remote/services/profile_qr_codec.dart';

void main() {
  group('ProfileQrCodec.encode', () {
    test('produces a valid ets2la://profile URL with required fields', () {
      const profile = ConnectionProfile(
        id: 'local-1',
        name: 'Home PC',
        host: '192.168.1.5',
      );
      final encoded = ProfileQrCodec.encode(profile);
      expect(encoded, startsWith('ets2la://profile'));
      // Dart's Uri.toString percent-encodes query params using + for
      // spaces (application/x-www-form-urlencoded), matching browser
      // URL bars and the decoder on the receiving end.
      expect(encoded, contains('name=Home+PC'));
      expect(encoded, contains('host=192.168.1.5'));
      expect(encoded, isNot(contains('mac=')));
    });

    test('includes mac when present', () {
      const profile = ConnectionProfile(
        id: 'x',
        name: 'Rig',
        host: '10.0.0.1',
        mac: 'AA:BB:CC:DD:EE:FF',
      );
      final encoded = ProfileQrCodec.encode(profile);
      expect(encoded, contains('mac=AA%3ABB%3ACC%3ADD%3AEE%3AFF'));
    });
  });

  group('ProfileQrCodec.decode', () {
    test('roundtrips a profile through encode/decode preserving host/mac/name',
        () {
      const original = ConnectionProfile(
        id: 'ignored',
        name: 'Работа',
        host: '172.16.0.42',
        mac: 'aa-bb-cc-dd-ee-ff',
      );
      final decoded = ProfileQrCodec.decode(ProfileQrCodec.encode(original));
      expect(decoded, isNotNull);
      expect(decoded!.name, 'Работа');
      expect(decoded.host, '172.16.0.42');
      expect(decoded.mac, 'aa-bb-cc-dd-ee-ff');
    });

    test('regenerates the id on import so the local DB gets a fresh row', () {
      final encoded = ProfileQrCodec.encode(const ConnectionProfile(
        id: 'source-id',
        name: 'N',
        host: '1.2.3.4',
      ));
      final first = ProfileQrCodec.decode(encoded);
      expect(first, isNotNull);
      expect(first!.id, isNot('source-id'));
    });

    test('rejects unknown schemes and hosts', () {
      expect(ProfileQrCodec.decode(''), isNull);
      expect(ProfileQrCodec.decode('not a uri'), isNull);
      expect(ProfileQrCodec.decode('https://example.com/?host=1.2.3.4'),
          isNull);
      expect(ProfileQrCodec.decode('ets2la://wifi?host=1.2.3.4'), isNull);
    });

    test('requires both name and host to be present', () {
      expect(
        ProfileQrCodec.decode('ets2la://profile?host=1.2.3.4'),
        isNull,
      );
      expect(
        ProfileQrCodec.decode('ets2la://profile?name=Foo'),
        isNull,
      );
    });

    test('drops malformed MAC but keeps the rest of the profile', () {
      final decoded = ProfileQrCodec.decode(
          'ets2la://profile?name=X&host=1.2.3.4&mac=not-a-mac');
      expect(decoded, isNotNull);
      expect(decoded!.host, '1.2.3.4');
      expect(decoded.mac, isNull);
    });
  });
}
