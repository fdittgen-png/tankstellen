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
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/obd2/data/paused_trip_repository.dart';
import 'package:tankstellen/features/obd2/data/session/dropped_session_host.dart';
import 'package:tankstellen/features/obd2/data/session/dropped_session_manager.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_reattach_source.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';
import 'package:tankstellen/features/trips/domain/entities/gps_sample_diagnostic.dart';
import 'package:tankstellen/features/trips/domain/entities/recording_session_event.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';

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
      await Hive.close();
      tmpDir.deleteSync(recursive: true);
    });

    ({DroppedSessionManager mgr, _FakeHost host, List<_GateScanner> sources})
        build({required Duration verifyWindow}) {
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
        recoveryVerifyWindow: verifyWindow,
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
      final t = build(verifyWindow: const Duration(milliseconds: 40));
      t.mgr.handleDrop();
      adopt(t.sources[0], Obd2Service(FakeObd2Transport()));

      expect(t.host.degradedGpsOnly, isTrue,
          reason: 'the adoption proved the adapter, not the car');
      expect(t.mgr.awaitingEngineData, isTrue);
      expect(eventsOf(t.host, RecordingSessionEventKind.recoveryVerifying),
          hasLength(1));
      expect(eventsOf(t.host, RecordingSessionEventKind.leftDegraded), isEmpty,
          reason: 'RED before #4196: journaled as recovered on the probe');

      await Future<void>.delayed(const Duration(milliseconds: 90));

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
      final t = build(verifyWindow: const Duration(milliseconds: 40));
      t.mgr.handleDrop();
      adopt(t.sources[0], Obd2Service(FakeObd2Transport()));

      t.mgr.onEngineData();

      expect(t.host.degradedGpsOnly, isFalse);
      expect(t.mgr.dropReason, isNull);
      expect(t.host.sessionEvents.last, 'leftDegraded:engine data verified');

      await Future<void>.delayed(const Duration(milliseconds: 90));
      t.mgr.onEngineData();
      expect(eventsOf(t.host, RecordingSessionEventKind.recoveryUnverified),
          isEmpty, reason: 'a verified recovery cancels the window');
      expect(eventsOf(t.host, RecordingSessionEventKind.leftDegraded),
          hasLength(1), reason: 'later parses are no-ops');
    });

    test(
        'consecutive unverified adoptions stretch the window (capped at 4×); '
        'engine data resets it', () async {
      final t = build(verifyWindow: const Duration(milliseconds: 20));
      t.mgr.handleDrop();

      final windows = <int>[];
      for (var i = 0; i < 5; i++) {
        final window = t.mgr.currentRecoveryVerifyWindow;
        windows.add(window.inMilliseconds);
        adopt(t.sources[i], Obd2Service(FakeObd2Transport()));
        await Future<void>.delayed(window + const Duration(milliseconds: 40));
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

    test('the SAME instance adopted twice without engine data is refused',
        () async {
      final t = build(verifyWindow: const Duration(milliseconds: 20));
      t.mgr.handleDrop();
      final mute = Obd2Service(FakeObd2Transport());

      adopt(t.sources[0], mute);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      adopt(t.sources[1], mute);
      await Future<void>.delayed(const Duration(milliseconds: 90));

      expect(t.sources[1].adoptionGate!.isRefused(mute), isTrue,
          reason: 'an adoption that never delivered is a quick re-drop '
              'for the #3915 cycle breaker');
    });

    test('stopping the trip cancels a pending verification', () async {
      final t = build(verifyWindow: const Duration(milliseconds: 20));
      t.mgr.handleDrop();
      adopt(t.sources[0], Obd2Service(FakeObd2Transport()));

      t.mgr.cancelAllTimers();
      await Future<void>.delayed(const Duration(milliseconds: 60));

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
  void startScheduler() {}
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
