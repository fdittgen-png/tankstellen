// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_reconnect_scanner.dart';
import 'package:tankstellen/features/consumption/data/obd2/dropped_session_host.dart';
import 'package:tankstellen/features/consumption/data/obd2/dropped_session_manager.dart';
import 'package:tankstellen/features/consumption/data/obd2/paused_trip_repository.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/gps_sample_diagnostic.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// Focused unit tests for the #2188 [DroppedSessionManager] — the
/// connection-drop RECOVERY state machine extracted from
/// `TripRecordingController`. Drives the manager against a fake
/// [DroppedSessionHost] + in-memory Hive repos + a hand-driven scanner
/// so every branch (persist-on-drop, silent window absorb vs escalate,
/// reconnect-within / after-grace, grace auto-finalise) is exercised
/// deterministically without a real `Obd2Service`, scheduler, or
/// wall-clock timer.
void main() {
  group('DroppedSessionManager (#2188)', () {
    late Directory tmpDir;
    late Box<String> pausedBox;
    late Box<String> historyBox;
    late PausedTripRepository pausedRepo;
    late TripHistoryRepository historyRepo;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('dropped_session_test_');
      Hive.init(tmpDir.path);
      pausedBox = await Hive.openBox<String>(
        'paused_${DateTime.now().microsecondsSinceEpoch}',
      );
      historyBox = await Hive.openBox<String>(
        'history_${DateTime.now().microsecondsSinceEpoch}',
      );
      pausedRepo = PausedTripRepository(box: pausedBox);
      historyRepo = TripHistoryRepository(box: historyBox);
    });

    tearDown(() async {
      await pausedBox.deleteFromDisk();
      await historyBox.deleteFromDisk();
      await Hive.close();
      tmpDir.deleteSync(recursive: true);
    });

    DateTime now() => DateTime(2026, 5, 28, 12);

    DroppedSessionManager build(
      _FakeHost host, {
      Duration grace = const Duration(hours: 1),
      Duration silentWindow = Duration.zero,
      String? pinnedMac,
      AdapterReconnectScanner? Function(String, VoidCallback)? scannerFactory,
    }) {
      return DroppedSessionManager(
        host: host,
        now: now,
        pauseGraceWindow: grace,
        silentReconnectWindow: silentWindow,
        pinnedAdapterMac: pinnedMac,
        reconnectScannerFactory: scannerFactory,
        pausedRepo: pausedRepo,
        historyRepo: historyRepo,
      );
    }

    test('drop with silent window disabled persists the snapshot and '
        'flips the host into the visible drop state', () {
      final host = _FakeHost();
      final mgr = build(host);

      mgr.handleDrop();

      expect(host.pausedDueToDrop, isTrue,
          reason: 'a drop with no silent window must go straight to the '
              'visible pause state');
      expect(mgr.dropReason, TripDropReason.transportError);
      expect(host.stopSchedulerCalls, 1,
          reason: 'the scheduler must be stopped the instant a drop fires');
      expect(host.pauseSchedulerCalls, 1,
          reason: '#2671 — dispatch must also be GATED on drop so a later '
              'tick never writes into the dead/flapping link');
      expect(host.clearErrorWindowCalls, 1);
      expect(host.emitStateCalls, greaterThanOrEqualTo(1));
      final saved = pausedRepo.loadAll();
      expect(saved, hasLength(1),
          reason: 'the in-progress snapshot must be persisted on drop');
      expect(saved.single.id, host.sessionId);
      expect(saved.single.vehicleId, host.vehicleId);
    });

    test('grace window expiry auto-finalises the paused trip into '
        'history and removes the paused row', () async {
      final host = _FakeHost();
      final mgr = build(host);

      mgr.handleDrop();
      expect(pausedRepo.loadAll(), hasLength(1));

      await mgr.expireGraceWindowNow();

      expect(historyRepo.loadAll(), hasLength(1),
          reason: 'grace expiry must finalise the partial trip into the '
              'trip-history box');
      expect(pausedRepo.loadAll(), isEmpty,
          reason: 'the paused row must be deleted once finalised');
      expect(host.stopped, isTrue);
      expect(host.started, isFalse);
      expect(host.pausedDueToDrop, isFalse);
    });

    test('grace-finalised trip persists the live sample buffer + GPS '
        'diagnostics and the automatic flag (#2291)', () async {
      final host = _FakeHost()
        ..automatic = true
        ..capturedSamples = [
          TripSample(
            timestamp: DateTime(2026, 5, 28, 12, 0, 1),
            speedKmh: 30,
            rpm: 1500,
          ),
          TripSample(
            timestamp: DateTime(2026, 5, 28, 12, 0, 2),
            speedKmh: 42,
            rpm: 1800,
          ),
        ]
        ..capturedGpsSampleDiagnostics = [
          GpsSampleDiagnostic(
            index: 0,
            timestamp: DateTime(2026, 5, 28, 12, 0, 1),
            lifecycleState: 'resumed',
          ),
        ];
      final mgr = build(host);

      mgr.handleDrop();
      await mgr.expireGraceWindowNow();

      final finalised = historyRepo.loadAll();
      expect(finalised, hasLength(1));
      final entry = finalised.single;
      expect(entry.samples, hasLength(2),
          reason: 'the still-live captured-sample buffer must be persisted '
              'so trip-detail charts render instead of the empty state');
      expect(entry.samples.first.speedKmh, 30);
      expect(entry.gpsSampleDiagnostics, hasLength(1),
          reason: 'GPS cadence diagnostics must round-trip too');
      expect(entry.automatic, isTrue,
          reason: 'an auto-recovered trip must keep its automatic flag, not '
              'default to manual');
    });

    test('grace expiry is a no-op when the host is no longer in the '
        'paused-due-to-drop state (e.g. already resumed)', () async {
      final host = _FakeHost();
      final mgr = build(host);

      mgr.handleDrop();
      // Simulate a resume having already cleared the drop state.
      host.pausedDueToDrop = false;
      mgr.cancelGrace();

      await mgr.expireGraceWindowNow();

      expect(historyRepo.loadAll(), isEmpty,
          reason: 'a cancelled / resumed session must not be finalised by '
              'a late grace-window fire');
    });

    test('reconnect WITHIN the visible-drop window resumes the trip '
        'via the host and stops the scanner before finalise', () async {
      final host = _FakeHost();
      VoidCallback? capturedOnReconnect;
      final scanner = _FakeScanner();
      final mgr = build(
        host,
        pinnedMac: 'AA:BB',
        scannerFactory: (mac, onReconnect) {
          capturedOnReconnect = onReconnect;
          scanner.onReconnect = onReconnect;
          return scanner;
        },
      );

      mgr.handleDrop();
      expect(host.pausedDueToDrop, isTrue);
      expect(scanner.startCalls, 1,
          reason: 'the visible drop must start the reconnect scanner');
      expect(capturedOnReconnect, isNotNull);

      // The scanner finds the adapter — fire its callback. (The fake
      // wires resumeFromReconnect to clear the host state, mirroring
      // the controller's resume().)
      capturedOnReconnect!.call();

      expect(host.resumeFromReconnectCalls, 1,
          reason: 'a reconnect after the drop went visible must drive the '
              'ordinary resume path');
      expect(host.pausedDueToDrop, isFalse);

      // The grace timer must have been cancelled by resume() — proven by
      // a late grace-expiry being a no-op (no history written).
      mgr.cancelGrace();
      await mgr.expireGraceWindowNow();
      expect(historyRepo.loadAll(), isEmpty,
          reason: 'the scanner reconnect must beat the grace-window '
              'auto-finalise to the punch');
    });

    test('reconnect AFTER the grace window finalised the trip is a '
        'no-op — the host is already stopped', () async {
      final host = _FakeHost();
      VoidCallback? capturedOnReconnect;
      final mgr = build(
        host,
        pinnedMac: 'AA:BB',
        scannerFactory: (mac, onReconnect) {
          capturedOnReconnect = onReconnect;
          return _FakeScanner()..onReconnect = onReconnect;
        },
      );

      mgr.handleDrop();
      await mgr.expireGraceWindowNow();
      expect(host.stopped, isTrue);
      expect(historyRepo.loadAll(), hasLength(1));
      final resumeCallsBefore = host.resumeFromReconnectCalls;

      // A late scanner reconnect after finalise: pausedDueToDrop is
      // already false, so onScannerReconnect must NOT re-resume.
      capturedOnReconnect?.call();

      expect(host.resumeFromReconnectCalls, resumeCallsBefore,
          reason: 'a reconnect after the trip was finalised must not '
              'resurrect it');
      expect(historyRepo.loadAll(), hasLength(1),
          reason: 'no duplicate finalisation from a late reconnect');
    });

    group('#1904 silent-reconnect window', () {
      test('a transport drop with a silent window stays invisible — no '
          'visible pause, scanner probing', () {
        final host = _FakeHost();
        final scanner = _FakeScanner();
        final mgr = build(
          host,
          silentWindow: const Duration(seconds: 6),
          pinnedMac: 'AA:BB',
          scannerFactory: (mac, onReconnect) =>
              scanner..onReconnect = onReconnect,
        );

        mgr.handleDrop();

        expect(host.pausedDueToDrop, isFalse,
            reason: 'a transport drop must NOT flip the visible state '
                'while the silent window is open');
        expect(mgr.silentlyReconnecting, isTrue);
        expect(scanner.startCalls, 1,
            reason: 'the scanner must probe during the silent window');
        expect(host.emitStateCalls, 0,
            reason: 'the silent window must stay invisible — no state '
                'emission');
        expect(pausedRepo.loadAll(), hasLength(1),
            reason: 'the snapshot is still persisted so a process kill '
                'mid-window is recoverable');
      });

      test('a silent reconnect inside the window resumes the scheduler '
          'without ever showing a pause', () {
        final host = _FakeHost();
        VoidCallback? capturedOnReconnect;
        final mgr = build(
          host,
          silentWindow: const Duration(seconds: 6),
          pinnedMac: 'AA:BB',
          scannerFactory: (mac, onReconnect) {
            capturedOnReconnect = onReconnect;
            return _FakeScanner()..onReconnect = onReconnect;
          },
        );

        mgr.handleDrop();
        expect(mgr.silentlyReconnecting, isTrue);

        capturedOnReconnect!.call();

        expect(mgr.silentlyReconnecting, isFalse,
            reason: 'a successful silent reconnect must clear the flag');
        expect(host.pausedDueToDrop, isFalse,
            reason: 'the user never saw a pause');
        expect(host.startSchedulerCalls, 1,
            reason: 'a silent reconnect must restart the polling loop');
        expect(host.resumeSchedulerCalls, 1,
            reason: '#2671 — a confirmed reconnect must re-open dispatch + '
                'reset failure streaks before the loop resumes ticking');
        expect(host.resetDropDetectorCalls, 1);
        expect(pausedRepo.loadAll(), isEmpty,
            reason: 'a silent reconnect must clear the stranded partial');
        expect(mgr.dropReason, isNull);
      });

      test('the silent window elapsing with no reconnect escalates to '
          'the visible drop', () async {
        final host = _FakeHost();
        final mgr = build(
          host,
          // Tiny silent window so the real escalation timer fires fast.
          silentWindow: const Duration(milliseconds: 30),
          pinnedMac: 'AA:BB',
          // A scanner that never calls onReconnect — adapter is gone.
          scannerFactory: (mac, onReconnect) =>
              _FakeScanner()..onReconnect = onReconnect,
        );

        mgr.handleDrop();
        expect(host.pausedDueToDrop, isFalse,
            reason: 'invisible while the silent window is still open');

        // Wait past the 30 ms silent window so the escalation timer fires.
        await Future<void>.delayed(const Duration(milliseconds: 120));

        expect(mgr.silentlyReconnecting, isFalse);
        expect(host.pausedDueToDrop, isTrue,
            reason: 'an elapsed silent window with no reconnect must '
                'surface the visible pause banner');
        expect(mgr.dropReason, TripDropReason.transportError);

        // Clean up the now-running grace timer.
        mgr.cancelAllTimers();
        await mgr.stopReconnectScanner();
      });

      test('a silentFailure drop bypasses the silent window — visible '
          'immediately even when a silent window is configured', () {
        final host = _FakeHost();
        final mgr = build(
          host,
          silentWindow: const Duration(seconds: 6),
          pinnedMac: 'AA:BB',
          scannerFactory: (mac, onReconnect) =>
              _FakeScanner()..onReconnect = onReconnect,
        );

        mgr.handleDrop(reason: TripDropReason.silentFailure);

        expect(host.pausedDueToDrop, isTrue,
            reason: 'a dead-ECU silentFailure cannot be cleared by a BT '
                'reconnect, so it must go straight to the visible state');
        expect(mgr.silentlyReconnecting, isFalse);
        expect(mgr.dropReason, TripDropReason.silentFailure);
      });
    });

    test('no pinned MAC / no factory → the scanner is never built; the '
        'grace window is the sole recovery path', () async {
      final host = _FakeHost();
      var factoryCalls = 0;
      final mgr = build(
        host,
        grace: const Duration(hours: 1),
        scannerFactory: (mac, onReconnect) {
          factoryCalls++;
          return null;
        },
        // pinnedMac omitted → null.
      );

      mgr.handleDrop();
      expect(factoryCalls, 0,
          reason: 'the factory must not be invoked without a pinned MAC');
      expect(mgr.reconnectScanner, isNull);

      await mgr.expireGraceWindowNow();
      expect(historyRepo.loadAll(), hasLength(1),
          reason: 'without a scanner the grace-window auto-finalise is '
              'the only recovery path');
    });

    test('restart with a persisted dropped session: a re-drop in a fresh '
        'manager converges on the same paused-trips row', () {
      // First "session" drops and persists.
      final host1 = _FakeHost();
      build(host1).handleDrop();
      expect(pausedRepo.loadAll(), hasLength(1));

      // Simulate an app restart: a brand-new manager + host with the
      // SAME session id re-drops (e.g. the recovery service rehydrated
      // the in-flight trip). The save overwrites at the same key, so the
      // box still holds exactly one row for that session.
      final host2 = _FakeHost()..sessionId = host1.sessionId;
      build(host2).handleDrop();

      final rows = pausedRepo.loadAll();
      expect(rows, hasLength(1),
          reason: 'a re-drop on the same session id must overwrite, not '
              'duplicate, the persisted paused row');
      expect(rows.single.id, host1.sessionId);
    });

    group('#2565 GPS-only degrade', () {
      test('a transportError drop when GPS is alive degrades to GPS-only '
          'instead of pausing — scanner probing, NO grace timer', () async {
        final host = _FakeHost()..gpsAlive = true;
        final scanner = _FakeScanner();
        final mgr = build(
          host,
          // A long silent window — proves degrade OUTRANKS the silent
          // window (it must not even enter the invisible-reconnect path).
          silentWindow: const Duration(seconds: 6),
          // A short grace so a wrongly-armed timer would auto-finalise
          // fast — its NON-firing is the assertion below.
          grace: const Duration(milliseconds: 30),
          pinnedMac: 'AA:BB',
          scannerFactory: (mac, onReconnect) =>
              scanner..onReconnect = onReconnect,
        );

        mgr.handleDrop();

        expect(host.degradedGpsOnly, isTrue,
            reason: 'an OBD2 drop on a live-GPS drive must degrade to '
                'GPS-only recording, not pause');
        expect(host.pausedDueToDrop, isFalse,
            reason: 'degraded recording must never flip the pause state');
        expect(mgr.silentlyReconnecting, isFalse,
            reason: 'degrade outranks the #1904 silent window entirely');
        expect(scanner.startCalls, 1,
            reason: 'the reconnect scanner must probe so OBD2 can re-attach');
        expect(host.stopSchedulerCalls, 1);
        expect(host.disconnectDroppedServiceCalls, 1);
        expect(host.emitStateCalls, greaterThanOrEqualTo(1),
            reason: 'degraded mode is visible — the GPS banner must surface');

        // Wait well past the grace window: a degraded trip must NEVER
        // auto-finalise (no grace timer was armed).
        await Future<void>.delayed(const Duration(milliseconds: 120));
        expect(historyRepo.loadAll(), isEmpty,
            reason: 'a degraded trip is actively recording — it must never '
                'auto-finalise/discard via a grace timer');
        expect(host.degradedGpsOnly, isTrue,
            reason: 'still degraded after the would-be grace window');

        await mgr.stopReconnectScanner();
      });

      test('a silentFailure drop when GPS is alive ALSO degrades — a dead '
          'ECU still lets GPS carry the trip', () {
        final host = _FakeHost()..gpsAlive = true;
        final mgr = build(host);

        mgr.handleDrop(reason: TripDropReason.silentFailure);

        expect(host.degradedGpsOnly, isTrue);
        expect(host.pausedDueToDrop, isFalse);
        expect(mgr.dropReason, TripDropReason.silentFailure);
      });

      test('a drop with NO recent GPS fix keeps the classic pause path '
          '(regression-lock)', () {
        final host = _FakeHost(); // gpsAlive defaults to false.
        final mgr = build(host);

        mgr.handleDrop();

        expect(host.degradedGpsOnly, isFalse);
        expect(host.pausedDueToDrop, isTrue,
            reason: 'with no live GPS the OBD2 drop must pause exactly as '
                'before — no behaviour change on the dead-GPS path');
      });

      test('reconnect while degraded restores OBD2 recording — scheduler '
          'restarted, degrade flag cleared, no pause ever shown', () {
        final host = _FakeHost()..gpsAlive = true;
        VoidCallback? capturedOnReconnect;
        final mgr = build(
          host,
          pinnedMac: 'AA:BB',
          scannerFactory: (mac, onReconnect) {
            capturedOnReconnect = onReconnect;
            return _FakeScanner()..onReconnect = onReconnect;
          },
        );

        mgr.handleDrop();
        expect(host.degradedGpsOnly, isTrue);
        final startsBefore = host.startSchedulerCalls;

        capturedOnReconnect!.call();

        expect(host.degradedGpsOnly, isFalse,
            reason: 'a reconnect must drop back to full OBD2 recording');
        expect(host.pausedDueToDrop, isFalse,
            reason: 'the user never saw a pause');
        expect(host.startSchedulerCalls, startsBefore + 1,
            reason: 'OBD2 polling must restart on reconnect');
        expect(host.resetDropDetectorCalls, greaterThanOrEqualTo(1));
        expect(mgr.dropReason, isNull);
      });

      test('escalateDegradedToPaused flips a degraded trip whose GPS also '
          'died into the visible pause (both sources gone)', () {
        final host = _FakeHost()..gpsAlive = true;
        final mgr = build(host, grace: const Duration(hours: 1));

        mgr.handleDrop();
        expect(host.degradedGpsOnly, isTrue);

        mgr.escalateDegradedToPaused();

        expect(host.degradedGpsOnly, isFalse);
        expect(host.pausedDueToDrop, isTrue,
            reason: 'when GPS dies too, BOTH sources are gone → the '
                'visible pause banner must finally show');
        expect(mgr.dropReason, TripDropReason.transportError);

        mgr.cancelAllTimers();
      });
    });

    test('cancelAllTimers clears the silent flag so a stopped session '
        'cannot escalate after teardown', () {
      final host = _FakeHost();
      final mgr = build(
        host,
        silentWindow: const Duration(seconds: 6),
        pinnedMac: 'AA:BB',
        scannerFactory: (mac, onReconnect) =>
            _FakeScanner()..onReconnect = onReconnect,
      );

      mgr.handleDrop();
      expect(mgr.silentlyReconnecting, isTrue);

      mgr.cancelAllTimers();
      expect(mgr.silentlyReconnecting, isFalse,
          reason: 'stop()/cancelAllTimers must clear the silent flag so a '
              'pending window can never escalate after teardown');
    });
  });
}

