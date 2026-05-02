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

/// #1361 phase 2a — whole-window trip relinking.
///
/// When a closing plein lands, every trip in the open plein-to-plein
/// window is mirrored across every fill in that window (the prior
/// partials AND the closing plein). This is a behavioural change from
/// the pair-to-nearest semantics that #888 originally shipped — the
/// user wanted "the trajets since then are related to all fill-ups
/// since then" (#1361 spec).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late TripHistoryRepository historyRepo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('relinking_test_');
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
    double fuel = 5,
    double distanceKm = 50,
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
        fuelLitersConsumed: fuel,
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
      '1 opening plein + 2 partials + 5 trips → after closing plein '
      'lands, every trip id appears in every partial AND the closing '
      'plein\'s linkedTripIds', () async {
    // Layout (all veh-a):
    //   d0 — opening plein A (full)
    //   d1, d2, d3, d4, d5 — five trips
    //   d6 — partial top-up P1
    //   d7 — partial top-up P2
    //   d8 — closing plein B (full)
    final d0 = DateTime(2026, 4, 1);
    final d6 = DateTime(2026, 4, 10);
    final d7 = DateTime(2026, 4, 12);
    final d8 = DateTime(2026, 4, 15);

    for (var i = 0; i < 5; i++) {
      await seedTrip(
        id: 'trip-$i',
        vehicleId: 'veh-a',
        startedAt: d0.add(Duration(days: i + 1)),
      );
    }

    final container = makeContainer();
    final notifier = container.read(fillUpListProvider.notifier);
    // Sub-litre numbers so reconciliation never fires (all gaps below
    // floor) — the test focuses on relinking, not on correction.
    // 5 trips × 5 L = 25 L integrated; opening plein + partials +
    // closing keep the cumulative pump close to 25 ± 0.5 L over the
    // window so no correction is synthesised.
    await notifier.add(mkFillUp(id: 'A', date: d0, liters: 0.1));
    await notifier.add(mkFillUp(
      id: 'P1',
      date: d6,
      liters: 12.4,
      isFullTank: false,
    ));
    await notifier.add(mkFillUp(
      id: 'P2',
      date: d7,
      liters: 12.4,
      isFullTank: false,
    ));
    await notifier.add(mkFillUp(id: 'B', date: d8, liters: 0.1));

    final all = container.read(fillUpListProvider);
    final closing = all.firstWhere((f) => f.id == 'B');
    final partial1 = all.firstWhere((f) => f.id == 'P1');
    final partial2 = all.firstWhere((f) => f.id == 'P2');
    final opening = all.firstWhere((f) => f.id == 'A');

    final tripSet = {'trip-0', 'trip-1', 'trip-2', 'trip-3', 'trip-4'};
    expect(closing.linkedTripIds.toSet(), tripSet,
        reason: 'closing plein must carry all 5 trip ids');
    expect(partial1.linkedTripIds.toSet(), tripSet,
        reason: 'partial 1 must mirror the closing plein\'s links');
    expect(partial2.linkedTripIds.toSet(), tripSet,
        reason: 'partial 2 must mirror the closing plein\'s links');
    // Convention: opening plein is the EXCLUSIVE lower bound, so it
    // doesn't carry the closed-window trips. (The existing #888 test
    // relies on this — A's links stay empty.)
    expect(opening.linkedTripIds, isEmpty,
        reason: 'opening plein anchors the window from below '
            '(exclusive); its own links remain whatever they were '
            'when it was first added');
  });

  test(
      'closing plein triggers backwards re-link across the closed '
      'window even when partials were saved before the trips arrived',
      () async {
    // Real-world ordering: user logs the partial first, then drives,
    // then logs the closing plein. The trip arrives between the two
    // saves and must propagate to the partial when the closing plein
    // re-links.
    final d0 = DateTime(2026, 4, 1);
    final d6 = DateTime(2026, 4, 10);
    final d8 = DateTime(2026, 4, 15);

    final container = makeContainer();
    final notifier = container.read(fillUpListProvider.notifier);

    // Opening plein, then partial — neither sees any trips.
    await notifier.add(mkFillUp(id: 'A', date: d0, liters: 0.1));
    await notifier.add(mkFillUp(
      id: 'P1',
      date: d6,
      liters: 12,
      isFullTank: false,
    ));

    var partial = container
        .read(fillUpListProvider)
        .firstWhere((f) => f.id == 'P1');
    expect(partial.linkedTripIds, isEmpty);

    // Trip arrives now.
    await seedTrip(
      id: 'trip-late',
      vehicleId: 'veh-a',
      startedAt: d0.add(const Duration(days: 7)),
    );

    // Closing plein — should re-link backwards so the partial picks
    // up the trip too.
    await notifier.add(mkFillUp(id: 'B', date: d8, liters: 0.1));

    final all = container.read(fillUpListProvider);
    final closing = all.firstWhere((f) => f.id == 'B');
    partial = all.firstWhere((f) => f.id == 'P1');

    expect(closing.linkedTripIds, ['trip-late']);
    expect(partial.linkedTripIds, ['trip-late'],
        reason: 'partial must inherit the trip via backwards re-link');
  });

  test(
      'pre-existing single-plein scenario (#888 fixture parity) — '
      'no partials, A→B→C still link by per-window trip set', () async {
    // This mirrors the original #888 trip_linking_test fixture to
    // prove backward compat. Three pleins, no partials, ids partition
    // by window.
    final dateA = DateTime(2026, 4, 1, 8);
    final dateB = DateTime(2026, 4, 10, 18);
    final dateC = DateTime(2026, 4, 20, 18);

    await seedTrip(
      id: 'trip-ab-1',
      vehicleId: 'veh-a',
      startedAt: dateA.add(const Duration(days: 1)),
    );
    await seedTrip(
      id: 'trip-ab-2',
      vehicleId: 'veh-a',
      startedAt: dateA.add(const Duration(days: 5)),
    );
    await seedTrip(
      id: 'trip-bc-1',
      vehicleId: 'veh-a',
      startedAt: dateB.add(const Duration(days: 2)),
    );

    final container = makeContainer();
    final notifier = container.read(fillUpListProvider.notifier);
    await notifier.add(mkFillUp(id: 'A', date: dateA, liters: 0.1));
    await notifier.add(mkFillUp(id: 'B', date: dateB, liters: 0.1));
    await notifier.add(mkFillUp(id: 'C', date: dateC, liters: 0.1));

    final all = container.read(fillUpListProvider);
    final a = all.firstWhere((f) => f.id == 'A');
    final b = all.firstWhere((f) => f.id == 'B');
    final c = all.firstWhere((f) => f.id == 'C');

    expect(a.linkedTripIds, isEmpty,
        reason: 'first plein has no trips before it');
    expect(b.linkedTripIds.toSet(), {'trip-ab-1', 'trip-ab-2'});
    expect(c.linkedTripIds, ['trip-bc-1']);
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
