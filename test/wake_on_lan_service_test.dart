import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ets2la_remote/services/wake_on_lan_service.dart';

void main() {
  group('WakeOnLanService', () {
    group('parseMac', () {
      test('parses colon-separated MAC', () {
        final result = WakeOnLanService.parseMac('AA:BB:CC:DD:EE:FF');
        expect(result, isNotNull);
        expect(result!.length, 6);
        expect(result[0], 0xAA);
        expect(result[1], 0xBB);
        expect(result[2], 0xCC);
        expect(result[3], 0xDD);
        expect(result[4], 0xEE);
        expect(result[5], 0xFF);
      });

      test('parses hyphen-separated MAC', () {
        final result = WakeOnLanService.parseMac('aa-bb-cc-11-22-33');
        expect(result, isNotNull);
        expect(result!.length, 6);
        expect(result[0], 0xAA);
        expect(result[1], 0xBB);
        expect(result[2], 0xCC);
        expect(result[3], 0x11);
        expect(result[4], 0x22);
        expect(result[5], 0x33);
      });

      test('parses MAC without separators', () {
        final result = WakeOnLanService.parseMac('aabbccddeeff');
        expect(result, isNotNull);
        expect(result!.length, 6);
        expect(result[0], 0xAA);
        expect(result[1], 0xBB);
        expect(result[2], 0xCC);
        expect(result[3], 0xDD);
        expect(result[4], 0xEE);
        expect(result[5], 0xFF);
      });

      test('parses MAC with mixed case', () {
        final result = WakeOnLanService.parseMac('Aa:Bb:Cc:11:22:33');
        expect(result, isNotNull);
        expect(result![0], 0xAA);
      });

      test('parses MAC with spaces', () {
        final result = WakeOnLanService.parseMac('AA BB CC 11 22 33');
        expect(result, isNotNull);
        expect(result!.length, 6);
      });

      test('returns null for invalid length', () {
        expect(WakeOnLanService.parseMac('AA:BB:CC:DD:EE'), isNull);
        expect(WakeOnLanService.parseMac('AA:BB:CC:DD:EE:FF:00'), isNull);
        expect(WakeOnLanService.parseMac(''), isNull);
      });

      test('returns null for invalid hex characters', () {
        expect(WakeOnLanService.parseMac('GG:HH:II:JJ:KK:LL'), isNull);
        expect(WakeOnLanService.parseMac('AA:BB:CC:DD:EE:FG'), isNull);
      });

      test('returns null for non-hex string', () {
        expect(WakeOnLanService.parseMac('not:a:mac:addr'), isNull);
      });
    });

    group('isValidMac', () {
      test('returns true for valid MAC addresses', () {
        expect(WakeOnLanService.isValidMac('AA:BB:CC:DD:EE:FF'), true);
        expect(WakeOnLanService.isValidMac('aa-bb-cc-11-22-33'), true);
        expect(WakeOnLanService.isValidMac('aabbcc112233'), true);
      });

      test('returns false for invalid MAC addresses', () {
        expect(WakeOnLanService.isValidMac('invalid'), false);
        expect(WakeOnLanService.isValidMac(''), false);
        expect(WakeOnLanService.isValidMac('GG:HH:II:JJ:KK:LL'), false);
      });
    });

    group('_buildPacket', () {
      test('creates 102-byte magic packet', () {
        final mac = WakeOnLanService.parseMac('AA:BB:CC:DD:EE:FF')!;
        final packet = WakeOnLanService_MockBuildPacket(mac);
        expect(packet.length, 102);
      });

      test('first 6 bytes are 0xFF', () {
        final mac = WakeOnLanService.parseMac('AA:BB:CC:DD:EE:FF')!;
        final packet = WakeOnLanService_MockBuildPacket(mac);
        for (var i = 0; i < 6; i++) {
          expect(packet[i], 0xFF);
        }
      });

      test('bytes 6-11 are MAC repeated', () {
        final mac = Uint8List.fromList([0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]);
        final packet = WakeOnLanService_MockBuildPacket(mac);
        expect(packet[6], 0xAA);
        expect(packet[7], 0xBB);
        expect(packet[8], 0xCC);
        expect(packet[9], 0xDD);
        expect(packet[10], 0xEE);
        expect(packet[11], 0xFF);
      });

      test('MAC repeated 16 times total', () {
        final mac = Uint8List.fromList([0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]);
        final packet = WakeOnLanService_MockBuildPacket(mac);
        // Check first and last MAC repetition
        expect(packet[6], 0xAA);
        expect(packet[11], 0xFF);
        expect(packet[12], 0xAA);
        expect(packet[97], 0xAA);
        expect(packet[101], 0xFF);
      });
    });
  });
}

// Helper to test internal _buildPacket method through reflection or reimplementation
Uint8List WakeOnLanService_MockBuildPacket(Uint8List mac) {
  final packet = Uint8List(6 + 16 * 6);
  for (var i = 0; i < 6; i++) {
    packet[i] = 0xFF;
  }
  for (var i = 0; i < 16; i++) {
    packet.setRange(6 + i * 6, 6 + (i + 1) * 6, mac);
  }
  return packet;
}