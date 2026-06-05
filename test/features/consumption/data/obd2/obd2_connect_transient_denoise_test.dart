// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/bluetooth_facade.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'obd2_connection_errors.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'obd2_connection_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_permissions.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_read_telemetry.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/reconnect_connector.dart';

/// #2892 part C — the connect-log flood de-noiser. Error-log #22 spooled an
/// EXPECTED `Obd2AdapterUnresponsive` ("turn the ignition on and retry") 20×
/// as ERROR traces from the in-trip reconnect storm (a parked car). The new
/// `recordObd2ConnectTransient` routes the expected, user-surfaced connect
/// conditions to a breadcrumb while genuine faults stay ERROR traces — the
/// connect-path twin of the #2745/#2763 read de-noiser.
class _CapturingRecorder implements TraceRecorder {
  final errors = <Object>[];
  @override
  Future<void> record(Object error, StackTrace stackTrace,
      {ServiceChainSnapshot? serviceChainState}) async {
    errors.add(error);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _CapturingRecorder rec;

  setUp(() {
    errorLogger.resetForTest();
    rec = _CapturingRecorder();
    errorLogger.testRecorderOverride = rec;
    BreadcrumbCollector.clear();
  });

  tearDown(errorLogger.resetForTest);

  group('isExpectedObd2ConnectTransient classifies the connect families', () {
    test('the user-surfaced connect family is expected', () {
      expect(isExpectedObd2ConnectTransient(const Obd2AdapterUnresponsive()),
          isTrue);
      expect(isExpectedObd2ConnectTransient(const Obd2ScanTimeout()), isTrue);
      expect(isExpectedObd2ConnectTransient(const Obd2BluetoothOff()), isTrue);
      expect(
          isExpectedObd2ConnectTransient(const Obd2DisconnectedException()),
          isTrue);
      expect(isExpectedObd2ConnectTransient(TimeoutException('connect')),
          isTrue);
      expect(
          isExpectedObd2ConnectTransient(StateError('transport closed')),
          isTrue);
      expect(
          isExpectedObd2ConnectTransient(StateError('not connected')), isTrue);
    });

    test('genuine faults are NOT expected (stay ERROR)', () {
      expect(isExpectedObd2ConnectTransient(const Obd2PermissionDenied()),
          isFalse);
      expect(
          isExpectedObd2ConnectTransient(const Obd2ProtocolInitFailed('garble')),
          isFalse);
      // A bare StateError that is NOT a transport race is a genuine bug.
      expect(isExpectedObd2ConnectTransient(StateError('bad index')), isFalse);
      expect(isExpectedObd2ConnectTransient(Exception('boom')), isFalse);
    });
  });

  group('recordObd2ConnectTransient routing', () {
    test('an expected Obd2AdapterUnresponsive is a breadcrumb, NOT an ERROR',
        () async {
      recordObd2ConnectTransient(const Obd2AdapterUnresponsive(),
          StackTrace.current,
          where: 'reconnect');

      await Future<void>.delayed(Duration.zero);
      expect(rec.errors, isEmpty);
      expect(
        BreadcrumbCollector.snapshot().map((b) => b.action),
        contains('OBD2 connect failed — expected transient'),
      );
    });

    test('a genuine Obd2PermissionDenied STILL ERROR-logs (the guard)',
        () async {
      recordObd2ConnectTransient(const Obd2PermissionDenied(),
          StackTrace.current,
          where: 'reconnect');

      await Future<void>.delayed(Duration.zero);
      expect(rec.errors, hasLength(1));
      expect(rec.errors.single.toString(), contains('reconnect'));
      expect(BreadcrumbCollector.snapshot(), isEmpty);
    });
  });

  group('fault injection at the reconnect connect site (#2892)', () {
    test(
        'an EXPECTED Obd2AdapterUnresponsive on a reconnect does NOT reach '
        'errorLogger — it records a breadcrumb', () async {
      final connector = ReconnectConnector(
        connection:
            _ThrowingConnection(directError: const Obd2AdapterUnresponsive()),
        onConnected: (_) {},
      );

      final ok = await connector.attempt('aa:bb');
      await Future<void>.delayed(Duration.zero);

      expect(ok, isFalse, reason: 'the silent bus did not reconnect');
      expect(rec.errors, isEmpty,
          reason: 'an expected connect condition must NOT spool an ERROR '
              'trace (the error-log #22 ×20 flood)');
      expect(
        BreadcrumbCollector.snapshot().map((b) => b.action),
        contains('OBD2 connect failed — expected transient'),
      );
    });

    test('a GENUINE Obd2PermissionDenied on a reconnect STILL reaches '
        'errorLogger', () async {
      final connector = ReconnectConnector(
        connection:
            _ThrowingConnection(directError: const Obd2PermissionDenied()),
        onConnected: (_) {},
      );

      final ok = await connector.attempt('aa:bb');
      await Future<void>.delayed(Duration.zero);

      expect(ok, isFalse);
      expect(rec.errors, hasLength(1),
          reason: 'a real, actionable fault must stay a visible ERROR trace');
      final logged = rec.errors.single.toString();
      expect(logged, contains('Obd2PermissionDenied'));
      expect(logged, contains('ReconnectConnector direct connect failed'));
      expect(BreadcrumbCollector.snapshot(), isEmpty);
    });
  });
}

/// A connection whose direct connect throws the injected error and whose scan
/// is empty, so `ReconnectConnector.attempt` exercises the direct-path catch
/// then returns false. Subclasses the real service so the (overridable) thin
/// instance methods can be replaced; the heavy facades are inert.
class _ThrowingConnection extends Obd2ConnectionService {
  _ThrowingConnection({required this.directError})
      : super(
          registry: Obd2AdapterRegistry.defaults(),
          permissions: _GrantPermissions(),
          bluetooth: _EmptyFacade(),
        );

  final Object directError;

  @override
  Future<Obd2Service?> connectByMacDirect(
    String mac, {
    Duration timeout = const Duration(seconds: 4),
    bool fallbackToScan = true,
  }) async {
    throw directError;
  }

  @override
  Stream<List<ResolvedObd2Candidate>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    // Empty — the direct path's catch is the unit under test; nothing to scan.
  }
}

class _GrantPermissions implements Obd2Permissions {
  @override
  Future<Obd2PermissionState> current() async => Obd2PermissionState.granted;
  @override
  Future<Obd2PermissionState> request() async => Obd2PermissionState.granted;
  @override
  Future<bool> requestNotifications() async => true;
}

class _EmptyFacade implements BluetoothFacade {
  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {}

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile) =>
      throw UnimplementedError();

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) =>
      throw UnimplementedError();
}
