// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/adapter_registry.dart';
import 'package:tankstellen/features/obd2/data/bluetooth_facade.dart';
import 'package:tankstellen/features/obd2/data/classic_bluetooth_facade.dart';
import 'package:tankstellen/features/obd2/data/classic_elm_channel.dart';
import 'package:tankstellen/features/obd2/data/classic_method_channel.dart';
import 'package:tankstellen/features/obd2/data/elm_byte_channel.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace_log.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_errors.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_permissions.dart';

/// #2969 — proves that a FAILED connect at the SERVICE entry points (the single
/// virtual-dispatch chokepoint every live caller funnels through) leaves a
/// non-empty `Obd2ConnectTrace` with the correct outcome — even though the
/// comm-health session never began. Each test is RED on master (no trace
/// existed) and green after the service-entry instrumentation.
///
/// The Classic path drives the REAL [ClassicElmChannel] over a fake
/// [Obd2ClassicMethodChannel] (no echoing fake that would false-green the
/// rfcomm-open-fail classification): the channel-open outcome is stamped where
/// the real failure is in hand.
void main() {
  setUp(Obd2ConnectTraceLog.clear);
  tearDown(Obd2ConnectTraceLog.clear);

  Obd2ConnectionService svc({
    BluetoothFacade? bluetooth,
    ClassicBluetoothFacade? classic,
    Obd2PermissionState perm = Obd2PermissionState.granted,
  }) =>
      Obd2ConnectionService(
        registry: Obd2AdapterRegistry.defaults(),
        permissions: _FakePerm(perm),
        bluetooth: bluetooth ?? _Facade(batches: const []),
        classicBluetooth: classic,
        scanSettleDelay: Duration.zero,
      );

  Obd2ConnectTrace lastTrace() {
    final snap = Obd2ConnectTraceLog.snapshot();
    expect(snap, isNotEmpty, reason: 'a FAILED connect must leave a trace');
    return snap.first;
  }

  test('connectBest() with no ranked candidate → scanEmpty trace (#2969)',
      () async {
    // The pre-#2969 silent dead-end: `_lastRanked` empty → null, no trace.
    final result = await svc().connectBest();

    expect(result, isNull);
    final trace = lastTrace();
    expect(trace.outcome, Obd2ConnectOutcome.scanEmpty);
    expect(trace.steps.map((s) => s.label), contains('rank'));
  });

  test('connectByMac() under a permission denial → permissionDenied trace',
      () async {
    final service = svc(perm: Obd2PermissionState.denied);
    await expectLater(
      service.connectByMac('AA:BB:CC:DD:EE:F1'),
      throwsA(isA<Obd2PermissionDenied>()),
    );
    expect(lastTrace().outcome, Obd2ConnectOutcome.permissionDenied);
  });

  test('connectByMac() surfacing bluetoothOff → bluetoothOff trace (#2969)',
      () async {
    final service = svc(
      bluetooth:
          _Facade(batches: const [], scanError: const Obd2BluetoothOff()),
    );
    await expectLater(
      service.connectByMac('AA:BB:CC:DD:EE:F1'),
      throwsA(isA<Obd2BluetoothOff>()),
    );
    expect(lastTrace().outcome, Obd2ConnectOutcome.bluetoothOff);
  });

  test(
      'Classic rfcomm-open bool-false (REAL ClassicElmChannel) → rfcommOpenFail '
      'trace via connectByMacClassicDirect (#2969)', () async {
    // Drive the REAL ClassicElmChannel over a fake plugin that returns false —
    // the production path that stamps the connect-trace outcome where the
    // failure is in hand. No echoing fake.
    final plugin = _FalseConnectPlugin();
    final classic = _RealClassicFacade(plugin);
    final service = svc(classic: classic);

    final result = await service.connectByMacClassicDirect('AA:BB:CC:DD:EE:F1');

    expect(result, isNull);
    final trace = lastTrace();
    expect(trace.resolvedTransport, Obd2ConnectTransport.classic);
    expect(trace.outcome, Obd2ConnectOutcome.rfcommOpenFail);
    expect(trace.steps.map((s) => s.label), contains('channel-open'));
  });

  test(
      'Classic rfcomm-open THROW (REAL ClassicElmChannel) → rfcommOpenFail '
      'trace (#2969)', () async {
    final plugin = _ThrowingConnectPlugin();
    final classic = _RealClassicFacade(plugin);
    final service = svc(classic: classic);

    await service.connectByMacClassicDirect('AA:BB:CC:DD:EE:F1');

    final trace = lastTrace();
    expect(trace.outcome, Obd2ConnectOutcome.rfcommOpenFail);
    expect(trace.failureDetail, isNotNull);
  });

  test('a BLE direct-connect failure that reaches the by-MAC catch is traced',
      () async {
    // A non-FBP channel that throws a raw GATT_ERROR 133 from open() and
    // PROPAGATES (fallbackToScan:false, no inner swallow) exercises the by-MAC
    // backstop classification.
    final service = svc(
      bluetooth: _Facade(
        batches: const [],
        directOpenError: StateError('android: GATT_ERROR 133'),
      ),
    );
    final result =
        await service.connectByMacDirect('AA:BB:CC:DD:EE:F1', fallbackToScan: false);
    expect(result, isNull);
    final trace = lastTrace();
    // The trace is NON-EMPTY with a recorded failure (the literal complaint).
    expect(trace.outcome, isNotNull);
    expect(trace.steps, isNotEmpty);
  });

  test('the requested MAC is REDACTED in the trace (PII) (#2969)', () async {
    final result = await svc().connectBest();
    expect(result, isNull);
    // connectBest opens a trace with no MAC; drive a by-MAC path for the MAC.
    Obd2ConnectTraceLog.clear();
    final plugin = _FalseConnectPlugin();
    final service = svc(classic: _RealClassicFacade(plugin));
    await service.connectByMacClassicDirect('AA:BB:CC:DD:EE:F1');
    final trace = lastTrace();
    expect(trace.requestedMac, endsWith('E:F1'));
    expect(trace.requestedMac, isNot(contains('AA:BB')));
  });

  // ---- #3014 (Epic #3013, Phase 1) — every attempt traced WITH the name -----

  test(
      'a BLE by-MAC attempt PRODUCES a trace entry carrying the adapter NAME '
      '(RED on master: by-MAC path dropped the name → only a redacted MAC)',
      () async {
    // The maintainer's #1 trace-tool complaint: the SmartOBD BLE by-MAC attempt
    // showed only "···F:31" with no name. The name IS known at the connect
    // entry — it must reach the trace headline.
    final service = svc(
      bluetooth: _Facade(
        batches: const [],
        directOpenError: StateError('android: GATT_ERROR 133'),
      ),
    );
    final result = await service.connectByMacDirect(
      'AA:BB:CC:DD:EE:F1',
      fallbackToScan: false,
      adapterName: 'SmartOBD',
    );
    expect(result, isNull);
    final trace = lastTrace();
    expect(trace.adapterName, 'SmartOBD',
        reason: 'the resolved human name must reach the trace headline, not '
            'just the redacted MAC');
    // And the by-MAC attempt still produces a non-empty trace.
    expect(trace.outcome, isNotNull);
    expect(trace.requestedTransport, Obd2ConnectTransport.ble);
  });

  test(
      'a Classic by-MAC trace carries adapterName == the human name '
      '(extends the false-green MAC-only assertion #2969)', () async {
    final plugin = _FalseConnectPlugin();
    final service = svc(classic: _RealClassicFacade(plugin));
    await service.connectByMacClassicDirect('AA:BB:CC:DD:EE:F1',
        adapterName: 'vLinker FS 1234');
    final trace = lastTrace();
    // The PII redaction still holds…
    expect(trace.requestedMac, endsWith('E:F1'));
    // …AND the human name is now carried (the assertion the prior test only
    // checked the MAC for — false-green on the name).
    expect(trace.adapterName, 'vLinker FS 1234');
  });

  test(
      'connectByMac() infers the requestedTransport from the name via the '
      'registry (was hard-coded unknown) (#3014)', () async {
    // A vLinker FS name name-matches the Classic profile → the trace records
    // `classic`, not the old honest-but-blind `unknown`. The scan errors out
    // (no adapter) so the trace finalises with the inferred transport intact.
    final service = svc(
      bluetooth: _Facade(batches: const [], scanError: const Obd2ScanTimeout()),
    );
    final result = await service.connectByMac('AA:BB:CC:DD:EE:F1',
        adapterName: 'vLinker FS 9000');
    expect(result, isNull);
    final trace = lastTrace();
    expect(trace.requestedTransport, Obd2ConnectTransport.classic);
    expect(trace.adapterName, 'vLinker FS 9000');
  });
}

