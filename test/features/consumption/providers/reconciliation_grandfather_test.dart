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
import '../../../helpers/silence_error_logger.dart';

/// Grandfathering coverage (Epic #2439 / #2449).
///
/// Validated decision: pre-existing SILENT auto-corrections on disk are
/// left exactly as-is — never migrated, deleted, or re-prompted. Only
/// NEWLY-detected gaps use the guided workflow. This test puts a legacy
/// correction in the fill-up store (a fixture for "what shipped before
/// this PR") and asserts:
///   - it survives untouched while a NEW window is detected + resolved
///     through the workflow's Path A apply seam, AND
///   - the invariant (`reconciliationBasis(...).residualLiters == 0`)
///     holds for the freshly-resolved window despite the legacy entry.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late TripHistoryRepository historyRepo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('reconcile_grandfather_');
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

  FillUp mkFillUp({
    required String id,
    required DateTime date,
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
        vehicleId: 'veh-a',
        isFullTank: isFullTank,
      );

  test(
      'legacy silent correction is left untouched while a new window is '
      'resolved; the new window still reconciles to 0', () async {
    final container = makeContainer();
    final notifier = container.read(fillUpListProvider.notifier);

    // ── Fixture: a legacy SILENT auto-correction from before this PR,
    // attributed to an older window. Grandfathered — never touched.
    await container.read(fillUpRepositoryProvider).save(FillUp(
          id: 'legacy_correction',
          date: DateTime(2026, 1, 15),
          liters: 3,
          totalCost: 0,
          odometerKm: 9000,
          fuelType: FuelType.e10,
          vehicleId: 'veh-a',
          isFullTank: false,
          isCorrection: true,
        ));

    // ── A NEW window: a trip integrated 5 L, the plein pumps 12 → a 7 L
    // gap detected → workflow surfaces a pending gap.
    await historyRepo.save(TripHistoryEntry(
      id: 't1',
      vehicleId: 'veh-a',
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
    await notifier
        .add(mkFillUp(id: 'opening', date: DateTime(2026, 4, 1, 8), liters: 30));
    await notifier.add(mkFillUp(
      id: 'closing',
      date: DateTime(2026, 4, 2, 18),
      liters: 12,
      odometerKm: 10100,
    ));

    final pending = container.read(pendingReconciliationsProvider)!;
    // User resolves Path A (consented correction).
    await notifier.applyReconciliation(
      pending.correction.copyWith(liters: pending.gap),
    );

    final corrections =
        container.read(fillUpListProvider).where((f) => f.isCorrection).toList();
    // Legacy + new correction both present; legacy is byte-for-byte
    // untouched (never migrated / deleted / re-prompted).
    expect(corrections, hasLength(2));
    final legacy =
        corrections.firstWhere((f) => f.id == 'legacy_correction');
    expect(legacy.liters, closeTo(3, 1e-9));
    expect(legacy.date, DateTime(2026, 1, 15));
    expect(legacy.odometerKm, closeTo(9000, 1e-9));

    // The new window reconciles to 0 (the legacy entry belongs to a
    // different window and isn't in this basis).
    final windowFills = container
        .read(fillUpListProvider)
        .where((f) => f.id == 'closing' || f.id == 'correction_closing')
        .toList();
    final windowTrips = historyRepo
        .loadAll()
        .where((e) => !e.summary.startedAt!.isBefore(DateTime(2026, 4, 1, 8)))
        .map((e) => e.summary)
        .toList();
    final basis = reconciliationBasis(
      windowFills: windowFills,
      windowTrips: windowTrips,
      isVirtualTrip: (t) => t.isVirtual,
    );
    expect(basis.residualLiters, closeTo(0, 1e-9));
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
