// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/bluetooth_facade.dart';
import 'package:tankstellen/features/consumption/data/obd2/classic_bluetooth_facade.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_comm_diagnostics.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_permissions.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/reconnect_connector.dart';
import '../../../../helpers/silence_error_logger.dart';

/// Exercises the in-trip reconnect connect policy (#2245): DIRECT connect
/// first, RSSI-gated scan only as the ultimate fallback, no double-scan.
void main() {
  silenceErrorLoggerSpool();

  group('ReconnectConnector — direct-first (#2245)', () {
    test('connects via direct GATT WITHOUT scanning on the happy path',
        () async {
      final fake = _FakeFacade(
        directChannel: _FakeChannel(respondTo: _elmOk()),
        // A non-empty scan batch — if direct ever fell back to scan this
        // would be observable via scanInvoked.
        batches: [
          [_cand('aa:bb', -55)],
        ],
      );
      Obd2Service? connected;
      final connector = ReconnectConnector(
        connection: _build(fake),
        onConnected: (s) => connected = s,
      );

      final ok = await connector.attempt('aa:bb');

      expect(ok, isTrue);
      expect(connected, isNotNull);
      expect(fake.directCalls, 1,
          reason: 'reconnect must try a direct connect first');
      expect(fake.scanInvoked, isFalse,
          reason: 'a successful direct connect must NOT scan (no double-scan)');
      await connected!.disconnect();
    });

    test('attemptPassive opens an autoConnect channel and NEVER scans (#2261)',
        () async {
      final fake = _FakeFacade(
        directChannel: _FakeChannel(respondTo: _elmOk()),
        batches: [
          [_cand('aa:bb', -55)],
        ],
      );
      Obd2Service? connected;
      final connector = ReconnectConnector(
        connection: _build(fake),
        onConnected: (s) => connected = s,
      );

      final ok = await connector.attemptPassive('aa:bb');

      expect(ok, isTrue);
      expect(connected, isNotNull);
      expect(fake.passiveCalls, 1,
          reason: 'the passive path must request an autoConnect channel');
      expect(fake.directCalls, 0,
          reason: 'the passive path must not use the active direct connect');
      expect(fake.scanInvoked, isFalse,
          reason: 'a passive GATT wait IS the fallback — it never scans');
      await connected!.disconnect();
    });

    test('falls back to the scan path only when direct fails — and scans '
        'exactly once', () async {
      final fake = _FakeFacade(
        // Direct open throws ⇒ direct fails; scan carries a strong,
        // repeated sighting so the gate passes on the 2nd batch.
        directChannel: _FakeChannel(openError: StateError('GATT 133')),
        channel: _FakeChannel(respondTo: _elmOk()),
        batches: [
          [_cand('aa:bb', -80)], // weak, seen once → gate skips
          [_cand('aa:bb', -80)], // seen twice → gate passes
        ],
      );
      Obd2Service? connected;
      final connector = ReconnectConnector(
        connection: _build(fake),
        onConnected: (s) => connected = s,
      );

      final ok = await connector.attempt('aa:bb');

      expect(ok, isTrue);
      expect(connected, isNotNull);
      expect(fake.directCalls, 1, reason: 'direct attempted first');
      expect(fake.scanCount, 1,
          reason: 'exactly one scan window — the connector owns the gated '
              'fallback, the service does not double-scan');
      await connected!.disconnect();
    });

    test('refreshes lastCandidate to the strongest-seen advertisement',
        () async {
      final fake = _FakeFacade(
        directChannel: _FakeChannel(openError: StateError('GATT 133')),
        channel: _FakeChannel(respondTo: _elmOk()),
        batches: [
          [_cand('aa:bb', -85)], // weak first
          [_cand('aa:bb', -50)], // much stronger — becomes lastCandidate
        ],
      );
      Obd2Service? connected;
      final connector = ReconnectConnector(
        connection: _build(fake),
        onConnected: (s) => connected = s,
      );

      await connector.attempt('aa:bb');

      expect(connector.lastCandidate, isNotNull);
      expect(connector.lastCandidate!.candidate.rssi, -50,
          reason: 'lastCandidate tracks the strongest sighting');
      // No baseline existed this drop, so the strong 2nd sighting connects
      // via the two-consecutive-batches rule and records its RSSI.
      expect(connector.lastSuccessfulRssi, -50);
      await connected?.disconnect();
    });

    test('skips a lone weak sighting (gate not satisfied) and returns false',
        () async {
      final fake = _FakeFacade(
        directChannel: _FakeChannel(openError: StateError('GATT 133')),
        channel: _FakeChannel(respondTo: _elmOk()),
        batches: [
          [_cand('aa:bb', -90)], // weak, seen exactly once → never connects
        ],
      );
      Obd2Service? connected;
      final connector = ReconnectConnector(
        connection: _build(fake),
        onConnected: (s) => connected = s,
      );

      final ok = await connector.attempt('aa:bb');

      expect(ok, isFalse,
          reason: 'no baseline + seen once + weak ⇒ gate skips, no connect');
      expect(connected, isNull);
    });
  });

  group('ReconnectConnector — transport-aware reconnect (#2565)', () {
    test(
        "transportHint=='classic' ⇒ attempt() classic-directs FIRST and "
        'NEVER takes the BLE direct path', () async {
      // The root cause: a Classic adapter (vLinker FS) was reconnecting over
      // BLE `channelForDirect` → 4 s timeout storm. The classic-direct path
      // must run instead, and the BLE direct path must never be touched.
      final classicChannel = _FakeChannel(respondTo: _elmOk());
      final classicFake = _FakeClassicFacade(channel: classicChannel);
      final ble = _FakeFacade(
        // A non-empty batch + a direct channel: if the classic path ever
        // fell through to BLE direct / scan it would be observable here.
        directChannel: _FakeChannel(respondTo: _elmOk()),
        batches: [
          [_cand('cc:dd', 0)],
        ],
      );
      Obd2Service? connected;
      final connector = ReconnectConnector(
        connection: _build(ble, classic: classicFake),
        onConnected: (s) => connected = s,
        transportHint: 'classic',
      );

      final ok = await connector.attempt('cc:dd');

      expect(ok, isTrue);
      expect(connected, isNotNull);
      expect(connected!.linkKind, 'classic');
      expect(classicFake.channelForCalls, ['cc:dd'],
          reason: 'reconnect must go over the live (classic) transport');
      expect(ble.directCalls, 0,
          reason: 'NEVER the doomed BLE direct path for a classic adapter');
      expect(ble.scanInvoked, isFalse,
          reason: 'a successful classic-direct connect must NOT scan');
      await connected!.disconnect();
    });

    test(
        "transportHint=='classic' + classic-direct fails ⇒ goes STRAIGHT to "
        'the transport-aware scan (no BLE direct attempt)', () async {
      // Classic-direct init fails (silent channel), so the connector must
      // fall to the merged BLE+Classic scan. The bonded classic candidate
      // (rssi==0) passes the gate on the FIRST batch (#2565 RSSI hardening),
      // and the connect routes through the classic facade. The BLE direct
      // path must never be attempted.
      final scanChannel = _FakeChannel(respondTo: _elmOk());
      final classicFake = _FakeClassicFacade(
        // First channelFor (direct) is silent → init times out; the scan
        // path's connect() then builds a fresh channel that answers OK.
        channels: [
          _FakeChannel(silent: true), // classic-direct: fails init
          scanChannel, // scan-path connect: succeeds
        ],
        // The bonded classic adapter ('vLinker FS' resolves to the Classic
        // profile, rssi==0 sentinel) — seen ONCE; the #2565 gate connects it
        // on the first batch.
        batches: [
          [_classicCand('cc:dd')],
        ],
      );
      final ble = _FakeFacade(
        directChannel: _FakeChannel(respondTo: _elmOk()),
        batches: const [[]],
      );
      Obd2Service? connected;
      final connector = ReconnectConnector(
        connection: _build(ble, classic: classicFake),
        onConnected: (s) => connected = s,
        transportHint: 'classic',
      );

      final ok = await connector.attempt('cc:dd');

      expect(ok, isTrue,
          reason: 'the merged scan recovers the classic adapter');
      expect(connected, isNotNull);
      expect(connected!.linkKind, 'classic');
      expect(ble.directCalls, 0,
          reason: 'a failed classic-direct must NOT fall to BLE direct — '
              'straight to the transport-aware scan');
      expect(classicFake.scanInvoked, isTrue,
          reason: 'the fallback is the merged BLE+Classic scan');
      await connected!.disconnect();
    }, timeout: const Timeout(Duration(seconds: 30)));

    test(
        "transportHint=='ble' keeps the existing BLE-direct-first path",
        () async {
      // Regression-lock: a BLE drop is unchanged — direct GATT first,
      // never the classic facade.
      final classicFake = _FakeClassicFacade(channel: _FakeChannel(silent: true));
      final ble = _FakeFacade(
        directChannel: _FakeChannel(respondTo: _elmOk()),
        batches: [
          [_cand('aa:bb', -55)],
        ],
      );
      Obd2Service? connected;
      final connector = ReconnectConnector(
        connection: _build(ble, classic: classicFake),
        onConnected: (s) => connected = s,
        transportHint: 'ble',
      );

      final ok = await connector.attempt('aa:bb');

      expect(ok, isTrue);
      expect(ble.directCalls, 1,
          reason: 'BLE drop ⇒ BLE direct first (unchanged)');
      expect(classicFake.channelForCalls, isEmpty,
          reason: 'a BLE drop never touches the classic facade');
      expect(ble.scanInvoked, isFalse);
      await connected!.disconnect();
    });

    test(
        'attemptPassive for a classic drop bounded-retries classic-direct, '
        'never a BLE autoConnect wait (#2565)', () async {
      final classicFake = _FakeClassicFacade(channel: _FakeChannel(respondTo: _elmOk()));
      final ble = _FakeFacade(
        directChannel: _FakeChannel(respondTo: _elmOk()),
        batches: const [[]],
      );
      Obd2Service? connected;
      final connector = ReconnectConnector(
        connection: _build(ble, classic: classicFake),
        onConnected: (s) => connected = s,
        transportHint: 'classic',
      );

      final ok = await connector.attemptPassive('cc:dd');

      expect(ok, isTrue);
      expect(connected!.linkKind, 'classic');
      expect(classicFake.channelForCalls, ['cc:dd']);
      expect(ble.passiveCalls, 0,
          reason: 'a classic drop must NOT open a BLE autoConnect channel');
      expect(ble.directCalls, 0);
      await connected!.disconnect();
    });
  });

  group('ReconnectConnector → per-attempt telemetry (#2905)', () {
    setUp(Obd2CommDiagnostics.instance.reset);
    tearDown(() {
      Obd2CommDiagnostics.instance
        ..enabled = false
        ..reset();
    });

    test('a successful DIRECT reconnect records a direct success row', () async {
      Obd2CommDiagnostics.instance
        ..enabled = true
        ..beginSession();
      final fake = _FakeFacade(
        directChannel: _FakeChannel(respondTo: _elmOk()),
        batches: const [[]],
      );
      Obd2Service? connected;
      final connector = ReconnectConnector(
        connection: _build(fake),
        onConnected: (s) => connected = s,
        attemptNumber: () => 1,
        backoffMs: () => 0,
      );

      await connector.attempt('aa:bb');

      final rows = Obd2CommDiagnostics.instance.snapshot().reconnectAttempts;
      expect(rows, hasLength(1));
      expect(rows.single.succeeded, isTrue);
      expect(rows.single.path, 'direct');
      expect(rows.single.attemptNumber, 1);
      await connected?.disconnect();
    });

    test('a failed DIRECT reconnect records a failed direct row with the '
        'forwarded scanner ordinal + backoff', () async {
      Obd2CommDiagnostics.instance
        ..enabled = true
        ..beginSession();
      final fake = _FakeFacade(
        // The connection service catches the GATT-133 internally and returns
        // null (no rethrow) — the connector's clean-null branch tags the
        // reconnect-path reason as device-not-connected.
        directChannel: _FakeChannel(openError: StateError('GATT_ERROR 133')),
        // No scan sighting ⇒ the scan fallback finds nothing and returns false.
        batches: const [[]],
      );
      final connector = ReconnectConnector(
        connection: _build(fake),
        onConnected: (_) {},
        attemptNumber: () => 3,
        backoffMs: () => 5000,
      );

      final ok = await connector.attempt('aa:bb');

      expect(ok, isFalse);
      final rows = Obd2CommDiagnostics.instance.snapshot().reconnectAttempts;
      final directRow = rows.firstWhere((r) => r.path == 'direct');
      expect(directRow.succeeded, isFalse);
      // The reconnect-PATH reason is forwarded into the per-attempt timeline
      // (init-path channels only ever recorded init-path reasons before).
      expect(directRow.reasonCode, 'device-not-connected');
      expect(directRow.attemptNumber, 3,
          reason: 'the scanner ordinal is forwarded onto the row');
      expect(directRow.backoffMs, 5000,
          reason: 'the scanner backoff is forwarded onto the row');
    });
  });
}

