import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/vehicle/data/obd2_vin_reader.dart';

/// Unit tests for [Obd2VinReader] (#1162).
///
/// Pattern: drive a real [Obd2Service] backed by a programmable
/// [Obd2Transport] that returns whatever bytes the test wants for
/// `0902\r`. This mirrors the canonical AT-init boilerplate the rest
/// of the OBD2 service tests use (see
/// `test/features/consumption/data/obd2/obd2_service_test.dart`).
/// We can't `implements Obd2Service` directly — the class has private
/// fields and a non-trivial constructor — so we wrap a fake transport
/// instead, which is what every other obd2 test does.
void main() {
  group('Obd2VinReader (#1162)', () {
    test('returns the parsed VIN on a valid Mode 09 PID 02 response',
        () async {
      // Realistic multi-frame response — the parser drops headers,
      // counters, and non-printable bytes and keeps the trailing 17
      // characters.
      const vin = 'WVWZZZ1KZ8W123456';
      final hexBody = vin.codeUnits
          .map((c) => c.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(' ');
      final vinResponse =
          '49 02 01 $hexBody 49 02 02 49 02 03 49 02 04 49 02 05>';

      final service = await _connected({'0902': vinResponse});
      final reader = Obd2VinReader(service);

      expect(await reader.readVin(), vin);
    });

    test("returns null on 'NO DATA' (older ECUs without Mode 09 PID 02)",
        () async {
      final service = await _connected({'0902': 'NO DATA>'});
      final reader = Obd2VinReader(service);

      expect(await reader.readVin(), isNull);
    });

    test('returns null on a malformed response (< 17 valid chars)',
        () async {
      // Only a handful of valid VIN bytes; parser returns null.
      final service = await _connected({'0902': '49 02 01 41 42 43>'});
      final reader = Obd2VinReader(service);

      expect(await reader.readVin(), isNull);
    });

    test('returns null when the adapter does not respond within timeout',
        () async {
      // SlowTransport hangs the response longer than the reader's
      // 50ms timeout window — verifies the .timeout() bound actually
      // fires and the reader doesn't block the UI on a frozen adapter.
      final transport = _SlowTransport(
        delay: const Duration(seconds: 5),
        response: 'NO DATA>',
      );
      await transport.connect();
      final reader = Obd2VinReader(
        Obd2Service(transport),
        timeout: const Duration(milliseconds: 50),
      );

      expect(await reader.readVin(), isNull);
    });

    test('returns null when sendCommand throws (logs but does not rethrow)',
        () async {
      final transport = _ThrowingTransport();
      await transport.connect();
      final reader = Obd2VinReader(Obd2Service(transport));

      // Should NOT rethrow — bug-fix loop relies on the UI getting
      // null back so it can show the manual-fallback snackbar.
      expect(await reader.readVin(), isNull);
    });
  });
}

// --- helpers ---------------------------------------------------------

const _initResponses = {
  'ATZ': 'ELM327 v1.5>',
  'ATE0': 'OK>',
  'ATL0': 'OK>',
  'ATH0': 'OK>',
  'ATSP0': 'OK>',
};

Future<Obd2Service> _connected(Map<String, String> extra) async {
  final transport = FakeObd2Transport({..._initResponses, ...extra});
  final service = Obd2Service(transport);
  await service.connect();
  return service;
}

/// Transport that delays before completing — used to exercise the
/// [Obd2VinReader] timeout branch without sleeping the test runner.
class _SlowTransport implements Obd2Transport {
  _SlowTransport({required this.delay, required this.response});

  final Duration delay;
  final String response;
  bool _connected = false;

  @override
  Future<void> connect() async => _connected = true;

  @override
  Future<String> sendCommand(String command) async {
    await Future<void>.delayed(delay);
    return response;
  }

  @override
  Future<void> disconnect() async => _connected = false;

  @override
  bool get isConnected => _connected;
}

/// Transport that throws on every sendCommand — exercises the
/// catch-and-return-null branch of [Obd2VinReader.readVin].
class _ThrowingTransport implements Obd2Transport {
  bool _connected = false;

  @override
  Future<void> connect() async => _connected = true;

  @override
  Future<String> sendCommand(String command) async {
    throw StateError('adapter disconnected mid-request');
  }

  @override
  Future<void> disconnect() async => _connected = false;

  @override
  bool get isConnected => _connected;
}
