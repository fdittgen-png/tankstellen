import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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

/// Hive-backed persistence tests for the [BrokenMapBeliefByVehicle]
/// notifier (#1423 phase 4). Verifies that:
///   1. a high-discrepancy plein-complet observation persists the
///      updated belief into [SettingsStorage] under the
///      [brokenMapBeliefSettingsKeyPrefix] namespace,
///   2. a fresh notifier instance (different ProviderContainer)
///      hydrates the same belief lazily on first [beliefFor] call —
///      proving the round-trip survives an "app restart",
///   3. legacy / corrupted JSON in storage falls back to a default
///      belief without crashing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late TripHistoryRepository historyRepo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('broken_map_persist_');
    Hive.init(tmpDir.path);
    final box = await Hive.openBox<String>(HiveBoxes.obd2TripHistory);
    historyRepo = TripHistoryRepository(box: box);
  });

  tearDown(() async {
    await Hive.box<String>(HiveBoxes.obd2TripHistory).deleteFromDisk();
    await Hive.close();
    // Windows occasionally holds the box file open briefly after
    // [Hive.close]. Suppress the deleteSync error so the suite stays
    // green — the temp dir lives under [Directory.systemTemp] and the
    // OS will reclaim it on next reboot. Mirrors the
    // [feedback_hive_widget_test_teardown] guidance that bounded
    // cleanup beats a PathAccessException race.
    try {
      tmpDir.deleteSync(recursive: true);
    } on FileSystemException catch (e, st) {
      debugPrint('persistence_test tearDown: $e\n$st');
    }
  });

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
      'high-discrepancy plein persists the belief in settings storage '
      'under the brokenMapBelief: prefix', () async {
    final storage = _FakeSettingsStorage();
    final container = ProviderContainer(
      overrides: [
        settingsStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);

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
      id: 'closing',
      date: DateTime(2026, 4, 2, 18),
      liters: 12,
      odometerKm: 10100,
    ));

    // Drain the persistence microtask the setter kicked off.
    await Future<void>.delayed(Duration.zero);

    const key = '${brokenMapBeliefSettingsKeyPrefix}veh-a';
    expect(storage.data.containsKey(key), isTrue,
        reason: 'belief must be persisted under the prefix-veh key');
    final raw = storage.data[key];
    expect(raw, isA<String>(), reason: 'belief is JSON-encoded');
    final json = jsonDecode(raw as String) as Map<String, dynamic>;
    final restored = BrokenMapBelief.fromJson(json);
    expect(restored.confidence, closeTo(0.4, 1e-9));
    expect(restored.observationCount, 1);
    expect(restored.lastTrigger, BrokenMapReason.pleinCompletDiscrepancy);
  });

  test(
      'a fresh ProviderContainer hydrates the belief lazily from settings '
      'storage on first beliefFor call — round-trip survives "restart"',
      () async {
    // Seed storage directly as if a previous app session had persisted
    // a belief — equivalent to opening the app after an upgrade.
    final storage = _FakeSettingsStorage();
    final priorBelief = BrokenMapBelief(
      confidence: 0.82,
      observationCount: 3,
      lastUpdate: DateTime(2026, 4, 30),
      lastTrigger: BrokenMapReason.pleinCompletDiscrepancy,
    );
    storage.data['${brokenMapBeliefSettingsKeyPrefix}veh-a'] =
        jsonEncode(priorBelief.toJson());

    final container = ProviderContainer(
      overrides: [
        settingsStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);

    final hydrated = container
        .read(brokenMapBeliefByVehicleProvider.notifier)
        .beliefFor('veh-a');
    expect(hydrated.confidence, closeTo(0.82, 1e-9));
    expect(hydrated.observationCount, 3);
    expect(hydrated.lastTrigger, BrokenMapReason.pleinCompletDiscrepancy);
  });

  test(
      'corrupted JSON in storage falls back to a default belief without '
      'crashing', () async {
    final storage = _FakeSettingsStorage();
    storage.data['${brokenMapBeliefSettingsKeyPrefix}veh-a'] = 'not-json';

    final container = ProviderContainer(
      overrides: [
        settingsStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);

    final hydrated = container
        .read(brokenMapBeliefByVehicleProvider.notifier)
        .beliefFor('veh-a');
    expect(hydrated, const BrokenMapBelief());
  });

  test(
      'high-discrepancy belief crossing 0.7 also lands in the per-adapter '
      'blocklist when a trip with adapterFirmware exists', () async {
    final storage = _FakeSettingsStorage();
    final container = ProviderContainer(
      overrides: [
        settingsStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);

    // Seed an observed-firmware trip so the plein-complet hook can
    // resolve the adapter id when persisting.
    await historyRepo.save(TripHistoryEntry(
      id: 't1',
      vehicleId: 'veh-a',
      adapterFirmware: 'ELM327 v1.5',
      summary: TripSummary(
        distanceKm: 100,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        fuelLitersConsumed: 5,
        startedAt: DateTime(2026, 4, 1, 9),
        endedAt: DateTime(2026, 4, 1, 9, 30),
      ),
    ));

    // Pre-seed a strong belief so a single high-discrepancy
    // observation pushes confidence above 0.7 in one EMA fold.
    // Starting at 0.85, observation = 1.0 → α(1.0) + (1-α)(0.85)
    //                                       = 0.4 + 0.51 = 0.91.
    storage.data['${brokenMapBeliefSettingsKeyPrefix}veh-a'] = jsonEncode(
      const BrokenMapBelief(
        confidence: 0.85,
        observationCount: 5,
        lastTrigger: BrokenMapReason.pleinCompletDiscrepancy,
      ).toJson(),
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
      liters: 12,
      odometerKm: 10100,
    ));

    await Future<void>.delayed(Duration.zero);

    const blocklistKey = 'obdAdapterBroken:ELM327 v1.5';
    expect(storage.data[blocklistKey], isNotNull,
        reason: 'belief crossing the threshold must persist to the blocklist');
    expect(
      storage.data[blocklistKey] as double,
      greaterThan(0.7),
    );
  });
}

class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> data = {};

  @override
  dynamic getSetting(String key) => data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    data[key] = value;
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
