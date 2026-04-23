import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// #888 — auto-link OBD2 trajets to the fill-up they completed.
///
/// Trajets are first-class, standalone recordings. The fill-up save
/// path pulls the trip-history ids recorded for the vehicle since the
/// previous fill-up and persists them in [FillUp.linkedTripIds]. That
/// replaces the old inline coupling where recording-start required a
/// pending fill-up.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late TripHistoryRepository historyRepo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('trip_linking_test_');
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
    double distanceKm = 25,
  }) {
    return historyRepo.save(TripHistoryEntry(
      id: id,
      vehicleId: vehicleId,
      summary: TripSummary(
        distanceKm: distanceKm,
        maxRpm: 2800,
        highRpmSeconds: 10,
        idleSeconds: 30,
        harshBrakes: 0,
        harshAccelerations: 0,
        fuelLitersConsumed: distanceKm * 6.5 / 100,
        startedAt: startedAt,
        endedAt: startedAt.add(const Duration(minutes: 20)),
      ),
    ));
  }

  FillUp mkFillUp({
    required String id,
    required DateTime date,
    String vehicleId = 'veh-a',
    double liters = 40,
    double totalCost = 60,
    double odometerKm = 10000,
  }) =>
      FillUp(
        id: id,
        date: date,
        liters: liters,
        totalCost: totalCost,
        odometerKm: odometerKm,
        fuelType: FuelType.e10,
        vehicleId: vehicleId,
      );

  test('3 recorded trips + 1 new fill-up → linkedTripIds contains all 3 '
      'ids', () async {
    final fillDate = DateTime(2026, 4, 20, 18);
    final t1 = fillDate.subtract(const Duration(days: 3));
    final t2 = fillDate.subtract(const Duration(days: 2));
    final t3 = fillDate.subtract(const Duration(hours: 5));

    await seedTrip(id: 'trip-1', vehicleId: 'veh-a', startedAt: t1);
    await seedTrip(id: 'trip-2', vehicleId: 'veh-a', startedAt: t2);
    await seedTrip(id: 'trip-3', vehicleId: 'veh-a', startedAt: t3);

    final container = makeContainer();
    final notifier = container.read(fillUpListProvider.notifier);
    await notifier.add(mkFillUp(id: 'fill-1', date: fillDate));

    final saved = container.read(fillUpListProvider).single;
    expect(saved.linkedTripIds, hasLength(3));
    expect(saved.linkedTripIds.toSet(),
        {'trip-1', 'trip-2', 'trip-3'});
  });

  test('0 recorded trips → fill-up saves, linkedTripIds == []',
      () async {
    final container = makeContainer();
    final notifier = container.read(fillUpListProvider.notifier);
    await notifier.add(mkFillUp(
      id: 'fill-only',
      date: DateTime(2026, 4, 20, 18),
    ));

    final saved = container.read(fillUpListProvider).single;
    expect(saved.linkedTripIds, isEmpty);
  });

  test('2 fill-ups A+B, 5 trips (3 between A-B, 2 after B) → B links '
      'the 3, new fill-up C links the 2', () async {
    final dateA = DateTime(2026, 4, 1, 8);
    final dateB = DateTime(2026, 4, 10, 18);
    final dateC = DateTime(2026, 4, 20, 18);

    // 3 trips strictly between A and B.
    await seedTrip(
      id: 'trip-ab-1',
      vehicleId: 'veh-a',
      startedAt: dateA.add(const Duration(days: 1)),
    );
    await seedTrip(
      id: 'trip-ab-2',
      vehicleId: 'veh-a',
      startedAt: dateA.add(const Duration(days: 3)),
    );
    await seedTrip(
      id: 'trip-ab-3',
      vehicleId: 'veh-a',
      startedAt: dateA.add(const Duration(days: 7)),
    );
    // 2 trips strictly between B and C.
    await seedTrip(
      id: 'trip-bc-1',
      vehicleId: 'veh-a',
      startedAt: dateB.add(const Duration(days: 2)),
    );
    await seedTrip(
      id: 'trip-bc-2',
      vehicleId: 'veh-a',
      startedAt: dateB.add(const Duration(days: 5)),
    );

    final container = makeContainer();
    final notifier = container.read(fillUpListProvider.notifier);

    // Seed A (no trips before it → empty links).
    await notifier.add(mkFillUp(id: 'A', date: dateA));
    // B — should pick up the 3 trips between A and B.
    await notifier.add(mkFillUp(id: 'B', date: dateB));
    // C — should pick up only the 2 trips between B and C.
    await notifier.add(mkFillUp(id: 'C', date: dateC));

    final all = container.read(fillUpListProvider);
    // Newest-first.
    final fillC = all.firstWhere((f) => f.id == 'C');
    final fillB = all.firstWhere((f) => f.id == 'B');
    final fillA = all.firstWhere((f) => f.id == 'A');

    expect(fillA.linkedTripIds, isEmpty,
        reason: 'No trips before fill-up A');
    expect(fillB.linkedTripIds.toSet(),
        {'trip-ab-1', 'trip-ab-2', 'trip-ab-3'},
        reason: 'B links all 3 trips in the A→B window');
    expect(fillC.linkedTripIds.toSet(), {'trip-bc-1', 'trip-bc-2'},
        reason: 'C links only the 2 trips in the B→C window');
  });

  test('trips for a different vehicle are NOT linked', () async {
    final fillDate = DateTime(2026, 4, 20, 18);
    await seedTrip(
      id: 'trip-mine',
      vehicleId: 'veh-a',
      startedAt: fillDate.subtract(const Duration(hours: 5)),
    );
    await seedTrip(
      id: 'trip-theirs',
      vehicleId: 'veh-b',
      startedAt: fillDate.subtract(const Duration(hours: 3)),
    );

    final container = makeContainer();
    final notifier = container.read(fillUpListProvider.notifier);
    await notifier.add(mkFillUp(id: 'fill-a', date: fillDate));

    final saved = container.read(fillUpListProvider).single;
    expect(saved.linkedTripIds, ['trip-mine']);
  });
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
