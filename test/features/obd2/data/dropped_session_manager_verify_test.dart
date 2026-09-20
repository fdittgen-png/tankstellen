// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4196 (Epic #4195) — a reattach is an ADOPTION, not a recovery. The
// reattach source proves adoption with `ATRV`, which the ELM chip answers
// with the vehicle bus dead; the manager used to leave GPS-only and
// journal `leftDegraded` on that alone. The trip now stays GPS-only until
// the first fresh engine parse, and a link that delivers none within its
// window is handed back — with the window stretching per consecutive
// unverified adoption, so a dead bus cannot become a dial storm.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/obd2/data/paused_trip_repository.dart';
import 'package:tankstellen/features/obd2/data/session/dropped_session_host.dart';
import 'package:tankstellen/features/obd2/data/session/dropped_session_manager.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_reattach_source.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/session/recovery_verifier.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';
import 'package:tankstellen/features/trips/domain/entities/gps_sample_diagnostic.dart';
import 'package:tankstellen/features/trips/domain/entities/recording_session_event.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';

import '../../../helpers/hive_temp_dir.dart';

void main() {
  group('DroppedSessionManager verified recovery (#4196)', () {
    late Directory tmpDir;
    late Box<String> pausedBox;
    late Box<String> historyBox;
    late DateTime clock;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('verify_recovery_test_');
      Hive.init(tmpDir.path);
      // Unique per test run without a wall-clock read (#3660 ratchet):
      // the temp dir name is already unique.
      final tag = tmpDir.path.hashCode.abs();
      pausedBox = await Hive.openBox<String>('paused_$tag');
      historyBox = await Hive.openBox<String>('history_$tag');
      clock = DateTime(2026, 9, 1, 19, 22, 39);
    });

    tearDown(() async {
      await pausedBox.deleteFromDisk();
      await historyBox.deleteFromDisk();
      await closeHiveAndDeleteTemp(tmpDir);
    });

    ({DroppedSessionManager mgr, _FakeHost host, List<_GateScanner> sources})
        build({required RecoveryVerifier verifier}) {
      final host = _FakeHost()..gpsAlive = true;
      final sources = <_GateScanner>[];
      final mgr = DroppedSessionManager(
        host: host,
        now: () => clock,
        pauseGraceWindow: const Duration(hours: 1),
        silentReconnectWindow: Duration.zero,
        pinnedAdapterMac: 'AA:BB:CC:DD:EE:FF',
        reconnectScannerFactory: (mac, onReconnect) {
          final s = _GateScanner(onReconnect);
          sources.add(s);
          return s;
        },
        recoveryVerifier: verifier,
        pausedRepo: PausedTripRepository(box: pausedBox),
        historyRepo: TripHistoryRepository(box: historyBox),
      );
      return (mgr: mgr, host: host, sources: sources);
    }

    /// The reattach source's fire, as production does it.
    void adopt(_GateScanner source, Obd2Service svc) {
      source.adoptionGate!.noteAdopted(svc);
      source.onReconnect();
    }

    Iterable<String> eventsOf(_FakeHost host, RecordingSessionEventKind kind) =>
        host.sessionEvents.where((e) => e.split(':').first == kind.name);

    test(
        'adopted but silent: GPS-only holds, no leftDegraded — and the '
        'window hands the link back and waits for another', () async {
      final timers = _FakeTimers();
      final t = build(
          verifier: RecoveryVerifier(baseWindow: const Duration(milliseconds: 40), startTimer: timers.start));
      t.mgr.handleDrop();
      adopt(t.sources[0], Obd2Service(FakeObd2Transport()));

      expect(t.host.degradedGpsOnly, isTrue,
          reason: 'the adoption proved the adapter, not the car');
      expect(t.mgr.awaitingEngineData, isTrue);
      expect(eventsOf(t.host, RecordingSessionEventKind.recoveryVerifying),
          hasLength(1));
      expect(eventsOf(t.host, RecordingSessionEventKind.leftDegraded), isEmpty,
          reason: 'RED before #4196: journaled as recovered on the probe');

      timers.elapse(); // the window elapses — no sleeping

      expect(eventsOf(t.host, RecordingSessionEventKind.recoveryUnverified),
          hasLength(1));
      expect(t.mgr.awaitingEngineData, isFalse);
      expect(t.host.degradedGpsOnly, isTrue, reason: 'GPS carries on');
      expect(t.host.disconnectDroppedServiceCalls, 2,
          reason: 'handed back to the owner through the drop seam');
      expect(t.sources, hasLength(2));
      expect(t.sources[1].startCalls, 1,
          reason: 'a fresh reattach source waits for the next link');
    });

    test('the first engine parse completes the recovery — once', () async {
      final timers = _FakeTimers();
      final t = build(
          verifier: RecoveryVerifier(baseWindow: const Duration(milliseconds: 40), startTimer: timers.start));
      t.mgr.handleDrop();
      adopt(t.sources[0], Obd2Service(FakeObd2Transport()));

      t.mgr.onEngineData();

      expect(t.host.degradedGpsOnly, isFalse);
      expect(t.mgr.dropReason, isNull);
      expect(t.host.sessionEvents.last, 'leftDegraded:engine data verified');

      timers.elapse(); // the window elapses — no sleeping
      t.mgr.onEngineData();
      expect(eventsOf(t.host, RecordingSessionEventKind.recoveryUnverified),
          isEmpty, reason: 'a verified recovery cancels the window');
      expect(eventsOf(t.host, RecordingSessionEventKind.leftDegraded),
          hasLength(1), reason: 'later parses are no-ops');
    });

    test(
        'consecutive unverified adoptions stretch the window (capped at 4×); '
        'engine data resets it', () async {
      final timers = _FakeTimers();
      final t = build(
          verifier: RecoveryVerifier(baseWindow: const Duration(milliseconds: 20), startTimer: timers.start));
      t.mgr.handleDrop();

      final windows = <int>[];
      for (var i = 0; i < 5; i++) {
        final window = t.mgr.currentRecoveryVerifyWindow;
        windows.add(window.inMilliseconds);
        adopt(t.sources[i], Obd2Service(FakeObd2Transport()));
        timers.elapse(); // the window elapses — no sleeping
      }

      expect(windows, [20, 40, 60, 80, 80],
          reason: 'a bus that never answers costs one dial per stretched '
              'window, never a storm');
      expect(eventsOf(t.host, RecordingSessionEventKind.recoveryUnverified),
          hasLength(5));

      adopt(t.sources[5], Obd2Service(FakeObd2Transport()));
      t.mgr.onEngineData();
      expect(t.mgr.currentRecoveryVerifyWindow,
          const Duration(milliseconds: 20));
    });

    test(
        '#4386 — the 4x cap emits an honest terminal condition, and a '
        'verified engine parse clears it', () async {
      final timers = _FakeTimers();
      final t = build(
          verifier: RecoveryVerifier(
              baseWindow: const Duration(milliseconds: 20),
              startTimer: timers.start));
      t.mgr.handleDrop();

      // Three unverified adoptions: the window is still stretching, so
      // automatic recovery still has something to say.
      for (var i = 0; i < RecoveryVerifier.unverifiedCap - 1; i++) {
        adopt(t.sources[i], Obd2Service(FakeObd2Transport()));
        timers.elapse();
        expect(t.mgr.recoveryExhausted, isFalse,
            reason: 'the window is still growing at streak ${i + 1}');
      }
      expect(eventsOf(t.host, RecordingSessionEventKind.recoveryExhausted),
          isEmpty);

      // The fourth: the window has stopped growing and four adapters in
      // a row answered ATRV with nothing behind it.
      adopt(t.sources[RecoveryVerifier.unverifiedCap - 1],
          Obd2Service(FakeObd2Transport()));
      timers.elapse();

      expect(t.mgr.recoveryExhausted, isTrue);
      expect(eventsOf(t.host, RecordingSessionEventKind.recoveryExhausted),
          hasLength(1), reason: 'said once, not once per window');
      expect(t.host.degradedGpsOnly, isTrue,
          reason: '#4195 invariant 1 — GPS recording is untouched');

      // A fifth unverified window must not repeat the announcement.
      adopt(t.sources[RecoveryVerifier.unverifiedCap],
          Obd2Service(FakeObd2Transport()));
      timers.elapse();
      expect(eventsOf(t.host, RecordingSessionEventKind.recoveryExhausted),
          hasLength(1));

      // The adapter finally reaches the car: the terminal state clears.
      adopt(t.sources[RecoveryVerifier.unverifiedCap + 1],
          Obd2Service(FakeObd2Transport()));
      t.mgr.onEngineData();
      expect(t.mgr.recoveryExhausted, isFalse);
      expect(t.host.degradedGpsOnly, isFalse);
    });

    test('the SAME instance adopted twice without engine data is refused',
        () async {
      final timers = _FakeTimers();
      final t = build(
          verifier: RecoveryVerifier(baseWindow: const Duration(milliseconds: 20), startTimer: timers.start));
      t.mgr.handleDrop();
      final mute = Obd2Service(FakeObd2Transport());

      adopt(t.sources[0], mute);
      timers.elapse(); // the window elapses — no sleeping
      adopt(t.sources[1], mute);
      timers.elapse(); // the window elapses — no sleeping

      expect(t.sources[1].adoptionGate!.isRefused(mute), isTrue,
          reason: 'an adoption that never delivered is a quick re-drop '
              'for the #3915 cycle breaker');
    });

    test(
        '#4237 — a duplicate adoption signal is single-flight: one polling '
        'start, one window, one verdict', () async {
      final timers = _FakeTimers();
      final t = build(
          verifier: RecoveryVerifier(baseWindow: const Duration(milliseconds: 40), startTimer: timers.start));
      t.mgr.handleDrop();
      adopt(t.sources[0], Obd2Service(FakeObd2Transport()));
      // A late second fire of the same source (a duplicate trigger).
      t.sources[0].onReconnect();

      expect(t.host.startSchedulerCalls, 1,
          reason: 'a second trigger must not start a second polling loop');
      expect(eventsOf(t.host, RecordingSessionEventKind.recoveryVerifying),
          hasLength(1));

      timers.elapse(); // the window elapses — no sleeping
      expect(eventsOf(t.host, RecordingSessionEventKind.recoveryUnverified),
          hasLength(1), reason: 'one window, one verdict');
    });

    test('stopping the trip cancels a pending verification', () async {
      final timers = _FakeTimers();
      final t = build(
          verifier: RecoveryVerifier(baseWindow: const Duration(milliseconds: 20), startTimer: timers.start));
      t.mgr.handleDrop();
      adopt(t.sources[0], Obd2Service(FakeObd2Transport()));

      t.mgr.cancelAllTimers();
      timers.elapse(); // the window elapses — no sleeping

      expect(t.mgr.awaitingEngineData, isFalse);
      expect(eventsOf(t.host, RecordingSessionEventKind.recoveryUnverified),
          isEmpty);
    });
  });
}

