// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4162 / #4311 — the OBD2 stop, the one lifecycle edge a user drives on
/// every trip, walked through its phases.
///
/// An OBD2 stop awaits a final odometer read before it saves, and the
/// live loop keeps ticking underneath it. The trace below records every
/// phase change the recording makes across a stop with a slow odometer.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_provider.dart';

import '../../../helpers/silence_error_logger.dart';
import '../support/phase_trace.dart';
import '../support/recording_disk_image.dart';
import '../support/recording_session_driver.dart';

void main() {
  silenceErrorLoggerSpool();

  late RecordingDisk disk;
  late RecordingSessionDriver driver;

  setUp(() async {
    disk = await RecordingDisk.open();
    driver = RecordingSessionDriver();
  });

  tearDown(() async {
    await driver.dispose();
    await disk.close();
  });

  test('an OBD2 stop walks only documented edges — or filed defects',
      () async {
    final container = driver.container();
    addTearDown(container.dispose);
    final transport = SlowOdometerTransport();
    final notifier = await RecordingSessionDriver.startObd2(container,
        transport: transport);
    RecordingSessionDriver.captureObd2Samples(notifier, 8);
    final trace = PhaseTrace(container);
    addTearDown(trace.close);

    // The live loop ticks every 250 ms; hold the odometer read past two.
    transport.odometerDelay = const Duration(milliseconds: 700);
    await notifier.stop();

    expect(container.read(tripRecordingProvider).phase,
        TripRecordingPhase.finished);
    expect(disk.historyRepo.loadAll(), hasLength(1));
    trace.expectLawful();
    // #4311 S1 / S2 — pinned until the fix removes them from
    // kKnownIllegalEdges.
    expect(trace.saw(TripRecordingPhase.saving, TripRecordingPhase.recording),
        isTrue,
        reason: 'S1: the live loop republished recording mid-save');
    expect(trace.saw(TripRecordingPhase.finished, TripRecordingPhase.saving),
        isTrue,
        reason: 'S2: the stop published finished, then saving again');
  });
}
