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
}
