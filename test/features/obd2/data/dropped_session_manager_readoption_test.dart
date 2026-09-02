// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3915 (Epic #3914) — the re-adoption cycle breaker in
// [DroppedSessionManager]: the SAME `Obd2Service` instance rebound and
// dropped again twice within 60 s of its rebind is refused for the rest
// of the trip (journal `adoptionRefused`), and the reattach source is
// handed the gate so it waits for a DIFFERENT instance. The 2026-09-01
// field trip re-adopted one instance every ~8.2 s for 43 minutes.
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
  group('DroppedSessionManager re-adoption cycle breaker (#3915)', () {
    late Directory tmpDir;
    late Box<String> pausedBox;
    late Box<String> historyBox;
    late DateTime clock;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('readoption_test_');
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
        build() {
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
        pausedRepo: PausedTripRepository(box: pausedBox),
        historyRepo: TripHistoryRepository(box: historyBox),
      );
      return (mgr: mgr, host: host, sources: sources);
    }

    /// The reattach source's fire, as production does it: report the
    /// adoption to the gate, then the manager's reconnect callback.
    void rebind(_GateScanner source, Obd2Service svc) {
      source.adoptionGate!.noteAdopted(svc);
      source.onReconnect();
    }

    Iterable<String> refusals(_FakeHost host) => host.sessionEvents
        .where((e) => e.startsWith(RecordingSessionEventKind.adoptionRefused.name));

    test(
        'the SAME instance rebound and dropped twice within 60 s is '
        'refused: journal event, gate refuses it, the owner seam still '
        'runs, and a fresh source waits with the same gate', () {
      final t = build();
      final corpse = Obd2Service(FakeObd2Transport());

      // Drop 1 — the first drop of the trip; GPS alive ⇒ degrade + source.
      t.mgr.handleDrop();
      expect(t.host.degradedGpsOnly, isTrue);
      expect(t.sources, hasLength(1));
      final gate = t.sources[0].adoptionGate;
      expect(gate, isNotNull, reason: 'the manager wires its gate in');

      // The source hands the trip `corpse`; 8.2 s later it drops again.
      rebind(t.sources[0], corpse);
      expect(t.host.degradedGpsOnly, isFalse);
      clock = clock.add(const Duration(milliseconds: 8200));
      t.mgr.handleDrop();
      expect(gate!.isRefused(corpse), isFalse,
          reason: 'ONE quick re-drop is link weather, not a cycle');
      expect(refusals(t.host), isEmpty);
      expect(t.sources, hasLength(2));

      // The same instance comes back once more and dies again.
      rebind(t.sources[1], corpse);
      clock = clock.add(const Duration(milliseconds: 8200));
      t.mgr.handleDrop();

      expect(gate.isRefused(corpse), isTrue,
          reason: 'the field loop: the same instance, twice in a row, '
              'within the window — refused for the rest of the trip');
      expect(refusals(t.host), hasLength(1));
      expect(refusals(t.host).single, contains('transportError'));
      expect(t.host.disconnectDroppedServiceCalls, 3,
          reason: 'the owner seam (recycle) runs on every drop, the '
              'refused one included');
      expect(t.host.degradedGpsOnly, isTrue,
          reason: 'GPS-only continues while waiting for a different link');
      expect(t.sources, hasLength(3));
      expect(identical(t.sources[2].adoptionGate, gate), isTrue,
          reason: 'the new source carries the same gate, so it will not '
              'fire the refused instance');
      expect(t.sources[2].startCalls, 1);

      // A different instance is welcome.
      final fresh = Obd2Service(FakeObd2Transport());
      expect(gate.isRefused(fresh), isFalse);
    });

    test(
        'a different instance resets the streak, and a re-drop after the '
        'window does not count', () {
      final t = build();
      final a = Obd2Service(FakeObd2Transport());
      final b = Obd2Service(FakeObd2Transport());

      t.mgr.handleDrop();
      rebind(t.sources[0], a);
      clock = clock.add(const Duration(seconds: 8));
      t.mgr.handleDrop(); // quick re-drop #1 of a

      rebind(t.sources[1], b); // a DIFFERENT instance: streak resets
      clock = clock.add(const Duration(seconds: 8));
      t.mgr.handleDrop(); // quick re-drop #1 of b
      final gate = t.sources[0].adoptionGate!;
      expect(gate.isRefused(a), isFalse);
      expect(gate.isRefused(b), isFalse);

      rebind(t.sources[2], b);
      clock = clock.add(const Duration(seconds: 90)); // lived past the window
      t.mgr.handleDrop();
      expect(gate.isRefused(b), isFalse,
          reason: 'a link that lived 90 s earned its adoption');
      expect(refusals(t.host), isEmpty);
    });

    test('ReadoptionCycleBreaker — identity, not equality, and the '
        'window is measured from the LAST rebind', () {
      final breaker = ReadoptionCycleBreaker(now: () => clock);
      final a = Obd2Service(FakeObd2Transport());
      expect(breaker.noteDrop(), isNull, reason: 'nothing adopted yet');

      breaker.noteAdopted(a);
      clock = clock.add(const Duration(seconds: 59));
      expect(breaker.noteDrop(), isNull);
      breaker.noteAdopted(a);
      clock = clock.add(const Duration(seconds: 61));
      expect(breaker.noteDrop(), isNull,
          reason: 'past the window: the streak resets');
      breaker.noteAdopted(a);
      clock = clock.add(const Duration(seconds: 1));
      expect(breaker.noteDrop(), isNull, reason: 'streak restarted at 1');
      breaker.noteAdopted(a);
      clock = clock.add(const Duration(seconds: 1));
      expect(breaker.noteDrop(), same(a));
      expect(breaker.isRefused(a), isTrue);
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
