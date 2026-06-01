// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser.dart';
import 'package:tankstellen/features/consumption/data/repositories/fill_up_repository.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/services/reconciler.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../helpers/silence_error_logger.dart';

/// End-to-end integration coverage for the fill-up + receipt-scan +
/// trip-vs-pump reconciliation journey (#1633 — epic #1612).
///
/// Drives the real production classes wired as one journey:
///
///   ReceiptParser (scan) → FillUpRepository (manual entry persisted to
///   Hive) → TripHistoryRepository (recorded trips) → Reconciler
///   (trip-vs-pump correction)
///
/// The only fake is the OCR boundary: real Optical Character
/// Recognition cannot run headless and is not this app's code, so the
/// scan is driven from a representative OCR text block — exactly the
/// string a [ReceiptParser] receives from the recognizer in
/// production. Lives under `test/integration/` (not `integration_test/`,
/// which would force an emulator) so it runs on every PR in the
/// existing sharded `test` CI job.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // #2628 — silence the IsolateErrorSpool so a fire-and-forget
  // `errorLogger.log` from the production code under test can't lazily open
  // a Hive file under the temp dir and race the recursive-delete teardown
  // (flaky PathNotFoundException). See silence_error_logger.dart.
  silenceErrorLoggerSpool();

  late Directory tmpDir;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('fill_up_journey_');
    Hive.init(tmpDir.path);
  });

  tearDown(() async {
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  test(
    'scan a receipt → log the fill-up → reconcile against a recorded '
    'trip → a correction fill-up is synthesised and stored',
    () async {
      const vehicleId = 'veh-308';

      // ── 1. Receipt scan — OCR text → structured fields ─────────────
      // Representative of what the ML-Kit recognizer hands a
      // [ReceiptParser] for a French diesel receipt.
      const ocrText = 'STATION TOTAL ACCESS\n'
          'GAZOLE B7\n'
          '42.35 L\n'
          'PRIX/L 1.799 EUR\n'
          'TOTAL 76.18 EUR\n'
          '15/04/2026 14:32';
      final scan = const ReceiptParser().parse(ocrText);
      expect(scan.hasData, isTrue, reason: 'a fuel receipt must parse');
      expect(scan.liters, closeTo(42.35, 0.01));
      expect(scan.totalCost, closeTo(76.18, 0.01));

      // ── 2. Manual fill-up entry — persisted through FillUpRepository
      final fillUps = FillUpRepository(_FakeSettingsStorage());

      // An opening plein two weeks earlier closes the previous window;
      // its litres do NOT count toward this window's `pumped` total
      // (the reconciler's lower bound is exclusive).
      final openingPlein = FillUp(
        id: 'plein-open',
        date: DateTime(2026, 4, 1),
        liters: 40,
        totalCost: 68.0,
        odometerKm: 30000,
        fuelType: FuelType.diesel,
        vehicleId: vehicleId,
        isFullTank: true,
      );
      // The closing plein is built straight from the scanned receipt.
      final closingPlein = FillUp(
        id: 'plein-close',
        date: DateTime(2026, 4, 15),
        liters: scan.liters!,
        totalCost: scan.totalCost!,
        odometerKm: 30800,
        fuelType: FuelType.diesel,
        vehicleId: vehicleId,
        isFullTank: true,
      );
      await fillUps.save(openingPlein);
      await fillUps.save(closingPlein);
      expect(fillUps.getAll().map((f) => f.id),
          containsAll(<String>['plein-open', 'plein-close']));

      // ── 3. A recorded OBD2 trip lives in the trip-history Hive box ─
      final tripBox = await Hive.openBox<String>(HiveBoxes.obd2TripHistory);
      final trips = TripHistoryRepository(box: tripBox);
      // The trip integrated only 32 L of fuel, but the pump dispensed
      // 42.35 L — a ~10 L gap, well over the reconciler's floors.
      await trips.save(
        TripHistoryEntry(
          id: 'trip-1',
          vehicleId: vehicleId,
          summary: TripSummary(
            distanceKm: 520,
            maxRpm: 3200,
            highRpmSeconds: 0,
            idleSeconds: 0,
            harshBrakes: 0,
            harshAccelerations: 0,
            fuelLitersConsumed: 32,
            avgLPer100Km: 32 / 520 * 100,
            startedAt: DateTime(2026, 4, 5, 8),
            endedAt: DateTime(2026, 4, 5, 17),
          ),
        ),
      );

      // ── 4. Trip-vs-pump reconciliation ─────────────────────────────
      final history = trips.loadAll();
      final tripsForVehicle = history
          .where((e) => e.vehicleId == vehicleId)
          .map((e) => e.summary)
          .toList();
      final result = const Reconciler().reconcile(
        closingPlein: closingPlein,
        allFillUpsForVehicle: fillUps.getAll(),
        tripsForVehicle: tripsForVehicle,
      );

      expect(result, isNotNull);
      expect(result!.action, ReconciliationAction.created,
          reason: 'a 10 L pumped-vs-consumed gap must synthesise a '
              'correction');
      expect(result.pumped, closeTo(42.35, 0.01));
      expect(result.consumed, closeTo(32, 0.01));
      expect(result.gap, closeTo(10.35, 0.01));

      // ── 5. The correction round-trips back into the fill-up log ────
      final correction = result.correction!;
      expect(correction.isCorrection, isTrue);
      expect(correction.isFullTank, isFalse);
      expect(correction.liters, closeTo(10.35, 0.01));
      expect(correction.vehicleId, vehicleId);
      await fillUps.save(correction);

      final stored = fillUps.getAll();
      expect(stored, hasLength(3));
      expect(stored.where((f) => f.isCorrection), hasLength(1),
          reason: 'exactly one synthesised correction is now logged');
      await tripBox.deleteFromDisk();
    },
  );

  test(
    'a receipt-driven fill-up that matches the recorded trip needs no '
    'correction',
    () async {
      const vehicleId = 'veh-208';
      final fillUps = FillUpRepository(_FakeSettingsStorage());

      final scan = const ReceiptParser()
          .parse('SP95-E10\n38.50 litres\nTOTAL 65.45 EUR');
      expect(scan.liters, closeTo(38.50, 0.01));

      final openingPlein = FillUp(
        id: 'p0',
        date: DateTime(2026, 3, 1),
        liters: 38,
        totalCost: 64.0,
        odometerKm: 12000,
        fuelType: FuelType.e10,
        vehicleId: vehicleId,
        isFullTank: true,
      );
      final closingPlein = FillUp(
        id: 'p1',
        date: DateTime(2026, 3, 14),
        liters: scan.liters!,
        totalCost: scan.totalCost!,
        odometerKm: 12550,
        fuelType: FuelType.e10,
        vehicleId: vehicleId,
        isFullTank: true,
      );
      await fillUps.save(openingPlein);
      await fillUps.save(closingPlein);

      // Trip consumed almost exactly what the pump dispensed.
      final trip = TripSummary(
        distanceKm: 600,
        maxRpm: 3000,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        fuelLitersConsumed: 38.4,
        startedAt: DateTime(2026, 3, 7),
        endedAt: DateTime(2026, 3, 7, 10),
      );
      final result = const Reconciler().reconcile(
        closingPlein: closingPlein,
        allFillUpsForVehicle: fillUps.getAll(),
        tripsForVehicle: [trip],
      );

      expect(result, isNotNull);
      expect(result!.action, ReconciliationAction.skippedBelowThreshold,
          reason: 'a 0.1 L gap is below both reconciliation floors');
      expect(result.correction, isNull);
      expect(fillUps.getAll().where((f) => f.isCorrection), isEmpty);
    },
  );
}

/// In-memory [SettingsStorage] — the fill-up log persists as a JSON
/// list under `StorageKeys.consumptionLog`, so a map-backed fake is a
/// faithful stand-in for the Hive `settings` box.
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