class _FakePerm implements Obd2Permissions {
  final Obd2PermissionState state;
  _FakePerm(this.state);
  @override
  Future<Obd2PermissionState> current() async => state;
  @override
  Future<Obd2PermissionState> request() async => state;
  @override
  Future<bool> requestNotifications() async => true;
}

class _Facade implements BluetoothFacade {
  final List<List<Obd2AdapterCandidate>> batches;
  final Object? scanError;
  final Object? directOpenError;
  _Facade({required this.batches, this.scanError, this.directOpenError});

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    for (final b in batches) {
      yield b;
    }
    final err = scanError;
    if (err != null) throw err;
  }

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile) =>
      _ThrowingChannel(StateError('unused'));

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) =>
      _ThrowingChannel(directOpenError ?? StateError('GATT_ERROR 133'));
}

/// A Classic facade that builds the REAL [ClassicElmChannel] over [plugin] so
/// the channel-open stamp is exercised in production code, not faked.
class _RealClassicFacade implements ClassicBluetoothFacade {
  final Obd2ClassicMethodChannel plugin;
  _RealClassicFacade(this.plugin);

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) async* {}

  @override
  Future<void> stopScan() async {}

  @override
  Future<bool?> isBonded(String mac) async => null; // #3423 — unknown

  @override
  ElmByteChannel channelFor(String deviceId) =>
      ClassicElmChannel(address: deviceId, plugin: plugin);
}