/// Deterministic fake of the recording session the manager recovers.
/// Mirrors how `TripRecordingController` exposes its lifecycle to the
/// manager: [resumeFromReconnect] clears the drop state the same way the
/// real controller's resume() does, so the manager's reconnect path can
/// be asserted end-to-end.
class _FakeHost implements DroppedSessionHost {
  int stopSchedulerCalls = 0;
  int pauseSchedulerCalls = 0;
  int resumeSchedulerCalls = 0;
  int disconnectDroppedServiceCalls = 0;
  int startSchedulerCalls = 0;
  int resetDropDetectorCalls = 0;
  int clearErrorWindowCalls = 0;
  int emitStateCalls = 0;
  int resumeFromReconnectCalls = 0;

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

  /// #2565 — drives the degrade decision in `handleDrop`. Default false
  /// (dead GPS → classic pause path); the degrade tests flip it true.
  @override
  bool gpsAlive = false;

  @override
  String? sessionId = '2026-05-28T12:00:00.000';
  @override
  String? vehicleId = 'car-under-test';
  @override
  String? vin = 'WVWZZZ1JZXW000001';
  @override
  double? odometerStartKm = 1000.0;
  @override
  double? odometerLatestKm = 1005.0;
  @override
  bool automatic = false;

  @override
  List<TripSample> capturedSamples = [];

