// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/adapter_registry.dart';
import 'package:tankstellen/features/obd2/data/bluetooth_facade.dart';
import 'package:tankstellen/features/obd2/data/classic_bluetooth_facade.dart';
import 'package:tankstellen/features/obd2/data/elm_byte_channel.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_permissions.dart';
import 'package:tankstellen/features/obd2/data/reconnect_connector.dart';
import '../../../helpers/silence_error_logger.dart';

/// #2906 stop-scan-before-connect ordering. A shared [_EventLog] records the
/// ORDER of facade calls so the tests assert `stopScan` precedes every
/// `channel.open()` — Android returns GATT_ERROR 133 when a `connect()` races
/// an active scan still winding down on the radio.
void main() {
  silenceErrorLoggerSpool();

  group('#2906 — stop-scan-before-connect ordering', () {
    test('connect() stops the BLE + Classic scan BEFORE opening the channel',
        () async {
      final log = _EventLog();
      final ble = _OrderedFacade(log, channel: _OrderedChannel(log, 'ble'));
      final classic =
          _OrderedClassicFacade(log, channel: _OrderedChannel(log, 'classic'));
      final svc = _build(ble, classic: classic);

      await svc.connect(_resolvedBle('aa:bb'));

      // The radio must be stopped (both facades) before the channel opens.
      expect(log.events, containsAllInOrder(['ble:stopScan', 'ble:open']),
          reason: 'BLE scan must be stopped before the channel opens');
      expect(log.events, containsAllInOrder(['classic:stopScan', 'ble:open']),
          reason: 'the Classic scan must also be stopped before connecting');
      expect(log.events.indexOf('ble:open'),
          greaterThan(log.events.indexOf('ble:stopScan')));
    });

    test('the scan-fallback reconnect path stops the scan before connecting',
        () async {
      // The worst race: the connector breaks out of an `await for` scan loop
      // and immediately connects. `connect()` must stop the (still winding
      // down) scan before opening — the GATT-133 trap the issue describes.
      final log = _EventLog();
      final ble = _OrderedFacade(
        log,
        // Direct open throws ⇒ direct fails, forcing the scan fallback.
        directChannel: _OrderedChannel(log, 'direct', openError: true),
        channel: _OrderedChannel(log, 'scan'),
        batches: [
          [_cand('aa:bb', -50)],
        ],
      );
      final connector = ReconnectConnector(
        connection: _build(ble),
        onConnected: (_) {},
      );

      await connector.attempt('aa:bb');

      // The scan-path connect opened the 'scan' channel; a stopScan must
      // precede it.
      final openIdx = log.events.indexOf('scan:open');
      expect(openIdx, greaterThanOrEqualTo(0),
          reason: 'the scan-fallback connect must open its channel');
      final lastStopBeforeOpen = log.events
          .sublist(0, openIdx)
          .lastIndexWhere((e) => e == 'ble:stopScan');
      expect(lastStopBeforeOpen, greaterThanOrEqualTo(0),
          reason: 'stopScan must run before the scan-fallback channel opens');
    });

    test(
        'no active BLE scan ⇒ the settle pause is skipped (no leaked timer, '
        '#2918)', () {
      // The settle pause only matters when a scan was actually winding down on
      // the radio. With nothing scanning (a cold direct connect, the recording
      // pre-warm, or a widget test driving the prod graph) it must be skipped —
      // otherwise its Future.delayed leaks a pending timer past widget
      // disposal, which is exactly what broke consumption_app_bar_actions_test.
      fakeAsync((async) {
        final log = _EventLog();
        final svc = Obd2ConnectionService(
          registry: Obd2AdapterRegistry.defaults(),
          permissions: _GrantPermissions(),
          bluetooth: _OrderedFacade(log),
          // A huge settle that WOULD dominate (and leak) if the gate regressed.
          scanSettleDelay: const Duration(seconds: 5),
        );

        var done = false;
        unawaited(svc.stopScanBeforeConnect().then((_) => done = true));
        async.flushMicrotasks();

        // FlutterBluePlus.isScanningNow is false in tests, so the settle is
        // skipped: the call already completed without elapsing the 5 s timer.
        expect(done, isTrue,
            reason: 'the settle must be skipped when no scan was active — '
                'else a pending timer outlives widget disposal (#2918)');
        // The stop itself still runs unconditionally (the #2906 guarantee).
        expect(log.events, contains('ble:stopScan'));
        // No pending timer remains — fakeAsync throws at teardown otherwise.
      });
    });
  });
}

