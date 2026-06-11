// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/adapter_registry.dart';
import 'package:tankstellen/features/obd2/data/bluetooth_facade.dart';
import 'package:tankstellen/features/obd2/data/elm_byte_channel.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace_log.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_permissions.dart';
import 'package:tankstellen/features/obd2/data/obd2_scan_governor.dart';

import '../../../helpers/silence_error_logger.dart';

/// #3185 — wiring tests: the connection service's public entries actually
/// thread through the single-flight supervisor + the scan governor (the
/// chokepoint that demotes the six historical connect owners to requesters).
void main() {
  silenceErrorLoggerSpool();
  setUp(Obd2ConnectTraceLog.clear);
  tearDown(Obd2ConnectTraceLog.clear);

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  test('two concurrent connectByMacDirect attempts are SERIALIZED — the '
      'second channel does not open (and the first is not torn down) while '
      'the first attempt is mid-open', () async {
    final ch1 = _GatedChannel();
    final ch2 = _GatedChannel();
    final facade = _DirectFacade(channels: [ch1, ch2]);
    final svc = _build(bt: facade);

    final f1 = svc.connectByMacDirect('AA:01', fallbackToScan: false);
    await pump();
    expect(ch1.openCalls, 1, reason: 'first attempt is mid-open');

    final f2 = svc.connectByMacDirect('BB:02', fallbackToScan: false);
    await pump();
    // The pre-#3185 race: the second entrant's teardown closed the first's
    // half-open GATT mid-handshake (GATT-133 signature). Now it must queue.
    expect(ch2.openCalls, 0,
        reason: 'second attempt must wait for the single-flight slot');
    expect(ch1.closeCalls, 0,
        reason: 'the in-flight open must not be torn down by a queuer');

    ch1.failOpen(StateError('adapter unreachable')); // non-recoverable: no retry
    expect(await f1, isNull);
    await pump();
    expect(ch2.openCalls, 1, reason: 'queued attempt runs after the first');
    ch2.failOpen(StateError('adapter unreachable'));
    expect(await f2, isNull);
  });

  test('the waiting attempt records a supervisor-admission step in ITS trace',
      () async {
    final ch1 = _GatedChannel();
    final ch2 = _GatedChannel();
    final svc = _build(bt: _DirectFacade(channels: [ch1, ch2]));

    final f1 = svc.connectByMacDirect('AA:01', fallbackToScan: false);
    await pump();
    final f2 = svc.connectByMacDirect('BB:02', fallbackToScan: false);
    await pump();
    ch1.failOpen(StateError('x'));
    await f1;
    await pump();
    ch2.failOpen(StateError('x'));
    await f2;

    final traces = Obd2ConnectTraceLog.snapshot(); // newest first
    expect(traces, hasLength(2),
        reason: 'serialization keeps each attempt its OWN trace '
            '(no child-merge into the holder\'s)');
    final second = traces.first;
    expect(
      second.steps.map((s) => s.label),
      contains('supervisor-admission'),
    );
    expect(
      traces.last.steps.map((s) => s.label),
      isNot(contains('supervisor-admission')),
      reason: 'the holder itself never waited',
    );
  });

  test('a PASSIVE connect skips its cycle (null, no channel) while an active '
      'attempt is in flight — and never blocks it', () async {
    final ch1 = _GatedChannel();
    final facade = _DirectFacade(channels: [ch1]);
    final svc = _build(bt: facade);

    final active = svc.connectByMacDirect('AA:01', fallbackToScan: false);
    await pump();
    final passive = await svc.connectByMacPassive('AA:01');
    expect(passive, isNull);
    expect(facade.directCalls, 1,
        reason: 'the skipped passive cycle must not open a channel');
    ch1.failOpen(StateError('x'));
    await active;
  });

  test('scan() pays into the injected scan governor (one token per start)',
      () async {
    final governor = Obd2ScanGovernor();
    final svc = _build(
      bt: _DirectFacade(channels: []),
      scanGovernor: governor,
    );
    // The facade yields no batches → the scan window closes empty and the
    // service throws Obd2ScanTimeout; the token was still spent on the start.
    await expectLater(svc.scan().toList(), throwsA(anything));
    expect(governor.debugStartCount, 1);
  });
}

Obd2ConnectionService _build({
  required BluetoothFacade bt,
  Obd2ScanGovernor? scanGovernor,
}) =>
    Obd2ConnectionService(
      registry: Obd2AdapterRegistry.defaults(),
      permissions: _GrantedPermissions(),
      bluetooth: bt,
      scanSettleDelay: Duration.zero,
      scanGovernor: scanGovernor,
    );

class _GrantedPermissions implements Obd2Permissions {
  @override
  Future<Obd2PermissionState> current() async => Obd2PermissionState.granted;
  @override
  Future<Obd2PermissionState> request() async => Obd2PermissionState.granted;
  @override
  Future<bool> requestNotifications() async => true;
}

/// Channel whose `open()` blocks until the test resolves it — models a
/// mid-handshake GATT connect. `failOpen` fails it with a NON-recoverable
/// error so the transport's #2906 open-retry doesn't re-dial (keeps the
/// test fast and the call counts exact).
class _GatedChannel implements ElmByteChannel {
  final _openGate = Completer<void>();
  int openCalls = 0;
  int closeCalls = 0;

  void failOpen(Object error) {
    if (!_openGate.isCompleted) _openGate.completeError(error);
  }

  @override
  Future<void> open() {
    openCalls++;
    return _openGate.future;
  }

  @override
  Future<void> close() async {
    closeCalls++;
    failOpen(StateError('closed mid-open'));
  }

  @override
  Future<void> write(List<int> bytes) async {}

  @override
  Stream<List<int>> get incoming => const Stream.empty();

  @override
  bool get isOpen => false;
}

/// Facade handing out a scripted sequence of direct channels; its scan
/// yields nothing (the direct paths under test never scan).
class _DirectFacade implements BluetoothFacade {
  final List<ElmByteChannel> channels;
  int directCalls = 0;
  _DirectFacade({required this.channels});

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {}

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile) =>
      throw UnimplementedError('scan-path channel not used here');

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) {
    final ch = channels[directCalls];
    directCalls++;
    return ch;
  }
}
