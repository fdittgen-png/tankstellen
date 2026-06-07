// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/bluetooth_facade.dart';
import 'package:tankstellen/features/consumption/data/obd2/classic_bluetooth_facade.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connect_trace.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connect_trace_log.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_permissions.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import '../../../../helpers/silence_error_logger.dart';

/// #3025 / Epic #3013 — the transport-aware firstConnect routing invariant.
///
/// The field bug (vLinker BM-Android, a Classic-SPP adapter): the firstConnect
/// pre-warm / pinned path called the BLE `connectByMacDirect` UNCONDITIONALLY,
/// so a Classic adapter could ONLY 4 s-timeout, and the doomed BLE GATT to its
/// MAC then poisoned the subsequent RFCOMM socket. The fix routes firstConnect
/// through `connectByMacTransportAware`, which inspects the paired adapter NAME
/// and dispatches to the Classic RFCOMM path WITHOUT ever opening the BLE GATT.
void main() {
  silenceErrorLoggerSpool();

  group('connectByMacTransportAware path routing (#3025)', () {
    test(
        'a CLASSIC-named adapter takes the Classic RFCOMM path and NEVER the '
        'BLE direct path (the vLinker BM-Android fix)', () async {
      final conn = _RecordingConnection(adapterIsClassic: true);

      final svc = await conn.connectByMacTransportAware(
        'AA:BB:CC:DD:EE:DA',
        adapterName: 'vLinker BM-Android',
      );

      expect(svc, isNotNull, reason: 'the Classic adapter must connect');
      expect(conn.pathsTaken, ['classic']);
      expect(conn.bleDirectCalls, 0,
          reason: 'the BLE 4 s-timeout path must NEVER be invoked for a '
              'Classic adapter — that is the field bug + the SPP poison source');
    });

    test(
        'a BLE-named adapter takes the BLE direct path and never the Classic '
        'path', () async {
      final conn = _RecordingConnection(adapterIsClassic: false);

      final svc = await conn.connectByMacTransportAware(
        'AA:BB:CC:DD:EE:31',
        adapterName: 'vLinker FD',
      );

      expect(svc, isNotNull);
      expect(conn.pathsTaken, ['ble-direct']);
      expect(conn.classicDirectCalls, 0);
    });

    test(
        'an UNKNOWN/nameless adapter tries BLE first then Classic (fallback '
        'order preserved) — but the BLE GATT is fully torn down between',
        () async {
      // The BLE direct path misses (null), so the Classic direct path is tried
      // for the same MAC. Both paths self-tear-down their channel, so no
      // half-open GATT survives into the RFCOMM open.
      final conn = _RecordingConnection(adapterIsClassic: true);

      final svc = await conn.connectByMacTransportAware(
        'AA:BB:CC:DD:EE:FF',
        adapterName: null, // unknown transport
      );

      expect(svc, isNotNull,
          reason: 'the Classic adapter recovers on the second (Classic) '
              'attempt of the unknown-transport fallback');
      // BLE attempted first (missed), then Classic.
      expect(conn.bleDirectCalls, 1);
      expect(conn.pathsTaken, ['classic']);
    });

    test(
        'fallbackToScan:false on a Classic miss returns null WITHOUT scanning '
        '(the pre-warm contract)', () async {
      // Classic direct returns null (adapter out of range): with
      // fallbackToScan:false the pre-warm must not kick a slow scan.
      final conn = _RecordingConnection(
        adapterIsClassic: true,
        classicDirectReturnsNull: true,
      );

      final svc = await conn.connectByMacTransportAware(
        'AA:BB:CC:DD:EE:DA',
        adapterName: 'vLinker BM-Android',
        fallbackToScan: false,
      );

      expect(svc, isNull);
      expect(conn.scanFallbackCalls, 0,
          reason: 'fallbackToScan:false must not reach the scan path');
      expect(conn.bleDirectCalls, 0,
          reason: 'still no BLE path for a Classic adapter, even on a miss');
    });

    test(
        'a Classic miss WITH fallbackToScan:true reaches the transport-aware '
        'scan (connectByMac) — never a BLE direct', () async {
      final conn = _RecordingConnection(
        adapterIsClassic: true,
        classicDirectReturnsNull: true,
      );

      await conn.connectByMacTransportAware(
        'AA:BB:CC:DD:EE:DA',
        adapterName: 'vLinker BM-Android',
        fallbackToScan: true,
      );

      expect(conn.scanFallbackCalls, 1);
      expect(conn.bleDirectCalls, 0);
    });
  });

  group('connectByMacTransportAware against the REAL service (#3025)', () {
    setUp(Obd2ConnectTraceLog.clear);
    tearDown(Obd2ConnectTraceLog.clear);

    test(
        'a Classic adapter NEVER opens the BLE channelForDirect (4 s timeout) — '
        'the real service routes straight to the Classic facade', () async {
      final ble = _RecordingDirectFacade();
      final classicChannel = _ScriptedChannel(respondTo: _elmOkResponses());
      final classic = _RecordingClassicFacade(channel: classicChannel);
      final service = Obd2ConnectionService(
        registry: Obd2AdapterRegistry.defaults(),
        permissions: _GrantedPermissions(),
        bluetooth: ble,
        classicBluetooth: classic,
        scanSettleDelay: Duration.zero,
      );

      final connected = await service.connectByMacTransportAware(
        'AA:BB:CC:DD:EE:DA',
        adapterName: 'vLinker BM-Android',
      );

      expect(connected, isNotNull, reason: 'the Classic adapter connects');
      expect(ble.directCalls, 0,
          reason: 'the BLE channelForDirect (the 4 s-timeout + SPP-poison '
              'source) must NEVER be touched for a Classic adapter');
      expect(classic.channelForCalls, ['AA:BB:CC:DD:EE:DA'],
          reason: 'the RFCOMM channel is opened instead');
    });

    test(
        'the trace requestedTransport for a Classic adapter is classic, not '
        'ble (truthful field trace)', () async {
      final ble = _RecordingDirectFacade();
      final classic = _RecordingClassicFacade(
        channel: _ScriptedChannel(respondTo: _elmOkResponses()),
      );
      final service = Obd2ConnectionService(
        registry: Obd2AdapterRegistry.defaults(),
        permissions: _GrantedPermissions(),
        bluetooth: ble,
        classicBluetooth: classic,
        scanSettleDelay: Duration.zero,
      );

      await service.connectByMacTransportAware(
        'AA:BB:CC:DD:EE:DA',
        adapterName: 'vLinker BM-Android',
      );

      final traces = Obd2ConnectTraceLog.snapshot();
      expect(traces, isNotEmpty);
      expect(
        traces.any((t) => t.requestedTransport == Obd2ConnectTransport.classic),
        isTrue,
        reason: 'a Classic adapter must record rtx:classic, never rtx:ble',
      );
      expect(
        traces.any((t) => t.requestedTransport == Obd2ConnectTransport.ble),
        isFalse,
        reason: 'no BLE attempt was made, so no ble-stamped trace exists',
      );
    });
  });
}

