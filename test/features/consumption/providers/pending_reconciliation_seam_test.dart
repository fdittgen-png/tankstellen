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
import 'package:tankstellen/core/domain/fuel_type.dart';
import '../../../helpers/silence_error_logger.dart';

/// Detect-vs-publish seam coverage (Epic #2439 / #2442).
///
/// Verifies the NEVER-SILENT flip: when a gap is detected the seam now
///   - surfaces the gap + the proposed correction via the
///     [PendingReconciliations] provider (the read-side hook the guided
///     workflow consumes), AND
///   - creates NOTHING by itself — the silent save is GONE. No
///     correction fill-up and no virtual trajet exist until the user
///     completes the workflow (the silent-save regression guard), AND
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
      'AND NOTHING is created (silent-save regression guard)', () async {
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

    // NEVER SILENT (#2442): the seam created NOTHING. No correction
    // fill-up exists until the user completes the workflow.
    final stored = container.read(fillUpListProvider);
    expect(
      stored.where((f) => f.isCorrection),
      isEmpty,
      reason: 'no correction is created without the guided workflow',
    );
    // And no virtual trajet was injected either.
    expect(
      historyRepo.loadAll().where((e) => e.summary.isVirtual),
      isEmpty,
      reason: 'no virtual trajet is created without the guided workflow',
    );
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

  test(
      'a same-vehicle UNRESOLVED gap survives a later clean window (#2445 — '
      'the deferred decision is never lost)', () async {
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
    final firstGap = container.read(pendingReconciliationsProvider);
    expect(firstGap, isNotNull);

    // The user defers (never completes the workflow), then logs a later
    // clean window: matched integrator → skippedBelowThreshold. Pre-#2445
    // this silently cleared the dangling gap; #2445 inverts that — a still
    // -unresolved gap for the SAME vehicle must NOT be lost (the 'Resolve
    // gap' affordance re-opens it), and must not be re-published/duplicated.
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

    final still = container.read(pendingReconciliationsProvider);
    expect(still, isNotNull,
        reason: 'a clean later window must not drop the deferred gap');
    expect(still, firstGap,
        reason: 'the same gap is retained, not duplicated/re-published');
  });

  test(
      'a stale gap from a DIFFERENT vehicle is cleared by a clean window '
      '(#2445)', () async {
    final container = makeContainer();

    // First window on veh-a: high discrepancy → created → pending gap.
    await seedTrip(
      id: 't1',
      vehicleId: 'veh-a',
      startedAt: DateTime(2026, 4, 1, 9),
      distanceKm: 100,
      fuelLitersConsumed: 5,
    );
    final notifier = container.read(fillUpListProvider.notifier);
    await notifier.add(mkFillUp(
      id: 'opening-a',
      date: DateTime(2026, 4, 1, 8),
      liters: 30,
      odometerKm: 10000,
    ));
    await notifier.add(mkFillUp(
      id: 'closing-a',
      date: DateTime(2026, 4, 2, 18),
      liters: 12,
      odometerKm: 10100,
    ));
    expect(container.read(pendingReconciliationsProvider), isNotNull);

    // A clean window for a DIFFERENT vehicle (veh-b). The veh-a gap is
    // stale here — it must be cleared (only same-vehicle deferred gaps
    // survive).
    await seedTrip(
      id: 't2',
      vehicleId: 'veh-b',
      startedAt: DateTime(2026, 4, 3, 9),
      distanceKm: 100,
      fuelLitersConsumed: 11.8,
    );
    await notifier.add(mkFillUp(
      id: 'opening-b',
      date: DateTime(2026, 4, 3, 8),
      vehicleId: 'veh-b',
      liters: 30,
      odometerKm: 20000,
    ));
    await notifier.add(mkFillUp(
      id: 'closing-b',
      date: DateTime(2026, 4, 4, 18),
      vehicleId: 'veh-b',
      liters: 12,
      odometerKm: 20100,
    ));

    expect(container.read(pendingReconciliationsProvider), isNull,
        reason: 'a clean window clears a stale gap from another vehicle');
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
