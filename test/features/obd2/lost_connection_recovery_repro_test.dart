// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4229 (Epic #4195) — executable reproductions of the three
// lost-connection failure classes, traced on current master through the
// real production collaborators:
//
//   transport drop → Obd2LinkSupervisor (LinkState) → DroppedSessionManager
//   (degradedGpsOnly) → SupervisorReattachSource (recovery) → adoption
//   probe → RecoveryVerifier → first usable PID sample → session binding.
//
// Every test is labelled:
//
//   * **PIN** — passes on master and locks behaviour that already holds.
//   * **REPRO** — asserts the CURRENT (wrong) behaviour and names the
//     #4195 invariant it violates. It flips red the day the seam is
//     fixed; that is the signal, not a regression.
//   * **SEAM** — drives the smallest production change that would fix
//     the matching REPRO, through the EXISTING single authority
//     (`Obd2LinkSupervisor.wake()`), proving no second reconnect
//     controller is needed.
//
// The one seam all three REPROs share: the app already owns proof that
// the vehicle is running while a recording is degraded — sustained GPS
// ground speed — and never publishes it. `GpsMovementWakeNudge` (#3570)
// does exactly that, but it is wired ONLY into `GpsOnlyRecordingPipeline`;
// an OBD2 recording that fell back to GPS has no movement wake, and
// `Obd2VehiclePower.noteMotion()` — rung 5 of that class's own documented
// evidence ladder — has zero production callers.

import 'dart:async';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/session/dropped_session_host.dart';
import 'package:tankstellen/features/obd2/data/session/dropped_session_manager.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_link_supervisor.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_reattach_source.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_link_drop_signal.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';
import 'package:tankstellen/features/obd2/domain/obd2_engine_evidence.dart';
import 'package:tankstellen/features/obd2/domain/vehicle_power_state.dart';
import 'package:tankstellen/features/trips/domain/entities/gps_sample_diagnostic.dart';
import 'package:tankstellen/features/trips/domain/entities/recording_session_event.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';
import 'package:tankstellen/features/trips/providers/gps_movement_wake_nudge.dart';

/// Test clock the fake timers and every injected `now` share. `elapse`
/// moves both, so freshness windows (#3756 engine evidence, #3856 power
/// state) decay exactly as the timers fire.
class _Clock {
  DateTime now = DateTime(2026, 9, 18, 8, 0);

  void advance(FakeAsync async, Duration d) {
    now = now.add(d);
    async.elapse(d);
  }
}

/// The physical adapter, as the supervisor's dialer sees it: `powered`
/// null models "powered off / out of range" (a clean miss), a service
/// models an adapter that answers.
class _Adapter {
  Obd2Service? powered;
  int dials = 0;

  Future<Obd2Service?> dial() async {
    dials++;
    return powered;
  }
}

/// A connected [Obd2Service] over the shared fake transport. `connect()`
/// on [FakeObd2Transport] has no await before its assignment, so the
/// flag is set synchronously — no pumping needed.
Obd2Service _liveService() {
  final transport = FakeObd2Transport();
  unawaited(transport.connect());
  return Obd2Service(transport);
}

const _drop =
    Obd2LinkDropEvent(transportKind: 'classic', reason: 'socket-error');