/// A recording [Obd2ConnectionService] that overrides each by-MAC path so the
/// test can assert WHICH transport [connectByMacTransportAware] chose without a
/// real channel stack. Mirrors the self-test driver test's `_FakeConnection`.
class _RecordingConnection extends Obd2ConnectionService {
  _RecordingConnection({
    required this.adapterIsClassic,
    this.classicDirectReturnsNull = false,
  }) : super(
          registry: Obd2AdapterRegistry.defaults(),
          permissions: _GrantedPermissions(),
          bluetooth: _UnusedFacade(),
          classicBluetooth: _UnusedClassicFacade(),
        );

  /// When true, only the Classic RFCOMM path can connect (mirrors a real
  /// Classic adapter, which the BLE direct path can never reach).
  final bool adapterIsClassic;
  final bool classicDirectReturnsNull;

  final List<String> pathsTaken = [];
  int bleDirectCalls = 0;
  int classicDirectCalls = 0;
  int scanFallbackCalls = 0;

  Obd2Service _service(String linkKind) {
    return Obd2Service(_OkTransport())
      ..adapterMac = 'AA:BB:CC:DD:EE:FF'
      ..linkKind = linkKind;
  }

  @override
  Future<Obd2Service?> connectByMacDirect(
    String mac, {
    Duration timeout = const Duration(seconds: 4),
    bool fallbackToScan = true,
    String? adapterName,
  }) async {
    bleDirectCalls++;
    if (adapterIsClassic) return null; // models the 4 s-timeout-then-null
    pathsTaken.add('ble-direct');
    return _service('ble');
  }