class _FakeClassicFacade implements ClassicBluetoothFacade {
  final List<List<Obd2AdapterCandidate>> batches;
  final ElmByteChannel? channel;

  /// Per-call channel sequence — lets the direct attempt fail (silent) and
  /// the scan-path connect succeed with a fresh channel.
  final List<ElmByteChannel>? channels;
  int _i = 0;

  final List<String> channelForCalls = [];
  bool scanInvoked = false;

  _FakeClassicFacade({this.batches = const [], this.channel, this.channels});

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    scanInvoked = true;
    for (final batch in batches) {
      yield batch;
    }
  }

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(String deviceId) {
    channelForCalls.add(deviceId);
    if (channels != null) return channels![_i++];
    return channel ?? _FakeChannel(silent: true);
  }
}

// --- helpers ---------------------------------------------------------

Obd2ConnectionService _build(
  BluetoothFacade bt, {
  ClassicBluetoothFacade? classic,
}) =>
    Obd2ConnectionService(
      registry: Obd2AdapterRegistry.defaults(),
      permissions: _GrantPermissions(),
      bluetooth: bt,
      classicBluetooth: classic,
    );

Obd2AdapterCandidate _cand(String mac, int rssi) => Obd2AdapterCandidate(
      deviceId: mac,
      deviceName: 'vLinker FD',
      advertisedServiceUuids: const [],
      rssi: rssi,
    );

