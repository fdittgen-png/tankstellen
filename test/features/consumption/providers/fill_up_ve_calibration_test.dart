import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/data/ve_learner.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';

/// Integration-level tests for the fill-up save → η_v reconciliation
/// path (#815). These tests drive the real provider graph (no Riverpod
/// doubles) so the FillUpList.add hook is exercised end-to-end.
void main() {
  late ProviderContainer container;
  late _FakeTripHistory history;
  late VehicleProfileRepository profileRepo;

  setUp(() {
    history = _FakeTripHistory();
    final storage = _FakeSettingsStorage();
    profileRepo = VehicleProfileRepository(storage);
    container = ProviderContainer(
      overrides: [
        settingsStorageProvider.overrideWithValue(storage),
        vehicleProfileRepositoryProvider.overrideWithValue(profileRepo),
        // Inject a deterministic learner whose sample counter doesn't
        // depend on wall-clock trip duration — unit-test trips use
        // fabricated timestamps — and whose trip loader reads from an
        // in-memory list instead of Hive.
        veLearnerProvider.overrideWith(
          (ref) => VeLearner(
            profileRepository:
                ref.watch(vehicleProfileRepositoryProvider),
            tripHistoryLoader: history.entries.toList,
            sampleCounter: (_) => 600,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  test(
    'adding a second fill-up for a vehicle with trips since the '
    'previous fill-up produces a VeLearnResult that surfaces via '
    'lastVeLearnResultProvider, updates the vehicle η_v, and bumps '
    'the sample count',
    () async {
      await profileRepo.save(const VehicleProfile(
        id: 'veh-a',
        name: 'Peugeot 107',
      ));

      final previousFillDate = DateTime(2026, 4, 1, 8);
      final currentFillDate = DateTime(2026, 4, 15, 18);

      history.entries.add(TripHistoryEntry(
        id: 't1',
        vehicleId: 'veh-a',
        summary: TripSummary(
          distanceKm: 200,
          maxRpm: 0,
          highRpmSeconds: 0,
          idleSeconds: 0,
          harshBrakes: 0,
          harshAccelerations: 0,
          fuelLitersConsumed: 55,
          startedAt: previousFillDate.add(const Duration(hours: 2)),
          endedAt: previousFillDate.add(const Duration(hours: 5)),
        ),
      ));

      final notifier = container.read(fillUpListProvider.notifier);
      // Seed the previous fill-up so the learner anchors against it.
      await notifier.add(FillUp(
        id: 'prev',
        date: previousFillDate,
        liters: 40,
        totalCost: 60,
        odometerKm: 10000,
        fuelType: FuelType.e10,
        vehicleId: 'veh-a',
      ));
      // No snackbar fired — the first fill-up has no prior anchor.
      expect(container.read(lastVeLearnResultProvider), isNull);

      // Current fill-up — 50 L pumped vs 55 L integrated.
      await notifier.add(FillUp(
        id: 'cur',
        date: currentFillDate,
        liters: 50,
        totalCost: 75,
        odometerKm: 10200,
        fuelType: FuelType.e10,
        vehicleId: 'veh-a',
      ));

      final result = container.read(lastVeLearnResultProvider);
      expect(result, isNotNull);
      expect(result!.vehicleId, 'veh-a');
      expect(result.newVe, lessThan(0.85));
      expect(result.newVe, greaterThan(0.50));
      expect(result.sampleCount, 1);

      final updatedProfile = profileRepo.getById('veh-a')!;
      expect(updatedProfile.volumetricEfficiencySamples, 1);
      expect(updatedProfile.volumetricEfficiency, lessThan(0.85));
    },
  );

  test('snackbar text contains vehicle name and improvement percent',
      () async {
    await profileRepo.save(const VehicleProfile(
      id: 'veh-a',
      name: 'Peugeot 107',
    ));

    final previousFillDate = DateTime(2026, 4, 1, 8);
    final currentFillDate = DateTime(2026, 4, 15, 18);

    history.entries.add(TripHistoryEntry(
      id: 't1',
      vehicleId: 'veh-a',
      summary: TripSummary(
        distanceKm: 200,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        fuelLitersConsumed: 55,
        startedAt: previousFillDate.add(const Duration(hours: 2)),
        endedAt: previousFillDate.add(const Duration(hours: 5)),
      ),
    ));

    final notifier = container.read(fillUpListProvider.notifier);
    await notifier.add(FillUp(
      id: 'prev',
      date: previousFillDate,
      liters: 40,
      totalCost: 60,
      odometerKm: 10000,
      fuelType: FuelType.e10,
      vehicleId: 'veh-a',
    ));
    await notifier.add(FillUp(
      id: 'cur',
      date: currentFillDate,
      liters: 50,
      totalCost: 75,
      odometerKm: 10200,
      fuelType: FuelType.e10,
      vehicleId: 'veh-a',
    ));

    final result = container.read(lastVeLearnResultProvider);
    expect(result, isNotNull);

    // Template-equivalent snackbar text (the real consumption screen
    // uses AppLocalizations — we format the fallback string here to
    // prove the data carried by the result is enough to render it).
    final vehicle = profileRepo.getById(result!.vehicleId)!;
    final snackbar =
        'Consumption calibration updated for ${vehicle.name} — '
        'accuracy improved by '
        '${result.accuracyImprovementPct.round()}%';
    expect(snackbar, contains('Peugeot 107'));
    expect(
      RegExp(r'improved by \d+%').hasMatch(snackbar),
      isTrue,
      reason: 'Snackbar must carry a numeric improvement percent',
    );
  });
}

class _FakeTripHistory {
  final List<TripHistoryEntry> entries = [];
}

class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic getSetting(String key) => _data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
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