/// Reattach source that exposes what the manager wired in and lets the
/// test play the source's fire.
class _GateScanner implements Obd2ReattachSource {
  _GateScanner(this.onReconnect);

  final VoidCallback onReconnect;
  int startCalls = 0;
  int stopCalls = 0;

  @override
  VoidCallback? onPassiveWait;
  @override
  Obd2RecoveryOwnerStateCallback? onOwnerState; // #4385

  @override
  Obd2AdoptionGate? adoptionGate;

  @override
  int get currentAttemptNumber => 1;

  @override
  int get currentBackoffMs => 500;

  @override
  bool get isPassiveWaiting => false;

  @override
  Future<void> start() async => startCalls++;

  @override
  Future<void> stop() async => stopCalls++;
}

class _FakeHost implements DroppedSessionHost {
  // #4068 — the shared terminal transition (the real adapter routes it
  // to TripRunState.end()).
  @override
  void finalise() {
    stopped = true;
    started = false;
    pausedDueToDrop = false;
    degradedGpsOnly = false;
  }

  int disconnectDroppedServiceCalls = 0;
  int startSchedulerCalls = 0;
  final List<String> sessionEvents = [];

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
  String? sessionId = '2026-09-01T19:22:39.000';
  @override
  String? vehicleId = 'peugeot-107';
  @override
  String? vin;
  @override
  double? odometerStartKm = 100.0;
  @override
  double? odometerLatestKm = 101.0;
  @override
  bool automatic = false;
  @override
  List<TripSample> capturedSamples = [];
  @override
  List<GpsSampleDiagnostic> capturedGpsSampleDiagnostics = [];

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
  void disconnectDroppedService() => disconnectDroppedServiceCalls++;

  @override
  void noteSessionEvent(RecordingSessionEventKind kind, {String? detail}) =>
      sessionEvents.add(detail == null ? kind.name : '${kind.name}:$detail');

  @override
  TripSummary buildInProgressSummary() => _summary();

  @override
  TripSummary buildFinalSummary() => _summary();

  TripSummary _summary() => TripSummary(
        distanceKm: 1.0,
        maxRpm: 2200,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        startedAt: DateTime(2026, 9, 1, 19, 22),
        endedAt: DateTime(2026, 9, 1, 19, 30),
      );
}

/// Deterministic timers (#4237): nothing fires until the test elapses them.
class _FakeTimers {
  final List<_FakeTimer> _all = [];

  Timer start(Duration duration, void Function() callback) {
    final timer = _FakeTimer(callback);
    _all.add(timer);
    return timer;
  }

  /// Every pending window elapses now.
  void elapse() {
    for (final timer in List.of(_all)) {
      timer.fire();
    }
  }
}

class _FakeTimer implements Timer {
  _FakeTimer(this._callback);

  final void Function() _callback;
  bool _active = true;

  void fire() {
    if (!_active) return;
    _active = false;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}
