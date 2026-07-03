// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/adapter_registry.dart';
import 'package:tankstellen/features/obd2/data/bluetooth_facade.dart';
import 'package:tankstellen/features/obd2/data/classic_bluetooth_facade.dart';
import 'package:tankstellen/features/obd2/data/elm_byte_channel.dart';
import 'package:tankstellen/features/obd2/data/obd2_comm_diagnostics.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_permissions.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/reconnect_connector.dart';
import '../../../helpers/silence_error_logger.dart';

/// #2908 — when one transport repeatedly fails to establish a link across its
/// retry budget (direct + scan), the in-trip reconnect falls back to the OTHER
/// transport for the same adapter, and the #2911/#2905 telemetry records which
/// transport recovered the link.
void main() {
  silenceErrorLoggerSpool();

  group('ReconnectConnector — Classic↔BLE transport fallback (#2908)', () {
    setUp(Obd2CommDiagnostics.instance.reset);
    tearDown(() {
      Obd2CommDiagnostics.instance
        ..enabled = false
        ..reset();
    });

    test(
        'a wedged BLE transport escalates to a Classic-direct connect that '
        'succeeds, and telemetry records the switch', () async {
      Obd2CommDiagnostics.instance
        ..enabled = true
        ..beginSession();
      // Preferred (BLE) transport is wedged: direct open throws, no scan
      // sighting. The Classic facade answers OK on its direct channel.
      final ble = _Facade(
        directChannel: _Channel(openError: true),
        batches: const [[]], // scan finds nothing
      );
      final classic = _ClassicFacade(channel: _Channel());
      Obd2Service? connected;
      final connector = ReconnectConnector(
        connection: _build(ble, classic: classic),
        onConnected: (s) => connected = s,
        transportHint: 'ble', // the live link was BLE
        crossTransportThreshold: 1, // escalate on the first exhausted budget
        attemptNumber: () => 1,
        backoffMs: () => 0,
      );

      final ok = await connector.attempt('aa:bb');

      expect(ok, isTrue, reason: 'the Classic alternate recovered the link');
      expect(connected, isNotNull);
      expect(connected!.linkKind, 'classic',
          reason: 'the link landed on the ALTERNATE (Classic) transport');
      expect(classic.channelForCalls, contains('aa:bb'),
          reason: 'the fallback must dial the Classic facade');

      final rows = Obd2CommDiagnostics.instance.snapshot().reconnectAttempts;
      final fallbackRow = rows.firstWhere((r) => r.path == 'fallback-classic');
      expect(fallbackRow.succeeded, isTrue);
      final transitions = Obd2CommDiagnostics.instance.snapshot().transitions;
      expect(
        transitions.any((t) =>
            (t.detail ?? '').contains('transport-fallback:ble→classic')),
        isTrue,
        reason: 'the transport switch must be recorded as a transition detail',
      );
      await connected!.disconnect();
    });

    test(
        'a wedged Classic transport escalates to a BLE-direct connect that '
        'succeeds', () async {
      // The mirror case: a Classic rfcomm storm falls back to BLE direct.
      final classic = _ClassicFacade(channel: _Channel(silent: true));
      final ble = _Facade(
        directChannel: _Channel(), // BLE direct answers OK
        batches: const [[]],
      );
      Obd2Service? connected;
      final connector = ReconnectConnector(
        connection: _build(ble, classic: classic),
        onConnected: (s) => connected = s,
        transportHint: 'classic',
        crossTransportThreshold: 1,
      );

      final ok = await connector.attempt('cc:dd');

      expect(ok, isTrue, reason: 'the BLE alternate recovered the link');
      expect(connected!.linkKind, 'ble',
          reason: 'the link landed on the ALTERNATE (BLE) transport');
      expect(ble.directCalls, greaterThanOrEqualTo(1),
          reason: 'the fallback must dial the BLE direct facade');
      await connected!.disconnect();
    });

    test('the fallback is NOT tried before the failure threshold is reached',
        () async {
      // crossTransportThreshold:2 ⇒ the FIRST exhausted cycle must NOT touch
      // the alternate (a single transient blip is absorbed by the direct /
      // channel.open retries, not by thrashing both transports).
      final ble = _Facade(
        directChannel: _Channel(openError: true),
        batches: const [[]],
      );
      final classic = _ClassicFacade(channel: _Channel());
      final connector = ReconnectConnector(
        connection: _build(ble, classic: classic),
        onConnected: (_) {},
        transportHint: 'ble',
        crossTransportThreshold: 2,
      );

      final ok = await connector.attempt('aa:bb');

      expect(ok, isFalse, reason: 'first cycle: alternate not yet tried');
      expect(classic.channelForCalls, isEmpty,
          reason: 'below the threshold the alternate transport is untouched');

      // SECOND exhausted cycle reaches the threshold → the alternate is tried.
      final ok2 = await connector.attempt('aa:bb');
      expect(ok2, isTrue,
          reason: 'at the threshold the Classic alternate recovers the link');
      expect(classic.channelForCalls, contains('aa:bb'));
    });

    test('a BLE-only build (no Classic facade) has NO alternate — no fallback',
        () async {
      // Regression-lock: the BLE→Classic fallback must not be attempted when
      // no Classic facade is wired (most test/BLE-only configs).
      final ble = _Facade(
        directChannel: _Channel(openError: true),
        batches: const [[]],
      );
      final connector = ReconnectConnector(
        connection: _build(ble), // no classic facade
        onConnected: (_) {},
        transportHint: 'ble',
        crossTransportThreshold: 1,
      );

      final ok = await connector.attempt('aa:bb');

      expect(ok, isFalse,
          reason: 'no alternate transport ⇒ the cycle fails cleanly');
    });
  });
}

