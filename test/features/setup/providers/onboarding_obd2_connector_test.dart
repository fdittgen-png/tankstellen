import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_protocol.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/setup/providers/onboarding_obd2_connector.dart';

/// Unit tests for [DefaultOnboardingObd2Connector] (Refs #561).
///
/// `connect(BuildContext)` is exercised by the existing widget tests of
/// the calling onboarding step — opening the adapter picker requires a
/// fully-mounted widget tree and is out of scope for this file.
///
/// `readVin(Obd2Service)` has three branches we cover here:
///   1. happy path — Mode 09 PID 02 returns a well-formed CAN frame
///      and [Elm327Protocol.parseVin] decodes a 17-character VIN.
///   2. unparseable — bytes come back but [parseVin] returns `null`,
///      so `readVin` returns `null` (no throw).
///   3. catch path — `sendCommand` throws; `readVin` swallows it,
///      `debugPrint`s, and returns `null`.
///
/// A trivial provider read confirms the keep-alive Riverpod wiring.
void main() {
  group('DefaultOnboardingObd2Connector.readVin', () {
    test('returns the decoded VIN on a well-formed Mode 09 response',
        () async {
      // Captured shape from a real Peugeot 308 (2014). Five CAN frames,
      // each prefixed with `49 02 NN` plus padding zeros — same fixture
      // used by `obd2_vin_reader_test.dart`.
      const validVinResponse =
          '014\r\n0: 49 02 01 56 46 33\r\n'
          '1: 4C 43 42 4D 42 32 43\r\n'
          '2: 53 32 36 31 38 39 32\r\n'
          '3: 33 39 00 00 00 00 00\r\n>';
      final transport = _FakeTransport.forCommand(
        Elm327Protocol.vinCommand,
        validVinResponse,
      );
      await transport.connect();
      final service = Obd2Service(transport);
      const connector = DefaultOnboardingObd2Connector();

      final vin = await connector.readVin(service);

      expect(vin, isNotNull);
      // `parseVin` returns the last 17 printable characters.
      expect(vin, hasLength(17));
    });

    test('returns null when parseVin cannot decode the response', () async {
      // Three bytes pass cleanResponse but never reach parseVin's
      // 17-character threshold — parseVin returns null.
      const partial = '41 02 56\r>';
      final transport = _FakeTransport.forCommand(
        Elm327Protocol.vinCommand,
        partial,
      );
      await transport.connect();
      final service = Obd2Service(transport);
      const connector = DefaultOnboardingObd2Connector();

      final vin = await connector.readVin(service);

      expect(vin, isNull);
    });

    test('returns null when sendCommand throws (catch path)', () async {
      final transport = _ThrowingTransport(
        StateError('Bluetooth channel closed'),
      );
      await transport.connect();
      final service = Obd2Service(transport);
      const connector = DefaultOnboardingObd2Connector();

      final vin = await connector.readVin(service);

      expect(vin, isNull);
    });
  });

  group('onboardingObd2Connector provider', () {
    test('returns a DefaultOnboardingObd2Connector by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final connector = container.read(onboardingObd2ConnectorProvider);

      expect(connector, isA<DefaultOnboardingObd2Connector>());
    });
  });
}

/// Test transport that returns a fixed response for one specific
/// command and `NO DATA` for everything else. Mirrors the fake used
/// by `obd2_vin_reader_test.dart` so the two suites stay aligned.
class _FakeTransport implements Obd2Transport {
  final String _expected;
  final String _response;
  bool _connected = false;

  _FakeTransport.forCommand(this._expected, this._response);

  @override
  Future<void> connect() async {
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }

  @override
  bool get isConnected => _connected;

  @override
  Future<String> sendCommand(String command) async {
    if (!_connected) throw StateError('Not connected');
    if (command.trim() == _expected.trim()) return _response;
    return 'NO DATA\r>';
  }
}

/// Transport whose `sendCommand` always throws — simulates a transport
/// fault so the connector's catch branch can be exercised.
class _ThrowingTransport implements Obd2Transport {
  final Object _err;
  bool _connected = false;

  _ThrowingTransport(this._err);

  @override
  Future<void> connect() async {
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }

  @override
  bool get isConnected => _connected;

  @override
  Future<String> sendCommand(String command) async {
    throw _err;
  }
}
