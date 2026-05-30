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
import 'package:tankstellen/features/consumption/domain/services/reconciliation_basis.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/consumption/providers/pending_reconciliation_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import '../helpers/silence_error_logger.dart';

/// Cross-view invariant integration test (Epic #2439 / #2448) — the
/// standing guard the project lacked.
///
/// Drives the REAL production seam end-to-end — `FillUpList` (which runs
/// the detector → publishes a [PendingReconciliation]), then the two
/// consented apply paths (`applyReconciliation` = Path A,
/// `applyVirtualTrajet` = Path B) over a real [TripHistoryRepository] on
/// in-memory Hive — and asserts the HARD INVARIANT the maintainer
/// validated (2026-05-30): over each plein-to-plein tank window,
///
///   Σ FillUp.liters(incl. corrections) == Σ trip.fuelLitersConsumed
///   (incl. virtual trips)
///
/// expressed as `reconciliationBasis(...).residualLiters`:
///
///   * `residual == gap` BEFORE any resolution (the gap is real),
///   * `residual == 0` after EITHER Path A or Path B (identical totals),
///   * defer leaves `residual == gap` AND the pending marker retained,
///   * parametric: a range of (pumped, consumed) gaps above threshold are
///     ALL driven to 0 by BOTH paths — proving the figures conclude with
///     the same results regardless of which path the user picks,
///   * below-threshold / negative-gap / no-trips raise NO workflow and
///     leave the residual untouched.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late TripHistoryRepository historyRepo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('reconcile_invariant_');
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

  // ── Fixture shape (mirrors fill_up_receipt_reconciliation_journey) ──
  const vehicleId = 'veh-308';
  final windowStart = DateTime(2026, 4, 1, 8);

  Future<void> seedTrip({
    required String id,
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
    required double liters,
    required double odometerKm,
    bool isFullTank = true,
  }) =>
      FillUp(
        id: id,
        date: date,
        liters: liters,
        totalCost: liters * 1.5,
        odometerKm: odometerKm,
        fuelType: FuelType.diesel,
        vehicleId: vehicleId,
        isFullTank: isFullTank,
      );

  /// Computes the basis for the CLOSING window. Scopes corrections to the
  /// closing plein + its synthetic correction id so an unrelated window's
  /// entries never leak in; classifies virtual trips by the real
  /// [TripSummary.isVirtual] flag (#2444). Trips are scoped to the window
  /// by `startedAt`.
  ReconciliationBasis basisForWindow(
    ProviderContainer container, {
    String closingId = 'plein-close',
  }) {
    final fills = container
        .read(fillUpListProvider)
        .where((f) => f.id == closingId || f.id == 'correction_$closingId')
        .toList();
    final trips = historyRepo
        .loadAll()
        .where((e) => !e.summary.startedAt!.isBefore(windowStart))
        .map((e) => e.summary)
        .toList();
    return reconciliationBasis(
      windowFills: fills,
      windowTrips: trips,
      isVirtualTrip: (t) => t.isVirtual,
    );
  }

  /// Seed a single plein-to-plein window with a [pumped]-vs-[consumed]
  /// gap. An opening plein closes the prior window; the closing plein
  /// pumps [pumped] L; one recorded trip integrated [consumed] L. Returns
  /// the container after the detector ran on the closing-plein save.
  Future<ProviderContainer> seedWindow({
    required double pumped,
    required double consumed,
    double openingLiters = 30,
  }) async {
    final container = makeContainer();
    await seedTrip(
      id: 'trip-1',
      startedAt: windowStart.add(const Duration(hours: 1)),
      distanceKm: 500,
      fuelLitersConsumed: consumed,
    );
    final notifier = container.read(fillUpListProvider.notifier);
    await notifier.add(mkFillUp(
      id: 'plein-open',
      date: windowStart,
      liters: openingLiters,
      odometerKm: 30000,
    ));
    await notifier.add(mkFillUp(
      id: 'plein-close',
      date: DateTime(2026, 4, 15, 18),
      liters: pumped,
      odometerKm: 30800,
    ));
    return container;
  }

  test('residual == gap BEFORE any resolution (the gap is real)', () async {
    final container = await seedWindow(pumped: 42.35, consumed: 32);
    final pending = container.read(pendingReconciliationsProvider);
    expect(pending, isNotNull, reason: 'a ~10 L gap must publish a pending');
    expect(pending!.gap, closeTo(10.35, 1e-6));

    final basis = basisForWindow(container);
    expect(basis.fuelTotalLiters, closeTo(42.35, 1e-6));
    expect(basis.trajetsTotalLiters, closeTo(32, 1e-6));
    expect(basis.residualLiters, closeTo(pending.gap, 1e-6),
        reason: 'before resolution the residual equals the published gap');
  });

  test(
      'Path A (correctFillUps) → residual 0: exactly one correction of '
      'gap, no virtual trip', () async {
    final container = await seedWindow(pumped: 42.35, consumed: 32);
    final pending = container.read(pendingReconciliationsProvider)!;

    await container
        .read(fillUpListProvider.notifier)
        .applyReconciliation(pending.correction.copyWith(liters: pending.gap));

    final corrections = container
        .read(fillUpListProvider)
        .where((f) => f.isCorrection)
        .toList();
    expect(corrections, hasLength(1));
    expect(corrections.single.liters, closeTo(pending.gap, 1e-6));
    // No virtual trip on Path A.
    expect(historyRepo.loadAll().where((e) => e.summary.isVirtual), isEmpty);
    expect(container.read(pendingReconciliationsProvider), isNull);
    expect(basisForWindow(container).residualLiters, closeTo(0, 1e-6));
  });

  test(
      'Path B (addVirtualTrajet) → residual 0: one isVirtual trip of gap, '
      'no correction, fuel total == real pumped', () async {
    final container = await seedWindow(pumped: 42.35, consumed: 32);
    final pending = container.read(pendingReconciliationsProvider)!;

    await container.read(fillUpListProvider.notifier).applyVirtualTrajet(
          pending: pending,
          gapLiters: pending.gap,
          distanceKm: 150,
        );

    final virtuals =
        historyRepo.loadAll().where((e) => e.summary.isVirtual).toList();
    expect(virtuals, hasLength(1));
    expect(virtuals.single.summary.fuelLitersConsumed, closeTo(pending.gap, 1e-6));
    // No fill-up correction on Path B.
    expect(
      container.read(fillUpListProvider).where((f) => f.isCorrection),
      isEmpty,
    );
    final basis = basisForWindow(container);
    // Total L stays honest — exactly what the user pumped.
    expect(basis.fuelTotalLiters, closeTo(42.35, 1e-6));
    expect(basis.residualLiters, closeTo(0, 1e-6));
    expect(container.read(pendingReconciliationsProvider), isNull);
  });

  test(
      'Defer → residual stays == gap AND the pending marker is retained '
      '(decision not lost)', () async {
    final container = await seedWindow(pumped: 42.35, consumed: 32);
    final pending = container.read(pendingReconciliationsProvider);
    expect(pending, isNotNull);

    // The workflow returned "deferred" → the UI applies NOTHING. Nothing
    // is created on either side.
    expect(
      container.read(fillUpListProvider).where((f) => f.isCorrection),
      isEmpty,
    );
    expect(historyRepo.loadAll().where((e) => e.summary.isVirtual), isEmpty);

    final basis = basisForWindow(container);
    expect(basis.residualLiters, closeTo(pending!.gap, 1e-6),
        reason: 'deferring leaves the gap real');
    // The marker survives — #2445's 'Resolve gap' affordance reads it.
    expect(container.read(pendingReconciliationsProvider), isNotNull);
  });

  test(
      'Defer then a later CLEAN plein → prior unresolved gap is NOT lost '
      'or duplicated (#2445)', () async {
    final container = await seedWindow(pumped: 42.35, consumed: 32);
    final deferred = container.read(pendingReconciliationsProvider);
    expect(deferred, isNotNull);

    // User defers, then logs a later, perfectly-reconciled plein: a real
    // trip burns ~40 L, the plein pumps 40 → no NEW gap. The earlier
    // unresolved gap must survive (not silently cleared, not re-published
    // as a second pending).
    await seedTrip(
      id: 'trip-2',
      startedAt: DateTime(2026, 4, 20, 9),
      distanceKm: 500,
      fuelLitersConsumed: 39.8,
    );
    await container.read(fillUpListProvider.notifier).add(mkFillUp(
          id: 'plein-close-2',
          date: DateTime(2026, 4, 28, 18),
          liters: 40,
          odometerKm: 31600,
        ));

    final still = container.read(pendingReconciliationsProvider);
    expect(still, isNotNull,
        reason: 'a clean later window must not drop the deferred gap');
    expect(still, deferred,
        reason: 'the same gap is retained, not re-published/duplicated');
  });

  group('parametric — BOTH paths drive residual to 0 for any above-threshold gap',
      () {
    // (pumped, consumed) pairs whose gap clears both reconciler floors
    // (>= 0.5 L AND >= 5 % of pumped). Each must converge to residual 0
    // via Path A and via Path B, with identical fuel/trajets totals.
    const cases = <(double, double)>[
      (50, 40), // 10 L
      (42.35, 32), // 10.35 L (the journey fixture)
      (60, 45.5), // 14.5 L
      (35, 30), // 5 L (just over 5 % of 35 = 1.75)
      (80, 60), // 20 L
    ];

    for (final (pumped, consumed) in cases) {
      final gap = pumped - consumed;
      test('gap ${gap.toStringAsFixed(2)} L → Path A residual 0', () async {
        final container = await seedWindow(pumped: pumped, consumed: consumed);
        final pending = container.read(pendingReconciliationsProvider);
        expect(pending, isNotNull,
            reason: 'gap $gap must be above threshold');
        expect(pending!.gap, closeTo(gap, 1e-6));

        await container
            .read(fillUpListProvider.notifier)
            .applyReconciliation(
              pending.correction.copyWith(liters: pending.gap),
            );

        final basis = basisForWindow(container);
        expect(basis.residualLiters, closeTo(0, 1e-6));
        // Both totals land on the same value: real pumped litres.
        expect(basis.fuelTotalLiters, closeTo(pumped, 1e-6));
        expect(basis.trajetsTotalLiters, closeTo(pumped, 1e-6));
      });

      test('gap ${gap.toStringAsFixed(2)} L → Path B residual 0', () async {
        final container = await seedWindow(pumped: pumped, consumed: consumed);
        final pending = container.read(pendingReconciliationsProvider)!;

        await container.read(fillUpListProvider.notifier).applyVirtualTrajet(
              pending: pending,
              gapLiters: pending.gap,
              distanceKm: 100,
            );

        final basis = basisForWindow(container);
        expect(basis.residualLiters, closeTo(0, 1e-6));
        // Total L stays the real pumped figure on Path B (no correction).
        expect(basis.fuelTotalLiters, closeTo(pumped, 1e-6));
        expect(basis.trajetsTotalLiters, closeTo(pumped, 1e-6));
      });
    }
  });

  group('no workflow raised + residual untouched', () {
    test('below-threshold gap → no pending, residual stays the small gap',
        () async {
      // pumped 38.5 vs consumed 38.4 → 0.1 L gap, below both floors.
      final container = await seedWindow(pumped: 38.5, consumed: 38.4);
      expect(container.read(pendingReconciliationsProvider), isNull,
          reason: 'a 0.1 L gap is below the reconciliation floors');
      // The basis still reflects the untouched small gap — nothing added.
      final basis = basisForWindow(container);
      expect(basis.residualLiters, closeTo(0.1, 1e-6));
      expect(
        container.read(fillUpListProvider).where((f) => f.isCorrection),
        isEmpty,
      );
    });

    test('negative gap (trips exceed pumped) → no pending, residual < 0',
        () async {
      // pumped 30 vs consumed 40 → the integrator ran hot; the reconciler
      // never proposes a correction for a negative gap.
      final container = await seedWindow(pumped: 30, consumed: 40);
      expect(container.read(pendingReconciliationsProvider), isNull,
          reason: 'a negative gap never raises the workflow');
      final basis = basisForWindow(container);
      expect(basis.residualLiters, closeTo(-10, 1e-6),
          reason: 'residual is left as the raw signed gap, untouched');
      expect(
        container.read(fillUpListProvider).where((f) => f.isCorrection),
        isEmpty,
      );
    });

    test('no trips at all → no pending raised, residual untouched', () async {
      final container = makeContainer();
      final notifier = container.read(fillUpListProvider.notifier);
      await notifier.add(mkFillUp(
        id: 'plein-open',
        date: windowStart,
        liters: 30,
        odometerKm: 30000,
      ));
      await notifier.add(mkFillUp(
        id: 'plein-close',
        date: DateTime(2026, 4, 15, 18),
        liters: 42,
        odometerKm: 30800,
      ));

      expect(container.read(pendingReconciliationsProvider), isNull,
          reason: 'with no recorded trips the detector raises no workflow');
      expect(
        container.read(fillUpListProvider).where((f) => f.isCorrection),
        isEmpty,
      );
      // basis has no trips → trajets side is 0, residual == full pumped,
      // but it is LEFT untouched (no correction, no virtual).
      final basis = basisForWindow(container);
      expect(basis.trajetsTotalLiters, closeTo(0, 1e-6));
      expect(basis.residualLiters, closeTo(42, 1e-6));
    });
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
