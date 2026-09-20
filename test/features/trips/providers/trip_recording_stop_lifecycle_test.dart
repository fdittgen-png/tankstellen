// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4162 / #4311 — the OBD2 stop, the one lifecycle edge a user drives on
/// every trip, walked through its phases.
///
/// An OBD2 stop awaits a final odometer read before it saves, and the
/// live loop keeps ticking underneath it. Each test drives one of the
/// defects #4311 filed against that path: the phase flickering mid-save,
/// a kill waiting on the history write, the grace finalise resurrecting
/// its WAL row — and F1, a Stop arriving after the grace finalise.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/trips/domain/entities/trip_termination.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_provider.dart';

import '../../../helpers/silence_error_logger.dart';
import '../support/gated_trip_history_repository.dart';
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

  test('an OBD2 stop never flickers back: no saving→recording, no '
      'finished→saving (#4311 S1/S2)', () async {
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

    final state = container.read(tripRecordingProvider);
    expect(state.phase, TripRecordingPhase.finished);
    expect(state.saveStage, isNull,
        reason: 'S2: the save stage must not leak into finished');
    expect(disk.historyRepo.loadAll(), hasLength(1));
    expect(trace.illegal, isEmpty, reason: 'trace: ${trace.edges}');
    expect(trace.edges, [
      (TripRecordingPhase.recording, TripRecordingPhase.saving),
      (TripRecordingPhase.saving, TripRecordingPhase.finished),
    ]);
  });

  test('K1 — a kill while the OBD2 stop waits on the history write '
      'recovers the trip', () async {
    final gated = GatedTripHistoryRepository(box: disk.historyBox);
    final old = ProviderContainer(overrides: [
      ...driver.overrides,
      tripHistoryRepositoryProvider.overrideWithValue(gated),
    ]);
    final notifier = await RecordingSessionDriver.startObd2(old);
    RecordingSessionDriver.captureObd2Samples(notifier, 10);
    final stopping = notifier.stop();
    await gated.reached;

    final image = await disk.capture();
    gated.release();
    await stopping;
    await RecordingDisk.settle();
    old.dispose();

    final next = await disk.relaunch(image, overrides: driver.overrides);
    addTearDown(next.dispose);
    expect(next.read(tripRecordingProvider).phase,
        TripRecordingPhase.pausedDueToDrop,
        reason: 'the trip was not yet in history, so its WAL row is a trip '
            'to hand back — not a finalised row to discard');
    await next.read(tripRecordingProvider.notifier).stop();
    final saved = disk.historyRepo.loadAll();
    expect(saved, hasLength(1));
    expect(saved.single.samples, hasLength(10));
    expect(saved.single.termination?.reason,
        TripTerminationReason.recoveredAfterProcessDeath);
  });

  test('K2 — the grace-window finalise leaves no WAL row behind', () async {
    final container = driver.container();
    addTearDown(container.dispose);
    final trace = PhaseTrace(container);
    addTearDown(trace.close);
    final notifier = await RecordingSessionDriver.startObd2(container);
    RecordingSessionDriver.captureObd2Samples(notifier, 5);
    final ctl = notifier.debugController!
      ..debugTriggerDrop(reason: TripDropReason.silentFailure);
    await RecordingDisk.settle();

    await ctl.debugExpireGraceWindow();
    await RecordingDisk.settle();

    expect(container.read(tripRecordingProvider).phase,
        TripRecordingPhase.finished);
    expect(disk.historyRepo.loadAll(), hasLength(1));
    expect(disk.activeBox.isEmpty, isTrue,
        reason: 'the finalised trip is in history; a row on disk would be '
            'discarded at the next launch with a false error');
    expect(disk.pausedBox.isEmpty, isTrue);
    trace.expectLawful();
  });

  test('#4329 — the grace finalise tears the pipeline down as a Stop does: '
      'no Stop is needed, and nothing samples the finished trip', () async {
    final container = driver.container();
    addTearDown(container.dispose);
    final trace = PhaseTrace(container);
    addTearDown(trace.close);
    final notifier = await RecordingSessionDriver.startObd2(container);
    RecordingSessionDriver.captureObd2Samples(notifier, 5);
    final ctl = notifier.debugController!
      ..debugTriggerDrop(reason: TripDropReason.silentFailure);
    await RecordingDisk.settle();
    var readings = 0;
    final sub = ctl.live.listen((_) => readings++);
    addTearDown(sub.cancel);

    await ctl.debugExpireGraceWindow();
    await RecordingDisk.settle();

    expect(notifier.debugController, isNull,
        reason: 'the pipeline let go of the finished controller — its live '
            'and state subscriptions, GPS and link went with it');
    readings = 0;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(readings, 0, reason: 'the 250 ms loop no longer samples it');
    expect(container.read(tripRecordingProvider).phase,
        TripRecordingPhase.finished);
    expect(disk.historyRepo.loadAll(), hasLength(1),
        reason: 'the teardown saved nothing a second time');
    trace.expectLawful();
  });

  test('#4344 — a Stop while the start waits on its odometer read: the late '
      'read brings nothing alive, and nothing is saved or left on disk',
      () async {
    final container = driver.container();
    addTearDown(container.dispose);
    final trace = PhaseTrace(container);
    addTearDown(trace.close);
    final transport = SlowOdometerTransport()
      ..odometerDelay = const Duration(milliseconds: 600);
    final service = Obd2Service(transport);
    await service.connect();
    final notifier = container.read(tripRecordingProvider.notifier);
    final starting = notifier.start(service);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(notifier.debugController, isNotNull,
        reason: 'precondition: the start is under way');

    await notifier.stop();
    await starting;
    await Future<void>.delayed(const Duration(milliseconds: 800));

    expect(container.read(tripRecordingProvider).phase,
        TripRecordingPhase.idle);
    expect(notifier.debugController, isNull);
    expect(disk.activeBox.isEmpty, isTrue, reason: 'no WAL row was seeded');
    expect(disk.historyRepo.loadAll(), isEmpty);
    trace.expectLawful();
  });

  test('F1 — Stop after the grace window finalised the trip saves nothing '
      'twice', () async {
    final container = driver.container();
    addTearDown(container.dispose);
    final notifier = await RecordingSessionDriver.startObd2(container);
    RecordingSessionDriver.captureObd2Samples(notifier, 5);
    final ctl = notifier.debugController!
      ..debugTriggerDrop(reason: TripDropReason.silentFailure);
    await RecordingDisk.settle();
    await ctl.debugExpireGraceWindow();
    await RecordingDisk.settle();
    expect(disk.historyRepo.loadAll(), hasLength(1));

    // The recording screen's Stop (and the tile's) still reaches the
    // provider. (The tile's automatic variant only adds a badge bump.)
    await notifier.stop();
    await RecordingDisk.settle();

    expect(disk.historyRepo.loadAll(), hasLength(1),
        reason: 'one drive, one history row');
    expect(container.read(tripRecordingProvider).phase,
        TripRecordingPhase.finished);
  });
}
