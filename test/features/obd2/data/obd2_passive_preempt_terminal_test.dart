// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/adapter_registry.dart';
import 'package:tankstellen/features/obd2/data/bluetooth_facade.dart';
import 'package:tankstellen/features/obd2/data/bluetooth_obd2_transport.dart';
import 'package:tankstellen/features/obd2/data/elm_byte_channel.dart';
import 'package:tankstellen/features/obd2/data/obd2_channel_abandon.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_supervisor.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace_log.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_errors.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_permissions.dart';

import '../../../helpers/silence_error_logger.dart';

/// #3244 — passive preemption must be TERMINAL, and a force-released zombie
/// must neither close the active requester's channel nor corrupt its trace.
///
/// The audited failure chain: the supervisor's preempt teardown closed the
/// passive channel, but #3179 channels are re-openable and the transport
/// treated the close-induced failure as recoverable → the retry loop
/// re-dialled an UNBOUNDED autoConnect GATT request; the zombie's failure
/// path then closed `_lastDirectChannel` AFTER it had been re-assigned to
/// the ACTIVE requester's channel (killing the active connect mid-handshake,
/// the exact #3185 race), and the active requester's trace child-joined the
/// zombie's — no persisted root.
void main() {
  silenceErrorLoggerSpool();
  setUp(Obd2ConnectTraceLog.clear);
  tearDown(Obd2ConnectTraceLog.clear);

  /// Bounded wall-clock wait (the transport's open-retry backoff and the
  /// supervisor's preempt grace run on real timers).
  Future<void> waitFor(bool Function() done,
      {Duration timeout = const Duration(seconds: 5)}) async {
    final sw = Stopwatch()..start();
    while (!done() && sw.elapsed < timeout) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  group('abandon latch is terminal for the open-retry loop (#3244)', () {
    test('WITHOUT abandon, a recoverable open failure IS re-dialled '
        '(the #3179 contract this fix must not break)', () async {
      final ch = _FlakyChannel();
      final transport = BluetoothObd2Transport(ch);
      await expectLater(
          transport.connect(), throwsA(isA<Obd2DisconnectedException>()));
      expect(ch.openBodies, 3,
          reason: 'the bounded retry loop re-dials a recoverable failure');
    });

    test('abandon() during the retry backoff makes the NEXT open throw the '
        'terminal Obd2ChannelAbandoned — the loop never re-dials', () async {
      final ch = _FlakyChannel();
      final transport = BluetoothObd2Transport(ch);
      final connect = transport.connect();
      // The preempt teardown lands while the retry loop is backing off.
      ch.abandon();
      await expectLater(connect, throwsA(isA<Obd2ChannelAbandoned>()));
      expect(ch.openBodies, 1,
          reason: 'a preempt-abandoned channel must never be re-dialled — '
              'the pre-#3244 loop re-opened it as an unbounded autoConnect '
              'zombie racing the granted active requester');
    });
  });

  group('force-released zombie vs the active requester (#3244)', () {
    test(
        'the zombie unwinds terminally, never closes the ACTIVE channel, '
        'and the active attempt lands as its OWN root trace', () async {
      final passiveCh = _AbandonableGatedChannel();
      final activeCh = _AbandonableGatedChannel();
      final svc = _build(
        bt: _DirectFacade(channels: [passiveCh, activeCh]),
        // Tiny grace so the force-release path runs (the wedged passive
        // ignores its close, modelling a hung FBP wait).
        supervisor: Obd2ConnectSupervisor(
            preemptGrace: const Duration(milliseconds: 5)),
      );

      final passiveF = svc.connectByMacPassive('AA:01');
      await waitFor(() => passiveCh.openBodies == 1);
      expect(passiveCh.openBodies, 1, reason: 'passive wait is in flight');

      final activeF = svc.connectByMacDirect('AA:01', fallbackToScan: false);
      await waitFor(() => passiveCh.isAbandoned);
      expect(passiveCh.isAbandoned, isTrue,
          reason: 'the preempt teardown must poison the passive channel '
              'BEFORE closing it');
      expect(passiveCh.closeCalls, greaterThanOrEqualTo(1));

      // The wedged passive ignored its close → the grace force-releases the
      // slot and the ACTIVE requester proceeds.
      await waitFor(() => activeCh.openBodies == 1);
      expect(activeCh.openBodies, 1,
          reason: 'the force-released active attempt must proceed');

      // NOW the zombie's hung open finally fails with a RECOVERABLE error —
      // exactly what the #3179 retry loop would re-dial.
      passiveCh.failOpen(const Obd2DisconnectedException('socket closed'));
      expect(await passiveF, isNull,
          reason: 'the abandoned passive attempt unwinds terminally');
      expect(passiveCh.openBodies, 1, reason: 'no zombie re-dial');
      expect(activeCh.closeCalls, 0,
          reason: 'the zombie failure path must close only ITS OWN channel — '
              'on the pre-#3244 code its `_teardownLastDirectChannel()` '
              'closed the re-assigned ACTIVE channel mid-handshake');
      expect(activeCh.isAbandoned, isFalse);
      expect(Obd2ConnectTraceLog.active?.hasOutcome, isFalse,
          reason: 'the zombie\'s init-failure classification must not be '
              'stamped onto the ACTIVE requester\'s still-live trace — on '
              'the pre-#3244 code _openAndInit read the shared '
              '`Obd2ConnectTraceLog.active`, which by now is the rival\'s '
              'root (fixed by the own-trace capture)');

      // Finish the active attempt; its trace must be a persisted ROOT,
      // separate from the zombie's superseded trace.
      activeCh.failOpen(StateError('adapter unreachable'));
      expect(await activeF, isNull);
      final traces = Obd2ConnectTraceLog.snapshot(); // newest first
      expect(traces, hasLength(2),
          reason: 'the active requester must get its OWN root trace — on '
              'master it child-joined the zombie\'s and never persisted');
      expect(traces.last.steps.map((s) => s.label), contains('preempted'),
          reason: 'the superseded passive trace explains itself');
      expect(traces.last.outcome, isNotNull);
      expect(traces.first.steps.map((s) => s.label),
          isNot(contains('preempted')));
    });
  });

  group('superseded trace hand-off (#3244)', () {
    test('markSuperseded → the next beginTrace opens a ROOT and the zombie '
        'trace persists separately with its preempted step', () {
      final passive = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.liveReconnect, mac: 'AA:01');
      passive.markSuperseded('passive holder preempted (#3244)');

      final active = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.firstConnect, mac: 'AA:01');
      expect(active.isRoot, isTrue,
          reason: 'the active requester must NOT child-join a superseded '
              'zombie trace');

      final superseded = Obd2ConnectTraceLog.snapshot().single;
      expect(superseded.steps.map((s) => s.label), contains('preempted'));
      expect(superseded.outcome, Obd2ConnectOutcome.unknown);

      // The zombie's own late endTrace is a harmless no-op.
      Obd2ConnectTraceLog.endTrace(passive);
      expect(Obd2ConnectTraceLog.snapshot(), hasLength(1));

      active.setOutcome(Obd2ConnectOutcome.success);
      Obd2ConnectTraceLog.endTrace(active);
      expect(Obd2ConnectTraceLog.snapshot(), hasLength(2));
      expect(Obd2ConnectTraceLog.snapshot().first.outcome,
          Obd2ConnectOutcome.success);
    });
  });
}

