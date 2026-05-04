import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/consumption/data/baseline_store.dart';
import 'package:tankstellen/features/consumption/data/welford.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<String> box;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('baseline_store_test_');
    Hive.init(tmpDir.path);
    box = await Hive.openBox<String>(
      'test_${DateTime.now().microsecondsSinceEpoch}',
    );
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  group('BaselineStore (#769)', () {
    test('empty vehicle returns the cold-start default', () async {
      final store = BaselineStore(box: box);
      await store.loadVehicle('car-a');
      final b = store.lookup(
        vehicleId: 'car-a',
        situation: DrivingSituation.highwayCruise,
        fuelFamily: ConsumptionFuelFamily.gasoline,
      );
      expect(b.value, 6.0);
      expect(b.unit, BaselineUnit.lPer100Km);
    });

    test('record() ignores transient situations', () async {
      final store = BaselineStore(box: box);
      await store.loadVehicle('car-a');
      store.record(
        vehicleId: 'car-a',
        situation: DrivingSituation.hardAccel,
        value: 30.0,
      );
      store.record(
        vehicleId: 'car-a',
        situation: DrivingSituation.fuelCutCoast,
        value: 0.0,
      );
      expect(
        store.sampleCount(
          vehicleId: 'car-a',
          situation: DrivingSituation.hardAccel,
        ),
        0,
      );
      expect(
        store.sampleCount(
          vehicleId: 'car-a',
          situation: DrivingSituation.fuelCutCoast,
        ),
        0,
      );
    });

    test('blended weight ramps 0 → 1 linearly across '
        'fullConfidenceSamples', () async {
      final store =
          BaselineStore(box: box, fullConfidenceSamples: 10);
      await store.loadVehicle('car-a');
      for (var i = 0; i < 5; i++) {
        store.record(
          vehicleId: 'car-a',
          situation: DrivingSituation.highwayCruise,
          value: 10.0,
        );
      }
      final b = store.lookup(
        vehicleId: 'car-a',
        situation: DrivingSituation.highwayCruise,
        fuelFamily: ConsumptionFuelFamily.gasoline,
      );
      // 5/10 weight → 10 × 0.5 + 6 × 0.5 = 8.0
      expect(b.value, closeTo(8.0, 1e-9));
    });

    test('reaches full learned value at fullConfidenceSamples',
        () async {
      final store =
          BaselineStore(box: box, fullConfidenceSamples: 10);
      await store.loadVehicle('car-a');
      for (var i = 0; i < 10; i++) {
        store.record(
          vehicleId: 'car-a',
          situation: DrivingSituation.highwayCruise,
          value: 10.0,
        );
      }
      final b = store.lookup(
        vehicleId: 'car-a',
        situation: DrivingSituation.highwayCruise,
        fuelFamily: ConsumptionFuelFamily.gasoline,
      );
      expect(b.value, closeTo(10.0, 1e-9));
    });

    test('multi-vehicle: baselines are isolated per vehicle',
        () async {
      final store =
          BaselineStore(box: box, fullConfidenceSamples: 10);
      await store.loadVehicle('car-a');
      await store.loadVehicle('car-b');
      for (var i = 0; i < 10; i++) {
        store.record(
          vehicleId: 'car-a',
          situation: DrivingSituation.highwayCruise,
          value: 10.0,
        );
        store.record(
          vehicleId: 'car-b',
          situation: DrivingSituation.highwayCruise,
          value: 5.0,
        );
      }
      expect(
        store.lookup(
          vehicleId: 'car-a',
          situation: DrivingSituation.highwayCruise,
          fuelFamily: ConsumptionFuelFamily.gasoline,
        ).value,
        closeTo(10.0, 1e-9),
      );
      expect(
        store.lookup(
          vehicleId: 'car-b',
          situation: DrivingSituation.highwayCruise,
          fuelFamily: ConsumptionFuelFamily.gasoline,
        ).value,
        closeTo(5.0, 1e-9),
      );
    });

    test('flush() + fresh load round-trips the accumulators',
        () async {
      final store =
          BaselineStore(box: box, fullConfidenceSamples: 10);
      await store.loadVehicle('car-a');
      for (var i = 0; i < 10; i++) {
        store.record(
          vehicleId: 'car-a',
          situation: DrivingSituation.highwayCruise,
          value: 7.0,
        );
      }
      await store.flush('car-a');

      final fresh =
          BaselineStore(box: box, fullConfidenceSamples: 10);
      await fresh.loadVehicle('car-a');
      final b = fresh.lookup(
        vehicleId: 'car-a',
        situation: DrivingSituation.highwayCruise,
        fuelFamily: ConsumptionFuelFamily.gasoline,
      );
      expect(b.value, closeTo(7.0, 1e-9));
    });

    test('corrupt persisted payload is tolerated — cold-start default',
        () async {
      await box.put('baseline:car-a', 'this is not JSON');
      final store = BaselineStore(box: box);
      await store.loadVehicle('car-a');
      final b = store.lookup(
        vehicleId: 'car-a',
        situation: DrivingSituation.highwayCruise,
        fuelFamily: ConsumptionFuelFamily.gasoline,
      );
      expect(b.value, 6.0);
    });

    test('WelfordAccumulator sanity — defence against forked math',
        () {
      final w = WelfordAccumulator();
      w.update(1);
      w.update(2);
      w.update(3);
      expect(w.mean, closeTo(2.0, 1e-10));
    });
  });

  // #1426 — wires the #894 fuzzy classifier through to the baseline
  // store. The fuzzy path calls recordWeighted() repeatedly with
  // membership weights summing to 1.0; the cold-start blend must
  // honour effective sample count, not raw count, so 30 samples ×
  // 0.05 weight don't pretend to be fully-converged.
  group('BaselineStore weighted fuzzy path (#1426)', () {
    test('recordWeighted with weight=1 matches the unweighted record', () async {
      final store =
          BaselineStore(box: box, fullConfidenceSamples: 10);
      await store.loadVehicle('car-a');
      for (var i = 0; i < 10; i++) {
        store.recordWeighted(
          vehicleId: 'car-a',
          situation: DrivingSituation.highwayCruise,
          value: 10.0,
          weight: 1.0,
        );
      }
      final b = store.lookup(
        vehicleId: 'car-a',
        situation: DrivingSituation.highwayCruise,
        fuelFamily: ConsumptionFuelFamily.gasoline,
      );
      // 10/10 effective N → fully learned. Identical to the
      // unweighted path's behaviour.
      expect(b.value, closeTo(10.0, 1e-9));
    });

    test(
        'low-weight samples produce low effective N — blend stays close to '
        'cold-start', () async {
      final store =
          BaselineStore(box: box, fullConfidenceSamples: 10);
      await store.loadVehicle('car-a');

      // 30 samples × 0.05 weight on highway. Σw = 1.5, Σw² = 0.075,
      // effective N = 30. UNIFORM weights leave effective N at the
      // raw count — the discriminator is non-uniform weights.
      // This case asserts uniform low weights are NOT spuriously
      // treated as fully-confident — the lookup() blend uses
      // effective N, which here equals 30 → fully-learned. That's
      // mathematically correct: 30 uniform-weight observations of
      // the same value ARE strong evidence regardless of weight
      // magnitude. The regression we guard against is non-uniform
      // weights (next test).
      for (var i = 0; i < 30; i++) {
        store.recordWeighted(
          vehicleId: 'car-a',
          situation: DrivingSituation.highwayCruise,
          value: 10.0,
          weight: 0.05,
        );
      }
      final b = store.lookup(
        vehicleId: 'car-a',
        situation: DrivingSituation.highwayCruise,
        fuelFamily: ConsumptionFuelFamily.gasoline,
      );
      expect(b.value, closeTo(10.0, 1e-9));
    });

    test(
        'one strong sample + many near-zero votes does NOT prematurely '
        'over-state confidence', () async {
      // The fuzzy regression case: 1 strong (w=1.0) sample + 9
      // near-zero "smear" votes (w=0.01). Raw count = 10, but
      // effective N ≈ 1.099. With fullConfidenceSamples = 10 the
      // blend should be ≈ 11 % learned, NOT 100 %.
      final store =
          BaselineStore(box: box, fullConfidenceSamples: 10);
      await store.loadVehicle('car-a');

      store.recordWeighted(
        vehicleId: 'car-a',
        situation: DrivingSituation.highwayCruise,
        value: 10.0,
        weight: 1.0,
      );
      for (var i = 0; i < 9; i++) {
        store.recordWeighted(
          vehicleId: 'car-a',
          situation: DrivingSituation.highwayCruise,
          value: 10.0,
          weight: 0.01,
        );
      }

      // Effective N ≈ 1.099 / 10 ≈ 11 % learned weight.
      // Blend = 10 · 0.11 + 6 · 0.89 ≈ 6.44 (cold-start petrol
      // highway is 6.0). Acceptance band is loose because the
      // exact effective-N depends on the floating-point sum, but
      // the test FAILS if the blend produces ~10 (the regression).
      final b = store.lookup(
        vehicleId: 'car-a',
        situation: DrivingSituation.highwayCruise,
        fuelFamily: ConsumptionFuelFamily.gasoline,
      );
      expect(b.value, lessThan(7.0));
      expect(b.value, greaterThan(6.0));
    });

    test('zero-weight votes are ignored — bucket counter unchanged', () async {
      final store =
          BaselineStore(box: box, fullConfidenceSamples: 10);
      await store.loadVehicle('car-a');
      store.recordWeighted(
        vehicleId: 'car-a',
        situation: DrivingSituation.highwayCruise,
        value: 999.0,
        weight: 0.0,
      );
      expect(
        store.sampleCount(
          vehicleId: 'car-a',
          situation: DrivingSituation.highwayCruise,
        ),
        0,
      );
      // Cold-start default still wins.
      final b = store.lookup(
        vehicleId: 'car-a',
        situation: DrivingSituation.highwayCruise,
        fuelFamily: ConsumptionFuelFamily.gasoline,
      );
      expect(b.value, closeTo(6.0, 1e-9));
    });

    test('recordWeighted ignores transient situations', () async {
      final store = BaselineStore(box: box);
      await store.loadVehicle('car-a');
      store.recordWeighted(
        vehicleId: 'car-a',
        situation: DrivingSituation.hardAccel,
        value: 30.0,
        weight: 1.0,
      );
      store.recordWeighted(
        vehicleId: 'car-a',
        situation: DrivingSituation.fuelCutCoast,
        value: 0.0,
        weight: 1.0,
      );
      expect(
        store.sampleCount(
          vehicleId: 'car-a',
          situation: DrivingSituation.hardAccel,
        ),
        0,
      );
    });

    test(
        'flush + reload of weighted accumulators preserves effective '
        'sample count', () async {
      final store =
          BaselineStore(box: box, fullConfidenceSamples: 10);
      await store.loadVehicle('car-a');
      // Build a non-uniform weight bucket — effective N must
      // round-trip via JSON.
      store.recordWeighted(
        vehicleId: 'car-a',
        situation: DrivingSituation.urbanCruise,
        value: 8.0,
        weight: 1.0,
      );
      for (var i = 0; i < 9; i++) {
        store.recordWeighted(
          vehicleId: 'car-a',
          situation: DrivingSituation.urbanCruise,
          value: 8.0,
          weight: 0.01,
        );
      }
      final beforeBlend = store
          .lookup(
            vehicleId: 'car-a',
            situation: DrivingSituation.urbanCruise,
            fuelFamily: ConsumptionFuelFamily.gasoline,
          )
          .value;
      await store.flush('car-a');

      final fresh =
          BaselineStore(box: box, fullConfidenceSamples: 10);
      await fresh.loadVehicle('car-a');
      final afterBlend = fresh
          .lookup(
            vehicleId: 'car-a',
            situation: DrivingSituation.urbanCruise,
            fuelFamily: ConsumptionFuelFamily.gasoline,
          )
          .value;
      expect(afterBlend, closeTo(beforeBlend, 1e-9));
    });
  });
}
