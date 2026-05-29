// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/bluetooth_facade.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
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
}

// --- helpers ---------------------------------------------------------

Obd2ConnectionService _build(BluetoothFacade bt) => Obd2ConnectionService(
      registry: Obd2AdapterRegistry.defaults(),
      permissions: _GrantPermissions(),
      bluetooth: bt,
    );

Obd2AdapterCandidate _cand(String mac, int rssi) => Obd2AdapterCandidate(
      deviceId: mac,
      deviceName: 'vLinker FD',
      advertisedServiceUuids: const [],
      rssi: rssi,
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