void main() {
  late StreamController<Obd2LinkDropEvent> drops;
  late _Clock clock;
  late _Adapter adapter;

  setUp(() {
    drops = StreamController<Obd2LinkDropEvent>.broadcast();
    clock = _Clock();
    adapter = _Adapter();
  });

  tearDown(() => drops.close());

  Obd2LinkSupervisor buildSupervisor({
    Obd2EngineEvidence? evidence,
    Obd2VehiclePower? power,
  }) =>
      Obd2LinkSupervisor(
        dial: adapter.dial,
        drops: drops.stream,
        initialBackoff: const Duration(milliseconds: 500),
        maxBackoff: const Duration(seconds: 30),
        jitter: Random(4229),
        now: () => clock.now,
        engineEvidence: evidence ?? Obd2EngineEvidence(now: () => clock.now),
        vehiclePower: power ?? Obd2VehiclePower(now: () => clock.now),
      );

  // ==========================================================================
  // Class 1 — adapter powered off / out of range, restored while driving.
  // ==========================================================================
  group('#4229 class 1 — adapter powered off, then restored while driving',
      () {
    test(
        'PIN: a mid-drive drop with FRESH engine evidence keeps the fast '
        'ladder — the #3756 suppression holds for the whole drive', () {
      fakeAsync((async) {
        final evidence = Obd2EngineEvidence(now: () => clock.now)
          ..noteEngineOn();
        final sup = buildSupervisor(evidence: evidence);
        adapter.powered = null; // the driver's dongle lost power

        drops.add(_drop);
        async.flushMicrotasks();
        expect(sup.state.value, Obd2LinkState.reconnecting);
        expect(adapter.dials, 1, reason: 'the drop dials immediately');

        clock.advance(async, const Duration(minutes: 5));

        expect(sup.inStandDown, isFalse,
            reason: 'engine evidence is fresh — a drive never stands down');
        expect(adapter.dials, greaterThan(8),
            reason: 'the capped 30 s ladder keeps probing the whole time');
        unawaited(sup.dispose());
        async.flushMicrotasks();
      });
    });

    test(
        'REPRO: an outage longer than the engine-evidence window drops the '
        'loop into the storm hold, and the adapter coming back mid-hold is '
        'not dialed for the rest of it', () {
      fakeAsync((async) {
        final evidence = Obd2EngineEvidence(now: () => clock.now)
          ..noteEngineOn();
        final sup = buildSupervisor(evidence: evidence);
        adapter.powered = null;

        drops.add(_drop);
        async.flushMicrotasks();

        // The car keeps driving; the adapter stays dark. Nothing can
        // stamp engine evidence, because stamping it needs the very link
        // that is gone — so the 10 min window expires by construction.
        clock.advance(async, Obd2EngineEvidence.defaultWindow);
        expect(evidence.isFresh(), isFalse);

        // Past that point the identical-miss streak holds the storm
        // cadence (5 min, escalating to 15).
        clock.advance(async, const Duration(minutes: 10));
        expect(sup.inStandDown, isTrue);

        // Step to the instant a hold-cadence dial misses, so the window
        // below starts at the top of a hold whatever the jitter drew.
        final before = adapter.dials;
        for (var step = 0; step < 200 && adapter.dials == before; step++) {
          clock.advance(async, const Duration(seconds: 10));
        }
        expect(adapter.dials, before + 1);

        // The driver reseats the dongle. It answers every dial from now on.
        final dialsAtRestore = adapter.dials;
        adapter.powered = _liveService();
        clock.advance(async, const Duration(minutes: 4));

        // #4195 invariant 7 — "engine-off is not treated as a broken
        // adapter; retry is permitted only when there is fresh evidence
        // that the vehicle is running". The converse fails here: the
        // vehicle IS demonstrably running (the recording is still laying
        // down GPS samples at road speed) and the supervisor cannot see
        // it, because the ONLY producers of engine evidence — rpm and
        // ATRV voltage — need the dead link. So a restored adapter waits
        // out a hold of up to 15 minutes. On a commute that is the
        // #4195 headline: "the driver finishes the trip with GPS-only
        // data even though the adapter became reachable again".
        expect(adapter.dials, dialsAtRestore,
            reason: 'REPRO — no dial at all while the hold runs');
        expect(sup.state.value, Obd2LinkState.reconnecting);
        expect(sup.service, isNull,
            reason: 'the link is back on the wire and unused');
        unawaited(sup.dispose());
        async.flushMicrotasks();
      });
    });

    test(
        'SEAM: sustained GPS movement through GpsMovementWakeNudge → the '
        'existing supervisor.wake() breaks the hold and recovers the link',
        () {
      fakeAsync((async) {
        final evidence = Obd2EngineEvidence(now: () => clock.now)
          ..noteEngineOn();
        final sup = buildSupervisor(evidence: evidence);
        adapter.powered = null;

        drops.add(_drop);
        async.flushMicrotasks();
        clock.advance(async, const Duration(minutes: 20));
        expect(sup.inStandDown, isTrue);

        adapter.powered = _liveService();
        final dialsAtRestore = adapter.dials;

        // Exactly what `GpsOnlyRecordingPipeline` already does with its
        // GPS fixes — and what `Obd2RecordingPipeline` does not. No new
        // authority: the nudge calls the ONE owner's `wake()`.
        final nudge = GpsMovementWakeNudge(
          wake: sup.wake,
          now: () => clock.now,
        );
        for (var i = 0; i < 5; i++) {
          nudge.onSpeed(95);
        }
        async.flushMicrotasks();

        expect(adapter.dials, dialsAtRestore + 1,
            reason: 'one dial, immediately — the hold is a parked-car '
                'cadence and movement is the documented exit');
        expect(sup.state.value, Obd2LinkState.ready);
        expect(sup.service, isNotNull);
        unawaited(sup.dispose());
        async.flushMicrotasks();
      });
    });
  });

  // ==========================================================================
  // Class 2 — the transport socket dies while the engine keeps running.
  // ==========================================================================
  group('#4229 class 2 — transport socket dies, engine keeps running', () {
    test(
        'PIN: the full chain — drop → degradedGpsOnly → supervisor redial → '
        'adoption probe → recoveryVerifying → first PID → leftDegraded', () {
      fakeAsync((async) {
        final evidence = Obd2EngineEvidence(now: () => clock.now)
          ..noteEngineOn();
        final sup = buildSupervisor(evidence: evidence);
        final host = _FakeHost()..gpsAlive = true;
        final adopted = <Obd2Service>[];

        final mgr = DroppedSessionManager(
          host: host,
          now: () => clock.now,
          pauseGraceWindow: const Duration(hours: 1),
          silentReconnectWindow: Duration.zero,
          pinnedAdapterMac: 'AA:BB:CC:DD:EE:FF',
          reconnectScannerFactory: (mac, onReconnect) =>
              SupervisorReattachSource(
            sup,
            onConnected: adopted.add,
            onReconnect: onReconnect,
          ),
        );

        // Live: the supervisor holds the link the recording polls.
        adapter.powered = _liveService();
        unawaited(sup.connect());
        async.flushMicrotasks();
        expect(sup.state.value, Obd2LinkState.ready);
        final original = sup.service;

        // The RFCOMM socket dies. Both halves learn: the transport
        // signals the owner, the poll loop's error streak reaches the
        // trip's drop detector.
        adapter.powered = null;
        drops.add(_drop);
        async.flushMicrotasks();
        mgr.handleDrop();

        expect(host.degradedGpsOnly, isTrue,
            reason: '#4195 invariant 1 — GPS recording never stops');
        expect(host.events(RecordingSessionEventKind.degradedGpsOnly),
            hasLength(1));
        expect(sup.state.value, Obd2LinkState.reconnecting,
            reason: '#4195 invariant 2 — recovery has exactly one owner');
        expect(original!.isConnected, isFalse,
            reason: 'the owner closed the corpse before redialing');

        // The link comes back a few seconds later.
        final replacement = _liveService();
        adapter.powered = replacement;
        clock.advance(async, const Duration(seconds: 10));

        expect(sup.service, same(replacement));
        expect(adopted, [same(replacement)],
            reason: '#4195 invariant 4 — bound to the CURRENT session');
        expect(host.startSchedulerCalls, 1, reason: 'polling resumed');
        expect(host.degradedGpsOnly, isTrue,
            reason: '#4195 invariant 3 / #4196 — the ATRV adoption probe '
                'proved the ADAPTER, never the car');
        expect(host.events(RecordingSessionEventKind.recoveryVerifying),
            hasLength(1));
        expect(host.events(RecordingSessionEventKind.leftDegraded), isEmpty);

        // The first usable PID sample completes the recovery.
        mgr.onEngineData();
        expect(host.degradedGpsOnly, isFalse);
        expect(host.events(RecordingSessionEventKind.leftDegraded),
            hasLength(1),
            reason: '#4195 invariant 8 — the whole episode is journaled');
        expect(mgr.dropReason, isNull);

        mgr.cancelAllTimers();
        unawaited(mgr.stopReconnectScanner());
        unawaited(sup.dispose());
        async.flushMicrotasks();
      });
    });

    test(
        'PIN: a SILENT socket death (no transport edge) still recovers — '
        'the trip hands the corpse to the owner through the #3776 seam',
        () {
      fakeAsync((async) {
        final evidence = Obd2EngineEvidence(now: () => clock.now)
          ..noteEngineOn();
        final sup = buildSupervisor(evidence: evidence);
        final host = _FakeHost()..gpsAlive = true;
        final adopted = <Obd2Service>[];

        adapter.powered = _liveService();
        unawaited(sup.connect());
        async.flushMicrotasks();
        final corpse = sup.service!;

        final mgr = DroppedSessionManager(
          host: host,
          now: () => clock.now,
          pauseGraceWindow: const Duration(hours: 1),
          silentReconnectWindow: Duration.zero,
          pinnedAdapterMac: 'AA:BB:CC:DD:EE:FF',
          reconnectScannerFactory: (mac, onReconnect) =>
              SupervisorReattachSource(
            sup,
            onConnected: adopted.add,
            onReconnect: onReconnect,
          ),
        );
        // Production's `disconnectDroppedService`: a supervised link is
        // never closed by the trip layer — it is reported dead to the
        // owner, which closes it and redials.
        final replacement = _liveService();
        host.onDisconnectDropped = () {
          adapter.powered = replacement;
          sup.reportServiceDead(corpse, reason: 'trip-drop');
        };

        mgr.handleDrop();
        async.flushMicrotasks();
        expect(host.degradedGpsOnly, isTrue);
        expect(corpse.isConnected, isFalse,
            reason: '#4195 invariant 5 — a stale instance is recycled');

        clock.advance(async, const Duration(seconds: 10));
        expect(adopted, [same(replacement)]);
        mgr.onEngineData();
        expect(host.degradedGpsOnly, isFalse);

        mgr.cancelAllTimers();
        unawaited(mgr.stopReconnectScanner());
        unawaited(sup.dispose());
        async.flushMicrotasks();
      });
    });
  });

  // ==========================================================================
  // Class 3 — adapter reachable, ELM / vehicle protocol unresponsive.
  // ==========================================================================
  group('#4229 class 3 — adapter reachable, ELM/protocol unresponsive', () {
    test(
        'REPRO: a mute ELM makes the power model read "asleep" on a moving '
        'car, and the drop parks the ONE reconnect owner with zero dials',
        () {
      fakeAsync((async) {
        final power = Obd2VehiclePower(now: () => clock.now);
        final evidence = Obd2EngineEvidence(now: () => clock.now);
        final sup = buildSupervisor(evidence: evidence, power: power);

        adapter.powered = _liveService();
        unawaited(sup.connect());
        async.flushMicrotasks();
        final held = sup.service!;

        // The drive is real: the ~10 s ATRV watch reads alternator
        // voltage, so the model says the engine is running.
        power.noteVoltage(14.2);
        expect(power.state, VehiclePowerState.engineRunning);

        // Now the ELM stops answering. No more voltage replies, so the
        // 30 s voltage window ages out; the trip's silent-failure handler
        // stamps the silent bus (`_onSilentFailure` → `noteBusSilent`).
        clock.advance(async, const Duration(seconds: 31));
        power.noteBusSilent();

        // #4195 invariant 7. The car is doing road speed, but with the
        // link mute EVERY engine-evidence producer is mute too, so the
        // fused model reads `asleep` from the silent bus alone.
        expect(power.asleep, isTrue, reason: 'REPRO — on a moving car');

        final dialsBefore = adapter.dials;
        sup.reportServiceDead(held, reason: 'trip-drop');
        async.flushMicrotasks();

        // `_dropTail` sees `asleep` and parks instead of dialing.
        expect(sup.state.value, Obd2LinkState.engineOff,
            reason: 'REPRO — a broken adapter classified as engine-off');
        // `obd2_link_supervisor_asleep_park_test` pins the complement:
        // the engine transition DOES wake this park. That transition is
        // produced by an rpm parse or an `ATRV` read — both of which need
        // the very link that is mute here, so on this path it can never
        // arrive.
        clock.advance(async, const Duration(minutes: 20));
        expect(adapter.dials, dialsBefore,
            reason: 'REPRO — the parked loop never re-arms: the wake '
                'sources (rpm, ATRV voltage, ACL hint, app resume) are '
                'all unavailable to a driver with the screen off');
        unawaited(sup.dispose());
        async.flushMicrotasks();
      });
    });

    test(
        'REPRO: with the owner parked, the trip stays degradedGpsOnly for '
        'the rest of the drive and the journal never says why', () {
      fakeAsync((async) {
        final power = Obd2VehiclePower(now: () => clock.now);
        final sup = buildSupervisor(power: power);
        final host = _FakeHost()..gpsAlive = true;
        final adopted = <Obd2Service>[];

        adapter.powered = _liveService();
        unawaited(sup.connect());
        async.flushMicrotasks();
        final held = sup.service!;

        final mgr = DroppedSessionManager(
          host: host,
          now: () => clock.now,
          pauseGraceWindow: const Duration(hours: 1),
          silentReconnectWindow: Duration.zero,
          pinnedAdapterMac: 'AA:BB:CC:DD:EE:FF',
          reconnectScannerFactory: (mac, onReconnect) =>
              SupervisorReattachSource(
            sup,
            onConnected: adopted.add,
            onReconnect: onReconnect,
          ),
        );
        power.noteBusSilent();
        host.onDisconnectDropped =
            () => sup.reportServiceDead(held, reason: 'trip-drop');

        mgr.handleDrop(reason: TripDropReason.silentFailure);
        async.flushMicrotasks();
        expect(sup.state.value, Obd2LinkState.engineOff);

        clock.advance(async, const Duration(minutes: 30));

        expect(host.degradedGpsOnly, isTrue);
        expect(adopted, isEmpty, reason: 'nothing ever re-attaches');
        // #4195 invariant 8 — "every recovery episode is observable in
        // the always-on recording journal". The owner parked; the trip
        // does not know, so the journal (and the banner it drives) still
        // reads as an in-progress transport recovery for 30 minutes.
        expect(host.events(RecordingSessionEventKind.linkEngineOff), isEmpty,
            reason: 'REPRO — the park is invisible to the session journal');
        expect(mgr.dropReason, TripDropReason.silentFailure);

        mgr.cancelAllTimers();
        unawaited(mgr.stopReconnectScanner());
        unawaited(sup.dispose());
        async.flushMicrotasks();
      });
    });

    test(
        'SEAM: the same park, plus the movement nudge — one dial, and the '
        'trip re-attaches through the existing reattach source', () {
      fakeAsync((async) {
        final power = Obd2VehiclePower(now: () => clock.now);
        final sup = buildSupervisor(power: power);
        final host = _FakeHost()..gpsAlive = true;
        final adopted = <Obd2Service>[];

        adapter.powered = _liveService();
        unawaited(sup.connect());
        async.flushMicrotasks();
        final held = sup.service!;

        final mgr = DroppedSessionManager(
          host: host,
          now: () => clock.now,
          pauseGraceWindow: const Duration(hours: 1),
          silentReconnectWindow: Duration.zero,
          pinnedAdapterMac: 'AA:BB:CC:DD:EE:FF',
          reconnectScannerFactory: (mac, onReconnect) =>
              SupervisorReattachSource(
            sup,
            onConnected: adopted.add,
            onReconnect: onReconnect,
          ),
        );
        power.noteBusSilent();
        final healthy = _liveService();
        host.onDisconnectDropped = () {
          adapter.powered = healthy;
          sup.reportServiceDead(held, reason: 'trip-drop');
        };

        mgr.handleDrop(reason: TripDropReason.silentFailure);
        async.flushMicrotasks();
        expect(sup.state.value, Obd2LinkState.engineOff);

        final nudge = GpsMovementWakeNudge(
          wake: sup.wake,
          now: () => clock.now,
        );
        // The degraded recording is still laying down GPS samples at
        // road speed — the evidence the app already has.
        for (var i = 0; i < 5; i++) {
          nudge.onSpeed(95);
        }
        clock.advance(async, const Duration(seconds: 10));

        expect(sup.state.value, Obd2LinkState.ready);
        expect(adopted, [same(healthy)]);
        expect(host.degradedGpsOnly, isTrue,
            reason: '#4196 — adoption is not recovery; the trip stays '
                'GPS-only until a real engine parse');
        mgr.onEngineData();
        expect(host.degradedGpsOnly, isFalse);

        mgr.cancelAllTimers();
        unawaited(mgr.stopReconnectScanner());
        unawaited(sup.dispose());
        async.flushMicrotasks();
      });
    });

    test(
        'REPRO: Obd2VehiclePower rung 5 (GPS motion) is a complete, tested '
        'predicate with no production producer', () {
      final power = Obd2VehiclePower(now: () => clock.now);
      power.noteBusSilent();
      expect(power.movingWithoutEngine, isFalse,
          reason: 'REPRO — nothing in production ever calls noteMotion(), '
              'so the ladder rung the class documents can never fire');

      // What the seam would publish, and what it buys: the model can
      // then tell "parked, adapter asleep" from "moving, link broken".
      power.noteMotion();
      expect(power.movingWithoutEngine, isTrue);
    });
  });
}

