// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/consumption/data/obd2/broken_map_belief.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Call-site integration tests for the broken-MAP belief hook
/// (#1423 phase 3). Verifies that when [FillUpList.add] runs the
/// trip-vs-pump reconciler against a closing plein-complet, the
/// resulting pumped/consumed pair (plus optional VeLearner-proposed
/// η_v) is folded into the broken-MAP belief via
/// [BrokenMapDetector.recordPleinCompletObservation]. Uses real
/// [TripHistoryRepository] (via in-memory Hive) so the hook traverses
/// the same path production does.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late TripHistoryRepository historyRepo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('plein_complet_hook_');
    Hive.init(tmpDir.path);
    final box = await Hive.openBox<String>(HiveBoxes.obd2TripHistory);
    historyRepo = TripHistoryRepository(box: box);
  });

  tearDown(() async {
    await Hive.box<String>(HiveBoxes.obd2TripHistory).deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> seedTrip({
    required String id,
    required String vehicleId,
    required DateTime startedAt,
    required double distanceKm,
    required double fuelLitersConsumed,
  }) {
    return historyRepo.save(TripHistoryEntry(
      id: id,
      vehicleId: vehicleId,
      summary: TripSummary(
        distanceKm: distanceKm,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        fuelLitersConsumed: fuelLitersConsumed,
        startedAt: startedAt,
        endedAt: startedAt.add(const Duration(minutes: 30)),
      ),
    ));
  }

  FillUp mkFillUp({
    required String id,
    required DateTime date,
    String vehicleId = 'veh-a',
    double liters = 40,
    double odometerKm = 10000,
    bool isFullTank = true,
  }) =>
      FillUp(
        id: id,
        date: date,
        liters: liters,
        totalCost: liters * 1.5,
        odometerKm: odometerKm,
        fuelType: FuelType.e10,
        vehicleId: vehicleId,
        isFullTank: isFullTank,
      );

  test(
      'high-discrepancy plein-complet (pumped 2.4× consumed) → broken-MAP '
      'posterior lifts after one observation', () async {
    final container = makeContainer();

    // Seed an OBD-integrated 5 L trip across 100 km. Then a plein
    // pumps 12 L (consumption ratio 12/5 = 2.4 → discrepancy clamps to
    // 1.0 in the score function).
    await seedTrip(
      id: 't1',
      vehicleId: 'veh-a',
      startedAt: DateTime(2026, 4, 1, 9),
      distanceKm: 100,
      fuelLitersConsumed: 5,
    );

    final notifier = container.read(fillUpListProvider.notifier);
    // Opening plein on April 1 — establishes the window start.
    await notifier.add(mkFillUp(
      id: 'opening',
      date: DateTime(2026, 4, 1, 8),
      liters: 30,
    ));
    // Closing plein on April 2 — pumps 12 L while integrator only saw
    // 5 L, so the reconciler will create a correction AND the broken-
    // MAP hook scores the discrepancy as conclusive.
    await notifier.add(mkFillUp(
      id: 'closing',
      date: DateTime(2026, 4, 2, 18),
      liters: 12,
      odometerKm: 10100,
    ));

    final beliefs = container.read(brokenMapBeliefByVehicleProvider);
    expect(beliefs['veh-a'], isNotNull);
    final belief = beliefs['veh-a']!;
    // Discrepancy alone (no VeLearner because no vehicle profile is
    // wired in this test container — VeLearner returns null on missing
    // profile) → score = discrepancyScore (1.0). Bayesian fold from
    // the default prior: α=0.5+8=8.5, β=4.5+0=4.5, mean=8.5/13≈0.654.
    expect(belief.alpha, closeTo(8.5, 1e-9));
    expect(belief.beta, closeTo(4.5, 1e-9));
    expect(belief.pointEstimate, closeTo(8.5 / 13.0, 1e-9));
    expect(belief.observationCount, 1);
    expect(belief.lastTrigger, BrokenMapReason.pleinCompletDiscrepancy);
  });

  test(
      'clean plein-complet (pumped ≈ consumed) leaves belief at 0 — single '
      'clean observation produces score 0', () async {
    final container = makeContainer();

    // Integrator and pump match → ratio 1.0 → discrepancyScore = 0.
    await seedTrip(
      id: 't1',
      vehicleId: 'veh-a',
      startedAt: DateTime(2026, 4, 1, 9),
      distanceKm: 100,
      fuelLitersConsumed: 6,
    );

    final notifier = container.read(fillUpListProvider.notifier);
    await notifier.add(mkFillUp(
      id: 'opening',
      date: DateTime(2026, 4, 1, 8),
      liters: 30,
    ));
    await notifier.add(mkFillUp(
      id: 'closing',
      date: DateTime(2026, 4, 2, 18),
      liters: 6,
      odometerKm: 10100,
    ));

    final belief = container
        .read(brokenMapBeliefByVehicleProvider.notifier)
        .beliefFor('veh-a');
    // Clean ratio → score 0 → α=0.5·1=0.5, β=0.5·9+1=5.5,
    // mean=0.5/6≈0.083 (silent band).
    expect(belief.alpha, closeTo(0.5, 1e-9));
    expect(belief.beta, closeTo(5.5, 1e-9));
    expect(belief.pointEstimate, lessThan(0.1));
    expect(belief.observationCount, 1);
    expect(belief.lastTrigger, BrokenMapReason.none);
  });

  test('partial fill-up does NOT trigger the broken-MAP hook', () async {
    final container = makeContainer();

    await seedTrip(
      id: 't1',
      vehicleId: 'veh-a',
      startedAt: DateTime(2026, 4, 1, 9),
      distanceKm: 100,
      fuelLitersConsumed: 5,
    );

    final notifier = container.read(fillUpListProvider.notifier);
    await notifier.add(mkFillUp(
      id: 'opening',
      date: DateTime(2026, 4, 1, 8),
      liters: 30,
    ));
    // Closing entry is a PARTIAL fill — reconciler short-circuits, so
    // the broken-MAP hook MUST NOT fire either.
    await notifier.add(mkFillUp(
      id: 'partial',
      date: DateTime(2026, 4, 2, 18),
      liters: 12,
      odometerKm: 10100,
      isFullTank: false,
    ));

    final beliefs = container.read(brokenMapBeliefByVehicleProvider);
    expect(beliefs['veh-a'], isNull,
        reason: 'partial fills must not seed a broken-MAP belief');
  });

  test(
      'fill-up without a vehicleId is ignored by the broken-MAP hook',
      () async {
    final container = makeContainer();
    final notifier = container.read(fillUpListProvider.notifier);

    await notifier.add(FillUp(
      id: 'no-vehicle',
      date: DateTime(2026, 4, 2, 18),
      liters: 40,
      totalCost: 60,
      odometerKm: 100,
      fuelType: FuelType.e10,
    ));

    expect(container.read(brokenMapBeliefByVehicleProvider), isEmpty);
  });

  test('skippedNoTrips outcome (no integrated fuel) skips the hook',
      () async {
    final container = makeContainer();
    final notifier = container.read(fillUpListProvider.notifier);

    // No trips seeded → reconciler returns skippedNoTrips. Hook MUST
    // NOT fire on this branch (consumed = 0 → ratio undefined).
    await notifier.add(mkFillUp(
      id: 'opening',
      date: DateTime(2026, 4, 1, 8),
      liters: 30,
    ));
    await notifier.add(mkFillUp(
      id: 'closing',
      date: DateTime(2026, 4, 2, 18),
      liters: 12,
      odometerKm: 10100,
    ));

    expect(container.read(brokenMapBeliefByVehicleProvider), isEmpty);
  });

  test(
      'two consecutive high-discrepancy observations compound the '
      'posterior past 0.8', () async {
    final container = makeContainer();

    // First window — opening + closing plein with high discrepancy.
    await seedTrip(
      id: 't1',
      vehicleId: 'veh-a',
      startedAt: DateTime(2026, 4, 1, 9),
      distanceKm: 100,
      fuelLitersConsumed: 5,
    );
    final notifier = container.read(fillUpListProvider.notifier);
    await notifier.add(mkFillUp(
      id: 'opening',
      date: DateTime(2026, 4, 1, 8),
      liters: 30,
    ));
    await notifier.add(mkFillUp(
      id: 'closing-1',
      date: DateTime(2026, 4, 2, 18),
      liters: 12,
      odometerKm: 10100,
    ));
    final after1 = container
        .read(brokenMapBeliefByVehicleProvider.notifier)
        .beliefFor('veh-a');
    expect(after1.pointEstimate, closeTo(8.5 / 13.0, 1e-9));

    // Second window — another high-discrepancy plein.
    await seedTrip(
      id: 't2',
      vehicleId: 'veh-a',
      startedAt: DateTime(2026, 4, 3, 9),
      distanceKm: 100,
      fuelLitersConsumed: 5,
    );
    await notifier.add(mkFillUp(
      id: 'closing-2',
      date: DateTime(2026, 4, 4, 18),
      liters: 12,
      odometerKm: 10200,
    ));
    final after2 = container
        .read(brokenMapBeliefByVehicleProvider.notifier)
        .beliefFor('veh-a');
    // Bayesian fold of a second strong observation:
    // α=0.5·8.5 + 8 = 12.25; β=0.5·4.5 + 0 = 2.25; mean ≈ 0.845.
    expect(after2.alpha, closeTo(12.25, 1e-9));
    expect(after2.beta, closeTo(2.25, 1e-9));
    expect(after2.pointEstimate, greaterThan(0.8));
    expect(after2.observationCount, 2);
  });
}

class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic getSetting(String key) => _data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    _data[key] = value;
  }

  @override
  bool get isSetupComplete => false;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}