// --- helpers ---------------------------------------------------------------

class _EventLog {
  final List<String> events = [];
  void add(String e) => events.add(e);
}

Obd2ConnectionService _build(
  BluetoothFacade bt, {
  ClassicBluetoothFacade? classic,
}) =>
    Obd2ConnectionService(
      registry: Obd2AdapterRegistry.defaults(),
      permissions: _GrantPermissions(),
      bluetooth: bt,
      classicBluetooth: classic,
      // No real wait in tests — the production default is ~120 ms.
      scanSettleDelay: Duration.zero,
    );

ResolvedObd2Candidate _resolvedBle(String mac) {
  final registry = Obd2AdapterRegistry.defaults();
  final cand = _cand(mac, -50);
  return registry.rank([cand]).firstWhere(
    (r) => r.candidate.deviceId == mac,
    orElse: () => registry.rank([cand]).first,
  );
}

Obd2AdapterCandidate _cand(String mac, int rssi) => Obd2AdapterCandidate(
      deviceId: mac,
      deviceName: 'vLinker FD',
      // Advertise the generic FFF0 BLE service so the registry resolves a BLE
      // profile for this candidate.
      advertisedServiceUuids: const ['0000fff0-0000-1000-8000-00805f9b34fb'],
      rssi: rssi,
    );

class _GrantPermissions implements Obd2Permissions {
  @override
  Future<Obd2PermissionState> current() async => Obd2PermissionState.granted;
  @override
  Future<Obd2PermissionState> request() async => Obd2PermissionState.granted;
  @override
  Future<bool> requestNotifications() async => true;
}

class _OrderedFacade implements BluetoothFacade {
  final _EventLog log;
  final List<List<Obd2AdapterCandidate>> batches;
  final ElmByteChannel? channel;
  final ElmByteChannel? directChannel;

  _OrderedFacade(
    this.log, {
    this.batches = const [],
    this.channel,
    this.directChannel,
  });

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    log.add('ble:scan');
    for (final batch in batches) {
      yield batch;
    }
  }

  @override
  Future<void> stopScan() async => log.add('ble:stopScan');

  @override
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile) =>
      channel ?? _OrderedChannel(log, 'ble');

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) =>
      directChannel ?? channel ?? _OrderedChannel(log, 'ble-direct');
}

class _OrderedClassicFacade implements ClassicBluetoothFacade {
  final _EventLog log;
  final ElmByteChannel? channel;
  final List<String> channelForCalls = [];

  _OrderedClassicFacade(this.log, {this.channel});

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    // No Classic scan batches are needed by these tests — the fallback path
    // dials the bonded MAC directly via [channelFor].
  }

  @override
  Future<void> stopScan() async => log.add('classic:stopScan');

  @override
  ElmByteChannel channelFor(String deviceId) {
    channelForCalls.add(deviceId);
    return channel ?? _OrderedChannel(log, 'classic');
  }
}

/// A channel that logs `<tag>:open` on open + answers a clean ELM init so
/// `_openAndInit` succeeds. [openError] forces the open to throw (a wedged
/// transport) so the caller falls back.
class _OrderedChannel implements ElmByteChannel {
  final _EventLog log;
  final String tag;
  final bool openError;
  final StreamController<List<int>> _ctrl = StreamController.broadcast();
  bool _open = false;

  _OrderedChannel(this.log, this.tag, {this.openError = false});

  @override
  bool get isOpen => _open;

  @override
  Stream<List<int>> get incoming => _ctrl.stream;

  @override
  Future<void> open() async {
    log.add('$tag:open');
    if (openError) throw StateError('GATT_ERROR 133 ($tag)');
    _open = true;
  }

  @override
  Future<void> write(List<int> bytes) async {
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
