import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_ve_recompute_provider.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

/// Coverage for the #1858 retroactive η_v recompute trigger — the
/// keep-alive listener that rescales a vehicle's trips when its η_v is
/// edited.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('ve_recompute_');
    Hive.init(tmpDir.path);
    await HiveStorage.initForTest();
    await Hive.openBox<String>(HiveBoxes.obd2TripHistory);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    tmpDir.deleteSync(recursive: true);
  });

  TripHistoryEntry trip({
    required String id,
    double? veUsed,
    required double fuel,
  }) =>
      TripHistoryEntry(
        id: id,
        vehicleId: 'v1',
        summary: TripSummary(
          distanceKm: 100,
          maxRpm: 3000,
          highRpmSeconds: 0,
          idleSeconds: 0,
          harshBrakes: 0,
          harshAccelerations: 0,
          fuelLitersConsumed: fuel,
          avgLPer100Km: fuel,
          volumetricEfficiencyUsed: veUsed,
        ),
      );

  test(
    'a manual η_v override change rescales the vehicle\'s recalculable '
    'trips and leaves not-recalculable ones untouched',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Seed the vehicle at η_v 0.80.
      await container.read(vehicleProfileListProvider.notifier).save(
            const VehicleProfile(
              id: 'v1',
              name: 'Test car',
              volumetricEfficiency: 0.80,
            ),
          );

      // Seed two trips: one η_v-recalculable, one not.
      final tripRepo = container.read(tripHistoryRepositoryProvider)!;
      await tripRepo.save(trip(id: 'recalc', veUsed: 0.80, fuel: 4.0));
      await tripRepo.save(trip(id: 'legacy', veUsed: null, fuel: 5.0));

      // Arm the listener AFTER seeding, so the seed itself is not a
      // change it reacts to — only the η_v edit below is.
      container.read(tripVeRecomputeListenerProvider);

      // The user corrects η_v to 0.90 via a manual override.
      await container.read(vehicleProfileListProvider.notifier).save(
            const VehicleProfile(
              id: 'v1',
              name: 'Test car',
              volumetricEfficiency: 0.80,
              manualVolumetricEfficiencyOverride: 0.90,
            ),
          );
      // Let the fire-and-forget recompute complete.
      await Future<void>.delayed(const Duration(milliseconds: 80));

      final trips = {for (final t in tripRepo.loadAll()) t.id: t};
      // Recalculable trip rescaled ×(0.90/0.80) = 1.125 and re-stamped.
      expect(trips['recalc']!.summary.fuelLitersConsumed, closeTo(4.5, 1e-6));
      expect(trips['recalc']!.summary.volumetricEfficiencyUsed, 0.90);
      // Not-recalculable trip untouched.
      expect(trips['legacy']!.summary.fuelLitersConsumed, 5.0);
      expect(trips['legacy']!.summary.volumetricEfficiencyUsed, isNull);
    },
  );

  test(
    'a vehicle save that does not change η_v leaves trips untouched',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(vehicleProfileListProvider.notifier).save(
            const VehicleProfile(
              id: 'v1',
              name: 'Test car',
              volumetricEfficiency: 0.80,
            ),
          );
      final tripRepo = container.read(tripHistoryRepositoryProvider)!;
      await tripRepo.save(trip(id: 'recalc', veUsed: 0.80, fuel: 4.0));

      container.read(tripVeRecomputeListenerProvider);

      // A rename — η_v is unchanged.
      await container.read(vehicleProfileListProvider.notifier).save(
            const VehicleProfile(
              id: 'v1',
              name: 'Renamed car',
              volumetricEfficiency: 0.80,
            ),
          );
      await Future<void>.delayed(const Duration(milliseconds: 80));

      final recalc = tripRepo.loadAll().single;
      expect(recalc.summary.fuelLitersConsumed, 4.0,
          reason: 'no η_v change → no recompute');
      expect(recalc.summary.volumetricEfficiencyUsed, 0.80);
    },
  );
}