Obd2ConnectionService _build({
  required BluetoothFacade bt,
  Obd2ConnectSupervisor? supervisor,
}) =>
    Obd2ConnectionService(
      registry: Obd2AdapterRegistry.defaults(),
      permissions: _GrantedPermissions(),
      bluetooth: bt,
      scanSettleDelay: Duration.zero,
      supervisor: supervisor,
    );

class _GrantedPermissions implements Obd2Permissions {
  @override
  Future<Obd2PermissionState> current() async => Obd2PermissionState.granted;
  @override
  Future<Obd2PermissionState> request() async => Obd2PermissionState.granted;
  @override
  Future<bool> requestNotifications() async => true;
}

/// Channel whose first open throws a RECOVERABLE disconnect (a real blip the
/// #3179 retry loop is built to re-dial) and that honours the production
/// abandon-latch contract at the top of `open()`.
class _FlakyChannel with Obd2ChannelAbandonLatch implements ElmByteChannel {
  int openBodies = 0;

  @override
  Future<void> open() async {
    throwIfAbandoned(); // the production FlutterBluePlusElmChannel contract
    openBodies++;
    throw const Obd2DisconnectedException('transient blip');
  }

  @override
  Future<void> close() async {}
  @override
  Future<void> write(List<int> bytes) async {}
  @override
  Stream<List<int>> get incoming => const Stream.empty();
  @override
  bool get isOpen => false;
}

/// Gated channel modelling a WEDGED passive autoConnect wait: `open()` blocks
/// until the test resolves it, and `close()` deliberately does NOT unwind the
/// wait (the hung-FBP case that forces the supervisor's grace release).
class _AbandonableGatedChannel
    with Obd2ChannelAbandonLatch
    implements ElmByteChannel {
  final _openGate = Completer<void>();
  int openBodies = 0;
  int closeCalls = 0;

  void failOpen(Object error) {
    if (!_openGate.isCompleted) _openGate.completeError(error);
  }

  @override
  Future<void> open() {
    throwIfAbandoned(); // the production contract (#3244)
    openBodies++;
    return _openGate.future;
  }

  @override
  Future<void> close() async {
    closeCalls++;
  }

  @override
  Future<void> write(List<int> bytes) async {}
  @override
  Stream<List<int>> get incoming => const Stream.empty();
  @override
  bool get isOpen => false;
}

/// Facade handing out a scripted sequence of direct channels.
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
