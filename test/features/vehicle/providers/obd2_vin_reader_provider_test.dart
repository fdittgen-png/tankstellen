import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/bluetooth_facade.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_protocol.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_permissions.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/vehicle/data/obd2_vin_reader.dart';
import 'package:tankstellen/features/vehicle/providers/obd2_vin_reader_provider.dart';

/// Unit tests for [Obd2VinReaderService] (#1162, Refs #561).
///
/// The underlying [Obd2VinReader] already has direct coverage in
/// `test/features/vehicle/data/obd2_vin_reader_test.dart`. This file
/// targets the orchestrator wrapper class, which composes
/// `connectBest` + `Obd2VinReader.read` + `disconnect` and was
/// previously only exercised through widget-test overrides — the
/// production `Obd2VinReaderService` itself had zero direct coverage.
///
/// Cases:
///   1. `connectBest` returns null (no scan run yet) → io failure,
///      no errorLogger entry (this branch deliberately skips logging).
///   2. `connectBest` throws (permission denied / scan timeout / ...)
///      → io failure AND an errorLogger entry with
///      `op: 'vinReaderService.readVin'` + `reason: 'connect'`.
///   3. Happy path: a fake `Obd2Service` (real class over a
///      [FakeObd2Transport]) returns well-formed VIN bytes →
///      `result.isSuccess` is true AND the transport's `disconnect`
///      was called (proves the `finally` block runs).
///   4. Read-failure path: the transport returns `NO DATA` → result
///      is `unsupported` AND `disconnect` was still called (proves
///      the `finally` block runs even when the read fails).
void main() {
  // Wire the global errorLogger to an in-memory recorder so the
  // failure-path branches don't try to spool through Hive (which is
  // not initialized in unit-test mode). Mirrors the precedent in
  // `obd2_vin_reader_test.dart`.
  late _CapturingTraceRecorder recorder;

  setUp(() {
    errorLogger.resetForTest();
    recorder = _CapturingTraceRecorder();
    errorLogger.testRecorderOverride = recorder;
  });

  tearDown(() {
    errorLogger.resetForTest();
  });

  group('Obd2VinReaderService.readVin', () {
    test(
      'returns failure(io) when connectBest yields null '
      '(no scan has run yet) and does NOT log an error',
      () async {
        final connection = _FakeObd2ConnectionService(
          connectBestResult: null,
        );
        final service = Obd2VinReaderService(connection: connection);

        final result = await service.readVin(
          pairedAdapterMac: 'AA:BB:CC:DD:EE:FF',
        );

        expect(result.isSuccess, isFalse);
        expect(result.failure, ObdVinFailureReason.io);
        // The null branch deliberately surfaces a typed failure
        // without logging — only the catch path logs.
        expect(recorder.records, isEmpty);
        expect(connection.connectBestCalls, 1);
      },
    );

    test(
      'returns failure(io) and logs the connect error when '
      'connectBest throws',
      () async {
        final connection = _FakeObd2ConnectionService(
          throwOnConnect: Exception('bluetooth permission denied'),
        );
        final service = Obd2VinReaderService(connection: connection);

        final result = await service.readVin(
          pairedAdapterMac: 'AA:BB:CC:DD:EE:FF',
        );

        expect(result.isSuccess, isFalse);
        expect(result.failure, ObdVinFailureReason.io);
        expect(connection.connectBestCalls, 1);
        // The catch path MUST log the error so a failing connect is
        // diagnosable. The wrapped error stringifies with the layer
        // and context map (#1104 contract) — assert on those markers.
        expect(recorder.records, hasLength(1));
        final logged = recorder.records.single.error.toString();
        expect(logged, contains('background'));
        expect(logged, contains('vinReaderService.readVin'));
        expect(logged, contains('connect'));
      },
    );

    test(
      'returns success and disconnects the service when the VIN '
      'read succeeds (proves the finally block runs on the happy path)',
      () async {
        // Captured from a real Peugeot 308 (2014) — five CAN frames
        // prefixed with `49 02 NN`. Same fixture as the
        // Obd2VinReader unit tests.
        const validVinResponse =
            '014\r\n0: 49 02 01 56 46 33\r\n'
            '1: 4C 43 42 4D 42 32 43\r\n'
            '2: 53 32 36 31 38 39 32\r\n'
            '3: 33 39 00 00 00 00 00\r\n>';
        final transport = _RecordingFakeTransport.forCommand(
          Elm327Protocol.vinCommand,
          validVinResponse,
        );
        await transport.connect();
        final obd2Service = Obd2Service(transport);

        final connection = _FakeObd2ConnectionService(
          connectBestResult: obd2Service,
        );
        final service = Obd2VinReaderService(connection: connection);

        final result = await service.readVin(
          pairedAdapterMac: 'AA:BB:CC:DD:EE:FF',
        );

        expect(result.isSuccess, isTrue);
        expect(result.vin, hasLength(17));
        expect(result.failure, isNull);
        // The orchestrator MUST close the transport via the
        // service's disconnect() call in the finally block.
        expect(transport.disconnectCalls, 1);
        expect(transport.isConnected, isFalse);
        // No log entries on the happy path.
        expect(recorder.records, isEmpty);
      },
    );

    test(
      'returns failure(unsupported) and STILL disconnects when the '
      'inner read returns NO DATA (proves the finally block runs '
      'on the read-failure path)',
      () async {
        // Pre-2005 ECU returns NO DATA for Mode 09 PID 02.
        final transport = _RecordingFakeTransport.forCommand(
          Elm327Protocol.vinCommand,
          'NO DATA\r\n>',
        );
        await transport.connect();
        final obd2Service = Obd2Service(transport);

        final connection = _FakeObd2ConnectionService(
          connectBestResult: obd2Service,
        );
        final service = Obd2VinReaderService(connection: connection);

        final result = await service.readVin(
          pairedAdapterMac: 'AA:BB:CC:DD:EE:FF',
        );

        expect(result.isSuccess, isFalse);
        expect(result.failure, ObdVinFailureReason.unsupported);
        // Critical: disconnect ran even though the read returned a
        // typed failure. Skipping it would leak the Bluetooth channel.
        expect(transport.disconnectCalls, 1);
        expect(transport.isConnected, isFalse);
        // The unsupported path inside Obd2VinReader does NOT log —
        // only the timeout / io branches do — so the orchestrator's
        // own log path (catch in the outer try) also stays silent.
        expect(recorder.records, isEmpty);
      },
    );
  });
}