/// A bonded Bluetooth-Classic sighting: the `vLinker FS` name resolves to
/// the `vlinker-fs-classic` profile, and Classic enumeration carries no
/// RSSI (the `0` sentinel) (#2565).
Obd2AdapterCandidate _classicCand(String mac) => Obd2AdapterCandidate(
      deviceId: mac,
      deviceName: 'vLinker FS',
      advertisedServiceUuids: const [],
      rssi: 0,
    );

Map<String, String> _elmOk() => {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
    };

class _GrantPermissions implements Obd2Permissions {
  @override
  Future<Obd2PermissionState> current() async => Obd2PermissionState.granted;
  @override
  Future<Obd2PermissionState> request() async => Obd2PermissionState.granted;
  @override
  Future<bool> requestNotifications() async => true;
}

class _FakeFacade implements BluetoothFacade {
  final List<List<Obd2AdapterCandidate>> batches;
  final ElmByteChannel? channel;
  final ElmByteChannel? directChannel;

  bool scanInvoked = false;
  int scanCount = 0;
  int directCalls = 0;
  int passiveCalls = 0;

  _FakeFacade({required this.batches, this.channel, this.directChannel});

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    scanInvoked = true;
    scanCount++;
    for (final batch in batches) {
      yield batch;
    }
  }

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile) =>
      channel ?? _FakeChannel(silent: true);

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) {
    if (autoConnect) {
      passiveCalls++;
    } else {
      directCalls++;
    }
    return directChannel ?? channel ?? _FakeChannel(silent: true);
  }
}

class _FakeChannel implements ElmByteChannel {
  final bool silent;
  final Map<String, String>? respondTo;
  final Object? openError;
  final StreamController<List<int>> _ctrl = StreamController.broadcast();
  bool _open = false;

  _FakeChannel({this.silent = false, this.respondTo, this.openError});

  @override
  bool get isOpen => _open;

  @override
  Stream<List<int>> get incoming => _ctrl.stream;

  @override
  Future<void> open() async {
    final err = openError;
    if (err != null) throw err;
    _open = true;
  }

  @override
  Future<void> write(List<int> bytes) async {
    if (silent) return;
    final cmd = String.fromCharCodes(bytes).trim();
    final reply = respondTo?[cmd] ?? 'OK>';
    _ctrl.add(reply.codeUnits);
  }

  @override
  Future<void> close() async {
    _open = false;
    if (!_ctrl.isClosed) await _ctrl.close();
  }
}