class _FalseConnectPlugin extends Obd2ClassicMethodChannel {
  _FalseConnectPlugin();
  // #2969 — the real ClassicElmChannel.open calls connectDetailed.
  @override
  Future<ClassicConnectResult> connectDetailed({
    required String address,
    required String uuid,
    int? budgetMs, // #3421
  }) async =>
      (ok: false, strategy: 'exhausted', error: 'read failed, socket closed');
  @override
  Future<void> disconnect() async {}
  @override
  Stream<List<int>> get incoming => const Stream<List<int>>.empty();
}

class _ThrowingConnectPlugin extends Obd2ClassicMethodChannel {
  _ThrowingConnectPlugin();
  @override
  Future<ClassicConnectResult> connectDetailed({
    required String address,
    required String uuid,
    int? budgetMs, // #3421
  }) async =>
      throw Exception('RFCOMM socket open failed');
  @override
  Future<void> disconnect() async {}
  @override
  Stream<List<int>> get incoming => const Stream<List<int>>.empty();
}

class _ThrowingChannel implements ElmByteChannel {
  final Object error;
  final StreamController<List<int>> _ctrl = StreamController.broadcast();
  _ThrowingChannel(this.error);

  @override
  bool get isOpen => false;
  @override
  Stream<List<int>> get incoming => _ctrl.stream;
  @override
  Future<void> open() async => throw error;
  @override
  Future<void> write(List<int> bytes) async {}
  @override
  Future<void> close() async {
    if (!_ctrl.isClosed) await _ctrl.close();
  }
}
