import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/consumption/data/baseline_store.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/providers/vehicle_baseline_summary_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('baseline_summary_');
    Hive.init(tmpDir.path);
    await Hive.openBox<String>(HiveBoxes.obd2Baselines);
  });

  tearDown(() async {
    await Hive.box<String>(HiveBoxes.obd2Baselines).deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  group('vehicleBaselineSummaryProvider (#779)', () {
    test('empty vehicle returns an empty map — no crash when the '
        'user visits the edit screen before any trip', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final summary =
          container.read(vehicleBaselineSummaryProvider('car-a'));
      expect(summary, isEmpty);
    });

    test('persisted baselines surface as sample counts per situation',
        () async {
      final store = BaselineStore(
        box: Hive.box<String>(HiveBoxes.obd2Baselines),
      );
      await store.loadVehicle('car-a');
      // Feed 12 highway samples + 3 urban samples.
      for (var i = 0; i < 12; i++) {
        store.record(
          vehicleId: 'car-a',
          situation: DrivingSituation.highwayCruise,
          value: 6.5,
        );
      }
      for (var i = 0; i < 3; i++) {
        store.record(
          vehicleId: 'car-a',
          situation: DrivingSituation.urbanCruise,
          value: 8.0,
        );
      }
      await store.flush('car-a');

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final summary =
          container.read(vehicleBaselineSummaryProvider('car-a'));
      expect(summary[DrivingSituation.highwayCruise], 12);
      expect(summary[DrivingSituation.urbanCruise], 3);
      // Never-sampled situations don't appear in the map.
      expect(summary.containsKey(DrivingSituation.idle), isFalse);
    });

    test('transients are filtered out — hardAccel + fuelCutCoast '
        'never accumulate so the UI should not show "learning" bars '
        'for them', () async {
      // Hand-craft a payload that (incorrectly) carries hardAccel
      // samples — the provider must still skip them.
      final box = Hive.box<String>(HiveBoxes.obd2Baselines);
      await box.put(
        'baseline:car-a',
        json.encode({
          'version': 1,
          'perSituation': {
            'hardAccel': {'n': 99, 'mean': 0.0, 'm2': 0.0},
            'urbanCruise': {'n': 5, 'mean': 7.0, 'm2': 2.0},
          },
        }),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final summary =
          container.read(vehicleBaselineSummaryProvider('car-a'));
      expect(summary.containsKey(DrivingSituation.hardAccel), isFalse);
      expect(summary[DrivingSituation.urbanCruise], 5);
    });

    test('corrupt payload is tolerated — empty map, no throw', () async {
      await Hive.box<String>(HiveBoxes.obd2Baselines)
          .put('baseline:car-a', 'not JSON');
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(vehicleBaselineSummaryProvider('car-a')),
        isEmpty,
      );
    });

    test('reset wipes the vehicle and invalidates the summary',
        () async {
      final store = BaselineStore(
        box: Hive.box<String>(HiveBoxes.obd2Baselines),
      );
      await store.loadVehicle('car-a');
      for (var i = 0; i < 5; i++) {
        store.record(
          vehicleId: 'car-a',
          situation: DrivingSituation.urbanCruise,
          value: 7,
        );
      }
      await store.flush('car-a');

      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container
            .read(vehicleBaselineSummaryProvider('car-a'))[
                DrivingSituation.urbanCruise],
        5,
      );

      await container.read(resetVehicleBaselinesProvider('car-a').future);
      expect(
        container.read(vehicleBaselineSummaryProvider('car-a')),
        isEmpty,
      );
    });
  });
}
