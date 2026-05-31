// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/consumption/data/baseline_store.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_live_reading.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/providers/trip_baseline_recorder.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../helpers/silence_error_logger.dart';

/// End-to-end reachability guard for the baseline recorder (#2513,
/// epic #2512).
///
/// Bug #2513: on a Fuzzy-mode vehicle the recorder's `_recordFuzzy`
/// passed `grade: 0` and no `isStopAndGoContext`, so the `stopAndGo`
/// and `climbingOrLoaded` buckets were stuck at 0/30 forever despite
/// hundreds of thousands of total samples.
///
/// This suite drives the real [TripBaselineRecorder] over a synthetic
/// trip that contains a stop-and-go segment AND a climb (with GPS
/// altitude + high load), in BOTH calibration modes, and asserts that
/// each of the two previously-dead buckets accumulates at least one
/// sample. It is the integration-level half of the #2513 guard.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('baseline_reach_');
    Hive.init(tmpDir.path);
    await Hive.openBox<String>(HiveBoxes.obd2Baselines);
  });

  tearDown(() async {
    await Hive.box<String>(HiveBoxes.obd2Baselines).deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  /// Build the synthetic trip: a stop-and-go segment (speed oscillating
  /// 0↔30 km/h every few seconds — repeated start/stop crossings, low
  /// average) followed by a sustained climb (steady ~50 km/h, rising
  /// GPS altitude, high engine/abs load — engine working hard at a
  /// near-constant speed). Timestamps are simulated via [elapsed]; the
  /// recorder stamps wall-clock internally but the rolling window is
  /// driven by call order + the sample's own cadence, so a tight loop
  /// produces a representative window.
  List<TripLiveReading> syntheticTrip() {
    final readings = <TripLiveReading>[];
    var distanceKm = 0.0;
    var elapsedS = 0;

    // --- Stop-and-go: oscillate 0 ↔ 30 km/h, several crossings ---
    const stopGoPattern = [
      30.0, 30.0, 0.0, 0.0, 30.0, 30.0, 0.0, 0.0, //
      30.0, 30.0, 0.0, 0.0, 30.0, 0.0, 30.0, 0.0,
    ];
    for (final speed in stopGoPattern) {
      distanceKm += speed / 3600.0; // 1 s of travel at this speed
      elapsedS += 1;
      readings.add(TripLiveReading(
        speedKmh: speed,
        rpm: speed > 1 ? 1500 : 800,
        fuelRateLPerHour: speed > 1 ? 4.0 : 0.8,
        // Low throttle/load in the urban stop-and-go crawl.
        throttlePercent: speed > 1 ? 18 : 2,
        engineLoadPercent: speed > 1 ? 25 : 12,
        absLoadPercent: speed > 1 ? 22 : 10,
        distanceKmSoFar: distanceKm,
        elapsed: Duration(seconds: elapsedS),
      ));
    }

    // --- Climb: steady ~50 km/h, rising altitude, high load ---
    var altitude = 100.0;
    for (var i = 0; i < 20; i++) {
      const speed = 50.0;
      distanceKm += speed / 3600.0;
      elapsedS += 1;
      altitude += 3.0; // ~3 m rise per ~14 m travelled → steep grade
      readings.add(TripLiveReading(
        speedKmh: speed,
        rpm: 2600,
        fuelRateLPerHour: 9.0,
        // Pedal down hard, engine genuinely loaded — the climb / tow
        // signature the rule path keys off (load > 70, tight speed
        // range) and the fuzzy load ramp fills from.
        throttlePercent: 60,
        engineLoadPercent: 85,
        absLoadPercent: 88,
        altitudeM: altitude,
        distanceKmSoFar: distanceKm,
        elapsed: Duration(seconds: elapsedS),
      ));
    }

    return readings;
  }

  /// Drive the recorder over the synthetic trip in [mode], flush, then
  /// read the persisted per-situation sample counts back off disk.
  Future<Map<DrivingSituation, int>> runTripIn(
    VehicleCalibrationMode mode,
  ) async {
    const vehicleId = 'reach-car';
    final profile = const VehicleProfile(
      id: vehicleId,
      name: 'Reachability test car',
      type: VehicleType.combustion,
      tankCapacityL: 50,
    ).copyWith(calibrationMode: mode);

    final container = ProviderContainer(overrides: [
      activeVehicleProfileProvider.overrideWith(
        () => _StubActiveVehicle(profile),
      ),
    ]);
    addTearDown(container.dispose);

    // Virtual clock driven by each reading's `elapsed` so the rolling
    // 30-s window AND the rule-path classifier's 3-s debounce advance
    // deterministically — a tight test loop would otherwise stamp every
    // sample at the same wall-clock instant and the rule path's
    // debounce/span gates would never fire.
    final base = DateTime(2026, 1, 1);
    var clockAt = base;
    DateTime clock() => clockAt;

    // Build the recorder with a real provider [Ref] (mirrors the
    // obd2_recording_pipeline test) so it runs the genuine Riverpod
    // read path for the active vehicle + fuzzy classifier.
    final recorder = container.read(_recorderProvider(clock));
    await recorder.load();
    for (final reading in syntheticTrip()) {
      clockAt = base.add(reading.elapsed);
      recorder.recordAndClassify(reading);
    }
    await recorder.flushAndSync();

    // Read the flushed payload back via a fresh store so we assert on
    // what actually persisted, not the recorder's in-memory state.
    final store = BaselineStore(
      box: Hive.box<String>(HiveBoxes.obd2Baselines),
    );
    await store.loadVehicle(vehicleId);
    return {
      for (final s in DrivingSituation.values)
        s: store.sampleCount(vehicleId: vehicleId, situation: s),
    };
  }

  for (final mode in VehicleCalibrationMode.values) {
    test('both stop-and-go and climbing/loaded accumulate samples in '
        '${mode.name} mode (#2513)', () async {
      final counts = await runTripIn(mode);

      expect(counts[DrivingSituation.stopAndGo]!, greaterThan(0),
          reason: 'the stop-and-go segment must record at least one '
              'stopAndGo sample in ${mode.name} mode — it sat at 0/30 '
              'forever before #2513');
      expect(counts[DrivingSituation.climbingOrLoaded]!, greaterThan(0),
          reason: 'the climb segment must record at least one '
              'climbingOrLoaded sample in ${mode.name} mode — it sat at '
              '0/30 forever before #2513');
    });
  }
}

/// Exposes a [TripBaselineRecorder] built with the provider's own
/// [Ref] (so the recorder's `_ref.read(...)` calls resolve against the
/// test container's overrides) plus an injected virtual clock keyed by
/// the family argument.
final _recorderProvider =
    Provider.family<TripBaselineRecorder, DateTime Function()>(
  (ref, clock) => TripBaselineRecorder(ref, now: clock),
);

class _StubActiveVehicle extends ActiveVehicleProfile {
  _StubActiveVehicle(this._value);
  final VehicleProfile? _value;

  @override
  VehicleProfile? build() => _value;
}
