// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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
import 'package:tankstellen/features/consumption/providers/pending_reconciliation_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import '../../../helpers/silence_error_logger.dart';

/// Detect-vs-apply seam coverage (Epic #2439 / #2441).
///
/// Verifies the split introduced for the guided reconciliation
/// workflow:
///   - on a created action the [PendingReconciliations] provider
///     surfaces the gap + the proposed correction (the read-side hook
///     #2442 will consume), AND
///   - the apply seam STILL performs the silent save today — the
///     correction round-trips into the fill-up log exactly as before
///     (behaviour-neutral; the behaviour flip is PR3/#2442), AND
///   - non-created outcomes (skipped-below-threshold, clamped-negative,
///     no-trips) surface NO pending gap.
///
/// Uses a real [TripHistoryRepository] over in-memory Hive so the seam
/// traverses the same path production does — mirrors
/// `plein_complet_belief_hook_test.dart`.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late TripHistoryRepository historyRepo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('pending_reconcile_seam_');
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
      'created action → PendingReconciliations exposes the gap + correction '
      'AND the silent save still happens (behaviour-neutral)', () async {
    final container = makeContainer();

    // Integrator only saw 5 L across 100 km; the closing plein pumps
    // 12 L → a 7 L gap that clears both reconciler floors → created.
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
      odometerKm: 10000,
    ));
    await notifier.add(mkFillUp(
      id: 'closing',
      date: DateTime(2026, 4, 2, 18),
      liters: 12,
      odometerKm: 10100,
    ));

    // Read-side hook: the pending gap is surfaced for the workflow.
    // The opening plein closes the PRIOR window (exclusive lower bound),
    // so it doesn't count toward this window: pumped = closing(12);
    // consumed = 5; gap = 7.
    final pending = container.read(pendingReconciliationsProvider);
    expect(pending, isNotNull, reason: 'a created action surfaces a gap');
    expect(pending!.pumped, closeTo(12, 1e-9));
    expect(pending.consumed, closeTo(5, 1e-9));
    expect(pending.gap, closeTo(7, 1e-9));
    expect(pending.vehicleId, 'veh-a');
    // The proposed correction mirrors the detector's synthetic entry.
    expect(pending.correction.isCorrection, isTrue);
    expect(pending.correction.isFullTank, isFalse);
    expect(pending.correction.liters, closeTo(7, 1e-9));
    expect(pending.correction.id, 'correction_closing');
    expect(pending.windowMidpointDate, pending.correction.date);
    expect(
      pending.windowMidpointOdometerKm,
      pending.correction.odometerKm,
    );

    // Behaviour-neutral: the apply seam STILL saved the correction.
    final stored = container.read(fillUpListProvider);
    final corrections = stored.where((f) => f.isCorrection).toList();
    expect(corrections, hasLength(1),
        reason: 'the silent save still persists exactly one correction');
    expect(corrections.single.liters, closeTo(7, 1e-9));
    expect(corrections.single.id, 'correction_closing');
  });

  test('skippedBelowThreshold (pumped ≈ consumed) surfaces NO pending gap',
      () async {
    final container = makeContainer();

    // Integrator saw 11.7 L; plein pumps 12 L → 0.3 L gap, below the
    // 0.5 L absolute floor → skippedBelowThreshold.
    await seedTrip(
      id: 't1',
      vehicleId: 'veh-a',
      startedAt: DateTime(2026, 4, 1, 9),
      distanceKm: 100,
      fuelLitersConsumed: 11.7,
    );

    final notifier = container.read(fillUpListProvider.notifier);
    await notifier.add(mkFillUp(
      id: 'opening',
      date: DateTime(2026, 4, 1, 8),
      liters: 0.0001, // negligible — keeps the window gap tiny
      odometerKm: 10000,
    ));
    await notifier.add(mkFillUp(
      id: 'closing',
      date: DateTime(2026, 4, 2, 18),
      liters: 12,
      odometerKm: 10100,
    ));

    expect(container.read(pendingReconciliationsProvider), isNull);
    expect(
      container.read(fillUpListProvider).where((f) => f.isCorrection),
      isEmpty,
    );
  });

  test('clampedNegative (integrator over-reported) surfaces NO pending gap',
      () async {
    final container = makeContainer();

    // Integrator saw 50 L but the window only pumped 12 L → negative
    // gap → clampedNegative, no correction.
    await seedTrip(
      id: 't1',
      vehicleId: 'veh-a',
      startedAt: DateTime(2026, 4, 1, 9),
      distanceKm: 100,
      fuelLitersConsumed: 50,
    );

    final notifier = container.read(fillUpListProvider.notifier);
    await notifier.add(mkFillUp(
      id: 'opening',
      date: DateTime(2026, 4, 1, 8),
      liters: 0.0001,
      odometerKm: 10000,
    ));
    await notifier.add(mkFillUp(
      id: 'closing',
      date: DateTime(2026, 4, 2, 18),
      liters: 12,
      odometerKm: 10100,
    ));

    expect(container.read(pendingReconciliationsProvider), isNull);
    expect(
      container.read(fillUpListProvider).where((f) => f.isCorrection),
      isEmpty,
    );
  });

  test('skippedNoTrips (no integrated fuel) surfaces NO pending gap',
      () async {
    final container = makeContainer();

    // No trips seeded → reconciler returns skippedNoTrips.
    final notifier = container.read(fillUpListProvider.notifier);
    await notifier.add(mkFillUp(
      id: 'opening',
      date: DateTime(2026, 4, 1, 8),
      liters: 30,
      odometerKm: 10000,
    ));
    await notifier.add(mkFillUp(
      id: 'closing',
      date: DateTime(2026, 4, 2, 18),
      liters: 12,
      odometerKm: 10100,
    ));

    expect(container.read(pendingReconciliationsProvider), isNull);
    expect(
      container.read(fillUpListProvider).where((f) => f.isCorrection),
      isEmpty,
    );
  });

  test('a created gap is cleared when a later clean window needs none',
      () async {
    final container = makeContainer();

    // First window: high discrepancy → created → pending gap set.
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
      odometerKm: 10000,
    ));
    await notifier.add(mkFillUp(
      id: 'closing-1',
      date: DateTime(2026, 4, 2, 18),
      liters: 12,
      odometerKm: 10100,
    ));
    expect(container.read(pendingReconciliationsProvider), isNotNull);

    // Second window: matched integrator → skippedBelowThreshold → the
    // stale gap must be cleared, not left dangling.
    await seedTrip(
      id: 't2',
      vehicleId: 'veh-a',
      startedAt: DateTime(2026, 4, 3, 9),
      distanceKm: 100,
      fuelLitersConsumed: 11.8,
    );
    await notifier.add(mkFillUp(
      id: 'closing-2',
      date: DateTime(2026, 4, 4, 18),
      liters: 12,
      odometerKm: 10200,
    ));

    expect(container.read(pendingReconciliationsProvider), isNull,
        reason: 'a clean window clears the previous pending gap');
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
