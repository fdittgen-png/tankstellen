// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/gps_sample_diagnostic.dart';
import 'package:tankstellen/features/consumption/domain/entities/trip_save_stage.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/providers/recording_pipeline.dart';
import 'package:tankstellen/features/consumption/providers/trip_baseline_recorder.dart';
import 'package:tankstellen/features/consumption/providers/trip_gps_stream_controller.dart';
import 'package:tankstellen/features/consumption/providers/trip_haptic_controller.dart';
import 'package:tankstellen/features/consumption/providers/trip_oem_fuel_level_controller.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_state.dart';
import 'package:tankstellen/features/obd2/data/auto_trip_coordinator.dart';
import 'package:tankstellen/features/obd2/data/fake_background_adapter_listener.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_arbiter.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_drop_signal.dart';
import 'package:tankstellen/features/obd2/data/obd2_reconnect_controller.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_speed_stream.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';
import 'package:tankstellen/features/obd2/providers/obd2_reconnect_provider.dart';
import 'package:tankstellen/features/obd2/providers/obd2_recording_pipeline.dart';

import '../../helpers/silence_error_logger.dart';

/// #3419 (epic #3415 task 2) — integration reproduction tests for the four
/// diagnosed OBD2 link-authority races. Written at the level the bugs live
/// (the drop-signal / connect-initiator seams), per the recurring-bug
/// protocol: each test was verified RED against master's behaviour before
/// the #3420 [Obd2LinkArbiter] was implemented, and each carries a comment
/// naming exactly what master does wrong. These tests are the regression
/// lock that gates the #3424 deletion of the superseded machinery.
///
/// Field evidence (#3415, 2026-07-02 export): ten fully-successful ELM
/// inits in 43 s alternating firstConnect/liveReconnect — the adapter
/// answered every time, each session destroyed by a rival connect
/// authority; 1479 connect attempts in one day.
void main() {
  silenceErrorLoggerSpool();

  // #3424 — the latch shim this suite used to reset through was deleted;
  // reset the arbiter (the one authority) directly.
  setUp(Obd2LinkArbiter.instance.resetForTest);
  tearDown(Obd2LinkArbiter.instance.resetForTest);

  group('OBD2 link-authority races (#3415 / #3419)', () {
    test(
        'race 1 — a drop INSIDE the trip-start window belongs to the '
        'recording authority: the idle #3019 machine must not react', () async {
      // MASTER BUG: Obd2RecordingPipeline.start claims the #3387 latch only
      // at the END of start (obd2_recording_pipeline.dart:273), AFTER the
      // baseline load + the 25 s controller-start watchdog window. A drop
      // that lands inside that window finds the latch unclaimed, so the
      // app-wide #3019 reconnector starts its loop against the very link the
      // trip start still owns — two authorities on one adapter (the war).
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(obd2ReconnectProvider), Obd2ReconnectState.idle);

      final host = _FakeWalHost();
      final gate = Completer<void>();
      final pipeline = container.read(
        _gatedBaselinesPipelineProvider((host: host, gate: gate.future)),
      );
      final service = Obd2Service(FakeObd2Transport(_elmOk()))
        ..adapterMac = _mac;
      await service.connect();
      service.adapterMac = _mac;

      // start() is now parked inside its trip-start window (baseline load).
      final startF = pipeline.start(service);
      await _pump();

      // The link drops mid-start (the adapter blipped while initialising).
      Obd2LinkDropSignal.instance.notifyDrop(
          transportKind: 'classic', mac: _mac, reason: 'classic-socket-error');
      await pumpEventQueue();

      expect(container.read(obd2ReconnectProvider), Obd2ReconnectState.idle,
          reason: 'a drop inside the trip-start window must be owned by the '
              'single recording authority — on master the latch is only '
              'claimed after the start watchdog window, so the idle #3019 '
              'loop starts a SECOND reconnect against the starting trip');

      gate.complete();
      await startF;
      await pipeline.stop();
    });

    test(
        'race 2 — a drop during stop teardown (release→disconnect window) '
        'must not start an idle reconnect against the closing socket',
        () async {
      // MASTER BUG: Obd2RecordingPipeline.stop releases the #3387 latch as
      // its FIRST statement (obd2_recording_pipeline.dart:299) but only
      // disconnects the service at the very end (:381). A socket drop inside
      // that teardown window (engine off while saving) finds the latch
      // already released, so #3019 fires a reconnect at an adapter the stop
      // sequence is deliberately closing.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(obd2ReconnectProvider), Obd2ReconnectState.idle);

      final host = _FakeWalHost();
      final transport = _GatedDisconnectTransport(_elmOk());
      final pipeline = container.read(_pipelineProvider(host));
      final service = Obd2Service(transport)..adapterMac = _mac;
      await service.connect();
      service.adapterMac = _mac;
      await pipeline.start(service);

      // Gate the disconnect so the teardown window stays open.
      final gate = Completer<void>();
      transport.disconnectGate = gate.future;
      final stopF = pipeline.stop();
      var spins = 0;
      while (!transport.disconnectEntered && spins++ < 200) {
        await _pump();
      }
      expect(transport.disconnectEntered, isTrue,
          reason: 'harness: stop() must have reached svc.disconnect()');

      // The dying socket raises its drop while the teardown is in flight.
      Obd2LinkDropSignal.instance.notifyDrop(
          transportKind: 'classic', mac: _mac, reason: 'classic-socket-error');
      await pumpEventQueue();

      expect(container.read(obd2ReconnectProvider), Obd2ReconnectState.idle,
          reason: 'the recording authority owns the link until its disconnect '
              'COMPLETES — on master release() precedes svc.disconnect(), so '
              'the idle #3019 loop reconnects a deliberately-closing session');

      gate.complete();
      await stopF;
    });

    test(
        'race 3 — the auto-record opener and the idle #3019 loop are never '
        'two interleaved connect authorities', () async {
      // MASTER BUG: nothing gates the auto-record session opener against the
      // idle #3019 reconnector (the #3386 latch only covers a live
      // RECORDING). Field breadcrumbs 2026-06-28: `obd2-reconnect:
      // backoff-scheduled nextAttempt=2` followed 15 ms later by
      // `auto_record:connectStarted` — both machines drove connect cycles at
      // the same adapter. The lower-priority authority must stand down.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(obd2ReconnectProvider), Obd2ReconnectState.idle);

      // An idle drop starts the #3019 loop (no recording, no session).
      Obd2LinkDropSignal.instance.notifyDrop(
          transportKind: 'classic', mac: _mac, reason: 'classic-socket-error');
      await pumpEventQueue();
      expect(container.read(obd2ReconnectProvider),
          Obd2ReconnectState.reconnecting);

      // The paired adapter reappears → the auto-record opener connects.
      final listener = FakeBackgroundAdapterListener();
      final coordinator = AutoTripCoordinator(
        listener: listener,
        startTrip: (_) async => null,
        stopAndSaveAutomatic: () async {},
        config: _config(),
        sessionOpener: (mac) => _openFakeService(),
        speedStreamFactory: _inertSpeedStream,
      );
      addTearDown(coordinator.stop);
      await coordinator.start();
      listener.emitConnected(_mac);
      // The opener runs a real (fake-transport) ELM init with wall-clock
      // settles — poll bounded instead of pumpEventQueue (mirrors the
      // auto_trip_coordinator_test pumpSpeedTicks approach).
      await _waitFor(() => coordinator.hasOpenSession);

      expect(coordinator.hasOpenSession, isTrue,
          reason: 'the auto-record authority owns the link now');
      expect(container.read(obd2ReconnectProvider),
          isNot(Obd2ReconnectState.reconnecting),
          reason: 'one connect authority at a time: when the auto-record '
              'opener takes the link, the idle #3019 loop must stand down — '
              'on master both keep driving connect cycles at the one adapter '
              '(the 06-28 breadcrumb pair, 15 ms apart)');
    });

    test(
        'race 4 — a held recording link blocks a rival initiator entirely '
        '(the instant connect/teardown war pattern is impossible)', () async {
      // MASTER BUG: with a manual recording live, the auto-record
      // foreground-arm path still opens a DIRECT connect to the same adapter
      // (its `_tripActive` guard only knows about trips IT started).
      // Establishing the second RFCOMM session tears down the recording's
      // socket, whose reconnect then tears down the second — the field
      // signature of ten successful ELM inits in 43 s, alternating
      // firstConnect/liveReconnect (#3415 traces t16/t17). A held
      // recording lease must block the rival initiator outright.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(obd2ReconnectProvider), Obd2ReconnectState.idle);

      final host = _FakeWalHost();
      final pipeline = container.read(_pipelineProvider(host));
      final service = Obd2Service(FakeObd2Transport(_elmOk()))
        ..adapterMac = _mac;
      await service.connect();
      service.adapterMac = _mac;
      await pipeline.start(service);
      addTearDown(pipeline.stop);

      var rivalConnects = 0;
      final listener = FakeBackgroundAdapterListener();
      final coordinator = AutoTripCoordinator(
        listener: listener,
        startTrip: (_) async => null,
        stopAndSaveAutomatic: () async {},
        config: _config(),
        sessionOpener: (mac) {
          rivalConnects++;
          return _openFakeService();
        },
        foregroundSessionOpener: (mac) {
          rivalConnects++;
          return _openFakeService();
        },
        speedStreamFactory: _inertSpeedStream,
      );
      addTearDown(coordinator.stop);
      await coordinator.start();

      // Rival initiator 1: the foreground-active arm (app resumed mid-trip).
      await coordinator.armForegroundActive();
      // Rival initiator 2: a background AdapterConnected for the same MAC.
      listener.emitConnected(_mac);
      await pumpEventQueue();

      expect(rivalConnects, 0,
          reason: 'while a recording holds the link, NO rival initiator may '
              'open a connect cycle at the adapter — on master the '
              'auto-record openers connect anyway and destroy the '
              'recording\'s single SPP session (the connect-success/teardown '
              'alternation war)');
      expect(coordinator.hasOpenSession, isFalse,
          reason: 'the rival must not end up holding a session it stole '
              'from the live recording');
    });
  });
}

