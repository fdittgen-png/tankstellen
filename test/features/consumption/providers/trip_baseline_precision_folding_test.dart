// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/consumption/data/baseline_store.dart';
import 'package:tankstellen/features/obd2/data/trip_live_reading.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/providers/trip_baseline_recorder.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../helpers/silence_error_logger.dart';

/// #2515 PR2 — precision-folding integration coverage that drives the
/// real [TripBaselineRecorder]'s fuzzy `_recordFuzzy` path:
///
///  * the per-sample fuel-mass correction (λ / STFT-LTFT / MAP) is
///    applied before the Welford accumulator learns the value, so an
///    enriched sample (λ < 1) drags the learned mean LOWER than feeding
///    the raw rate — and a sample carrying none of the precision PIDs is
///    recorded unchanged (no regression);
///  * the belt-and-braces warm-up gate records a cold sample ONLY into
///    coldStart, so the urban / steady-state means are untouched.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('precision_fold_');
    Hive.init(tmpDir.path);
    await Hive.openBox<String>(HiveBoxes.obd2Baselines);
  });

  tearDown(() async {
    await Hive.box<String>(HiveBoxes.obd2Baselines).deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  /// Drive [readings] through the recorder for a fresh [vehicleId] in
  /// fuzzy mode, flush, and return the persisted store so the test can
  /// read learned means / per-situation counts back off disk.
  Future<BaselineStore> runTrip(
    String vehicleId,
    List<TripLiveReading> readings,
  ) async {
    final profile = VehicleProfile(
      id: vehicleId,
      name: 'Precision test car',
      type: VehicleType.combustion,
      tankCapacityL: 50,
    ).copyWith(calibrationMode: VehicleCalibrationMode.fuzzy);

    final container = ProviderContainer(overrides: [
      activeVehicleProfileProvider.overrideWith(
        () => _StubActiveVehicle(profile),
      ),
    ]);
    addTearDown(container.dispose);

    final base = DateTime(2026, 1, 1);
    var clockAt = base;
    DateTime clock() => clockAt;

    final recorder = container.read(_recorderProvider(clock));
    await recorder.load();
    for (final reading in readings) {
      clockAt = base.add(reading.elapsed);
      recorder.recordAndClassify(reading);
    }
    await recorder.flushAndSync();

    final store = BaselineStore(
      box: Hive.box<String>(HiveBoxes.obd2Baselines),
    );
    await store.loadVehicle(vehicleId);
    return store;
  }

  /// A steady warm urban cruise sample at [speed] km/h (warm engine so
  /// it never trips the cold-start bucket), optionally carrying the λ /
  /// MAP precision PIDs so the fuel-mass correction has something to
  /// fold in. `elapsed` is set by the caller's loop index.
  TripLiveReading urbanSample(
    int i, {
    double speed = 35,
    double? lambda,
    double? mapKpa,
  }) =>
      TripLiveReading(
        speedKmh: speed,
        rpm: 1800,
        fuelRateLPerHour: 7.0,
        throttlePercent: 30,
        engineLoadPercent: 40,
        absLoadPercent: 38,
        coolantTempC: 90, // fully warm — steady-state, not cold-start
        lambda: lambda,
        mapKpa: mapKpa,
        distanceKmSoFar: speed / 3600.0 * (i + 1),
        elapsed: Duration(seconds: i + 1),
      );

  group('fuel-mass correction in _recordFuzzy', () {
    test('an enriched (λ=0.9) trip learns a LOWER urban mean than the '
        'same trip without the λ PID', () async {
      const fuelFamily = ConsumptionFuelFamily.gasoline;

      // Raw run: identical samples, NO precision PIDs → identity factor.
      final rawStore = await runTrip('raw-car', [
        for (var i = 0; i < 40; i++) urbanSample(i),
      ]);
      // Corrected run: identical samples but λ=0.9 (enrichment) → the
      // recorded value is divided down by 1/0.9, lowering the mean.
      final corrStore = await runTrip('corr-car', [
        for (var i = 0; i < 40; i++) urbanSample(i, lambda: 0.9),
      ]);

      final raw = rawStore.lookup(
        vehicleId: 'raw-car',
        situation: DrivingSituation.urbanCruise,
        fuelFamily: fuelFamily,
      );
      final corrected = corrStore.lookup(
        vehicleId: 'corr-car',
        situation: DrivingSituation.urbanCruise,
        fuelFamily: fuelFamily,
      );

      // Both runs accumulate the same number of urban samples, so the
      // blend weight is identical → a lower lookup directly reflects a
      // lower learned mean from the enrichment correction.
      expect(corrected.value, lessThan(raw.value),
          reason: 'λ=0.9 enrichment divides the recorded value by ~1/0.9, '
              'so the corrected urban mean must come out lower than the '
              'raw-rate mean');
    });

    test('a no-PID trip is recorded unchanged (no regression)', () async {
      // The cold-start baseline an empty bucket falls back to.
      final cold = coldStartBaseline(
          ConsumptionFuelFamily.gasoline, DrivingSituation.urbanCruise);

      final store = await runTrip('nopid-car', [
        for (var i = 0; i < 40; i++) urbanSample(i),
      ]);
      final learned = store.lookup(
        vehicleId: 'nopid-car',
        situation: DrivingSituation.urbanCruise,
        fuelFamily: ConsumptionFuelFamily.gasoline,
      );

      // The samples are 7 L/h at 35 km/h → 20 L/100 km, well above the
      // cold-start default. With the identity factor the learned mean
      // pulls the blended baseline ABOVE the cold-start default; any
      // accidental correction on a no-PID car would shift it.
      expect(learned.value, greaterThan(cold.value),
          reason: 'a car with no λ/trim/MAP PIDs must record the raw rate '
              'unchanged, so the learned urban mean stays above the '
              'cold-start default');
    });
  });

  group('warm-up exclusion in _recordFuzzy', () {
    test('a cold (coolant 45 °C) urban segment records ONLY coldStart, '
        'never urban / steady-state', () async {
      final store = await runTrip('cold-car', [
        // 30 cold samples at urban speed but coolant 45 °C the whole time.
        for (var i = 0; i < 30; i++)
          urbanSample(i).copyWith(coolantTempC: 45),
      ]);

      final coldCount = store.sampleCount(
        vehicleId: 'cold-car',
        situation: DrivingSituation.coldStartWarmup,
      );
      final urbanCount = store.sampleCount(
        vehicleId: 'cold-car',
        situation: DrivingSituation.urbanCruise,
      );
      final highwayCount = store.sampleCount(
        vehicleId: 'cold-car',
        situation: DrivingSituation.highwayCruise,
      );
      final stopGoCount = store.sampleCount(
        vehicleId: 'cold-car',
        situation: DrivingSituation.stopAndGo,
      );

      expect(coldCount, greaterThan(0),
          reason: 'a cold (coolant 45 °C) segment must fill coldStart');
      expect(urbanCount, 0,
          reason: 'the warm-up gate must keep cold samples out of the '
              'urban-cruise mean');
      expect(highwayCount, 0);
      expect(stopGoCount, 0);
    });

    test('a warm (coolant 90 °C) urban segment does fill urban (the gate '
        'only excludes cold samples)', () async {
      final store = await runTrip('warm-car', [
        for (var i = 0; i < 30; i++) urbanSample(i),
      ]);

      expect(
        store.sampleCount(
          vehicleId: 'warm-car',
          situation: DrivingSituation.urbanCruise,
        ),
        greaterThan(0),
        reason: 'warm steady-state samples must still fill urban — the '
            'warm-up gate is a no-op once the engine is at temperature',
      );
    });
  });
}

/// Recorder built with the provider's own [Ref] so its `_ref.read(...)`
/// calls resolve against the test container's overrides, plus an
/// injected virtual clock keyed by the family argument (mirrors the
/// #2513 reachability harness).
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