/// In-memory [TraceRecorder] that captures every record() call so
/// tests can assert on the logged error + stack trace. Bypasses the
/// real Hive + Sentry pipeline entirely.
class _CapturingTraceRecorder implements TraceRecorder {
  final List<({Object error, StackTrace stack})> records = [];

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    records.add((error: error, stack: stackTrace));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Fake [Obd2ConnectionService] wired with the minimum-viable
/// dependencies its non-virtual super-constructor demands. We only
/// override `connectBest` — every other method is unused by
/// [Obd2VinReaderService] so the inert defaults are safe.
class _FakeObd2ConnectionService extends Obd2ConnectionService {
  _FakeObd2ConnectionService({
    this.connectBestResult,
    this.throwOnConnect,
  }) : super(
          registry: Obd2AdapterRegistry.defaults(),
          permissions: _AlwaysGrantedPermissions(),
          bluetooth: _UnusedBluetoothFacade(),
        );

  /// Service to return from [connectBest]. Null reproduces the
  /// "no scan run yet" branch.
  final Obd2Service? connectBestResult;

  /// When non-null, [connectBest] throws this object instead of
  /// returning a service — used to drive the orchestrator's catch
  /// path.
  final Object? throwOnConnect;

  /// Number of [connectBest] calls; lets tests assert the
  /// orchestrator actually attempted a connect.
  int connectBestCalls = 0;

  @override
  Future<Obd2Service?> connectBest() async {
    connectBestCalls++;
    final err = throwOnConnect;
    if (err != null) throw err;
    return connectBestResult;
  }
}

/// Permissions stub. The orchestrator never reaches this layer in
/// these tests, but the super-constructor needs a non-null value.
class _AlwaysGrantedPermissions implements Obd2Permissions {
  @override
  Future<Obd2PermissionState> current() async => Obd2PermissionState.granted;

  @override
  Future<Obd2PermissionState> request() async => Obd2PermissionState.granted;
}

/// BluetoothFacade stub. Same rationale as [_AlwaysGrantedPermissions]
/// — required by the super-constructor, never invoked in this test.
class _UnusedBluetoothFacade implements BluetoothFacade {
  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {}

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile) {
    throw UnimplementedError(
      'BluetoothFacade.channelFor is not used by Obd2VinReaderService '
      'tests — connectBest is overridden directly.',
    );
  }
}

/// Test transport that returns a fixed response for one specific
/// command and `NO DATA` for everything else, while recording how
/// many times [disconnect] was called. This is what lets the
/// success/unsupported tests assert the `finally` block ran.
class _RecordingFakeTransport implements Obd2Transport {
  final String _expected;
  final String _response;
  bool _connected = false;
  int disconnectCalls = 0;

  _RecordingFakeTransport.forCommand(this._expected, this._response);

  @override
  Future<void> connect() async {
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
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