const _mac = 'AA:BB:CC:00:11:22';

/// Canned happy-path ELM init replies (mirrors the sibling
/// `obd2_recording_pipeline_test.dart` harness).
Map<String, String> _elmOk() => const {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
      '01A6': '41 A6 00 01 6A 2C>',
    };

Future<void> _pump() => Future<void>.delayed(Duration.zero);

AutoRecordConfig _config() => const AutoRecordConfig(
      mac: _mac,
      movementStartThresholdKmh: 5,
      disconnectSaveDelay: Duration(seconds: 60),
    );

/// Bounded real-time wait — the coordinator's opener resolves on wall-clock
/// timers (ELM init settles), which `pumpEventQueue` cannot advance.
Future<void> _waitFor(bool Function() done,
    {Duration timeout = const Duration(seconds: 8)}) async {
  final sw = Stopwatch()..start();
  while (!done() && sw.elapsed < timeout) {
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

/// A connectable fake session for the coordinator's opener seam.
Future<Obd2Service?> _openFakeService() async {
  final svc = Obd2Service(FakeObd2Transport(_elmOk()))..adapterMac = _mac;
  await svc.connect();
  return svc;
}

/// Speed stream that never polls (day-long period) — these tests exercise
/// the CONNECT authority, not the movement detection.
Obd2SpeedStream _inertSpeedStream(Obd2Service service, {String? mac}) =>
    Obd2SpeedStream(service, mac: mac, pollPeriod: const Duration(days: 1));

/// #3382-style harness: a [TripBaselineRecorder] whose load is parked on an
/// injected gate, keeping `start()` inside its trip-start window while the
/// test fires a drop into that window.
class _GatedBaselines extends TripBaselineRecorder {
  _GatedBaselines(super.ref, this._gate);
  final Future<void> _gate;
  @override
  Future<void> load() => _gate;
}

/// Transport whose [disconnect] can be parked on a gate, keeping `stop()`
/// inside its teardown window while the test fires a drop into that window.
class _GatedDisconnectTransport extends FakeObd2Transport {
  _GatedDisconnectTransport(super.responses);
  Future<void>? disconnectGate;
  bool disconnectEntered = false;

  @override
  Future<void> disconnect() async {
    disconnectEntered = true;
    final gate = disconnectGate;
    if (gate != null) await gate;
    await super.disconnect();
  }
}

final _pipelineProvider =
    Provider.family<Obd2RecordingPipeline, Obd2RecordingPipelineHost>(
  (ref, host) => Obd2RecordingPipeline(
    ref: ref,
    host: host,
    haptics: TripHapticController(),
    gps: TripGpsStreamController(
      ref: ref,
      lifecycleState: () => AppLifecycleState.resumed,
    ),
    baselines: TripBaselineRecorder(ref),
    oemFuel: TripOemFuelLevelController(),
    readActiveVehicle: () => null,
    readOemPidsFlag: () => false,
    readDiagnosticCaptureFlag: () => false,
  ),
);

final _gatedBaselinesPipelineProvider = Provider.family<Obd2RecordingPipeline,
    ({Obd2RecordingPipelineHost host, Future<void> gate})>(
  (ref, args) => Obd2RecordingPipeline(
    ref: ref,
    host: args.host,
    haptics: TripHapticController(),
    gps: TripGpsStreamController(
      ref: ref,
      lifecycleState: () => AppLifecycleState.resumed,
    ),
    baselines: _GatedBaselines(ref, args.gate),
    oemFuel: TripOemFuelLevelController(),
    readActiveVehicle: () => null,
    readOemPidsFlag: () => false,
    readDiagnosticCaptureFlag: () => false,
  ),
);

/// Minimal counting WAL host (mirrors the obd2_recording_pipeline_test
/// harness — only what start/stop touch).
class _FakeWalHost implements Obd2RecordingPipelineHost {
  @override
  TripRecordingState state = const TripRecordingState();
  @override
  String? lastTripVehicleId;
  @override
  DateTime? lastTripStartedAt;

  @override
  String? readActiveVehicleId() => null;
  @override
  void setSaveStage(TripSaveStage stage) {}
  @override
  void seedActiveSnapshot() {}
  @override
  void maybeFlushActiveSnapshot() {}
  @override
  Future<void> flushActiveSnapshot({bool force = false}) async {}
  @override
  Future<void> clearActiveSnapshot() async {}
  @override
  Future<TripPersistOutcome> saveToHistory(
    TripSummary summary, {
    bool automatic = false,
    List<TripSample> samples = const [],
    List<GpsSampleDiagnostic> gpsSampleDiagnostics = const [],
    String? vehicleId,
    String? adapterMac,
    String? adapterName,
    String? adapterFirmware,
    int gpsFixCount = 0,
  }) async =>
      TripPersistOutcome.discardedNoMovement;
}
