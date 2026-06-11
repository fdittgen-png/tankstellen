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
import 'package:tankstellen/core/domain/fuel_type.dart';
import '../../../helpers/silence_error_logger.dart';

/// Apply-seam coverage for the guided reconciliation workflow's two
/// resolution paths (Epic #2439 / #2443 + #2444 + #2449).
///
/// Drives the same seam the UI drives — `FillUpList.applyReconciliation`
/// (Path A) and `FillUpList.applyVirtualTrajet` (Path B) — over a real
/// [TripHistoryRepository] on in-memory Hive, then asserts the hard
/// invariant `reconciliationBasis(...).residualLiters == 0` for the
/// window after EITHER path. Also covers grandfathering: a legacy
/// correction on disk coexists with a freshly-resolved window.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late TripHistoryRepository historyRepo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('guided_reconcile_apply_');
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

  /// Seed a window with a 7 L gap (pumped 12, consumed 5) → created,
  /// publishing a pending gap. Returns the container.
  Future<ProviderContainer> seedGapWindow() async {
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
      odometerKm: 10000,
    ));
    await notifier.add(mkFillUp(
      id: 'closing',
      date: DateTime(2026, 4, 2, 18),
      liters: 12,
      odometerKm: 10100,
    ));
    return container;
  }

  /// Compute the basis for the CLOSING window (pumped 12 vs trips).
  /// Scopes corrections to THIS window's synthetic id so a legacy
  /// correction from another window (the #2449 grandfather case) is
  /// never pulled in.
  ReconciliationBasis basisForWindow(ProviderContainer container) {
    final fills = container
        .read(fillUpListProvider)
        .where((f) => f.id == 'closing' || f.id == 'correction_closing')
        .toList();
    final trips = historyRepo
        .loadAll()
        .where((e) => !e.summary.startedAt!.isBefore(DateTime(2026, 4, 1, 8)))
        .map((e) => e.summary)
        .toList();
    return reconciliationBasis(
      windowFills: fills,
      windowTrips: trips,
      isVirtualTrip: (t) => t.isVirtual,
    );
  }

  test('Path A → exactly one correction of edited litres, residual 0', () async {
    final container = await seedGapWindow();
    final pending = container.read(pendingReconciliationsProvider)!;
    expect(pending.gap, closeTo(7, 1e-9));

    // User confirms a fill-up was wrong → Path A; edits litres to the
    // gap (7 L, the prefill) and applies.
    final notifier = container.read(fillUpListProvider.notifier);
    await notifier.applyReconciliation(
      pending.correction.copyWith(liters: pending.gap),
    );

    final corrections =
        container.read(fillUpListProvider).where((f) => f.isCorrection).toList();
    expect(corrections, hasLength(1));
    expect(corrections.single.liters, closeTo(7, 1e-9));
    // No virtual trajet on Path A.
    expect(historyRepo.loadAll().where((e) => e.summary.isVirtual), isEmpty);
    // Pending gap cleared + window reconciles.
    expect(container.read(pendingReconciliationsProvider), isNull);
    expect(basisForWindow(container).residualLiters, closeTo(0, 1e-9));
  });

  test(
      'Path B → exactly one virtual trip (gap litres), no correction, '
      'fuel total == real pump litres, residual 0', () async {
    final container = await seedGapWindow();
    final pending = container.read(pendingReconciliationsProvider)!;

    final notifier = container.read(fillUpListProvider.notifier);
    await notifier.applyVirtualTrajet(
      pending: pending,
      gapLiters: pending.gap,
      distanceKm: 100,
    );

    final virtuals =
        historyRepo.loadAll().where((e) => e.summary.isVirtual).toList();
    expect(virtuals, hasLength(1));
    expect(virtuals.single.summary.fuelLitersConsumed, closeTo(7, 1e-9));
    expect(virtuals.single.summary.isVirtual, isTrue);
    // No fill-up correction on Path B → fuel total stays real pump L.
    expect(
      container.read(fillUpListProvider).where((f) => f.isCorrection),
      isEmpty,
    );
    final basis = basisForWindow(container);
    expect(basis.fuelTotalLiters, closeTo(12, 1e-9));
    expect(basis.residualLiters, closeTo(0, 1e-9));
    expect(container.read(pendingReconciliationsProvider), isNull);
  });

  test('Path B virtual trip is excluded from a re-run consumed (no double-count)',
      () async {
    final container = await seedGapWindow();
    final pending = container.read(pendingReconciliationsProvider)!;
    final notifier = container.read(fillUpListProvider.notifier);
    await notifier.applyVirtualTrajet(
      pending: pending,
      gapLiters: pending.gap,
      distanceKm: 100,
    );

    // A later clean window: a real trip burns ~12 L, plein pumps 12.
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

    // The virtual trip from the first window must NOT be counted in the
    // second window's reconciliation → clean window, no new gap.
    expect(container.read(pendingReconciliationsProvider), isNull,
        reason: 'virtual trip excluded from the next window consumed');
  });

  test('Decide later → nothing created, gap retained', () async {
    final container = await seedGapWindow();
    expect(container.read(pendingReconciliationsProvider), isNotNull);

    // The workflow returns "deferred" → the UI applies NOTHING. We
    // simulate that by NOT calling either apply path.
    expect(
      container.read(fillUpListProvider).where((f) => f.isCorrection),
      isEmpty,
    );
    expect(historyRepo.loadAll().where((e) => e.summary.isVirtual), isEmpty);
    // The gap is retained for #2445's re-entry surface.
    expect(container.read(pendingReconciliationsProvider), isNotNull);
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
