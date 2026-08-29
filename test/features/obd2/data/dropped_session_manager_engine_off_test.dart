// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3859 (Epic #3855) — `TripDropReason.engineOff`: the driver switched the
// engine off with the recording running (or started before starting it).
// The drop machinery for a BROKEN link — service teardown, the fallback
// marker, the reconnect scanner — is exactly what turned a parked car into
// dial storms and a "connection dropped" verdict. This state does none of
// it: recording continues on GPS, the link is kept, nothing dials, and the
// engine transition resumes on the same link.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/obd2/data/session/dropped_session_host.dart';
import 'package:tankstellen/features/obd2/data/session/dropped_session_manager.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_reattach_source.dart';
import 'package:tankstellen/features/obd2/data/paused_trip_repository.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';
import 'package:tankstellen/features/trips/domain/entities/gps_sample_diagnostic.dart';
import 'package:tankstellen/features/trips/domain/entities/recording_session_event.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';

void main() {
  late Directory tmpDir;
  late Box<String> pausedBox;
  late Box<String> historyBox;
  late PausedTripRepository pausedRepo;
  late TripHistoryRepository historyRepo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('engine_off_test_');
    Hive.init(tmpDir.path);
    // Each test owns a fresh Hive directory, so fixed box names are unique.
    pausedBox = await Hive.openBox<String>('paused');
    historyBox = await Hive.openBox<String>('history');
    pausedRepo = PausedTripRepository(box: pausedBox);
    historyRepo = TripHistoryRepository(box: historyBox);
  });

  tearDown(() async {
    await pausedBox.deleteFromDisk();
    await historyBox.deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  DroppedSessionManager build(_Host host) =>
      DroppedSessionManager(
        host: host,
        now: () => DateTime(2026, 8, 29, 20),
        pauseGraceWindow: const Duration(hours: 1),
        silentReconnectWindow: Duration.zero,
        pinnedAdapterMac: 'AA:BB',
        reconnectScannerFactory: (mac, onReconnect) {
          host.scannerFactoryCalls++;
          return _Scanner()..onReconnect = onReconnect;
        },
        pausedRepo: pausedRepo,
        historyRepo: historyRepo,
      );

  test('an engine-off drop with GPS alive keeps recording, keeps the link, '
      'and dials NOTHING', () {
    final host = _Host()..gpsAlive = true;
    final mgr = build(host);

    mgr.handleDrop(reason: TripDropReason.engineOff);

    expect(host.degradedGpsOnly, isTrue, reason: 'GPS keeps the trip going');
    expect(host.pausedDueToDrop, isFalse);
    expect(mgr.dropReason, TripDropReason.engineOff);
    expect(host.stopSchedulerCalls, 1, reason: 'no PID traffic into a silent bus');
    expect(host.pauseSchedulerCalls, 1);
    expect(host.disconnectDroppedServiceCalls, 0,
        reason: 'the link is KEPT — the adapter still answers AT, and the '
            'voltage watch needs it');
    expect(host.scannerFactoryCalls, 0,
        reason: 'the reattach source would fire on the still-ready link '
            'and resume polling into a silent bus');
    expect(host.events.map((e) => e.kind),
        containsAll([
          RecordingSessionEventKind.linkEngineOff,
          RecordingSessionEventKind.degradedGpsOnly,
        ]));
    expect(pausedRepo.loadAll(), hasLength(1),
        reason: 'the snapshot is still persisted — a crash while parked '
            'must not lose the drive');
  });

  test('the engine transition on a LIVE link resumes polling on it', () {
    final host = _Host()..gpsAlive = true;
    final mgr = build(host);
    mgr.handleDrop(reason: TripDropReason.engineOff);

    mgr.onEngineRunning(linkAlive: true);

    expect(host.degradedGpsOnly, isFalse);
    expect(mgr.dropReason, isNull);
    expect(host.resumeSchedulerCalls, 1);
    expect(host.startSchedulerCalls, 1,
        reason: 'startScheduler carries the protocol gate: the quiet-window '
            '0100 runs NOW that the bus can answer');
    expect(host.resetDropDetectorCalls, 1);
    expect(host.scannerFactoryCalls, 0);
    expect(host.events.last.kind, RecordingSessionEventKind.leftDegraded);
    expect(pausedRepo.loadAll(), isEmpty,
        reason: 'the paused row is cleared on the live resume');
  });

  test('the engine transition with the link GONE falls into the ordinary '
      'reattach wait', () {
    final host = _Host()..gpsAlive = true;
    final mgr = build(host);
    mgr.handleDrop(reason: TripDropReason.engineOff);

    mgr.onEngineRunning(linkAlive: false);

    expect(host.degradedGpsOnly, isTrue,
        reason: 'still GPS-only until the supervisor re-binds a fresh link');
    expect(mgr.dropReason, TripDropReason.transportError);
    expect(host.scannerFactoryCalls, 1,
        reason: 'NOW the reattach source is wanted: the supervisor, woken '
            'by the same transition, will reach ready');
    expect(host.startSchedulerCalls, 0);
  });

  test('onEngineRunning is a no-op outside the engine-off wait', () {
    final host = _Host()..gpsAlive = true;
    final mgr = build(host);
    mgr.handleDrop(); // an ordinary transport drop → degraded (transportError)
    final scannerCalls = host.scannerFactoryCalls;

    mgr.onEngineRunning(linkAlive: true);

    expect(mgr.dropReason, TripDropReason.transportError);
    expect(host.startSchedulerCalls, 0);
    expect(host.scannerFactoryCalls, scannerCalls);
  });

  test('an engine-off drop with GPS dead takes the visible pause path — '
      'nothing is left to record', () {
    final host = _Host()..gpsAlive = false;
    final mgr = build(host);

    mgr.handleDrop(reason: TripDropReason.engineOff);

    expect(host.pausedDueToDrop, isTrue);
    expect(host.degradedGpsOnly, isFalse);
    expect(mgr.dropReason, TripDropReason.engineOff);
  });

  test('finaliseParked ends an auto-record trip into history (#3862)',
      () async {
    final host = _Host()
      ..gpsAlive = true
      ..automatic = true;
    final mgr = build(host);
    mgr.handleDrop(reason: TripDropReason.engineOff);

    await mgr.finaliseParked();

    expect(host.stopped, isTrue);
    expect(host.started, isFalse);
    expect(host.degradedGpsOnly, isFalse);
    expect(historyRepo.loadAll(), hasLength(1));
    expect(pausedRepo.loadAll(), isEmpty);
    final ended = host.events.lastWhere(
        (e) => e.kind == RecordingSessionEventKind.ended);
    expect(ended.detail, 'engineOffParked');
  });

  test('a second finaliseParked after stop is a no-op', () async {
    final host = _Host()..gpsAlive = true;
    final mgr = build(host);
    mgr.handleDrop(reason: TripDropReason.engineOff);
    await mgr.finaliseParked();
    await mgr.finaliseParked();
    expect(historyRepo.loadAll(), hasLength(1));
  });
}

class _Scanner implements Obd2ReattachSource {
  VoidCallback? onReconnect;
  @override
  set onPassiveWait(VoidCallback? callback) {}
  @override
  bool get isPassiveWaiting => false;
  @override
  int get currentAttemptNumber => 0;
  @override
  int get currentBackoffMs => 0;
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
}

class _Host implements DroppedSessionHost {
  int stopSchedulerCalls = 0;
  int pauseSchedulerCalls = 0;
  int resumeSchedulerCalls = 0;
  int disconnectDroppedServiceCalls = 0;
  int startSchedulerCalls = 0;
  int resetDropDetectorCalls = 0;
  int clearErrorWindowCalls = 0;
  int emitStateCalls = 0;
  int resumeFromReconnectCalls = 0;
  int scannerFactoryCalls = 0;
  final List<({RecordingSessionEventKind kind, String? detail})> events = [];

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
  String? get sessionId => 'session-1';
  @override
  String? get vehicleId => 'veh-1';
  @override
  String? get vin => null;
  @override
  double? get odometerStartKm => null;
  @override
  double? get odometerLatestKm => null;
  @override
  bool automatic = false;
  @override
  List<TripSample> capturedSamples = [];
  @override
  Future<List<TripSample>> collectAllSamples() async => capturedSamples;
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
  void noteSessionEvent(RecordingSessionEventKind kind, {String? detail}) =>
      events.add((kind: kind, detail: detail));
  @override
  void emitState() => emitStateCalls++;
  @override
  void resumeFromReconnect() {
    resumeFromReconnectCalls++;
    pausedDueToDrop = false;
  }

  @override
  TripSummary buildInProgressSummary() => _summary();
  @override
  TripSummary buildFinalSummary() => _summary();

  TripSummary _summary() => TripSummary(
        distanceKm: 3.2,
        maxRpm: 2400,
        avgLPer100Km: null,
        fuelLitersConsumed: null,
        startedAt: DateTime(2026, 8, 29, 19, 50),
        endedAt: DateTime(2026, 8, 29, 20),
        harshBrakes: 0,
        harshAccelerations: 0,
        idleSeconds: 0,
        highRpmSeconds: 0,
      );
}
