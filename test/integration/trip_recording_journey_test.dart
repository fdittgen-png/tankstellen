import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';

/// End-to-end integration coverage for the OBD2 trip-recording journey
/// (#1632 — epic #1612).
///
/// Drives the whole vertical slice with a fake ONLY at the BLE
/// transport boundary:
///
///   FakeObd2Transport → Obd2Service → TripRecording provider →
///   TripRecordingController + TripRecorder → TripHistoryRepository →
///   Hive
///
/// Everything between the fake transport and the persisted
/// [TripHistoryEntry] is the real production code. The journey lives
/// under `test/integration/` rather than `integration_test/` so it
/// stays headless — `integration_test/` would force an emulator —
/// and runs on every PR inside the existing sharded `test` CI job.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('trip_recording_journey_');
    Hive.init(tmpDir.path);
    // The trip-recording provider graph touches the settings + vehicle
    // boxes (active-vehicle lookup, baseline store); open the standard
    // test box set plus the trip-history box this journey reads back.
    await HiveStorage.initForTest();
    await Hive.openBox<String>(HiveBoxes.obd2TripHistory);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    tmpDir.deleteSync(recursive: true);
  });

  test(
    'connect → record live telemetry → pause/resume → stop persists a '
    'consumption entry the trip-history can read back',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // ── 1. OBD2 connect ────────────────────────────────────────────
      final service = Obd2Service(FakeObd2Transport(_elmOk()));
      final connected = await service.connect();
      expect(connected, isTrue, reason: 'fake ELM327 must connect');

      // ── 2. Start recording ─────────────────────────────────────────
      final notifier = container.read(tripRecordingProvider.notifier);
      expect(
        container.read(tripRecordingProvider).phase,
        TripRecordingPhase.idle,
      );
      await notifier.start(service);
      expect(
        container.read(tripRecordingProvider).phase,
        TripRecordingPhase.recording,
      );

      // ── 3. Feed a realistic drive: accelerate, cruise, slow down ───
      final ctl = notifier.debugController;
      expect(ctl, isNotNull,
          reason: 'provider must own a controller while recording');
      final start = DateTime(2026, 5, 17, 9);
      // 0→90 km/h over 10 s, cruise 90 for 10 s, 90→0 over 10 s.
      final speeds = <double>[
        for (var i = 0; i <= 10; i++) i * 9.0, // accelerate
        for (var i = 0; i < 10; i++) 90.0, // cruise
        for (var i = 10; i >= 0; i--) i * 9.0, // decelerate
      ];
      for (var i = 0; i < speeds.length; i++) {
        final at = start.add(Duration(seconds: i));
        final speed = speeds[i];
        final rpm = 900 + speed * 30; // crude gear-agnostic rpm model
        final fuelRate = 1.0 + speed * 0.08; // L/h rises with speed
        // Feed the recorder (aggregate metrics + fuel integration)…
        ctl!.debugInjectSample(
          speedKmh: speed,
          rpm: rpm,
          at: at,
          fuelRateLPerHour: fuelRate,
        );
        // …the virtual odometer (distance, since the test ELM exposes
        // no odometer PID — the common no-PID-01A6 car)…
        ctl.debugRecordSpeedSample(speedKmh: speed, at: at);
        // …and the per-tick buffer the trip-detail charts read back.
        ctl.debugCaptureSample(
          TripSample(
            timestamp: at,
            speedKmh: speed,
            rpm: rpm,
            fuelRateLPerHour: fuelRate,
          ),
        );
      }

      // ── 4. Pause / resume mid-journey — the trip keeps the service ─
      notifier.pause();
      expect(
        container.read(tripRecordingProvider).phase,
        TripRecordingPhase.paused,
      );
      notifier.resume();
      expect(
        container.read(tripRecordingProvider).phase,
        TripRecordingPhase.recording,
      );

      // ── 5. Stop ────────────────────────────────────────────────────
      await notifier.stop();
      expect(
        container.read(tripRecordingProvider).phase,
        TripRecordingPhase.finished,
      );

      // ── 6. The journey landed in trip history as a consumption entry
      final repo = container.read(tripHistoryRepositoryProvider);
      expect(repo, isNotNull, reason: 'trip-history box is open');
      final history = repo!.loadAll();
      expect(history, hasLength(1),
          reason: 'stop() must persist exactly one TripHistoryEntry');

      final entry = history.single;
      // Per-tick samples survived for the trip-detail charts.
      expect(entry.samples, hasLength(speeds.length));
      expect(entry.samples.first.speedKmh, 0);
      expect(entry.samples.first.timestamp, start);
      // Aggregated metrics are coherent: the car moved and burned fuel.
      expect(entry.summary.distanceKm, greaterThan(0),
          reason: 'speed telemetry must integrate into a virtual-odometer '
              'distance');
      expect(entry.summary.distanceSource, 'virtual',
          reason: 'no odometer PID was exposed — distance is integrated');
      expect(entry.summary.maxRpm, closeTo(900 + 90 * 30, 0.001));
      expect(entry.summary.fuelLitersConsumed, isNotNull);
      expect(entry.summary.fuelLitersConsumed!, greaterThan(0));
      expect(entry.summary.avgLPer100Km, isNotNull);

      // ── 7. reset() returns the recorder to idle for the next trip ──
      notifier.reset();
      expect(
        container.read(tripRecordingProvider).phase,
        TripRecordingPhase.idle,
      );
    },
  );

  test(
    'a trip stopped without any telemetry persists nothing — the '
    'empty-trip short-circuit holds end to end',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = Obd2Service(FakeObd2Transport(_elmOk()));
      await service.connect();

      final notifier = container.read(tripRecordingProvider.notifier);
      await notifier.start(service);
      // No samples injected — stop immediately.
      await notifier.stop();

      final repo = container.read(tripHistoryRepositoryProvider);
      expect(repo, isNotNull);
      expect(repo!.loadAll(), isEmpty,
          reason: 'an empty trip must not pollute the rolling history log');
    },
  );
}

/// ELM327 init handshake for [FakeObd2Transport]. Deliberately omits
/// the `01A6` odometer PID so the trip integrates a virtual-odometer
/// distance from speed telemetry — the behaviour for the many cars
/// that don't expose a live odometer reading.
Map<String, String> _elmOk() => const {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
    };
