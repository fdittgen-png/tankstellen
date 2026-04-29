import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/consumption/data/obd2/active_trip_repository.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';

/// Tests for #1303 — the [TripRecording] provider's write-through
/// snapshot path.
///
/// Covers:
///   1. start() seeds an active snapshot (the wiring is alive even
///      before a single live sample lands),
///   2. an explicit `onAppBackgrounded()` force-flush writes the
///      latest captured-samples buffer to disk,
///   3. stop() clears the snapshot — a finalised trip must not
///      lure the recovery service into resurrecting it on next
///      cold start,
///   4. reset() clears the snapshot — a discarded trip must also
///      not survive into the next launch,
///   5. restoreFromSnapshot rehydrates the provider into a
///      pausedDueToDrop state with the stored vehicle id.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<String> activeBox;
  late Box<String> historyBox;
  late ActiveTripRepository activeRepo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync(
      'trip_recording_active_snapshot_test_',
    );
    Hive.init(tmpDir.path);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    activeBox = await Hive.openBox<String>('active_$stamp');
    historyBox = await Hive.openBox<String>(HiveBoxes.obd2TripHistory);
    activeRepo = ActiveTripRepository(box: activeBox);
  });

  tearDown(() async {
    await activeBox.deleteFromDisk();
    await historyBox.deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  Future<TripRecording> startTrip(ProviderContainer container) async {
    final service = Obd2Service(FakeObd2Transport(_elmOk()));
    await service.connect();
    final notifier = container.read(tripRecordingProvider.notifier);
    notifier.debugSetActiveRepo(activeRepo);
    await notifier.start(service);
    return notifier;
  }

  test('start() seeds an active snapshot on disk', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = await startTrip(container);
    addTearDown(() async {
      // Tear down the controller cleanly so its scheduler / emit
      // timer doesn't fire state changes after the provider is
      // disposed. Without this Riverpod throws "use after dispose"
      // from the still-running listeners.
      await notifier.stop();
    });
    expect(notifier.debugController, isNotNull);

    // The seed flush is async — yield once so the unawaited
    // `_flushActiveSnapshot(force: true)` completes.
    await Future<void>.delayed(Duration.zero);

    final stored = activeRepo.loadSnapshot();
    expect(stored, isNotNull,
        reason: 'start() must seed an initial snapshot so a process '
            'death before the first live sample is still recoverable');
    expect(stored!.phase, 'recording');
  });

  test(
    'onAppBackgrounded() force-flushes the captured-samples buffer',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = await startTrip(container);
      addTearDown(() async {
        await notifier.stop();
      });
      final ctl = notifier.debugController!;

      // Populate the captured-samples buffer that
      // `_buildSnapshotFor` reads. We don't need to drive the
      // 4 Hz emit loop — the buffer is what gets serialised.
      final start = DateTime.now();
      for (int i = 0; i < 6; i++) {
        ctl.debugCaptureSample(_sampleFor(start, i));
      }

      // Force a flush via the lifecycle hook. The hook is async so
      // we await it directly.
      await notifier.onAppBackgrounded();

      final stored = activeRepo.loadSnapshot();
      expect(stored, isNotNull);
      expect(stored!.samples, isNotEmpty,
          reason: 'lifecycle force-flush must persist the captured '
              'samples buffer — without this a process kill mid-drive '
              'loses every emit since the last 5 s debounce window');
    },
  );

  test('stop() clears the snapshot', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = await startTrip(container);
    final ctl = notifier.debugController!;
    final start = DateTime.now();
    for (int i = 0; i < 6; i++) {
      // Drive both the recorder and the captured-samples buffer
      // so stop() finds enough state to persist a TripHistoryEntry
      // (the empty-trip early-return otherwise short-circuits and
      // the snapshot-clear path doesn't get exercised).
      ctl.debugInjectSample(
        speedKmh: 40 + i.toDouble(),
        rpm: 1800,
        at: start.add(Duration(seconds: i)),
        fuelRateLPerHour: 5.5,
      );
      ctl.debugCaptureSample(_sampleFor(start, i));
    }
    await notifier.onAppBackgrounded();
    expect(activeRepo.loadSnapshot(), isNotNull);

    await notifier.stop();

    expect(activeRepo.loadSnapshot(), isNull,
        reason: 'a finalised trip must not survive into the next '
            'cold start as a recoverable in-progress trip');
  });

  test('reset() clears the snapshot', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = await startTrip(container);
    addTearDown(() async {
      await notifier.stop();
    });
    await Future<void>.delayed(Duration.zero);
    expect(activeRepo.loadSnapshot(), isNotNull);

    notifier.reset();
    // reset() fires an unawaited clear — yield so it completes.
    await Future<void>.delayed(Duration.zero);

    expect(activeRepo.loadSnapshot(), isNull);
  });

  test(
    'restoreFromSnapshot rehydrates the provider into pausedDueToDrop',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(tripRecordingProvider.notifier);
      notifier.debugSetActiveRepo(activeRepo);

      final start = DateTime.utc(2026, 4, 28, 9, 0);
      final snap = ActiveTripSnapshot(
        id: start.toIso8601String(),
        vehicleId: 'veh-restored',
        vin: 'VIN-RESTORED',
        automatic: true,
        phase: 'recording',
        summary: const _RestoredSummary().build(),
        samples: const [],
        odometerStartKm: 1000.0,
        odometerLatestKm: 1010.0,
        startedAt: start,
        lastFlushedAt: start.add(const Duration(minutes: 30)),
      );

      final applied = notifier.restoreFromSnapshot(snap);
      expect(applied, isTrue);
      expect(notifier.state.phase, TripRecordingPhase.pausedDueToDrop);
      expect(notifier.lastTripVehicleId, 'veh-restored');
      expect(notifier.lastTripStartedAt, start);
    },
  );

  test(
    'restoreFromSnapshot is a no-op when a trip is already active',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = await startTrip(container);
      addTearDown(() async {
        await notifier.stop();
      });
      // Provider is now mid-trip; recovery must NOT clobber it.
      final start = DateTime.utc(2026, 4, 28, 9, 0);
      final snap = ActiveTripSnapshot(
        id: 'phantom',
        vehicleId: 'veh-phantom',
        vin: null,
        automatic: false,
        phase: 'recording',
        summary: const _RestoredSummary().build(),
        samples: const [],
        odometerStartKm: null,
        odometerLatestKm: null,
        startedAt: start,
        lastFlushedAt: start,
      );
      final applied = notifier.restoreFromSnapshot(snap);
      expect(applied, isFalse,
          reason: 'a fresh launch that already started a trip must not '
              'be hijacked by a stale recovery snapshot');
    },
  );
}

/// Tiny builder so the test can construct a minimal valid summary
/// without dragging the production constants in. Keeps the test
/// readable when the provider restoration assertion only cares
/// about identity / phase, not summary contents.
class _RestoredSummary {
  const _RestoredSummary();
  TripSummary build() => const TripSummary(
        distanceKm: 5.5,
        maxRpm: 3500,
        highRpmSeconds: 2,
        idleSeconds: 30,
        harshBrakes: 1,
        harshAccelerations: 0,
      );
}

/// Build a [TripSample] for the captured-buffer feed. Inlined so the
/// test stays focused on the provider behaviour without pulling more
/// imports than necessary.
TripSample _sampleFor(DateTime start, int i) => TripSample(
      timestamp: start.add(Duration(seconds: i)),
      speedKmh: 40 + i.toDouble(),
      rpm: 1800 + i * 5,
      fuelRateLPerHour: 5.5,
    );

/// Minimal ELM327 fake transport responses so a fresh
/// [Obd2Service.connect] succeeds without simulating the full
/// adapter handshake.
Map<String, String> _elmOk() => const {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
      '01A6': '41 A6 00 01 6A 2C>',
    };
