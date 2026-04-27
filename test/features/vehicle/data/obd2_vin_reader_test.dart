import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_protocol.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/vehicle/data/obd2_vin_reader.dart';

/// Unit tests for [Obd2VinReader] (#1162).
///
/// Drives the reader against a [_FakeTransport] that lets each test
/// dictate the response to Mode 09 PID 02. Five cases cover the full
/// state space of [ObdVinResult]:
///
///   1. success — well-formed CAN frames decode to a 17-char VIN.
///   2. unsupported — ELM responds NO DATA.
///   3. malformed — bytes come back but [parseVin] can't decode.
///   4. timeout — sendCommand future doesn't resolve before [timeout].
///   5. io — any other thrown error propagates as
///      [ObdVinFailureReason.io].
void main() {
  // Wire the global errorLogger to an in-memory recorder so the
  // failure-path branches don't try to spool through Hive (which is
  // not initialized in unit-test mode).
  setUp(() {
    errorLogger.resetForTest();
    errorLogger.testRecorderOverride = _FakeTraceRecorder();
  });

  tearDown(() {
    errorLogger.resetForTest();
  });

  group('Obd2VinReader.read', () {
    test('returns success with the decoded VIN on a well-formed response',
        () async {
      // Captured from a real Peugeot 308 (2014) — five CAN frames,
      // each prefixed with `49 02 NN` plus padding zeros.
      const validVinResponse =
          '014\r\n0: 49 02 01 56 46 33\r\n'
          '1: 4C 43 42 4D 42 32 43\r\n'
          '2: 53 32 36 31 38 39 32\r\n'
          '3: 33 39 00 00 00 00 00\r\n>';
      final transport = _FakeTransport.forCommand(
        Elm327Protocol.vinCommand,
        validVinResponse,
      );
      final reader = Obd2VinReader(service: Obd2Service(transport));
      await transport.connect();

      final result = await reader.read();

      expect(result.isSuccess, isTrue);
      // `parseVin` returns the last 17 printable characters — exactly
      // the VIN encoded in the fake response.
      expect(result.vin, hasLength(17));
      expect(result.failure, isNull);
    });

    test(
      'returns failure(unsupported) when the ELM responds NO DATA '
      '(typical pre-2005 ECU)',
      () async {
        final transport = _FakeTransport.forCommand(
          Elm327Protocol.vinCommand,
          'NO DATA\r\n>',
        );
        final reader = Obd2VinReader(service: Obd2Service(transport));
        await transport.connect();

        final result = await reader.read();

        expect(result.isSuccess, isFalse);
        expect(result.vin, isNull);
        expect(result.failure, ObdVinFailureReason.unsupported);
      },
    );

    test(
      'returns failure(malformed) when bytes come back but parseVin '
      'cannot extract a 17-character VIN',
      () async {
        // Three fake bytes that pass cleanResponse but never reach the
        // 17-character threshold parseVin requires. parseVin returns
        // null, and the reader classifies it as malformed.
        const partial = '41 02 56\r>';
        final transport = _FakeTransport.forCommand(
          Elm327Protocol.vinCommand,
          partial,
        );
        final reader = Obd2VinReader(service: Obd2Service(transport));
        await transport.connect();

        final result = await reader.read();

        expect(result.isSuccess, isFalse);
        expect(result.failure, ObdVinFailureReason.malformed);
      },
    );

    test(
      'returns failure(timeout) when sendCommand does not resolve '
      'before the configured timeout',
      () async {
        final transport = _HangingTransport();
        final reader = Obd2VinReader(
          service: Obd2Service(transport),
          // Tiny window keeps the test fast; the real default is 3 s.
          timeout: const Duration(milliseconds: 50),
        );
        await transport.connect();

        final result = await reader.read();

        expect(result.failure, ObdVinFailureReason.timeout);
      },
    );

    test(
      'returns failure(io) when sendCommand throws a non-timeout error '
      '(BT dropped / adapter bug / etc.)',
      () async {
        final transport = _ThrowingTransport(
          StateError('Bluetooth channel closed'),
        );
        final reader = Obd2VinReader(service: Obd2Service(transport));
        await transport.connect();

        final result = await reader.read();

        expect(result.failure, ObdVinFailureReason.io);
      },
    );
  });
}

/// In-memory [TraceRecorder] used to drain `errorLogger.log` calls
/// during the failure-path tests. We don't assert on the captured
/// records — we just stop the global logger from reaching Hive.
class _FakeTraceRecorder implements TraceRecorder {
  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Test transport that returns a fixed response for one specific
/// command and `NO DATA` for everything else.
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

/// Transport whose `sendCommand` future never completes — simulates a
/// stuck adapter so the reader's timeout path can be exercised.
class _HangingTransport implements Obd2Transport {
  bool _connected = false;
  final Completer<String> _stuck = Completer<String>();

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
  Future<String> sendCommand(String command) => _stuck.future;
}

/// Transport whose `sendCommand` always throws — simulates a transport
/// fault (BT channel closed, plugin error, etc.).
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