  @override
  List<GpsSampleDiagnostic> capturedGpsSampleDiagnostics = [];

  @override
  void stopScheduler() => stopSchedulerCalls++;

  @override
  void pauseScheduler() => pauseSchedulerCalls++;

  @override
  void resumeScheduler() => resumeSchedulerCalls++;

  @override
  void disconnectDroppedService() => disconnectDroppedServiceCalls++;

  @override
  void startScheduler() => startSchedulerCalls++;

  @override
  void resetDropDetector() => resetDropDetectorCalls++;

  @override
  void clearDropDetectorErrorWindow() => clearErrorWindowCalls++;

  @override
  void emitState() => emitStateCalls++;

  @override
  void resumeFromReconnect() {
    resumeFromReconnectCalls++;
    // Mirror TripRecordingController.resume()'s drop-recovery half.
    pausedDueToDrop = false;
    startScheduler();
  }

  @override
  TripSummary buildInProgressSummary() => _summary(distanceKm: 2.5);

  @override
  TripSummary buildFinalSummary() => _summary(distanceKm: 5.0);

  TripSummary _summary({required double distanceKm}) => TripSummary(
        distanceKm: distanceKm,
        maxRpm: 2200,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        startedAt: DateTime(2026, 5, 28, 12),
        endedAt: DateTime(2026, 5, 28, 12, 10),
      );
}

/// Observation-only scanner: records start()/stop() counts and lets a
/// test fire its [onReconnect] manually. The real backoff math is
/// covered by `adapter_reconnect_scanner_test.dart`.
class _FakeScanner implements AdapterReconnectScanner {
  VoidCallback? onReconnect;
  int startCalls = 0;
  int stopCalls = 0;
  bool _scanning = false;

  @override
  String get pinnedMac => 'AA:BB';

  @override
  Duration get currentBackoff => const Duration(seconds: 5);

  @override
  int get currentAttemptNumber => 1;

  @override
  int get currentBackoffMs => 5000;

  @override
  bool get isScanning => _scanning;

  @override
  bool get isPassiveWaiting => false;

  @override
  VoidCallback? onPassiveWait;

  @override
  int get consecutiveMisses => 0;

  @override
  Future<void> start() async {
    _scanning = true;
    startCalls++;
  }

  @override
  Future<void> stop() async {
    _scanning = false;
    stopCalls++;
  }
}