// --- helpers ---------------------------------------------------------------

Obd2ConnectionService _build(
  BluetoothFacade bt, {
  ClassicBluetoothFacade? classic,
}) =>
    Obd2ConnectionService(
      registry: Obd2AdapterRegistry.defaults(),
      permissions: _GrantPermissions(),
      bluetooth: bt,
      classicBluetooth: classic,
      scanSettleDelay: Duration.zero,
    );

class _GrantPermissions implements Obd2Permissions {
  @override
  Future<Obd2PermissionState> current() async => Obd2PermissionState.granted;
  @override
  Future<Obd2PermissionState> request() async => Obd2PermissionState.granted;
  @override
  Future<bool> requestNotifications() async => true;
}

class _Facade implements BluetoothFacade {
  final List<List<Obd2AdapterCandidate>> batches;
  final ElmByteChannel? directChannel;
  int directCalls = 0;

  _Facade({this.batches = const [], this.directChannel});

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    for (final batch in batches) {
      yield batch;
    }
  }

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile) =>
      _Channel(silent: true);

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) {
    if (!autoConnect) directCalls++;
    return directChannel ?? _Channel(silent: true);
  }
}

class _ClassicFacade implements ClassicBluetoothFacade {
  final ElmByteChannel? channel;
  final List<String> channelForCalls = [];

  _ClassicFacade({this.channel});

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) async* {}

  @override
  Future<void> stopScan() async {}

  @override
  Future<bool?> isBonded(String mac) async => null; // #3423 — unknown

  @override
  ElmByteChannel channelFor(String deviceId) {
    channelForCalls.add(deviceId);
    return channel ?? _Channel(silent: true);
  }
}

class _Channel implements ElmByteChannel {
  final bool silent;
  final bool openError;
  final StreamController<List<int>> _ctrl = StreamController.broadcast();
  bool _open = false;

  _Channel({this.silent = false, this.openError = false});

  @override
  bool get isOpen => _open;

  @override
  Stream<List<int>> get incoming => _ctrl.stream;

  @override
  Future<void> open() async {
    if (openError) throw StateError('GATT_ERROR 133');
    _open = true;
  }

  @override
  Future<void> write(List<int> bytes) async {
    if (silent) return;
    final cmd = String.fromCharCodes(bytes).trim();
    _ctrl.add((_elmOk()[cmd] ?? 'OK>').codeUnits);
  }

  @override
  Future<void> close() async {
    _open = false;
    if (!_ctrl.isClosed) await _ctrl.close();
  }
}

Map<String, String> _elmOk() => {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
    };
