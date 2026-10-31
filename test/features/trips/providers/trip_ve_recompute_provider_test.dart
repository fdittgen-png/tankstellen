// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';
import 'package:tankstellen/features/trips/providers/trip_history_provider.dart';
import 'package:tankstellen/features/trips/providers/trip_ve_recompute_provider.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../helpers/hive_temp_dir.dart';

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
    await closeHiveAndDeleteTemp(tmpDir);
  });

  TripHistoryEntry trip({
    required String id,
    double? veUsed,
    required double fuel,
    String vehicleId = 'v1',
    List<TripSample> samples = const [],
  }) =>
      TripHistoryEntry(
        id: id,
        vehicleId: vehicleId,
        samples: samples,
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
      // Let the fire-and-forget recompute complete (#4544: the full
      // decode runs on a worker isolate, so poll instead of a fixed wait).
      for (var i = 0; i < 50; i++) {
        final s = tripRepo.loadById('recalc')!.summary;
        if (s.volumetricEfficiencyUsed == 0.90) break;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      final trips = {for (final t in tripRepo.loadAll()) t.id: t};
      // Recalculable trip rescaled ×(0.90/0.80) = 1.125 and re-stamped.
      expect(trips['recalc']!.summary.fuelLitersConsumed, closeTo(4.5, 1e-6));
      expect(trips['recalc']!.summary.volumetricEfficiencyUsed, 0.90);
      // Not-recalculable trip untouched.
      expect(trips['legacy']!.summary.fuelLitersConsumed, 5.0);
      expect(trips['legacy']!.summary.volumetricEfficiencyUsed, isNull);
    },
  );

  // #4544 — the recompute used to run the synchronous full `loadAll()`
  // (every chunk of every trip) on the UI isolate. It must decide on
  // summaries, load only the trips that change, never re-save unchanged
  // ones, and keep the changed trip's telemetry.
  test(
    'recompute never decodes every trip, re-saves only changed trips and '
    'keeps their samples (#4544)',
    () async {
      final spy = _SpyTripRepo(
        box: Hive.box<String>(HiveBoxes.obd2TripHistory),
      );
      final container = ProviderContainer(overrides: [
        tripHistoryRepositoryProvider.overrideWithValue(spy),
      ]);
      addTearDown(container.dispose);

      await container.read(vehicleProfileListProvider.notifier).save(
            const VehicleProfile(
              id: 'v1',
              name: 'Test car',
              volumetricEfficiency: 0.80,
            ),
          );
      final start = DateTime(2026, 5, 1, 8);
      await spy.save(trip(
        id: 'recalc',
        veUsed: 0.80,
        fuel: 4.0,
        samples: [
          TripSample(timestamp: start, speedKmh: 0, rpm: 800),
          TripSample(
            timestamp: start.add(const Duration(seconds: 5)),
            speedKmh: 42,
            rpm: 1900,
          ),
        ],
      ));
      await spy.save(trip(id: 'legacy', veUsed: null, fuel: 5.0));
      await spy.save(
          trip(id: 'other', veUsed: 0.80, fuel: 3.0, vehicleId: 'v2'));
      spy.savedIds.clear();
      spy.loadAllCalls = 0;

      container.read(tripVeRecomputeListenerProvider);
      await container.read(vehicleProfileListProvider.notifier).save(
            const VehicleProfile(
              id: 'v1',
              name: 'Test car',
              volumetricEfficiency: 0.80,
              manualVolumetricEfficiencyOverride: 0.90,
            ),
          );
      // The full decode now runs on a worker isolate — give it time.
      for (var i = 0; i < 50 && spy.savedIds.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(spy.loadAllCalls, 0,
          reason: 'the synchronous full decode of every trip must not run');
      expect(spy.savedIds, ['recalc'],
          reason: 'only the trip whose figures change is re-saved');
      final recalc = spy.loadById('recalc')!;
      expect(recalc.summary.fuelLitersConsumed, closeTo(4.5, 1e-6));
      expect(recalc.samples, hasLength(2),
          reason: 'the rewrite must keep the trip\'s telemetry');
      expect(spy.loadById('other')!.summary.fuelLitersConsumed, 3.0);
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

/// Real repository that counts full decodes and records saved ids.
class _SpyTripRepo extends TripHistoryRepository {
  _SpyTripRepo({required super.box});

  int loadAllCalls = 0;
  final List<String> savedIds = [];

  @override
  List<TripHistoryEntry> loadAll({bool dedupe = true}) {
    loadAllCalls++;
    return super.loadAll(dedupe: dedupe);
  }

  @override
  Future<bool> save(TripHistoryEntry entry) {
    savedIds.add(entry.id);
    return super.save(entry);
  }
}