  @override
  Future<Obd2Service?> connectByMacClassicDirect(String mac,
      {String? adapterName}) async {
    classicDirectCalls++;
    if (!adapterIsClassic) return null;
    if (classicDirectReturnsNull) return null;
    pathsTaken.add('classic');
    return _service('classic');
  }

  @override
  Future<Obd2Service?> connectByMac(String mac,
      {Duration timeout = const Duration(seconds: 5), String? adapterName}) async {
    scanFallbackCalls++;
    return null;
  }
}

class _GrantedPermissions implements Obd2Permissions {
  @override
  Future<Obd2PermissionState> current() async => Obd2PermissionState.granted;
  @override
  Future<Obd2PermissionState> request() async => Obd2PermissionState.granted;
  @override
  Future<bool> requestNotifications() async => true;
}

/// BLE facade that RECORDS every `channelForDirect` call so a Classic-adapter
/// connect can assert it was NEVER touched.
class _RecordingDirectFacade implements BluetoothFacade {
  int directCalls = 0;

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {}

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile) =>
      _ScriptedChannel(silent: true);

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) {
    directCalls++;
    // A real Classic adapter would 4 s-timeout here; throw so any accidental
    // BLE attempt is unmistakable in the test (not a silent success).
    return _ScriptedChannel(openError: StateError('BLE GATT to Classic adapter'));
  }
}

class _RecordingClassicFacade implements ClassicBluetoothFacade {
  _RecordingClassicFacade({required this.channel});
  final ElmByteChannel channel;
  final List<String> channelForCalls = [];

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) async* {}

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(String deviceId) {
    channelForCalls.add(deviceId);
    return channel;
  }
}

class _UnusedFacade implements BluetoothFacade {
  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {}
  @override
  Future<void> stopScan() async {}
  @override
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile) =>
      _ScriptedChannel(silent: true);
  @override
  ElmByteChannel channelForDirect(String mac,
          {Duration connectTimeout = const Duration(seconds: 4),
          bool autoConnect = false}) =>
      _ScriptedChannel(silent: true);
}

class _UnusedClassicFacade implements ClassicBluetoothFacade {
  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) async* {}
  @override
  Future<void> stopScan() async {}
  @override
  ElmByteChannel channelFor(String deviceId) => _ScriptedChannel(silent: true);
}

/// Transport whose init sequence always completes — used by the recording
/// connection fake to mint a connectable [Obd2Service].
class _OkTransport extends FakeObd2Transport {
  _OkTransport() : super(_elmOkResponses());
}

/// Minimal channel that answers ELM327 init OK (or throws on open / stays
/// silent) — same shape as the connection-service test's `_FakeChannel`.
class _ScriptedChannel implements ElmByteChannel {
  _ScriptedChannel({this.silent = false, this.respondTo, this.openError});
  final bool silent;
  final Map<String, String>? respondTo;
  final Object? openError;
  final StreamController<List<int>> _ctrl = StreamController.broadcast();
  bool _open = false;

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

Map<String, String> _elmOkResponses() => {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
    };
