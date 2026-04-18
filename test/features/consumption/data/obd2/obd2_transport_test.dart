import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';

void main() {
  group('FakeObd2Transport', () {
    test('not connected by default', () {
      final t = FakeObd2Transport();
      expect(t.isConnected, isFalse);
    });

    test('connect() flips isConnected to true', () async {
      final t = FakeObd2Transport();
      await t.connect();
      expect(t.isConnected, isTrue);
    });

    test('disconnect() flips isConnected back to false', () async {
      final t = FakeObd2Transport();
      await t.connect();
      await t.disconnect();
      expect(t.isConnected, isFalse);
    });

    test('sendCommand before connect throws StateError', () async {
      final t = FakeObd2Transport();
      await expectLater(
        () => t.sendCommand('ATZ'),
        throwsA(isA<StateError>()),
      );
    });

    test('sendCommand returns the pre-configured response for a known '
        'command', () async {
      final t = FakeObd2Transport({'010C': '41 0C 1A F8>'});
      await t.connect();
      expect(await t.sendCommand('010C'), '41 0C 1A F8>');
    });

    test('sendCommand returns NO DATA when the command has no entry',
        () async {
      // Matches the ELM327 wire-protocol response for an un-answered
      // PID, so the parser above can treat both the real and fake
      // case identically.
      final t = FakeObd2Transport();
      await t.connect();
      expect(await t.sendCommand('UNKNOWN'), 'NO DATA>');
    });

    test('sendCommand trims whitespace around the command', () async {
      final t = FakeObd2Transport({'010C': '41 0C 1A F8>'});
      await t.connect();
      expect(await t.sendCommand('  010C  '), '41 0C 1A F8>');
    });

    test('passing null responses is equivalent to an empty map', () async {
      final t = FakeObd2Transport();
      await t.connect();
      expect(await t.sendCommand('anything'), 'NO DATA>');
    });

    test('reconnect after disconnect allows further sendCommand calls',
        () async {
      final t = FakeObd2Transport({'OK': '41>'});
      await t.connect();
      await t.disconnect();
      await t.connect();
      expect(await t.sendCommand('OK'), '41>');
    });
  });
}
