// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/providers/recording_pipeline.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/obd2/data/obd2_comm_diagnostics.dart';

import '../../../helpers/silence_error_logger.dart';

/// #3573 — the per-trip OBD2 comm-health capture reads a PROCESS-WIDE
/// singleton session. A GPS-only trip (no adapter identity) must therefore
/// NOT capture it: the field log 2026-07-13 showed a GPS-only trip
/// inheriting the supervisor's idle link and rendering a misleading
/// "0% complete · 0% utilization · no dropouts" card for a link the trip
/// never touched. Trips that bound a real OBD2 service keep the capture.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;

  setUp(() async {
    Obd2CommDiagnostics.instance.enabled = false;
    Obd2CommDiagnostics.instance.reset();
    tmpDir = Directory.systemTemp.createTempSync('comm_gating_');
    Hive.init(tmpDir.path);
    await Hive.openBox<String>(HiveBoxes.obd2TripHistory);
  });

  tearDown(() async {
    Obd2CommDiagnostics.instance.enabled = false;
    Obd2CommDiagnostics.instance.reset();
    await Hive.box<String>(HiveBoxes.obd2TripHistory).deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  TripSummary mkSummary(DateTime start) => TripSummary(
        distanceKm: 12,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 30,
        harshBrakes: 0,
        harshAccelerations: 0,
        startedAt: start,
        endedAt: start.add(const Duration(minutes: 20)),
      );

  /// Give the process-wide singleton a capturable session — the
  /// supervisor's idle link (connected, zero PID dispatches).
  void seedIdleLinkSession() {
    final diag = Obd2CommDiagnostics.instance;
    diag.enabled = true;
    diag.beginSession(linkKind: 'classic', redactedMac: '···········6:DA');
    diag.noteConnectionEvent(attempt: true, success: true);
  }

  test(
      'a GPS-only save (no adapter identity) does NOT capture the '
      'process-wide idle-link session', () async {
    seedIdleLinkSession();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(tripRecordingProvider.notifier);

    final start = DateTime(2026, 7, 13, 19, 33);
    final outcome = await notifier.debugSaveToHistory(
      mkSummary(start),
      gpsFixCount: 5,
      // adapterMac deliberately absent — the GPS-only pipeline never
      // stamps adapter identity.
    );
    expect(outcome, TripPersistOutcome.saved);

    final repo = container.read(tripHistoryRepositoryProvider);
    final saved = repo!.loadById(start.toIso8601String());
    expect(saved, isNotNull);
    expect(saved!.obd2Diagnostic, isNull,
        reason: 'a trip that never used the link must not inherit the '
            'singleton session as its comm-health card');
  });

  test('an OBD2 save (adapter identity present) still captures the session',
      () async {
    seedIdleLinkSession();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(tripRecordingProvider.notifier);

    final start = DateTime(2026, 7, 13, 20, 30);
    final outcome = await notifier.debugSaveToHistory(
      mkSummary(start),
      adapterMac: 'DC:0D:30:59:36:DA',
      adapterName: 'vLinker BM-Android',
      gpsFixCount: 5,
    );
    expect(outcome, TripPersistOutcome.saved);

    final repo = container.read(tripHistoryRepositoryProvider);
    final saved = repo!.loadById(start.toIso8601String());
    expect(saved, isNotNull);
    expect(saved!.obd2Diagnostic, isNotNull,
        reason: 'trips that bound an OBD2 service keep the #2912 capture');
  });
}