/// Recording host the [DroppedSessionManager] drives, with the two hooks
/// these traces need: a journal of session events and the production
/// `disconnectDroppedService` behaviour (report the corpse to the owner).
class _FakeHost implements DroppedSessionHost {
  int startSchedulerCalls = 0;
  final List<String> sessionEvents = [];
  void Function()? onDisconnectDropped;

  Iterable<String> events(RecordingSessionEventKind kind) =>
      sessionEvents.where((e) => e.split(':').first == kind.name);

  @override
  bool pausedDueToDrop = false;
  @override
  bool degradedGpsOnly = false;
  @override
  bool stopped = false;
  @override
  bool started = true;
  @override
  bool paused = false;
  @override
  bool gpsAlive = false;
  @override
  String? sessionId = '2026-09-18T08:00:00.000';
  @override
  String? vehicleId = 'peugeot-107';
  @override
  String? vin;
  @override
  double? odometerStartKm = 100.0;
  @override
  double? odometerLatestKm = 118.0;
  @override
  bool automatic = false;
  @override
  List<TripSample> capturedSamples = [];
  @override
  List<GpsSampleDiagnostic> capturedGpsSampleDiagnostics = [];

  @override
  void finalise() {
    stopped = true;
    started = false;
    pausedDueToDrop = false;
    degradedGpsOnly = false;
  }

  @override
  Future<List<TripSample>> collectAllSamples() async => capturedSamples;

  @override
  void stopScheduler() {}
  @override
  void pauseScheduler() {}
  @override
  void resumeScheduler() {}
  @override
  void startScheduler() => startSchedulerCalls++;
  @override
  void resetDropDetector() {}
  @override
  void clearDropDetectorErrorWindow() {}
  @override
  void emitState() {}
  @override
  void resumeFromReconnect() => pausedDueToDrop = false;

  @override
  void disconnectDroppedService() => onDisconnectDropped?.call();

  @override
  void noteSessionEvent(RecordingSessionEventKind kind, {String? detail}) =>
      sessionEvents.add(detail == null ? kind.name : '${kind.name}:$detail');

  @override
  TripSummary buildInProgressSummary() => _summary();

  @override
  TripSummary buildFinalSummary() => _summary();

  TripSummary _summary() => TripSummary(
        distanceKm: 18.0,
        maxRpm: 3100,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        startedAt: DateTime(2026, 9, 18, 8),
        endedAt: DateTime(2026, 9, 18, 8, 30),
      );
}
