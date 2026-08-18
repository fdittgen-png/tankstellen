// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:collection';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/obd2/data/auto_record_trace_log.dart';
import 'package:tankstellen/features/obd2/data/session/auto_trip_coordinator.dart';
import 'package:tankstellen/features/obd2/data/protocol/elm327_protocol.dart';
import 'package:tankstellen/features/obd2/data/transport/fake_background_adapter_listener.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_link_drop_signal.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_link_supervisor.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_speed_stream.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';

/// #3725 — regression: a `ready` supervisor holding a DEAD service (the
/// dongle was swapped/unpowered between trips; classic RFCOMM death is
/// only visible on I/O, so no drop event ever fired) must not strand
/// auto-record. Field log 2026-08-15: every session open reused the
/// corpse, the speed stream's #3569 watchdog errored instantly, and the
/// coordinator retried the exact same dead service at 60 s cadence for
/// an entire 25-minute trip — zero OBD2 data recorded.
///
/// Uses the REAL [Obd2LinkSupervisor] (fake dialer) and the REAL
/// [Obd2SpeedStream] over a fake transport, so the reuse contract is
/// exercised end to end rather than through a supervisor stand-in.

class _FakeTransport implements Obd2Transport {
  final Queue<int?> speedQueue;
  bool connected = true;

  _FakeTransport(this.speedQueue);

  @override
  bool get isConnected => connected;

  @override
  Future<void> connect() async {
    connected = true;
  }

  @override
  Future<void> disconnect() async {
    connected = false;
  }

  @override
  Future<String> sendCommand(String command) async {
    if (command == Elm327Protocol.vehicleSpeedCommand) {
      if (speedQueue.isEmpty) return 'NO DATA';
      final int? kmh = speedQueue.removeFirst();
      if (kmh == null) return 'NO DATA';
      final String hex = kmh.toRadixString(16).padLeft(2, '0').toUpperCase();
      return '41 0D $hex';
    }
    return '';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _SilentTraceRecorder implements TraceRecorder {
  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  const String mac = 'D4:E9:5E:A8:CD:7E';
  const Duration shortPoll = Duration(milliseconds: 5);

  late FakeBackgroundAdapterListener listener;
  late AutoTripCoordinator coordinator;
  late Obd2LinkSupervisor supervisor;
  late List<Obd2Service> handedOffServices;

  ({Obd2Service service, _FakeTransport transport}) buildFakeService(
    List<int?> speeds,
  ) {
    final transport = _FakeTransport(Queue<int?>.of(speeds));
    return (service: Obd2Service(transport), transport: transport);
  }

  AutoTripCoordinator buildCoordinator({
    required Obd2SessionOpener opener,
  }) {
    return AutoTripCoordinator(
      listener: listener,
      linkSupervisor: supervisor,
      startTrip: (Obd2Service service) async {
        handedOffServices.add(service);
        return null;
      },
      stopAndSaveAutomatic: () async {},
      sessionOpener: opener,
      speedStreamFactory: (Obd2Service service, {String? mac}) {
        return Obd2SpeedStream(service, mac: mac, pollPeriod: shortPoll);
      },
      config: const AutoRecordConfig(
        mac: mac,
        movementStartThresholdKmh: 5.0,
        disconnectSaveDelay: Duration(milliseconds: 50),
      ),
      consecutiveSamplesWindow: 3,
    );
  }

  setUp(() {
    AutoRecordTraceLog.clear();
    BreadcrumbCollector.clear();
    errorLogger.resetForTest();
    errorLogger.testRecorderOverride = _SilentTraceRecorder();
    listener = FakeBackgroundAdapterListener();
    handedOffServices = <Obd2Service>[];
  });

  tearDown(() async {
    await coordinator.stop();
    await supervisor.dispose();
    errorLogger.testRecorderOverride = null;
    errorLogger.resetForTest();
  });

  test(
      'ready supervisor holding a dead service: arm recycles the link and '
      'dials fresh instead of reusing the corpse', () async {
    final corpse = buildFakeService(const <int?>[]);
    final fresh = buildFakeService([20, 25, 30, 40, 45, 50]);

    supervisor = Obd2LinkSupervisor(
      dial: () async => fresh.service,
      drops: const Stream<Obd2LinkDropEvent>.empty(),
      jitter: Random(1),
    );
    // Put the supervisor into `ready` holding the corpse-to-be, then
    // kill its transport WITHOUT any drop event — the silent-death
    // scenario (dongle unplugged between trips).
    await supervisor.connectWith(() async => corpse.service);
    expect(supervisor.state.value, Obd2LinkState.ready);
    corpse.transport.connected = false;

    coordinator = buildCoordinator(opener: (_) async => fresh.service);
    await coordinator.start();
    listener.emitConnected(mac);
    await Future<void>.delayed(shortPoll * 12);

    expect(handedOffServices, hasLength(1),
        reason: 'movement on the FRESH service must start a trip — the '
            'pre-#3725 behavior errored on the corpse and never sampled');
    expect(identical(handedOffServices.first, fresh.service), isTrue,
        reason: 'the trip must run on the freshly dialed service, never '
            'the dead one the supervisor was still holding');
    expect(
      AutoRecordTraceLog.snapshot().any(
          (e) => e.detail?.contains('supervisor service stale') ?? false),
      isTrue,
      reason: 'the recycle must leave a trace-log line for field triage',
    );
  });

  test(
      'supervisor-owned service dying under the speed watch moves the '
      'supervisor off ready so retries stop reusing the corpse', () async {
    final held = buildFakeService([20, 25]);

    supervisor = Obd2LinkSupervisor(
      // Recycle dial misses: the adapter is gone. Pre-#3725 the
      // supervisor was never even told, so it stayed `ready` forever.
      dial: () async => null,
      drops: const Stream<Obd2LinkDropEvent>.empty(),
      jitter: Random(1),
    );
    await supervisor.connectWith(() async => held.service);
    expect(supervisor.state.value, Obd2LinkState.ready);

    coordinator = buildCoordinator(opener: (_) async => held.service);
    await coordinator.start();
    listener.emitConnected(mac);
    // Let the reuse path wire the speed stream and deliver a sample,
    // then kill the transport mid-watch — the #3569 watchdog errors on
    // the next tick.
    await Future<void>.delayed(shortPoll * 4);
    held.transport.connected = false;
    await Future<void>.delayed(shortPoll * 4);

    expect(supervisor.service, isNull,
        reason: 'the supervisor must stop serving the dead service');
    expect(supervisor.state.value, isNot(Obd2LinkState.ready),
        reason: 'a transport death under the coordinator watch must move '
            'the supervisor into its reconnect loop');
  });
}
